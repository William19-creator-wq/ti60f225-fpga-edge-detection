// CF01…05：全部 seed/RAW/SMOOTH 峰，串行 A/B/C/D/E 与冻结 CIRC。
// 外部真实 NUM/STATS/FIT/ANGLE lease 必须确认；候选文件未连接主板工程。
module board_circle_refine #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter [32:0] ADDRESS_BYTES=33'h10000000,
    parameter bit BORROW_SCOPE=1'b0,SHARED_RETURN_WORDS=1'b0,ENABLE_RADIUS_ONLY=1'b0,FAST_POINT_MATH=1'b0
)(
    input wire clk,rst,start,input wire [95:0] scope,input wire [20:0] points,input wire [8:0] seeds,
    input wire [31:0] point_base,seed_base,hist_base,raw_peak_base,smooth_peak_base,
    input wire [31:0] hist_meta_base,circ_base,circ_meta_base,
    output wire start_ready,done,output reg fault,quarantined,drained,output reg [10:0] circ_count,
    output reg [18:0] raw_visited,smooth_visited,output reg [31:0] local_rejected,duplicates,
    output reg [63:0] pm_calls,
    output wire req_valid,input wire req_ready,output wire req_write,output wire [31:0] req_addr,
    input wire rsp_valid,output wire rsp_ready,input wire [511:0] rsp_data,input wire rsp_error,rsp_drained,
    output wire pack_valid,output wire [2:0] pack_index,output wire [63:0] pack_data,
    // 0关闭、1 PM、2 CR、3既有FIT；父不能在借用未归还时切实际 owner。
    output wire [1:0] numeric_owner_request,input wire [1:0] numeric_owner_granted,
    output wire num_req_valid,input wire num_req_ready,output wire [621:0] num_req_body,
    input wire num_rsp_valid,output wire num_rsp_ready,input wire [584:0] num_rsp_body,
    input wire num_quiet,output wire [4:0] num_rsp_word_index,input wire [15:0] num_rsp_word16,
    output wire geometry_bind_valid,input wire geometry_bind_ready,
    output wire geometry_release_valid,input wire geometry_release_ready,
    output wire geometry_token_valid,input wire geometry_token_ready,output wire [261:0] geometry_token_body,
    input wire geometry_stat_valid,input wire [631:0] geometry_stat_body,output wire geometry_stat_ready,
    output wire geometry_fit_req_valid,input wire geometry_fit_req_ready,output wire [621:0] geometry_fit_req_body,
    input wire geometry_fit_rsp_valid,input wire [584:0] geometry_fit_rsp_body,output wire geometry_fit_rsp_ready,
    output wire geometry_cancel_valid,output wire [175:0] geometry_cancel_id,
    input wire geometry_stats_quiet,geometry_fit_quiet,geometry_fault,
    output wire angle_owner_request,input wire angle_owner_granted,
    output wire angle_req_valid,input wire angle_req_ready,output wire [621:0] angle_req_body,
    input wire angle_rsp_valid,output wire angle_rsp_ready,input wire [584:0] angle_rsp_body,input wire angle_quiet
);
    localparam IDLE=0,BIND=1,SEED_READ=2,SEED_WAIT=3,HIST_START=4,HIST_LIVE=5,
        HIST_PM_REQUEST=6,HIST_PM_WAIT=7,HIST_PM_CLOSE=8,HIST_PM_REPLY=9,HIST_META_READ=10,HIST_META_WAIT=11,
        PEAK_READ=12,PEAK_WAIT=13,PASS_PREP=14,STATS_START=15,POINT_READ=16,POINT_WAIT=17,POINT_CHECK=18,
        PM_REQUEST=19,PM_WAIT=20,PM_CLOSE=21,POINT_TOKEN=22,POINT_ADVANCE=23,POINT_PAD=24,POINT_CONSUME=25,
        END_SCAN=26,STAT_WAIT=27,FIT_REQUEST=28,FIT_WAIT=29,FIT_CLOSE=30,STAT_CONSUME=31,STAT_CLOSE=32,
        CR_REQUEST=33,CR_WAIT=34,CR_CLOSE=35,ANGLE_REQUEST=36,ANGLE_WAIT=37,ANGLE_CLOSE=38,
        POPCOUNT=39,DEDUP_READ=40,DEDUP_WAIT=41,RECORD_PACK=42,WRITE_REQUEST=43,WRITE_WAIT=44,
        CANDIDATE_NEXT=45,SEED_NEXT=46,META_PACK=47,RELEASE=48,FINAL_CLOSE=49,COMPLETE=50,
        FAIL_CLOSE=51,FAIL_ABORT=52,FAIL_STAT=53,FAIL_STAT_CLOSE=54,FAIL_DDR=55,FAIL_RELEASE=56,FAILED=57,QUARANTINE=58,FAIL_FINAL=59;
    reg [5:0] state;
    reg [1:0] numeric_owner;
    reg angle_owned,lease_owned,hist_owned,native_pending,stats_active,context_exhausted,angle_exhausted;
    reg [63:0] context_sequence,angle_sequence;
    wire [95:0] locked_scope;
    generate if(BORROW_SCOPE)begin:borrow_scope
        assign locked_scope=scope;
    end else begin:copy_scope
        reg [95:0] snapshot;
        assign locked_scope=snapshot;
        always @(posedge clk)if(rst)snapshot<=0;else if(start && start_ready)snapshot<=scope;
    end endgenerate
    reg [20:0] point_limit,ordinal,member_count,n_expected,eligible,support;
    reg [8:0] seed_limit;
    reg [31:0] locked_point_base,locked_seed_base,locked_hist_base,locked_raw_base,locked_smooth_base,
        locked_hist_meta_base,locked_circ_base,locked_circ_meta_base,address;
    reg [7:0] seed_index;
    reg route;
    reg [9:0] route_count,peak_index;
    reg [1:0] peak_part;
    reg [2:0] phase,pm_step,cr_purpose,pack_slot;
    reg [2:0] lane;
    reg signed [17:0] c0x,c0y,c1x,c1y,c2x,c2y;
    reg [16:0] r0,r1,r2;
    reg [17:0] lower_sum,upper_sum;
    reg has_lower,has_upper,point_member,pass_finished,reject_candidate,write_meta;
    reg [38:0] sum_distance;
    reg [52:0] sse;
    reg [63:0] sector_mask;
    reg [15:0] max_residual,fit_quality,score;
    reg positive_seen,negative_seen;
    reg [17:0] residual;
    reg [6:0] sector_count,pop_index;
    reg [10:0] dedup_index,previous_x,previous_y;
    reg previous_valid;
    reg [3:0] after_stat;
    reg pm_failed,cr_failed,cr_local,angle_failed,hist_eval_failed,fatal_pending;
    reg [63:0] previous_seed_rank;
    reg [52:0] previous_seed_key;
    reg previous_seed_valid;

    wire [175:0] context_id={8'hd1,context_sequence,8'd0,locked_scope};
    wire [175:0] angular_id={8'hc3,angle_sequence,8'd0,locked_scope};
    wire [63:0] point_word=rsp_data[lane*64+:64];
    wire signed [10:0] gx=point_word[10:0],gy=point_word[21:11];
    wire [10:0] ax=gx[10] ? -gx : gx,ay=gy[10] ? -gy : gy;
    wire point_legal=point_word[63]==0 && point_word[31:24]==0 && point_word[42:32]<WIDTH &&
        point_word[53:43]<HEIGHT && gx>=-11'sd1020 && gx<=11'sd1020 &&
        gy>=-11'sd1020 && gy<=11'sd1020 && point_word[21:0]!=0 &&
        ({1'b0,ax}+{1'b0,ay})<=12'd1530 && (!previous_valid ||
        point_word[53:43]>previous_y || (point_word[53:43]==previous_y && point_word[42:32]>previous_x));
    wire signed [18:0] radial_dx=$signed({4'd0,point_word[42:32],4'd0})-$signed({c2x[17],c2x});
    wire signed [18:0] radial_dy=$signed({4'd0,point_word[53:43],4'd0})-$signed({c2y[17],c2y});

    wire hist_start_ready,hist_done,hist_fault,hist_quarantined;
    wire [20:0] hist_votes;
    wire [9:0] hist_raw_count,hist_smooth_count;
    wire [16:0] hist_raw_first,hist_raw_last,hist_smooth_first,hist_smooth_last;
    wire hist_req_valid,hist_req_write,hist_rsp_ready,hist_pack_valid,hist_eval_req_valid,hist_eval_rsp_ready;
    wire [31:0] hist_req_addr;
    wire [2:0] hist_pack_index;
    wire [63:0] hist_pack_data,hist_eval_point;
    wire [20:0] hist_eval_ordinal;
    wire pm_req_ready,pm_rsp_valid,pm_quiet,pm_fault,pm_error,pm_drained,pm_normal;
    wire [17:0] pm_radius;
    wire [95:0] pm_scope;
    wire [7:0] pm_seed;
    wire [2:0] pm_pass;
    wire [20:0] pm_ordinal;
    wire pm_num_valid,pm_num_ready,pm_num_rsp_ready;
    wire [621:0] pm_num_body;
    wire [4:0] pm_num_word_index;
    wire cr_ready,cr_rsp_valid,cr_quiet,cr_fault,cr_error,cr_reject,cr_drained;
    wire [95:0] cr_value;
    wire [2:0] cr_response_op;
    wire [175:0] cr_response_id;
    wire cr_num_valid,cr_num_ready,cr_num_rsp_ready;
    wire [621:0] cr_num_body;
    wire [4:0] cr_num_word_index;
    reg [319:0] cr_command_data;
    wire pm_request=(state==HIST_PM_REQUEST || state==PM_REQUEST) && numeric_owner_granted==1 && pm_calls!=64'hffffffffffffffff;
    wire pm_response_ready=(state==HIST_PM_WAIT || state==PM_WAIT) && pm_scope==locked_scope &&
        pm_seed==seed_index && pm_pass==(hist_owned ? 3'd0 : phase) &&
        pm_ordinal==(hist_owned ? hist_eval_ordinal : ordinal);
    wire signed [17:0] pm_center_x=hist_owned ? c0x : phase==5 ? c2x :
        pm_step==0 ? c0x : pm_step==2 ? c2x : c1x;
    wire signed [17:0] pm_center_y=hist_owned ? c0y : phase==5 ? c2y :
        pm_step==0 ? c0y : pm_step==2 ? c2y : c1y;
    wire [15:0] pm_tolerance=phase==5 && !hist_owned ? 16'd6554 : 16'd13107;
    // 仅 B/c1、C/c0、D/c0、D/c2 不读 normal；phase/step 到 PM quiet 才改变。
    wire pm_radius_only=!hist_owned && ((phase==2 && pm_step==1) ||
        (phase==3 && pm_step==0) || (phase==4 && (pm_step==0 || pm_step==2)));
    wire [18:0] twice_radius={pm_radius,1'b0};
    wire in_partition=(!has_lower || twice_radius>{1'b0,lower_sum}) &&
        (!has_upper || twice_radius<={1'b0,upper_sum});
    wire [17:0] pm_target_radius=pm_step==0 ? {1'b0,r0} : {1'b0,r1};
    wire [18:0] wide_residual=pm_radius>=pm_target_radius ?
        {1'b0,pm_radius}-{1'b0,pm_target_radius} : {1'b0,pm_target_radius}-{1'b0,pm_radius};
    wire [18:0] final_residual=pm_radius>={1'b0,r2} ?
        {1'b0,pm_radius}-{2'd0,r2} : {2'd0,r2}-{1'b0,pm_radius};
    wire [21:0] next_members={1'b0,member_count}+22'd1;
    wire [39:0] next_distance={1'b0,sum_distance}+{22'd0,pm_radius};
    wire [53:0] next_sse={1'b0,sse}+{18'd0,cr_value[35:0]};

    assign numeric_owner_request=numeric_owner;
    assign angle_owner_request=angle_owned;
    assign num_req_valid=!rst && ((numeric_owner==1 && numeric_owner_granted==1 && pm_num_valid) ||
        (numeric_owner==2 && numeric_owner_granted==2 && cr_num_valid));
    assign num_req_body=numeric_owner==2 ? cr_num_body : pm_num_body;
    assign pm_num_ready=numeric_owner==1 && numeric_owner_granted==1 && num_req_ready;
    assign cr_num_ready=numeric_owner==2 && numeric_owner_granted==2 && num_req_ready;
    assign num_rsp_ready=numeric_owner==1 && numeric_owner_granted==1 ? pm_num_rsp_ready :
        numeric_owner==2 && numeric_owner_granted==2 ? cr_num_rsp_ready : 1'b0;
    assign num_rsp_word_index=numeric_owner==2 ? cr_num_word_index : pm_num_word_index;

    board_geometry_point_math #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.SHARED_RETURN_WORDS(SHARED_RETURN_WORDS),
        .ENABLE_RADIUS_ONLY(ENABLE_RADIUS_ONLY),.FAST_POINT_MATH(FAST_POINT_MATH)) point_math(
        .clk,.rst,.eval_req_valid(pm_request),.eval_req_ready(pm_req_ready),.eval_scope(locked_scope),
        .eval_seed(seed_index),.eval_pass(hist_owned ? 3'd0 : phase),.eval_ordinal(hist_owned ? hist_eval_ordinal : ordinal),
        .eval_point(hist_owned ? hist_eval_point : point_word),.eval_cx(pm_center_x),.eval_cy(pm_center_y),.eval_tolerance(pm_tolerance),
        .eval_rsp_valid(pm_rsp_valid),.eval_rsp_ready(pm_response_ready),.eval_rsp_scope(pm_scope),.eval_rsp_seed(pm_seed),
        .eval_rsp_pass(pm_pass),.eval_rsp_ordinal(pm_ordinal),.radius(pm_radius),.normal_ok(pm_normal),.error(pm_error),.drained(pm_drained),
        .quiet(pm_quiet),.fault(pm_fault),.num_req_valid(pm_num_valid),.num_req_ready(pm_num_ready),.num_req_body(pm_num_body),
        .num_rsp_valid(num_rsp_valid && numeric_owner==1 && numeric_owner_granted==1),.num_rsp_ready(pm_num_rsp_ready),
        .num_rsp_body,.num_quiet,.num_rsp_word_index(pm_num_word_index),.num_rsp_word16,.eval_radius_only(pm_radius_only));
    board_circle_reduce #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.SHARED_RETURN_WORDS(SHARED_RETURN_WORDS)) reduction(
        .clk,.rst,.command_valid(state==CR_REQUEST && numeric_owner_granted==2),.command_ready(cr_ready),
        .command_op(cr_purpose),.command_id(context_id),.command_data(cr_command_data),.response_valid(cr_rsp_valid),
        .response_ready(state==CR_WAIT && cr_response_id==context_id && cr_response_op==cr_purpose),
        .response_op(cr_response_op),.response_id(cr_response_id),.value(cr_value),.error(cr_error),.local_reject(cr_reject),
        .drained(cr_drained),.quiet(cr_quiet),.fault(cr_fault),.num_req_valid(cr_num_valid),.num_req_ready(cr_num_ready),.num_req_body(cr_num_body),
        .num_rsp_valid(num_rsp_valid && numeric_owner==2 && numeric_owner_granted==2),.num_rsp_ready(cr_num_rsp_ready),
        .num_rsp_body,.num_quiet,.num_rsp_word_index(cr_num_word_index),.num_rsp_word16);
    board_circle_histogram #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ADDRESS_BYTES(ADDRESS_BYTES),.BORROW_SCOPE(1'b1)) histogram(
        .clk,.rst,.start(state==HIST_START && numeric_owner_granted==1),.scope(locked_scope),.seed_ordinal(seed_index),
        .points(point_limit),.minimum_peak_votes(21'd6),.point_base(locked_point_base),.hist_base(locked_hist_base),
        .raw_peak_base(locked_raw_base),.smooth_peak_base(locked_smooth_base),.meta_base(locked_hist_meta_base),
        .start_ready(hist_start_ready),.done(hist_done),.fault(hist_fault),.quarantined(hist_quarantined),.votes(hist_votes),
        .raw_count(hist_raw_count),.smooth_count(hist_smooth_count),.raw_first(hist_raw_first),.raw_last(hist_raw_last),
        .smooth_first(hist_smooth_first),.smooth_last(hist_smooth_last),
        .eval_req_valid(hist_eval_req_valid),.eval_req_ready(state==HIST_LIVE && pm_quiet),
        .eval_req_point(hist_eval_point),.eval_req_ordinal(hist_eval_ordinal),
        .eval_rsp_valid(state==HIST_PM_REPLY),.eval_rsp_ready(hist_eval_rsp_ready),.eval_radius(pm_radius),
        .eval_normal_ok(pm_normal),.eval_error(pm_error || hist_eval_failed),
        .eval_drained(hist_eval_failed ? pm_quiet && num_quiet : pm_drained && pm_quiet),
        .req_valid(hist_req_valid),.req_ready(req_ready && hist_owned),.req_write(hist_req_write),.req_addr(hist_req_addr),
        .rsp_valid(rsp_valid && hist_owned),.rsp_ready(hist_rsp_ready),.rsp_data,.rsp_error,.rsp_drained,
        .pack_valid(hist_pack_valid),.pack_index(hist_pack_index),.pack_data(hist_pack_data));

    assign geometry_bind_valid=!rst && state==BIND && !lease_owned;
    assign geometry_release_valid=!rst && lease_owned && (state==RELEASE || state==FAIL_RELEASE);
    assign geometry_cancel_valid=1'b0;
    assign geometry_cancel_id=context_id;
    assign geometry_fit_req_body=geometry_stat_body[621:0];
    assign geometry_fit_req_valid=!rst && state==FIT_REQUEST && geometry_stat_valid && numeric_owner_granted==3;
    assign geometry_fit_rsp_ready=!rst && state==FIT_WAIT && geometry_fit_rsp_body[175:0]==context_id;
    assign geometry_stat_ready=!rst && (state==STAT_CONSUME || state==FAIL_STAT) &&
        geometry_stat_body[175:0]==context_id && geometry_fit_quiet && cr_quiet;
    reg [83:0] token_data;
    reg [1:0] token_op;
    always @*begin
        token_data=0;token_op=stats_protocol_pkg::START;
        if(state==STATS_START)begin
            token_data[10:0]=11'(WIDTH);token_data[21:11]=11'(HEIGHT);
            token_data[26:22]=phase==5 ? 5'd17 : 5'd11;token_data[34:27]=8'd1;
            token_data[50:35]=phase==5 ? 16'd0 : 16'd16;token_data[71:51]=point_limit;
        end else if(state==POINT_TOKEN)begin
            token_op=stats_protocol_pkg::POINT;token_data[20:0]=ordinal;token_data[21]=point_member;
            token_data[32:22]=point_word[42:32];token_data[43:33]=point_word[53:43];
            token_data[54:44]=point_word[10:0];token_data[65:55]=point_word[21:11];
        end else if(state==END_SCAN)begin
            token_op=stats_protocol_pkg::END_SCAN;token_data[21:0]={1'b0,point_limit};
        end else if(state==FAIL_ABORT)token_op=stats_protocol_pkg::ABORT_SCAN;
    end
    assign geometry_token_body={token_data,token_op,context_id};
    assign geometry_token_valid=!rst && (state==FAIL_ABORT ||
        (!fatal_pending && (state==STATS_START || state==POINT_TOKEN || state==END_SCAN)));
    always @*begin
        cr_command_data=0;
        case(cr_purpose)
            0:begin cr_command_data[38:0]=sum_distance;cr_command_data[59:39]=member_count;end
            1:begin cr_command_data[18:0]=radial_dx;cr_command_data[37:19]=radial_dy;
                cr_command_data[48:38]=gx;cr_command_data[59:49]=gy;cr_command_data[77:60]=residual;end
            2:begin cr_command_data[20:0]=support;cr_command_data[41:21]=eligible;end
            3:cr_command_data[262:0]=geometry_stat_body[222+:263];
            4:begin cr_command_data[20:0]=support;cr_command_data[41:21]=eligible;cr_command_data[94:42]=sse;
                cr_command_data[101:95]=sector_count;cr_command_data[122:102]=21'd6;
                cr_command_data[138:123]=16'd32768;cr_command_data[154:139]=16'd2047;cr_command_data[170:155]=16'd256;end
            default:begin end
        endcase
    end
    assign angle_req_body={362'd0,radial_dy,radial_dx,9'd0,2'd0,5'd9,8'd1,11'(HEIGHT),11'(WIDTH),angular_id};
    assign angle_req_valid=!rst && state==ANGLE_REQUEST && angle_owner_granted && !angle_exhausted;
    assign angle_rsp_ready=!rst && state==ANGLE_WAIT && angle_rsp_body[175:0]==angular_id;
    wire [10:0] restored_full_angle={1'b0,angle_rsp_body[209:200]}+(angle_rsp_body[210] ? 11'd512 : 11'd0);
    wire expected_half=radial_dy<0 || (radial_dy==0 && radial_dx<0);
    wire [7:0] next_seed_index=seed_index+8'd1;

    wire reading=state==SEED_READ || state==HIST_META_READ || state==PEAK_READ || state==POINT_READ || state==DEDUP_READ;
    assign req_valid=!rst && (hist_owned ? hist_req_valid : reading || state==WRITE_REQUEST);
    assign req_write=hist_owned ? hist_req_write : state==WRITE_REQUEST;
    assign req_addr=hist_owned ? hist_req_addr : address;
    wire capture_reply=state==SEED_WAIT || state==HIST_META_WAIT || state==PEAK_WAIT || state==DEDUP_WAIT || state==WRITE_WAIT;
    assign rsp_ready=!rst && (hist_owned ? hist_rsp_ready :
        (capture_reply && rsp_drained) || state==POINT_CONSUME ||
        (state==FAIL_DDR && pm_quiet && cr_quiet && geometry_fit_quiet && angle_quiet));
    wire signed [19:0] extent_left=$signed({{2{c2x[17]}},c2x})-$signed({3'd0,r2});
    wire signed [19:0] extent_right=$signed({{2{c2x[17]}},c2x})+$signed({3'd0,r2});
    wire signed [19:0] extent_top=$signed({{2{c2y[17]}},c2y})-$signed({3'd0,r2});
    wire signed [19:0] extent_bottom=$signed({{2{c2y[17]}},c2y})+$signed({3'd0,r2});
    wire [3:0] circle_flags={1'b0,positive_seen && negative_seen,
        (extent_left<0 || extent_top<0 || extent_right>16*(WIDTH-1) || extent_bottom>16*(HEIGHT-1)),
        (c2x<0 || c2y<0 || $signed({1'b0,c2x})>16*(WIDTH-1) || $signed({1'b0,c2y})>16*(HEIGHT-1))};
    wire [255:0] circle_body={11'd0,score,sse,sector_mask,eligible,support,r2,c2y,c2x,circle_flags,5'd0,seed_index};
    wire [319:0] circle_record={{11'd0,max_residual,fit_quality,support},circle_body};
    reg [511:0] metadata;
    always @*begin
        metadata=0;metadata[95:0]=locked_scope;metadata[116:96]=point_limit;metadata[125:117]=seed_limit;
        metadata[136:126]=circ_count;metadata[155:137]=raw_visited;metadata[174:156]=smooth_visited;
        metadata[206:175]=local_rejected;metadata[238:207]=duplicates;metadata[302:239]=pm_calls;
        metadata[303]=1;metadata[311:304]=8'd2;
    end
    assign pack_valid=!rst && (hist_owned ? hist_pack_valid : state==RECORD_PACK || state==META_PACK);
    assign pack_index=hist_owned ? hist_pack_index : pack_slot;
    assign pack_data=hist_owned ? hist_pack_data : state==META_PACK ? metadata[pack_slot*64+:64] :
        pack_slot<5 ? circle_record[pack_slot*64+:64] : 64'd0;
    // lease 的几何 quiet 只在 owned 时有效；bind_ready 核查绑定前的真实旧服务关闭。
    assign start_ready=!rst && (state==IDLE || state==COMPLETE) && !native_pending && num_quiet &&
        pm_quiet && cr_quiet && angle_quiet && !lease_owned && geometry_bind_ready;
    assign done=!rst && state==COMPLETE;

    function automatic apart(input [31:0] a,b,input [32:0] ae,be);
        apart=ae<={1'b0,b} || be<={1'b0,a};
    endfunction
    wire [32:0] point_end={1'b0,point_base}+((({12'd0,points}+33'd7)>>3)<<6);
    wire [32:0] seed_end={1'b0,seed_base}+33'd4096;
    wire [32:0] hist_end={1'b0,hist_base}+33'd524288,raw_end={1'b0,raw_peak_base}+33'd32768,
        smooth_end={1'b0,smooth_peak_base}+33'd32768,circ_end={1'b0,circ_base}+33'd65536;
    wire [32:0] hm_end={1'b0,hist_meta_base}+33'd64,cm_end={1'b0,circ_meta_base}+33'd64;
    wire start_legal=points<=WIDTH*HEIGHT && seeds<=256 && WIDTH>=6 && WIDTH<=1920 && WIDTH%2==0 && HEIGHT>=5 && HEIGHT<=1080 &&
        ADDRESS_BYTES>=33'd64 && ADDRESS_BYTES<=33'h100000000 &&
        point_base[5:0]==0 && seed_base[5:0]==0 && hist_base[5:0]==0 && raw_peak_base[5:0]==0 &&
        smooth_peak_base[5:0]==0 && hist_meta_base[5:0]==0 && circ_base[5:0]==0 && circ_meta_base[5:0]==0 &&
        point_end<=ADDRESS_BYTES && seed_end<=ADDRESS_BYTES && hist_end<=ADDRESS_BYTES && raw_end<=ADDRESS_BYTES &&
        smooth_end<=ADDRESS_BYTES && hm_end<=ADDRESS_BYTES && circ_end<=ADDRESS_BYTES && cm_end<=ADDRESS_BYTES &&
        apart(point_base,seed_base,point_end,seed_end) && apart(point_base,hist_base,point_end,hist_end) &&
        apart(point_base,raw_peak_base,point_end,raw_end) && apart(point_base,smooth_peak_base,point_end,smooth_end) &&
        apart(point_base,hist_meta_base,point_end,hm_end) && apart(point_base,circ_base,point_end,circ_end) && apart(point_base,circ_meta_base,point_end,cm_end) &&
        apart(seed_base,hist_base,seed_end,hist_end) && apart(seed_base,raw_peak_base,seed_end,raw_end) && apart(seed_base,smooth_peak_base,seed_end,smooth_end) &&
        apart(seed_base,hist_meta_base,seed_end,hm_end) && apart(seed_base,circ_base,seed_end,circ_end) && apart(seed_base,circ_meta_base,seed_end,cm_end) &&
        apart(hist_base,raw_peak_base,hist_end,raw_end) && apart(hist_base,smooth_peak_base,hist_end,smooth_end) &&
        apart(hist_base,hist_meta_base,hist_end,hm_end) && apart(hist_base,circ_base,hist_end,circ_end) && apart(hist_base,circ_meta_base,hist_end,cm_end) &&
        apart(raw_peak_base,smooth_peak_base,raw_end,smooth_end) && apart(raw_peak_base,hist_meta_base,raw_end,hm_end) &&
        apart(raw_peak_base,circ_base,raw_end,circ_end) && apart(raw_peak_base,circ_meta_base,raw_end,cm_end) &&
        apart(smooth_peak_base,hist_meta_base,smooth_end,hm_end) && apart(smooth_peak_base,circ_base,smooth_end,circ_end) &&
        apart(smooth_peak_base,circ_meta_base,smooth_end,cm_end) && apart(hist_meta_base,circ_base,hm_end,circ_end) &&
        apart(hist_meta_base,circ_meta_base,hm_end,cm_end) && apart(circ_base,circ_meta_base,circ_end,cm_end);
    wire [127:0] seed_word=rsp_data[seed_index[1:0]*128+:128];
    wire [63:0] peak_word=rsp_data[63:0];
    wire seed_legal=seed_word[127:118]==0 && seed_word[117] && seed_word[16:0]!=0;
    wire peak_legal=rsp_data[511:64]==0 && peak_word[63:61]==0 && peak_word[60:59]=={1'b0,route} &&
        peak_word[16:0]!=0 && peak_word[37:17]<=point_limit && peak_word[58:38]<=point_limit &&
        (route ? peak_word[58:38] : peak_word[37:17])>=21'd6;

    task automatic known_fail;
        begin fault<=1;drained<=0;state<=FAIL_CLOSE;end
    endtask
    task automatic unknown_fail;
        begin fault<=1;quarantined<=1;drained<=0;state<=QUARANTINE;end
    endtask
    task automatic next_peak_or_seed;
        begin
            if(peak_index+10'd1<route_count)begin
                peak_index<=peak_index+10'd1;peak_part<=0;
                address<=(route ? locked_smooth_base : locked_raw_base)+{16'd0,(peak_index+10'd1),6'd0};state<=PEAK_READ;
            end else if(!route && hist_smooth_count!=0)begin
                route<=1;route_count<=hist_smooth_count;peak_index<=0;peak_part<=0;address<=locked_smooth_base;state<=PEAK_READ;
            end else state<=SEED_NEXT;
        end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;numeric_owner<=0;angle_owned<=0;lease_owned<=0;hist_owned<=0;native_pending<=0;
            stats_active<=0;context_exhausted<=0;angle_exhausted<=0;context_sequence<=0;angle_sequence<=0;
            point_limit<=0;ordinal<=0;member_count<=0;n_expected<=0;eligible<=0;support<=0;seed_limit<=0;
            locked_point_base<=0;locked_seed_base<=0;locked_hist_base<=0;locked_raw_base<=0;locked_smooth_base<=0;
            locked_hist_meta_base<=0;locked_circ_base<=0;locked_circ_meta_base<=0;address<=0;
            seed_index<=0;route<=0;route_count<=0;peak_index<=0;peak_part<=0;phase<=0;pm_step<=0;cr_purpose<=0;
            pack_slot<=0;lane<=0;c0x<=0;c0y<=0;c1x<=0;c1y<=0;c2x<=0;c2y<=0;r0<=0;r1<=0;r2<=0;
            lower_sum<=0;upper_sum<=0;has_lower<=0;has_upper<=0;point_member<=0;pass_finished<=0;reject_candidate<=0;
            write_meta<=0;sum_distance<=0;sse<=0;sector_mask<=0;max_residual<=0;fit_quality<=0;score<=0;
            positive_seen<=0;negative_seen<=0;residual<=0;sector_count<=0;pop_index<=0;dedup_index<=0;
            previous_x<=0;previous_y<=0;previous_valid<=0;after_stat<=0;
            pm_failed<=0;cr_failed<=0;cr_local<=0;angle_failed<=0;hist_eval_failed<=0;fatal_pending<=0;
            previous_seed_rank<=0;previous_seed_key<=0;previous_seed_valid<=0;
            fault<=0;quarantined<=0;drained<=0;circ_count<=0;raw_visited<=0;smooth_visited<=0;
            local_rejected<=0;duplicates<=0;pm_calls<=0;
        end else begin
            if(req_valid && req_ready)native_pending<=1;
            if(rsp_valid && rsp_ready)native_pending<=0;
            if(geometry_fault)fatal_pending<=1;
            case(state)
                IDLE,COMPLETE:if(start && start_ready)begin
                    point_limit<=points;seed_limit<=seeds;locked_point_base<=point_base;locked_seed_base<=seed_base;
                    locked_hist_base<=hist_base;locked_raw_base<=raw_peak_base;locked_smooth_base<=smooth_peak_base;
                    locked_hist_meta_base<=hist_meta_base;locked_circ_base<=circ_base;locked_circ_meta_base<=circ_meta_base;
                    seed_index<=0;route<=0;peak_index<=0;circ_count<=0;raw_visited<=0;smooth_visited<=0;
                    local_rejected<=0;duplicates<=0;pm_calls<=0;fault<=0;quarantined<=0;drained<=0;
                    fatal_pending<=0;previous_seed_valid<=0;write_meta<=0;reject_candidate<=0;
                    if(!start_legal || context_exhausted || angle_exhausted || pm_fault || cr_fault)known_fail();
                    else state<=BIND;
                end
                BIND:begin
                    if(geometry_bind_valid && geometry_bind_ready)begin lease_owned<=1;angle_owned<=1;end
                    if(fatal_pending)known_fail();
                    else if(lease_owned && angle_owner_granted && angle_quiet)begin
                        if(seed_limit==0)begin pack_slot<=0;address<=locked_circ_meta_base;write_meta<=1;state<=META_PACK;end
                        else begin address<=locked_seed_base;state<=SEED_READ;end
                    end
                end
                SEED_READ:if(req_valid && req_ready)state<=SEED_WAIT;
                SEED_WAIT:if(rsp_valid)begin
                    if(!rsp_drained)unknown_fail();
                    else if(rsp_error || !seed_legal || (previous_seed_valid &&
                        (seed_word[116:53]<previous_seed_rank || (seed_word[116:53]==previous_seed_rank && seed_word[52:0]<=previous_seed_key))))known_fail();
                    else begin
                        c0x<=seed_word[52:35]^18'h20000;c0y<=seed_word[34:17]^18'h20000;
                        previous_seed_rank<=seed_word[116:53];previous_seed_key<=seed_word[52:0];previous_seed_valid<=1;
                        numeric_owner<=1;state<=HIST_START;
                    end
                end
                HIST_START:if(numeric_owner_granted==1 && hist_start_ready)begin
                    hist_owned<=1;hist_eval_failed<=0;state<=HIST_LIVE;
                end
                HIST_LIVE:begin
                    if(hist_quarantined)unknown_fail();
                    else if(hist_fault)known_fail();
                    else if(hist_done && pm_quiet && num_quiet && !native_pending)begin
                        hist_owned<=0;numeric_owner<=0;address<=locked_hist_meta_base;state<=HIST_META_READ;
                    end else if(hist_eval_req_valid && pm_quiet)begin hist_eval_failed<=0;state<=HIST_PM_REQUEST;end
                end
                HIST_PM_REQUEST:begin
                    if((&pm_calls || (pm_fault && !pm_req_ready)) && pm_quiet)begin hist_eval_failed<=1;state<=HIST_PM_REPLY;end
                    else if(pm_request && pm_req_ready)begin
                        pm_calls<=pm_calls+64'd1;state<=HIST_PM_WAIT;
                    end
                end
                HIST_PM_WAIT:if(pm_rsp_valid)begin
                    if(!pm_response_ready)unknown_fail();
                    else if(!pm_drained)begin hist_eval_failed<=1;state<=HIST_PM_REPLY;end
                    else state<=HIST_PM_CLOSE;
                end
                HIST_PM_CLOSE:if(pm_quiet && num_quiet)state<=HIST_PM_REPLY;
                HIST_PM_REPLY:if(hist_eval_rsp_ready)state<=HIST_LIVE;
                HIST_META_READ:if(req_valid && req_ready)state<=HIST_META_WAIT;
                HIST_META_WAIT:if(rsp_valid)begin
                    if(!rsp_drained)unknown_fail();
                    else if(rsp_error || rsp_data[95:0]!=locked_scope || rsp_data[103:96]!=seed_index ||
                        rsp_data[124:104]!=point_limit || rsp_data[145:125]!=hist_votes ||
                        rsp_data[155:146]!=hist_raw_count || rsp_data[165:156]!=hist_smooth_count ||
                        rsp_data[182:166]!=hist_raw_first || rsp_data[199:183]!=hist_raw_last ||
                        rsp_data[216:200]!=hist_smooth_first || rsp_data[233:217]!=hist_smooth_last ||
                        rsp_data[251:234]!=18'd131081 || rsp_data[269:252]!=18'd131072 ||
                        rsp_data[280:270]!=WIDTH || rsp_data[291:281]!=HEIGHT || rsp_data[299:292]!=8'd1 ||
                        !rsp_data[300] || rsp_data[511:301]!=0 || hist_raw_count>512 || hist_smooth_count>512)known_fail();
                    else if(hist_raw_count!=0)begin
                        route<=0;route_count<=hist_raw_count;peak_index<=0;peak_part<=0;address<=locked_raw_base;state<=PEAK_READ;
                    end else if(hist_smooth_count!=0)begin
                        route<=1;route_count<=hist_smooth_count;peak_index<=0;peak_part<=0;address<=locked_smooth_base;state<=PEAK_READ;
                    end else state<=SEED_NEXT;
                end
                PEAK_READ:if(req_valid && req_ready)state<=PEAK_WAIT;
                PEAK_WAIT:if(rsp_valid)begin
                    if(!rsp_drained)unknown_fail();
                    else if(rsp_error || !peak_legal)known_fail();
                    else if(peak_part==0)begin
                        r0<=peak_word[16:0];has_lower<=peak_index!=0;has_upper<=peak_index+10'd1<route_count;
                        lower_sum<=0;upper_sum<=0;reject_candidate<=0;
                        if(route)smooth_visited<=smooth_visited+19'd1;else raw_visited<=raw_visited+19'd1;
                        if(peak_index!=0)begin
                            peak_part<=1;address<=(route ? locked_smooth_base : locked_raw_base)+{16'd0,(peak_index-10'd1),6'd0};state<=PEAK_READ;
                        end else if(peak_index+10'd1<route_count)begin
                            peak_part<=2;address<=(route ? locked_smooth_base : locked_raw_base)+{16'd0,(peak_index+10'd1),6'd0};state<=PEAK_READ;
                        end else begin phase<=1;state<=PASS_PREP;end
                    end else if(peak_part==1)begin
                        if(peak_word[16:0]>=r0)known_fail();
                        else begin
                            lower_sum<={1'b0,peak_word[16:0]}+{1'b0,r0};
                            if(peak_index+10'd1<route_count)begin
                                peak_part<=2;address<=(route ? locked_smooth_base : locked_raw_base)+{16'd0,(peak_index+10'd1),6'd0};state<=PEAK_READ;
                            end else begin phase<=1;state<=PASS_PREP;end
                        end
                    end else if(peak_word[16:0]<=r0)known_fail();
                    else begin upper_sum<={1'b0,r0}+{1'b0,peak_word[16:0]};phase<=1;state<=PASS_PREP;end
                end
                PASS_PREP:begin
                    ordinal<=0;lane<=0;member_count<=0;sum_distance<=0;previous_valid<=0;pass_finished<=0;pm_step<=0;
                    address<=locked_point_base;
                    if(phase==5)begin
                        eligible<=0;support<=0;sse<=0;sector_mask<=0;max_residual<=0;positive_seen<=0;negative_seen<=0;
                    end
                    if(phase==1 || phase==3 || phase==5)begin
                        if(context_exhausted)known_fail();else state<=STATS_START;
                    end else if(point_limit==0)begin cr_purpose<=0;numeric_owner<=2;state<=CR_REQUEST;end
                    else state<=POINT_READ;
                end
                STATS_START:if(fatal_pending)known_fail();else if(geometry_token_valid && geometry_token_ready)begin
                    stats_active<=1;state<=point_limit==0 ? END_SCAN : POINT_READ;
                end
                POINT_READ:if(req_valid && req_ready)state<=POINT_WAIT;
                POINT_WAIT:if(rsp_valid)begin
                    if(!rsp_drained)unknown_fail();else if(rsp_error)known_fail();else state<=POINT_CHECK;
                end
                POINT_CHECK:begin
                    if(!rsp_valid || !native_pending)unknown_fail();
                    else if(!point_legal)known_fail();
                    else begin
                        previous_x<=point_word[42:32];previous_y<=point_word[53:43];previous_valid<=1;
                        pm_step<=0;point_member<=0;numeric_owner<=1;state<=PM_REQUEST;
                    end
                end
                PM_REQUEST:if((&pm_calls || (pm_fault && !pm_req_ready)) && pm_quiet)known_fail();
                    else if(pm_request && pm_req_ready)begin
                        pm_failed<=0;pm_calls<=pm_calls+64'd1;state<=PM_WAIT;
                    end
                PM_WAIT:if(pm_rsp_valid)begin
                    if(!pm_response_ready)unknown_fail();
                    else if(!pm_drained)unknown_fail();
                    else begin pm_failed<=pm_error;state<=PM_CLOSE;end
                end
                PM_CLOSE:if(pm_quiet && num_quiet)begin
                    numeric_owner<=0;
                    if(pm_failed)known_fail();
                    else if(phase==5)begin
                        if(final_residual<=19'd64 && eligible>=point_limit)known_fail();
                        else begin
                            if(final_residual<=19'd64)eligible<=eligible+21'd1;
                            point_member<=final_residual<=19'd32 && pm_normal && pm_radius!=0;
                            residual<=final_residual[17:0];
                            if(final_residual<=19'd32 && pm_normal && pm_radius!=0)begin
                                cr_purpose<=1;numeric_owner<=2;state<=CR_REQUEST;
                            end else state<=POINT_TOKEN;
                        end
                    end else if(pm_step==0)begin
                        if(phase==1)begin point_member<=in_partition && wide_residual<=19'd64 && pm_normal;state<=POINT_TOKEN;end
                        else if(phase==2)begin
                            if(in_partition && wide_residual<=19'd64 && pm_normal)begin pm_step<=1;numeric_owner<=1;state<=PM_REQUEST;end
                            else state<=POINT_ADVANCE;
                        end else if(in_partition)begin pm_step<=1;numeric_owner<=1;state<=PM_REQUEST;end
                        else if(phase==3)state<=POINT_TOKEN;else state<=POINT_ADVANCE;
                    end else if(phase==2 || pm_step==2)begin
                        if(next_members[21] || next_members>point_limit || next_distance[39])known_fail();
                        else begin member_count<=next_members[20:0];sum_distance<=next_distance[38:0];state<=POINT_ADVANCE;end
                    end else if(phase==3)begin point_member<=wide_residual<=19'd64 && pm_normal;state<=POINT_TOKEN;end
                    else if(wide_residual<=19'd64 && pm_normal)begin pm_step<=2;numeric_owner<=1;state<=PM_REQUEST;end
                    else state<=POINT_ADVANCE;
                end
                POINT_TOKEN:if(fatal_pending)known_fail();else if(geometry_token_valid && geometry_token_ready)begin
                    if(point_member && (phase==5 ? support : member_count)>=point_limit)known_fail();
                    else begin
                        if(point_member)begin if(phase==5)support<=support+21'd1;else member_count<=member_count+21'd1;end
                        state<=POINT_ADVANCE;
                    end
                end
                POINT_ADVANCE:begin
                    if(fatal_pending)known_fail();
                    else begin
                        ordinal<=ordinal+21'd1;
                        if(ordinal+21'd1>=point_limit)begin
                            pass_finished<=1;
                            if(lane==7)state<=POINT_CONSUME;else begin lane<=lane+3'd1;state<=POINT_PAD;end
                        end else if(lane==7)state<=POINT_CONSUME;
                        else begin lane<=lane+3'd1;state<=POINT_CHECK;end
                    end
                end
                POINT_PAD:if(point_word!=0)known_fail();else if(lane==7)state<=POINT_CONSUME;else lane<=lane+3'd1;
                POINT_CONSUME:if(rsp_valid && rsp_ready)begin
                    if(!rsp_drained || rsp_error)begin if(!rsp_drained)unknown_fail();else known_fail();end
                    else if(pass_finished)begin
                        if(stats_active)state<=END_SCAN;
                        else if(member_count!=n_expected)known_fail();
                        else begin cr_purpose<=0;numeric_owner<=2;state<=CR_REQUEST;end
                    end else begin lane<=0;address<=address+32'd64;state<=POINT_READ;end
                end
                END_SCAN:if(fatal_pending)known_fail();else if(geometry_token_valid && geometry_token_ready)state<=STAT_WAIT;
                STAT_WAIT:if(geometry_stat_valid)begin
                    if(geometry_stat_body[175:0]!=context_id)unknown_fail();
                    else if(geometry_stat_body[631:622]!=0 || geometry_stat_body[210:206]!=(phase==5 ? 5'd17 : 5'd11) ||
                        geometry_stat_body[197:176]!={11'(HEIGHT),11'(WIDTH)} || geometry_stat_body[205:198]!=8'd1 ||
                        geometry_stat_body[221:211]!=0 ||
                        (phase==5 ? geometry_stat_body[621:485]!=0 :
                         (geometry_stat_body[621:501]!=0 || geometry_stat_body[500:485]!=16'd16)) ||
                        geometry_stat_body[242:222]!=(phase==5 ? support : member_count))begin after_stat<=4;state<=STAT_CONSUME;fault<=1;end
                    else if((phase==5 ? support : member_count)<21'd6)begin reject_candidate<=1;after_stat<=3;state<=STAT_CONSUME;end
                    else if(phase==5)begin cr_purpose<=3;numeric_owner<=2;state<=CR_REQUEST;end
                    else begin numeric_owner<=3;state<=FIT_REQUEST;end
                end
                FIT_REQUEST:if(geometry_fit_req_valid && geometry_fit_req_ready)state<=FIT_WAIT;
                FIT_WAIT:if(geometry_fit_rsp_valid)begin
                    if(geometry_fit_rsp_body[175:0]!=context_id)unknown_fail();
                    else begin
                        if(geometry_fit_rsp_body[189:176]!={9'd0,5'd11} || geometry_fit_rsp_body[191:190]>2'd1 ||
                            (geometry_fit_rsp_body[191:190]==0 && (geometry_fit_rsp_body[199:192]!=0 || geometry_fit_rsp_body[584:273]!=0 ||
                            geometry_fit_rsp_body[256:236]!=member_count)))begin fault<=1;after_stat<=4;end
                        else if(geometry_fit_rsp_body[191:190]==1)begin
                            if(geometry_fit_rsp_body[584:200]!=0 ||
                                !(geometry_fit_rsp_body[199:192]==fit_protocol_pkg::DEGENERATE ||
                                  geometry_fit_rsp_body[199:192]==fit_protocol_pkg::ILL_CONDITION ||
                                  geometry_fit_rsp_body[199:192]==fit_protocol_pkg::GEOM_RANGE ||
                                  geometry_fit_rsp_body[199:192]==fit_protocol_pkg::COUNT))begin fault<=1;after_stat<=4;end
                            else begin reject_candidate<=1;after_stat<=3;end
                        end else begin
                            n_expected<=geometry_fit_rsp_body[256:236];
                            if(phase==1)begin c1x<=geometry_fit_rsp_body[217:200];c1y<=geometry_fit_rsp_body[235:218];after_stat<=0;end
                            else begin c2x<=geometry_fit_rsp_body[217:200];c2y<=geometry_fit_rsp_body[235:218];after_stat<=1;end
                        end
                        state<=FIT_CLOSE;
                    end
                end
                FIT_CLOSE:if(geometry_fit_quiet && num_quiet)begin numeric_owner<=0;state<=STAT_CONSUME;end
                STAT_CONSUME:if(geometry_stat_valid)begin
                    if(geometry_stat_body[175:0]!=context_id)unknown_fail();
                    else if(geometry_stat_ready)state<=STAT_CLOSE;
                end
                STAT_CLOSE:if(geometry_stats_quiet && geometry_fit_quiet && cr_quiet && num_quiet)begin
                    stats_active<=0;
                    if(&context_sequence)begin context_exhausted<=1;known_fail();end
                    else begin
                        context_sequence<=context_sequence+64'd1;
                        if(after_stat==4)known_fail();
                        else if(after_stat==3)state<=CANDIDATE_NEXT;
                        else if(after_stat==2)begin sector_count<=0;pop_index<=0;state<=POPCOUNT;end
                        else begin phase<=after_stat==0 ? 3'd2 : 3'd4;state<=PASS_PREP;end
                    end
                end
                CR_REQUEST:if(cr_fault && cr_quiet && !cr_ready)known_fail();
                    else if(numeric_owner_granted==2 && cr_ready)begin cr_failed<=0;cr_local<=0;state<=CR_WAIT;end
                CR_WAIT:if(cr_rsp_valid)begin
                    if(cr_response_id!=context_id || cr_response_op!=cr_purpose)unknown_fail();
                    else if(!cr_drained)unknown_fail();
                    else begin cr_failed<=cr_error;cr_local<=cr_reject;state<=CR_CLOSE;end
                end
                CR_CLOSE:if(cr_quiet && num_quiet)begin
                    numeric_owner<=0;
                    if(cr_failed)known_fail();
                    else if(cr_local)begin
                        reject_candidate<=1;
                        if(stats_active)begin after_stat<=3;state<=STAT_CONSUME;end else state<=CANDIDATE_NEXT;
                    end else case(cr_purpose)
                        0:begin
                            if(member_count!=n_expected || cr_value[95:17]!=0 || cr_value[16:0]==0)known_fail();
                            else begin if(phase==2)r1<=cr_value[16:0];else r2<=cr_value[16:0];phase<=phase+3'd1;state<=PASS_PREP;end
                        end
                        1:begin
                            if(cr_value[95:38]!=0 || cr_value[37:36]==3 || next_sse[53])known_fail();
                            else begin
                                sse<=next_sse[52:0];if(residual>max_residual)max_residual<=residual[15:0];
                                if(cr_value[37:36]==1)positive_seen<=1;if(cr_value[37:36]==2)negative_seen<=1;
                                state<=ANGLE_REQUEST;
                            end
                        end
                        2:begin
                            if(cr_value[95:16]!=0)known_fail();
                            else begin score<=cr_value[15:0];dedup_index<=0;
                                if(circ_count==0)begin address<=locked_circ_base;pack_slot<=0;write_meta<=0;state<=RECORD_PACK;end
                                else begin address<=locked_circ_base;state<=DEDUP_READ;end end
                        end
                        3:begin
                            if(cr_value[95:38]!=0 || !cr_value[37] || cr_value[20:0]!=support)begin after_stat<=4;fault<=1;end
                            else begin fit_quality<=cr_value[36:21];after_stat<=2;end
                            state<=STAT_CONSUME;
                        end
                        4:begin
                            if(cr_value[95:1]!=0)known_fail();
                            else if(!cr_value[0])begin reject_candidate<=1;state<=CANDIDATE_NEXT;end
                            else begin cr_purpose<=2;numeric_owner<=2;state<=CR_REQUEST;end
                        end
                        default:known_fail();
                    endcase
                end
                ANGLE_REQUEST:if(angle_exhausted)known_fail();else if(angle_req_valid && angle_req_ready)begin angle_failed<=0;state<=ANGLE_WAIT;end
                ANGLE_WAIT:if(angle_rsp_valid)begin
                    if(angle_rsp_body[175:0]!=angular_id)unknown_fail();
                    else begin
                        if(angle_rsp_body[199:176]!={10'd0,9'd0,5'd9} || angle_rsp_body[584:227]!=0 ||
                            angle_rsp_body[209:200]>10'd512 || angle_rsp_body[226:221]!=angle_rsp_body[220:215] ||
                            angle_rsp_body[210]!=expected_half || angle_rsp_body[220:211]!=restored_full_angle[9:0])angle_failed<=1;
                        else sector_mask[angle_rsp_body[226:221]]<=1;
                        state<=ANGLE_CLOSE;
                    end
                end
                ANGLE_CLOSE:if(angle_quiet)begin
                    if(&angle_sequence)begin angle_exhausted<=1;known_fail();end
                    else begin angle_sequence<=angle_sequence+64'd1;if(angle_failed)known_fail();else state<=POINT_TOKEN;end
                end
                POPCOUNT:begin
                    sector_count<=sector_count+{6'd0,sector_mask[pop_index[5:0]]};
                    if(pop_index==63)begin cr_purpose<=4;numeric_owner<=2;state<=CR_REQUEST;end
                    else pop_index<=pop_index+7'd1;
                end
                DEDUP_READ:if(req_valid && req_ready)state<=DEDUP_WAIT;
                DEDUP_WAIT:if(rsp_valid)begin
                    if(!rsp_drained)unknown_fail();
                    else if(rsp_error || rsp_data[511:320]!=0 || rsp_data[319:309]!=0 || rsp_data[255:245]!=0 ||
                        rsp_data[12:8]!=0 || rsp_data[16] || rsp_data[69:53]==0 ||
                        rsp_data[90:70]<21'd6 || rsp_data[90:70]>rsp_data[111:91] || rsp_data[111:91]>point_limit ||
                        rsp_data[276:256]!=rsp_data[90:70])known_fail();
                    else if(rsp_data[69:17]==circle_body[69:17])begin
                        // seed诊断可不同；同冻结几何的其余指标必须逐位相同。
                        if(rsp_data[319:13]!=circle_record[319:13])known_fail();
                        else begin duplicates<=duplicates+32'd1;state<=CANDIDATE_NEXT;end
                    end else if(dedup_index+11'd1>=circ_count)begin
                        if(circ_count==1024)known_fail();
                        else begin address<=locked_circ_base+{15'd0,circ_count,6'd0};pack_slot<=0;write_meta<=0;state<=RECORD_PACK;end
                    end else begin dedup_index<=dedup_index+11'd1;address<=address+32'd64;state<=DEDUP_READ;end
                end
                RECORD_PACK,META_PACK:if(pack_slot==7)begin pack_slot<=0;state<=WRITE_REQUEST;end else pack_slot<=pack_slot+3'd1;
                WRITE_REQUEST:if(req_valid && req_ready)state<=WRITE_WAIT;
                WRITE_WAIT:if(rsp_valid)begin
                    if(!rsp_drained)unknown_fail();else if(rsp_error)known_fail();
                    else if(write_meta)state<=RELEASE;
                    else begin circ_count<=circ_count+11'd1;state<=CANDIDATE_NEXT;end
                end
                CANDIDATE_NEXT:begin
                    if(reject_candidate)begin local_rejected<=local_rejected+32'd1;reject_candidate<=0;end
                    next_peak_or_seed();
                end
                SEED_NEXT:if({1'b0,seed_index}+9'd1>=seed_limit)begin
                    pack_slot<=0;write_meta<=1;address<=locked_circ_meta_base;state<=META_PACK;
                end else begin seed_index<=next_seed_index;address<=locked_seed_base+{20'd0,next_seed_index[7:2],6'd0};state<=SEED_READ;end
                RELEASE:if(geometry_release_valid && geometry_release_ready)begin lease_owned<=0;angle_owned<=0;numeric_owner<=0;state<=FINAL_CLOSE;end
                FINAL_CLOSE:if(!angle_owner_granted && numeric_owner_granted==0 && angle_quiet && pm_quiet && cr_quiet &&
                    num_quiet && !native_pending)begin drained<=1;state<=COMPLETE;end
                FAIL_CLOSE:begin
                    if(hist_quarantined)unknown_fail();
                    else if(pm_quiet && cr_quiet && (!lease_owned || geometry_fit_quiet) && angle_quiet && num_quiet)begin
                        numeric_owner<=0;
                        if(hist_owned && !native_pending && !hist_req_valid)hist_owned<=0;
                        if(stats_active)state<=geometry_stat_valid ? FAIL_STAT : FAIL_ABORT;
                        else if(native_pending)state<=FAIL_DDR;
                        else state<=FAIL_RELEASE;
                    end
                end
                FAIL_ABORT:if(geometry_token_valid && geometry_token_ready)state<=FAIL_STAT;
                FAIL_STAT:if(geometry_stat_valid)begin
                    if(geometry_stat_body[175:0]!=context_id)unknown_fail();
                    else if(geometry_stat_ready)state<=FAIL_STAT_CLOSE;
                end
                FAIL_STAT_CLOSE:if(geometry_stats_quiet && geometry_fit_quiet)begin
                    stats_active<=0;if(&context_sequence)context_exhausted<=1;else context_sequence<=context_sequence+64'd1;
                    state<=native_pending ? FAIL_DDR : FAIL_RELEASE;
                end
                FAIL_DDR:if(rsp_valid && rsp_ready)begin if(!rsp_drained)unknown_fail();else begin hist_owned<=0;state<=FAIL_RELEASE;end end
                FAIL_RELEASE:begin
                    if(!lease_owned)begin angle_owned<=0;numeric_owner<=0;state<=FAIL_FINAL;end
                    else if(geometry_release_valid && geometry_release_ready)begin lease_owned<=0;angle_owned<=0;numeric_owner<=0;state<=FAIL_FINAL;end
                end
                FAIL_FINAL:if(!angle_owner_granted && numeric_owner_granted==0 && angle_quiet && pm_quiet && cr_quiet && num_quiet && !native_pending)begin drained<=1;state<=FAILED;end
                FAILED,QUARANTINE:begin end
                default:unknown_fail();
            endcase
        end
    end
endmodule
