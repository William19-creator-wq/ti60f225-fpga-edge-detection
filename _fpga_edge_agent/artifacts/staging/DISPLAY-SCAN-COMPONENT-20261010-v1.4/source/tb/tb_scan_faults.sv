`timescale 1ns/1ps
// Q1/Q2、SC27/ST24：真实错误RID；保留未知事务及owner引用，不以复位制造closed。
module tb_scan_faults;
    import frame_owner_pkg::*;
    import display_handoff_pkg::*;
    import display_fetch_pkg::*;
    logic core_clk=0,video_clk=0,safe_reset_n=0,finished=0;
    always #5 core_clk=~core_clk;
    always #6.734 video_clk=~video_clk;
    logic cmd_valid=0,reply_ready=0;wire cmd_ready,reply_valid;
    command_t command;wire [941:0] reply;
    reply_t saved,source,offer;
    wire [17:0] source_states;wire [8:0] result_states;
    wire [63:0] latest,freeze,policy;wire owner_frozen,owner_q,se,re;
    logic control_valid=0,cancel_valid=0,manual_vs=0;wire control_ready,response_valid;
    route_request_t control;
    wire [1206:0] response;
    wire lookup_valid;wire [478:0] lookup_demand;
    wire q,active_valid,old_closed_valid;
    wire [386:0] old_closed_ref;
    wire [941:0] active_bundle;
    wire [63:0] active_sequence,scan_token,video_policy;
    wire frozen,committed,hold;
    wire [31:0] underruns;
    wire arvalid,arready,rvalid,rready,rlast,slave_idle;
    wire [31:0] araddr,ar_count,r_count;
    wire [3:0] arid,rid;wire [7:0] arlen;wire [2:0] arsize;wire [1:0] arburst,rresp;wire [127:0] rdata;
    logic [2:0][2:0] source_for_result=0;
    integer journal,owner_journal,metrics,owner_metrics,transactions=0,wrong_rid=0,ars=0,rs=0;
    demand_t lookup_view;
    assign lookup_view=lookup_demand;
    wire lookup_permitted=offer.result_slot<3 && result_states[offer.result_slot*3+:3]==R_OFFERED &&
        lookup_view.result_handle==offer.result_handle && lookup_view.origin==offer.origin && lookup_view.policy==offer.policy;
    frame_owner #(.IMAGE_WIDTH(20),.IMAGE_HEIGHT(8)) owner (
        .core_clk,.safe_reset_n,.cmd_valid,.cmd_ready,.command,.reply_valid,.reply_ready,.reply,
        .source_states,.result_states,.latest_handle(latest),.freeze_handle(freeze),.policy,.frozen(owner_frozen),.quarantined(owner_q),.source_exhausted(se),.result_exhausted(re));
    display_scan_component #(.IMAGE_WIDTH(20),.IMAGE_HEIGHT(8)) dut (
        .core_clk,.video_clk,.safe_reset_n,.enable(1'b1),.control_valid,.control_ready,.control_request(control),
        .control_response_valid(response_valid),.control_response_ready(1'b0),.control_response(response),
        .cancel_valid,.cancel_sequence(control.sequence_id),.root_retire_capacity(1'b1),
        .in_de(1'b0),.in_hs(1'b0),.in_vs(manual_vs),.in_frame_start(1'b0),.in_x_even(11'd0),.in_y(11'd0),
        .out_rgb_pair(),.out_de(),.out_hs(),.out_vs(),.out_frame_start(),.out_x_even(),.out_y(),.out_error(),
        .lookup_valid,.lookup_ready(1'b1),.lookup_demand,.lookup_bundle(offer),.lookup_permitted,
        .old_closed_valid,.old_closed_ready(1'b1),.old_closed_ref,
        .m_axi_arvalid(arvalid),.m_axi_arready(arready),.m_axi_araddr(araddr),.m_axi_arid(arid),.m_axi_arlen(arlen),.m_axi_arsize(arsize),.m_axi_arburst(arburst),
        .m_axi_rvalid(rvalid),.m_axi_rready(rready),.m_axi_rdata(rdata),.m_axi_rid(rid),.m_axi_rresp(rresp),.m_axi_rlast(rlast),
        .active_valid,.active_bundle,.active_sequence,.scan_token,.video_policy,.frozen,.committed,.snapshot_hold(hold),.quarantined(q),.underrun_lines(underruns));
    axi_read_byte_slave #(.IMAGE_WIDTH(20),.IMAGE_HEIGHT(8)) memory (
        .clk(core_clk),.rst(!safe_reset_n),.source_for_result,.ideal(1'b1),.ar_pause(1'b0),.r_pause(1'b0),.fault_mode(3'd2),
        .arvalid,.arready,.araddr,.arid,.arlen,.arsize,.arburst,.rvalid,.rready,.rdata,.rid,.rresp,.rlast,.ar_count,.r_count,.idle(slave_idle));
    function automatic command_t source_cmd(input integer op,input logic [7:0] flags=0);
        command_t c;c='0;c.op=4'(op);c.flags=flags;c.source_handle=source.source_handle;c.origin=source.origin;return c;
    endfunction
    function automatic command_t result_cmd(input integer op,input logic [7:0] flags=0);
        command_t c;c='0;c.op=4'(op);c.flags=flags;c.source_handle=offer.source_handle;c.result_handle=offer.result_handle;
        c.origin=offer.origin;c.cj=offer.cj;c.policy=offer.policy;return c;
    endfunction
    task automatic exchange(input command_t c);
        @(negedge core_clk);wait(cmd_ready);command=c;cmd_valid=1;@(negedge core_clk);cmd_valid=0;
        wait(reply_valid);@(negedge core_clk);saved=reply;if(saved.status!=0)$fatal(1,"Owner setup status");
        $fdisplay(owner_journal,"EVENT,%h,%h,%h,%h,%h,%h,%h,%b,%b,%b,%b",c,saved,source_states,result_states,latest,freeze,policy,owner_frozen,owner_q,se,re);
        transactions++;reply_ready=1;@(negedge core_clk);reply_ready=0;
    endtask
    initial begin
        command_t c;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        journal=$fopen("fault-events.jsonl","w");owner_journal=$fopen("events.csv","w");command=0;control=0;source=0;offer=0;
        repeat(8)@(negedge core_clk);safe_reset_n=1;repeat(12)@(negedge core_clk);$fdisplay(owner_journal,"RESET,20,8,1");
        c='0;c.op=ALLOC_SOURCE;c.origin[130:67]={32'd200,32'h88};exchange(c);source=saved;
        exchange(source_cmd(SOURCE_EOF));exchange(source_cmd(SOURCE_END,7));
        c='0;c.op=ALLOC_RESULT;c.source_handle=source.source_handle;c.origin=source.origin;
        c.cj={1'b1,1'b1,11'd320,11'd64,11'd8,11'd20,32'd55,64'd0};c.body={288'd0,3'd1,11'd4,96'd0,2'd0};
        exchange(c);offer=saved;exchange(result_cmd(RESULT_END,7));exchange(result_cmd(OFFER));offer=saved;source_for_result[offer.result_slot]=offer.source_slot;
        control.kind=HC_OFFER;control.sequence_id=64'h1234000000000100;control.target_policy=1;control.bundle=offer;
        @(negedge core_clk);wait(control_ready);control_valid=1;@(negedge core_clk);control_valid=0;
        wait(wrong_rid>0 && q);@(negedge core_clk);cancel_valid=1;@(negedge core_clk);cancel_valid=0;
        repeat(80)@(negedge core_clk);
        @(negedge video_clk);manual_vs=1;@(negedge video_clk);manual_vs=0;repeat(80)@(negedge core_clk);
        if(!q || !dut.engine_q || response_valid || old_closed_valid || dut.candidate_closed_valid || active_valid)
            $fatal(1,"Unknown response did not remain isolated");
        if(result_states[offer.result_slot*3+:3]!=R_OFFERED || source_states[source.source_slot*3+:3]!=S_COMPLETE || !dut.transport_live)
            $fatal(1,"Unknown IO falsely released owner/transport reference");
        $fdisplay(journal,"{\"event\":\"end\",\"q\":1,\"engine_q\":1,\"source_state\":3,\"result_state\":3,\"closed\":0,\"response\":0,\"transport_live\":1}");$fclose(journal);$fclose(owner_journal);
        owner_metrics=$fopen("protocol-metrics.json","w");$fdisplay(owner_metrics,"{\"finished\":true,\"transactions\":%0d,\"resets\":1}",transactions);$fclose(owner_metrics);
        metrics=$fopen("fault-metrics.json","w");$fdisplay(metrics,"{\"finished\":true,\"expected_quarantine\":true,\"wrong_rid_handshakes\":%0d,\"ar\":%0d,\"r\":%0d,\"unknown_io_closed\":false,\"owner_refs_retained\":true,\"hardware_verified\":false}",wrong_rid,ars,rs);$fclose(metrics);
        finished=1;$finish;
    end
    always @(posedge core_clk)if(safe_reset_n)begin
        if(arvalid && arready)begin ars++;$fdisplay(journal,"{\"event\":\"ar\",\"id\":%0d,\"length\":%0d,\"address\":%0d}",arid,arlen+1,araddr);end
        if(rvalid && rready)begin
            rs++;if(rid!=2)wrong_rid++;
            $fdisplay(journal,"{\"event\":\"r\",\"id\":%0d,\"response\":%0d,\"last\":%0d}",rid,rresp,rlast);
        end
        if(wrong_rid && (old_closed_valid || response_valid))$fatal(1,"Unknown RID produced closure/response");
    end
    initial begin #1000000;$fatal(1,"Fault scenario timeout");end
endmodule
