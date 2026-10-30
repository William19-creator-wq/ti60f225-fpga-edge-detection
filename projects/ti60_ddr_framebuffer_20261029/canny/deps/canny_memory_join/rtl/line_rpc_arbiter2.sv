// One external 64-byte transaction, owner held through response consumption.
// Producers hold request payload while valid and !ready; the external target
// does the same for response payload. Forward those stable payloads instead of
// duplicating 1024 data flip-flops at every nested arbitration boundary.
// Arbitration locks before exposing valid, so a competing request cannot alter
// a stalled transaction. An unknown drain still quarantines the entire port.
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
    typedef enum logic [2:0] {IDLE,REQUEST,WAIT_RESPONSE,QUARANTINE} state_t;
    state_t state;
    logic owner,turn,chosen;
    always_comb begin
        chosen=req_valid[turn] ? turn : !turn;
        req_ready=0;rsp_valid=0;
        if(!rst && state==REQUEST)req_ready[owner]=line_req_ready;
        if(!rst && state==WAIT_RESPONSE)rsp_valid[owner]=line_rsp_valid;
        line_write=req_write[owner];line_addr=req_addr[owner];line_wdata=req_data[owner];
        rsp_data=line_rdata;rsp_error=line_error;rsp_drained=line_drained;
    end
    assign line_req_valid=!rst && state==REQUEST && req_valid[owner];
    assign line_rsp_ready=!rst && state==WAIT_RESPONSE && rsp_ready[owner];
    assign quarantined=state==QUARANTINE;
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;owner<=0;turn<=0;
        end else case(state)
            IDLE:if(|req_valid)begin
                owner<=chosen;state<=REQUEST;
            end
            REQUEST:if(line_req_valid && line_req_ready)begin
                turn<=!owner;state<=WAIT_RESPONSE;
            end
            WAIT_RESPONSE:if(line_rsp_valid && line_rsp_ready)
                state<=line_drained ? IDLE : QUARANTINE;
            default:begin end
        endcase
    end
endmodule
