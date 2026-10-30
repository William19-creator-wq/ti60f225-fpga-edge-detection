// Serialize source selection, RGB thumbnail capture and atomic pair publication.
// Paused history protects the entire clip. User commands coalesce while a writer
// drains; normal/live selection resumes only after its final B response.
module history_compare_control(
 input wire clk,rst,command_valid,command_compare,
 input wire [1:0] command_mode,input wire [5:0] command_index,command_a,command_b,
 input wire command_freeze_valid,input wire [5:0] command_freeze_slot,input wire [63:0] command_freeze_id,
 output reg select_freeze_valid,output reg [5:0] select_freeze_slot,output reg [63:0] select_freeze_id,
 output reg select_command,output reg [1:0] select_mode,output reg [5:0] select_index,
 input wire selection_apply,selected_valid,input wire [63:0] selected_id,
 input wire boundary,frame_tick,reader_drained,
 output reg job_start,output wire [31:0] job_base,output reg [63:0] job_source_id,
 input wire job_done,job_good,input wire [63:0] job_completed_id,
 output reg compare_enabled,output wire preparing,output reg pair_valid,front_bank,
 output reg [63:0] a_id,b_id,output reg [31:0] failed_pairs
);
 localparam IDLE=0,SELECT_A=1,WAIT_APPLY=2,SETTLE=3,START_JOB=4,WAIT_JOB=5,PUBLISH=6;
 reg [2:0] state;reg pending,pending_compare,side;
 reg [1:0] pending_mode,settle_count;
 reg [5:0] pending_index,pending_a,pending_b,active_a,active_b;
 reg [63:0] built_a,built_b;
 reg pending_freeze_valid;reg [5:0] pending_freeze_slot;reg [63:0] pending_freeze_id;
 assign preparing=compare_enabled&&(state!=IDLE||pending||!pair_valid);
 assign job_base=32'h02000000+(!front_bank?32'h00400000:0)+(side?32'h00200000:0);
 always @(posedge clk)begin
   select_command<=0;job_start<=0;
   if(rst)begin
     state<=IDLE;pending<=0;pending_compare<=0;pending_mode<=0;pending_index<=0;pending_a<=0;pending_b<=0;
     active_a<=0;active_b<=0;side<=0;settle_count<=0;select_mode<=0;select_index<=0;
     compare_enabled<=0;pair_valid<=0;front_bank<=0;job_source_id<=0;built_a<=0;built_b<=0;a_id<=0;b_id<=0;failed_pairs<=0;
     pending_freeze_valid<=0;pending_freeze_slot<=0;pending_freeze_id<=0;select_freeze_valid<=0;select_freeze_slot<=0;select_freeze_id<=0;
   end else begin
     if(command_valid)begin
       pending<=1;pending_compare<=command_compare;pending_mode<=command_mode;
       pending_index<=command_index;pending_a<=command_a;pending_b<=command_b;
       pending_freeze_valid<=command_freeze_valid;pending_freeze_slot<=command_freeze_slot;pending_freeze_id<=command_freeze_id;
     end
     case(state)
       IDLE:if(pending&&!command_valid)begin
         pending<=0;compare_enabled<=pending_compare;
         if(pending_compare)begin active_a<=pending_a;active_b<=pending_b;side<=0;state<=SELECT_A;end
         else begin
           select_mode<=pending_mode;select_index<=pending_index;select_command<=1;
           select_freeze_valid<=pending_freeze_valid;select_freeze_slot<=pending_freeze_slot;select_freeze_id<=pending_freeze_id;
         end
       end
       SELECT_A:begin
         select_mode<=3;select_index<=side?active_b:active_a;select_command<=1;select_freeze_valid<=0;state<=WAIT_APPLY;
       end
       WAIT_APPLY:begin
         if(pending||command_valid)state<=IDLE;
         else if(selection_apply&&selected_valid)begin
           job_source_id<=selected_id;settle_count<=2;state<=SETTLE;
         end
       end
       SETTLE:begin
         if(pending||command_valid)state<=IDLE;
         else if(frame_tick)begin
           if(settle_count==1)state<=START_JOB;else settle_count<=settle_count-1;
         end
       end
       START_JOB:begin
         if(pending||command_valid)state<=IDLE;
         else begin job_start<=1;state<=WAIT_JOB;end
       end
       WAIT_JOB:if(job_done)begin
         if(!job_good||job_completed_id!=job_source_id)begin failed_pairs<=failed_pairs+1;state<=IDLE;end
         else if(pending||command_valid)state<=IDLE;
         else if(!side)begin built_a<=job_source_id;side<=1;state<=SELECT_A;end
         else begin built_b<=job_source_id;state<=PUBLISH;end
       end
       PUBLISH:begin
         if(pending||command_valid)state<=IDLE;
         else if(boundary&&reader_drained)begin
           front_bank<=!front_bank;pair_valid<=1;a_id<=built_a;b_id<=built_b;state<=IDLE;
         end
       end
     endcase
   end
 end
endmodule
