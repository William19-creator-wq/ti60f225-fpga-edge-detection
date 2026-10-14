`timescale 1ns/1ps
// JREQ4：主动错包的测试父。仅证明运输协议，不赋予真实行或DDR关闭权限。
module tb_fetch_transport;
 import display_fetch_pkg::*;
 logic core_clk=0,video_clk=0,safe_reset_n=0,video_clock_running=1;
 always #5 core_clk=~core_clk;
 always #6.734 if(video_clock_running)video_clk=~video_clk;
 logic video_request_valid=0,video_receipt_ready=0,video_cancel=0;
 request_t video_request,expected_request;
 wire video_request_ready,video_receipt_valid,video_busy,video_quarantined;
 wire [614:0] video_receipt;
 wire service_valid,service_cancel,service_receipt_ready,transport_live,core_idle,core_quarantined;
 wire [480:0] service_request;
 wire [386:0] transport_ref;
 logic service_claim_ready=1,service_receipt_valid=0;
 receipt_t service_receipt,expected_receipt;
 integer logfd,cycle=0,case_id=0,claims=0,sends=0,received=0;
 logic finished=0;
 display_fetch_link dut(.*);
 always @(posedge core_clk)begin
  cycle++;
  if(safe_reset_n&&service_valid&&service_claim_ready)begin
   claims++;
   $fdisplay(logfd,"{\"event\":\"claim\",\"case\":%0d,\"request\":\"%h\",\"cycle\":%0d}",case_id,service_request,cycle);
  end
  if(safe_reset_n&&service_receipt_valid&&service_receipt_ready)begin
   sends++;
   $fdisplay(logfd,"{\"event\":\"core_receipt\",\"case\":%0d,\"packet\":\"%h\",\"cycle\":%0d}",case_id,service_receipt,cycle);
  end
 end
 task automatic reset_safe;
  @(negedge core_clk);safe_reset_n=0;video_request_valid=0;video_receipt_ready=0;video_cancel=0;service_receipt_valid=0;
  repeat(8)@(negedge core_clk);safe_reset_n=1;repeat(10)@(negedge core_clk);
 endtask
 task automatic run_packet(input integer fault);
  integer old_claims,old_sends;logic [614:0] held;
  begin
   case_id++;reset_safe();old_claims=claims;old_sends=sends;
   @(negedge video_clk);video_request='0;video_request.bank=1;
   video_request.demand.sequence_id=64'h1234567800000000+64'(case_id);
   video_request.demand.scan=64'hfedcba0987654321;
   video_request.demand.result_handle=64'h8888777766665555;
   video_request.demand.policy=64'h1111222233334444;
   video_request.demand.origin={64'hffffffff22222222,32'ha5a5a5a5,32'h5a5a5a5a,64'habcdef0199999999,3'd4};
   video_request.demand.target_y=1079;video_request.demand.source_y=1078;video_request.demand.mode=5;video_request.demand.required_mask=7;
   expected_request=video_request;
   $fdisplay(logfd,"{\"event\":\"job\",\"case\":%0d,\"fault\":%0d,\"request\":\"%h\"}",case_id,fault,expected_request);
   video_request_valid=1;
   do @(posedge video_clk);while(!video_request_ready);
   @(negedge video_clk);video_request_valid=0;
   if(fault==0)video_clock_running=0;
   do @(posedge core_clk);while(!service_valid);
   if(service_request!==expected_request)$fatal(1,"Transport request was not atomic");
   @(negedge core_clk);
   // 发送真正被测试父接受的身份；错误包只改指定字段。
   service_receipt='0;service_receipt.bank=expected_request.bank;
   service_receipt.ticket={64'd9,expected_request.demand};
   service_receipt.status=FC_BUSY;service_receipt.outcome=1;service_receipt.drained=1;
   case(fault)
    1:service_receipt.bank=2;
    2:service_receipt.ticket.origin[194]=~service_receipt.ticket.origin[194];
    3:begin service_receipt.ticket.generation=0;service_receipt.row_granted=1;end
    4:service_receipt.outcome=3;
    5:service_receipt.drained=0;
   endcase
   expected_receipt=service_receipt;service_receipt_valid=1;
   do @(posedge core_clk);while(!service_receipt_ready);
   @(negedge core_clk);service_receipt_valid=0;
   if(fault==0)begin
    repeat(200)begin
     @(posedge core_clk);#1;
     if(!transport_live||core_idle||!video_busy||video_receipt_valid||service_request!==expected_request)$fatal(1,"No video clock still closed transport");
    end
    $fdisplay(logfd,"{\"event\":\"pause\",\"case\":%0d,\"edges\":200}",case_id);
    video_clock_running=1;
   end
   do @(posedge video_clk);while(!video_receipt_valid);
   held=video_receipt;
   repeat(13)begin
    @(negedge video_clk);
    if(!video_receipt_valid||video_receipt!==held||held!==expected_receipt||video_request_ready||!transport_live)$fatal(1,"Transport result lost holding/debt");
   end
   video_receipt_ready=1;
   @(posedge video_clk);
   if(!video_receipt_valid)$fatal(1,"Receipt vanished before actual acceptance");
   received++;
   $fdisplay(logfd,"{\"event\":\"receipt\",\"case\":%0d,\"packet\":\"%h\"}",case_id,video_receipt);
   @(negedge video_clk);video_receipt_ready=0;
   repeat(30)@(negedge core_clk);
   if(claims!=old_claims+1||sends!=old_sends+1||video_receipt_valid||service_valid)$fatal(1,"Duplicate/missing transport event");
   if(fault==0)begin
    do @(negedge video_clk);while(!video_request_ready);
    if(video_quarantined||core_quarantined||transport_live||!core_idle)$fatal(1,"Correct return did not truly ACK");
   end else begin
    repeat(20)@(negedge video_clk);
    if(!video_quarantined||!core_quarantined||!transport_live||core_idle||video_request_ready)$fatal(1,"Bad packet reopened/closed quarantine");
    if(transport_ref!==demand_ref(expected_request.demand))$fatal(1,"Q lost original transport identity");
   end
   $fdisplay(logfd,"{\"event\":\"closed_check\",\"case\":%0d,\"video_q\":%0d,\"core_q\":%0d,\"live\":%0d,\"idle\":%0d,\"ref\":\"%h\"}",case_id,video_quarantined,core_quarantined,transport_live,core_idle,transport_ref);
  end
 endtask
 initial begin
  if($test$plusargs("EXPECT_FATAL"))begin #1;$fatal(1,"fatal exit probe");end
  logfd=$fopen("transport-events.jsonl","w");if(!logfd)$fatal(1,"Cannot open transport log");
  for(integer f=0;f<6;f++)run_packet(f);
  $fclose(logfd);logfd=$fopen("transport-metrics.json","w");
  $fdisplay(logfd,"{\"finished\":true,\"cases\":%0d,\"claims\":%0d,\"sends\":%0d,\"received\":%0d}",case_id,claims,sends,received);
  $fclose(logfd);finished=1;$display("FETCH TRANSPORT PASS cases=%0d",case_id);$finish;
 end
 initial begin #1000000;$fatal(1,"Transport watchdog case=%0d",case_id);end
endmodule
