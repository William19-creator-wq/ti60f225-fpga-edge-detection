// VP04：独立四pin观察工程；不连接真实MIPI、DDR或TMDS接口。
module video_partial_probe_top(input wire clk_25m,key1_n,output wire led0,led1);
    wire core_rst;
    reset_sync reset_adapter(.clk(clk_25m),.key1_n(key1_n),.core_rst(core_rst));
    wire de,hs,vs,frame_start;wire [10:0] x_even,y;
    video_timing_1080p_pair timing(.clk(clk_25m),.rst(core_rst),.de(de),.hs(hs),.vs(vs),.frame_start(frame_start),.x_even(x_even),.y(y));
    wire [9:0] raw0=x_even[9:0]+y[9:0],raw1=raw0+10'd1;
    wire pixel_valid,cap_sof,cap_eol,cap_eof,frame_end_valid,frame_end_good,error_valid;
    wire [19:0] raw_pair_out;wire [15:0] gray_pair;wire [10:0] capture_x,capture_y;
    wire [31:0] frame_id,frame_end_id;wire [2:0] frame_end_reason,error_reason;
    camera_capture_normalizer capture(.clk(clk_25m),.rst(core_rst),.in_valid(de),.raw_pair({raw1,raw0}),
        .in_sof(frame_start),.in_eol(x_even==1918),.in_bad(1'b0),.pixel_valid(pixel_valid),.raw_pair_out(raw_pair_out),.gray_pair(gray_pair),
        .x_even(capture_x),.y(capture_y),.frame_id(frame_id),.sof(cap_sof),.eol(cap_eol),.eof(cap_eof),
        .frame_end_valid(frame_end_valid),.frame_end_id(frame_end_id),.frame_end_good(frame_end_good),.frame_end_reason(frame_end_reason),.error_valid(error_valid),.error_reason(error_reason));
    logic [31:0] frame_count,data_checksum,capture_count;
    wire [10:0] source_x0,source_x1,source_y;
    wire [23:0] rgb0={source_x0[7:0],source_y[7:0],source_x0[7:0]^source_y[7:0]};
    wire [23:0] rgb1={source_x1[7:0],source_y[7:0],source_x1[7:0]^source_y[7:0]};
    wire [7:0] gray0=source_x0[7:0]+source_y[7:0],gray1=source_x1[7:0]+source_y[7:0];
    wire [1:0] edges={(source_x1[5:0]==source_y[5:0]),(source_x0[5:0]==source_y[5:0])};
    wire [47:0] out_rgb_pair;wire out_de,out_hs,out_vs,out_frame_start;
    video_compare_presenter presenter(.clk(clk_25m),.rst(core_rst),.in_de(de),.in_hs(hs),.in_vs(vs),.in_frame_start(frame_start),
        .in_x_even(x_even),.in_y(y),.cfg_mode(frame_count[1:0]),.rgb_pair({rgb1,rgb0}),.gray_pair({gray1,gray0}),.edge_pair(edges),
        .source_x0(source_x0),.source_x1(source_x1),.source_y(source_y),.out_rgb_pair(out_rgb_pair),.out_de(out_de),.out_hs(out_hs),.out_vs(out_vs),.out_frame_start(out_frame_start));
    always_ff @(posedge clk_25m)begin
        if(core_rst)begin frame_count<=0;data_checksum<=0;capture_count<=0;end
        else begin
            if(frame_start)frame_count<=frame_count+32'd1;
            if(pixel_valid)capture_count<=capture_count+32'd1;
            // 把实际坐标/身份/终态也折入，避免观察工程裁掉这些有用数据端点。
            data_checksum<=(data_checksum+{28'd0,out_frame_start,out_hs,out_vs,out_de}) ^
                (out_de?({8'd0,out_rgb_pair[23:0]}+{8'd0,out_rgb_pair[47:24]}):32'd0) ^
                (pixel_valid?({16'd0,gray_pair}+{12'd0,raw_pair_out}+frame_id+{10'd0,capture_y,capture_x}+
                    {29'd0,cap_sof,cap_eol,cap_eof}):32'd0) ^
                (frame_end_valid?(frame_end_id+{28'd0,frame_end_good,frame_end_reason}):32'd0) ^
                (error_valid?{29'd0,error_reason}:32'd0);
        end
    end
    assign led0=capture_count[20]^frame_count[0];assign led1=data_checksum[7]^data_checksum[23];
endmodule
