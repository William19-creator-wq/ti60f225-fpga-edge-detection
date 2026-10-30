`timescale 1ns/1ps
module tb_tag_ram;
reg clk=0,rst=1,cfg_valid=0,cfg_rsp_ready=1,abort_private_valid=0,req_valid=0,rsp_ready=0;
reg[31:0]cfg_base=32'h06400000;reg[63:0]cfg_job_id=1,abort_job_id=1;reg[1:0]req_op=0;reg[20:0]req_index=0;
wire cfg_ready,cfg_rsp_valid,cfg_rsp_error,req_ready,rsp_valid,rsp_claimed,rsp_error,rsp_aborted,claim_valid;
wire[1:0]rsp_old;wire[15:0]rsp_word;wire[20:0]claim_index;wire line_req_valid,line_write,line_rsp_ready,quarantined;wire[31:0]line_addr;wire[511:0]line_wdata;
reg line_rsp_valid=0;reg[511:0]line_rdata=0;reg pending=0,pending_write=0;integer delay_count=0,pending_line=0,operations=0;
reg[511:0]pending_data;reg[511:0]backing[int];reg[1:0]golden[int];
always #5 clk=~clk;
canny_state_cache dut(.clk(clk),.rst(rst),.cfg_valid(cfg_valid),.cfg_ready(cfg_ready),.cfg_base(cfg_base),.cfg_job_id(cfg_job_id),.cfg_rsp_valid(cfg_rsp_valid),.cfg_rsp_ready(cfg_rsp_ready),.cfg_rsp_error(cfg_rsp_error),.abort_private_valid(abort_private_valid),.abort_job_id(abort_job_id),.req_valid(req_valid),.req_ready(req_ready),.req_op(req_op),.req_index(req_index),.rsp_valid(rsp_valid),.rsp_ready(rsp_ready),.rsp_old(rsp_old),.rsp_claimed(rsp_claimed),.rsp_error(rsp_error),.rsp_aborted(rsp_aborted),.rsp_word(rsp_word),.claim_valid(claim_valid),.claim_ready(1'b1),.claim_index(claim_index),.line_req_valid(line_req_valid),.line_req_ready(!pending&&!line_rsp_valid),.line_write(line_write),.line_addr(line_addr),.line_wdata(line_wdata),.line_rsp_valid(line_rsp_valid),.line_rsp_ready(line_rsp_ready),.line_rdata(line_rdata),.line_error(1'b0),.line_drained(1'b1),.quarantined(quarantined),.active_job_id());
function automatic[1:0] initial_state(input integer a);initial_state=2'((a*7+(a>>4))%3);endfunction
function automatic[1:0] expected_state(input integer a);if(golden.exists(a))expected_state=golden[a];else expected_state=initial_state(a);endfunction
function automatic[511:0] fresh_line(input integer a);reg[511:0]v;begin for(integer k=0;k<256;k++)v[k*2+:2]=initial_state(a*256+k);fresh_line=v;end endfunction
always @(posedge clk)begin
 if(line_req_valid&&!pending&&!line_rsp_valid)begin
  if(line_addr[5:0]!=0||line_addr<cfg_base||line_addr>=cfg_base+518400)$fatal(1,"DDR address");
  pending<=1;pending_line=(line_addr-cfg_base)/64;pending_write<=line_write;pending_data<=line_wdata;delay_count<=2;
 end else if(pending)begin
  if(delay_count!=0)delay_count<=delay_count-1;
  else begin
   if(pending_write)begin
    for(integer k=0;k<256;k++)if(pending_data[k*2+:2]!==expected_state(pending_line*256+k))$fatal(1,"dirty writeback mismatch line%0d lane%0d",pending_line,k);
    backing[pending_line]=pending_data;
   end else line_rdata<=backing.exists(pending_line)?backing[pending_line]:fresh_line(pending_line);
   line_rsp_valid<=1;pending<=0;
  end
 end
 if(line_rsp_valid&&line_rsp_ready)line_rsp_valid<=0;
end
task automatic configure(input integer job);begin
 @(negedge clk);cfg_job_id=job;cfg_valid=1;do @(posedge clk);while(!cfg_ready);@(negedge clk);cfg_valid=0;
 wait(cfg_rsp_valid);if(cfg_rsp_error)$fatal(1,"config");@(negedge clk);
end endtask
task automatic request(input integer op,a);reg[1:0]old;reg claimed;reg[15:0]word_expected;begin
 old=expected_state(a);claimed=(op==1&&old==2)||(op==2&&old==1);
 for(integer k=0;k<8;k++)word_expected[k*2+:2]=expected_state((a/8)*8+k);
 @(negedge clk);req_op=op;req_index=a;req_valid=1;do @(posedge clk);while(!req_ready);@(negedge clk);req_valid=0;
 wait(rsp_valid);#1;
 if(rsp_error||rsp_aborted||quarantined)$fatal(1,"unexpected reply error op%0d a%0d",op,a);
 if(op!=3)begin
  if(rsp_old!==old||rsp_claimed!==claimed||rsp_word!==word_expected)$fatal(1,"response mismatch op%0d a%0d old%0d/%0d claim%b/%b word%h/%h",op,a,rsp_old,old,rsp_claimed,claimed,rsp_word,word_expected);
  if(claimed)golden[a]=3;
 end
 @(negedge clk);rsp_ready=1;@(negedge clk);rsp_ready=0;operations++;
end endtask
initial begin
 repeat(5)@(negedge clk);rst=0;configure(1);
 for(integer n=0;n<48;n++)begin request(2,256+n);request(0,256+n);request(1,65792+n);end
 for(integer n=0;n<240;n++)request(n%3,((n%4)*65536)+((n*17)%4096));
 request(3,0);
 foreach(golden[k])if(backing[k/256][(k%256)*2+:2]!==golden[k])$fatal(1,"flush missed state");
 configure(2);for(integer n=0;n<48;n++)request(0,256+n);request(3,0);
 // Abort while a real backing read is pending: consume the response and fail closed.
 configure(3);@(negedge clk);req_op=0;req_index=20'h54321;req_valid=1;do @(posedge clk);while(!req_ready);@(negedge clk);req_valid=0;
 wait(line_req_valid);@(negedge clk);abort_job_id=3;abort_private_valid=1;@(negedge clk);abort_private_valid=0;
 wait(rsp_valid);if(!rsp_aborted||!rsp_error)$fatal(1,"abort reply missing");
 $display("TAG_RAM_CACHE_PASS %0d operations, hit/read-ahead/claim, tag conflicts, dirty writeback, full flush, reconfigure and abort drain",operations);$finish;
end
initial begin #20000000;$fatal(1,"timeout");end
endmodule
