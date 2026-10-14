// SI-REQ01…07 / C0-OP03…06：原FE与私有Canny流真实连接，无测试旁路。
module canny_stream_top #(parameter integer W=1920,H=1080) (
    input wire clk,rst,cancel,
    input wire cj_valid,output wire cj_ready,input wire [141:0] cj,
    input wire in_valid,output wire in_ready,input wire [73:0] in_fp,
    output wire class_valid,input wire class_ready,output wire [124:0] class_payload,
    output wire grad_valid,input wire grad_ready,output wire [184:0] grad_payload,
    output wire status_valid,input wire status_ready,output wire [591:0] status_payload
);
    wire fj_valid,fj_ready,fs_valid,fs_ready,fe_cancel,fp_allow;
    wire stream_start,data_flush,ctx_live,derr_valid,derr_ready;
    wire [109:0] fj;wire [162:0] fs;wire [141:0] ctx_cj;wire [119:0] derr;
    wire [95:0] job_ids=ctx_cj[95:0];
    // 门控只取旧控制状态。当前metadata错误不组合反向撤掉已经成立的fire。
    wire data_open=!rst&&!data_flush&&!stream_start;
    wire [4:0] private_empty;
    wire [7:0] event_fire;
    wire [967:0] event_metadata;
    function automatic [120:0] metadata(input logic [24:0] coordinate,input logic [95:0] ids);
        metadata={coordinate[24:22],ids,coordinate[21:0]};
    endfunction

    wire fe_in_ready,fe_out_valid,g_in_ready;
    wire [15:0] m_pair;wire [24:0] m_coordinate;
    wire [95:0] m_ids;wire [1:0] unused_fe_edge;
    wire [2:0] fs_code;wire [95:0] fs_ids;
    wire [20:0] fs_in_pairs,fs_out_pairs;wire [10:0] fs_x,fs_y;
    assign in_ready=fp_allow&&fe_in_ready;
    assign fs={fs_y,fs_x,fs_out_pairs,fs_in_pairs,fs_ids,fs_code};
    frontend_frame_pair #(.W(W),.H(H)) frontend (
        .clk(clk),.rst(rst),.job_valid(fj_valid),.job_ready(fj_ready),
        .job_epoch(fj[31:0]),.job_frame_id(fj[63:32]),.job_config_id(fj[95:64]),
        .job_median_enable(fj[96]),.job_output_kind(fj[98:97]),.job_threshold(fj[109:99]),
        .in_valid(in_valid&&fp_allow),.in_ready(fe_in_ready),.in_rgb(in_fp[47:0]),
        .in_x_even(in_fp[58:48]),.in_y(in_fp[69:59]),.in_sof(in_fp[70]),
        .in_eol(in_fp[71]),.in_eof(in_fp[72]),.in_bad(in_fp[73]),
        .out_valid(fe_out_valid),.out_ready(g_in_ready&&data_open),.out_y_filtered(m_pair),
        .out_edge(unused_fe_edge),.out_x_even(m_coordinate[10:0]),.out_y(m_coordinate[21:11]),
        .out_sof(m_coordinate[22]),.out_eol(m_coordinate[23]),.out_eof(m_coordinate[24]),
        .out_epoch(m_ids[31:0]),.out_frame_id(m_ids[63:32]),.out_config_id(m_ids[95:64]),
        .cancel(fe_cancel),.status_valid(fs_valid),.status_ready(fs_ready),.status_code(fs_code),
        .status_epoch(fs_ids[31:0]),.status_frame_id(fs_ids[63:32]),.status_config_id(fs_ids[95:64]),
        .status_in_pairs(fs_in_pairs),.status_out_pairs(fs_out_pairs),.status_error_x(fs_x),.status_error_y(fs_y)
    );

    wire g_valid,s_window_in_ready;wire [15:0] g_pair;wire [24:0] g_coordinate;
    wire [120:0] g_metadata=metadata(g_coordinate,job_ids);
    wire s_data_open;
    gaussian5x5_pair #(.W(W),.H(H)) gaussian (
        .clk(clk),.rst(rst),.frame_start(stream_start),.data_flush(data_flush),
        .in_valid(fe_out_valid&&data_open),.in_ready(g_in_ready),.in_pair(m_pair),
        .in_x_even(m_coordinate[10:0]),.in_y(m_coordinate[21:11]),
        .in_sof(m_coordinate[22]),.in_eol(m_coordinate[23]),.in_eof(m_coordinate[24]),
        .out_valid(g_valid),.out_ready(s_window_in_ready&&s_data_open),.out_pair(g_pair),
        .out_x_even(g_coordinate[10:0]),.out_y(g_coordinate[21:11]),
        .out_sof(g_coordinate[22]),.out_eol(g_coordinate[23]),.out_eof(g_coordinate[24]),.empty(private_empty[0])
    );
    // 共享R1窗口按输入x寻址，故S调用者拥有受限q/row。
    // raw G8 metadata仍由C0观察；不能用canonical坐标掩盖接口错误。
    logic [9:0] s_input_q;logic [10:0] s_input_row;logic s_input_done;
    assign s_data_open=data_open&&!s_input_done;
    wire [24:0] s_input_coordinate={
        s_input_q==W/2-1&&s_input_row==H-1,
        s_input_q==W/2-1,s_input_q==0&&s_input_row==0,s_input_row,s_input_q,1'b0};
    always_ff @(posedge clk) begin : canonical_sobel_input
        if(rst||data_flush) begin s_input_q<=0;s_input_row<=0;s_input_done<=1;end
        else if(stream_start) begin s_input_q<=0;s_input_row<=0;s_input_done<=0;end
        else if(g_valid&&s_window_in_ready&&data_open&&!s_input_done) begin
            if(s_input_q==W/2-1) begin
                if(s_input_row==H-1) s_input_done<=1;
                else begin s_input_q<=0;s_input_row<=s_input_row+11'd1;end
            end else s_input_q<=s_input_q+10'd1;
        end
    end
    wire sw_valid,sobel_in_ready,sw_empty,sobel_empty;
    wire [143:0] sw_pair;wire [24:0] sw_coordinate;
    window3x3_pair #(.W(W),.H(H)) sobel_window (
        .clk(clk),.rst(rst),.frame_start(stream_start),.flush(data_flush),
        .in_valid(g_valid&&s_data_open),.in_ready(s_window_in_ready),.in_y_pair(g_pair),
        .in_x_even(s_input_coordinate[10:0]),.in_y(s_input_coordinate[21:11]),
        .in_sof(s_input_coordinate[22]),.in_eol(s_input_coordinate[23]),.in_eof(s_input_coordinate[24]),
        .out_valid(sw_valid),.out_ready(sobel_in_ready&&data_open),.out_window_pair(sw_pair),
        .out_x_even(sw_coordinate[10:0]),.out_y(sw_coordinate[21:11]),
        .out_sof(sw_coordinate[22]),.out_eol(sw_coordinate[23]),.out_eof(sw_coordinate[24]),.empty(sw_empty)
    );
    wire s_valid,d_in_ready;wire [21:0] s_gx,s_gy,s_m;
    wire [15:0] unused_s_center;wire [1:0] unused_s_edge;wire [24:0] s_coordinate;
    wire [65:0] s_pair={s_m[21:11],s_gy[21:11],s_gx[21:11],s_m[10:0],s_gy[10:0],s_gx[10:0]};
    sobel_pair sobel (
        .clk(clk),.rst(rst),.frame_start(stream_start),.flush(data_flush),
        .in_valid(sw_valid&&data_open),.in_ready(sobel_in_ready),.in_window_pair(sw_pair),
        .output_kind(2'd1),.threshold(11'd0),
        .in_x_even(sw_coordinate[10:0]),.in_y(sw_coordinate[21:11]),
        .in_sof(sw_coordinate[22]),.in_eol(sw_coordinate[23]),.in_eof(sw_coordinate[24]),
        .out_valid(s_valid),.out_ready(d_in_ready&&data_open),.out_y_pair(unused_s_center),.out_edge(unused_s_edge),
        .out_gx_pair(s_gx),.out_gy_pair(s_gy),.out_l1_pair(s_m),
        .out_x_even(s_coordinate[10:0]),.out_y(s_coordinate[21:11]),
        .out_sof(s_coordinate[22]),.out_eol(s_coordinate[23]),.out_eof(s_coordinate[24]),.empty(sobel_empty)
    );
    assign private_empty[1]=sw_empty&&sobel_empty;

    wire d_valid,fork_in_ready;wire [69:0] d_pair;wire [24:0] d_coordinate;
    gradient_direction_pair direction (
        .clk(clk),.rst(rst),.frame_start(stream_start),.data_flush(data_flush),.job_ids(job_ids),
        .in_valid(s_valid&&data_open),.in_ready(d_in_ready),.in_pair(s_pair),
        .in_x_even(s_coordinate[10:0]),.in_y(s_coordinate[21:11]),
        .in_sof(s_coordinate[22]),.in_eol(s_coordinate[23]),.in_eof(s_coordinate[24]),
        .out_valid(d_valid),.out_ready(fork_in_ready&&data_open),.out_pair(d_pair),
        .out_x_even(d_coordinate[10:0]),.out_y(d_coordinate[21:11]),
        .out_sof(d_coordinate[22]),.out_eol(d_coordinate[23]),.out_eof(d_coordinate[24]),
        .err_valid(derr_valid),.err_ready(derr_ready),.err_payload(derr),.empty(private_empty[2])
    );
    wire n_valid,n_window_in_ready,fork_grad_valid;
    wire [31:0] n_pair;wire [63:0] grad_pair;wire [24:0] n_coordinate,grad_coordinate;
    canny_fork_pair fork_stage (
        .clk(clk),.rst(rst),.frame_start(stream_start),.data_flush(data_flush),.retain_grad(ctx_cj[141]),
        .in_valid(d_valid&&data_open),.in_ready(fork_in_ready),.in_pair(d_pair),
        .in_x_even(d_coordinate[10:0]),.in_y(d_coordinate[21:11]),
        .in_sof(d_coordinate[22]),.in_eol(d_coordinate[23]),.in_eof(d_coordinate[24]),
        .n_valid(n_valid),.n_ready(n_window_in_ready&&data_open),.n_pair(n_pair),
        .n_x_even(n_coordinate[10:0]),.n_y(n_coordinate[21:11]),
        .n_sof(n_coordinate[22]),.n_eol(n_coordinate[23]),.n_eof(n_coordinate[24]),
        .grad_valid(fork_grad_valid),.grad_ready(grad_ready&&data_open),.grad_pair(grad_pair),
        .grad_x_even(grad_coordinate[10:0]),.grad_y(grad_coordinate[21:11]),
        .grad_sof(grad_coordinate[22]),.grad_eol(grad_coordinate[23]),.grad_eof(grad_coordinate[24]),.empty(private_empty[3])
    );
    assign grad_valid=fork_grad_valid&&data_open;
    assign grad_payload={metadata(grad_coordinate,job_ids),grad_pair};

    wire nw_valid,class_in_ready,nw_empty,class_empty;
    wire [287:0] nw_pair;wire [24:0] nw_coordinate;
    nms_window_pair #(.W(W),.H(H)) nms_window (
        .clk(clk),.rst(rst),.frame_start(stream_start),.data_flush(data_flush),
        .in_valid(n_valid&&data_open),.in_ready(n_window_in_ready),.in_pair(n_pair),
        .in_x_even(n_coordinate[10:0]),.in_y(n_coordinate[21:11]),
        .in_sof(n_coordinate[22]),.in_eol(n_coordinate[23]),.in_eof(n_coordinate[24]),
        .out_valid(nw_valid),.out_ready(class_in_ready&&data_open),.out_window_pair(nw_pair),
        .out_x_even(nw_coordinate[10:0]),.out_y(nw_coordinate[21:11]),
        .out_sof(nw_coordinate[22]),.out_eol(nw_coordinate[23]),.out_eof(nw_coordinate[24]),.empty(nw_empty)
    );
    wire class_out_valid;wire [3:0] class_pair;wire [24:0] class_coordinate;
    nms_classify_pair #(.W(W),.H(H)) classify (
        .clk(clk),.rst(rst),.frame_start(stream_start),.data_flush(data_flush),
        .in_valid(nw_valid&&data_open),.in_ready(class_in_ready),.in_window_pair(nw_pair),
        .threshold_low(ctx_cj[128:118]),.threshold_high(ctx_cj[139:129]),
        .in_x_even(nw_coordinate[10:0]),.in_y(nw_coordinate[21:11]),
        .in_sof(nw_coordinate[22]),.in_eol(nw_coordinate[23]),.in_eof(nw_coordinate[24]),
        .out_valid(class_out_valid),.out_ready(class_ready&&data_open),.out_class_pair(class_pair),
        .out_x_even(class_coordinate[10:0]),.out_y(class_coordinate[21:11]),
        .out_sof(class_coordinate[22]),.out_eol(class_coordinate[23]),.out_eof(class_coordinate[24]),.empty(class_empty)
    );
    assign class_valid=class_out_valid&&data_open;
    assign class_payload={metadata(class_coordinate,job_ids),class_pair};
    assign private_empty[4]=nw_empty&&class_empty;

    // 八个接口各自独立记真实fire；marker/ID/坐标均来自本交接的原sideband。
    assign event_fire={grad_valid&&grad_ready,class_valid&&class_ready,
        n_valid&&n_window_in_ready&&data_open,d_valid&&fork_in_ready&&data_open,
        s_valid&&d_in_ready&&data_open,g_valid&&s_window_in_ready&&s_data_open,
        fe_out_valid&&g_in_ready&&data_open,in_valid&&in_ready};
    assign event_metadata={metadata(grad_coordinate,job_ids),metadata(class_coordinate,job_ids),
        metadata(n_coordinate,job_ids),metadata(d_coordinate,job_ids),metadata(s_coordinate,job_ids),
        g_metadata,metadata(m_coordinate,m_ids),metadata(in_fp[72:48],job_ids)};
    canny_stream_controller #(.W(W),.H(H)) controller (
        .clk(clk),.rst(rst),.cancel(cancel),.cj_valid(cj_valid),.cj_ready(cj_ready),.cj(cj),
        .fj_valid(fj_valid),.fj_ready(fj_ready),.fj(fj),.fs_valid(fs_valid),.fs_ready(fs_ready),.fs(fs),
        .fe_cancel(fe_cancel),.fp_allow(fp_allow),.stream_start(stream_start),.data_flush(data_flush),
        .ctx_live(ctx_live),.ctx_cj(ctx_cj),.derr_valid(derr_valid),.derr_ready(derr_ready),.derr(derr),
        .event_fire(event_fire),.event_metadata(event_metadata),.event_classes(class_pair),.event_grad(grad_pair),
        .private_empty(private_empty),.status_valid(status_valid),.status_ready(status_ready),.status_payload(status_payload)
    );
endmodule
