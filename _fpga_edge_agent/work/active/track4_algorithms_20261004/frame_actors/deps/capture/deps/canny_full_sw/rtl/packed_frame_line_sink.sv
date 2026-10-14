// FC02/04：一个私有512bit累加槽；末项使用next_buffer；公开RPC直到drain。
module packed_frame_line_sink #(
    parameter integer unsigned ITEM_BITS=4,ITEMS=1036800,ID_BITS=96
)(
    input logic clk,rst,
    input logic cfg_valid,output wire cfg_ready,input logic [31:0] cfg_base,input logic [ID_BITS-1:0] cfg_id,
    output wire cfg_rsp_valid,input logic cfg_rsp_ready,output logic cfg_rsp_error,
    input logic in_valid,output wire in_ready,input logic [ITEM_BITS-1:0] in_data,input logic in_bad,
    input logic abort_valid,input logic [ID_BITS-1:0] abort_id,
    output wire done_valid,input logic done_ready,output logic done_error,done_aborted,output wire done_drained,
    output logic [21:0] count,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output logic [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained,output wire quarantined
);
    localparam integer unsigned PER_LINE=512/ITEM_BITS,SLOT_BITS=$clog2(PER_LINE);
    localparam logic [32:0] ALLOCATION=33'(((ITEMS+PER_LINE-1)/PER_LINE)*64);
    typedef enum logic [2:0] {IDLE,CFG_REPLY,ACCEPT,REQUEST,WAIT_RESPONSE,DONE,QUARANTINE} state_t;
    state_t state;
    logic [31:0] base;
    logic [ID_BITS-1:0] active_id;
    logic abort_sticky;
    logic [511:0] buffer,next_buffer;
    wire matching_abort=abort_valid && state!=IDLE && state!=DONE && abort_id==active_id;
    wire stopping=abort_sticky || matching_abort;
    wire [32:0] cfg_end={1'b0,cfg_base}+ALLOCATION;
    assign cfg_ready=!rst && state==IDLE;
    assign cfg_rsp_valid=!rst && state==CFG_REPLY;
    assign in_ready=!rst && state==ACCEPT && !stopping;
    assign done_valid=!rst && state==DONE;
    assign done_drained=state==DONE;
    assign line_req_valid=!rst && state==REQUEST;
    assign line_rsp_ready=!rst && state==WAIT_RESPONSE;
    assign line_write=1'b1;
    assign line_wdata=buffer;
    assign quarantined=state==QUARANTINE;
    always_comb begin
        next_buffer=buffer;next_buffer[count[SLOT_BITS-1:0]*ITEM_BITS+:ITEM_BITS]=in_data;
    end
    initial if((ITEM_BITS!=1 && ITEM_BITS!=4 && ITEM_BITS!=8) || ITEMS==0 || ITEMS>2073600 || ID_BITS<64)
        $fatal(1,"Unsupported packed line sink parameters");
    task automatic finish_task(input logic error_value,input logic aborted_value);
        begin done_error<=error_value;done_aborted<=aborted_value;state<=DONE;end
    endtask
    always_ff @(posedge clk)begin
        if(rst)begin state<=IDLE;base<=0;active_id<=0;abort_sticky<=0;buffer<=0;count<=0;line_addr<=0;cfg_rsp_error<=0;done_error<=0;done_aborted<=0;end
        else begin
            if(matching_abort)abort_sticky<=1;
            case(state)
                IDLE:if(cfg_valid && cfg_ready)begin
                    base<=cfg_base;active_id<=cfg_id;abort_sticky<=0;buffer<=0;count<=0;done_error<=0;done_aborted<=0;
                    cfg_rsp_error<=cfg_base[5:0]!=0 || cfg_end>33'h100000000;state<=CFG_REPLY;
                end
                CFG_REPLY:if(cfg_rsp_ready)state<=cfg_rsp_error ? IDLE : ACCEPT;
                ACCEPT:begin
                    if(stopping)finish_task(1,1);
                    else if(in_valid && in_ready)begin
                        count<=count+22'd1;
                        if(in_bad || count>=22'(ITEMS))finish_task(1,0);
                        else begin
                            buffer<=next_buffer;
                            if(count[SLOT_BITS-1:0]==SLOT_BITS'(PER_LINE-1) || count==22'(ITEMS-1))begin
                                line_addr<=32'({1'b0,base}+({11'd0,(count>>SLOT_BITS)}<<6));state<=REQUEST;
                            end
                        end
                    end
                end
                REQUEST:if(line_req_ready)state<=WAIT_RESPONSE;
                WAIT_RESPONSE:if(line_rsp_valid)begin
                    if(!line_drained)state<=QUARANTINE;
                    else if(line_error)finish_task(1,0);
                    else if(stopping)finish_task(1,1);
                    else if(count==22'(ITEMS))finish_task(0,0);
                    else begin buffer<=0;state<=ACCEPT;end
                end
                DONE:if(done_ready)state<=IDLE;
                default:begin end
            endcase
        end
    end
endmodule
