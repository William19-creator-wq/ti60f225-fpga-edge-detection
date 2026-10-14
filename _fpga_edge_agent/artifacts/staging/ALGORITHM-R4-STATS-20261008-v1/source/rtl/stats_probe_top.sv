// ST-M03：一个来源槽→统计→唯一原FIT→一个共享响应字→真正585位CRC。
module stats_probe_top #(parameter logic [63:0] FIRST_SEQUENCE=64'd0)(
    input wire clk_25m,input wire key1_n,output wire led0,led1
);
    import stats_protocol_pkg::*;
    wire core_rst;
    reset_sync reset_adapter(.clk(clk_25m),.key1_n(key1_n),.core_rst(core_rst));
    typedef enum logic [2:0] {START_OFFER,POINT_OFFER,CLOSE_OFFER,WAIT_OBSERVATION,HALT} source_state_t;
    typedef enum logic [3:0] {STAT_WAIT,FIT_OFFER,FIT_WAIT,FIT_QUIET,OBS_OFFER,OBS_BITS} adapter_state_t;
    source_state_t source_phase;
    adapter_state_t adapter_state;
    logic [261:0] token_slot;
    logic [63:0] next_sequence,current_sequence;
    logic sequence_exhausted;
    logic [31:0] source_lfsr;
    logic [21:0] source_cursor;
    logic [10:0] source_x,source_y;
    logic [20:0] source_extent;
    logic [15:0] source_threshold;
    logic [621:0] request_slot;
    logic [584:0] response_word;
    logic protocol_fault;
    logic [31:0] rolling_crc;
    logic [9:0] bit_count;
    logic [23:0] heartbeat;
    wire token_valid=!core_rst && (source_phase==START_OFFER || source_phase==POINT_OFFER || source_phase==CLOSE_OFFER);
    wire token_ready,stat_valid,stats_quiet,fault_active;
    wire [7:0] fault_reason;
    wire [631:0] stat_body;
    wire stat_ready=!core_rst && adapter_state==STAT_WAIT && source_phase!=START_OFFER && source_phase!=HALT;
    wire fit_req_ready,fit_rsp_valid,fit_quiet;
    wire [584:0] fit_rsp_body;
    wire fit_req_valid=!core_rst && adapter_state==FIT_OFFER;
    wire fit_rsp_ready=!core_rst && adapter_state==FIT_WAIT;
    wire observer_ready=!core_rst && adapter_state!=OBS_BITS;
    wire observer_valid=!core_rst && adapter_state==OBS_OFFER;
    wire observer_done=!core_rst && adapter_state==OBS_BITS && bit_count==584;
    wire [31:0] advanced_lfsr={source_lfsr[30:0],source_lfsr[31]^source_lfsr[21]^source_lfsr[1]^source_lfsr[0]};
    wire [21:0] advanced_cursor=source_cursor+22'd1;
    logic [11:0] advanced_x_wide;
    logic [10:0] advanced_x,advanced_y;
    logic [31:0] next_crc;
    logic stat_matrix_ok,fit_matrix_ok;
    logic [621:0] expected_metadata;
    logic [83:0] expected_header;
    logic [399:0] stat_payload;
    integer used_bits;

    function automatic [4:0] source_kind(input logic [63:0] seq);
        case(seq[1:0]) 0:source_kind=11;1:source_kind=12;2:source_kind=17;default:source_kind=18;endcase
    endfunction
    function automatic [175:0] source_identity(input logic [63:0] seq);
        source_identity={8'd0,seq,8'd0,32'd1,32'd0,32'd1};
    endfunction
    function automatic [261:0] make_start(input logic [63:0] seq,input logic [31:0] lfsr);
        logic [83:0] h;
        begin
            h=0;h[0+:11]=(seq[3] && seq[1:0]==0)?11'd7:11'd1920;
            h[11+:11]=1080;h[22+:5]=source_kind(seq);h[27+:8]=1;h[51+:21]=21'd32+{12'd0,lfsr[8:0]};
            make_start=token(source_identity(seq),START,h);
        end
    endfunction
    function automatic [261:0] make_point(input logic [63:0] seq,input logic [21:0] ordinal,
        input logic [10:0] x,y,input logic [31:0] lfsr);
        logic [83:0] p;logic signed [11:0] gx,gy;
        begin
            p=0;gx=$signed({1'b0,x})-12'sd960;gy=$signed({1'b0,y})-12'sd540;
            p[0+:21]=ordinal[20:0];p[21]=lfsr[22] || ordinal<3;p[22+:11]=x;p[33+:11]=y;
            p[44+:11]=gx[10:0];p[55+:11]=gy[10:0];
            p[66]=seq[3] && seq[1:0]==2 && ordinal==2;
            make_point=token(source_identity(seq),POINT,p);
        end
    endfunction
    function automatic [261:0] make_close(input logic [63:0] seq,input logic [21:0] seen,input logic abort_job);
        logic [83:0] p;
        begin
            p=0;if(!abort_job) p[21:0]=seen+((seq[3] && seq[1:0]==1)?22'd1:22'd0);
            make_close=token(source_identity(seq),abort_job?ABORT_SCAN:END_SCAN,p);
        end
    endfunction

    stats_core statistics(.clk(clk_25m),.rst(core_rst),.token_valid(token_valid),.token_ready(token_ready),.token_body(token_slot),
        .stat_valid(stat_valid),.stat_ready(stat_ready),.stat_body(stat_body),.fault_active(fault_active),.fault_reason(fault_reason),.quiet(stats_quiet));
    fit_core fitting(.clk(clk_25m),.rst(core_rst),.req_valid(fit_req_valid),.req_ready(fit_req_ready),.req_body(request_slot),
        .rsp_valid(fit_rsp_valid),.rsp_ready(fit_rsp_ready),.rsp_body(fit_rsp_body),.cancel_valid(1'b0),.cancel_id(176'd0),.quiet(fit_quiet));
    assign led0=rolling_crc[7]^rolling_crc[23];
    assign led1=heartbeat[23];

    always_comb begin
        advanced_x_wide={1'b0,source_x}+12'd17;
        advanced_x=advanced_x_wide>=1920?(advanced_x_wide-12'd1920):advanced_x_wide[10:0];
        advanced_y=source_y+(advanced_x_wide>=1920?11'd1:11'd0);
        next_crc=rolling_crc<<1;
        if(rolling_crc[31]^response_word[584]) next_crc=next_crc^32'h04c11db7;
        expected_header=0;
        expected_header[0+:11]=(current_sequence[3] && current_sequence[1:0]==0)?11'd7:11'd1920;
        expected_header[11+:11]=1080;expected_header[22+:5]=source_kind(current_sequence);
        expected_header[27+:8]=1;expected_header[35+:16]=source_threshold;expected_header[51+:21]=source_extent;
        expected_metadata=pack_numeric(source_identity(current_sequence),expected_header,21'd0,56'sd0,56'sd0,56'sd0,56'sd0,56'sd0,1'b0);
        case(source_kind(current_sequence)) 11:used_bits=279;12:used_bits=233;17:used_bits=263;default:used_bits=217;endcase
        stat_payload=stat_body[222+:400];
        stat_matrix_ok=stat_body[221:0]==expected_metadata[221:0];
        case(stat_body[623:622])
            fit_protocol_pkg::VALUE:stat_matrix_ok=stat_matrix_ok && stat_body[631:624]==0 &&
                (stat_payload>>used_bits)==0 && stat_payload[20:0]<=source_extent;
            fit_protocol_pkg::FRAME_FAIL:stat_matrix_ok=stat_matrix_ok && stat_payload==0 &&
                (stat_body[631:624]==2 || stat_body[631:624]==3 || stat_body[631:624]==7 ||
                 stat_body[631:624]==8 || stat_body[631:624]==12 || stat_body[631:624]==13);
            fit_protocol_pkg::CANCEL_DROP:stat_matrix_ok=stat_matrix_ok && stat_payload==0 && stat_body[631:624]==0;
            default:stat_matrix_ok=0;
        endcase
        fit_matrix_ok=fit_rsp_body[175:0]==request_slot[175:0] && fit_rsp_body[176+:5]==request_slot[206+:5] && fit_rsp_body[181+:9]==0;
        case(fit_rsp_body[191:190])
            fit_protocol_pkg::VALUE:fit_matrix_ok=fit_matrix_ok && fit_rsp_body[199:192]==0;
            fit_protocol_pkg::LOCAL_REJECT:fit_matrix_ok=fit_matrix_ok && fit_rsp_body[584:200]==0 &&
                (fit_rsp_body[199:192]==4 || fit_rsp_body[199:192]==5 || fit_rsp_body[199:192]==6 || fit_rsp_body[199:192]==7);
            fit_protocol_pkg::FRAME_FAIL:fit_matrix_ok=fit_matrix_ok && fit_rsp_body[584:200]==0 &&
                (fit_rsp_body[199:192]==2 || fit_rsp_body[199:192]==3 || fit_rsp_body[199:192]==7 || fit_rsp_body[199:192]==8 ||
                 fit_rsp_body[199:192]==11 || fit_rsp_body[199:192]==12 || fit_rsp_body[199:192]==13);
            fit_protocol_pkg::CANCEL_DROP:fit_matrix_ok=fit_matrix_ok && fit_rsp_body[584:200]==0 && fit_rsp_body[199:192]==0;
            default:fit_matrix_ok=0;
        endcase
    end

    always_ff @(posedge clk_25m) begin
        if(core_rst) begin
            source_phase<=START_OFFER;token_slot<=make_start(FIRST_SEQUENCE,32'h43106025);
            next_sequence<=FIRST_SEQUENCE;current_sequence<=0;sequence_exhausted<=0;source_lfsr<=32'h43106025;
            source_cursor<=0;source_x<=0;source_y<=0;source_extent<=0;source_threshold<=0;
        end else case(source_phase)
            START_OFFER:if(token_ready) begin
                current_sequence<=next_sequence;source_extent<=token_slot[229+:21];source_threshold<=token_slot[213+:16];
                if(&next_sequence) sequence_exhausted<=1;else next_sequence<=next_sequence+64'd1;
                source_x<={1'b0,source_lfsr[9:0]};source_y<=source_lfsr[19:10]==540?11'd541:{1'b0,source_lfsr[19:10]};source_cursor<=0;
                token_slot<=make_point(next_sequence,22'd0,{1'b0,source_lfsr[9:0]},
                    source_lfsr[19:10]==540?11'd541:{1'b0,source_lfsr[19:10]},source_lfsr);source_phase<=POINT_OFFER;
            end
            POINT_OFFER:if(token_ready) begin
                source_lfsr<=advanced_lfsr;source_cursor<=advanced_cursor;source_x<=advanced_x;source_y<=advanced_y;
                if(fault_active || (current_sequence[3] && current_sequence[1:0]==3 && source_cursor==3)) begin
                    token_slot<=make_close(current_sequence,advanced_cursor,1'b1);source_phase<=CLOSE_OFFER;
                end else if(advanced_cursor>=source_extent) begin
                    token_slot<=make_close(current_sequence,advanced_cursor,1'b0);source_phase<=CLOSE_OFFER;
                end else token_slot<=make_point(current_sequence,advanced_cursor,advanced_x,advanced_y,advanced_lfsr);
            end
            CLOSE_OFFER:if(token_ready) source_phase<=WAIT_OBSERVATION;
            WAIT_OBSERVATION:if(observer_done) begin
                if(sequence_exhausted) source_phase<=HALT;
                else begin token_slot<=make_start(next_sequence,source_lfsr);source_phase<=START_OFFER;end
            end
            HALT:source_phase<=HALT;
            default:source_phase<=HALT;
        endcase
    end

    // response_word只由此块写：收到终态→持有→obs_fire移交→585沿移位。
    always_ff @(posedge clk_25m) begin
        if(core_rst) begin
            adapter_state<=STAT_WAIT;request_slot<=0;response_word<=0;protocol_fault<=0;
            rolling_crc<=32'hffffffff;bit_count<=0;heartbeat<=0;
        end else begin
            heartbeat<=heartbeat+24'd1;
            case(adapter_state)
                STAT_WAIT:if(stat_valid && stat_ready) begin
                    if(!stat_matrix_ok) begin
                        response_word<=fit_protocol_pkg::pack_response(expected_metadata,fit_protocol_pkg::FRAME_FAIL,fit_protocol_pkg::INTERNAL,385'd0);
                        protocol_fault<=1;adapter_state<=FIT_QUIET;
                    end else if(stat_body[623:622]==fit_protocol_pkg::VALUE) begin
                        request_slot<=stat_body[621:0];adapter_state<=FIT_OFFER;
                    end else begin
                        response_word<=fit_protocol_pkg::pack_response(stat_body[621:0],stat_body[623:622],stat_body[631:624],385'd0);
                        adapter_state<=FIT_QUIET;
                    end
                end
                FIT_OFFER:if(fit_req_ready) adapter_state<=FIT_WAIT;
                FIT_WAIT:if(fit_rsp_valid) begin
                    if(fit_matrix_ok) response_word<=fit_rsp_body;
                    else begin
                        response_word<=fit_protocol_pkg::pack_response(request_slot,fit_protocol_pkg::FRAME_FAIL,fit_protocol_pkg::INTERNAL,385'd0);protocol_fault<=1;
                    end
                    adapter_state<=FIT_QUIET;
                end
                FIT_QUIET:if(stats_quiet && fit_quiet) adapter_state<=OBS_OFFER;
                OBS_OFFER:if(observer_ready) begin bit_count<=0;adapter_state<=OBS_BITS;end
                OBS_BITS:begin
                    rolling_crc<=next_crc;response_word<=response_word<<1;
                    if(observer_done) adapter_state<=STAT_WAIT;else bit_count<=bit_count+10'd1;
                end
                default:begin protocol_fault<=1;adapter_state<=FIT_QUIET;end
            endcase
        end
    end
endmodule
