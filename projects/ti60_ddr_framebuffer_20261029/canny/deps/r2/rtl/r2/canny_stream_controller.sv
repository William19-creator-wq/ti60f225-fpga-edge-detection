// SI-REQ03/05 / C0-OP01…08：唯一CJ/FE owner，真实前缀、第一原因和CS保持。
module canny_stream_controller #(parameter integer W=1920,H=1080) (
    input wire clk,rst,cancel,
    input wire cj_valid,output wire cj_ready,input wire [141:0] cj,
    output wire fj_valid,input wire fj_ready,output logic [109:0] fj,
    input wire fs_valid,output wire fs_ready,input wire [162:0] fs,
    output wire fe_cancel,fp_allow,stream_start,data_flush,ctx_live,
    output logic [141:0] ctx_cj,
    input wire derr_valid,output wire derr_ready,input wire [119:0] derr,
    input wire [7:0] event_fire,input wire [967:0] event_metadata,
    input wire [3:0] event_classes,input wire [63:0] event_grad,
    input wire [4:0] private_empty,
    output wire status_valid,input wire status_ready,output wire [591:0] status_payload
);
    localparam logic [2:0] IDLE=0,ARM=1,WAIT_FE=2,RUN=3,DRAIN=4,ABORT_DRAIN=5,STATUS=6;
    localparam logic [20:0] P=(W/2)*H,N=W*H;
    localparam logic [9:0] LAST_Q=W/2-1;
    localparam logic [10:0] LAST_ROW=H-1;
    localparam logic [27:0] NO_LOCATION=28'd30; // loc_valid0,stage15，其余零。
    logic [2:0] state;
    logic fj_pending,fe_started,fe_status_seen,stream_started,cancel_seen,fe_cancel_sent;
    logic [162:0] fe_status_snapshot;
    logic [20:0] pair_counts[0:7],strong_pixels,weak_pixels;
    logic [9:0] expected_q[0:7];logic [10:0] expected_row[0:7];
    logic [7:0] observed_eof,legal_eof;
    logic [4:0] first_reason;logic [31:0] reason_mask;logic [27:0] first_location;
    wire owns_job=state!=IDLE&&state!=STATUS;
    wire all_private_empty=&private_empty;
    wire cj_fire=cj_valid&&cj_ready,fj_fire=fj_valid&&fj_ready;
    wire fs_fire=fs_valid&&fs_ready,derr_fire=derr_valid&&derr_ready;
    assign cj_ready=!rst&&state==IDLE&&all_private_empty&&!derr_valid;
    assign fj_valid=!rst&&fj_pending&&state!=IDLE&&state!=STATUS;
    assign fs_ready=!rst&&owns_job&&fe_started&&!fe_status_seen;
    assign derr_ready=!rst&&owns_job;
    assign stream_start=!rst&&state==ARM&&!cancel;
    assign data_flush=!rst&&state==ABORT_DRAIN;
    assign fe_cancel=!rst&&owns_job&&fe_started&&!fe_status_seen&&(cancel||state==ABORT_DRAIN);
    assign fp_allow=!rst&&state==RUN&&stream_started&&fe_started&&!cancel;
    assign ctx_live=!rst&&state!=IDLE;
    assign status_valid=!rst&&state==STATUS;

    // 临时计算先扩22位；FS同沿收尾核的是旧计数+真实fire，不误判合法末FO。
    logic [21:0] counts_after_fire[0:7],strong_after_fire,weak_after_fire;
    logic [7:0] eof_after_fire,legal_eof_after_fire;
    logic [31:0] event_reason_mask;
    logic [27:0] reason_locations[1:18];
    logic [4:0] chosen_reason;
    logic [27:0] chosen_location;
    logic [120:0] meta;
    logic meta_id_ok,meta_coordinate_ok,meta_markers_ok;
    logic grad_lane_bad[0:1];
    logic signed [11:0] grad_x,grad_y;
    logic complete_counts,completion_base;

    function automatic [27:0] pixel_location(input logic [10:0] x,y,
        input logic lane,input logic [3:0] stage);
        logic [11:0] full_x;
        begin
            full_x={1'b0,x}+{11'b0,lane};
            pixel_location=(full_x<=12'd2047) ? {y,full_x[10:0],lane,stage,1'b1} : NO_LOCATION;
        end
    endfunction
    // 同一原因多个来源时保留最先调用的上游位置；不同原因另按固定优先级选first。
    task automatic observe_reason(input integer code,input logic [27:0] location);
        begin
            if(!event_reason_mask[code]) reason_locations[code]=location;
            event_reason_mask[code]=1'b1;
        end
    endtask
    always_comb begin : collect_old_state_events
        event_reason_mask=0;chosen_reason=0;chosen_location=NO_LOCATION;
        eof_after_fire=observed_eof;legal_eof_after_fire=legal_eof;
        strong_after_fire={1'b0,strong_pixels};weak_after_fire={1'b0,weak_pixels};
        meta=0;meta_id_ok=0;meta_coordinate_ok=0;meta_markers_ok=0;
        grad_x=0;grad_y=0;
        for(integer code=1;code<=18;code=code+1) reason_locations[code]=NO_LOCATION;
        for(integer lane=0;lane<2;lane=lane+1) grad_lane_bad[lane]=0;
        for(integer port_index=0;port_index<8;port_index=port_index+1)
            counts_after_fire[port_index]={1'b0,pair_counts[port_index]}
                + (owns_job&&event_fire[port_index]?22'd1:22'd0);

        if(owns_job) begin
            if(cancel&&!cancel_seen) observe_reason(1,NO_LOCATION);
            if(fs_fire) begin
                if(fs[98:3]!=ctx_cj[95:0]||fs[2:0]==3'd7
                    ||{1'b0,fs[119:99]}!=counts_after_fire[0]
                    ||{1'b0,fs[140:120]}!=counts_after_fire[1]) observe_reason(10,NO_LOCATION);
                case(fs[2:0])
                    3'd1:if(!fe_cancel_sent) observe_reason(4,NO_LOCATION);
                    3'd2:observe_reason(5,pixel_location(fs[151:141],fs[162:152],1'b0,4'd1));
                    3'd3:observe_reason(6,pixel_location(fs[151:141],fs[162:152],1'b0,4'd1));
                    3'd4:observe_reason(7,pixel_location(fs[151:141],fs[162:152],1'b0,4'd1));
                    3'd5:observe_reason(8,NO_LOCATION);
                    3'd6:observe_reason(9,NO_LOCATION);
                    default:begin end
                endcase
            end
            for(integer port_index=0;port_index<8;port_index=port_index+1) begin
                // DERR在Sobel之后、D4之前，确保相同STREAM_ID的来源次序。
                if(port_index==4&&derr_fire) begin
                    observe_reason(11,derr[23]?{derr[21:11],derr[10:0],derr[22],4'd5,1'b1}:NO_LOCATION);
                    if(derr[119:24]!=ctx_cj[95:0])
                        observe_reason(12,derr[23]?{derr[21:11],derr[10:0],derr[22],4'd5,1'b1}:NO_LOCATION);
                end
                if(event_fire[port_index]) begin
                    meta=event_metadata[port_index*121 +: 121];
                    meta_id_ok=meta[117:22]==ctx_cj[95:0];
                    meta_coordinate_ok=meta[10:0]=={expected_q[port_index],1'b0}
                        &&meta[21:11]==expected_row[port_index];
                    meta_markers_ok=meta[118]==(expected_q[port_index]==0&&expected_row[port_index]==0)
                        &&meta[119]==(expected_q[port_index]==LAST_Q)
                        &&meta[120]==(expected_q[port_index]==LAST_Q&&expected_row[port_index]==LAST_ROW);
                    if(meta[120]) eof_after_fire[port_index]=1;
                    if(pair_counts[port_index]==P-1&&meta_id_ok&&meta_coordinate_ok&&meta_markers_ok&&meta[120])
                        legal_eof_after_fire[port_index]=1;
                    // RGB合法性由原FE负责；其余真实内部口在这里检查原metadata。
                    if(port_index!=0) begin
                        if(!meta_id_ok) observe_reason(12,pixel_location(meta[10:0],meta[21:11],1'b0,port_index+1));
                        if(!meta_coordinate_ok) observe_reason(13,pixel_location(meta[10:0],meta[21:11],1'b0,port_index+1));
                        if(!meta_markers_ok) observe_reason(14,pixel_location(meta[10:0],meta[21:11],1'b0,port_index+1));
                    end
                    if(counts_after_fire[port_index]>{1'b0,P}||(port_index==7&&!ctx_cj[141]))
                        observe_reason(15,pixel_location(meta[10:0],meta[21:11],1'b0,port_index+1));
                    if(port_index==6) begin
                        for(integer lane=0;lane<2;lane=lane+1) begin
                            case(event_classes[lane*2 +: 2])
                                2'b10:strong_after_fire=strong_after_fire+22'd1;
                                2'b01:weak_after_fire=weak_after_fire+22'd1;
                                2'b11:observe_reason(16,pixel_location(meta[10:0],meta[21:11],lane,4'd7));
                                default:begin end
                            endcase
                        end
                    end
                    if(port_index==7) begin
                        for(integer lane=0;lane<2;lane=lane+1) begin
                            grad_x=$signed({event_grad[lane*32+10],event_grad[lane*32 +: 11]});
                            grad_y=$signed({event_grad[lane*32+21],event_grad[lane*32+11 +: 11]});
                            grad_lane_bad[lane]=event_grad[lane*32+24 +: 8]!=0
                                ||grad_x < -12'sd1020||grad_x > 12'sd1020
                                ||grad_y < -12'sd1020||grad_y > 12'sd1020;
                            if(grad_lane_bad[lane]) observe_reason(18,pixel_location(meta[10:0],meta[21:11],lane,4'd8));
                        end
                    end
                end
            end
            if(strong_after_fire>{1'b0,N}||weak_after_fire>{1'b0,N}
                ||strong_after_fire+weak_after_fire>{1'b0,N}) observe_reason(17,NO_LOCATION);
        end
        complete_counts=1;
        for(integer port_index=0;port_index<7;port_index=port_index+1)
            if(pair_counts[port_index]!=P||!legal_eof[port_index]||!observed_eof[port_index]) complete_counts=0;
        if(ctx_cj[141]) begin
            if(pair_counts[7]!=P||!legal_eof[7]||!observed_eof[7]) complete_counts=0;
        end else if(pair_counts[7]!=0||observed_eof[7]||legal_eof[7]) complete_counts=0;
        completion_base=state==DRAIN&&stream_started&&fe_started&&fe_status_seen&&!fj_pending
            &&fe_status_snapshot[2:0]==0&&all_private_empty&&!derr_valid;
        if(completion_base&&!complete_counts) observe_reason(15,NO_LOCATION);
        // 原因优先级不依赖上面程序文字顺序；mask始终保留全部同沿原因。
        if(event_reason_mask[1]) chosen_reason=1;
        else if(event_reason_mask[10]) chosen_reason=10;
        else if(event_reason_mask[4]) chosen_reason=4;
        else if(event_reason_mask[5]) chosen_reason=5;
        else if(event_reason_mask[6]) chosen_reason=6;
        else if(event_reason_mask[7]) chosen_reason=7;
        else if(event_reason_mask[8]) chosen_reason=8;
        else if(event_reason_mask[9]) chosen_reason=9;
        else if(event_reason_mask[11]) chosen_reason=11;
        else if(event_reason_mask[12]) chosen_reason=12;
        else if(event_reason_mask[13]) chosen_reason=13;
        else if(event_reason_mask[14]) chosen_reason=14;
        else if(event_reason_mask[16]) chosen_reason=16;
        else if(event_reason_mask[18]) chosen_reason=18;
        else if(event_reason_mask[15]) chosen_reason=15;
        else if(event_reason_mask[17]) chosen_reason=17;
        if(chosen_reason!=0) chosen_location=reason_locations[chosen_reason];
    end

    wire [591:0] current_terminal={fe_status_snapshot,weak_pixels,strong_pixels,observed_eof,
        pair_counts[7],pair_counts[6],pair_counts[5],pair_counts[4],pair_counts[3],pair_counts[2],pair_counts[1],pair_counts[0],
        first_location,cancel_seen,stream_started,fe_status_seen,fe_started,reason_mask,first_reason,ctx_cj};
    // STATUS owns and holds every terminal field until status_ready. Publishing
    // these retained registers directly avoids a duplicate 592-bit snapshot.
    // Transition guards exclude new events/FS/DERR, so the terminal values are
    // identical to the old snapshot on every valid cycle, including stalls.
    assign status_payload=current_terminal;
    always_ff @(posedge clk) begin : task_lifecycle
        if(rst) begin
            state<=IDLE;ctx_cj<=0;fj<=0;fj_pending<=0;
            fe_started<=0;fe_status_seen<=0;stream_started<=0;cancel_seen<=0;fe_cancel_sent<=0;
            fe_status_snapshot<=0;observed_eof<=0;legal_eof<=0;strong_pixels<=0;weak_pixels<=0;
            first_reason<=0;reason_mask<=0;first_location<=NO_LOCATION;
            for(integer port_index=0;port_index<8;port_index=port_index+1) begin
                pair_counts[port_index]<=0;expected_q[port_index]<=0;expected_row[port_index]<=0;
            end
        end else begin
            if(owns_job) begin
                observed_eof<=eof_after_fire;legal_eof<=legal_eof_after_fire;
                strong_pixels<=strong_after_fire[20:0];weak_pixels<=weak_after_fire[20:0];
                reason_mask<=reason_mask|event_reason_mask;
                if(first_reason==0&&chosen_reason!=0) begin first_reason<=chosen_reason;first_location<=chosen_location;end
                if(cancel) cancel_seen<=1;
                if(fe_cancel&&!fs_valid) fe_cancel_sent<=1;
                if(fj_fire) begin fj_pending<=0;fe_started<=1;end
                if(fs_fire) begin fe_status_seen<=1;fe_status_snapshot<=fs;end
                for(integer port_index=0;port_index<8;port_index=port_index+1) begin
                    if(event_fire[port_index]) begin
                        pair_counts[port_index]<=counts_after_fire[port_index][20:0];
                        if(pair_counts[port_index]<P-1) begin
                            if(expected_q[port_index]==LAST_Q) begin
                                expected_q[port_index]<=0;expected_row[port_index]<=expected_row[port_index]+11'd1;
                            end else expected_q[port_index]<=expected_q[port_index]+10'd1;
                        end
                    end
                end
            end
            case(state)
                IDLE:if(cj_fire) begin
                    ctx_cj<=cj;fj_pending<=0;fe_started<=0;fe_status_seen<=0;stream_started<=0;
                    cancel_seen<=0;fe_cancel_sent<=0;fe_status_snapshot<=0;
                    observed_eof<=0;legal_eof<=0;strong_pixels<=0;weak_pixels<=0;
                    first_reason<=0;reason_mask<=0;first_location<=NO_LOCATION;
                    for(integer port_index=0;port_index<8;port_index=port_index+1) begin
                        pair_counts[port_index]<=0;expected_q[port_index]<=0;expected_row[port_index]<=0;
                    end
                    if(cj[106:96]!=W||cj[117:107]!=H) begin
                        first_reason<=2;reason_mask<=(32'd1<<2)|(cj[128:118]>cj[139:129]?(32'd1<<3):32'd0);state<=ABORT_DRAIN;
                    end else if(cj[128:118]>cj[139:129]) begin first_reason<=3;reason_mask<=32'd1<<3;state<=ABORT_DRAIN;end
                    else state<=ARM;
                end
                ARM:if(!cancel) begin
                    fj<={13'b0,ctx_cj[140],ctx_cj[95:0]};fj_pending<=1;stream_started<=1;state<=WAIT_FE;
                end
                WAIT_FE:if(fj_fire) state<=RUN;
                RUN:if(event_fire[0]&&pair_counts[0]==P-1) state<=DRAIN;
                DRAIN:if(completion_base&&complete_counts&&first_reason==0&&reason_mask==0
                    &&event_reason_mask==0&&event_fire==0&&!fs_fire&&!derr_fire) begin
                    state<=STATUS;
                end
                ABORT_DRAIN:if(first_reason!=0&&!fj_pending&&(!fe_started||fe_status_seen)
                    &&all_private_empty&&!derr_valid&&event_reason_mask==0&&event_fire==0&&!fs_fire&&!derr_fire) begin
                    state<=STATUS;
                end
                STATUS:if(status_ready) state<=IDLE;
                default:state<=IDLE;
            endcase
            if(owns_job&&event_reason_mask!=0) state<=ABORT_DRAIN;
        end
    end
    // synthesis translate_off
    initial if(W<6||W>1920||W%2!=0||H<5||H>1080) $fatal(1,"C0 dimensions");
    // synthesis translate_on
endmodule
