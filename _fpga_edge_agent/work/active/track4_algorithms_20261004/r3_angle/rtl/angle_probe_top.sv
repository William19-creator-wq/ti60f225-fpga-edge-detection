// AN08：LFSR只随真req_fire更新；真rsp_fire后逐位观察585bit，结束才复用上下文。
module angle_probe_top(input wire clk_25m,key1_n,output logic led0,output wire led1);
    wire core_rst;reset_sync reset_adapter(.clk(clk_25m),.key1_n(key1_n),.core_rst(core_rst));
    typedef enum logic [2:0] {SOURCE_EMPTY,SOURCE_OFFER,SOURCE_WAIT,OBSERVE_BITS,OBSERVE_DONE,SOURCE_STOP} source_state_t;
    source_state_t source_state;
    logic [191:0] source_lfsr;logic [63:0] source_sequence;logic sequence_exhausted;
    logic [621:0] request_slot;logic [584:0] response_shift;logic [9:0] bit_index;logic [31:0] rolling_crc;
    wire req_ready,rsp_valid,core_quiet;wire [584:0] rsp_body;
    wire req_valid=!core_rst && source_state==SOURCE_OFFER;
    wire rsp_ready=!core_rst && source_state==SOURCE_WAIT;
    wire observer_done=!core_rst && source_state==OBSERVE_BITS && bit_index==0;
    logic [4:0] next_kind;logic [399:0] next_payload;logic [175:0] next_identity;logic [31:0] next_crc;
    logic [9:0] gx_magnitude,gy_magnitude;logic [17:0] dx_magnitude,dy_magnitude;logic [10:0] x,y;
    angle_core arithmetic(.clk(clk_25m),.rst(core_rst),.req_valid(req_valid),.req_body(request_slot),.req_ready(req_ready),
        .rsp_valid(rsp_valid),.rsp_body(rsp_body),.rsp_ready(rsp_ready),.cancel_valid(1'b0),.cancel_id(176'd0),.quiet(core_quiet));
    assign led1=rolling_crc[0];
    always_comb begin
        case(source_sequence[1:0])0:next_kind=8;1:next_kind=9;2:next_kind=10;default:next_kind=16;endcase
        gx_magnitude=source_lfsr[9:0]>1020?10'd1020:source_lfsr[9:0];gy_magnitude=source_lfsr[19:10]>1020?10'd1020:source_lfsr[19:10];
        if(gx_magnitude==0 && gy_magnitude==0)gx_magnitude=1;
        dx_magnitude=source_lfsr[17:0];dy_magnitude=source_lfsr[35:18];if(dx_magnitude==0 && dy_magnitude==0)dx_magnitude=1;
        x=source_lfsr[10:0]>=1920?source_lfsr[10:0]-11'd1920:source_lfsr[10:0];
        y=source_lfsr[21:11]>=1080?source_lfsr[21:11]-11'd1080:source_lfsr[21:11];
        next_payload=0;
        case(next_kind)
            8:begin
                next_payload[0+:11]=source_lfsr[20]?-$signed({1'b0,gx_magnitude}):$signed({1'b0,gx_magnitude});
                next_payload[11+:11]=source_lfsr[21]?-$signed({1'b0,gy_magnitude}):$signed({1'b0,gy_magnitude});
            end
            9:begin
                next_payload[0+:19]=source_lfsr[36]?-$signed({1'b0,dx_magnitude}):$signed({1'b0,dx_magnitude});
                next_payload[19+:19]=source_lfsr[37]?-$signed({1'b0,dy_magnitude}):$signed({1'b0,dy_magnitude});
            end
            10:begin next_payload[0+:11]=x;next_payload[11+:11]=y;next_payload[22+:9]=source_lfsr[30:22];end
            16:next_payload[0+:9]=source_lfsr[8:0];
            default:begin end
        endcase
        next_identity={{3'd0,next_kind},source_sequence,8'd0,32'd1,32'd0,32'd1};
        next_crc=rolling_crc<<1;if(rolling_crc[31]^response_shift[584])next_crc=next_crc^32'h04c11db7;
    end
    always_ff @(posedge clk_25m)begin
        if(core_rst)begin source_state<=SOURCE_EMPTY;source_lfsr<=192'd1;source_sequence<=0;sequence_exhausted<=0;rolling_crc<=32'hffffffff;led0<=0;end
        else case(source_state)
            SOURCE_EMPTY:begin request_slot<={next_payload,9'd0,2'd0,next_kind,8'd1,11'd1080,11'd1920,next_identity};source_state<=SOURCE_OFFER;end
            SOURCE_OFFER:if(req_ready)begin
                source_lfsr<={source_lfsr[190:0],source_lfsr[191]^source_lfsr[190]^source_lfsr[187]^source_lfsr[185]};
                if(&source_sequence)sequence_exhausted<=1;else source_sequence<=source_sequence+64'd1;source_state<=SOURCE_WAIT;
            end
            SOURCE_WAIT:if(rsp_valid)begin response_shift<=rsp_body;bit_index<=584;source_state<=OBSERVE_BITS;if(request_slot[104+:10]==1023)led0<=!led0;end
            OBSERVE_BITS:begin rolling_crc<=next_crc;response_shift<=response_shift<<1;if(observer_done)source_state<=OBSERVE_DONE;else bit_index<=bit_index-10'd1;end
            OBSERVE_DONE:if(core_quiet)source_state<=sequence_exhausted?SOURCE_STOP:SOURCE_EMPTY;
            SOURCE_STOP:source_state<=SOURCE_STOP;
            default:source_state<=SOURCE_STOP;
        endcase
    end
endmodule
