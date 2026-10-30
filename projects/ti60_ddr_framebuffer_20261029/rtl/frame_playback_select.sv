// AXI-clock frame selection. Lease clients 0/1 alternate between current and
// next frame. apply requires BOTH a display boundary and drained old reads.
// Commands: 0 live, 1 freeze, 2 play from oldest, 3 pause/seek at command_index.
// Source timestamps count 50 MHz camera ticks; this module runs at 100 MHz.
module frame_playback_select #(parameter integer DIRECT_FREEZE=0)(
 input logic clk,rst,
 input logic command_valid,input logic [1:0] command_mode,input logic [5:0] command_index,
 input wire freeze_target_valid,input wire [5:0] freeze_target_slot,input wire [63:0] freeze_target_id,
 output logic [1:0] mode,output wire hold_history,output logic [5:0] position,
 input logic latest_valid,input logic [5:0] latest_slot,input logic [63:0] latest_frame_id,
 input logic [6:0] history_count,
 output logic [5:0] history_index,input logic history_valid,
 input logic [5:0] history_slot,input logic [63:0] history_frame_id,history_timestamp,
 output logic lease_request,lease_release,output logic [2:0] lease_client,
 output logic [5:0] lease_slot,input logic lease_ack,lease_error,
 input logic display_boundary,reads_drained,
 output logic selected_valid,output logic [5:0] selected_slot,
 output logic [63:0] selected_frame_id,output wire [31:0] selected_base,
 output logic apply,output logic fault
);
 localparam IDLE=0,QUERY=1,ACQUIRE=2,ACK=3,WAIT_BOUNDARY=4,RELEASE=5,RELEASE_ACK=6;
 logic [2:0] state;
 logic [2:0] query_wait;
 logic current_client,had_current,cancel_pending;
 logic [5:0] candidate_slot,target_position;
 logic [63:0] candidate_id,candidate_time,clock_ticks,play_start,first_timestamp;
 logic play_anchor,seek_pending;
 logic freeze_pending;logic [5:0] frozen_slot;logic [63:0] frozen_id;
 wire direct_freeze=DIRECT_FREEZE&&freeze_target_valid;
 wire cancel_now=command_valid&&(command_mode!=1||selected_valid||direct_freeze);
 // A request before the first capture must still allow one complete history frame.
 assign hold_history=history_count!=0&&(mode!=0||(command_valid&&command_mode!=0));
 assign selected_base=32'h08000000+{5'd0,selected_slot,21'd0};
 always_ff @(posedge clk)begin
   lease_request<=0;apply<=0;clock_ticks<=clock_ticks+1;
   if(rst)begin
     mode<=0;position<=0;history_index<=0;state<=IDLE;query_wait<=0;
     current_client<=0;had_current<=0;cancel_pending<=0;
     candidate_slot<=0;candidate_id<=0;candidate_time<=0;target_position<=0;
     selected_valid<=0;selected_slot<=0;selected_frame_id<=0;
     lease_release<=0;lease_client<=0;lease_slot<=0;fault<=0;
     clock_ticks<=0;play_start<=0;first_timestamp<=0;play_anchor<=0;seek_pending<=0;
     freeze_pending<=0;frozen_slot<=0;frozen_id<=0;
   end else begin
     if(command_valid)begin
       mode<=command_mode;
       freeze_pending<=command_mode==1&&direct_freeze;
       if(command_mode==1&&direct_freeze)begin frozen_slot<=freeze_target_slot;frozen_id<=freeze_target_id;end
       if(command_mode==2)begin position<=0;seek_pending<=1;play_anchor<=0;end
       if(command_mode==3)begin
         // 63 is a control command, outside the valid 0..59 history range:
         // pause keeps the leased displayed frame, cancelling only a candidate.
         if(command_index==63&&selected_valid)begin
           if(mode==2)position<=position==0?0:position-1;
           else if(mode==0)position<=history_count==0?0:history_count-1;
           seek_pending<=0;
         end else begin
           position<=history_count==0?0:(command_index>=history_count?history_count-1:command_index);
           seek_pending<=1;
         end
       end
       if(command_mode==0||command_mode==1)seek_pending<=0;
       if(cancel_now)cancel_pending<=1;
     end
     case(state)
       IDLE:begin
         cancel_pending<=0;
         if(!command_valid)begin
           if(freeze_pending)begin candidate_slot<=frozen_slot;candidate_id<=frozen_id;state<=ACQUIRE;end
           else if((mode==0||(!selected_valid&&mode==1))&&latest_valid&&
               (!selected_valid||latest_frame_id!=selected_frame_id))begin
             candidate_slot<=latest_slot;candidate_id<=latest_frame_id;state<=ACQUIRE;
           end else if((mode==2||seek_pending)&&history_count!=0)begin
             history_index<=position;target_position<=position;query_wait<=3;state<=QUERY;
           end
         end
       end
       QUERY:begin
         if(cancel_now||cancel_pending)state<=IDLE;
         else if(query_wait!=0)query_wait<=query_wait-1;
         else if(history_valid)begin
           candidate_slot<=history_slot;candidate_id<=history_frame_id;candidate_time<=history_timestamp;
           if(!play_anchor||mode!=2||((clock_ticks-play_start)>>1)>=history_timestamp-first_timestamp)
             state<=ACQUIRE;
         end else begin fault<=1;state<=IDLE;end
       end
       ACQUIRE:begin
         if(cancel_now||cancel_pending)state<=IDLE;
         else begin
           lease_request<=1;lease_release<=0;lease_client<={2'd0,!current_client};
           lease_slot<=candidate_slot;state<=ACK;
         end
       end
       ACK:if(lease_ack)begin
         if(lease_error)begin fault<=1;state<=IDLE;end
         else state<=WAIT_BOUNDARY;
       end
       WAIT_BOUNDARY:begin
         if(cancel_now||cancel_pending)begin
           // Release only the unused candidate; the displayed frame stays leased.
           lease_client<={2'd0,!current_client};state<=RELEASE;had_current<=1;
         end else if(display_boundary&&reads_drained)begin
           selected_valid<=1;selected_slot<=candidate_slot;selected_frame_id<=candidate_id;apply<=1;
           had_current<=selected_valid;lease_client<={2'd0,current_client};current_client<=!current_client;
           seek_pending<=0;freeze_pending<=0;state<=RELEASE;
           if(mode==2)begin
             if(!play_anchor)begin play_start<=clock_ticks;first_timestamp<=candidate_time;play_anchor<=1;end
             if(target_position+1>=history_count)begin mode<=3;position<=target_position;end
             else position<=target_position+1;
           end
         end
       end
       RELEASE:begin
         if(had_current)begin lease_request<=1;lease_release<=1;state<=RELEASE_ACK;end
         else state<=IDLE;
       end
       RELEASE_ACK:if(lease_ack)begin if(lease_error)fault<=1;state<=IDLE;end
     endcase
   end
 end
endmodule
