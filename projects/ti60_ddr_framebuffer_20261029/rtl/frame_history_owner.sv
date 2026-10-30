// 64 x 2 MiB RAW8 slots. All ports are synchronous to the AXI clock.
// Capture supplies finish_ok only after dimensions, EOF and every B response pass.
// Readers acquire a lease BEFORE issuing AR and release only after FIFO/R drain.
// History is a chronological ring. hold_history makes that ring an immutable clip.
module frame_history_owner #(
 parameter integer CLIENTS=5,EXTERNAL_PINS=0
)(
 input logic clk,rst,
 input logic capture_request,
 output logic capture_grant, capture_drop,
 output logic [5:0] capture_slot,
 output wire [31:0] capture_base,
 input logic capture_finish,capture_finish_ok,
 input logic [63:0] capture_frame_id,capture_timestamp,
 input logic hold_history,
 input logic [63:0] external_pins,
 input logic lease_request,input logic [$clog2(CLIENTS)-1:0] lease_client,
 input logic lease_release,input logic [5:0] lease_slot,
 output logic lease_ack,lease_error,
 input logic [5:0] history_index,
 output logic history_valid,output logic [5:0] history_slot,
 output logic [63:0] history_frame_id,history_timestamp,
 output logic [6:0] history_count,
 output logic latest_valid,output logic [5:0] latest_slot,
 output logic [63:0] latest_frame_id,
 output logic [31:0] dropped_count,bad_count,
 output logic fault
);
 logic [63:0] valid_slots,history_mask;
 logic [5:0] history [0:59];
 logic [63:0] frame_ids [0:63],timestamps [0:63];
 logic [5:0] first,tail;
 logic [CLIENTS-1:0] leased;
 logic [5:0] client_slots [0:CLIENTS-1];
 logic writing,searching;
 logic [5:0] scan;
 logic [6:0] scanned;
 logic [63:0] pinned;
 logic [6:0] query_position;
 logic query_valid;
 logic [5:0] query_slot;
 integer c;
 assign capture_base=32'h08000000+{5'd0,capture_slot,21'd0};
 always_comb begin
   pinned=history_mask|(EXTERNAL_PINS?external_pins:64'd0);
   if(latest_valid)pinned[latest_slot]=1'b1;
   for(integer k=0;k<CLIENTS;k=k+1)
     if(leased[k])pinned[client_slots[k]]=1'b1;
   // A simultaneous new lease must also exclude its slot from allocation.
   if(lease_request&&!lease_release&&lease_client<CLIENTS&&valid_slots[lease_slot])pinned[lease_slot]=1'b1;
   query_position={1'b0,first}+{1'b0,history_index};
   if(query_position>=60)query_position=query_position-60;
 end
 always_ff @(posedge clk) begin
   capture_grant<=0;capture_drop<=0;lease_ack<=0;lease_error<=0;
   query_valid<=history_index<history_count;
   query_slot<=history[query_position];
   history_valid<=query_valid;history_slot<=query_slot;
   // Query descriptor is deliberately a registered two-cycle lookup.
   history_frame_id<=frame_ids[query_slot];history_timestamp<=timestamps[query_slot];
   if(rst)begin
     valid_slots<=0;history_mask<=0;first<=0;tail<=0;history_count<=0;
     leased<=0;writing<=0;searching<=0;scan<=0;scanned<=0;capture_slot<=0;
     latest_valid<=0;latest_slot<=0;latest_frame_id<=0;
     dropped_count<=0;bad_count<=0;fault<=0;history_valid<=0;query_valid<=0;query_slot<=0;
   end else begin
     if(lease_request)begin
       lease_ack<=1;
       if(lease_client>=CLIENTS)begin lease_error<=1;fault<=1;end
       else if(lease_release)leased[lease_client]<=0;
       else if(valid_slots[lease_slot]&&!(writing&&capture_slot==lease_slot))begin
         leased[lease_client]<=1;client_slots[lease_client]<=lease_slot;
       end else begin lease_error<=1;fault<=1;end
     end
     if(capture_request)begin
       if(writing||searching)begin capture_drop<=1;dropped_count<=dropped_count+1;end
       else begin searching<=1;scanned<=0;end
     end
     if(searching)begin
       if(!pinned[scan])begin
         capture_slot<=scan;writing<=1;searching<=0;capture_grant<=1;
         valid_slots[scan]<=0;scan<=scan+1;
       end else if(scanned==63)begin
         searching<=0;capture_drop<=1;dropped_count<=dropped_count+1;
       end else begin scan<=scan+1;scanned<=scanned+1;end
     end
     if(capture_finish)begin
       if(!writing)fault<=1;
       else begin
         writing<=0;
         if(!capture_finish_ok)bad_count<=bad_count+1;
         else begin
           valid_slots[capture_slot]<=1;
           frame_ids[capture_slot]<=capture_frame_id;timestamps[capture_slot]<=capture_timestamp;
           latest_valid<=1;latest_slot<=capture_slot;latest_frame_id<=capture_frame_id;
           if(!hold_history)begin
             history[tail]<=capture_slot;history_mask[capture_slot]<=1;
             tail<=(tail==59)?0:tail+1;
             if(history_count==60)begin
               history_mask[history[first]]<=0;first<=(first==59)?0:first+1;
             end else history_count<=history_count+1;
           end
         end
       end
     end
   end
 end
endmodule
