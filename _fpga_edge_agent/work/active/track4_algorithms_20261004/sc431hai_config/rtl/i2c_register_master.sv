// SC03/05，CT02/03：16位寄存器、8位数据的单事务开漏I2C。
// 同步输入确认实际SCL高后才计高时间；碰撞释放，不替另一个master发STOP。
module i2c_register_master #(
    parameter integer unsigned CLK_MAX_HZ=101000000,SCL_HZ=100000,TIMEOUT_US=10000
)(
    input logic clk,rst,enable,
    input logic req_valid,output wire req_ready,input logic req_read,
    input logic [6:0] req_device,input logic [15:0] req_register,input logic [7:0] req_data,input logic [63:0] req_tag,
    input logic cancel_valid,input logic [63:0] cancel_tag,
    output wire rsp_valid,input logic rsp_ready,output wire [63:0] rsp_tag,
    output logic [7:0] rsp_data,rsp_reason,output logic [1:0] rsp_outcome,
    output logic [3:0] rsp_phase,rsp_ack_mask,output logic rsp_drained,output wire quarantined,
    input logic scl_i,sda_i,output logic scl_drive_low,sda_drive_low
);
    import sc431hai_profile_pkg::*;
    localparam integer unsigned HALF=(CLK_MAX_HZ+2*SCL_HZ-1)/(2*SCL_HZ);
    localparam integer unsigned DEADLINE=32'((64'(CLK_MAX_HZ)*64'(TIMEOUT_US)+64'd999999)/64'd1000000);
    localparam integer HCW=$clog2(HALF+1),TCW=$clog2(DEADLINE+1);
    typedef enum logic [4:0] {IDLE,WAIT_FREE,START_HOLD,LOW_FALL,BIT_LOW,BIT_RISE,BIT_HIGH,BYTE_NEXT,
        RESTART_LOW,RESTART_RISE,RESTART_HIGH,STOP_LOW,STOP_RISE,STOP_HIGH,WAIT_RELEASE,RESPONSE,QUARANTINE} state_t;
    typedef enum logic [1:0] {TX,SLAVE_ACK,RX,MASTER_NACK} bit_kind_t;
    state_t state;bit_kind_t bit_kind;
    (* ASYNC_REG="TRUE" *) logic scl_meta,scl_sync,sda_meta,sda_sync;
    logic [63:0] tag;
    logic [6:0] device;
    logic [15:0] register_address;
    logic [7:0] write_data,tx_byte,rx_byte;
    logic read_operation,cancel_seen,owned,q_notice,stop_setup;
    logic [2:0] bit_index;
    logic [1:0] byte_index;
    logic [HCW-1:0] phase_count;
    logic [TCW-1:0] wait_count;
    wire active=state!=IDLE && state!=RESPONSE && state!=QUARANTINE;
    wire matching_cancel=active && cancel_valid && cancel_tag==tag;
    wire cancellation=cancel_seen || matching_cancel;
    assign req_ready=!rst && state==IDLE;
    assign rsp_valid=!rst && (state==RESPONSE || (state==QUARANTINE && q_notice));
    assign rsp_tag=tag;
    assign quarantined=state==QUARANTINE;

    function automatic logic [3:0] byte_phase(input logic [1:0] number,input logic reading);
        case(number)
            0:byte_phase=1;
            1:byte_phase=2;
            2:byte_phase=3;
            3:byte_phase=reading ? 5 : 4;
        endcase
    endfunction
    task automatic move(input state_t next_state);
        begin state<=next_state;phase_count<=0;wait_count<=0;end
    endtask
    task automatic error_cause(input logic [7:0] code,input logic [3:0] phase_code);
        begin
            rsp_outcome<=1;
            if(rsp_reason==NONE)begin rsp_reason<=code;rsp_phase<=phase_code;end
        end
    endtask
    task automatic stop_owned;
        begin scl_drive_low<=1;stop_setup<=0;move(STOP_LOW);end
    endtask
    task automatic release_collision;
        begin
            error_cause(ARBITRATION,byte_phase(byte_index,read_operation));
            scl_drive_low<=0;sda_drive_low<=0;move(WAIT_RELEASE);
        end
    endtask
    task automatic quarantine_notice(input logic [7:0] code,input logic [3:0] phase_code);
        begin
            scl_drive_low<=0;sda_drive_low<=0;rsp_outcome<=3;rsp_drained<=0;q_notice<=1;
            if(rsp_reason==NONE)begin rsp_reason<=code;rsp_phase<=phase_code;end
            move(QUARANTINE);
        end
    endtask
    always_ff @(posedge clk)begin
        if(rst)begin scl_meta<=1;scl_sync<=1;sda_meta<=1;sda_sync<=1;end
        else begin scl_meta<=scl_i;scl_sync<=scl_meta;sda_meta<=sda_i;sda_sync<=sda_meta;end
    end
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;bit_kind<=TX;tag<=0;device<=0;register_address<=0;write_data<=0;
            tx_byte<=0;rx_byte<=0;read_operation<=0;cancel_seen<=0;owned<=0;q_notice<=0;stop_setup<=0;
            bit_index<=7;byte_index<=0;phase_count<=0;wait_count<=0;
            scl_drive_low<=0;sda_drive_low<=0;
            rsp_data<=0;rsp_reason<=0;rsp_outcome<=0;rsp_phase<=0;rsp_ack_mask<=0;rsp_drained<=0;
        end else begin
            if(active)wait_count<=wait_count+TCW'(1);
            if(matching_cancel)begin
                cancel_seen<=1;
                if(rsp_outcome==0)rsp_outcome<=2;
            end
            if(active && !enable)begin
                if(owned)quarantine_notice(PLATFORM,9);
                else begin
                    scl_drive_low<=0;sda_drive_low<=0;rsp_outcome<=1;rsp_reason<=PLATFORM;rsp_phase<=9;rsp_drained<=1;
                    move(RESPONSE);
                end
            end else if(active && wait_count==TCW'(DEADLINE-1))begin
                quarantine_notice(TIMEOUT,(state==STOP_LOW || state==STOP_RISE || state==STOP_HIGH) ? 4'd7 : 4'd8);
            end else case(state)
                IDLE:if(req_valid && req_ready)begin
                    tag<=req_tag;device<=req_device;register_address<=req_register;write_data<=req_data;read_operation<=req_read;
                    tx_byte<={req_device,1'b0};rx_byte<=0;bit_index<=7;byte_index<=0;bit_kind<=TX;
                    cancel_seen<=0;owned<=0;q_notice<=0;rsp_data<=0;rsp_reason<=0;rsp_outcome<=0;rsp_phase<=0;rsp_ack_mask<=0;rsp_drained<=0;
                    scl_drive_low<=0;sda_drive_low<=0;
                    if(req_device<7'h08 || req_device>7'h77)begin rsp_outcome<=1;rsp_reason<=BAD_FIELD;rsp_drained<=1;move(RESPONSE);end
                    else if(!enable)begin rsp_outcome<=1;rsp_reason<=PLATFORM;rsp_phase<=9;rsp_drained<=1;move(RESPONSE);end
                    else if(cancel_valid && cancel_tag==req_tag)begin rsp_outcome<=2;rsp_drained<=1;move(RESPONSE);end
                    else move(WAIT_FREE);
                end
                WAIT_FREE:begin
                    if(cancellation)begin rsp_drained<=1;move(RESPONSE);end
                    else if(scl_sync && sda_sync)begin
                        if(phase_count==HCW'(HALF-1))begin sda_drive_low<=1;owned<=1;move(START_HOLD);end
                        else phase_count<=phase_count+HCW'(1);
                    end else phase_count<=0;
                end
                START_HOLD:begin
                    if(!scl_sync)release_collision();
                    else if(phase_count==HCW'(HALF-1))begin scl_drive_low<=1;move(LOW_FALL);end
                    else phase_count<=phase_count+HCW'(1);
                end
                LOW_FALL:if(!scl_sync)begin
                    if(cancellation)stop_owned();
                    else begin sda_drive_low<=bit_kind==TX && !tx_byte[bit_index];move(BIT_LOW);end
                end
                BIT_LOW:begin
                    if(phase_count==HCW'(HALF-1))begin scl_drive_low<=0;move(BIT_RISE);end
                    else phase_count<=phase_count+HCW'(1);
                end
                BIT_RISE:if(scl_sync)move(BIT_HIGH);
                BIT_HIGH:begin
                    if(!scl_sync)release_collision();
                    else if(phase_count==HCW'(HALF-1))begin
                        case(bit_kind)
                            TX:begin
                                if(tx_byte[bit_index] && !sda_sync)release_collision();
                                else begin
                                    scl_drive_low<=1;
                                    if(bit_index==0)bit_kind<=SLAVE_ACK;else bit_index<=bit_index-3'd1;
                                    move(LOW_FALL);
                                end
                            end
                            SLAVE_ACK:begin
                                if(sda_sync)begin error_cause(NACK,byte_phase(byte_index,read_operation));stop_owned();end
                                else begin rsp_ack_mask[byte_index]<=1;move(BYTE_NEXT);end
                            end
                            RX:begin
                                rx_byte<={rx_byte[6:0],sda_sync};scl_drive_low<=1;
                                if(bit_index==0)begin rsp_data<={rx_byte[6:0],sda_sync};bit_kind<=MASTER_NACK;end
                                else bit_index<=bit_index-3'd1;
                                move(LOW_FALL);
                            end
                            MASTER_NACK:if(!sda_sync)release_collision();else stop_owned();
                        endcase
                    end else phase_count<=phase_count+HCW'(1);
                end
                BYTE_NEXT:begin
                    if(cancellation)stop_owned();
                    else case(byte_index)
                        0:begin byte_index<=1;tx_byte<=register_address[15:8];bit_index<=7;bit_kind<=TX;scl_drive_low<=1;move(LOW_FALL);end
                        1:begin byte_index<=2;tx_byte<=register_address[7:0];bit_index<=7;bit_kind<=TX;scl_drive_low<=1;move(LOW_FALL);end
                        2:begin
                            byte_index<=3;bit_index<=7;bit_kind<=TX;scl_drive_low<=1;
                            if(read_operation)begin tx_byte<={device,1'b1};sda_drive_low<=0;move(RESTART_LOW);end
                            else begin tx_byte<=write_data;move(LOW_FALL);end
                        end
                        3:if(read_operation)begin bit_kind<=RX;bit_index<=7;scl_drive_low<=1;move(LOW_FALL);end else stop_owned();
                    endcase
                end
                RESTART_LOW:begin
                    if(cancellation)stop_owned();
                    else if(!scl_sync && sda_sync)begin
                        if(phase_count==HCW'(HALF-1))begin scl_drive_low<=0;move(RESTART_RISE);end
                        else phase_count<=phase_count+HCW'(1);
                    end else phase_count<=0;
                end
                RESTART_RISE:if(scl_sync)move(RESTART_HIGH);
                RESTART_HIGH:begin
                    if(!scl_sync)release_collision();
                    else if(phase_count==HCW'(HALF-1))begin
                        if(!sda_sync)release_collision();else begin sda_drive_low<=1;move(START_HOLD);end
                    end else phase_count<=phase_count+HCW'(1);
                end
                STOP_LOW:if(!scl_sync)begin
                    if(!stop_setup)begin sda_drive_low<=1;stop_setup<=1;phase_count<=0;end
                    else if(phase_count==HCW'(HALF-1))begin scl_drive_low<=0;move(STOP_RISE);end
                    else phase_count<=phase_count+HCW'(1);
                end
                STOP_RISE:if(scl_sync)move(STOP_HIGH);
                STOP_HIGH:begin
                    if(!scl_sync)release_collision();
                    else if(phase_count==HCW'(HALF-1))begin sda_drive_low<=0;move(WAIT_RELEASE);end
                    else phase_count<=phase_count+HCW'(1);
                end
                WAIT_RELEASE:begin
                    if(scl_sync && sda_sync)begin
                        if(phase_count==HCW'(HALF-1))begin owned<=0;rsp_drained<=1;move(RESPONSE);end
                        else phase_count<=phase_count+HCW'(1);
                    end else phase_count<=0;
                end
                RESPONSE:if(rsp_ready)move(IDLE);
                QUARANTINE:if(q_notice && rsp_ready)q_notice<=0;
                default:quarantine_notice(PROTOCOL,8);
            endcase
        end
    end
    // synthesis translate_off
    initial if(CLK_MAX_HZ<1000000 || CLK_MAX_HZ>200000000 || SCL_HZ!=100000 || TIMEOUT_US<100 || HALF<5 || DEADLINE<=HALF)$fatal(1,"I2C timing parameter range");
    always @(posedge clk)if(!rst)begin
        if(rsp_valid && rsp_drained && (owned || scl_drive_low || sda_drive_low))$fatal(1,"I2C safe response before physical release");
        if(quarantined && (req_ready || rsp_drained))$fatal(1,"I2C quarantine recycled");
    end
    // synthesis translate_on
endmodule
