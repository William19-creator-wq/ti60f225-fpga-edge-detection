`timescale 1ns/1ps
module tb_display_handoff #(
    parameter integer TEST_HANDOFF_W=1920,TEST_HANDOFF_H=1080,TEST_FULL_SCAN=0,TEST_LIMIT=0
);
    import display_handoff_pkg::*;
    import frame_owner_pkg::*;
    localparam logic [63:0] MAX64=64'hffffffffffffffff;
    localparam logic [63:0] INITIAL_POLICY=TEST_LIMIT==1 ? MAX64 : 64'd1;
    localparam logic [63:0] INITIAL_SCAN=TEST_LIMIT==2 ? MAX64-1 : 64'd0;
    localparam logic [63:0] INITIAL_SEQUENCE=TEST_LIMIT==3 ? MAX64-1 : 64'd0;
    logic core_clk=0,video_clk=0,video_enable=1,safe_reset_n=0,finished=0;
    always #5 core_clk=~core_clk;
    always #6.734 if(video_enable)video_clk=~video_clk;
    logic request_valid=0,response_ready=0,cancel_valid=0;wire request_ready,response_valid;
    logic [1136:0] request=0;wire [1206:0] response;logic [63:0] cancel_sequence=0;
    logic manual_tick=0,manual_de=0,old_vs=0;
    wire timing_de,timing_hs,timing_vs,timing_start;wire [10:0] timing_x,timing_y;
    video_timing_1080p_pair timing(.clk(video_clk),.rst(!safe_reset_n),.de(timing_de),.hs(timing_hs),.vs(timing_vs),.frame_start(timing_start),.x_even(timing_x),.y(timing_y));
    always @(posedge video_clk or negedge safe_reset_n)if(!safe_reset_n)old_vs<=0;else old_vs<=timing_vs;
    wire vsync_tick=TEST_FULL_SCAN ? timing_vs&&!old_vs : manual_tick;
    wire scan_de=TEST_FULL_SCAN ? timing_de : manual_de;
    logic prepared_valid=0,retire_capacity=1,closed_valid=0;
    logic [63:0] prepared_sequence=0,prepared_scan=0,prepared_result=0,prepared_policy=0;
    logic [194:0] prepared_origin=0,closed_origin=0;
    logic [63:0] closed_sequence=0,closed_result=0,closed_policy=0;
    wire candidate_valid,cancel_candidate,prepare_selected,active_valid,active_changed;
    wire [941:0] candidate_bundle,active_bundle;wire [63:0] candidate_sequence,candidate_target_scan,previous_result;
    wire [63:0] scan_token,video_policy,frozen_source;wire frozen,committed,snapshot_hold,core_inflight,quarantined;
    wire [2:0] error_reason;wire [63:0] error_sequence;
`ifdef HANDOFF_POST_MAP
    display_handoff dut(.*);
`else
    display_handoff #(.IMAGE_WIDTH(TEST_HANDOFF_W),.IMAGE_HEIGHT(TEST_HANDOFF_H),.WATCHDOG_CYCLES(TEST_FULL_SCAN ? 50500000 : 8192),
        .INIT_POLICY(INITIAL_POLICY),.INIT_SCAN(INITIAL_SCAN),.INIT_LAST_SEQUENCE(INITIAL_SEQUENCE)) dut(.*);
`endif

    logic cmd_valid=0,reply_ready=0;wire cmd_ready,reply_valid;logic [940:0] command=0;wire [941:0] reply;
    wire [17:0] source_states;wire [8:0] result_states;wire [63:0] latest_handle,freeze_handle,policy;
    wire owner_frozen,owner_quarantined,source_exhausted,result_exhausted;
    frame_owner #(.IMAGE_WIDTH(TEST_HANDOFF_W),.IMAGE_HEIGHT(TEST_HANDOFF_H),.INIT_POLICY(INITIAL_POLICY)) owner(
        .core_clk,.safe_reset_n,.cmd_valid,.cmd_ready,.command,.reply_valid,.reply_ready,.reply,.source_states,.result_states,
        .latest_handle,.freeze_handle,.policy,.frozen(owner_frozen),.quarantined(owner_quarantined),.source_exhausted,.result_exhausted);
    integer journal,owner_journal,requests=0,responses=0,changes=0,ticks=0,resets=0,owner_events=0,owner_holds=0,held_cycles=0,frame_counter=0;
    logic [63:0] next_sequence=INITIAL_SEQUENCE+1;
    route_response_t last_response;frame_owner_pkg::reply_t owner_reply,sources_saved[0:7],offers_saved[0:7];
    logic [1206:0] held_response;logic held=0;
    logic [941:0] last_active=0;logic last_active_valid=0,last_frozen=0,last_committed=0,last_hold=0;
    logic [63:0] last_policy=INITIAL_POLICY,last_frozen_source=0;logic last_q=0;
    always @(posedge core_clk)if(safe_reset_n)begin
        if(held && (!response_valid || response!==held_response))$fatal(1,"Core held response changed");
        held=response_valid&&!response_ready;held_response=response;if(held)held_cycles++;
        if(request_valid&&request_ready)begin requests++;$fwrite(journal,"REQ,%0t,%h\n",$realtime,request);end
        if(cancel_valid)$fwrite(journal,"CANCEL,%0t,%h\n",$realtime,cancel_sequence);
        if(response_valid&&response_ready)begin responses++;$fwrite(journal,"RSP,%0t,%h\n",$realtime,response);end
        if(quarantined&&!last_q)$fwrite(journal,"FAULT,%0t,%0d,%h\n",$realtime,error_reason,error_sequence);
        last_q=quarantined;
    end
    // 沿前记录资格，沿后记录结果；不把内部state当作参考期望。
    always @(posedge video_clk)if(safe_reset_n)begin
        logic tick_sample,de_sample;tick_sample=vsync_tick;de_sample=scan_de;
        if(vsync_tick)begin
            ticks++;$fwrite(journal,"TICK,%0t,%h,%b,%b,%h,%h,%h,%h,%h,%b\n",$realtime,scan_token,scan_de,prepared_valid,prepared_sequence,prepared_scan,prepared_result,prepared_policy,prepared_origin,retire_capacity);
        end
        if(closed_valid)$fwrite(journal,"CLOSED,%0t,%h,%h,%h,%h\n",$realtime,closed_sequence,closed_result,closed_policy,closed_origin);
        #0.001;
        if(active_valid!=last_active_valid || active_bundle!==last_active)begin
            if(!tick_sample || de_sample || !active_changed || !prepare_selected)$fatal(1,"Active changed outside qualified blank VS");
            changes++;$fwrite(journal,"APPLY,%0t,%h,%h,%h\n",$realtime,active_bundle,previous_result,scan_token);
        end
        if(video_policy!=last_policy || frozen!=last_frozen || committed!=last_committed || snapshot_hold!=last_hold || frozen_source!=last_frozen_source)
            $fwrite(journal,"CONTROL,%0t,%h,%b,%b,%b,%h\n",$realtime,video_policy,frozen,committed,snapshot_hold,frozen_source);
        last_active=active_bundle;last_active_valid=active_valid;last_policy=video_policy;last_frozen=frozen;last_committed=committed;last_hold=snapshot_hold;last_frozen_source=frozen_source;
    end
    function automatic command_t source_command(input integer op,input frame_owner_pkg::reply_t b,input logic [7:0] flags=0);
        command_t c;c='0;c.op=4'(op);c.flags=flags;c.source_handle=b.source_handle;c.origin=b.origin;return c;
    endfunction
    function automatic command_t result_command(input integer op,input frame_owner_pkg::reply_t b,input logic [7:0] flags=0);
        command_t c;c='0;c.op=4'(op);c.flags=flags;c.source_handle=b.source_handle;c.result_handle=b.result_handle;c.origin=b.origin;c.cj=b.cj;c.policy=b.policy;return c;
    endfunction
    task automatic owner_exchange(input command_t c,input integer expected_status=0);
        frame_owner_pkg::reply_t saved;
        @(negedge core_clk);while(!cmd_ready)@(negedge core_clk);command=c;cmd_valid=1;
        @(negedge core_clk);cmd_valid=0;if(!reply_valid)$fatal(1,"Missing owner reply");saved=reply;command='1;
        repeat(3)begin @(negedge core_clk);if(reply!==saved || !reply_valid || cmd_ready)$fatal(1,"Owner holding changed");owner_holds++;end
        if(saved.status!=expected_status)$fatal(1,"Owner op=%0d status=%0d wanted=%0d",c.op,saved.status,expected_status);
        $fwrite(owner_journal,"EVENT,%h,%h,%h,%h,%h,%h,%h,%b,%b,%b,%b\n",c,saved,source_states,result_states,latest_handle,freeze_handle,policy,owner_frozen,owner_quarantined,source_exhausted,result_exhausted);
        owner_events++;owner_reply=saved;reply_ready=1;@(negedge core_clk);reply_ready=0;
    endtask
    task automatic make_source(input integer index);
        command_t c;c='0;c.op=ALLOC_SOURCE;frame_counter++;c.origin[130:67]={32'(frame_counter),32'h45};owner_exchange(c);sources_saved[index]=owner_reply;
        owner_exchange(source_command(SOURCE_EOF,sources_saved[index]));owner_exchange(source_command(SOURCE_END,sources_saved[index],8'h07));
    endtask
    task automatic make_offer(input integer index,input integer source_index,input integer mode=4);
        command_t c;c='0;c.op=ALLOC_RESULT;c.source_handle=sources_saved[source_index].source_handle;c.origin=sources_saved[source_index].origin;
        c.cj={1'b1,1'b1,11'd320,11'd64,11'(TEST_HANDOFF_H),11'(TEST_HANDOFF_W),32'(index+1),64'd0};
        c.body={288'd0,3'(mode),11'(TEST_HANDOFF_H/2),24'hff0000,24'h00ff00,24'h00a0ff,24'hffff00,2'b11};
        owner_exchange(c);offers_saved[index]=owner_reply;
        owner_exchange(result_command(RESULT_END,offers_saved[index],8'h07));owner_exchange(result_command(OFFER,offers_saved[index]));offers_saved[index]=owner_reply;
    endtask
    task automatic cold_reset;
        video_enable=1;@(negedge core_clk);safe_reset_n=0;request_valid=0;response_ready=0;cancel_valid=0;cmd_valid=0;reply_ready=0;
        prepared_valid=0;closed_valid=0;manual_tick=0;manual_de=0;retire_capacity=1;held=0;last_q=0;
        last_active=0;last_active_valid=0;last_policy=INITIAL_POLICY;last_frozen=0;last_committed=0;last_hold=0;last_frozen_source=0;
        repeat(10)@(negedge core_clk);safe_reset_n=1;repeat(10)@(negedge core_clk);resets++;next_sequence=INITIAL_SEQUENCE+1;
        $fwrite(journal,"RESET,%0t,%0d,%0d,%h,%h,%h\n",$realtime,TEST_HANDOFF_W,TEST_HANDOFF_H,INITIAL_POLICY,INITIAL_SCAN,INITIAL_SEQUENCE);
        $fwrite(owner_journal,"RESET,%0d,%0d,%h\n",TEST_HANDOFF_W,TEST_HANDOFF_H,INITIAL_POLICY);
    endtask
    task automatic submit(input integer kind,input logic [941:0] bundle=0,input logic [63:0] target=0,input logic [63:0] cause=0,input logic [63:0] sequence_override=0);
        route_request_t r;integer before_count;r='0;r.kind=3'(kind);r.sequence_id=sequence_override ? sequence_override : next_sequence;
        if(!sequence_override && next_sequence!=MAX64)next_sequence++;r.bundle=bundle;r.cause=cause;r.target_policy=target;
        @(negedge core_clk);before_count=requests;request=r;request_valid=1;
        while(requests==before_count)@(negedge core_clk);request_valid=0;request='1;
    endtask
    task automatic receive(input integer expected_status=0,input integer hold_count=0);
        integer waited=0;route_response_t saved;
        while(!response_valid && waited<10000)begin @(negedge core_clk);waited++;end
        if(!response_valid)$fatal(1,"Missing handoff response, Q=%b reason=%0d",quarantined,error_reason);
        saved=response;if(saved.status!=expected_status)$fatal(1,"Handoff seq=%0d kind=%0d status=%0d wanted=%0d",saved.sequence_id,saved.kind,saved.status,expected_status);
        repeat(hold_count)begin @(negedge core_clk);if(!response_valid || response!==saved || request_ready)$fatal(1,"Held business changed/reaccepted");end
        last_response=saved;response_ready=1;@(negedge core_clk);response_ready=0;repeat(12)@(negedge core_clk);
    endtask
    task automatic tick;
        if(TEST_FULL_SCAN)begin @(negedge video_clk);while(!vsync_tick)@(negedge video_clk);@(negedge video_clk);end
        else begin @(negedge video_clk);manual_tick=1;@(negedge video_clk);manual_tick=0;end
    endtask
    task automatic prepare_candidate;
        frame_owner_pkg::reply_t b;wait(candidate_valid);@(negedge video_clk);b=candidate_bundle;prepared_valid=1;
        prepared_sequence=candidate_sequence;prepared_scan=candidate_target_scan;prepared_result=b.result_handle;prepared_policy=video_policy;prepared_origin=b.origin;
    endtask
    task automatic apply_offer(input integer index,input bit update_owner=1,input integer hold_count=0);
        submit(HC_OFFER,offers_saved[index],video_policy);prepare_candidate();tick();receive(HC_OK,hold_count);prepared_valid=0;
        if(active_bundle!==offers_saved[index] || last_response.bundle!==offers_saved[index])$fatal(1,"Whole offer changed");
        if(update_owner)owner_exchange(result_command(APPLY,offers_saved[index]));
    endtask
    task automatic pulse_cancel(input logic [63:0] sequence_id);
        @(negedge core_clk);cancel_valid=1;cancel_sequence=sequence_id;@(negedge core_clk);cancel_valid=0;
    endtask
    task automatic close_candidate(input bit wrong=0);
        frame_owner_pkg::reply_t b;@(negedge video_clk);b=candidate_bundle;closed_valid=1;closed_sequence=candidate_sequence;closed_result=b.result_handle;
        closed_policy=video_policy;closed_origin=b.origin^(wrong ? 195'd8 : 195'd0);@(negedge video_clk);closed_valid=0;
    endtask
    task automatic freeze_commit(input frame_owner_pkg::reply_t pin,input logic [63:0] cause);
        submit(HC_COMMIT,pin,video_policy,cause);receive();if(snapshot_hold || !committed || frozen_source!=pin.source_handle)$fatal(1,"Freeze commit failed");
    endtask
    initial begin
        command_t c;frame_owner_pkg::reply_t pin,bad;logic [63:0] freeze_sequence,saved_sequence;logic [941:0] saved_active;
        integer metrics;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        journal=$fopen("handoff-events.csv","w");owner_journal=$fopen("owner-events.csv","w");cold_reset();
        if(TEST_LIMIT==1)begin submit(HC_PREPARE,0,0);receive(HC_EXHAUSTED);end
        else if(TEST_LIMIT==2)begin tick();if(scan_token!=MAX64)$fatal(1,"Near max scan mismatch");tick();repeat(10)@(negedge core_clk);if(!quarantined || error_reason!=3 || scan_token!=MAX64)$fatal(1,"Scan wrapped");end
        else if(TEST_LIMIT==3)begin
            submit(7,0,1);receive(HC_FIELD);submit(7,0,1,0,MAX64);receive(HC_IDENTITY);submit(7,0,1,0,1);receive(HC_IDENTITY);
        end else if(TEST_FULL_SCAN)begin
            make_source(0);make_offer(0,0);apply_offer(0,1,31);make_source(1);make_offer(1,1,5);apply_offer(1);
            owner_exchange(result_command(RETIRE,offers_saved[0],8'h0a));
            if(ticks!=2 || changes!=2)$fatal(1,"Full scan cadence/count");
        end else begin
            make_source(0);make_offer(0,0);submit(HC_OFFER,offers_saved[0],1);prepare_candidate();
            for(integer field_index=0;field_index<6;field_index++)begin
                prepare_candidate();case(field_index)
                    0:prepared_sequence++;1:prepared_scan--;2:prepared_result++;3:prepared_policy++;4:prepared_origin^=195'd8;5:retire_capacity=0;
                endcase
                tick();repeat(5)@(negedge core_clk);if(active_valid || response_valid)$fatal(1,"Wrong qualification applied");retire_capacity=1;
            end
            prepare_candidate();tick();receive(HC_OK,31);prepared_valid=0;owner_exchange(result_command(APPLY,offers_saved[0]));
            make_source(1);make_offer(1,1,5);apply_offer(1,0,23);
            freeze_sequence=next_sequence;submit(HC_PREPARE,0,2);repeat(15)@(negedge video_clk);tick();receive(HC_OK,19);
            if(last_response.bundle!==offers_saved[1] || !snapshot_hold || !frozen || committed)$fatal(1,"Snapshot used stale core A");
            c=result_command(FREEZE,offers_saved[1],8'h01);owner_exchange(c);pin=owner_reply;
            if(freeze_handle!=sources_saved[1].source_handle)$fatal(1,"Owner failed pin actual B");
            submit(HC_COMMIT,pin,2,freeze_sequence+1);receive(HC_IDENTITY);if(!snapshot_hold)$fatal(1,"Wrong cause released hold");
            bad=pin;bad.body^=400'd1;submit(HC_COMMIT,bad,2,freeze_sequence);receive(HC_IDENTITY);
            freeze_commit(pin,freeze_sequence);owner_exchange(result_command(APPLY,offers_saved[1]));
            make_offer(2,1,1);apply_offer(2);owner_exchange(result_command(RETIRE,offers_saved[0],8'h0a));owner_exchange(result_command(RETIRE,offers_saved[1],8'h0a));
            submit(HC_RESUME,0,3);repeat(12)@(negedge video_clk);tick();receive();c='0;c.op=RESUME;owner_exchange(c);
            if(frozen || owner_frozen || active_bundle!==offers_saved[2])$fatal(1,"Resume released current display");

            // 合法取消必须等待完全匹配的实际closed；ready与取消同VS时取消优先。
            make_source(2);make_offer(3,2);saved_sequence=next_sequence;submit(HC_OFFER,offers_saved[3],3);prepare_candidate();
            pulse_cancel(saved_sequence+99);repeat(8)@(negedge video_clk);if(cancel_candidate)$fatal(1,"Wrong sequence canceled");
            pulse_cancel(saved_sequence);repeat(8)@(negedge video_clk);tick();wait(cancel_candidate);saved_active=active_bundle;
            close_candidate(1);repeat(17)@(negedge core_clk);if(response_valid || active_bundle!==saved_active)$fatal(1,"Wrong closed or canceled apply");
            close_candidate();receive(HC_CANCELED,11);prepared_valid=0;if(!last_response.candidate_closed)$fatal(1,"Closed proof missing");owner_exchange(result_command(DROP_RESULT,offers_saved[3],8'h0a));
            bad=offers_saved[2];bad.op=OFFER;bad.body^=400'h10000000000000000000000000000;
            submit(HC_OFFER,bad,3);receive(HC_FIELD);if(last_response.candidate_closed || active_bundle!==saved_active)$fatal(1,"Invalid offer faked closure");
            saved_sequence=next_sequence;submit(7,0,3);receive(HC_FIELD);submit(7,0,3,0,saved_sequence);receive(HC_IDENTITY);
            // 等待freeze时取消；已发布APPLIED回复的迟取消不改内容。
            saved_sequence=next_sequence;submit(HC_PREPARE,0,4);pulse_cancel(saved_sequence);receive(HC_CANCELED);if(frozen || video_policy!=3)$fatal(1,"Canceled prepare changed policy");
            make_offer(4,2,2);saved_sequence=next_sequence;submit(HC_OFFER,offers_saved[4],3);prepare_candidate();tick();wait(response_valid);
            pulse_cancel(saved_sequence);receive(HC_OK,33);prepared_valid=0;owner_exchange(result_command(APPLY,offers_saved[4]));owner_exchange(result_command(RETIRE,offers_saved[2],8'h0a));

            // NO_ACTIVE先commit零源，再绑定owner在第一帧完成时真正加的FREEZE。
            cold_reset();freeze_sequence=next_sequence;submit(HC_PREPARE,0,2);repeat(12)@(negedge video_clk);tick();receive();
            if(last_response.has_active || snapshot_hold || last_response.bundle!=0)$fatal(1,"NO_ACTIVE mismatch");
            c='0;c.op=FREEZE;owner_exchange(c);pin=owner_reply;freeze_commit(pin,freeze_sequence);make_source(0);
            pin='0;pin.op=FREEZE;pin.status=OK;pin.source_handle=sources_saved[0].source_handle;pin.origin=sources_saved[0].origin;pin.source_slot=sources_saved[0].source_slot;pin.result_slot=3;pin.policy=policy;
            if(freeze_handle!=pin.source_handle)$fatal(1,"First completed source not pinned");freeze_commit(pin,freeze_sequence);
            make_offer(0,0);apply_offer(0);submit(HC_RESUME,0,3);repeat(12)@(negedge video_clk);tick();receive();c='0;c.op=RESUME;owner_exchange(c);

            // COMMIT在owner已pin后取消仍保留snapshot hold；先重试结清，再允许RESUME。
            freeze_sequence=next_sequence;submit(HC_PREPARE,0,4);repeat(12)@(negedge video_clk);tick();receive();
            owner_exchange(result_command(FREEZE,offers_saved[0],8'h01));pin=owner_reply;saved_sequence=next_sequence;
            submit(HC_COMMIT,pin,4,freeze_sequence);pulse_cancel(saved_sequence);receive(HC_CANCELED);
            if(!snapshot_hold || committed || freeze_handle!=pin.source_handle)$fatal(1,"Canceled commit lost snapshot pin");
            submit(HC_RESUME,0,5);receive(HC_STATE);freeze_commit(pin,freeze_sequence);
            submit(HC_RESUME,0,5);repeat(12)@(negedge video_clk);tick();receive();c='0;c.op=RESUME;owner_exchange(c);

            // NO_ACTIVE已有latest时，COMMIT使用owner返回的真实source-only整包。
            cold_reset();make_source(0);freeze_sequence=next_sequence;submit(HC_PREPARE,0,2);repeat(12)@(negedge video_clk);tick();receive();
            c='0;c.op=FREEZE;owner_exchange(c);pin=owner_reply;
            if(pin.source_handle!=sources_saved[0].source_handle || pin.result_handle!=0)$fatal(1,"NO_ACTIVE latest selection mismatch");
            freeze_commit(pin,freeze_sequence);make_offer(0,0);apply_offer(0);
            submit(HC_RESUME,0,3);repeat(12)@(negedge video_clk);tick();receive();c='0;c.op=RESUME;owner_exchange(c);

            // 业务等不到row0超时，时钟恢复/迟回复均不自动解除隔离。
`ifndef HANDOFF_POST_MAP
            make_source(1);make_offer(1,1);submit(HC_OFFER,offers_saved[1],3);wait(candidate_valid);
            repeat(8300)@(negedge core_clk);if(!quarantined || error_reason!=2 || request_ready || !core_inflight)$fatal(1,"Business timeout not quarantined");
            prepare_candidate();tick();receive();if(!quarantined || request_ready)$fatal(1,"Late reply unquarantined");
            cold_reset();video_enable=0;repeat(8300)@(negedge core_clk);if(!quarantined || error_reason!=1)$fatal(1,"Clock stop not quarantined");
            video_enable=1;repeat(600)@(negedge core_clk);if(!quarantined || request_ready)$fatal(1,"Clock recovery auto-cleared quarantine");
`endif
            cold_reset();manual_de=1;tick();manual_de=0;repeat(10)@(negedge core_clk);if(!quarantined || error_reason!=4)$fatal(1,"Active DE boundary not quarantined");
        end
        $fclose(journal);$fclose(owner_journal);metrics=$fopen("protocol-metrics.json","w");
        $fwrite(metrics,"{\"finished\":true,\"kind\":\"handoff\",\"width\":%0d,\"height\":%0d,\"full_scan\":%0d,\"limit\":%0d,\"requests\":%0d,\"responses\":%0d,\"changes\":%0d,\"ticks\":%0d,\"resets\":%0d,\"held_cycles\":%0d,\"owner_events\":%0d,\"owner_holds\":%0d}\n",TEST_HANDOFF_W,TEST_HANDOFF_H,TEST_FULL_SCAN,TEST_LIMIT,requests,responses,changes,ticks,resets,held_cycles,owner_events,owner_holds);$fclose(metrics);
        finished=1;$display("Display handoff PASS requests=%0d responses=%0d changes=%0d owner_events=%0d",requests,responses,changes,owner_events);$finish;
    end
    initial begin #100000000;if(!finished)$fatal(1,"Handoff suite watchdog");end
endmodule
