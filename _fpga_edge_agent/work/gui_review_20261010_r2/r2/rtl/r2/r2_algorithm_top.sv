// SI-REQ07：四pin生产默认1920×1080，仅规则可暂停源，无实体操作。
module r2_algorithm_top #(parameter integer W=1920,H=1080) (
    input wire clk_25m,key1_n,output wire led0,led1
);
    wire clk=clk_25m;wire rst;
    reset_sync reset_adapter(.clk(clk),.key1_n(key1_n),.core_rst(rst));
    wire cj_valid,cj_ready,in_valid,in_ready,class_valid,class_ready,grad_valid,grad_ready,status_valid,status_ready;
    wire [141:0] cj;wire [73:0] in_fp;wire [124:0] class_payload;
    wire [184:0] grad_payload;wire [591:0] status_payload,last_cs;
    wire job_start,fault,source_stop,cancel,source_last_fire;wire [1:0] pattern;
    wire [20:0] observed_class_pairs,observed_grad_pairs,observed_strong,observed_weak;
    wire observed_class_eof,observed_grad_eof,record_protocol_ok,observer_fault_sticky;
    wire terminal_fixture_match,terminal_complete_ok,terminal_done,last_result_valid,last_fixture_match,last_complete_ok;
    wire [31:0] last_crc;
    r2_job_controller #(.W(W),.H(H)) job_controller (
        .clk(clk),.rst(rst),.cj_valid(cj_valid),.cj_ready(cj_ready),.cj(cj),
        .source_last_fire(source_last_fire),.source_input_fire(in_valid&&in_ready),
        .status_valid(status_valid),.status_payload(status_payload),.status_fire(status_valid&&status_ready),
        .observed_class_pairs(observed_class_pairs),.observed_grad_pairs(observed_grad_pairs),
        .observed_strong(observed_strong),.observed_weak(observed_weak),
        .observed_class_eof(observed_class_eof),.observed_grad_eof(observed_grad_eof),.record_protocol_ok(record_protocol_ok),
        .observer_fault_sticky(observer_fault_sticky),.terminal_done(terminal_done),
        .last_fixture_match(last_fixture_match),.last_complete_ok(last_complete_ok),.last_crc(last_crc),
        .job_start(job_start),.pattern(pattern),.fault(fault),.source_stop(source_stop),.cancel(cancel),
        .terminal_fixture_match(terminal_fixture_match),.terminal_complete_ok(terminal_complete_ok)
    );
    r2_pattern_pair_source #(.W(W),.H(H)) source (
        .clk(clk),.rst(rst),.job_start(job_start),.cj(cj),.pattern(pattern),.fault(fault),.source_stop(source_stop),
        .out_valid(in_valid),.out_ready(in_ready),.out_fp(in_fp),.source_last_fire(source_last_fire)
    );
    canny_stream_top #(.W(W),.H(H)) stream (
        .clk(clk),.rst(rst),.cancel(cancel),.cj_valid(cj_valid),.cj_ready(cj_ready),.cj(cj),
        .in_valid(in_valid),.in_ready(in_ready),.in_fp(in_fp),
        .class_valid(class_valid),.class_ready(class_ready),.class_payload(class_payload),
        .grad_valid(grad_valid),.grad_ready(grad_ready),.grad_payload(grad_payload),
        .status_valid(status_valid),.status_ready(status_ready),.status_payload(status_payload)
    );
    r2_result_crc_observer #(.W(W),.H(H)) observer (
        .clk(clk),.rst(rst),.job_start(job_start),.cj(cj),.retain_grad(cj[141]),
        .class_valid(class_valid),.class_ready(class_ready),.class_payload(class_payload),
        .grad_valid(grad_valid),.grad_ready(grad_ready),.grad_payload(grad_payload),
        .status_valid(status_valid),.status_ready(status_ready),.status_payload(status_payload),
        .terminal_fixture_match(terminal_fixture_match),.terminal_complete_ok(terminal_complete_ok),
        .observed_class_pairs(observed_class_pairs),.observed_grad_pairs(observed_grad_pairs),
        .observed_strong(observed_strong),.observed_weak(observed_weak),
        .observed_class_eof(observed_class_eof),.observed_grad_eof(observed_grad_eof),.record_protocol_ok(record_protocol_ok),
        .observer_fault_sticky(observer_fault_sticky),.terminal_done(terminal_done),.last_result_valid(last_result_valid),
        .last_fixture_match(last_fixture_match),.last_complete_ok(last_complete_ok),.last_cs(last_cs),.last_crc(last_crc)
    );
    r2_led_status leds(.clk(clk),.rst(rst),.last_result_valid(last_result_valid),
        .last_complete_ok(last_complete_ok),.last_crc(last_crc),.led0(led0),.led1(led1));
endmodule
