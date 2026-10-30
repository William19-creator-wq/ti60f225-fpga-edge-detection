// Four 2 MiB thumbnail slots: front/back pairs. Only the unused pair is written.
// Source slots must remain leased by the caller until job_done has drained writes.
// New requests coalesce to the latest A/B pair; stale pairs are never published.
module comparison_pair_commit(
 input logic clk,rst,request,
 input logic [5:0] requested_a_slot,requested_b_slot,
 input logic [63:0] requested_a_id,requested_b_id,
 output wire preparing,
 output wire job_valid,input logic job_ready,
 output wire [5:0] job_source_slot,output wire [63:0] job_source_id,
 output wire [31:0] job_base,
 input logic job_done,job_good,input logic [63:0] completed_source_id,
 input logic display_boundary,reader_drained,
 output logic pair_valid,front_bank,commit,
 output logic [63:0] displayed_a_id,displayed_b_id,
 output logic [31:0] failed_pairs
);
 localparam IDLE=0,ISSUE_A=1,WAIT_A=2,ISSUE_B=3,WAIT_B=4,PUBLISH=5;
 logic [2:0] state;
 logic pending,stale;
 logic [5:0] next_a,next_b,active_a,active_b;
 logic [63:0] next_a_id,next_b_id,active_a_id,active_b_id;
 wire b_job=state==ISSUE_B||state==WAIT_B;
 assign preparing=state!=IDLE||pending;
 assign job_valid=state==ISSUE_A||state==ISSUE_B;
 assign job_source_slot=b_job?active_b:active_a;
 assign job_source_id=b_job?active_b_id:active_a_id;
 assign job_base=32'h02000000+(!front_bank?32'h00400000:0)+(b_job?32'h00200000:0);
 always_ff @(posedge clk)begin
   commit<=0;
   if(rst)begin
     state<=IDLE;pending<=0;stale<=0;pair_valid<=0;front_bank<=0;
     next_a<=0;next_b<=0;next_a_id<=0;next_b_id<=0;
     active_a<=0;active_b<=0;active_a_id<=0;active_b_id<=0;
     displayed_a_id<=0;displayed_b_id<=0;failed_pairs<=0;
   end else begin
     if(request)begin
       pending<=1;next_a<=requested_a_slot;next_b<=requested_b_slot;
       next_a_id<=requested_a_id;next_b_id<=requested_b_id;
       if(state!=IDLE)stale<=1;
     end
     case(state)
       IDLE:if(pending&&!request)begin
         pending<=0;stale<=0;active_a<=next_a;active_b<=next_b;
         active_a_id<=next_a_id;active_b_id<=next_b_id;state<=ISSUE_A;
       end
       ISSUE_A:if(job_ready)state<=WAIT_A;
       WAIT_A:if(job_done)begin
         if(!job_good||completed_source_id!=active_a_id)begin failed_pairs<=failed_pairs+1;state<=IDLE;end
         else if(stale||request)state<=IDLE;
         else state<=ISSUE_B;
       end
       ISSUE_B:if(job_ready)state<=WAIT_B;
       WAIT_B:if(job_done)begin
         if(!job_good||completed_source_id!=active_b_id)begin failed_pairs<=failed_pairs+1;state<=IDLE;end
         else if(stale||request)state<=IDLE;
         else state<=PUBLISH;
       end
       PUBLISH:begin
         if(stale||request)state<=IDLE;
         else if(display_boundary&&reader_drained)begin
           front_bank<=!front_bank;pair_valid<=1;displayed_a_id<=active_a_id;displayed_b_id<=active_b_id;
           commit<=1;state<=IDLE;
         end
       end
     endcase
   end
 end
endmodule
