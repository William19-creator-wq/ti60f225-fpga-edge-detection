// v7 扫描适配：算法不得反压 HDMI。六行延迟保留原图，结果按同帧同坐标取回。
// 输入低 24 位为前一个像素，像素内部高字节为实际显示红色；不沿用旧信号名猜颜色。
module integration_video_presenter #(
    parameter integer W=1920, H=1080, HTOTAL=1100,
    parameter integer RUNTIME_FILTER_CONFIG=0, RUNTIME_EDGE_CONFIG=0,CANNY_AVAILABLE=0,
    parameter integer MEDIAN_DETAIL_DIFF=16, MEDIAN_DETAIL_SIMILARITY=4,
    parameter integer SOBEL_COHERENCE_MIN_DIFF=20,
    // v3：候选B，仅补三项全部同向的较弱轮廓；原T64/D20分支保留。
    parameter integer SOBEL_WEAK_MIN_DIFF=18,
    parameter integer SOBEL_WEAK_THRESHOLD_DROP=0,
    parameter integer EDGE_CONTEXT_THRESHOLD_DROP=16,
    parameter integer EDGE_THIN_MODE=1,
    parameter integer DIAGONAL_MIN_DIFF=18
)(
    input wire clk, rst,
    input wire in_vs, in_hs, in_de,
    input wire [47:0] in_rgb,
    input wire [1:0] in_canny_edge,
    input wire cfg_overlay_canny,cfg_wide_overlay,
    input wire [1:0] cfg_compare, // 0 gray/median, 1 gray/Sobel, 2 gray/absolute difference
    input wire [2:0] cfg_mode,
    input wire [10:0] cfg_threshold,
    input wire cfg_median_enable,
    input wire cfg_detail_enable,
    input wire cfg_edge_enhance,
    input wire [31:0] cfg_config_id,
    output reg [2:0] active_mode,
    output reg [10:0] active_threshold,
    output reg [1:0] active_filter,
    output reg active_edge_enhance,
    output wire active_overlay_canny,active_wide_overlay,output wire [1:0] active_compare,
    output reg out_vs, out_hs, out_de,
    output reg [47:0] out_rgb,
    output reg sticky_fault
);
    localparam integer DELAY=6*HTOTAL;
    // Preserve timing independently from ROI reads. At M7 both halves use
    // x=W/4..3W/4-1 of the SAME row/frame at 1:1 pixel spacing.
    wire [53:0] scan_read;
    wire [49:0] remapped_payload;
    wire [2:0] timing_read;
    wire timing_ready,payload_ready;
    wire scan_ready=timing_ready&&payload_ready;
    reg [2:0] frame_mode;
    reg [1:0] frame_compare;
    reg frame_overlay_canny;
    reg display_overlay_canny;reg [1:0] display_compare;reg frame_wide,display_wide;
    assign active_overlay_canny=display_overlay_canny;assign active_wide_overlay=display_wide;assign active_compare=display_compare;
    reg [10:0] display_x,display_y;
    wire [10:0] offset_x=timing_read[0]?(display_x==W-2?11'd0:display_x+11'd2):display_x;
    wire signed [13:0] roi_offset=active_mode==7?(offset_x<W/2?14'(W/8):-14'(W/8)):14'sd0;
    scan_offset_ram #(.WIDTH(3),.DELAY(DELAY),.MAX_OFFSET(0),.RAM_WIDTH(5)) scan_timing(
        .clk,.rst,.in_data({in_vs,in_hs,in_de}),.read_offset(14'sd0),.out_data(timing_read),.valid(timing_ready));
    scan_offset_ram #(.WIDTH(50),.DELAY(DELAY),.MAX_OFFSET(W/8),.RAM_WIDTH(10)) scan_payload(
        .clk,.rst,.in_data({in_canny_edge,in_rgb}),.read_offset(roi_offset),.out_data(remapped_payload),.valid(payload_ready));
    assign scan_read={active_mode,timing_read,remapped_payload[47:0]};
    wire [1:0] delayed_canny=remapped_payload[49:48];
    reg [10:0] frame_threshold;
    reg frame_median;
    reg frame_detail,frame_edge_enhance;
    reg [31:0] frame_config_id;
    reg input_vs_d;
    wire frame_boundary=in_vs&&!input_vs_d;
    reg [31:0] input_frame;
    reg [10:0] input_x,input_y;
    reg job_pending,frame_armed,drop_frame;
    wire job_ready,algorithm_ready;
    wire job_fire=job_pending&&job_ready&&!frame_boundary;
    wire input_valid=in_de&&frame_armed&&!drop_frame;
    wire algorithm_valid;
    wire [15:0] filtered_pair;
    wire [1:0] edge_pair;
    wire [10:0] algorithm_x,algorithm_y;
    wire algorithm_eol;
    wire [31:0] algorithm_frame;
    wire status_valid;
    wire [2:0] status_code;

    // 此桥接固定external_sobel_owner=0；只在本版摄像显示路径启用方向支持。
    frontend_frame_pair #(.W(W),.H(H),.MEDIAN_DETAIL_ENABLE(1),.RUNTIME_FILTER_CONFIG(RUNTIME_FILTER_CONFIG),.RUNTIME_EDGE_CONFIG(RUNTIME_EDGE_CONFIG),
        .MEDIAN_DETAIL_DIFF(MEDIAN_DETAIL_DIFF),.MEDIAN_DETAIL_SIMILARITY(MEDIAN_DETAIL_SIMILARITY),.SOBEL_COHERENCE_ENABLE(1),
        .SOBEL_COHERENCE_MIN_DIFF(SOBEL_COHERENCE_MIN_DIFF),.SOBEL_WEAK_ENABLE(1),
        .SOBEL_WEAK_MIN_DIFF(SOBEL_WEAK_MIN_DIFF),
        .SOBEL_WEAK_THRESHOLD_DROP(SOBEL_WEAK_THRESHOLD_DROP),.EDGE_CONTEXT_ENABLE(1),
        .EDGE_CONTEXT_THRESHOLD_DROP(EDGE_CONTEXT_THRESHOLD_DROP),
        .EDGE_THIN_ENABLE(1),.EDGE_THIN_MODE(EDGE_THIN_MODE),
        .DIAGONAL_ENABLE(1),.DIAGONAL_MIN_DIFF(DIAGONAL_MIN_DIFF)) algorithms(
        .clk(clk),.rst(rst||frame_boundary),
        .job_valid(job_pending&&!frame_boundary),.job_ready(job_ready),
        .job_epoch(32'd1),.job_frame_id(input_frame),.job_config_id(RUNTIME_FILTER_CONFIG?frame_config_id:input_frame),
        .job_detail_enable(frame_detail),.job_edge_enhance(frame_edge_enhance),
        .job_median_enable(frame_median),.job_output_kind(2'd1),.job_threshold(frame_threshold),
        .in_valid(input_valid),.in_ready(algorithm_ready),.in_rgb(in_rgb),
        .in_x_even(input_x),.in_y(input_y),
        .in_sof(input_x==0&&input_y==0),.in_eol(input_x==W-2),
        .in_eof(input_x==W-2&&input_y==H-1),.in_bad(1'b0),
        .out_valid(algorithm_valid),.out_ready(1'b1),.out_y_filtered(filtered_pair),
        .out_edge(edge_pair),.out_x_even(algorithm_x),.out_y(algorithm_y),
        .out_sof(),.out_eol(algorithm_eol),.out_eof(),
        .out_epoch(),.out_frame_id(algorithm_frame),.out_config_id(),.cancel(drop_frame),
        .external_sobel_owner(1'b0),.external_sobel_start(1'b0),
        .external_sobel_flush(1'b0),.external_sobel_open(1'b0),
        .external_sobel_in_valid(1'b0),.external_sobel_in_ready(),
        .external_sobel_input(41'd0),.external_sobel_out_valid(),
        .external_sobel_out_ready(1'b1),.external_sobel_output(),.external_sobel_empty(),
        .status_valid(status_valid),.status_ready(1'b1),.status_code(status_code),
        .status_epoch(),.status_frame_id(),.status_config_id(),
        .status_in_pairs(),.status_out_pairs(),.status_error_x(),.status_error_y()
    );

    // 八行结果环形缓存。只在行尾发布标签，显示不会读半行或上一帧同槽数据。
    reg [17:0] result_memory[0:8191];
    reg [7:0] row_complete;
    // Same lifetime as overlay_edge_history: vertical blank exceeds six
    // delayed rows, so the first completed row of the next frame may retire
    // all previous row tags. Retain the FULL frame ID, shared by eight slots.
    reg [31:0] result_frame;
    reg result_initialized;
    reg [10:0] row_number[0:7];
    wire [12:0] result_write_address={algorithm_y[2:0],algorithm_x[10:1]};
    reg [31:0] display_frame;
    reg delayed_vs_d;
    wire delayed_vs=scan_read[50];
    wire delayed_hs=scan_read[49];
    wire delayed_de=scan_read[48];
    wire [10:0] result_x=active_mode==7?(display_x<W/2?display_x+11'(W/4):display_x-11'(W/4)):display_x;
    wire [12:0] result_read_address={display_y[2:0],result_x[10:1]};
    wire row_matches=row_complete[display_y[2:0]]&&
        result_initialized&&result_frame==display_frame&&row_number[display_y[2:0]]==display_y;
    reg [17:0] result_read;
    reg [53:0] pixel_pending;
    reg [10:0] x_pending;
    reg pending_ready,pending_result;reg [1:0] canny_pending;
    // Only one edge source is displayed per frame. Select at the INPUT
    // frame boundary, not from delayed display configuration or live keys.
    // The source's valid, coordinates and full frame ID travel together.
    // Existing vertical blank drains the six-line display delay before the
    // next frame writes this ring; overlay_edge_history checks row/frame tags.
    wire history_canny=(frame_mode==6)||frame_overlay_canny;
    wire [1:0] selected_vertical;
    overlay_edge_history #(.W(W),.H(H)) selected_width(
        .clk,.rst,.write_valid(history_canny?in_de:algorithm_valid),
        .write_edges(history_canny?in_canny_edge:edge_pair),
        .write_x(history_canny?input_x:algorithm_x),
        .write_y(history_canny?input_y:algorithm_y),
        .write_frame(history_canny?input_frame:algorithm_frame),
        .read_valid(scan_ready&&delayed_de),.read_x(result_x),.read_y(display_y),
        .read_frame(display_frame),.vertical_edges(selected_vertical));
    reg stage_vs,stage_hs,stage_de,stage_overlay;
    reg [47:0] stage_rgb;reg [1:0] stage_vertical;reg stage_left;
    reg [10:0] stage_x;
    wire next_neighbour=pending_ready&&pixel_pending[48]&&x_pending==stage_x+11'd2&&stage_x!=W-2;
    wire [1:0] expanded_edges={stage_vertical[0]|stage_vertical[1]|(next_neighbour&&selected_vertical[0]),
                              stage_left|stage_vertical[0]|stage_vertical[1]};


    function automatic [7:0] gray8(input reg [23:0] rgb);
        reg [15:0] r,g,b,total;
        begin
            r={8'd0,rgb[23:16]};g={8'd0,rgb[15:8]};b={8'd0,rgb[7:0]};
            total=(r<<6)+(r<<3)+(r<<2)+r+(g<<7)+(g<<4)+(g<<2)+(g<<1)+
                  (b<<4)+(b<<3)+(b<<2)+b+16'd128;
            gray8=total[15:8];
        end
    endfunction
    function automatic [23:0] display_pixel(
        input reg [23:0] rgb,input reg [7:0] filtered,input reg edge_value,
        input reg available,input reg [2:0] mode,input reg [10:0] x,input reg canny_edge
    );
        reg [2:0] selected;
        reg [7:0] gray;
        begin
            selected=mode;
            if(mode==5&&!CANNY_AVAILABLE)begin
                if(x<W/5)selected=0;
                else if(x<(W*2)/5)selected=1;
                else if(x<(W*3)/5)selected=2;
                else if(x<(W*4)/5)selected=3;
                else selected=4;
            end
            gray=gray8(rgb);
            display_pixel=rgb;
            case(selected)
                1:display_pixel={gray,gray,gray};
                2:if(available)display_pixel={filtered,filtered,filtered};
                3:if(available)display_pixel={24{edge_value}};
                4:if(display_overlay_canny?canny_edge:(available&&edge_value))display_pixel=24'hff0000;
                5:display_pixel={24{canny_edge}};
                6:if(canny_edge)display_pixel=24'hff0000;
                7:begin
                    if(x<W/2)display_pixel={3{gray}};
                    else if(display_compare==1)display_pixel=available?{24{edge_value}}:24'd0;
                    else if(display_compare==2)begin
                        gray=gray>filtered?gray-filtered:filtered-gray;
                        display_pixel=available?{3{gray}}:24'd0;
                    end else display_pixel=available?{3{filtered}}:24'd0;
                end
                default:display_pixel=rgb;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if(rst)begin
            input_vs_d<=0;input_frame<=0;input_x<=0;input_y<=0;
            frame_mode<=0;frame_threshold<=256;frame_median<=1;frame_compare<=0;frame_overlay_canny<=0;
            frame_detail<=0;frame_edge_enhance<=1;frame_config_id<=0;frame_wide<=1;
            job_pending<=0;frame_armed<=0;drop_frame<=0;
        end else begin
            input_vs_d<=in_vs;
            if(frame_boundary)begin
                input_frame<=input_frame+32'd1;input_x<=0;input_y<=0;
                frame_mode<=cfg_mode;frame_threshold<=cfg_threshold;frame_median<=cfg_median_enable;
                frame_compare<=cfg_compare;frame_overlay_canny<=cfg_overlay_canny;frame_wide<=cfg_wide_overlay;
                frame_detail<=RUNTIME_FILTER_CONFIG?cfg_detail_enable:1'b1;
                frame_edge_enhance<=RUNTIME_EDGE_CONFIG?cfg_edge_enhance:1'b1;
                frame_config_id<=cfg_config_id;
                job_pending<=1;frame_armed<=0;drop_frame<=0;
            end else begin
                if(job_fire)begin job_pending<=0;frame_armed<=1;end
                if(input_valid&&!algorithm_ready)drop_frame<=1;
                if(in_de)begin
                    if(input_x==W-2)begin input_x<=0;input_y<=input_y==H-1?11'd0:input_y+11'd1;end
                    else input_x<=input_x+11'd2;
                end
            end
        end
    end

    always @(posedge clk) begin
        if(algorithm_valid)result_memory[result_write_address]<={edge_pair,filtered_pair};
        if(scan_ready&&delayed_de)result_read<=result_memory[result_read_address];
    end
    always @(posedge clk)begin
        if(rst)begin
            row_complete<=0;result_frame<=0;result_initialized<=0;
            for(integer i=0;i<8;i=i+1)begin row_number[i]<=0;end
        end else if(algorithm_valid&&algorithm_eol)begin
            if(!result_initialized||result_frame!=algorithm_frame)
                row_complete<=8'b1<<algorithm_y[2:0];
            else row_complete[algorithm_y[2:0]]<=1;
            result_frame<=algorithm_frame;result_initialized<=1;
            row_number[algorithm_y[2:0]]<=algorithm_y;
        end
    end
    always @(posedge clk)begin
        if(rst)begin
            display_frame<=0;display_x<=0;display_y<=0;delayed_vs_d<=0;
            pending_ready<=0;pending_result<=0;pixel_pending<=0;x_pending<=0;canny_pending<=0;
            out_rgb<=0;out_vs<=0;out_hs<=0;out_de<=0;sticky_fault<=0;
            display_overlay_canny<=0;display_compare<=0;display_wide<=1;
            stage_vs<=0;stage_hs<=0;stage_de<=0;stage_rgb<=0;stage_vertical<=0;stage_left<=0;stage_x<=0;stage_overlay<=0;active_mode<=0;active_threshold<=64;active_filter<=1;active_edge_enhance<=1;
        end else begin
            pending_ready<=scan_ready;
            pixel_pending<=scan_read;x_pending<=display_x;canny_pending<=delayed_canny;
            pending_result<=scan_ready&&delayed_de&&row_matches;
            if(scan_ready)begin
                delayed_vs_d<=delayed_vs;
                if(delayed_vs&&!delayed_vs_d)begin
                    display_frame<=display_frame+32'd1;display_x<=0;display_y<=0;
                    display_overlay_canny<=frame_overlay_canny;display_compare<=frame_compare;display_wide<=frame_wide;
                    active_mode<=frame_mode;active_threshold<=frame_threshold;
                    active_filter<=!frame_median?2'd0:(frame_detail?2'd2:2'd1);
                    active_edge_enhance<=frame_edge_enhance;
                end else if(delayed_de)begin
                    if(display_x==W-2)begin display_x<=0;display_y<=display_y==H-1?11'd0:display_y+11'd1;end
                    else display_x<=display_x+11'd2;
                end
            end
            stage_vs<=pending_ready&&pixel_pending[50];
            stage_hs<=pending_ready&&pixel_pending[49];
            stage_de<=pending_ready&&pixel_pending[48];
            for(integer lane=0;lane<2;lane=lane+1)
                stage_rgb[lane*24+:24]<=display_pixel(pixel_pending[lane*24+:24],
                    result_read[lane*8+:8],result_read[16+lane],pending_result,
                    pixel_pending[53:51],x_pending+11'(lane),canny_pending[lane]);
            stage_x<=x_pending;stage_vertical<=selected_vertical;
            stage_left<=x_pending==0?1'b0:stage_vertical[1];
            stage_overlay<=display_wide&&(pixel_pending[53:51]==4||pixel_pending[53:51]==6);
            out_vs<=stage_vs;out_hs<=stage_hs;out_de<=stage_de;
            for(integer lane=0;lane<2;lane=lane+1)
                out_rgb[lane*24+:24]<=stage_de&&stage_overlay&&expanded_edges[lane]?24'hff0000:stage_rgb[lane*24+:24];
            if((input_valid&&!algorithm_ready)||(status_valid&&status_code!=0)||
               (scan_ready&&delayed_de&&display_frame!=0&&!row_matches))sticky_fault<=1;
        end
    end
    // synthesis translate_off
    initial begin
        if(W<4||W>1920||W%2||H<3||H>1080||HTOTAL<W/2+40||DELAY>=8192)
            $fatal(1,"Unsupported video geometry");
    end
    // synthesis translate_on
endmodule
