"""一次性将整机副本的三个串行任务数据路径提升到共同父模块；原始资料不改。"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FE = [
    ('output', '', 'frontend_job_valid'), ('input', '', 'frontend_job_ready'), ('output', '[109:0]', 'frontend_job'),
    ('output', '', 'frontend_input_valid'), ('input', '', 'frontend_input_ready'), ('output', '[73:0]', 'frontend_input'),
    ('input', '', 'frontend_output_valid'), ('output', '', 'frontend_output_ready'), ('input', '[138:0]', 'frontend_output'),
    ('input', '', 'frontend_status_valid'), ('output', '', 'frontend_status_ready'), ('input', '[162:0]', 'frontend_status'),
    ('output', '', 'frontend_cancel'),
]
READER = [
    ('output', '', 'reader_job_valid'), ('input', '', 'reader_job_ready'), ('output', '[95:0]', 'reader_job'),
    ('input', '', 'reader_config_valid'), ('output', '', 'reader_config_ready'), ('input', '', 'reader_config_error'),
    ('input', '', 'reader_pixel_valid'), ('output', '', 'reader_pixel_ready'), ('input', '[137:0]', 'reader_pixel'),
    ('input', '', 'reader_done_valid'), ('output', '', 'reader_done_ready'), ('input', '[161:0]', 'reader_status'),
    ('output', '', 'reader_cancel'), ('output', '[63:0]', 'reader_cancel_id'),
    ('input', '', 'reader_line_valid'), ('output', '', 'reader_line_ready'), ('input', '', 'reader_line_write'),
    ('input', '[31:0]', 'reader_line_addr'), ('input', '[511:0]', 'reader_line_wdata'),
    ('output', '', 'reader_reply_valid'), ('input', '', 'reader_reply_ready'), ('output', '[511:0]', 'reader_reply_data'),
    ('output', '', 'reader_reply_error'), ('output', '', 'reader_reply_drained'),
]
WRITER = [
    ('output', '', 'writer_config_valid'), ('input', '', 'writer_config_ready'), ('output', '[95:0]', 'writer_config'),
    ('input', '', 'writer_config_reply_valid'), ('output', '', 'writer_config_reply_ready'), ('input', '', 'writer_config_error'),
    ('output', '', 'writer_pixel_valid'), ('input', '', 'writer_pixel_ready'), ('output', '[85:0]', 'writer_pixel'),
    ('output', '', 'writer_abort'), ('output', '[63:0]', 'writer_abort_id'),
    ('input', '', 'writer_done_valid'), ('output', '', 'writer_done_ready'), ('input', '[25:0]', 'writer_status'),
    ('input', '', 'writer_line_valid'), ('output', '', 'writer_line_ready'), ('input', '', 'writer_line_write'),
    ('input', '[31:0]', 'writer_line_addr'), ('input', '[511:0]', 'writer_line_wdata'),
    ('output', '', 'writer_reply_valid'), ('input', '', 'writer_reply_ready'), ('output', '[511:0]', 'writer_reply_data'),
    ('output', '', 'writer_reply_error'), ('output', '', 'writer_reply_drained'),
]


def add_ports(source, ports):
    end = source.index('\n);')
    return source[:end] + ',\n' + ',\n'.join(f'    {direction} wire {width} {name}' for direction, width, name in ports) + source[end:]


def replace_instance(source, kind, body):
    start = source.index('    ' + kind + ' #(')
    end = source.index(');', start) + 2
    return source[:start] + body + source[end:]


def forward(source, instance, ports):
    marker = instance + '('
    pos = source.index(marker) + len(marker)
    return source[:pos] + '\n        ' + ', '.join('.' + name for _, _, name in ports) + ',\n        ' + source[pos:]


def save(relative, source):
    (ROOT / relative).write_text(source, encoding='utf-8')


stream_file = 'algorithm/deps/r2/rtl/r2/canny_stream_top.sv'
s = (ROOT / stream_file).read_text(encoding='utf-8')
assert 'frontend_job_valid' not in s, 'Preserve already shared sources; do not apply twice'
s = add_ports(s, FE)
s = replace_instance(s, 'frontend_frame_pair', '''    // 共同 R1 只在本帧 owner 下工作，数值和 valid/ready 契约保持原样。
    assign frontend_job_valid=fj_valid;assign fj_ready=frontend_job_ready;assign frontend_job=fj;
    assign frontend_input_valid=in_valid&&fp_allow;assign frontend_input=in_fp;assign fe_in_ready=frontend_input_ready;
    assign fe_out_valid=frontend_output_valid;assign frontend_output_ready=g_in_ready&&data_open;
    assign m_pair=frontend_output[15:0];assign unused_fe_edge=frontend_output[17:16];
    assign m_coordinate=frontend_output[42:18];assign m_ids=frontend_output[138:43];
    assign fs_valid=frontend_status_valid;assign frontend_status_ready=fs_ready;assign frontend_cancel=fe_cancel;
    assign fs_code=frontend_status[2:0];assign fs_ids=frontend_status[98:3];
    assign fs_in_pairs=frontend_status[119:99];assign fs_out_pairs=frontend_status[140:120];
    assign fs_x=frontend_status[151:141];assign fs_y=frontend_status[162:152];''')
save(stream_file, s)

full_file = 'algorithm/deps/canny_full_sw/rtl/canny_full_top.sv'
s = (ROOT / full_file).read_text(encoding='utf-8')
s = add_ports(s, FE + WRITER)
s = forward(s, 'stream', FE)
s = replace_instance(s, 'edge_frame_writer', '''    // 结果写帧器与 Sobel 共用，只有 HY 阶段才产生本任务像素。
    assign writer_config_valid=state==CFG_RESULT_REQ;assign edge_cfg_ready=writer_config_ready;
    assign writer_config={active_handle,saved_result_base};
    assign edge_cfg_rsp_valid=writer_config_reply_valid;assign writer_config_reply_ready=state==CFG_RESULT_WAIT;
    assign edge_cfg_rsp_error=writer_config_error;
    assign writer_pixel_valid=h_pixel_valid;assign edge_in_ready=writer_pixel_ready;
    assign writer_pixel={h_pixel_id,h_pixel_index,h_pixel_edge};
    assign writer_abort=private_abort&&hy_mode;assign writer_abort_id=active_handle;
    assign edge_done_valid=writer_done_valid;assign writer_done_ready=!edge_seen;
    assign edge_count=writer_status[21:0];assign edge_done_error=writer_status[22];
    assign edge_done_aborted=writer_status[23];assign edge_done_drained=writer_status[24];assign edge_quarantined=writer_status[25];
    assign edge_rpc_valid=writer_line_valid;assign writer_line_ready=edge_rpc_ready;
    assign edge_rpc_write=writer_line_write;assign edge_rpc_addr=writer_line_addr;assign edge_rpc_data=writer_line_wdata;
    assign writer_reply_valid=hy_mode&&rpc_rsp_valid[0];assign edge_rpc_rsp_ready=writer_reply_ready;
    assign writer_reply_data=rpc_rdata;assign writer_reply_error=rpc_error;assign writer_reply_drained=rpc_drained;''')
save(full_file, s)

canny_file = 'algorithm/rtl/frame_canny_rpc.sv'
s = (ROOT / canny_file).read_text(encoding='utf-8')
s = add_ports(s, FE + READER + WRITER)
s = forward(s, 'canny ', FE + WRITER) if 'canny (' in s else forward(s, 'canny', FE + WRITER)
s = replace_instance(s, 'rgb_frame_reader', '''    // reader 的真实事务仍经过原 algorithm_group；这里只移出重复硬件。
    assign reader_job_valid=state==START_READER;assign r_job_ready=reader_job_ready;assign reader_job={handle,locked_source};
    assign r_cfg_valid=reader_config_valid;assign reader_config_ready=state==WAIT_READER_CFG;assign r_cfg_error=reader_config_error;
    assign r_out_valid=reader_pixel_valid;assign reader_pixel_ready=r_out_ready;assign r_fp=reader_pixel[73:0];assign r_id=reader_pixel[137:74];
    assign reader_cancel=child_cancel;assign reader_cancel_id=handle;
    assign r_done_valid=reader_done_valid;assign reader_done_ready=r_done_ready;
    assign r_done_id=reader_status[63:0];assign r_outcome=reader_status[65:64];assign r_reason=reader_status[73:66];
    assign r_prepared=reader_status[94:74];assign r_output=reader_status[115:95];
    assign r_lines=reader_status[137:116];assign r_discard=reader_status[159:138];assign r_stop=reader_status[160];assign r_q=reader_status[161];
    assign client_valid[0]=reader_line_valid;assign reader_line_ready=client_ready[0];assign client_write[0]=reader_line_write;
    assign client_addr[0]=reader_line_addr;assign client_data[0]=reader_line_wdata;
    assign reader_reply_valid=client_rsp_valid[0];assign client_rsp_ready[0]=reader_reply_ready;
    assign reader_reply_data=client_rdata;assign reader_reply_error=client_error;assign reader_reply_drained=client_drained;''')
save(canny_file, s)

sobel_file = 'board/rtl/board_sobel_rpc.sv'
s = (ROOT / sobel_file).read_text(encoding='utf-8')
s = add_ports(s, FE + READER + WRITER)
s = replace_instance(s, 'rgb_frame_reader', '''    assign reader_job_valid=state==RSTART;assign r_job_ready=reader_job_ready;assign reader_job={handle,src};
    assign r_cfg_valid=reader_config_valid;assign reader_config_ready=state==RREPLY;assign r_cfg_error=reader_config_error;
    assign r_valid=reader_pixel_valid;assign reader_pixel_ready=r_ready;assign r_fp=reader_pixel[73:0];
    assign reader_cancel=1'b0;assign reader_cancel_id=handle;
    assign r_done=reader_done_valid;assign reader_done_ready=state==RUN&&!r_closed;
    assign r_outcome=reader_status[65:64];assign r_reason=reader_status[73:66];assign r_q=reader_status[161];
    assign req_valid[0]=reader_line_valid;assign reader_line_ready=req_ready[0];assign req_write[0]=reader_line_write;
    assign addr[0]=reader_line_addr;assign wdata[0]=reader_line_wdata;
    assign reader_reply_valid=rsp_valid[0];assign rsp_ready[0]=reader_reply_ready;
    assign reader_reply_data=rdata;assign reader_reply_error=rpc_error;assign reader_reply_drained=rpc_drained;''')
s = replace_instance(s, 'frontend_frame_pair', '''    assign frontend_job_valid=state==FSTART;assign f_job_ready=frontend_job_ready;
    assign frontend_job={cj[139:129],2'd1,cj[140],cj[95:0]};
    assign frontend_input_valid=r_valid&&state==RUN;assign frontend_input=r_fp;assign f_in_ready=frontend_input_ready;
    assign f_valid=frontend_output_valid;assign frontend_output_ready=f_ready;
    assign f_edge=frontend_output[17:16];assign f_x=frontend_output[28:18];assign f_y=frontend_output[39:29];
    assign frontend_cancel=1'b0;assign f_done=frontend_status_valid;assign frontend_status_ready=state==RUN&&!f_closed;
    assign f_code=frontend_status[2:0];''')
s = replace_instance(s, 'edge_frame_writer', '''    assign writer_config_valid=state==WCFG;assign w_cfg_ready=writer_config_ready;assign writer_config={handle,dst};
    assign w_cfg_valid=writer_config_reply_valid;assign writer_config_reply_ready=state==WREPLY;assign w_cfg_error=writer_config_error;
    assign writer_pixel_valid=held;assign w_ready=writer_pixel_ready;assign writer_pixel={handle,pixel_index,edge_pair[lane]};
    assign writer_abort=1'b0;assign writer_abort_id=handle;
    assign w_done=writer_done_valid;assign writer_done_ready=state==RUN&&!w_closed;
    assign w_error=writer_status[22];assign w_aborted=writer_status[23];assign w_drained=writer_status[24];assign w_q=writer_status[25];
    assign req_valid[1]=writer_line_valid;assign writer_line_ready=req_ready[1];assign req_write[1]=writer_line_write;
    assign addr[1]=writer_line_addr;assign wdata[1]=writer_line_wdata;
    assign writer_reply_valid=rsp_valid[1];assign rsp_ready[1]=writer_reply_ready;
    assign writer_reply_data=rdata;assign writer_reply_error=rpc_error;assign writer_reply_drained=rpc_drained;''')
save(sobel_file, s)

wrapper_file = 'board/rtl/board_algorithm_rpc.sv'
s = (ROOT / wrapper_file).read_text(encoding='utf-8')
ports = FE + READER + WRITER
declarations = ['    // 共享 owner 从 job_fire 到 DONE 消费保持；只有同一 owner 获得 ready/回复。']
for direction, width, name in ports:
    declarations += [f'    wire {width} c_{name},s_{name},{name};']
    if direction == 'output':
        declarations += [f'    assign {name}=choose_sobel?s_{name}:c_{name};']
    else:
        declarations += [f"    assign c_{name}=choose_sobel?'0:{name};", f"    assign s_{name}=choose_sobel?{name}:'0;"]
pos = s.index('    reg busy,selected;')
s = s[:pos] + '\n'.join(declarations) + '\n' + s[pos:]
for instance, prefix in [('canny', 'c_'), ('sobel', 's_')]:
    marker = instance + '(' if instance + '(' in s else instance + ' ('
    pos = s.index(marker) + len(marker)
    s = s[:pos] + '\n        ' + ', '.join(f'.{name}({prefix}{name})' for _, _, name in ports) + ',\n        ' + s[pos:]

common = '''
    // 原算法模块自身不被替代；三份物理资源仅在串行任务之间复用。
    frontend_frame_pair #(.W(WIDTH),.H(HEIGHT)) shared_frontend(
        .clk,.rst,.job_valid(frontend_job_valid),.job_ready(frontend_job_ready),
        .job_epoch(frontend_job[31:0]),.job_frame_id(frontend_job[63:32]),.job_config_id(frontend_job[95:64]),
        .job_median_enable(frontend_job[96]),.job_output_kind(frontend_job[98:97]),.job_threshold(frontend_job[109:99]),
        .in_valid(frontend_input_valid),.in_ready(frontend_input_ready),.in_rgb(frontend_input[47:0]),
        .in_x_even(frontend_input[58:48]),.in_y(frontend_input[69:59]),.in_sof(frontend_input[70]),
        .in_eol(frontend_input[71]),.in_eof(frontend_input[72]),.in_bad(frontend_input[73]),
        .out_valid(frontend_output_valid),.out_ready(frontend_output_ready),.out_y_filtered(frontend_output[15:0]),
        .out_edge(frontend_output[17:16]),.out_x_even(frontend_output[28:18]),.out_y(frontend_output[39:29]),
        .out_sof(frontend_output[40]),.out_eol(frontend_output[41]),.out_eof(frontend_output[42]),
        .out_epoch(frontend_output[74:43]),.out_frame_id(frontend_output[106:75]),.out_config_id(frontend_output[138:107]),
        .cancel(frontend_cancel),.status_valid(frontend_status_valid),.status_ready(frontend_status_ready),
        .status_code(frontend_status[2:0]),.status_epoch(frontend_status[34:3]),.status_frame_id(frontend_status[66:35]),
        .status_config_id(frontend_status[98:67]),.status_in_pairs(frontend_status[119:99]),.status_out_pairs(frontend_status[140:120]),
        .status_error_x(frontend_status[151:141]),.status_error_y(frontend_status[162:152]));
    rgb_frame_reader #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) shared_reader(
        .clk,.rst,.job_valid(reader_job_valid),.job_ready(reader_job_ready),.job_base(reader_job[31:0]),.job_handle(reader_job[95:32]),
        .job_rsp_valid(reader_config_valid),.job_rsp_ready(reader_config_ready),.job_rsp_error(reader_config_error),
        .out_valid(reader_pixel_valid),.out_ready(reader_pixel_ready),.out_fp(reader_pixel[73:0]),.out_id(reader_pixel[137:74]),
        .cancel_valid(reader_cancel),.cancel_id(reader_cancel_id),.done_valid(reader_done_valid),.done_ready(reader_done_ready),
        .done_id(reader_status[63:0]),.outcome(reader_status[65:64]),.reason(reader_status[73:66]),
        .prepared_pairs(reader_status[94:74]),.output_pairs(reader_status[115:95]),.read_lines(reader_status[137:116]),
        .discarded_lines(reader_status[159:138]),.source_stop(reader_status[160]),.quarantined(reader_status[161]),
        .line_req_valid(reader_line_valid),.line_req_ready(reader_line_ready),.line_write(reader_line_write),
        .line_addr(reader_line_addr),.line_wdata(reader_line_wdata),.line_rsp_valid(reader_reply_valid),.line_rsp_ready(reader_reply_ready),
        .line_rdata(reader_reply_data),.line_error(reader_reply_error),.line_drained(reader_reply_drained));
    edge_frame_writer #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ITEM_BITS(1)) shared_writer(
        .clk,.rst,.cfg_valid(writer_config_valid),.cfg_ready(writer_config_ready),.cfg_base(writer_config[31:0]),.cfg_id(writer_config[95:32]),
        .cfg_rsp_valid(writer_config_reply_valid),.cfg_rsp_ready(writer_config_reply_ready),.cfg_rsp_error(writer_config_error),
        .in_valid(writer_pixel_valid),.in_ready(writer_pixel_ready),.in_index(writer_pixel[21:1]),.in_edge(writer_pixel[0]),.in_id(writer_pixel[85:22]),
        .abort_valid(writer_abort),.abort_id(writer_abort_id),.done_valid(writer_done_valid),.done_ready(writer_done_ready),
        .count(writer_status[21:0]),.done_error(writer_status[22]),.done_aborted(writer_status[23]),.done_drained(writer_status[24]),.quarantined(writer_status[25]),
        .line_req_valid(writer_line_valid),.line_req_ready(writer_line_ready),.line_write(writer_line_write),
        .line_addr(writer_line_addr),.line_wdata(writer_line_wdata),.line_rsp_valid(writer_reply_valid),.line_rsp_ready(writer_reply_ready),
        .line_rdata(writer_reply_data),.line_error(writer_reply_error),.line_drained(writer_reply_drained));
'''
s = s.replace('\nendmodule', common + '\nendmodule')
save(wrapper_file, s)
print('Shared real RGB reader, R1 frontend and 1-bit edge writer; algorithm parents keep their actual memory transaction owners.')
