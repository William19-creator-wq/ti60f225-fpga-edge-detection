// R1独立四pin工程，生产1920×1080；全部图像候选进入真实CRC/pad扇出。
module r1_algorithm_top #(parameter integer W=1920,parameter integer H=1080) (
    input wire clk_25m,key1_n,output wire led0,led1
);
    wire rst; reset_sync reset_adapter(.clk(clk_25m),.key1_n(key1_n),.core_rst(rst));
    wire job_valid,job_ready,job_start,median_enable;
    wire [31:0] job_epoch,job_frame_id,job_config_id;
    wire [1:0] output_kind,pattern;
    wire [10:0] threshold;
    wire in_valid,in_ready,in_sof,in_eol,in_eof,source_last_fire;
    wire [47:0] in_rgb;wire [10:0] in_x_even,in_y;
    wire out_valid,out_ready,out_sof,out_eol,out_eof;
    wire [15:0] out_y_filtered;wire [1:0] out_edge;
    wire [10:0] out_x_even,out_y;
    wire [31:0] out_epoch,out_frame_id,out_config_id;
    wire status_valid,status_ready;wire [2:0] status_code;
    wire [31:0] status_epoch,status_frame_id,status_config_id;
    wire [20:0] status_in_pairs,status_out_pairs;
    wire [10:0] status_error_x,status_error_y;
    wire accept_records,terminal_accepted_good,terminal_crc_done,terminal_good;
    wire [20:0] data_pairs,last_in_pairs,last_out_pairs,last_data_pairs;
    wire last_result_valid,last_good;wire [31:0] last_crc,last_epoch,last_frame_id,last_config_id;
    wire [2:0] last_status;
    r1_job_supervisor #(.W(W),.H(H)) supervisor (
        .clk(clk_25m),.rst(rst),.job_valid(job_valid),.job_ready(job_ready),
        .job_epoch(job_epoch),.job_frame_id(job_frame_id),.job_config_id(job_config_id),
        .job_median_enable(median_enable),.job_output_kind(output_kind),.job_pattern(pattern),
        .job_threshold(threshold),.job_start(job_start),.source_last_fire(source_last_fire),
        .accept_records(accept_records),.status_valid(status_valid),.status_ready(status_ready),
        .status_code(status_code),.status_epoch(status_epoch),.status_frame_id(status_frame_id),
        .status_config_id(status_config_id),.status_in_pairs(status_in_pairs),
        .status_out_pairs(status_out_pairs),.data_pairs(data_pairs),
        .terminal_accepted_good(terminal_accepted_good),.terminal_crc_done(terminal_crc_done),
        .terminal_good(terminal_good)
    );
    pattern_pair_source #(.W(W),.H(H)) source (
        .clk(clk_25m),.rst(rst),.job_start(job_start),.job_stop(status_valid),
        .job_epoch(job_epoch),.job_frame_id(job_frame_id),.job_config_id(job_config_id),
        .job_median_enable(median_enable),.job_output_kind(output_kind),.job_threshold(threshold),
        .job_pattern(pattern),.in_valid(in_valid),.in_ready(in_ready),.in_rgb(in_rgb),
        .in_x_even(in_x_even),.in_y(in_y),.in_sof(in_sof),.in_eol(in_eol),.in_eof(in_eof),
        .source_last_fire(source_last_fire)
    );
    frontend_frame_pair #(.W(W),.H(H)) core (
        .clk(clk_25m),.rst(rst),.job_valid(job_valid),.job_ready(job_ready),
        .job_epoch(job_epoch),.job_frame_id(job_frame_id),.job_config_id(job_config_id),
        .job_median_enable(median_enable),.job_output_kind(output_kind),.job_threshold(threshold),
        .in_valid(in_valid),.in_ready(in_ready),.in_rgb(in_rgb),.in_x_even(in_x_even),.in_y(in_y),
        .in_sof(in_sof),.in_eol(in_eol),.in_eof(in_eof),.in_bad(1'b0),
        .out_valid(out_valid),.out_ready(out_ready),.out_y_filtered(out_y_filtered),.out_edge(out_edge),
        .out_x_even(out_x_even),.out_y(out_y),.out_sof(out_sof),.out_eol(out_eol),.out_eof(out_eof),
        .out_epoch(out_epoch),.out_frame_id(out_frame_id),.out_config_id(out_config_id),.cancel(1'b0),
        .status_valid(status_valid),.status_ready(status_ready),.status_code(status_code),
        .status_epoch(status_epoch),.status_frame_id(status_frame_id),.status_config_id(status_config_id),
        .status_in_pairs(status_in_pairs),.status_out_pairs(status_out_pairs),
        .status_error_x(status_error_x),.status_error_y(status_error_y)
    );
    result_crc_observer observer (
        .clk(clk_25m),.rst(rst),.job_start(job_start),.accept_records(accept_records),
        .out_valid(out_valid),.out_ready(out_ready),.out_y_filtered(out_y_filtered),.out_edge(out_edge),
        .out_x_even(out_x_even),.out_y(out_y),.out_sof(out_sof),.out_eol(out_eol),.out_eof(out_eof),
        .out_epoch(out_epoch),.out_frame_id(out_frame_id),.out_config_id(out_config_id),
        .status_valid(status_valid),.status_ready(status_ready),.status_code(status_code),
        .status_epoch(status_epoch),.status_frame_id(status_frame_id),.status_config_id(status_config_id),
        .status_in_pairs(status_in_pairs),.status_out_pairs(status_out_pairs),
        .terminal_accepted_good(terminal_accepted_good),.data_pairs(data_pairs),
        .terminal_crc_done(terminal_crc_done),.terminal_good(terminal_good),
        .last_result_valid(last_result_valid),.last_crc(last_crc),.last_status(last_status),
        .last_epoch(last_epoch),.last_frame_id(last_frame_id),.last_config_id(last_config_id),
        .last_in_pairs(last_in_pairs),.last_out_pairs(last_out_pairs),.last_data_pairs(last_data_pairs),
        .last_good(last_good)
    );
    r1_led_status #(.W(W),.H(H)) leds (
        .clk(clk_25m),.rst(rst),.last_result_valid(last_result_valid),.last_good(last_good),
        .last_status(last_status),.last_crc(last_crc),
        .last_in_pairs(last_in_pairs),.last_out_pairs(last_out_pairs),.last_data_pairs(last_data_pairs),
        .led0(led0),.led1(led1)
    );
endmodule
