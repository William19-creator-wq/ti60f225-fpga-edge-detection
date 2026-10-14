// SC01..05：ID、原表164写、14字段真实读回。寄存器资格与ARM/画面资格分开。
module sc431hai_config #(
    parameter integer unsigned CLK_MAX_HZ=101000000,SCL_HZ=100000,TIMEOUT_US=10000,READY_TIMEOUT_US=100000,
    parameter logic [63:0] INITIAL_TAG=64'd0
)(
    input logic clk,rst,platform_ok,
    input logic job_valid,output wire job_ready,input logic [159:0] job_scope,
    input logic [1:0] job_operation,input logic [6:0] job_device_addr,
    input logic cancel_valid,input logic [159:0] cancel_scope,
    output wire done_valid,input logic done_ready,output wire [159:0] done_scope,
    output wire [1:0] done_operation,output wire [6:0] done_device_addr,
    output logic [1:0] outcome,output logic [7:0] reason,readback_value,
    output logic [15:0] failed_reg,chip_id,output logic [3:0] failed_phase,ack_mask,
    output logic [7:0] writes_committed,reads_completed,output logic [13:0] verify_mask,
    output logic [111:0] readback_values,output logic [1:0] chip_valid,
    output logic drained,registers_verified,live_verified,output logic [159:0] verified_scope,
    output wire quarantined,
    input logic scl_i,sda_i,output wire scl_drive_low,sda_drive_low
);
    import sc431hai_profile_pkg::*;
    localparam integer unsigned T4=32'((64'(CLK_MAX_HZ)*64'd4000+64'd999999)/64'd1000000);
    localparam integer unsigned POWER_LIMIT=32'((64'(CLK_MAX_HZ)*64'(READY_TIMEOUT_US)+64'd999999)/64'd1000000);
    localparam integer PCW=$clog2(T4+1),WCW=$clog2(POWER_LIMIT+1);
    typedef enum logic [3:0] {IDLE,WAIT_POWER,PREPARE,ROM_LO,ROM_LO_WAIT,ROM_HI,ROM_HI_WAIT,ISSUE,WAIT_REPLY,DONE,QUARANTINE} state_t;
    typedef enum logic [2:0] {ID_HIGH,ID_LOW,ROM_WRITE,VERIFY,STREAM_OFF_WRITE,STREAM_OFF_READ} stage_t;
    state_t state;stage_t stage;
    logic [159:0] scope;
    logic [1:0] operation;
    logic [6:0] device_addr;
    logic [7:0] rom_index;
    logic [3:0] verify_index;
    logic [PCW-1:0] power_age;
    logic [WCW-1:0] power_wait;
    logic cancel_seen,platform_failed,q_after_done;
    logic [63:0] next_tag,command_tag;
    logic command_read;
    logic [15:0] command_register;
    logic [7:0] command_data;
    logic [19:0] rom_low_word;
    wire [19:0] rom_word;
    wire rom_re=state==ROM_LO || state==ROM_HI;
    wire [8:0] rom_address={rom_index,state==ROM_HI};
    wire matching_cancel=cancel_valid && cancel_scope==scope && state!=IDLE && state!=DONE && state!=QUARANTINE;
    wire cancellation=cancel_seen || matching_cancel;
    wire [64:0] tag_end={1'b0,next_tag}+(job_operation==0 ? 65'd180 : 65'd2);
    wire legal_job=job_operation<=1 && (job_device_addr==7'h30 || job_device_addr==7'h32);
    wire m_ready,m_valid,m_drained,m_q;
    wire [63:0] m_tag;wire [7:0] m_data,m_reason;wire [1:0] m_outcome;wire [3:0] m_phase,m_ack;
    wire master_fire=state==ISSUE && m_ready;
    wire response_fire=state==WAIT_REPLY && m_valid;
    assign job_ready=!rst && state==IDLE && !m_q;
    assign done_valid=!rst && state==DONE;
    assign done_scope=scope;assign done_operation=operation;assign done_device_addr=device_addr;
    assign quarantined=m_q || q_after_done || state==QUARANTINE;
    sc431hai_profile_rom profile(.clk(clk),.re(rom_re),.address(rom_address),.word_out(rom_word));
    i2c_register_master #(.CLK_MAX_HZ(CLK_MAX_HZ),.SCL_HZ(SCL_HZ),.TIMEOUT_US(TIMEOUT_US)) bus(
        .clk(clk),.rst(rst),.enable(platform_ok),.req_valid(state==ISSUE),.req_ready(m_ready),.req_read(command_read),
        .req_device(device_addr),.req_register(command_register),.req_data(command_data),.req_tag(command_tag),
        .cancel_valid(cancellation),.cancel_tag(command_tag),.rsp_valid(m_valid),.rsp_ready(state==WAIT_REPLY),.rsp_tag(m_tag),
        .rsp_data(m_data),.rsp_reason(m_reason),.rsp_outcome(m_outcome),.rsp_phase(m_phase),.rsp_ack_mask(m_ack),.rsp_drained(m_drained),.quarantined(m_q),
        .scl_i(scl_i),.sda_i(sda_i),.scl_drive_low(scl_drive_low),.sda_drive_low(sda_drive_low));
    task automatic finish(input logic [1:0] kind,input logic [7:0] code,input logic safe);
        begin outcome<=kind;reason<=code;drained<=safe;state<=DONE;registers_verified<=0;if(kind==3)q_after_done<=1;end
    endtask
    task automatic command(input logic reading,input logic [15:0] reg_address,input logic [7:0] value);
        begin command_read<=reading;command_register<=reg_address;command_data<=value;command_tag<=next_tag;state<=ISSUE;end
    endtask
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;stage<=ID_HIGH;scope<=0;operation<=0;device_addr<=0;rom_index<=0;verify_index<=0;
            power_age<=0;power_wait<=0;cancel_seen<=0;platform_failed<=0;q_after_done<=0;next_tag<=INITIAL_TAG;
            command_tag<=0;command_read<=0;command_register<=0;command_data<=0;rom_low_word<=0;
            outcome<=0;reason<=0;readback_value<=0;failed_reg<=0;chip_id<=0;failed_phase<=0;ack_mask<=0;
            writes_committed<=0;reads_completed<=0;verify_mask<=0;readback_values<=0;chip_valid<=0;
            drained<=0;registers_verified<=0;live_verified<=0;verified_scope<=0;
        end else begin
            if(!platform_ok)begin power_age<=0;live_verified<=0;end
            else if(power_age<PCW'(T4))power_age<=power_age+PCW'(1);
            if(cancel_valid && cancel_scope==verified_scope)live_verified<=0;
            if(matching_cancel)begin cancel_seen<=1;live_verified<=0;end
            if(state!=IDLE && state!=DONE && state!=QUARANTINE && !platform_ok)begin platform_failed<=1;live_verified<=0;end
            case(state)
                IDLE:if(job_valid && job_ready)begin
                    scope<=job_scope;operation<=job_operation;device_addr<=job_device_addr;rom_index<=0;verify_index<=0;
                    cancel_seen<=0;platform_failed<=0;power_wait<=0;q_after_done<=0;
                    outcome<=0;reason<=0;readback_value<=0;failed_reg<=0;chip_id<=0;failed_phase<=0;ack_mask<=0;
                    writes_committed<=0;reads_completed<=0;verify_mask<=0;readback_values<=0;chip_valid<=0;
                    drained<=0;registers_verified<=0;live_verified<=0;
                    if(!legal_job)finish(1,BAD_FIELD,1);
                    else if(tag_end>65'h0ffffffffffffffff)finish(1,TAG_EXHAUSTED,1);
                    else if(cancel_valid && cancel_scope==job_scope)finish(2,NONE,1);
                    else begin stage<=job_operation==0 ? ID_HIGH : STREAM_OFF_WRITE;state<=WAIT_POWER;end
                end
                WAIT_POWER:begin
                    // 等待资格期间platform=0本身不是“已就绪后失效”。
                    platform_failed<=0;
                    if(cancellation)finish(2,NONE,1);
                    else if(platform_ok && power_age==PCW'(T4))state<=PREPARE;
                    else if(power_wait==WCW'(POWER_LIMIT-1))begin failed_phase<=9;finish(1,TIMEOUT,1);end
                    else power_wait<=power_wait+WCW'(1);
                end
                PREPARE:begin
                    if(platform_failed || !platform_ok)begin failed_phase<=9;finish(1,PLATFORM,1);end
                    else if(cancellation)finish(2,NONE,1);
                    else case(stage)
                        ID_HIGH:command(1,16'h3107,0);
                        ID_LOW:command(1,16'h3108,0);
                        ROM_WRITE:state<=ROM_LO;
                        VERIFY:command(1,verify_address(verify_index),0);
                        STREAM_OFF_WRITE:command(0,16'h0100,0);
                        STREAM_OFF_READ:command(1,16'h0100,0);
                    endcase
                end
                ROM_LO:state<=ROM_LO_WAIT;
                ROM_LO_WAIT:begin rom_low_word<=rom_word;state<=ROM_HI;end
                ROM_HI:state<=ROM_HI_WAIT;
                ROM_HI_WAIT:begin
                    if(platform_failed || !platform_ok)begin failed_phase<=9;finish(1,PLATFORM,1);end
                    else if(cancellation)finish(2,NONE,1);
                    else command(0,{rom_word[3:0],rom_low_word[19:8]},rom_low_word[7:0]);
                end
                ISSUE:if(master_fire)begin next_tag<=next_tag+64'd1;state<=WAIT_REPLY;end
                WAIT_REPLY:if(response_fire)begin
                    ack_mask<=m_ack;readback_value<=m_data;
                    if(m_tag!=command_tag)begin failed_reg<=command_register;failed_phase<=8;finish(3,PROTOCOL,0);end
                    else if(m_outcome!=0 || !m_drained)begin
                        failed_reg<=command_register;failed_phase<=m_phase;
                        finish(!m_drained ? 2'd3 : m_outcome,m_reason,m_drained);
                    end else begin
                        // 真成功回复必须计入前缀；同沿cancel不能抹已发生的从机事务。
                        if(command_read)reads_completed<=reads_completed+8'd1;else writes_committed<=writes_committed+8'd1;
                        case(stage)
                            ID_HIGH:begin chip_id[15:8]<=m_data;chip_valid[1]<=1;stage<=ID_LOW;state<=PREPARE;end
                            ID_LOW:begin
                                chip_id[7:0]<=m_data;chip_valid[0]<=1;
                                if({chip_id[15:8],m_data}!=SENSOR_ID)begin failed_reg<=16'h3108;failed_phase<=6;finish(1,ID_MISMATCH,1);end
                                else begin stage<=ROM_WRITE;state<=PREPARE;end
                            end
                            ROM_WRITE:begin
                                if(rom_index==163)begin stage<=VERIFY;verify_index<=0;end else rom_index<=rom_index+8'd1;
                                state<=PREPARE;
                            end
                            VERIFY:begin
                                readback_values[verify_index*8+:8]<=m_data;
                                if((m_data&verify_bits(verify_index))!=verify_expected(verify_index))begin
                                    failed_reg<=command_register;failed_phase<=6;finish(1,READBACK,1);
                                end else begin
                                    verify_mask[verify_index]<=1;
                                    if(verify_index==13)begin
                                        outcome<=0;reason<=0;drained<=1;registers_verified<=1;live_verified<=1;verified_scope<=scope;state<=DONE;
                                    end else begin verify_index<=verify_index+4'd1;state<=PREPARE;end
                                end
                            end
                            STREAM_OFF_WRITE:begin stage<=STREAM_OFF_READ;state<=PREPARE;end
                            STREAM_OFF_READ:if(m_data[0])begin failed_reg<=16'h0100;failed_phase<=6;finish(1,READBACK,1);end else finish(0,NONE,1);
                        endcase
                        // 内容错误优先；正常前缀提交后，cancel/平台失效阻止下一条命令和live资格。
                        if(platform_failed || !platform_ok)begin failed_phase<=9;finish(1,PLATFORM,1);live_verified<=0;end
                        else if(cancellation && !(stage==ID_LOW && {chip_id[15:8],m_data}!=SENSOR_ID) &&
                            !(stage==VERIFY && (m_data&verify_bits(verify_index))!=verify_expected(verify_index)) &&
                            !(stage==STREAM_OFF_READ && m_data[0]))begin finish(2,NONE,1);live_verified<=0;end
                    end
                end
                DONE:if(done_ready)state<=q_after_done ? QUARANTINE : IDLE;
                QUARANTINE:begin end
                default:finish(3,PROTOCOL,0);
            endcase
        end
    end
    // synthesis translate_off
    initial if(CLK_MAX_HZ<1000000 || CLK_MAX_HZ>200000000 || READY_TIMEOUT_US<4000)$fatal(1,"SC431 config timing");
    always @(posedge clk)if(!rst)begin
        if(master_fire && command_tag!=next_tag)$fatal(1,"SC431 tag reservation changed");
        if(done_valid && outcome==0 && operation==0 && (writes_committed!=164 || reads_completed!=16 || verify_mask!=14'h3fff || chip_valid!=3 || chip_id!=SENSOR_ID))$fatal(1,"SC431 verified counts");
        if(done_valid && drained && (state==ISSUE || state==WAIT_REPLY || m_q))$fatal(1,"SC431 safe done with bus borrow");
    end
    // synthesis translate_on
endmodule
