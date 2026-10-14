// FT08/FT-T10：实际七kind源→拟合→585位串行CRC。中文来源见验证附稿第4节。
module fit_probe_top(input wire clk_25m,input wire key1_n,output logic led0,output wire led1);
    import fit_protocol_pkg::*;
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
    logic [4:0] next_kind;
    logic [399:0] next_payload;
    logic [175:0] next_identity;
    logic [31:0] next_crc;
    logic [10:0] x,y,ax;
    logic [20:0] n;
    logic [5:0] g;
    logic [11:0] g2;
    logic [10:0] xc;
    logic [9:0] yc;
    logic [12:0] xy_sum,yx_sum;
    logic [24:0] d,f;
    logic [7:0] a,b_abs;
    logic signed [8:0] b;
    logic [16:0] a2,b2;
    logic signed [18:0] ab;

    function automatic [10:0] pixel(input logic [10:0] raw,input logic [10:0] limit);
        pixel=raw>=limit?raw-limit:raw;
    endfunction
    function automatic [31:0] raw_normal(input logic [31:0] raw);
        raw_normal=raw[31]?-{2'd0,raw[29:0]}:{2'd0,raw[29:0]};
    endfunction

    fit_core arithmetic(.clk(clk_25m),.rst(core_rst),.req_valid(req_valid),.req_ready(req_ready),.req_body(request_slot),
        .rsp_valid(rsp_valid),.rsp_ready(rsp_ready),.rsp_body(rsp_body),.cancel_valid(1'b0),.cancel_id(176'd0),.quiet(core_quiet));
    assign led1=rolling_crc[0];

    always_comb begin
        case(source_sequence[2:0])
            0:next_kind=11; 1:next_kind=12; 2:next_kind=13; 3,7:next_kind=14;
            4:next_kind=15; 5:next_kind=17; 6:next_kind=18;
            default:next_kind=11;
        endcase
        x=pixel(source_lfsr[10:0],11'd1920); y=pixel(source_lfsr[21:11],11'd1080);
        ax=x==1919?11'd1918:x;
        g={1'b0,source_lfsr[4:0]}+6'd1; g2={6'd0,g}*{6'd0,g};
        xc={1'b0,source_lfsr[14:5]}+11'd1; yc={1'b0,source_lfsr[23:15]}+10'd1;
        xy_sum=({2'd0,xc}<<1)+{3'd0,yc}; yx_sum={2'd0,xc}+({3'd0,yc}<<1);
        d={13'd0,g2}*{12'd0,xy_sum}; f={13'd0,g2}*{12'd0,yx_sum};
        a={1'b0,source_lfsr[5:0],1'b0}+8'd1; b_abs={1'b0,source_lfsr[11:6],1'b0}+8'd1;
        b=source_lfsr[12]?-$signed({1'b0,b_abs}):$signed({1'b0,b_abs});
        a2=({9'd0,a}*{9'd0,a})<<1; b2=({9'd0,b_abs}*{9'd0,b_abs})<<1;
        ab=($signed({11'd0,a})*$signed({{10{b[8]}},b}))<<<1;
        next_payload=0; n=source_lfsr[20:0];
        if(n>2073600) n=n-21'd2073600;
        if(source_sequence[3]) begin
            next_payload[383:0]=source_lfsr;
            case(next_kind)
                11,17:begin
                    next_payload[20:0]=n<3?21'd3:n;
                    if(next_kind==11) next_payload[399:279]=0; else next_payload[399:263]=0;
                end
                12,18:begin
                    next_payload[20:0]=n<2?21'd2:n;
                    if(next_kind==12) next_payload[399:233]=0; else next_payload[399:217]=0;
                end
                13:begin
                    next_payload[0+:32]=raw_normal(source_lfsr[0+:32]); next_payload[32+:32]=raw_normal(source_lfsr[32+:32]);
                    next_payload[82+:32]=raw_normal(source_lfsr[82+:32]); next_payload[114+:32]=raw_normal(source_lfsr[114+:32]);
                    next_payload[399:164]=0;
                end
                14:begin
                    next_payload[0+:32]=raw_normal(source_lfsr[0+:32]); next_payload[32+:32]=raw_normal(source_lfsr[32+:32]);
                    next_payload[82+:11]=pixel(source_lfsr[82+:11],11'd1920); next_payload[93+:11]=pixel(source_lfsr[93+:11],11'd1080);
                    next_payload[399:104]=0;
                end
                15:begin
                    next_payload[72+:11]=pixel(source_lfsr[72+:11],11'd1920); next_payload[83+:11]=pixel(source_lfsr[83+:11],11'd1080);
                    next_payload[399:94]=0;
                end
                default:next_payload=0;
            endcase
        end else case(next_kind)
            11,17:begin
                next_payload[0+:21]=3; next_payload[21+:43]={30'd0,g2,1'b0}; next_payload[64+:44]={32'd0,g2};
                next_payload[108+:43]={30'd0,g2,1'b0}; next_payload[151+:56]={31'd0,d}; next_payload[207+:56]={31'd0,f};
            end
            12,18:begin
                next_payload[0+:21]=2; next_payload[87+:43]={26'd0,a2}; next_payload[130+:43]={26'd0,b2};
                next_payload[173+:44]={{25{ab[18]}},ab};
            end
            13:begin
                next_payload[0+:32]=32'd1073741824; next_payload[64+:18]={3'd0,x,4'd0};
                next_payload[114+:32]=32'd1073741824; next_payload[146+:18]={3'd0,y,4'd0};
            end
            14:begin
                next_payload[0+:32]=32'd1073741824; next_payload[64+:18]={4'd0,source_lfsr[31:22],4'd0};
                next_payload[82+:11]=x; next_payload[93+:11]=y;
            end
            15:begin
                next_payload[0+:18]={3'd0,ax,4'd0}; next_payload[18+:18]={3'd0,y,4'd0};
                next_payload[36+:18]=({7'd0,ax}+18'd1)<<4; next_payload[54+:18]={3'd0,y,4'd0};
                next_payload[72+:11]=pixel(source_lfsr[42:32],11'd1920); next_payload[83+:11]=pixel(source_lfsr[53:43],11'd1080);
            end
            default:next_payload=0;
        endcase
        next_identity={{3'd0,next_kind},source_sequence,8'd0,32'd1,32'd0,32'd1};
        next_crc=rolling_crc<<1;
        if(rolling_crc[31]^response_shift[584]) next_crc=next_crc^32'h04c11db7;
    end

    always_ff @(posedge clk_25m) begin
        if(core_rst) begin
            source_state<=SOURCE_EMPTY; source_lfsr<=384'd1; source_sequence<=0;
            sequence_exhausted<=0; rolling_crc<=32'hffffffff; led0<=0;
        end else case(source_state)
            SOURCE_EMPTY:begin
                request_slot<={next_payload,9'd0,2'd0,next_kind,8'd1,11'd1080,11'd1920,next_identity}; source_state<=SOURCE_OFFER;
            end
            SOURCE_OFFER:if(req_ready) begin
                source_lfsr<={source_lfsr[382:0],source_lfsr[383]^source_lfsr[382]^source_lfsr[380]^source_lfsr[377]};
                if(&source_sequence) sequence_exhausted<=1; else source_sequence<=source_sequence+64'd1;
                source_state<=SOURCE_WAIT;
            end
            SOURCE_WAIT:if(rsp_valid) begin
                response_shift<=rsp_body; bit_index<=584; source_state<=OBSERVE_BITS;
                if(request_slot[104+:10]==10'h3ff) led0<=!led0;
            end
            OBSERVE_BITS:begin
                rolling_crc<=next_crc; response_shift<=response_shift<<1;
                if(bit_index==0) source_state<=OBSERVE_DONE; else bit_index<=bit_index-10'd1;
            end
            OBSERVE_DONE:source_state<=sequence_exhausted?SOURCE_STOP:SOURCE_EMPTY;
            SOURCE_STOP:source_state<=SOURCE_STOP;
            default:source_state<=SOURCE_STOP;
        endcase
    end
endmodule
