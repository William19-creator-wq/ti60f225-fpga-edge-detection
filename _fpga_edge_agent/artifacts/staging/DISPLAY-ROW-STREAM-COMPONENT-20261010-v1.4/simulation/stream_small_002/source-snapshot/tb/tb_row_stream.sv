`timescale 1ns/1ps
// STV1..4：真正fetch/native/消费者/renderer，同一bundle的连续整帧；父是明确fixture。
module tb_row_stream #(parameter integer TEST_W=20,TEST_H=8,TEST_FAULTS=1);
 import display_row_pkg::*;
 import display_fetch_pkg::*;
 localparam integer P=TEST_W/2,N=TEST_W*TEST_H,HT=P+140,VT=TEST_H+45;
 localparam logic [63:0] RESULT_BASE=64'h8888999900000000;
 logic core_clk=0,video_clk=0,safe_reset_n=0,video_clock_running=1;
 always #5 core_clk=~core_clk;
 always #6.734 if(video_clock_running)video_clk=~video_clk;
 logic [1:0] video_reset=3;
 always @(posedge video_clk or negedge safe_reset_n)
  if(!safe_reset_n)video_reset<=3;else video_reset<={video_reset[0],1'b0};
 wire video_rst=video_reset!=0;
 logic enable=1,video_request_valid=0,video_receipt_ready;
 request_t video_request,held_request;
 receipt_t receipt;
 wire video_request_ready,video_receipt_valid,video_busy,video_q;
 wire [614:0] video_receipt,service_receipt;
 wire [480:0] service_request;
 wire service_valid,service_claim_ready,service_cancel,service_receipt_valid,service_receipt_ready;
 wire transport_live,core_idle,core_q,engine_q,core_scope_live;
 wire [386:0] transport_ref;
 frame_owner_pkg::reply_t bundle;
 wire lookup_valid;wire [478:0] lookup_demand;
 wire [2:0] return_valid,row_valid,owned,native_req_ready,native_rsp_valid,native_rsp_error,native_rel_ready,native_rel_error;
 wire [2:0][542:0] return_ticket,row_ticket;
 wire [2:0][1:0] return_kind;
 logic [2:0] return_ready=7,native_req_valid,native_rsp_ready,native_rel_valid;
 wire [2:0] row_ready;
 wire [2:0][53:0] native_data;
 wire [2:0][9:0] native_rsp_addr;
 wire [2:0][63:0] request_gen,release_gen;
 wire [2:0][9:0] request_addr;
 wire [2:0][1:0] release_kind;
 wire [2:0] req_valid,req_ready,rsp_valid,rsp_ready,rel_valid,rel_ready,reserve_ready,prepared,stream_q,stream_live,pixel_valid,identity_good;
 wire [2:0][53:0] pixel_pair;
 wire [2:0][386:0] stream_ref;
 wire [2:0][1:0] line_error;
 wire [2:0][10:0] shown,issued,popped;
 logic [2:0] reserve_valid,display_start,display_de,discard_mask=0,request_pause=0,response_pause=0,release_pause=0,wrong_addr=0,wrong_demand=0,bad_release=0,owned_loss=0;
 logic reserve_discard=0,reserve_corrupt=0,extra_response=0;
 logic [2:0][542:0] reserve_ticket;
 logic [2:0][478:0] display_demand;
 wire [2:0][9:0] seen_rsp_addr;
 wire [2:0][63:0] seen_release_gen;
 wire arvalid,arready,rvalid,rready,rlast;
 wire [31:0] araddr,ar_count,r_count;
 wire [3:0] arid,rid;wire [7:0] arlen;wire [2:0] arsize;wire [1:0] arburst,rresp;wire [127:0] rdata;
 logic ideal=1,ar_pause=0;logic [2:0][2:0] source_for_result=0;wire slave_idle;
 integer frame_id=0,current_mode=0,logfd,outfd=0,nativefd=0,metricfd;
 integer core_cycle=0,video_cycle=0,frame_slots=0,output_slots=0,total_output=0,total_reads=0,total_requests=0,total_writes=0,total_returns=0;
 integer frame_releases=0,manual_step=0,fault_case=0,frame_pop[0:2],frame_req[0:2],frame_show[0:2],wr_index[0:2],last_pixel_cycle[0:2];
 integer row_pop[0:2],row_req[0:2],row_show[0:2];
 logic [2:0] bank_free=7;
 logic [63:0] generations[0:2];
 logic finished=0,video_run=0,manual_mode=0,manual_de=0;
 logic [10:0] manual_x=0;
 logic [2:0] stalled_request=0;logic [2:0][73:0] old_request;
 logic [2:0] stalled_release=0;logic [2:0][65:0] old_release;
 wire timing_de,timing_hs,timing_vs,timing_start;wire [10:0] timing_x,timing_y;
 logic [10:0] small_h=0,small_v=0;
 generate if(TEST_W==1920 && TEST_H==1080)begin
  video_timing_1080p_pair timing(.clk(video_clk),.rst(!video_run||manual_mode||video_rst),.de(timing_de),.hs(timing_hs),.vs(timing_vs),.frame_start(timing_start),.x_even(timing_x),.y(timing_y));
 end else begin
  always @(posedge video_clk)if(!video_run||manual_mode||video_rst)begin small_h<=0;small_v<=0;end
   else if(small_h==HT-1)begin small_h<=0;small_v<=small_v==VT-1 ? 0 : small_v+1'b1;end else small_h<=small_h+1'b1;
  assign timing_de=small_h<P && small_v<TEST_H;assign timing_hs=small_h>=P+44 && small_h<P+66;
  assign timing_vs=small_v>=TEST_H+4 && small_v<TEST_H+9;assign timing_start=small_h==0 && small_v==0;
  assign timing_x=timing_de ? 11'(2*small_h) : 0;assign timing_y=timing_de ? small_v : 0;
 end endgenerate
 wire raw_de=video_run && (manual_mode ? manual_de : timing_de);
 wire raw_hs=video_run && !manual_mode && timing_hs;
 wire raw_vs=video_run && !manual_mode && timing_vs;
 wire raw_start=video_run && (manual_mode ? manual_step==0 : timing_start);
 wire [10:0] raw_x=manual_mode ? manual_x : timing_x;
 wire [10:0] raw_y=manual_mode ? 11'd0 : timing_y;
 wire [1:0] selected_bank=manual_mode ? 2'd0 : 2'(raw_y%3);
 wire [47:0] out_rgb;wire out_de,out_hs,out_vs,out_start;wire [10:0] out_x,out_y;wire [1:0] out_error;
 integer tag0=0,tag1=0;
 assign receipt=video_receipt;
 function automatic logic [31:0] align16(input logic [31:0] x);return (x+15)&32'hfffffff0;endfunction
 function automatic demand_t demand_for_y(input integer y);
  demand_t d;
  begin
   d='0;d.sequence_id=64'h1234567800000000+64'(frame_id);d.scan=64'hfedcb09800000000+64'(frame_id);
   d.result_handle=bundle.result_handle;d.policy=bundle.policy;d.origin=bundle.origin;d.target_y=11'(y);d.source_y=11'(y);d.mode=3'(current_mode);
   case(current_mode)
    0:begin d.required_mask=y<TEST_H/2?1:2;d.source_y=11'(2*(y%(TEST_H/2)));end
    1,2:d.required_mask=1;3:d.required_mask=2;4:d.required_mask=3;5:d.required_mask=7;
   endcase
   return d;
  end
 endfunction
 function automatic logic [53:0] expected_pair(input row_ticket_t t,input integer a);
  integer x,y,f;logic [23:0] c0,c1;logic [47:0] c;logic [1:0] e;logic [3:0] an;
  begin
   x=2*a;y=t.source_y;f=int'(t.origin[2:0])+1;
   c0={8'((37*x+11*y+3*f)%256),8'((13*x+47*y+7*f)%256),8'((53*x+19*y+17*f)%256)};
   c1={8'((37*(x+1)+11*y+3*f)%256),8'((13*(x+1)+47*y+7*f)%256),8'((53*(x+1)+19*y+17*f)%256)};
   c=t.required_mask[0]?{c1,c0}:0;e=t.required_mask[1]?{1'((x+1+y+f)%3==0),1'((x+y+f)%3==0)}:0;
   an=t.required_mask[2]?{2'((7*(x+1)+3*y+f)%4),2'((7*x+3*y+f)%4)}:0;return {an,e,c};
  end
 endfunction
 logic [386:0] query_ref;
 // J2：实际读集显式列出；常量参数的函数调用不能隐含动态帧依赖。
 always_comb query_ref={64'h1234567800000000+64'(frame_id),bundle.result_handle,bundle.policy,bundle.origin};
 always_comb begin
  reserve_valid=0;reserve_ticket=0;display_start=0;display_de=0;display_demand=0;
  video_receipt_ready=0;
  if(video_receipt_valid)begin
   if(receipt.status==0 && receipt.outcome==0 && receipt.bank<3)begin
    reserve_valid[receipt.bank]=1;reserve_ticket[receipt.bank]=receipt.ticket;
    if(reserve_corrupt)reserve_ticket[receipt.bank][479]=~reserve_ticket[receipt.bank][479];
    video_receipt_ready=reserve_ready[receipt.bank];
   end else video_receipt_ready=1;
  end
  for(integer b=0;b<3;b++)begin
   demand_t d;
   d=demand_for_y(int'(raw_y));if(wrong_demand[b])d.policy^=64'h8000000000000000;
   display_demand[b]=d;display_de[b]=raw_de && selected_bank==b;
   display_start[b]=display_de[b] && raw_x==0;
   native_req_valid[b]=req_valid[b]&&!request_pause[b];
   native_rsp_ready[b]=rsp_ready[b]&&!response_pause[b];
   native_rel_valid[b]=rel_valid[b]&&!release_pause[b];
  end
 end
 display_fetch_link link(.core_clk,.video_clk,.safe_reset_n,.video_request_valid,.video_request_ready,.video_request,
  .video_cancel(1'b0),.video_receipt_valid,.video_receipt_ready,.video_receipt,.video_busy,.video_quarantined(video_q),
  .service_valid,.service_claim_ready,.service_request,.service_cancel,.service_receipt_valid,.service_receipt_ready,.service_receipt,
  .transport_live,.transport_ref,.core_idle,.core_quarantined(core_q));
 display_scan_prefetch_core #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H)) core(
  .core_clk,.video_clk,.safe_reset_n,.enable,.service_valid,.service_claim_ready,.service_request,.service_cancel,.service_receipt_valid,.service_receipt_ready,.service_receipt,
  .lookup_valid,.lookup_ready(1'b1),.lookup_demand,.lookup_bundle(bundle),.lookup_permitted(1'b1),.scope_query_valid(1'b1),.scope_query_ref(query_ref),.local_scope_live(core_scope_live),.quarantined(engine_q),
  .return_valid,.return_ready,.return_ticket,.return_kind,.row_valid,.row_ready,.row_ticket,.owned,
  .rd_request_valid(native_req_valid),.rd_request_ready(native_req_ready),.rd_generation(request_gen),.rd_address(request_addr),
  .rd_response_valid(native_rsp_valid),.rd_response_ready(native_rsp_ready),.rd_data(native_data),.rd_response_address(native_rsp_addr),.rd_error(native_rsp_error),
  .release_valid(native_rel_valid),.release_ready(native_rel_ready),.release_generation(seen_release_gen),.release_kind,.release_error(native_rel_error),
  .m_axi_arvalid(arvalid),.m_axi_arready(arready),.m_axi_araddr(araddr),.m_axi_arid(arid),.m_axi_arlen(arlen),.m_axi_arsize(arsize),.m_axi_arburst(arburst),
  .m_axi_rvalid(rvalid),.m_axi_rready(rready),.m_axi_rdata(rdata),.m_axi_rid(rid),.m_axi_rresp(rresp),.m_axi_rlast(rlast));
 axi_read_byte_slave #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H)) memory(.clk(core_clk),.rst(!safe_reset_n),.source_for_result,.ideal,.ar_pause,.r_pause(1'b0),.fault_mode(3'd0),
  .arvalid,.arready,.araddr,.arid,.arlen,.arsize,.arburst,.rvalid,.rready,.rdata,.rid,.rresp,.rlast,.ar_count,.r_count,.idle(slave_idle));
 for(genvar b=0;b<3;b++)begin: consumers
  assign req_ready[b]=native_req_ready[b]&&!request_pause[b];assign rsp_valid[b]=(native_rsp_valid[b]&&!response_pause[b]) || (extra_response&&b==0);
  assign seen_rsp_addr[b]=native_rsp_addr[b] ^ (wrong_addr[b] ? 10'd1:10'd0);
  assign seen_release_gen[b]=release_gen[b] ^ (bad_release[b] ? 64'd1:64'd0);assign rel_ready[b]=native_rel_ready[b]&&!release_pause[b];
  display_row_streamer #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H)) stream(
   .video_clk,.safe_reset_n,.reserve_valid(reserve_valid[b]),.reserve_ready(reserve_ready[b]),.reserve_ticket(reserve_ticket[b]),.reserve_discard,
   .row_valid(row_valid[b]),.row_ready(row_ready[b]),.row_ticket(row_ticket[b]),.owned(owned[b]&&!owned_loss[b]),.prepared(prepared[b]),
   .display_start(display_start[b]),.display_de(display_de[b]),.display_x_even(raw_x),.display_demand(display_demand[b]),.discard(discard_mask[b]),
   .rd_request_valid(req_valid[b]),.rd_request_ready(req_ready[b]),.rd_generation(request_gen[b]),.rd_address(request_addr[b]),
   .rd_response_valid(rsp_valid[b]),.rd_response_ready(rsp_ready[b]),.rd_data(native_data[b]),.rd_response_address(seen_rsp_addr[b]),.rd_error(native_rsp_error[b]),
   .release_valid(rel_valid[b]),.release_ready(rel_ready[b]),.release_generation(release_gen[b]),.release_kind(release_kind[b]),.release_error(native_rel_error[b]),
   .pixel_pair(pixel_pair[b]),.pixel_valid(pixel_valid[b]),.identity_good(identity_good[b]),.quarantined(stream_q[b]),.local_live(stream_live[b]),.local_ref(stream_ref[b]),
   .line_error(line_error[b]),.shown(shown[b]),.issued(issued[b]),.popped(popped[b]));
 end
 display_renderer #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H)) renderer(.clk(video_clk),.rst(video_rst),.in_de(raw_de),.in_hs(raw_hs),.in_vs(raw_vs),.in_frame_start(raw_start),
  .in_x_even(raw_x),.in_y(raw_y),.in_pair(pixel_pair[selected_bank]),.in_render(bundle.body[111:0]),.in_pixels_valid(pixel_valid[selected_bank]),.in_identity_good(identity_good[selected_bank]),
  .out_rgb_pair(out_rgb),.out_de,.out_hs,.out_vs,.out_frame_start(out_start),.out_x_even(out_x),.out_y,.out_error);
 task automatic make_bundle(input integer mode);
  integer ss,rs;logic [95:0] sd,ed,ad;
  begin
   current_mode=mode;ss=(frame_id-1)%6;rs=(frame_id-1)%3;bundle='0;bundle.op=5;
   bundle.source_handle=64'h7777ffff00000000+64'(ss+1);bundle.result_handle=RESULT_BASE+64'(frame_id);bundle.policy=64'habcdabcd00000000+64'(frame_id);
   bundle.origin={bundle.source_handle,32'(200+frame_id),32'd77,bundle.source_handle,3'(ss)};bundle.source_slot=3'(ss);bundle.result_slot=2'(rs);
   bundle.cj={1'b1,1'b1,11'd400,11'd80,11'(TEST_H),11'(TEST_W),32'd9,32'(200+frame_id),32'd77};
   sd={32'(ss)*32'h00800000,32'(3*N),align16(32'(3*N))};ed=0;ad=0;
   if(mode!=1&&mode!=2)ed={32'h03000000+32'(rs)*32'h00800000,32'((N+7)/8),align16(32'((N+7)/8))};
   if(mode==5)ad={32'h03100000+32'(rs)*32'h00800000,32'(4224+(N+3)/4),align16(32'(4224+(N+3)/4))};
   bundle.body={sd,ed,ad,3'(mode),11'(TEST_H/2),24'hff0000,24'h00ff00,24'hffffff,24'hffff00,2'd3};
  end
 endtask
 task automatic reset_safe;
  begin
   if(safe_reset_n && !slave_idle)$fatal(1,"Qualified fixture reset requires old AXI slave idle");
   @(negedge core_clk);safe_reset_n=0;video_run=0;video_request_valid=0;discard_mask=0;request_pause=0;response_pause=0;release_pause=0;wrong_addr=0;wrong_demand=0;bad_release=0;owned_loss=0;reserve_discard=0;reserve_corrupt=0;extra_response=0;ar_pause=0;
   repeat(8)@(negedge core_clk);safe_reset_n=1;repeat(12)@(negedge core_clk);
   bank_free=7;for(integer b=0;b<3;b++)begin generations[b]=1;last_pixel_cycle[b]=-100;end
   $fdisplay(logfd,"{\"event\":\"reset\",\"frame\":%0d}",frame_id);
  end
 endtask
 task automatic open_frame(input integer mode,fault);
  begin
   frame_id++;fault_case=fault;make_bundle(mode);frame_slots=0;output_slots=0;frame_releases=0;
   for(integer b=0;b<3;b++)begin frame_pop[b]=0;frame_req[b]=0;frame_show[b]=0;end
   outfd=$fopen($sformatf("frame-%03d.bin",frame_id),"wb");nativefd=$fopen($sformatf("native-%03d.bin",frame_id),"wb");if(!outfd||!nativefd)$fatal(1,"Cannot open binary trace");
   $fdisplay(logfd,"{\"event\":\"frame\",\"frame\":%0d,\"mode\":%0d,\"fault\":%0d,\"bundle\":\"%h\",\"demand0\":\"%h\"}",frame_id,mode,fault,bundle,demand_for_y(0));
  end
 endtask
 task automatic send_row(input integer y);
  integer b;row_ticket_t expected;
  begin
   b=y%3;wait(bank_free[b]);@(negedge video_clk);video_request={2'(b),demand_for_y(y)};held_request=video_request;
   expected={generations[b],video_request.demand};video_request_valid=1;
   do @(posedge video_clk);while(!video_request_ready);
   bank_free[b]=0;$fdisplay(logfd,"{\"event\":\"job\",\"frame\":%0d,\"bank\":%0d,\"ticket\":\"%h\"}",frame_id,b,expected);
   @(negedge video_clk);video_request_valid=0;
   do @(posedge video_clk);while(!(video_receipt_valid&&video_receipt_ready));
   if(receipt.bank!=b||receipt.ticket!==expected||receipt.status||receipt.outcome||!receipt.row_granted||!receipt.drained||receipt.row_returned||receipt.delivered!=P)$fatal(1,"Actual core receipt not full row");
   @(negedge video_clk);
  end
 endtask
 task automatic close_frame;
  begin
   @(negedge video_clk);video_run=0;manual_de=0;
   repeat(5)@(negedge video_clk);$fclose(outfd);$fclose(nativefd);outfd=0;nativefd=0;
   $fdisplay(logfd,"{\"event\":\"frame_end\",\"frame\":%0d,\"slots\":%0d,\"output_slots\":%0d,\"releases\":%0d,\"q\":%0d,\"requests\":[%0d,%0d,%0d],\"pops\":[%0d,%0d,%0d],\"shown\":[%0d,%0d,%0d]}",frame_id,frame_slots,output_slots,frame_releases,stream_q,frame_req[0],frame_req[1],frame_req[2],frame_pop[0],frame_pop[1],frame_pop[2],frame_show[0],frame_show[1],frame_show[2]);
  end
 endtask
 task automatic normal_frame(input integer mode);
  begin
   open_frame(mode,0);manual_mode=0;
   fork
    begin for(integer y=0;y<TEST_H;y++)send_row(y);end
    begin wait(prepared[0]&&prepared[1]);@(negedge video_clk);video_run=1;wait(frame_slots==HT*VT);end
   join
   close_frame();wait(bank_free==7 && stream_live==0 && !transport_live);repeat(4)@(negedge core_clk);
   if(core_scope_live||engine_q||core_q||video_q||stream_q||frame_releases!=TEST_H||output_slots!=HT*VT)$fatal(1,"Continuous full-frame did not close");
   $fdisplay(logfd,"{\"event\":\"scope\",\"frame\":%0d,\"live\":%0d,\"expected\":0,\"ref\":\"%h\"}",frame_id,core_scope_live,query_ref);
  end
 endtask
 task automatic manual_pixels(input integer fault);
  integer cutoff;
  begin
   cutoff=P/2;manual_mode=1;manual_step=0;manual_x=0;manual_de=1;video_run=1;
   for(integer k=0;k<P;k++)begin
    manual_step=k;manual_x=11'(2*k);manual_de=1;
    if(k==cutoff)case(fault)
     3:discard_mask[0]=1;4:response_pause[0]=1;5:wrong_addr[0]=1;6:wrong_demand[0]=1;7:manual_de=0;
    endcase
    @(posedge video_clk);@(negedge video_clk);
   end
   manual_step=P;manual_de=0;video_run=0;
   response_pause=0;wrong_addr=0;wrong_demand=0;
   if(fault==8)discard_mask[0]=1; // 最后一对已经真接受，晚取消不倒改CONSUMED。
  end
 endtask
 task automatic fault_frame(input integer fault);
  begin
   reset_safe();open_frame(1,fault);manual_mode=1;
   if(fault==1)begin
    ar_pause=1;reserve_discard=1;
    fork send_row(0);begin wait(arvalid);@(negedge video_clk);manual_pixels(fault);@(negedge core_clk);ar_pause=0;end join
   end else begin
    if(fault==10||fault==15)request_pause[0]=1;
    if(fault==11)reserve_corrupt=1;
    send_row(0);
    if(fault==2)begin @(negedge video_clk);manual_pixels(fault);end
    else if(fault==9)begin wait(prepared[0]);@(negedge video_clk);discard_mask[0]=1;manual_pixels(fault);end
    else if(fault==10)begin
     wait(req_valid[0]);repeat(3)@(negedge video_clk);discard_mask[0]=1;repeat(5)@(negedge video_clk);
     if(!req_valid[0]||request_addr[0]!=0)$fatal(1,"Cancel withdrew held RE0");request_pause=0;manual_pixels(fault);
    end else if(fault==11)begin wait(stream_q[0]);@(negedge video_clk);manual_pixels(fault);end
    else if(fault==15)begin extra_response=1;wait(stream_q[0]);@(negedge video_clk);manual_pixels(fault);end
    else begin
     wait(prepared[0]);repeat(3)@(negedge video_clk);
     if(fault==12)bad_release[0]=1;
     if(fault==13)release_pause[0]=1;
     if(fault==14)begin
      logic [73:0] held;held={request_gen[0],request_addr[0]};video_clock_running=0;
      repeat(200)begin @(posedge core_clk);#1;if(!stream_live[0]||!core_scope_live||!owned[0]||stream_q[0]||{request_gen[0],request_addr[0]}!==held)$fatal(1,"Stopped video lost borrowed row");end
      $fdisplay(logfd,"{\"event\":\"video_pause\",\"frame\":%0d,\"edges\":200}",frame_id);video_clock_running=1;
     end
     if(fault==16)begin owned_loss[0]=1;wait(stream_q[0]);@(negedge video_clk);end
     manual_pixels(fault);
    end
   end
   if(fault==13)begin wait(rel_valid[0]);repeat(6)@(negedge video_clk);discard_mask[0]=1;repeat(4)@(negedge video_clk);release_pause=0;end
   if(fault==11||fault==12||fault==15||fault==16)begin
    wait(stream_q[0]);repeat(25)@(negedge video_clk);
    if(!stream_live[0]||!owned[0]||!core_scope_live||bank_free[0]||reserve_ready[0])$fatal(1,"Quarantine falsely released scope");
   end else begin
    wait(bank_free[0] && !stream_live[0] && !transport_live);repeat(3)@(negedge core_clk);
    if(core_scope_live||stream_q||owned[0])$fatal(1,"Safe failure did not actually close");
   end
   close_frame();
   $fdisplay(logfd,"{\"event\":\"scope\",\"frame\":%0d,\"live\":%0d,\"expected\":%0d,\"ref\":\"%h\"}",frame_id,core_scope_live,(fault==11||fault==12||fault==15||fault==16),query_ref);
  end
 endtask
 always @(negedge core_clk)if(lookup_valid)source_for_result[bundle.result_slot]=bundle.source_slot;
 always @(posedge core_clk)begin
  core_cycle++;
  if(safe_reset_n&&!core.rst)begin
   if(frame_id>0 && $isunknown(query_ref))$fatal(1,"Frame scope query identity has X");
   if(arvalid&&arready)$fdisplay(logfd,"{\"event\":\"ar\",\"frame\":%0d,\"bank\":%0d,\"y\":%0d,\"a\":%0d,\"id\":%0d,\"len\":%0d}",frame_id,core.reader_bank,core.reader_ticket.target_y,araddr,arid,arlen);
   if(rvalid&&rready)$fdisplay(logfd,"{\"event\":\"r\",\"frame\":%0d,\"id\":%0d,\"resp\":%0d,\"last\":%0d}",frame_id,rid,rresp,rlast);
   for(integer b=0;b<3;b++)begin
    if(core.fill_reply_valid[b]&&core.fill_reply_ready[b]&&core.fill_reply_status[b]==0)wr_index[b]=0;
    if(core.wr_valid[b]&&core.wr_ready[b])begin
     if(core.wr_address[b]!=wr_index[b]||core.wr_generation[b]!=core.reader_ticket.generation||core.wr_data[b]!==expected_pair(core.reader_ticket,wr_index[b]))$fatal(1,"True WR data/order/GEN");
     wr_index[b]++;total_writes++;
    end
    if(return_valid[b]&&return_ready[b])begin
     row_ticket_t t;t=return_ticket[b];
     if(t.generation!=generations[b])$fatal(1,"Actual GEN return mismatch");
     generations[b]++;bank_free[b]=1;total_returns++;
     $fdisplay(logfd,"{\"event\":\"return\",\"frame\":%0d,\"bank\":%0d,\"ticket\":\"%h\",\"kind\":%0d}",frame_id,b,t,return_kind[b]);
    end
   end
  end
 end
 always @(posedge video_clk)begin
  video_cycle++;
  if(video_rst)begin tag0<=0;tag1<=0;stalled_request=0;stalled_release=0;end
  else begin
   tag0<=video_run ? frame_id:0;tag1<=tag0;
   if(video_run)frame_slots++;
   if(video_receipt_valid&&video_receipt_ready)$fdisplay(logfd,"{\"event\":\"receipt\",\"frame\":%0d,\"packet\":\"%h\"}",frame_id,receipt);
   for(integer b=0;b<3;b++)begin
    row_ticket_t t;logic [63:0] data;t=row_ticket[b];data={10'd0,native_data[b]};
    if(stalled_request[b]&&(!req_valid[b]||{request_gen[b],request_addr[b]}!==old_request[b]))$fatal(1,"Registered native request holding");
    stalled_request[b]=req_valid[b]&&!req_ready[b];old_request[b]={request_gen[b],request_addr[b]};
    if(stalled_release[b]&&(!rel_valid[b]||{release_gen[b],release_kind[b]}!==old_release[b]))$fatal(1,"Release holding");
    stalled_release[b]=rel_valid[b]&&!rel_ready[b];old_release[b]={release_gen[b],release_kind[b]};
    if(reserve_valid[b]&&reserve_ready[b])begin
     row_pop[b]=0;row_req[b]=0;row_show[b]=0;
     $fdisplay(logfd,"{\"event\":\"reserve\",\"frame\":%0d,\"bank\":%0d,\"ticket\":\"%h\",\"presented\":\"%h\",\"discard\":%0d,\"vc\":%0d}",frame_id,b,row_ticket[b],reserve_ticket[b],reserve_discard,video_cycle);
    end
    if(native_req_valid[b]&&native_req_ready[b])begin
     if(request_gen[b]!=t.generation||request_addr[b]!=row_req[b]||row_req[b]>=P)$fatal(1,"Actual native RE order/full GEN");
     row_req[b]++;frame_req[b]++;total_requests++;
    end
    if(native_rsp_valid[b]&&native_rsp_ready[b])begin
     if(native_rsp_error[b]||native_rsp_addr[b]!=row_pop[b]||native_data[b]!==expected_pair(t,row_pop[b]))$fatal(1,"Actual native full54 mismatch");
     row_pop[b]++;frame_pop[b]++;total_reads++;
     if(!nativefd)$fatal(1,"Native response outside frame trace");
     $fwrite(nativefd,"%c%c%c%c%c%c%c%c%c%c%c%c%c%c",b,pixel_valid[b],t.target_y[7:0],{5'd0,t.target_y[10:8]},native_rsp_addr[b][7:0],{6'd0,native_rsp_addr[b][9:8]},data[7:0],data[15:8],data[23:16],data[31:24],data[39:32],data[47:40],data[55:48],data[63:56]);
    end
    if(pixel_valid[b])begin row_show[b]++;frame_show[b]++;last_pixel_cycle[b]=video_cycle;end
    if(rel_valid[b]&&rel_ready[b])begin
     if(video_cycle-last_pixel_cycle[b]<=2)$fatal(1,"Release before renderer downstream tail");
     frame_releases++;
     $fdisplay(logfd,"{\"event\":\"release\",\"frame\":%0d,\"bank\":%0d,\"ticket\":\"%h\",\"generation\":\"%h\",\"kind\":%0d,\"requests\":%0d,\"pops\":%0d,\"shown\":%0d,\"vc\":%0d,\"last_pixel\":%0d}",frame_id,b,t,seen_release_gen[b],release_kind[b],row_req[b],row_pop[b],row_show[b],video_cycle,last_pixel_cycle[b]);
    end
   end
  end
 end
 // 观察S1更新后的值；tag1仅追踪外部输入时隙，不读取renderer内部状态。
 always @(negedge video_clk)if(!video_rst && tag1!=0)begin
  logic [15:0] flags;flags={10'd0,out_error,out_start,out_vs,out_hs,out_de};
  if(!outfd||tag1!=frame_id)$fatal(1,"Output trace source lifetime");
  $fwrite(outfd,"%c%c%c%c%c%c%c%c%c%c%c%c",out_rgb[7:0],out_rgb[15:8],out_rgb[23:16],out_rgb[31:24],out_rgb[39:32],out_rgb[47:40],out_x[7:0],{5'd0,out_x[10:8]},out_y[7:0],{5'd0,out_y[10:8]},flags[7:0],flags[15:8]);
  output_slots++;total_output++;
  if(fault_case==0 && out_de && out_error)$fatal(1,"Continuous normal frame underrun/identity error mode=%0d y=%0d x=%0d error=%0d",current_mode,out_y,out_x,out_error);
 end
 initial begin
  if($test$plusargs("EXPECT_FATAL"))begin #1;$fatal(1,"fatal exit probe");end
  logfd=$fopen("stream-events.jsonl","w");if(!logfd)$fatal(1,"Cannot open trace");
  reset_safe();for(integer m=0;m<6;m++)normal_frame(m);
  if(TEST_FAULTS)for(integer f=1;f<=16;f++)fault_frame(f);
  metricfd=$fopen("stream-metrics.json","w");
  $fdisplay(metricfd,"{\"finished\":true,\"width\":%0d,\"height\":%0d,\"frames\":%0d,\"normal_frames\":6,\"fault_frames\":%0d,\"slots\":%0d,\"native_requests\":%0d,\"native_pops\":%0d,\"writes\":%0d,\"returns\":%0d}",TEST_W,TEST_H,frame_id,16*TEST_FAULTS,total_output,total_requests,total_reads,total_writes,total_returns);
  $fclose(metricfd);$fclose(logfd);finished=1;$display("ROW STREAM PASS W=%0d H=%0d frames=%0d",TEST_W,TEST_H,frame_id);$finish;
 end
 initial begin #1000000000;$fatal(1,"Stream watchdog frame=%0d mode=%0d fault=%0d slots=%0d core=%0d free=%b prepared=%b q=%b",frame_id,current_mode,fault_case,frame_slots,core.state,bank_free,prepared,stream_q);end
endmodule
