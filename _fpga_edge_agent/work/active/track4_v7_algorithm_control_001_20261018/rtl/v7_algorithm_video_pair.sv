// v7 扫描适配：算法不得反压 HDMI。四行延迟保留原图，结果按同帧同坐标取回。
// 输入低 24 位为前一个像素，像素内部高字节为实际显示红色；不沿用旧信号名猜颜色。
module v7_algorithm_video_pair #(
    parameter integer W=1920, H=1080, HTOTAL=1100, HUD_ENABLE=1
)(
    input wire clk, rst,
    input wire in_vs, in_hs, in_de,
    input wire [47:0] in_rgb,
    input wire [2:0] cfg_mode,
    input wire [10:0] cfg_threshold,
    input wire cfg_median_enable,
    output reg out_vs, out_hs, out_de,
    output reg [47:0] out_rgb,
    output reg sticky_fault
);
    localparam integer DELAY=4*HTOTAL;
    localparam integer DELAY_DEPTH=8192;
    // 固定时钟延迟，不按 valid 压缩；读写地址相隔 DELAY，避免同址 RAM 行为依赖。
    reg [64:0] scan_memory[0:DELAY_DEPTH-1];
    reg [12:0] scan_write, warm_count;
    wire [12:0] scan_read_address=scan_write-13'(DELAY);
    reg [64:0] scan_read;
    reg scan_ready;
    reg [2:0] frame_mode;
    reg [10:0] frame_threshold;
    reg frame_median;
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

    frontend_frame_pair #(.W(W),.H(H)) algorithms(
        .clk(clk),.rst(rst||frame_boundary),
        .job_valid(job_pending&&!frame_boundary),.job_ready(job_ready),
        .job_epoch(32'd1),.job_frame_id(input_frame),.job_config_id(input_frame),
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
    reg [31:0] row_frame[0:7];
    reg [10:0] row_number[0:7];
    wire [12:0] result_write_address={algorithm_y[2:0],algorithm_x[10:1]};
    reg [31:0] display_frame;
    reg [10:0] display_x,display_y;
    reg delayed_vs_d;
    wire delayed_vs=scan_read[50];
    wire delayed_hs=scan_read[49];
    wire delayed_de=scan_read[48];
    wire [12:0] result_read_address={display_y[2:0],display_x[10:1]};
    wire row_matches=row_complete[display_y[2:0]]&&
        row_frame[display_y[2:0]]==display_frame&&row_number[display_y[2:0]]==display_y;
    reg [17:0] result_read;
    reg [64:0] pixel_pending;
    reg [10:0] x_pending,y_pending;
    wire [47:0] rendered_pair;
    reg pending_ready,pending_result;

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
        input reg available,input reg [2:0] mode,input reg [10:0] x
    );
        reg [2:0] selected;
        reg [7:0] gray,difference,amplified;
        begin
            selected=mode;
            if(mode==5)begin
                if(x<W/5)selected=0;
                else if(x<(W*2)/5)selected=1;
                else if(x<(W*3)/5)selected=2;
                else if(x<(W*4)/5)selected=3;
                else selected=4;
            end
            gray=gray8(rgb);
            difference=gray>=filtered?gray-filtered:filtered-gray;
            amplified=difference>=32?8'd255:{difference[4:0],3'b000};
            display_pixel=rgb;
            case(selected)
                1:display_pixel={gray,gray,gray};
                2:if(available)display_pixel={filtered,filtered,filtered};
                3:if(available)display_pixel={24{edge_value}};
                4:if(available&&edge_value)display_pixel=24'hff0000;
                6:if(available)display_pixel={amplified,amplified,amplified};
                default:display_pixel=rgb;
            endcase
        end
    endfunction

    generate for(genvar lane=0;lane<2;lane=lane+1)begin:display_lane
        wire [10:0] pixel_x=x_pending+11'(lane);
        wire [23:0] processed=display_pixel(pixel_pending[lane*24+:24],
            result_read[lane*8+:8],result_read[16+lane],pending_result,
            pixel_pending[53:51],pixel_x);
        if(HUD_ENABLE)begin:status_enabled
            v7_algorithm_status_pixel status_pixel(.rgb(processed),.x(pixel_x),.y(y_pending),
                .mode(pixel_pending[53:51]),.threshold(pixel_pending[64:54]),
                .available(pending_result),.pixel(rendered_pair[lane*24+:24]));
        end else begin:status_disabled
            assign rendered_pair[lane*24+:24]=processed;
        end
    end endgenerate

    always @(posedge clk) begin
        if(rst)begin
            input_vs_d<=0;input_frame<=0;input_x<=0;input_y<=0;
            frame_mode<=0;frame_threshold<=256;frame_median<=1;
            job_pending<=0;frame_armed<=0;drop_frame<=0;
        end else begin
            input_vs_d<=in_vs;
            if(frame_boundary)begin
                input_frame<=input_frame+32'd1;input_x<=0;input_y<=0;
                frame_mode<=cfg_mode;frame_threshold<=cfg_threshold;frame_median<=cfg_median_enable;
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
        if(rst)begin scan_write<=0;warm_count<=0;scan_ready<=0;end
        else begin
            scan_write<=scan_write+13'd1;
            if(warm_count<DELAY)warm_count<=warm_count+13'd1;
            scan_ready<=warm_count>=DELAY;
        end
        // 不复位大 RAM；scan_ready 在首次完整填充之前隔离未初始化内容。
        scan_memory[scan_write]<={frame_threshold,frame_mode,in_vs,in_hs,in_de,in_rgb};
        scan_read<=scan_memory[scan_read_address];
        if(algorithm_valid)result_memory[result_write_address]<={edge_pair,filtered_pair};
        if(scan_ready&&delayed_de)result_read<=result_memory[result_read_address];
    end
    always @(posedge clk)begin
        if(rst)begin
            row_complete<=0;
            for(integer i=0;i<8;i=i+1)begin row_frame[i]<=0;row_number[i]<=0;end
        end else if(algorithm_valid&&algorithm_eol)begin
            row_complete[algorithm_y[2:0]]<=1;
            row_frame[algorithm_y[2:0]]<=algorithm_frame;
            row_number[algorithm_y[2:0]]<=algorithm_y;
        end
    end
    always @(posedge clk)begin
        if(rst)begin
            display_frame<=0;display_x<=0;display_y<=0;delayed_vs_d<=0;
            pending_ready<=0;pending_result<=0;pixel_pending<=0;x_pending<=0;y_pending<=0;
            out_rgb<=0;out_vs<=0;out_hs<=0;out_de<=0;sticky_fault<=0;
        end else begin
            pending_ready<=scan_ready;
            pixel_pending<=scan_read;x_pending<=display_x;y_pending<=display_y;
            pending_result<=scan_ready&&delayed_de&&row_matches;
            if(scan_ready)begin
                delayed_vs_d<=delayed_vs;
                if(delayed_vs&&!delayed_vs_d)begin
                    display_frame<=display_frame+32'd1;display_x<=0;display_y<=0;
                end else if(delayed_de)begin
                    if(display_x==W-2)begin display_x<=0;display_y<=display_y==H-1?11'd0:display_y+11'd1;end
                    else display_x<=display_x+11'd2;
                end
            end
            out_vs<=pending_ready&&pixel_pending[50];
            out_hs<=pending_ready&&pixel_pending[49];
            out_de<=pending_ready&&pixel_pending[48];
            out_rgb<=rendered_pair;
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
