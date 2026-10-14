`timescale 1ns/1ps
module tb_row_scan_join #(parameter integer TEST_JOIN_W=20,TEST_JOIN_H=8);
    import display_row_pkg::*;import display_handoff_pkg::*;
    localparam integer PAIRS=TEST_JOIN_W/2;
    logic core_clk=0,video_clk=0,safe_reset_n=0,finished=0;
    always #5 core_clk=~core_clk;always #6.734 video_clk=~video_clk;
    logic [2:0] fill_valid=0,fill_reply_ready=0,wr_valid=0,publish_valid=0,io_closed=0,producer_closed=0,abort_valid=0,row_ready=0,rd_request_valid=0,rd_response_ready=0,release_valid=0;
    wire [2:0] return_ready;
    wire [2:0] fill_ready,fill_reply_valid,wr_ready,publish_ready,abort_ready,return_valid,core_busy,exhausted,quarantined,write_error,row_valid,owned,rd_request_ready,rd_response_valid,rd_error,release_ready,release_error;
    logic [2:0][542:0] fill_ticket=0;wire [2:0][542:0] fill_reply_ticket,return_ticket,row_ticket;
    wire [2:0][2:0] fill_reply_status;wire [2:0][1:0] return_kind;
    logic [2:0][63:0] wr_generation=0,publish_generation=0,abort_generation=0,rd_generation=0,release_generation=0;
    logic [2:0][9:0] wr_address=0,rd_address=0;wire [2:0][9:0] rd_response_address;
    logic [2:0][53:0] wr_data=0;wire [2:0][53:0] rd_data;logic [2:0][1:0] release_kind=0;
    display_rows3 #(.IMAGE_WIDTH(TEST_JOIN_W),.IMAGE_HEIGHT(TEST_JOIN_H),.INIT_GENERATION(1)) dut(.*);
    logic request_valid=0,response_ready=0,cancel_valid=0,vsync_tick=0,scan_de=0;wire request_ready,response_valid;
    logic [1136:0] request=0;wire [1206:0] response;logic [63:0] cancel_sequence=0;
    wire candidate_valid,cancel_candidate,prepare_selected,active_valid,active_changed;
    wire [941:0] candidate_bundle,active_bundle;wire [63:0] candidate_sequence,candidate_target_scan,previous_result;
    wire [63:0] scan_token,video_policy,frozen_source;wire frozen,committed,snapshot_hold,core_inflight,quarantined_parent;
    wire [2:0] error_reason;wire [63:0] error_sequence;
    row_ticket_t row0_view,row2_view,closed_view;
    assign row0_view=row_ticket[0];assign row2_view=row_ticket[2];
    wire prepared_valid=candidate_valid && (candidate_sequence==777 ? owned[0] : owned[2]);
    wire [542:0] prepared_ticket=candidate_sequence==777 ? row_ticket[0] : row_ticket[2];
    row_ticket_t prepared_view;assign prepared_view=prepared_ticket;
    wire close_src_ready,close_dst_valid,close_src_run,close_dst_run;wire [542:0] close_dst_data;
    logic return0_ready=0;
    assign return_ready={close_src_ready,1'b0,return0_ready};
    atomic_mailbox #(.PAYLOAD_WIDTH(543)) closed_link(
        .src_clk(core_clk),.dst_clk(video_clk),.safe_reset_n,.src_valid(return_valid[2]),.src_ready(close_src_ready),.src_data(return_ticket[2]),
        .dst_valid(close_dst_valid),.dst_ready(1'b1),.dst_data(close_dst_data),.src_running(close_src_run),.dst_running(close_dst_run));
    assign closed_view=close_dst_data;
    display_handoff #(.IMAGE_WIDTH(TEST_JOIN_W),.IMAGE_HEIGHT(TEST_JOIN_H),.WATCHDOG_CYCLES(8192)) handoff(
        .core_clk,.video_clk,.safe_reset_n,.request_valid,.request_ready,.request,.response_valid,.response_ready,.response,
        .cancel_valid,.cancel_sequence,.vsync_tick,.scan_de,.prepared_valid,
        .prepared_sequence(prepared_view.sequence_id),.prepared_scan(prepared_view.scan),.prepared_result(prepared_view.result_handle),
        .prepared_policy(prepared_view.policy),.prepared_origin(prepared_view.origin),.retire_capacity(1'b1),
        .closed_valid(close_dst_valid),.closed_sequence(closed_view.sequence_id),.closed_result(closed_view.result_handle),.closed_policy(closed_view.policy),.closed_origin(closed_view.origin),
        .candidate_valid,.candidate_bundle,.candidate_sequence,.candidate_target_scan,.cancel_candidate,.prepare_selected,
        .active_valid,.active_bundle,.active_changed,.previous_result,.scan_token,.video_policy,.frozen_source,.frozen,.committed,.snapshot_hold,
        .core_inflight,.quarantined(quarantined_parent),.error_reason,.error_sequence);
    integer journal,link_journal,requests=0,responses=0,writes=0,reads=0,rows=0,returns=0,read_requests=0,fill_count[3],pub_count[3],row_count[3],rel_count[3];
    frame_owner_pkg::reply_t offer_a,offer_b;row_ticket_t ticket_a,ticket_b;route_response_t last_response;
    function automatic logic [31:0] aligned(input integer n);return 32'((n+15)&~15);endfunction
    function automatic frame_owner_pkg::reply_t offer(input integer source,input integer result,input integer slot);
        frame_owner_pkg::reply_t b;logic [95:0] src,edge_desc;integer n;
        b='0;n=TEST_JOIN_W*TEST_JOIN_H;b.op=5;b.source_handle=64'(source);b.result_handle=64'(result);b.source_slot=3'(slot);b.result_slot=2'(slot);b.policy=1;
        b.origin={64'(source),32'd1,32'h45,64'(source),3'(slot)};
        b.cj={1'b1,1'b1,11'd320,11'd64,11'(TEST_JOIN_H),11'(TEST_JOIN_W),32'd21,32'd1,32'h45};
        src={32'(slot*8388608),32'(3*n),aligned(3*n)};edge_desc={32'(50331648+slot*8388608),32'((n+7)/8),aligned((n+7)/8)};
        b.body={src,edge_desc,96'd0,3'd4,11'(TEST_JOIN_H/2),24'hff0000,24'h00ff00,24'h00a0ff,24'hffff00,2'b11};return b;
    endfunction
    function automatic row_ticket_t ticket(input frame_owner_pkg::reply_t b,input integer seq,input integer scan);
        row_ticket_t t;t='0;t.generation=1;t.sequence_id=64'(seq);t.scan=64'(scan);t.result_handle=b.result_handle;t.policy=b.policy;t.origin=b.origin;t.mode=4;t.required_mask=3;return t;
    endfunction
    function automatic logic [53:0] pattern(input row_ticket_t t,input integer address);
        logic [53:0] d;integer x,y,f;
        d=0;y=int'(t.source_y);f=int'(t.origin[130:99]);
        for(integer lane=0;lane<2;lane++)begin
            x=2*address+lane;
            d[lane*24+:24]={8'((x*37+y*11+f*3)%256),8'((x*13+y*47+f*7)%256),8'((x*53+y*19+f*17)%256)};
            d[48+lane]=((x+y+f)%3)==0;d[50+2*lane+:2]=2'((x*7+y*3+f)%4);
        end
        return d;
    endfunction
    always @(posedge core_clk)if(safe_reset_n)begin
        for(integer b=0;b<3;b++)begin
            if(fill_valid[b]&&fill_ready[b])begin fill_count[b]++;$fwrite(journal,"FILL,%0t,%0d,%h\n",$realtime,b,fill_ticket[b]);end
            if(fill_reply_valid[b]&&fill_reply_ready[b])$fwrite(journal,"FILL_REPLY,%0t,%0d,%h,%0d\n",$realtime,b,fill_reply_ticket[b],fill_reply_status[b]);
            if(wr_valid[b]&&wr_ready[b])begin writes++;$fwrite(journal,"WRITE,%0t,%0d,%h,%0d,%h\n",$realtime,b,wr_generation[b],wr_address[b],wr_data[b]);end
            if(publish_valid[b]&&publish_ready[b])begin pub_count[b]++;$fwrite(journal,"PUBLISH,%0t,%0d,%h,%b,%b\n",$realtime,b,publish_generation[b],io_closed[b],producer_closed[b]);end
            if(return_valid[b]&&return_ready[b])begin returns++;$fwrite(journal,"RETURN,%0t,%0d,%h,%0d\n",$realtime,b,return_ticket[b],return_kind[b]);$fwrite(link_journal,"ROW_RETURN,%0t,%0d,%h\n",$realtime,b,return_ticket[b]);end
        end
        if(request_valid&&request_ready)begin requests++;$fwrite(link_journal,"REQ,%0t,%h\n",$realtime,request);end
        if(response_valid&&response_ready)begin responses++;$fwrite(link_journal,"RSP,%0t,%h\n",$realtime,response);end
        if(cancel_valid)$fwrite(link_journal,"CANCEL,%0t,%h\n",$realtime,cancel_sequence);
    end
    always @(posedge video_clk)if(safe_reset_n)begin
        for(integer b=0;b<3;b++)begin
            if(row_valid[b]&&row_ready[b])begin row_count[b]++;rows++;$fwrite(journal,"ROW,%0t,%0d,%h\n",$realtime,b,row_ticket[b]);end
            if(rd_request_valid[b]&&rd_request_ready[b])begin read_requests++;$fwrite(journal,"READ,%0t,%0d,%h,%0d\n",$realtime,b,rd_generation[b],rd_address[b]);end
            if(rd_response_valid[b]&&rd_response_ready[b])begin reads++;$fwrite(journal,"DATA,%0t,%0d,%0d,%h,%b\n",$realtime,b,rd_response_address[b],rd_data[b],rd_error[b]);end
            if(release_valid[b]&&release_ready[b])begin rel_count[b]++;$fwrite(journal,"RELEASE,%0t,%0d,%h,%0d\n",$realtime,b,release_generation[b],release_kind[b]);end
        end
        if(vsync_tick)$fwrite(link_journal,"TICK,%0t,%h,%h,%b\n",$realtime,scan_token,prepared_ticket,prepared_valid);
        if(close_dst_valid)$fwrite(link_journal,"CLOSED,%0t,%h\n",$realtime,close_dst_data);
        #0.001;if(active_changed)$fwrite(link_journal,"APPLY,%0t,%h,%h\n",$realtime,active_bundle,scan_token);
    end
    task automatic fill_row(input integer b,input row_ticket_t t);
        integer n;
        @(negedge core_clk);n=fill_count[b];fill_ticket[b]=t;fill_valid[b]=1;while(fill_count[b]==n)@(negedge core_clk);fill_valid[b]=0;
        while(!fill_reply_valid[b])@(negedge core_clk);if(fill_reply_status[b]!=0 || fill_reply_ticket[b]!==t)$fatal(1,"Join fill reply");
        fill_reply_ready[b]=1;@(negedge core_clk);fill_reply_ready[b]=0;
        for(integer a=0;a<PAIRS;a++)begin wr_generation[b]=1;wr_address[b]=10'(a);wr_data[b]=pattern(t,a);wr_valid[b]=1;while(!wr_ready[b])@(negedge core_clk);@(negedge core_clk);end
        wr_valid[b]=0;n=pub_count[b];publish_generation[b]=1;io_closed[b]=1;producer_closed[b]=1;publish_valid[b]=1;
        while(pub_count[b]==n)@(negedge core_clk);publish_valid[b]=0;
        while(!row_valid[b])@(negedge video_clk);n=row_count[b];row_ready[b]=1;while(row_count[b]==n)@(negedge video_clk);row_ready[b]=0;
    endtask
    task automatic send_offer(input frame_owner_pkg::reply_t b,input integer seq);
        route_request_t q;integer n;q='0;q.kind=HC_OFFER;q.sequence_id=64'(seq);q.target_policy=1;q.bundle=b;
        @(negedge core_clk);n=requests;request=q;request_valid=1;while(requests==n)@(negedge core_clk);request_valid=0;
    endtask
    task automatic tick;@(negedge video_clk);vsync_tick=1;@(negedge video_clk);vsync_tick=0;endtask
    task automatic receive(input integer status);
        while(!response_valid)@(negedge core_clk);last_response=response;
        if(last_response.status!=status)$fatal(1,"Join response status");
        repeat(11)begin @(negedge core_clk);if(response!==last_response || !response_valid)$fatal(1,"Join held response");end
        response_ready=1;@(negedge core_clk);response_ready=0;repeat(15)@(negedge core_clk);
    endtask
    task automatic discard_row(input integer b);
        integer n;@(negedge video_clk);n=rel_count[b];release_generation[b]=1;release_kind[b]=ROW_DISCARDED;release_valid[b]=1;
        while(rel_count[b]==n)@(negedge video_clk);release_valid[b]=0;
    endtask
    initial begin
        integer metrics,n;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");journal=$fopen("row-events.csv","w");link_journal=$fopen("handoff-link-events.csv","w");
        for(integer b=0;b<3;b++)begin fill_count[b]=0;pub_count[b]=0;row_count[b]=0;rel_count[b]=0;end
        repeat(9)@(negedge core_clk);safe_reset_n=1;repeat(9)@(negedge core_clk);$fwrite(journal,"RESET,%0t,%0d,%0d,%h\n",$realtime,TEST_JOIN_W,TEST_JOIN_H,64'd1);
        offer_a=offer(9,99,0);ticket_a=ticket(offer_a,777,2);send_offer(offer_a,777);fill_row(0,ticket_a);wait(candidate_valid);tick();
        repeat(7)@(negedge core_clk);if(active_valid || response_valid)$fatal(1,"Wrong scan row applied");tick();receive(HC_OK);
        if(active_bundle!==offer_a || last_response.bundle!==offer_a || !active_valid)$fatal(1,"Real complete row not applied");
        offer_b=offer(19,199,1);ticket_b=ticket(offer_b,778,3);send_offer(offer_b,778);fill_row(2,ticket_b);wait(candidate_valid);
        @(negedge video_clk);n=read_requests;rd_request_valid[2]=1;rd_generation[2]=1;rd_address[2]=0;while(read_requests==n)@(negedge video_clk);rd_request_valid[2]=0;
        wait(rd_response_valid[2]);if(rd_data[2]!==pattern(ticket_b,0) || rd_error[2])$fatal(1,"Join native row data");
        @(negedge core_clk);cancel_sequence=778;cancel_valid=1;@(negedge core_clk);cancel_valid=0;wait(cancel_candidate);
        tick();@(negedge video_clk);release_valid[2]=1;release_generation[2]=1;release_kind[2]=ROW_DISCARDED;
        repeat(13)begin @(negedge video_clk);if(release_ready[2] || return_valid[2] || response_valid)$fatal(1,"Candidate closed before final holding consumed");end
        release_valid[2]=0;rd_response_ready[2]=1;while(reads==0)@(negedge video_clk);rd_response_ready[2]=0;discard_row(2);receive(HC_CANCELED);
        if(!last_response.candidate_closed || active_bundle!==offer_a || last_response.bundle!==offer_b)$fatal(1,"Wrong candidate closed/active");
        discard_row(0);while(!return_valid[0])@(negedge core_clk);return0_ready=1;@(negedge core_clk);return0_ready=0;repeat(5)@(negedge core_clk);
        if(owned!=0 || core_busy!=0 || quarantined_parent)$fatal(1,"Join row borrow leak");
        $fclose(journal);$fclose(link_journal);metrics=$fopen("protocol-metrics.json","w");
        $fwrite(metrics,"{\"finished\":true,\"join\":true,\"width\":%0d,\"height\":%0d,\"row_count\":2,\"near_max\":0,\"writes\":%0d,\"reads\":%0d,\"errors\":0,\"rows\":%0d,\"returns\":%0d,\"resets\":1,\"safe_reset_aborted_rows\":0,\"requests\":%0d,\"responses\":%0d}\n",TEST_JOIN_W,TEST_JOIN_H,writes,reads,rows,returns,requests,responses);$fclose(metrics);
        finished=1;$display("Row/handoff join PASS real rows=%0d native_reads=%0d",rows,reads);$finish;
    end
    initial begin #1000000;if(!finished)$fatal(1,"Row join suite watchdog");end
endmodule
