// Capture + history + selection integration in a single AXI clock domain.
// The external reader must honor selected_base/apply and report reads_drained
// only when its AXI responses, prefetch FIFO and processing source reads finish.
module raw_frame_store #(parameter integer EXTERNAL_PINS=0,DIRECT_FREEZE=0)(
 input logic axi_clk,cam_clk,reset_n,enable,
 input logic sof,eof,de,line_end,input logic [31:0] pix4,input logic [63:0] cam_timestamp,
 input logic command_valid,input logic [1:0] command_mode,input logic [5:0] command_index,
 input wire freeze_target_valid,input wire [5:0] freeze_target_slot,input wire [63:0] freeze_target_id,
 input logic display_boundary,reads_drained,
 input logic [63:0] external_pins,
 output wire [1:0] mode,output wire [5:0] position,
 output wire selected_valid,output wire [31:0] selected_base,
 output wire [63:0] selected_frame_id,output wire apply,
 output wire [6:0] history_count,output wire fault,
 output wire [31:0] capture_drops,slot_drops,bad_frames,
 output wire [31:0] awaddr,output wire [7:0] awlen,output wire [2:0] awsize,
 output wire [1:0] awburst,output wire awvalid,input logic awready,
 output wire [127:0] wdata,output wire [15:0] wstrb,
 output wire wlast,wvalid,input logic wready,input logic bvalid,
 input logic [1:0] bresp,output wire bready
);
 wire slot_request,slot_grant,slot_drop,frame_done,frame_good;
 wire [31:0] slot_base;
 wire [63:0] frame_id,frame_timestamp;
 wire hold_history,lease_request,lease_release,lease_ack,lease_error;
 wire [2:0] lease_client;wire [5:0] lease_slot;
 wire [5:0] history_index,history_slot,latest_slot,selected_slot,capture_slot;
 wire [63:0] history_frame_id,history_timestamp,latest_frame_id;
 wire history_valid,latest_valid,owner_fault,select_fault;
 assign fault=owner_fault||select_fault;
 raw_capture_engine capture(
   .axi_clk(axi_clk),.cam_clk(cam_clk),.reset_n(reset_n),.enable(enable),
   .sof(sof),.eof(eof),.de(de),.line_end(line_end),.pix4(pix4),.cam_timestamp(cam_timestamp),
   .slot_request(slot_request),.slot_grant(slot_grant),.slot_drop(slot_drop),.slot_base(slot_base),
   .frame_done(frame_done),.frame_good(frame_good),.frame_id(frame_id),.frame_timestamp(frame_timestamp),
   .dropped_frames(capture_drops),
   .awaddr(awaddr),.awlen(awlen),.awsize(awsize),.awburst(awburst),.awvalid(awvalid),.awready(awready),
   .wdata(wdata),.wstrb(wstrb),.wlast(wlast),.wvalid(wvalid),.wready(wready),
   .bvalid(bvalid),.bresp(bresp),.bready(bready));
 frame_history_owner #(.EXTERNAL_PINS(EXTERNAL_PINS)) owner(
   .external_pins(external_pins),
   .clk(axi_clk),.rst(!reset_n),.capture_request(slot_request),.capture_grant(slot_grant),.capture_drop(slot_drop),
   .capture_slot(capture_slot),.capture_base(slot_base),.capture_finish(frame_done),.capture_finish_ok(frame_good),
   .capture_frame_id(frame_id),.capture_timestamp(frame_timestamp),.hold_history(hold_history),
   .lease_request(lease_request),.lease_client(lease_client),.lease_release(lease_release),.lease_slot(lease_slot),
   .lease_ack(lease_ack),.lease_error(lease_error),.history_index(history_index),.history_valid(history_valid),
   .history_slot(history_slot),.history_frame_id(history_frame_id),.history_timestamp(history_timestamp),
   .history_count(history_count),.latest_valid(latest_valid),.latest_slot(latest_slot),.latest_frame_id(latest_frame_id),
   .dropped_count(slot_drops),.bad_count(bad_frames),.fault(owner_fault));
 frame_playback_select #(.DIRECT_FREEZE(DIRECT_FREEZE)) selection(
   .freeze_target_valid(freeze_target_valid),.freeze_target_slot(freeze_target_slot),.freeze_target_id(freeze_target_id),
   .clk(axi_clk),.rst(!reset_n),.command_valid(command_valid),.command_mode(command_mode),.command_index(command_index),
   .mode(mode),.hold_history(hold_history),.position(position),.latest_valid(latest_valid),.latest_slot(latest_slot),
   .latest_frame_id(latest_frame_id),.history_count(history_count),.history_index(history_index),.history_valid(history_valid),
   .history_slot(history_slot),.history_frame_id(history_frame_id),.history_timestamp(history_timestamp),
   .lease_request(lease_request),.lease_release(lease_release),.lease_client(lease_client),.lease_slot(lease_slot),
   .lease_ack(lease_ack),.lease_error(lease_error),.display_boundary(display_boundary),.reads_drained(reads_drained),
   .selected_valid(selected_valid),.selected_slot(selected_slot),.selected_frame_id(selected_frame_id),.selected_base(selected_base),
   .apply(apply),.fault(select_fault));
endmodule
