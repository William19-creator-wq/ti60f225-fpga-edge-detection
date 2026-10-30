from pathlib import Path
p=Path(__file__).parent
f=p/'rtl/history_frame_buffer.sv';s=f.read_text()
s=s.replace('input wire command_valid,','''input wire command_valid,
input wire command_compare,input wire [5:0] command_a,command_b,
input wire video_rgb_vs,video_rgb_de,input wire [47:0] video_rgb,
output wire [47:0] compare_rgb,output wire compare_rgb_valid,input wire compare_rgb_ready,
output wire compare_read_mode,output wire [129:0] compare_status,''')
s=s.replace('wire read_busy,read_done,read_fault;','''wire read_busy,read_done,read_fault;
wire raw_busy,compare_busy,raw_fault,compare_fault;
reg read_kind=0;
wire select_command,selection_apply;wire [1:0] select_mode;wire [5:0] select_index;
wire compare_enabled,preparing,pair_valid,front_bank;
wire [63:0] compare_a_id,compare_b_id;wire [31:0] compare_failures;
wire job_start,job_done,job_good;wire [31:0] job_base;wire [63:0] job_source_id,job_completed_id;
wire [1:0] wa_valid,wa_ready,wd_valid,wd_ready,wd_last,wb_valid,wb_ready;
wire [1:0][31:0] wa_addr;wire [1:0][7:0] wa_len;wire [1:0][2:0] wa_size;
wire [1:0][1:0] wa_burst,wb_resp;wire [1:0][127:0] wd_data;wire [1:0][15:0] wd_strb;
assign compare_status={compare_enabled,preparing,compare_a_id,compare_b_id};
assign read_busy=raw_busy||compare_busy;
assign read_fault=raw_fault||compare_fault;''')
s=s.replace('if(!axi_clk_rst_n)begin wait_drain<=0;blank_window<=0;end','if(!axi_clk_rst_n)begin wait_drain<=0;blank_window<=0;read_kind<=0;end')
s=s.replace('if(blank_window==1&&selected_valid)read_start<=1;','''if(blank_window==1&&selected_valid)begin
      read_kind<=compare_enabled&&pair_valid&&!preparing;read_start<=1;
    end''')
s=s.replace('wire owner_fault;','''wire owner_fault;
history_compare_control compare_control(
 .clk(axi_clk),.rst(!axi_clk_rst_n),.command_valid(command_valid),.command_compare(command_compare),
 .command_mode(command_mode),.command_index(command_index),.command_a(command_a),.command_b(command_b),
 .select_command(select_command),.select_mode(select_mode),.select_index(select_index),
 .selection_apply(selection_apply),.selected_valid(selected_valid),.selected_id(source_frame_id),
 .boundary(blank_window!=0),.reader_drained(!read_busy&&blank_window!=0),
 .job_start(job_start),.job_base(job_base),.job_source_id(job_source_id),
 .job_done(job_done),.job_good(job_good),.job_completed_id(job_completed_id),
 .compare_enabled(compare_enabled),.preparing(preparing),.pair_valid(pair_valid),.front_bank(front_bank),
 .a_id(compare_a_id),.b_id(compare_b_id),.failed_pairs(compare_failures));
thumbnail_capture_engine thumbnail_writer(
 .axi_clk(axi_clk),.video_clk(o_clk),.reset_n(rst_n),.start(job_start),.target_base(job_base),.source_id(job_source_id),
 .busy(),.done(job_done),.good(job_good),.completed_source_id(job_completed_id),
 .video_vs(video_rgb_vs),.video_de(video_rgb_de),.video_rgb(video_rgb),
 .awaddr(wa_addr[1]),.awlen(wa_len[1]),.awsize(wa_size[1]),.awburst(wa_burst[1]),.awvalid(wa_valid[1]),.awready(wa_ready[1]),
 .wdata(wd_data[1]),.wstrb(wd_strb[1]),.wlast(wd_last[1]),.wvalid(wd_valid[1]),.wready(wd_ready[1]),
 .bvalid(wb_valid[1]),.bresp(wb_resp[1]),.bready(wb_ready[1]));
frame_write_share writes(
 .clk(axi_clk),.rst(!axi_clk_rst_n),.c_awvalid(wa_valid),.c_awready(wa_ready),.c_awaddr(wa_addr),.c_awlen(wa_len),
 .c_awsize(wa_size),.c_awburst(wa_burst),.c_wvalid(wd_valid),.c_wready(wd_ready),.c_wdata(wd_data),.c_wstrb(wd_strb),
 .c_wlast(wd_last),.c_bvalid(wb_valid),.c_bready(wb_ready),.c_bresp(wb_resp),
 .awvalid(awvalid),.awready(awready),.awaddr(awaddr),.awlen(awlen),.awsize(awsize),.awburst(awburst),
 .wvalid(wvalid),.wready(wready),.wdata(wdata),.wstrb(wstrb),.wlast(wlast),.bvalid(bvalid),.bready(bready),.bresp(bresp));''')
a=s.index('raw_frame_store store(');b=s.index('assign history_fault=',a)
chunk=s[a:b].replace('.command_valid(command_valid),.command_mode(command_mode),.command_index(command_index)', '.command_valid(select_command),.command_mode(select_mode),.command_index(select_index)').replace('.apply()', '.apply(selection_apply)')
for port,sig in dict(awaddr='wa_addr[0]',awlen='wa_len[0]',awsize='wa_size[0]',awburst='wa_burst[0]',awvalid='wa_valid[0]',awready='wa_ready[0]',wdata='wd_data[0]',wstrb='wd_strb[0]',wlast='wd_last[0]',wvalid='wd_valid[0]',wready='wd_ready[0]',bvalid='wb_valid[0]',bresp='wb_resp[0]',bready='wb_ready[0]').items():
 chunk=chunk.replace(f'.{port}({port})',f'.{port}({sig})')
s=s[:a]+chunk+s[b:]
a=s.index('raw_frame_read_dma reader(');b=s.index('wire [127:0] read_word;',a)
s=s[:a]+'''wire [1:0][31:0] read_addr;wire [1:0][7:0] read_len;wire [1:0][2:0] read_size;
wire [1:0][1:0] read_burst;wire [1:0] read_arvalid,read_rready,read_pvalid;
wire [1:0][127:0] read_pixels;
assign araddr=read_addr[read_kind];assign arlen=read_len[read_kind];assign arsize=read_size[read_kind];
assign arburst=read_burst[read_kind];assign arvalid=read_arvalid[read_kind];assign rready=read_rready[read_kind];
assign pixel_data=read_pixels[read_kind];assign pixel_valid=read_pvalid[read_kind];
raw_frame_read_dma reader(
 .clk(axi_clk),.rst(!axi_clk_rst_n),.start(read_start&&!read_kind),.cancel(boundary||wait_drain),
 .base_address(selected_base),.fifo_free(fifo_free),.busy(raw_busy),.done(),.fault(raw_fault),
 .araddr(read_addr[0]),.arlen(read_len[0]),.arsize(read_size[0]),.arburst(read_burst[0]),.arvalid(read_arvalid[0]),.arready(arready&&!read_kind),
 .rdata(rdata),.rresp(rresp),.rlast(rlast),.rvalid(rvalid&&!read_kind),.rready(read_rready[0]),
 .pixel_data(read_pixels[0]),.pixel_valid(read_pvalid[0]),.pixel_ready(!fifo_full&&!reset_read_fifo&&!read_kind));
comparison_read_dma compare_reader(
 .clk(axi_clk),.rst(!axi_clk_rst_n),.start(read_start&&read_kind),.cancel(boundary||wait_drain),
 .front_bank(front_bank),.fifo_free(fifo_free),.busy(compare_busy),.done(),.fault(compare_fault),
 .araddr(read_addr[1]),.arlen(read_len[1]),.arsize(read_size[1]),.arburst(read_burst[1]),.arvalid(read_arvalid[1]),.arready(arready&&read_kind),
 .rdata(rdata),.rresp(rresp),.rlast(rlast),.rvalid(rvalid&&read_kind),.rready(read_rready[1]),
 .pixel_data(read_pixels[1]),.pixel_valid(read_pvalid[1]),.pixel_ready(!fifo_full&&!reset_read_fifo&&read_kind));
''' +s[b:]
s=s.replace('reg video_period_d=0;','''reg video_period_d=0;
(* async_reg="true" *) reg [1:0] read_kind_sync=0;
always @(posedge o_clk)begin
 if(!rd_clk_rst_n)read_kind_sync<=0;else read_kind_sync<={read_kind_sync[0],read_kind};
end
assign compare_read_mode=read_kind_sync[1];
wire raw_word_ready,compare_word_ready;
assign read_ready=compare_read_mode?compare_word_ready:raw_word_ready;
rgb32_pair_unpack compare_unpack(
 .clk(o_clk),.rst(!rd_clk_rst_n),.flush(video_read_hold||!compare_read_mode||(fifo_rd_period&&!video_period_d)),
 .in_data(read_word),.in_valid(read_valid&&compare_read_mode),.in_ready(compare_word_ready),
 .out_rgb(compare_rgb),.out_valid(compare_rgb_valid),.out_ready(compare_rgb_ready));''')
s=s.replace('.in_data(read_word),.in_valid(read_valid),.in_ready(read_ready)', '''// Synthetic RAW keeps the original HDMI timing generator supplied during comparison.
 .in_data(compare_read_mode?128'd0:read_word),.in_valid(compare_read_mode||read_valid),.in_ready(raw_word_ready)''')
f.write_text(s)
