// S07/S08 / IF-S04：真实请求→core→585bit串行CRC→异步LED。
module scalar_probe_top(input wire clk_25m,input wire key1_n,output logic led0,output wire led1);
    import scalar_protocol_pkg::*;
    wire core_rst;
    reset_sync reset_adapter(.clk(clk_25m),.key1_n(key1_n),.core_rst(core_rst));
    typedef enum logic [2:0] {SOURCE_EMPTY,SOURCE_OFFER,SOURCE_WAIT,OBSERVE_BITS,OBSERVE_DONE,SOURCE_STOP} source_state_t;
    source_state_t source_state;
    logic [383:0] source_lfsr;
    logic [63:0] source_sequence;
    logic sequence_exhausted;
    logic [621:0] request_slot;
    logic [584:0] response_shift;
    logic [9:0] bit_index;
    logic [31:0] rolling_crc;
    wire req_ready,rsp_valid,core_quiet;
    wire [584:0] rsp_body;
    wire req_valid=!core_rst && source_state==SOURCE_OFFER;
    wire rsp_ready=!core_rst && source_state==SOURCE_WAIT;
    wire [4:0] next_kind={2'd0,source_sequence[2:0]};
    logic next_as,next_bs;
    logic [191:0] next_b;
    logic [399:0] next_payload;
    logic [175:0] next_identity;
    logic [31:0] next_crc;
    scalar_core arithmetic(.clk(clk_25m),.rst(core_rst),
        .req_valid(req_valid),.req_ready(req_ready),.req_body(request_slot),
        .rsp_valid(rsp_valid),.rsp_ready(rsp_ready),.rsp_body(rsp_body),
        .cancel_valid(1'b0),.cancel_id(176'd0),.quiet(core_quiet));
    assign led1=rolling_crc[0];

    always_comb begin : source_and_crc_values
        next_as=0;next_bs=0;
        if(next_kind==0 || next_kind==1 || next_kind==2 || next_kind==5) begin
            next_as=source_sequence[3];next_bs=source_sequence[4];
        end else if(next_kind==3) next_as=source_sequence[3];
        next_b=source_lfsr[383:192];
        if(next_kind==3 || next_kind==6) next_b[0]=1'b1;
        next_payload={16'd0,next_b,source_lfsr[191:0]};
        if(next_kind==4 || next_kind==7) next_payload={208'd0,source_lfsr[191:0]};
        next_identity={{3'd0,next_kind},source_sequence,8'd0,32'd1,32'd0,32'd1};
        next_crc=rolling_crc<<1;
        if(rolling_crc[31]^response_shift[584]) next_crc=next_crc^32'h04c11db7;
    end
    always_ff @(posedge clk_25m) begin : probe_transactions
        if(core_rst) begin
            source_state<=SOURCE_EMPTY;source_lfsr<=384'd1;source_sequence<=0;
            sequence_exhausted<=0;rolling_crc<=32'hffffffff;led0<=0;
        end else case(source_state)
            SOURCE_EMPTY:begin
                request_slot<={next_payload,maximum_target(next_kind),next_bs,next_as,next_kind,
                               8'd1,11'd1080,11'd1920,next_identity};
                source_state<=SOURCE_OFFER;
            end
            SOURCE_OFFER:if(req_ready) begin
                source_lfsr<={source_lfsr[382:0],source_lfsr[383]^source_lfsr[382]^source_lfsr[380]^source_lfsr[377]};
                source_state<=SOURCE_WAIT;
            end
            SOURCE_WAIT:if(rsp_valid) begin
                response_shift<=rsp_body;bit_index<=584;source_state<=OBSERVE_BITS;
                if(source_sequence[9:0]==10'h3ff) led0<=!led0;
                if(source_sequence==64'hffffffffffffffff) sequence_exhausted<=1;
                else source_sequence<=source_sequence+64'd1;
            end
            OBSERVE_BITS:begin
                rolling_crc<=next_crc;response_shift<=response_shift<<1;
                if(bit_index==0) source_state<=OBSERVE_DONE;
                else bit_index<=bit_index-10'd1;
            end
            OBSERVE_DONE:source_state<=sequence_exhausted?SOURCE_STOP:SOURCE_EMPTY;
            SOURCE_STOP:source_state<=SOURCE_STOP;
            default:source_state<=SOURCE_STOP;
        endcase
    end
endmodule
