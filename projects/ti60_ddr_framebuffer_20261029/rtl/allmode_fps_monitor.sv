// Read-only measurement in the 74.25 MHz video pixel-pair clock domain.
// C: complete CSI frames; P: successful frontend jobs (Canny jobs in M5).
// D: complete display scans with all required rows (new Canny results in M5).
// H: VS refresh events. D in M0-M4 can repeat a captured sensor frame.
// Counts wrap at 16 bits, restart on mode change; rates saturate at 65535.
// Registered Gray CDC for C; Canny counters already use the existing coherent
// video-domain diagnostic snapshot. No control output feeds the video path.
module allmode_fps_monitor #(
    parameter integer CLOCK_HZ=74250000,
    parameter integer PAIRS_PER_FRAME=1036800
)(
    input wire clk,rst,
    input wire [31:0] camera_gray_async,raw_gray_async,rejected_gray_async,
    input wire [4:0] rejection_reasons_async,
    output reg [31:0] source_counts,source_rates,
    output reg [4:0] source_reasons,
    input wire [2:0] mode,
    input wire vs,de,algorithm_complete,display_missing,
    input wire [15:0] canny_jobs,canny_frame,
    input wire canny_available,
    output reg [63:0] counts,rates,
    output reg [15:0] bad_frames,
    output reg rates_valid
);
    (* ASYNC_REG="TRUE" *) reg [31:0] camera_meta,camera_sync;
    (* ASYNC_REG="TRUE" *) reg [31:0] raw_meta,raw_sync,rejected_meta,rejected_sync;
    // Reasons are independent sticky bits. Each has its own two-flop synchronizer.
    (* ASYNC_REG="TRUE" *) reg [4:0] reasons_meta,reasons_sync;
    reg [31:0] raw_origin,raw_window,rejected_origin,rejected_window;
    reg [31:0] source_measured_rates;
    wire [31:0] raw_count=from_gray(raw_sync),rejected_count=from_gray(rejected_sync);
    wire [31:0] raw_total=raw_count-raw_origin,rejected_total=rejected_count-rejected_origin;
    reg [2:0] warm;
    function automatic [31:0] from_gray(input [31:0] g);
        integer k;
        begin
            from_gray[31]=g[31];
            for(k=30;k>=0;k=k-1) from_gray[k]=from_gray[k+1]^g[k];
        end
    endfunction
    function automatic [15:0] sat16(input [31:0] value);
        sat16=(|value[31:16])?16'hffff:value[15:0];
    endfunction
    wire [31:0] camera_count=from_gray(camera_sync);
    reg [31:0] camera_origin,camera_window;
    reg [2:0] mode_d,frame_mode;
    reg vs_d,frame_armed,frame_bad;
    reg [20:0] frame_pairs;
    reg [15:0] jobs_d,handle_d;
    reg [15:0] total_p,total_d,total_h,errors;
    reg [15:0] window_p,window_d,window_h;
    reg [$clog2(CLOCK_HZ)-1:0] ticks;
    reg [63:0] measured_rates;
    reg measured_valid;
    wire frame_edge=vs&&!vs_d;
    wire same_mode=mode==mode_d;
    wire eligible_frame=frame_edge&&frame_armed&&frame_mode==mode&&same_mode;
    wire complete_scan=eligible_frame&&frame_pairs==PAIRS_PER_FRAME&&!frame_bad;
    wire [15:0] canny_job_delta=canny_jobs-jobs_d;
    wire [15:0] p_step=(mode==5)?canny_job_delta:{15'd0,algorithm_complete};
    // Count publications, not differences between handles (failed attempts can
    // leave handle gaps). The existing display handshake accepts at most one
    // result per display scan. Track handles even while outside M5.
    wire d_step=(mode==5)?(canny_available&&canny_frame!=handle_d):complete_scan;
    wire [31:0] p_next={16'd0,window_p}+{16'd0,p_step};
    wire [31:0] d_next={16'd0,window_d}+{31'd0,d_step};
    wire [31:0] h_next={16'd0,window_h}+{31'd0,frame_edge};
    wire [31:0] c_elapsed=camera_count-camera_window;
    wire [31:0] c_total=camera_count-camera_origin;
    always @(posedge clk)begin
        if(rst)begin
            camera_meta<=0;camera_sync<=0;warm<=0;
            raw_meta<=0;raw_sync<=0;rejected_meta<=0;rejected_sync<=0;
            reasons_meta<=0;reasons_sync<=0;source_reasons<=0;
            raw_origin<=0;raw_window<=0;rejected_origin<=0;rejected_window<=0;
            source_counts<=0;source_rates<=0;source_measured_rates<=0;
            mode_d<=0;vs_d<=0;frame_mode<=0;frame_armed<=0;
            frame_bad<=0;frame_pairs<=0;jobs_d<=0;handle_d<=0;
            camera_origin<=0;camera_window<=0;ticks<=0;
            total_p<=0;total_d<=0;total_h<=0;errors<=0;
            window_p<=0;window_d<=0;window_h<=0;
            measured_rates<=0;measured_valid<=0;
            counts<=0;rates<=0;bad_frames<=0;rates_valid<=0;
        end else begin
            camera_meta<=camera_gray_async;camera_sync<=camera_meta;
            raw_meta<=raw_gray_async;raw_sync<=raw_meta;
            rejected_meta<=rejected_gray_async;rejected_sync<=rejected_meta;
            reasons_meta<=rejection_reasons_async;reasons_sync<=reasons_meta;
            warm<={warm[1:0],1'b1};
            mode_d<=mode;vs_d<=vs;jobs_d<=canny_jobs;handle_d<=canny_frame;
            if(frame_edge)begin
                frame_armed<=1;frame_mode<=mode;
                // VS normally lies in blanking; simultaneous DE is malformed.
                frame_pairs<=de?21'd1:21'd0;frame_bad<=de;
            end else if(de&&frame_armed)begin
                if(frame_pairs!=21'h1fffff)frame_pairs<=frame_pairs+21'd1;
                if(display_missing||frame_pairs==21'h1fffff)frame_bad<=1;
            end
            if(!warm[2]||!same_mode)begin
                camera_origin<=camera_count;camera_window<=camera_count;
                raw_origin<=raw_count;raw_window<=raw_count;
                rejected_origin<=rejected_count;rejected_window<=rejected_count;
                source_counts<=0;source_rates<=0;source_measured_rates<=0;
                ticks<=0;total_p<=0;total_d<=0;total_h<=0;errors<=0;
                window_p<=0;window_d<=0;window_h<=0;
                measured_rates<=0;measured_valid<=0;
                counts<=0;rates<=0;bad_frames<=0;rates_valid<=0;
            end else begin
                total_p<=total_p+p_step;total_d<=total_d+{15'd0,d_step};
                total_h<=total_h+{15'd0,frame_edge};
                if(eligible_frame&&!complete_scan&&errors!=16'hffff)errors<=errors+16'd1;
                if(ticks==CLOCK_HZ-1)begin
                    ticks<=0;camera_window<=camera_count;
                    raw_window<=raw_count;rejected_window<=rejected_count;
                    source_measured_rates<={sat16(rejected_count-rejected_window),sat16(raw_count-raw_window)};
                    measured_rates<={sat16(h_next),sat16(d_next),sat16(p_next),sat16(c_elapsed)};
                    measured_valid<=1;window_p<=0;window_d<=0;window_h<=0;
                end else begin
                    ticks<=ticks+1'b1;
                    window_p<=sat16(p_next);window_d<=sat16(d_next);window_h<=sat16(h_next);
                end
                // Hold text values for the entire output frame. Rates are the
                // last full one-second window, with <= one scan publication lag.
                if(frame_edge)begin
                    counts<={total_h,total_d,total_p,c_total[15:0]};
                    source_counts<={rejected_total[15:0],raw_total[15:0]};
                    source_rates<=source_measured_rates;source_reasons<=reasons_sync;
                    rates<=measured_rates;rates_valid<=measured_valid;bad_frames<=errors;
                end
            end
        end
    end
endmodule
