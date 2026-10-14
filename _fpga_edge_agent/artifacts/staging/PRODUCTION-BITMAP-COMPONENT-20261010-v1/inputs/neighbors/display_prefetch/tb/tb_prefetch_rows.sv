`timescale 1ns/1ps
// PF01..07：从字节AXI到实际native三行RAM，测试驱动只在负沿改变。
module tb_prefetch_rows #(
 parameter integer TEST_PF_W=20,TEST_PF_H=8,TEST_PF_ROWS=36
);
 import display_row_pkg::*;
 localparam integer P=TEST_PF_W/2,N=TEST_PF_W*TEST_PF_H;
 logic core_clk=0,video_clk=0,safe_reset_n=0,enable=1;
 always #5 core_clk=~core_clk;
 always #6.734 video_clk=~video_clk;
 logic job_valid=0,job_reply_ready=0,job_permitted=1,cancel_valid=0,done_ready=0;
 logic [1:0] job_bank=0,cancel_bank=0;
 row_ticket_t job_ticket,cancel_ticket,held_ticket;
 frame_owner_pkg::reply_t job_bundle;
 wire job_ready,job_reply_valid,done_valid,drained,row_returned,quarantined;
 wire [2:0] job_reply_status;wire [1:0] outcome,saved_bank;wire [7:0] reason;
 wire [542:0] saved_ticket;wire [10:0] prepared_pairs,delivered_pairs;wire [31:0] read_beats;
 wire [2:0] return_valid,row_valid,owned,rd_request_ready,rd_response_valid,rd_error,release_ready,release_error;
 wire [2:0][542:0] return_ticket,row_ticket;wire [2:0][1:0] return_kind;
 wire [2:0][53:0] rd_data;wire [2:0][9:0] rd_response_address;
 logic [2:0] return_ready=0,row_ready=0,rd_request_valid=0,rd_response_ready=0,release_valid=0;
 logic [2:0][63:0] rd_generation=0,release_generation=0;
 logic [2:0][9:0] rd_address=0;logic [2:0][1:0] release_kind=0;
 wire arvalid,arready,rvalid,rready,rlast;wire [31:0] araddr,ar_count,r_count;
 wire [3:0] arid,rid;wire [7:0] arlen;wire [2:0] arsize;wire [1:0] arburst,rresp;wire [127:0] rdata;
 logic ideal=0,ar_pause=0,r_pause=0;logic [2:0] fault_mode=0;
 logic [2:0][2:0] source_for_result=0;wire slave_idle;
 display_prefetch_rows #(.IMAGE_WIDTH(TEST_PF_W),.IMAGE_HEIGHT(TEST_PF_H)) dut(
 .core_clk,.video_clk,.safe_reset_n,.enable,.job_valid,.job_ready,.job_bank,.job_ticket,.job_bundle,.job_permitted,
 .job_reply_valid,.job_reply_ready,.job_reply_status,.saved_bank,.saved_ticket,.cancel_valid,.cancel_bank,.cancel_ticket,
 .done_valid,.done_ready,.outcome,.reason,.drained,.row_returned,.prepared_pairs,.delivered_pairs,.read_beats,.quarantined,
 .return_valid,.return_ready,.return_ticket,.return_kind,.row_valid,.row_ready,.row_ticket,.owned,
 .rd_request_valid,.rd_request_ready,.rd_generation,.rd_address,.rd_response_valid,.rd_response_ready,.rd_data,.rd_response_address,.rd_error,
 .release_valid,.release_ready,.release_generation,.release_kind,.release_error,
 .m_axi_arvalid(arvalid),.m_axi_arready(arready),.m_axi_araddr(araddr),.m_axi_arid(arid),.m_axi_arlen(arlen),.m_axi_arsize(arsize),.m_axi_arburst(arburst),
 .m_axi_rvalid(rvalid),.m_axi_rready(rready),.m_axi_rdata(rdata),.m_axi_rid(rid),.m_axi_rresp(rresp),.m_axi_rlast(rlast));
 axi_read_byte_slave #(.IMAGE_WIDTH(TEST_PF_W),.IMAGE_HEIGHT(TEST_PF_H)) memory(
 .clk(core_clk),.rst(!safe_reset_n),.source_for_result,.ideal,.ar_pause,.r_pause,.fault_mode,
 .arvalid,.arready,.araddr,.arid,.arlen,.arsize,.arburst,.rvalid,.rready,.rdata,.rid,.rresp,.rlast,.ar_count,.r_count,.idle(slave_idle));
 integer logfd,metricfd,case_id=0,cycle=0,normal_rows=0,read_pixels=0,rejected=0,safe_failed=0,q_cases=0;
 integer current_case=0,wr_count=0,rd_count=0,case_start=0,ideal_cycles=0;
 logic finished=0,keep_row=0;integer held_case;logic [63:0] generations[0:2];
 row_ticket_t parked_ticket[0:2];integer parked_case[0:2];
 logic [63:0] sequence_counter=1;
 logic ar_stalled=0,r_stalled=0,out_stalled=0,ack_stalled=0,done_stalled=0;
 logic [48:0] ar_old;logic [134:0] r_old;logic [65:0] done_old;
 logic [63:0] out_old;logic [2:0] ack_old;
 function automatic logic [31:0] align16(input logic [31:0] x);return (x+15)&32'hfffffff0;endfunction
 function automatic logic [53:0] expected_pair(input row_ticket_t t,input integer a);
  integer x,y,f,r0,g0,b0,r1,g1,b1;logic [47:0] rgb;logic [1:0] e;logic [3:0] ann;
  begin
   x=2*a;y=t.source_y;f=int'(t.origin[2:0])+1;
   r0=(37*x+11*y+3*f)%256;g0=(13*x+47*y+7*f)%256;b0=(53*x+19*y+17*f)%256;
   r1=(37*(x+1)+11*y+3*f)%256;g1=(13*(x+1)+47*y+7*f)%256;b1=(53*(x+1)+19*y+17*f)%256;
   rgb=t.required_mask[0] ? {8'(r1),8'(g1),8'(b1),8'(r0),8'(g0),8'(b0)} : 0;
   e=t.required_mask[1] ? {1'(((x+1+y+f)%3)==0),1'(((x+y+f)%3)==0)} : 0;
   ann=t.required_mask[2] ? {2'((7*(x+1)+3*y+f)%4),2'((7*x+3*y+f)%4)} : 0;
   return {ann,e,rgb};
  end
 endfunction
 task automatic prepare(input integer mode,y,bank);
  logic [95:0] sd,ed,ad;logic [111:0] render;integer ss,rs,sy,mask;
  begin
   ss=case_id%6;rs=case_id%3;sy=y;mask=0;
   case(mode)0:begin mask=y<TEST_PF_H/2 ? 1 : 2;sy=2*(y%(TEST_PF_H/2));end
    1,2:mask=1;3:mask=2;4:mask=3;5:mask=7;endcase
   job_bundle='0;job_bundle.op=5;job_bundle.source_handle=64'(100+ss);job_bundle.result_handle=64'(1000+case_id);
   job_bundle.origin={job_bundle.source_handle,32'(200+ss),32'd77,job_bundle.source_handle,3'(ss)};
   job_bundle.source_slot=3'(ss);job_bundle.result_slot=2'(rs);job_bundle.policy=64'(10+case_id);
   job_bundle.cj={1'b1,1'b1,11'd400,11'd80,11'(TEST_PF_H),11'(TEST_PF_W),32'd9,32'(200+ss),32'd77};
   sd={32'(ss)*32'h00800000,32'(3*N),align16(32'(3*N))};ed=0;ad=0;
   if(mode!=1&&mode!=2)ed={32'h03000000+32'(rs)*32'h00800000,32'((N+7)/8),align16(32'((N+7)/8))};
   if(mode==5)ad={32'h03100000+32'(rs)*32'h00800000,32'(4224+(N+3)/4),align16(32'(4224+(N+3)/4))};
   render={3'(mode),11'(TEST_PF_H/2),24'hff0000,24'h00ff00,24'hffffff,24'hffff00,2'd3};
   job_bundle.body={sd,ed,ad,render};source_for_result[rs]=3'(ss);
   job_ticket={generations[bank],sequence_counter,64'(20+case_id),job_bundle.result_handle,job_bundle.policy,job_bundle.origin,11'(y),11'(sy),3'(mode),3'(mask)};
   job_bank=2'(bank);job_permitted=1;cancel_valid=0;cancel_bank=job_bank;cancel_ticket=job_ticket;fault_mode=0;enable=1;ar_pause=0;r_pause=0;
  end
 endtask
 task automatic set_cancel;
  cancel_valid=1;cancel_bank=job_bank;cancel_ticket=job_ticket;
 endtask
 task automatic reset_safe;
  begin
   // 本TB先停止并清掉受控slave旧活动；这不是对真实DDR reset资格的证明。
   @(negedge core_clk);safe_reset_n=0;job_valid=0;job_reply_ready=0;done_ready=0;cancel_valid=0;
   row_ready=0;rd_request_valid=0;rd_response_ready=0;release_valid=0;return_ready=0;enable=1;ar_pause=0;r_pause=0;fault_mode=0;
   repeat(8)@(negedge core_clk);safe_reset_n=1;repeat(10)@(negedge core_clk);
   for(integer b=0;b<3;b++)generations[b]=1;
   $fdisplay(logfd,"{\"event\":\"reset\",\"case\":%0d,\"cycle\":%0d}",current_case,cycle);
  end
 endtask
 task automatic consume_row(input integer b,input row_ticket_t t,input integer log_case);
  begin
   @(negedge video_clk);row_ready[b]=1;
   do @(posedge video_clk);while(!row_valid[b]);
   if(row_ticket[b]!==t)$fatal(1,"Video full ticket mismatch");
   @(negedge video_clk);row_ready[b]=0;
   for(integer a=0;a<P;a++)begin
    rd_generation[b]=t.generation;rd_address[b]=10'(a);rd_request_valid[b]=1;
    do @(posedge video_clk);while(!rd_request_ready[b]);
    @(negedge video_clk);rd_request_valid[b]=0;
    // 每17项制造响应holding，必须保留native已读出的完整54bit。
    if(a%17==0)repeat(3)@(negedge video_clk);
    rd_response_ready[b]=1;
    do @(posedge video_clk);while(!rd_response_valid[b]);
    if(rd_error[b] || rd_response_address[b]!=a || rd_data[b]!==expected_pair(t,a))$fatal(1,"Native video response mismatch case=%0d a=%0d got=%h exp=%h",current_case,a,rd_data[b],expected_pair(t,a));
    $fdisplay(logfd,"{\"event\":\"read\",\"case\":%0d,\"bank\":%0d,\"address\":%0d,\"data\":\"%h\"}",log_case,b,a,rd_data[b]);
    rd_count++;read_pixels+=2;
    @(negedge video_clk);rd_response_ready[b]=0;
   end
   release_valid[b]=1;release_generation[b]=t.generation;release_kind[b]=0;
   do @(posedge video_clk);while(!release_ready[b]);
   @(negedge video_clk);release_valid[b]=0;
   @(negedge core_clk);return_ready[b]=1;
   do @(posedge core_clk);while(!return_valid[b]);
   if(return_ticket[b]!==t||return_kind[b]!=0)$fatal(1,"Actual consumed return mismatch");
   $fdisplay(logfd,"{\"event\":\"return\",\"case\":%0d,\"bank\":%0d,\"ticket\":\"%h\",\"kind\":%0d,\"cycle\":%0d}",log_case,b,return_ticket[b],return_kind[b],cycle);
   @(negedge core_clk);return_ready[b]=0;generations[b]++;repeat(2)@(negedge core_clk);
  end
 endtask
 task automatic run_case(input integer mode,y,b,scenario,fault);
  integer expect_status,expect_outcome,start_ar,start_r,start_cycle;logic [65:0] terminal;row_ticket_t actual_ticket;
  begin
   case_id++;current_case=case_id;wr_count=0;rd_count=0;sequence_counter++;
   @(negedge core_clk);prepare(mode,y,b);expect_status=0;expect_outcome=0;
   case(scenario)
    1:begin job_permitted=0;expect_status=2;end
    2:begin job_bundle.origin[131]=~job_bundle.origin[131];expect_status=1;end
    3:begin job_bundle.body[336]=~job_bundle.body[336];expect_status=1;end
    4:begin job_ticket.required_mask^=3'b001;expect_status=1;end
    5:expect_status=3;
    6:begin job_ticket.generation++;expect_status=4;end
    7:begin set_cancel();expect_outcome=2;end
    8:begin ar_pause=1;expect_outcome=2;end
    9:begin r_pause=1;expect_outcome=2;end
    10:expect_outcome=2;
    13:expect_outcome=1;
    14,15,16,17:expect_outcome=3;
    18:begin job_bundle.cj[96]=~job_bundle.cj[96];expect_status=1;end
    19:begin job_ticket.policy++;expect_status=1;end
    20:begin job_ticket.result_handle++;expect_status=1;end
    21:begin job_ticket.source_y=11'((job_ticket.source_y+1)%TEST_PF_H);expect_status=1;end
    22:begin job_bank=3;expect_status=1;end
    23:begin job_bundle.source_slot=6;expect_status=1;end
    24:begin job_ticket.sequence_id=0;expect_status=1;end
    25:begin job_ticket.scan=0;expect_status=1;end
    26:begin job_ticket.generation=0;expect_status=1;end
    27:begin job_bundle.op=6;expect_status=1;end
    28:begin job_bundle.body[112]=~job_bundle.body[112];expect_status=1;end
   endcase
   fault_mode=3'(fault);actual_ticket=job_ticket;start_ar=ar_count;start_r=r_count;start_cycle=cycle;
   $fdisplay(logfd,"{\"event\":\"job\",\"case\":%0d,\"scenario\":%0d,\"fault\":%0d,\"bank\":%0d,\"ticket\":\"%h\",\"bundle\":\"%h\",\"permission\":%0d,\"expect_status\":%0d,\"expect_outcome\":%0d,\"ideal\":%0d,\"cycle\":%0d}",current_case,scenario,fault,job_bank,job_ticket,job_bundle,job_permitted,expect_status,expect_outcome,ideal,cycle);
   job_valid=1;do @(posedge core_clk);while(!job_ready);
   @(negedge core_clk);job_valid=0;
   do @(posedge core_clk);while(!job_reply_valid);
   if(job_reply_status!=expect_status)$fatal(1,"ACK mismatch case %0d status %0d expected %0d",current_case,job_reply_status,expect_status);
   repeat(4)@(negedge core_clk);
   if(scenario==7)set_cancel();
   job_reply_ready=1;do @(posedge core_clk);while(!job_reply_valid);
   $fdisplay(logfd,"{\"event\":\"ack\",\"case\":%0d,\"status\":%0d,\"cycle\":%0d}",current_case,job_reply_status,cycle);
   @(negedge core_clk);job_reply_ready=0;
   if(expect_status!=0)begin
    repeat(12)@(negedge core_clk);
    if(ar_count!=start_ar||wr_count!=0||done_valid)$fatal(1,"Rejected job caused IO/data/done");rejected++;
    $fdisplay(logfd,"{\"event\":\"reject_closed\",\"case\":%0d,\"cycle\":%0d}",current_case,cycle);
   end else begin
    if(scenario==8)begin wait(arvalid);repeat(8)@(negedge core_clk);set_cancel();repeat(5)@(negedge core_clk);ar_pause=0;end
    if(scenario==9)begin wait(ar_count>start_ar);repeat(7)@(negedge core_clk);set_cancel();repeat(5)@(negedge core_clk);r_pause=0;end
    if(scenario==10)begin wait(dut.reader_out_valid && dut.reader_address==P-1);@(negedge core_clk);set_cancel();end
    if(scenario==12)begin wait(ar_count>start_ar);@(negedge core_clk);set_cancel();cancel_ticket.origin[3]=~cancel_ticket.origin[3];end
    if(scenario==17)begin wait(ar_count>start_ar);@(negedge core_clk);enable=0;end
    do @(posedge core_clk);while(!done_valid);
    terminal={read_beats,prepared_pairs,delivered_pairs,row_returned,drained,reason,outcome};
    if(outcome!=expect_outcome)$fatal(1,"Outcome mismatch case %0d got %0d expected %0d reason %0d",current_case,outcome,expect_outcome,reason);
    if(expect_outcome==0 && (!drained||row_returned||wr_count!=P||prepared_pairs!=P||delivered_pairs!=P))$fatal(1,"Success not actual full writes");
    if((expect_outcome==1||expect_outcome==2) && (!drained||!row_returned||!slave_idle))$fatal(1,"Safe failure not actual IO/row closed");
    if(expect_outcome==3 && (drained||row_returned||!quarantined))$fatal(1,"Unknown job falsely closed");
    if(ideal && mode==5 && scenario==0)ideal_cycles=cycle-start_cycle;
    if(scenario==11)begin @(negedge core_clk);set_cancel();end
    repeat(7)@(negedge core_clk);
    if(terminal!=={read_beats,prepared_pairs,delivered_pairs,row_returned,drained,reason,outcome})$fatal(1,"Terminal changed in holding");
    done_ready=1;do @(posedge core_clk);while(!done_valid);
    $fdisplay(logfd,"{\"event\":\"done\",\"case\":%0d,\"outcome\":%0d,\"reason\":%0d,\"drained\":%0d,\"returned\":%0d,\"prepared\":%0d,\"delivered\":%0d,\"beats\":%0d,\"elapsed\":%0d,\"cycle\":%0d}",current_case,outcome,reason,drained,row_returned,prepared_pairs,delivered_pairs,read_beats,cycle-start_cycle,cycle);
    @(negedge core_clk);done_ready=0;cancel_valid=0;enable=1;
    if(expect_outcome==0)begin normal_rows++;if(keep_row)begin held_ticket=actual_ticket;held_case=current_case;end else consume_row(b,actual_ticket,current_case);end
    else if(expect_outcome<3)begin safe_failed++;generations[b]++;end
    else begin
     q_cases++;repeat(30)@(negedge core_clk);if(job_ready||done_valid||!quarantined)$fatal(1,"Q reopened/repeated notice");
     reset_safe();
    end
   end
  end
 endtask
 always @(posedge core_clk)begin
  cycle++;
  if(safe_reset_n && !dut.rst)begin
   if(ar_stalled && (!arvalid || {araddr,arid,arlen,arsize,arburst}!==ar_old))$fatal(1,"AR holding");
   if(r_stalled && (!rvalid || {rdata,rid,rresp,rlast}!==r_old))$fatal(1,"R holding");
   if(out_stalled && (!dut.reader_out_valid || {dut.reader_data,dut.reader_address}!==out_old))$fatal(1,"Pair holding");
   if(ack_stalled && (!job_reply_valid || job_reply_status!==ack_old))$fatal(1,"ACK holding");
   if(done_stalled && (!done_valid || {read_beats,prepared_pairs,delivered_pairs,row_returned,drained,reason,outcome}!==done_old))$fatal(1,"Done holding");
   ar_stalled=arvalid&&!arready;ar_old={araddr,arid,arlen,arsize,arburst};r_stalled=rvalid&&!rready;r_old={rdata,rid,rresp,rlast};
   out_stalled=dut.reader_out_valid&&!dut.reader_out_ready;out_old={dut.reader_data,dut.reader_address};
   ack_stalled=job_reply_valid&&!job_reply_ready;ack_old=job_reply_status;done_stalled=done_valid&&!done_ready;done_old={read_beats,prepared_pairs,delivered_pairs,row_returned,drained,reason,outcome};
   if(arvalid&&arready)$fdisplay(logfd,"{\"event\":\"ar\",\"case\":%0d,\"address\":%0d,\"id\":%0d,\"len\":%0d,\"cycle\":%0d}",current_case,araddr,arid,arlen,cycle);
   if(rvalid&&rready)$fdisplay(logfd,"{\"event\":\"r\",\"case\":%0d,\"id\":%0d,\"resp\":%0d,\"last\":%0d,\"data\":\"%h\",\"cycle\":%0d}",current_case,rid,rresp,rlast,rdata,cycle);
   if(dut.reader_out_valid&&dut.reader_out_ready)begin
    if(dut.reader_address!=wr_count||dut.reader_data!==expected_pair(row_ticket_t'(saved_ticket),wr_count))$fatal(1,"Actual WR mismatch case %0d a=%0d got=%h expected=%h",current_case,wr_count,dut.reader_data,expected_pair(row_ticket_t'(saved_ticket),wr_count));
    $fdisplay(logfd,"{\"event\":\"write\",\"case\":%0d,\"address\":%0d,\"data\":\"%h\",\"cycle\":%0d}",current_case,dut.reader_address,dut.reader_data,cycle);wr_count++;
   end
   if(dut.publish_fire)$fdisplay(logfd,"{\"event\":\"publish\",\"case\":%0d,\"cycle\":%0d}",current_case,cycle);
   if(dut.abort_fire)$fdisplay(logfd,"{\"event\":\"abort\",\"case\":%0d,\"cycle\":%0d}",current_case,cycle);
   if(dut.abort_return_fire)$fdisplay(logfd,"{\"event\":\"abort_return\",\"case\":%0d,\"ticket\":\"%h\",\"kind\":%0d,\"cycle\":%0d}",current_case,dut.bank_return_ticket[saved_bank],dut.bank_return_kind[saved_bank],cycle);
  end else begin ar_stalled=0;r_stalled=0;out_stalled=0;ack_stalled=0;done_stalled=0;end
 end
 initial begin
  if($test$plusargs("EXPECT_FATAL"))begin #1;$fatal(1,"fatal exit probe");end
  logfd=$fopen("prefetch-events.jsonl","w");if(!logfd)$fatal(1,"Cannot open events");
  reset_safe();
  for(integer row=0;row<TEST_PF_ROWS;row++)run_case(row%6,row%TEST_PF_H,row%3,0,0);
  for(integer s=1;s<=4;s++)run_case(5,TEST_PF_H-1,0,s,0);
  run_case(5,TEST_PF_H-1,0,6,0);
  keep_row=1;run_case(5,TEST_PF_H-1,0,0,0);keep_row=0;
  run_case(5,TEST_PF_H-1,0,5,0);consume_row(0,held_ticket,held_case);
  for(integer s=18;s<=28;s++)run_case(5,TEST_PF_H-1,0,s,0);
  keep_row=1;
  for(integer b=0;b<3;b++)begin run_case(5,TEST_PF_H-1,b,0,0);parked_ticket[b]=held_ticket;parked_case[b]=held_case;end
  keep_row=0;run_case(5,TEST_PF_H-1,2,5,0);
  for(integer b=0;b<3;b++)consume_row(b,parked_ticket[b],parked_case[b]);
  keep_row=1;
  for(integer b=0;b<2;b++)begin run_case(5,TEST_PF_H-1,b,0,0);parked_ticket[b]=held_ticket;parked_case[b]=held_case;end
  keep_row=0;
  fork
   run_case(5,TEST_PF_H-1,2,0,0);
   consume_row(0,parked_ticket[0],parked_case[0]);
  join
  consume_row(1,parked_ticket[1],parked_case[1]);
  for(integer s=7;s<=12;s++)run_case(5,TEST_PF_H-1,1,s,0);
  run_case(5,TEST_PF_H-1,1,13,1);
  // early-LAST必须选至少2 beat的RGB；错ID/min一拍仍保持Q而不伪造drain。
  run_case(1,0,1,14,2);run_case(1,1,1,15,3);run_case(1,0,1,16,4);run_case(5,0,1,17,0);
  ideal=1;run_case(5,TEST_PF_H-1,2,0,0);ideal=0;
  metricfd=$fopen("protocol-metrics.json","w");
  $fdisplay(metricfd,"{\"width\":%0d,\"height\":%0d,\"cases\":%0d,\"normal_rows\":%0d,\"read_pixels\":%0d,\"rejected\":%0d,\"safe_failed\":%0d,\"quarantined\":%0d,\"ideal_mode5_cycles\":%0d,\"finished\":true}",TEST_PF_W,TEST_PF_H,case_id,normal_rows,read_pixels,rejected,safe_failed,q_cases,ideal_cycles);
  $fclose(metricfd);$fclose(logfd);finished=1;$display("PREFETCH PASS W=%0d H=%0d rows=%0d cases=%0d ideal_mode5_cycles=%0d",TEST_PF_W,TEST_PF_H,normal_rows,case_id,ideal_cycles);$finish;
 end
 initial begin #1000000000;$fatal(1,"Prefetch watchdog case=%0d state=%0d reader=%0d span=%0d prepared=%0d delivered=%0d",current_case,dut.state,dut.reader.state,dut.reader.spans.state,dut.reader.prepared_pairs,dut.reader.delivered_pairs);end
endmodule
