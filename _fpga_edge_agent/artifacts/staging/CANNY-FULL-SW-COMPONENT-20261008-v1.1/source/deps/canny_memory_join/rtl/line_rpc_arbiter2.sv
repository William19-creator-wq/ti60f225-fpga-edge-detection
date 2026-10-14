// MJ02：一个外部64B事务；owner直到回复消费才释放；未知drain隔离。
module line_rpc_arbiter2(
    input logic clk,rst,
    input logic [1:0] req_valid,output logic [1:0] req_ready,input logic [1:0] req_write,
    input logic [31:0] req_addr[0:1],input logic [511:0] req_data[0:1],
    output logic [1:0] rsp_valid,input logic [1:0] rsp_ready,
    output logic [511:0] rsp_data,output logic rsp_error,rsp_drained,
    output wire line_req_valid,input logic line_req_ready,output logic line_write,
    output logic [31:0] line_addr,output logic [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained,output wire quarantined
);
    typedef enum logic [2:0] {IDLE,REQUEST,WAIT_RESPONSE,REPLY,QUARANTINE} state_t;
    state_t state;
    logic owner,turn,chosen;
    always_comb begin
        chosen=req_valid[turn] ? turn : !turn;
        req_ready=0;rsp_valid=0;
        if(!rst && state==IDLE && |req_valid)req_ready[chosen]=1;
        if(!rst && state==REPLY)rsp_valid[owner]=1;
    end
    assign line_req_valid=!rst && state==REQUEST;
    assign line_rsp_ready=!rst && state==WAIT_RESPONSE;
    assign quarantined=state==QUARANTINE;
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;owner<=0;turn<=0;line_write<=0;line_addr<=0;line_wdata<=0;
            rsp_data<=0;rsp_error<=0;rsp_drained<=0;
        end else case(state)
            IDLE:if(req_valid[chosen] && req_ready[chosen])begin
                owner<=chosen;turn<=!chosen;line_write<=req_write[chosen];line_addr<=req_addr[chosen];line_wdata<=req_data[chosen];state<=REQUEST;
            end
            REQUEST:if(line_req_ready)state<=WAIT_RESPONSE;
            WAIT_RESPONSE:if(line_rsp_valid)begin rsp_data<=line_rdata;rsp_error<=line_error;rsp_drained<=line_drained;state<=REPLY;end
            REPLY:if(rsp_ready[owner])state<=rsp_drained ? IDLE : QUARANTINE;
            default:begin end
        endcase
    end
endmodule
