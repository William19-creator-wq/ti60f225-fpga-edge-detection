// 单seed全域HIST与两路线峰；距离/normal由父协调器实际计算，不把seed当圆结果。
// 物理读reply先复制到一块32x16缓存再归还，HIST RMW则借原reply完成八字PACK。
module board_circle_histogram #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter [32:0] ADDRESS_BYTES=33'h10000000,
    parameter bit BORROW_SCOPE=1'b0
)(
    input wire clk,rst,start,
    input wire [95:0] scope,
    input wire [7:0] seed_ordinal,
    input wire [20:0] points,minimum_peak_votes,
    input wire [31:0] point_base,hist_base,raw_peak_base,smooth_peak_base,meta_base,
    output wire start_ready,done,
    output reg fault,quarantined,
    output reg [20:0] votes,
    output reg [9:0] raw_count,smooth_count,
    output reg [16:0] raw_first,raw_last,smooth_first,smooth_last,
    output wire eval_req_valid,input wire eval_req_ready,
    output wire [63:0] eval_req_point,
    output wire [20:0] eval_req_ordinal,
    input wire eval_rsp_valid,output wire eval_rsp_ready,
    input wire [17:0] eval_radius,
    input wire eval_normal_ok,eval_error,eval_drained,
    output wire req_valid,input wire req_ready,
    output wire req_write,output wire [31:0] req_addr,
    input wire rsp_valid,output wire rsp_ready,
    input wire [511:0] rsp_data,input wire rsp_error,rsp_drained,
    output wire pack_valid,output wire [2:0] pack_index,
    output wire [63:0] pack_data
);
    localparam integer PIXELS=WIDTH*HEIGHT;
    localparam [5:0] IDLE=0,CLEAR_PREP=1,PACK=2,WRITE_REQUEST=3,WRITE_WAIT=4,
        READ_REQUEST=5,READ_WAIT=6,CACHE_COPY=7,POINT_READ=8,POINT_CAPTURE=9,
        POINT_CHECK=10,EVAL_REQUEST=11,EVAL_WAIT=12,HIST_VALIDATE=13,
        POINT_ADVANCE=14,SCAN_INIT=15,HIST_LOW_READ=16,HIST_LOW_CAPTURE=17,
        HIST_HIGH_READ=18,HIST_HIGH_CAPTURE=19,RING_READ=20,RING_CAPTURE=21,
        RING_WRITE=22,RING_CALC=23,PEAK_EVAL=24,PEAK_SELECT=25,
        FEED_ADVANCE=26,PAD_FEED=27,SCAN_FINISH=28,META_PREP=29,
        FINAL_QUIET=30,COMPLETE=31,READ_DISCARD=32,FAILED=33,QUARANTINE=34;
    localparam [1:0] READ_POINT=0,READ_HIST_RMW=1,READ_HIST_SCAN=2;
    localparam [1:0] PACK_ZERO=0,PACK_HIST=1,PACK_PEAK=2,PACK_META=3;
    localparam [2:0] WRITE_CLEAR=0,WRITE_HIST=1,WRITE_RAW=2,WRITE_SMOOTH=3,WRITE_META=4;
    reg [5:0] state;
    reg [1:0] read_kind,pack_kind;
    reg [2:0] write_kind,pack_slot;
    reg [31:0] locked_point_base,locked_hist_base,locked_raw_base,locked_smooth_base,locked_meta_base;
    reg [31:0] request_address;
    reg [20:0] point_limit,peak_min,ordinal;
    reg [7:0] locked_seed;
    wire [95:0] locked_scope;
    generate if(BORROW_SCOPE)begin:borrow_scope
        // 父保持同scope/seed到完整终态；本模块只在META时使用scope。
        assign locked_scope=scope;
    end else begin:copy_scope
        reg [95:0] snapshot;
        assign locked_scope=snapshot;
        always @(posedge clk)if(rst)snapshot<=0;
            else if(start&&start_ready)snapshot<=scope;
    end endgenerate

    reg [13:0] clear_block;
    reg [4:0] copy_word;
    reg copy_bad;
    reg [2:0] point_lane;
    reg [1:0] point_piece;
    reg [63:0] point_word;
    reg [10:0] previous_x,previous_y;
    reg previous_valid;
    reg [16:0] vote_radius;
    reg [3:0] validate_index;
    reg [20:0] next_bin_count;
    reg [3:0] hist_lane;
    reg [15:0] hist_low;
    reg [20:0] histogram_sum;
    reg [17:0] hist_bins,feed_n,feed_count;
    reg [4:0] ring_write_address;
    reg [1:0] ring_read_index;
    reg [20:0] raw_current,old_raw[0:3];
    reg [20:0] smooth_prevprev,smooth_prev,smooth_next;
    reg raw_active,smooth_active;
    reg [20:0] raw_height,smooth_height;
    reg [16:0] raw_start_radius,smooth_start_radius;
    reg [20:0] raw_start_raw,raw_start_window,smooth_start_raw,smooth_start_window;
    reg raw_pending,smooth_pending;
    reg [63:0] raw_record,smooth_record;

    wire [32:0] padded_points={12'd0,points}+33'd7;
    wire [32:0] point_end={1'b0,point_base}+((padded_points>>3)<<6);
    wire [32:0] hist_end={1'b0,hist_base}+33'd524288;
    wire [32:0] raw_end={1'b0,raw_peak_base}+33'd32768;
    wire [32:0] smooth_end={1'b0,smooth_peak_base}+33'd32768;
    wire [32:0] meta_end={1'b0,meta_base}+33'd64;
    function automatic apart(input [31:0] a,b,input [32:0] ae,be);
        apart=ae<={1'b0,b}||be<={1'b0,a};
    endfunction
    wire legal_start=WIDTH>=6&&WIDTH<=1920&&WIDTH%2==0&&HEIGHT>=5&&HEIGHT<=1080&&
        ADDRESS_BYTES>=33'd64&&ADDRESS_BYTES<=33'h100000000&&points<=PIXELS&&
        minimum_peak_votes!=0&&minimum_peak_votes<=PIXELS&&
        point_base[5:0]==0&&hist_base[5:0]==0&&raw_peak_base[5:0]==0&&
        smooth_peak_base[5:0]==0&&meta_base[5:0]==0&&
        point_end<=ADDRESS_BYTES&&hist_end<=ADDRESS_BYTES&&raw_end<=ADDRESS_BYTES&&
        smooth_end<=ADDRESS_BYTES&&meta_end<=ADDRESS_BYTES&&
        (points==0||(apart(point_base,hist_base,point_end,hist_end)&&
        apart(point_base,raw_peak_base,point_end,raw_end)&&
        apart(point_base,smooth_peak_base,point_end,smooth_end)&&
        apart(point_base,meta_base,point_end,meta_end)))&&
        apart(hist_base,raw_peak_base,hist_end,raw_end)&&
        apart(hist_base,smooth_peak_base,hist_end,smooth_end)&&
        apart(hist_base,meta_base,hist_end,meta_end)&&
        apart(raw_peak_base,smooth_peak_base,raw_end,smooth_end)&&
        apart(raw_peak_base,meta_base,raw_end,meta_end)&&
        apart(smooth_peak_base,meta_base,smooth_end,meta_end);

    wire [10:0] point_x=point_word[42:32],point_y=point_word[53:43];
    wire signed [10:0] point_gx=point_word[10:0],point_gy=point_word[21:11];
    wire [10:0] abs_gx=point_gx[10]?-point_gx:point_gx;
    wire [10:0] abs_gy=point_gy[10]?-point_gy:point_gy;
    wire point_legal=point_word[63]==0&&point_word[31:24]==0&&
        point_x<WIDTH&&point_y<HEIGHT&&point_word[21:0]!=0&&
        point_gx>=-11'sd1020&&point_gx<=11'sd1020&&
        point_gy>=-11'sd1020&&point_gy<=11'sd1020&&
        ({1'b0,abs_gx}+{1'b0,abs_gy})<=12'd1530&&
        (!previous_valid||point_y>previous_y||(point_y==previous_y&&point_x>previous_x));
    wire [21:0] ordinal_next={1'b0,ordinal}+22'd1;
    wire [20:0] point_block_first={ordinal[20:3],3'd0};
    wire [21:0] copied_point={1'b0,point_block_first}+{19'd0,copy_word[4:2]};
    wire [15:0] copy_data=rsp_data[copy_word*16+:16];
    wire copy_padding_bad=read_kind==READ_POINT&&copied_point>={1'b0,point_limit}&&copy_data!=0;

    // 同一缓存的COPY和RE不会同拍；read沿更新q，下一CAPTURE才消费。
    wire cache_write=!rst&&state==CACHE_COPY&&rsp_valid&&!rsp_error&&rsp_drained;
    wire cache_read=!rst&&(state==POINT_READ||state==HIST_LOW_READ||state==HIST_HIGH_READ);
    wire [8:0] cache_read_address=state==POINT_READ?{4'd0,point_lane,point_piece}:
        {4'd0,hist_lane,state==HIST_HIGH_READ};
    wire [15:0] cache_q;
    queue_ram16_1r1w shared_block_cache(.clk,.re(cache_read),.we(cache_write),
        .read_address(cache_read_address),.write_address({4'd0,copy_word}),.data(copy_data),.q(cache_q));
    wire [31:0] scanned_bin={cache_q,hist_low};
    wire [21:0] next_histogram_sum={1'b0,histogram_sum}+{1'b0,scanned_bin[20:0]};
    wire [31:0] checked_bin=rsp_data[validate_index*32+:32];
    wire [21:0] incremented_bin={1'b0,checked_bin[20:0]}+22'd1;

    function automatic [4:0] read_offset(input [1:0] index);
        case(index)0:read_offset=17;1:read_offset=10;2:read_offset=9;default:read_offset=8;endcase
    endfunction
    wire [4:0] offset=read_offset(ring_read_index);
    wire ring_history_valid=feed_n>={13'd0,offset};
    wire [4:0] ring_read_address=ring_write_address>=offset?
        ring_write_address-offset:ring_write_address+(5'd19-offset);
    wire ring_re=!rst&&state==RING_READ&&ring_history_valid;
    wire ring_we=!rst&&state==RING_WRITE;
    wire [15:0] ring_q_low,ring_q_high;
    queue_ram16_1r1w ring_low(.clk,.re(ring_re),.we(ring_we),
        .read_address({4'd0,ring_read_address}),.write_address({4'd0,ring_write_address}),
        .data(raw_current[15:0]),.q(ring_q_low));
    queue_ram16_1r1w ring_high(.clk,.re(ring_re),.we(ring_we),
        .read_address({4'd0,ring_read_address}),.write_address({4'd0,ring_write_address}),
        .data({11'd0,raw_current[20:16]}),.q(ring_q_high));
    wire [20:0] ring_old_value={ring_q_high[4:0],ring_q_low};
    wire [22:0] smooth_add={2'd0,smooth_prev}+{2'd0,raw_current};
    wire [22:0] smooth_result=smooth_add-{2'd0,old_raw[0]};

    wire legal_target=feed_n>=18'd10&&feed_n<=18'd131080;
    wire [17:0] target_wide=feed_n-18'd9;
    wire [16:0] target_radius=target_wide[16:0];
    wire [20:0] raw_left=target_radius==1?21'd0:old_raw[1];
    wire [20:0] raw_cur=old_raw[2];
    wire [20:0] raw_right=target_radius == 17'h1ffff ? 21'd0 : old_raw[3];
    wire [20:0] smooth_left=target_radius==1?21'd0:smooth_prevprev;
    wire [20:0] smooth_cur=smooth_prev;
    wire [20:0] smooth_right=target_radius == 17'h1ffff ? 21'd0 : smooth_next;
    wire raw_new=raw_cur>raw_left&&raw_cur!=0;
    wire smooth_new=smooth_cur>smooth_left&&smooth_cur!=0;
    wire raw_continuation=raw_active&&raw_height==raw_cur&&raw_cur==raw_left;
    wire smooth_continuation=smooth_active&&smooth_height==smooth_cur&&smooth_cur==smooth_left;
    wire raw_peak=legal_target&&(raw_new||raw_continuation)&&raw_cur>=peak_min&&raw_right<raw_cur;
    wire smooth_peak=legal_target&&(smooth_new||smooth_continuation)&&smooth_cur>=peak_min&&smooth_right<smooth_cur;
    wire [63:0] next_raw_record={3'd0,2'd0,
        (raw_new?smooth_cur:raw_start_window),(raw_new?raw_cur:raw_start_raw),
        (raw_new?target_radius:raw_start_radius)};
    wire [63:0] next_smooth_record={3'd0,2'd1,
        (smooth_new?smooth_cur:smooth_start_window),(smooth_new?raw_cur:smooth_start_raw),
        (smooth_new?target_radius:smooth_start_radius)};

    wire rmw_pack=state==PACK&&pack_kind==PACK_HIST;
    wire memory_reply_expected=state==READ_WAIT||state==CACHE_COPY||state==HIST_VALIDATE||
        state==READ_DISCARD||state==WRITE_WAIT||rmw_pack;
    wire unexpected_memory_reply=rsp_valid&&!memory_reply_expected;
    wire unexpected_eval_reply=eval_rsp_valid&&state!=EVAL_WAIT;
    assign start_ready=!rst&&(state==IDLE||state==COMPLETE)&&!rsp_valid&&!eval_rsp_valid;
    assign done=!rst&&state==COMPLETE;
    assign eval_req_valid=!rst&&state==EVAL_REQUEST;
    assign eval_req_point=point_word;
    assign eval_req_ordinal=ordinal;
    assign eval_rsp_ready=!rst&&state==EVAL_WAIT;
    assign req_valid=!rst&&(state==READ_REQUEST||state==WRITE_REQUEST);
    assign req_write=state==WRITE_REQUEST;
    assign req_addr=request_address;
    assign rsp_ready=!rst&&(state==WRITE_WAIT||state==READ_DISCARD||
        (state==READ_WAIT&&(rsp_error||!rsp_drained))||
        (state==CACHE_COPY&&(copy_word==31||rsp_error||!rsp_drained))||
        (rmw_pack&&(pack_slot==7||rsp_error||!rsp_drained)));
    assign pack_valid=!rst&&state==PACK&&
        (pack_kind!=PACK_HIST||(rsp_valid&&!rsp_error&&rsp_drained));
    assign pack_index=pack_slot;

    reg [511:0] metadata;
    reg [63:0] selected_pack_word;
    wire [63:0] hist_pack_word=rsp_data[pack_slot*64+:64];
    always @*begin
        metadata=0;
        metadata[95:0]=locked_scope;metadata[103:96]=locked_seed;
        metadata[124:104]=point_limit;metadata[145:125]=votes;
        metadata[155:146]=raw_count;metadata[165:156]=smooth_count;
        metadata[182:166]=raw_first;metadata[199:183]=raw_last;
        metadata[216:200]=smooth_first;metadata[233:217]=smooth_last;
        metadata[251:234]=feed_count;metadata[269:252]=hist_bins;
        metadata[280:270]=11'(WIDTH);metadata[291:281]=11'(HEIGHT);
        metadata[299:292]=8'd1;metadata[300]=1'b1;
        selected_pack_word=0;
        case(pack_kind)
            PACK_HIST:begin
                selected_pack_word=hist_pack_word;
                if(pack_slot==vote_radius[3:1])begin
                    if(vote_radius[0])selected_pack_word[63:32]={11'd0,next_bin_count};
                    else selected_pack_word[31:0]={11'd0,next_bin_count};
                end
            end
            PACK_PEAK:selected_pack_word=pack_slot==0?
                (write_kind==WRITE_RAW?raw_record:smooth_record):64'd0;
            PACK_META:selected_pack_word=metadata[pack_slot*64+:64];
            default:begin end
        endcase
    end
    assign pack_data=selected_pack_word;

    integer i;
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;fault<=0;quarantined<=0;read_kind<=READ_POINT;
            pack_kind<=PACK_ZERO;write_kind<=WRITE_CLEAR;pack_slot<=0;request_address<=0;
            locked_point_base<=0;locked_hist_base<=0;locked_raw_base<=0;locked_smooth_base<=0;locked_meta_base<=0;
            point_limit<=0;peak_min<=0;locked_seed<=0;ordinal<=0;clear_block<=0;
            copy_word<=0;copy_bad<=0;point_lane<=0;point_piece<=0;previous_valid<=0;
            vote_radius<=0;validate_index<=0;next_bin_count<=0;hist_lane<=0;
            histogram_sum<=0;hist_bins<=0;feed_n<=0;feed_count<=0;ring_write_address<=0;ring_read_index<=0;
            smooth_prevprev<=0;smooth_prev<=0;smooth_next<=0;raw_current<=0;
            raw_active<=0;smooth_active<=0;raw_pending<=0;smooth_pending<=0;
            votes<=0;raw_count<=0;smooth_count<=0;raw_first<=0;raw_last<=0;smooth_first<=0;smooth_last<=0;
            for(i=0;i<4;i=i+1)old_raw[i]<=0;
        end else if(state==FAILED||state==QUARANTINE)begin
            // FAILED/Q不再接受seed；未知事务不能因late reply被本地猜成已排空。
        end else if(unexpected_memory_reply||unexpected_eval_reply)begin
            fault<=1;quarantined<=1;state<=QUARANTINE;
        end else if(start&&start_ready)begin
            locked_point_base<=point_base;locked_hist_base<=hist_base;locked_raw_base<=raw_peak_base;
            locked_smooth_base<=smooth_peak_base;locked_meta_base<=meta_base;
            locked_seed<=seed_ordinal;point_limit<=points;peak_min<=minimum_peak_votes;
            votes<=0;raw_count<=0;smooth_count<=0;raw_first<=0;raw_last<=0;smooth_first<=0;smooth_last<=0;
            ordinal<=0;clear_block<=0;previous_valid<=0;raw_pending<=0;smooth_pending<=0;
            raw_active<=0;smooth_active<=0;fault<=0;quarantined<=0;
            if(!legal_start)begin fault<=1;state<=FAILED;end
            else state<=CLEAR_PREP;
        end else case(state)
            CLEAR_PREP:begin
                request_address<=locked_hist_base+{12'd0,clear_block,6'd0};
                pack_kind<=PACK_ZERO;write_kind<=WRITE_CLEAR;pack_slot<=0;state<=PACK;
            end
            PACK:begin
                if(pack_kind==PACK_HIST&&rsp_valid&&(rsp_error||!rsp_drained))begin
                    fault<=1;quarantined<=!rsp_drained;state<=rsp_drained?FAILED:QUARANTINE;
                end else if(pack_valid)begin
                    // 最后PACK沿仍借read reply；消费后下一WRITE_REQUEST状态才提出写。
                    if(pack_slot==7)state<=WRITE_REQUEST;
                    else pack_slot<=pack_slot+3'd1;
                end
            end
            WRITE_REQUEST:if(req_valid&&req_ready)state<=WRITE_WAIT;
            WRITE_WAIT:if(rsp_valid&&rsp_ready)begin
                if(rsp_error||!rsp_drained)begin
                    fault<=1;quarantined<=!rsp_drained;state<=rsp_drained?FAILED:QUARANTINE;
                end else case(write_kind)
                    WRITE_CLEAR:begin
                        if(clear_block==14'd8191)begin
                            if(point_limit==0)state<=SCAN_INIT;
                            else begin request_address<=locked_point_base;read_kind<=READ_POINT;state<=READ_REQUEST;end
                        end else begin clear_block<=clear_block+14'd1;state<=CLEAR_PREP;end
                    end
                    WRITE_HIST:begin votes<=votes+21'd1;state<=POINT_ADVANCE;end
                    WRITE_RAW:begin
                        if(raw_count==0)raw_first<=raw_record[16:0];
                        raw_last<=raw_record[16:0];raw_count<=raw_count+10'd1;
                        raw_pending<=0;state<=PEAK_SELECT;
                    end
                    WRITE_SMOOTH:begin
                        if(smooth_count==0)smooth_first<=smooth_record[16:0];
                        smooth_last<=smooth_record[16:0];smooth_count<=smooth_count+10'd1;
                        smooth_pending<=0;state<=PEAK_SELECT;
                    end
                    WRITE_META:state<=FINAL_QUIET;
                    default:begin fault<=1;state<=FAILED;end
                endcase
            end
            READ_REQUEST:if(req_valid&&req_ready)state<=READ_WAIT;
            READ_WAIT:if(rsp_valid)begin
                if(rsp_error||!rsp_drained)begin
                    fault<=1;quarantined<=!rsp_drained;state<=rsp_drained?FAILED:QUARANTINE;
                end else if(read_kind==READ_HIST_RMW)begin validate_index<=0;state<=HIST_VALIDATE;end
                else begin copy_word<=0;copy_bad<=0;state<=CACHE_COPY;end
            end
            CACHE_COPY:if(rsp_valid)begin
                if(rsp_error||!rsp_drained)begin
                    fault<=1;quarantined<=!rsp_drained;state<=rsp_drained?FAILED:QUARANTINE;
                end else begin
                    if(copy_padding_bad)copy_bad<=1;
                    if(copy_word==31)begin
                        // 末word的WE与reply消费同沿；后续状态才RE，不用同址碰撞结果。
                        if(copy_bad||copy_padding_bad)begin fault<=1;state<=FAILED;end
                        else if(read_kind==READ_POINT)begin
                            point_lane<=ordinal[2:0];point_piece<=0;state<=POINT_READ;
                        end else begin hist_lane<=0;state<=HIST_LOW_READ;end
                    end else copy_word<=copy_word+5'd1;
                end
            end
            POINT_READ:state<=POINT_CAPTURE;
            POINT_CAPTURE:begin
                point_word<={cache_q,point_word[63:16]};
                if(point_piece==3)state<=POINT_CHECK;
                else begin point_piece<=point_piece+2'd1;state<=POINT_READ;end
            end
            POINT_CHECK:begin
                if(ordinal>=point_limit||!point_legal)begin fault<=1;state<=FAILED;end
                else begin previous_x<=point_x;previous_y<=point_y;previous_valid<=1;state<=EVAL_REQUEST;end
            end
            EVAL_REQUEST:if(eval_req_valid&&eval_req_ready)state<=EVAL_WAIT;
            EVAL_WAIT:if(eval_rsp_valid&&eval_rsp_ready)begin
                if(eval_error||!eval_drained)begin
                    fault<=1;quarantined<=!eval_drained;state<=eval_drained?FAILED:QUARANTINE;
                end else if(eval_normal_ok&&eval_radius!=0&&eval_radius<=18'd131071)begin
                    vote_radius<=eval_radius[16:0];
                    request_address<=locked_hist_base+{13'd0,eval_radius[16:4],6'd0};
                    read_kind<=READ_HIST_RMW;state<=READ_REQUEST;
                end else state<=POINT_ADVANCE;
            end
            HIST_VALIDATE:if(rsp_valid)begin
                if(rsp_error||!rsp_drained)begin fault<=1;state<=READ_DISCARD;end
                else if(checked_bin[31:21]!=0||checked_bin[20:0]>point_limit||
                    (validate_index==vote_radius[3:0]&&incremented_bin>{1'b0,point_limit}))begin
                    fault<=1;state<=READ_DISCARD;
                end else begin
                    if(validate_index==vote_radius[3:0])next_bin_count<=incremented_bin[20:0];
                    if(validate_index==15)begin pack_kind<=PACK_HIST;write_kind<=WRITE_HIST;pack_slot<=0;state<=PACK;end
                    else validate_index<=validate_index+4'd1;
                end
            end
            READ_DISCARD:if(rsp_valid&&rsp_ready)begin
                quarantined<=!rsp_drained;state<=rsp_drained?FAILED:QUARANTINE;
            end
            POINT_ADVANCE:begin
                if(ordinal>=point_limit||ordinal_next[21])begin fault<=1;state<=FAILED;end
                else begin
                    ordinal<=ordinal_next[20:0];
                    if(ordinal_next=={1'b0,point_limit})state<=SCAN_INIT;
                    else if(ordinal[2:0]==7)begin
                        request_address<=locked_point_base+{8'd0,ordinal_next[20:3],6'd0};
                        read_kind<=READ_POINT;state<=READ_REQUEST;
                    end else begin point_lane<=point_lane+3'd1;point_piece<=0;state<=POINT_READ;end
                end
            end
            SCAN_INIT:begin
                // 每seed重建读资格；旧RAM不全清，n<offset的历史由真实域外零提供。
                histogram_sum<=0;hist_bins<=0;feed_n<=0;feed_count<=0;ring_write_address<=0;
                smooth_prevprev<=0;smooth_prev<=0;smooth_next<=0;raw_active<=0;smooth_active<=0;
                raw_pending<=0;smooth_pending<=0;request_address<=locked_hist_base;
                read_kind<=READ_HIST_SCAN;state<=READ_REQUEST;
            end
            HIST_LOW_READ:state<=HIST_LOW_CAPTURE;
            HIST_LOW_CAPTURE:begin hist_low<=cache_q;state<=HIST_HIGH_READ;end
            HIST_HIGH_READ:state<=HIST_HIGH_CAPTURE;
            HIST_HIGH_CAPTURE:begin
                if(feed_n>18'd131071||scanned_bin[31:21]!=0||scanned_bin[20:0]>point_limit||
                    (feed_n==0&&scanned_bin!=0)||next_histogram_sum>{1'b0,votes})begin
                    fault<=1;state<=FAILED;
                end else begin
                    histogram_sum<=next_histogram_sum[20:0];hist_bins<=hist_bins+18'd1;
                    raw_current<=scanned_bin[20:0];ring_read_index<=0;state<=RING_READ;
                end
            end
            PAD_FEED:begin raw_current<=0;ring_read_index<=0;state<=RING_READ;end
            RING_READ:state<=RING_CAPTURE;
            RING_CAPTURE:begin
                if(ring_history_valid&&ring_q_high[15:5]!=0)begin fault<=1;state<=FAILED;end
                else begin
                    old_raw[ring_read_index]<=ring_history_valid?ring_old_value:21'd0;
                    if(ring_read_index==3)state<=RING_WRITE;
                    else begin ring_read_index<=ring_read_index+2'd1;state<=RING_READ;end
                end
            end
            RING_WRITE:state<=RING_CALC;
            RING_CALC:begin
                if(smooth_add<{2'd0,old_raw[0]}||smooth_result>{2'd0,point_limit})begin
                    fault<=1;state<=FAILED;
                end else begin smooth_next<=smooth_result[20:0];state<=PEAK_EVAL;end
            end
            PEAK_EVAL:begin
                if(raw_pending||smooth_pending||
                    (raw_peak&&raw_count==10'd512)||(smooth_peak&&smooth_count==10'd512))begin
                    fault<=1;state<=FAILED;
                end else if(!legal_target)state<=FEED_ADVANCE;
                else begin
                    if(raw_new)begin
                        raw_height<=raw_cur;raw_start_radius<=target_radius;
                        raw_start_raw<=raw_cur;raw_start_window<=smooth_cur;
                    end
                    if(smooth_new)begin
                        smooth_height<=smooth_cur;smooth_start_radius<=target_radius;
                        smooth_start_raw<=raw_cur;smooth_start_window<=smooth_cur;
                    end
                    raw_active<=(raw_new||raw_continuation)&&!raw_peak;
                    smooth_active<=(smooth_new||smooth_continuation)&&!smooth_peak;
                    raw_pending<=raw_peak;smooth_pending<=smooth_peak;
                    if(raw_peak)raw_record<=next_raw_record;
                    if(smooth_peak)smooth_record<=next_smooth_record;
                    state<=(raw_peak||smooth_peak)?PEAK_SELECT:FEED_ADVANCE;
                end
            end
            PEAK_SELECT:begin
                if(raw_pending)begin
                    if(raw_count>=10'd512||(raw_count!=0&&raw_record[16:0]<=raw_last))begin fault<=1;state<=FAILED;end
                    else begin
                        request_address<=locked_raw_base+{16'd0,raw_count,6'd0};
                        write_kind<=WRITE_RAW;pack_kind<=PACK_PEAK;pack_slot<=0;state<=PACK;
                    end
                end else if(smooth_pending)begin
                    if(smooth_count>=10'd512||(smooth_count!=0&&smooth_record[16:0]<=smooth_last))begin fault<=1;state<=FAILED;end
                    else begin
                        request_address<=locked_smooth_base+{16'd0,smooth_count,6'd0};
                        write_kind<=WRITE_SMOOTH;pack_kind<=PACK_PEAK;pack_slot<=0;state<=PACK;
                    end
                end else state<=FEED_ADVANCE;
            end
            FEED_ADVANCE:begin
                if(raw_pending||smooth_pending)begin fault<=1;state<=FAILED;end
                else begin
                    // 仅这里推进一次feed，峰写停顿期间不重复WE或重喂本bin。
                    smooth_prevprev<=smooth_prev;smooth_prev<=smooth_next;
                    ring_write_address<=ring_write_address==18?5'd0:ring_write_address+5'd1;
                    feed_count<=feed_count+18'd1;
                    if(feed_n==18'd131080)state<=SCAN_FINISH;
                    else begin
                        feed_n<=feed_n+18'd1;
                        if(feed_n>=18'd131071)state<=PAD_FEED;
                        else if(feed_n[3:0]==15)begin
                            request_address<=locked_hist_base+((32'(feed_n)+32'd1)>>4<<6);
                            read_kind<=READ_HIST_SCAN;state<=READ_REQUEST;
                        end else begin hist_lane<=hist_lane+4'd1;state<=HIST_LOW_READ;end
                    end
                end
            end
            SCAN_FINISH:begin
                if(hist_bins!=18'd131072||feed_count!=18'd131081||histogram_sum!=votes||
                    ordinal!=point_limit||raw_pending||smooth_pending)begin fault<=1;state<=FAILED;end
                else state<=META_PREP;
            end
            META_PREP:begin
                request_address<=locked_meta_base;write_kind<=WRITE_META;
                pack_kind<=PACK_META;pack_slot<=0;state<=PACK;
            end
            FINAL_QUIET:state<=COMPLETE;
            IDLE,COMPLETE:begin end
            default:begin fault<=1;quarantined<=1;state<=QUARANTINE;end
        endcase
    end
endmodule
