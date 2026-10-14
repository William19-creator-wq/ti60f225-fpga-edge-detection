// 两个调用者共用一个64字节DDR事务口。选中、请求接受、回复消费是三个独立事件。
module board_native_rpc_arbiter2(
    input wire clk,rst,
    input wire a_valid,output wire a_ready,input wire a_write,
    input wire [31:0] a_addr,input wire [511:0] a_wdata,
    output wire a_rsp_valid,input wire a_rsp_ready,output wire a_drained,
    input wire b_valid,output wire b_ready,input wire b_write,
    input wire [31:0] b_addr,input wire [511:0] b_wdata,
    output wire b_rsp_valid,input wire b_rsp_ready,output wire b_drained,
    output wire req_valid,input wire req_ready,output wire req_write,
    output wire [31:0] req_addr,output wire [511:0] req_wdata,
    input wire rsp_valid,output wire rsp_ready,input wire drained,
    output wire [1:0] data_select,
    output reg fault
);
    localparam IDLE=0,OFFER=1,REPLY=2,FAILED=3;
    reg [1:0] state;
    reg owner,last_owner;
    assign req_valid=!rst&&state==OFFER&&(owner?b_valid:a_valid);
    assign req_write=owner?b_write:a_write;
    assign data_select={owner,!owner};
    assign req_addr=owner?b_addr:a_addr;
    assign req_wdata=owner?b_wdata:a_wdata;
    assign a_ready=!rst&&state==OFFER&&!owner&&req_ready;
    assign b_ready=!rst&&state==OFFER&&owner&&req_ready;
    assign a_rsp_valid=!rst&&state==REPLY&&!owner&&rsp_valid;
    assign b_rsp_valid=!rst&&state==REPLY&&owner&&rsp_valid;
    assign rsp_ready=!rst&&state==REPLY&&(owner?b_rsp_ready:a_rsp_ready);
    // 只有本调用者的回复或整个端口空闲，才报告它已排空。
    assign a_drained=drained&&(state==IDLE||(state==REPLY&&!owner));
    assign b_drained=drained&&(state==IDLE||(state==REPLY&&owner));
    always @(posedge clk)begin
        if(rst)begin state<=IDLE;owner<=0;last_owner<=1;fault<=0;end
        else if(rsp_valid&&state!=REPLY)begin state<=FAILED;fault<=1;end
        else case(state)
            IDLE:if(a_valid||b_valid)begin
                owner<=b_valid&&(!a_valid||!last_owner);
                state<=OFFER;
            end
            OFFER:begin
                if(!(owner?b_valid:a_valid))state<=IDLE;
                else if(req_valid&&req_ready)begin last_owner<=owner;state<=REPLY;end
            end
            REPLY:if(rsp_valid&&rsp_ready)begin
                if(drained)state<=IDLE;
                else begin state<=FAILED;fault<=1;end
            end
            FAILED:begin end // 未知排空不能伪造完成，冷复位后才能重新接单。
            default:begin state<=FAILED;fault<=1;end
        endcase
    end
endmodule
