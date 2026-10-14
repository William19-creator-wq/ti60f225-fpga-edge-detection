// FP01..08：真实owner/handoff，producer/row0/closed均明确为协议端点fixture。
module tb_frame_publish;
    import frame_owner_pkg::*;
    import display_handoff_pkg::*;
    parameter integer TEST_W=34, TEST_H=20;
    localparam integer PIXELS=TEST_W*TEST_H;
    logic core_clk=0, video_clk=0, rst=1, finished=0;
    always #5 core_clk=~core_clk;
    always #7 video_clk=~video_clk;
    logic halt=0, owner_quarantined, producer_quarantined=0, pause_new_requests=0;
    logic request_valid=0, request_ready;
    logic [63:0] request_token=0, request_source=0;
    logic [194:0] request_origin=0;
    logic [141:0] request_cj=0;
    logic [111:0] request_render=0;
    logic cancel_valid=0;logic [63:0] cancel_token=0;
    wire job_valid;logic job_ready=0;wire [941:0] job_bundle;
    logic producer_done_valid=0;wire producer_done_ready;
    logic [63:0] producer_done_result=0;
    logic [194:0] producer_done_origin=0;
    logic [95:0] producer_done_scope=0;
    logic [1:0] producer_outcome=0;logic [31:0] producer_reason=0;
    logic [21:0] producer_pixels=0, producer_discard=0;
    wire producer_cancel_valid;wire [63:0] producer_cancel_result;wire [95:0] producer_cancel_scope;
    logic source_cmd_valid=0;wire source_cmd_ready;logic [940:0] source_command=0;
    wire source_reply_valid;logic source_reply_ready=0;wire [941:0] source_reply;
    logic policy_cmd_valid=0;wire policy_cmd_ready;logic [940:0] policy_command=0;
    wire policy_reply_valid;logic policy_reply_ready=0;wire [941:0] policy_reply;
    wire owner_cmd_valid,owner_cmd_ready;wire [940:0] owner_command;
    wire [63:0] owner_offer_sequence;wire owner_reply_valid,owner_reply_ready;wire [941:0] owner_reply;
    logic owner_accept_enable=1;wire real_owner_ready;
    logic sequence_valid=1, sequence_exhausted=0;wire sequence_ready;logic [63:0] sequence_value=1;
    wire route_valid,route_ready;wire [1136:0] route_request;
    wire route_reply_valid,route_reply_ready;wire [1206:0] route_reply;
    wire route_cancel_valid;wire [63:0] route_cancel_sequence;
    logic route_accept_enable=1;wire real_route_ready;
    logic oldclosed_valid=0;wire oldclosed_ready;logic [386:0] oldclosed_ref=0;
    wire retired_valid;logic retired_ready=1;wire [386:0] retired_ref;
    wire root_retire_capacity;
    wire completion_valid;logic completion_ready=0;
    wire [63:0] completion_token;wire [1:0] completion_outcome;wire [3:0] completion_status;
    wire [63:0] completion_reason;wire [941:0] completion_bundle;
    wire result_idle,owner_bus_idle,retire_idle,quarantined;
    wire [17:0] source_states;wire [8:0] result_states;
    wire [63:0] latest_handle,freeze_handle,policy;wire frozen,source_exhausted,result_exhausted;
    logic vsync_enable=1,prepare_enable=1,candidate_close_enable=1;
    logic [5:0] video_counter=0;
    wire vsync_tick=vsync_enable && video_counter==31;
    wire candidate_valid,cancel_candidate,prepare_selected,active_valid,active_changed;
    wire [941:0] candidate_bundle,active_bundle;
    wire [63:0] candidate_sequence,candidate_target_scan,previous_display_result,scan_token,video_policy,frozen_source;
    wire video_frozen,committed,snapshot_hold,core_inflight,handoff_q;
    wire [2:0] error_reason;wire [63:0] error_sequence;
    reply_t candidate_view;
    reply_t fixture_source;
    command_t public_owner_command;
    assign public_owner_command=owner_command;
    assign candidate_view=candidate_bundle;
    always @(posedge video_clk) if(rst)video_counter<=0;else video_counter<=video_counter+1'b1;
    assign owner_cmd_ready=real_owner_ready && owner_accept_enable;
    assign route_ready=real_route_ready && route_accept_enable;

    frame_publish_control #(.WIDTH(TEST_W),.HEIGHT(TEST_H)) dut(.*);
    frame_owner_read_authority #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H),.FRAME_ALIGNMENT(64)) owner(
        .core_clk,.safe_reset_n(!rst),.cmd_valid(owner_cmd_valid && owner_accept_enable),.cmd_ready(real_owner_ready),
        .command(owner_command),.offer_sequence(owner_offer_sequence),
        .lookup_valid(1'b0),.lookup_ready(),.lookup_demand(479'd0),.lookup_permitted(),.lookup_bundle(),
        .reply_valid(owner_reply_valid),.reply_ready(owner_reply_ready),.reply(owner_reply),
        .source_states,.result_states,.latest_handle,.freeze_handle,.policy,.frozen,
        .quarantined(owner_quarantined),.source_exhausted,.result_exhausted);
    display_handoff #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H),.FRAME_ALIGNMENT(64),.WATCHDOG_CYCLES(1000000)) handoff(
        .core_clk,.video_clk,.safe_reset_n(!rst),.request_valid(route_valid && route_accept_enable),
        .request_ready(real_route_ready),.request(route_request),.response_valid(route_reply_valid),
        .response_ready(route_reply_ready),.response(route_reply),
        .cancel_valid(route_cancel_valid),.cancel_sequence(route_cancel_sequence),.vsync_tick,.scan_de(1'b0),
        .prepared_valid(candidate_valid && prepare_enable),.prepared_sequence(candidate_sequence),
        .prepared_scan(candidate_target_scan),.prepared_result(candidate_view.result_handle),
        .prepared_policy(candidate_view.policy),.prepared_origin(candidate_view.origin),.retire_capacity(root_retire_capacity),
        .closed_valid(cancel_candidate && candidate_close_enable),.closed_sequence(candidate_sequence),
        .closed_result(candidate_view.result_handle),.closed_policy(candidate_view.policy),.closed_origin(candidate_view.origin),
        .candidate_valid,.candidate_bundle,.candidate_sequence,.candidate_target_scan,.cancel_candidate,.prepare_selected,
        .active_valid,.active_bundle,.active_changed,.previous_result(previous_display_result),
        .scan_token,.video_policy,.frozen_source,.frozen(video_frozen),.committed,.snapshot_hold,
        .core_inflight,.quarantined(handoff_q),.error_reason,.error_sequence);

    integer fd,metric_fd,cycle=0,cases=0,requests=0,jobs=0,dones=0,completions=0,retired=0;
    integer actor_cancels=0,route_cancels=0,owner_commands=0,owner_replies=0,applied=0;
    logic [63:0] next_token=1;
    logic owner_held=0,job_held=0,route_held=0,complete_held=0,retire_held=0;
    logic [1004:0] held_owner;
    logic [941:0] held_job;
    logic [1136:0] held_route;
    logic [1075:0] held_completion;
    logic [386:0] held_retired;
    // 所有日志只在真实接口fire记录；身份核对由独立对象参考完成。
    always @(posedge core_clk) begin
        cycle=cycle+1;
        if(rst)begin owner_held=0;job_held=0;route_held=0;complete_held=0;retire_held=0;end
        else begin
            if(owner_held && (!owner_cmd_valid || {owner_command,owner_offer_sequence}!==held_owner))$fatal(1,"Owner held package changed");
            if(job_held && (!job_valid || job_bundle!==held_job))$fatal(1,"Producer held package changed");
            if(route_held && (!route_valid || route_request!==held_route))$fatal(1,"Route held package changed");
            if(complete_held && (!completion_valid || {completion_token,completion_outcome,completion_status,completion_reason,completion_bundle}!==held_completion))$fatal(1,"Completion held package changed");
            if(retire_held && (!retired_valid || retired_ref!==held_retired))$fatal(1,"Retired held ref changed");
            owner_held=owner_cmd_valid && !owner_cmd_ready;held_owner={owner_command,owner_offer_sequence};
            job_held=job_valid && !job_ready;held_job=job_bundle;
            route_held=route_valid && !route_ready;held_route=route_request;
            complete_held=completion_valid && !completion_ready;
            held_completion={completion_token,completion_outcome,completion_status,completion_reason,completion_bundle};
            retire_held=retired_valid && !retired_ready;held_retired=retired_ref;
            if(request_valid && request_ready)begin
                requests=requests+1;
                $fdisplay(fd,"{\"event\":\"request\",\"cycle\":%0d,\"token\":\"%h\",\"source\":\"%h\",\"origin\":\"%h\",\"cj\":\"%h\",\"render\":\"%h\"}",cycle,request_token,request_source,request_origin,request_cj,request_render);
            end
            if(cancel_valid)$fdisplay(fd,"{\"event\":\"cancel\",\"cycle\":%0d,\"token\":\"%h\"}",cycle,cancel_token);
            if(owner_cmd_valid && owner_cmd_ready)begin
                owner_commands=owner_commands+1;
                $fdisplay(fd,"{\"event\":\"command\",\"cycle\":%0d,\"command\":\"%h\",\"sequence\":\"%h\"}",cycle,owner_command,owner_offer_sequence);
            end
            if(owner_reply_valid && owner_reply_ready)begin
                owner_replies=owner_replies+1;
                $fdisplay(fd,"{\"event\":\"reply\",\"cycle\":%0d,\"reply\":\"%h\",\"ss\":\"%h\",\"rs\":\"%h\",\"latest\":\"%h\",\"freeze\":\"%h\",\"policy\":\"%h\",\"frozen\":%0d,\"q\":%0d,\"se\":%0d,\"re\":%0d}",cycle,owner_reply,source_states,result_states,latest_handle,freeze_handle,policy,frozen,owner_quarantined,source_exhausted,result_exhausted);
            end
            if(job_valid && job_ready)begin jobs=jobs+1;$fdisplay(fd,"{\"event\":\"job\",\"cycle\":%0d,\"bundle\":\"%h\"}",cycle,job_bundle);end
            if(producer_done_valid && producer_done_ready)begin
                dones=dones+1;$fdisplay(fd,"{\"event\":\"producer_done\",\"cycle\":%0d,\"result\":\"%h\",\"origin\":\"%h\",\"scope\":\"%h\",\"outcome\":%0d,\"reason\":%0d,\"pixels\":%0d,\"discard\":%0d}",cycle,producer_done_result,producer_done_origin,producer_done_scope,producer_outcome,producer_reason,producer_pixels,producer_discard);
            end
            if(producer_cancel_valid)begin actor_cancels=actor_cancels+1;$fdisplay(fd,"{\"event\":\"producer_cancel\",\"cycle\":%0d,\"result\":\"%h\",\"scope\":\"%h\"}",cycle,producer_cancel_result,producer_cancel_scope);end
            if(sequence_valid && sequence_ready)begin
                $fdisplay(fd,"{\"event\":\"sequence\",\"cycle\":%0d,\"value\":\"%h\"}",cycle,sequence_value);
                if(sequence_value!=64'hffffffffffffffff && sequence_value!=0)sequence_value<=sequence_value+1;
            end
            if(route_valid && route_ready)$fdisplay(fd,"{\"event\":\"route\",\"cycle\":%0d,\"request\":\"%h\"}",cycle,route_request);
            if(route_cancel_valid)begin route_cancels=route_cancels+1;$fdisplay(fd,"{\"event\":\"route_cancel\",\"cycle\":%0d,\"sequence\":\"%h\"}",cycle,route_cancel_sequence);end
            if(route_reply_valid && route_reply_ready)$fdisplay(fd,"{\"event\":\"route_reply\",\"cycle\":%0d,\"reply\":\"%h\"}",cycle,route_reply);
            if(dut.applied_valid && dut.applied_ready)begin
                applied=applied+1;$fdisplay(fd,"{\"event\":\"applied\",\"cycle\":%0d,\"sequence\":\"%h\",\"bundle\":\"%h\",\"previous\":\"%h\"}",cycle,dut.applied_sequence,dut.applied_bundle,dut.previous_result);
            end
            if(oldclosed_valid && oldclosed_ready)$fdisplay(fd,"{\"event\":\"oldclosed\",\"cycle\":%0d,\"ref\":\"%h\"}",cycle,oldclosed_ref);
            if(retired_valid && retired_ready)begin retired=retired+1;$fdisplay(fd,"{\"event\":\"retired\",\"cycle\":%0d,\"ref\":\"%h\"}",cycle,retired_ref);end
            if(completion_valid && completion_ready)begin
                completions=completions+1;$fdisplay(fd,"{\"event\":\"complete\",\"cycle\":%0d,\"token\":\"%h\",\"outcome\":%0d,\"status\":%0d,\"reason\":\"%h\",\"bundle\":\"%h\"}",cycle,completion_token,completion_outcome,completion_status,completion_reason,completion_bundle);
            end
        end
    end
    always @(posedge video_clk) if(!rst && cancel_candidate && candidate_close_enable)
        $fdisplay(fd,"{\"event\":\"candidate_closed_fixture\",\"sequence\":\"%h\",\"result\":\"%h\"}",candidate_sequence,candidate_view.result_handle);

    task automatic cold;
        begin
            @(negedge core_clk);rst=1;request_valid=0;cancel_valid=0;job_ready=0;producer_done_valid=0;
            source_cmd_valid=0;source_reply_ready=0;policy_cmd_valid=0;policy_reply_ready=0;
            completion_ready=0;oldclosed_valid=0;retired_ready=1;halt=0;producer_quarantined=0;
            pause_new_requests=0;sequence_valid=1;sequence_exhausted=0;sequence_value=1;
            owner_accept_enable=1;route_accept_enable=1;vsync_enable=1;prepare_enable=1;candidate_close_enable=1;
            $fdisplay(fd,"{\"event\":\"reset\",\"width\":%0d,\"height\":%0d}",TEST_W,TEST_H);
            repeat(8)@(negedge core_clk);rst=0;repeat(12)@(negedge core_clk);
        end
    endtask
    task automatic source_transaction(input command_t c,output reply_t b);
        begin
            @(negedge core_clk);source_command=c;source_cmd_valid=1;
            do @(posedge core_clk);while(!source_cmd_ready);
            @(negedge core_clk);source_cmd_valid=0;source_reply_ready=1;
            do @(posedge core_clk);while(!source_reply_valid);
            b=source_reply;
            @(negedge core_clk);source_reply_ready=0;
            if(b.status!=OK)$fatal(1,"Source fixture command failed");
        end
    endtask
    task automatic seed_source;
        command_t c;reply_t b;
        begin
            c='0;c.op=ALLOC_SOURCE;c.origin[130:67]=64'h0000000900000007;source_transaction(c,b);
            c='0;c.op=SOURCE_EOF;c.source_handle=b.source_handle;c.origin=b.origin;source_transaction(c,b);
            c.op=SOURCE_END;c.flags=7;source_transaction(c,b);
            fixture_source=b;
        end
    endtask
    task automatic start_request(input integer mode,input logic bad_cj=0,input integer source_selection=0);
        begin
            @(negedge core_clk);request_token=next_token;next_token=next_token+1;
            request_source=0;request_origin=0;
            if(source_selection!=0)begin
                request_source=fixture_source.source_handle;request_origin=fixture_source.origin;
                if(source_selection==2)request_origin=fixture_source.origin^195'd1;
            end
            request_cj={1'b0,1'b1,11'd400,11'd100,11'(TEST_H),11'(TEST_W),32'(next_token),64'd0};
            if(bad_cj)request_cj[106:96]=11'(TEST_W-2);
            request_render={3'(mode),11'(TEST_H/2),24'hff0000,24'h00ff00,24'h0000ff,24'hffff00,2'b11};
            request_valid=1;
            do @(posedge core_clk);while(!request_ready);
            // 接受后故意改变配置输入；所有执行字段必须继续来自快照。
            @(negedge core_clk);request_valid=0;request_cj='1;request_render='1;
        end
    endtask
    task automatic take_job(output reply_t b);
        begin
            wait(job_valid);@(negedge core_clk);job_ready=1;
            do @(posedge core_clk);while(!job_valid);
            b=job_bundle;@(negedge core_clk);job_ready=0;
        end
    endtask
    task automatic send_done(input reply_t b,input logic[1:0] outc,input integer count,input integer mismatch);
        begin
            @(negedge core_clk);producer_done_result=b.result_handle;
            producer_done_origin=b.origin;producer_done_scope=b.cj[95:0];
            if(mismatch==1)producer_done_result=b.result_handle^64'd1;
            if(mismatch==2)producer_done_scope=b.cj[95:0]^96'd1;
            if(mismatch==3)producer_done_origin=b.origin^195'd1;
            producer_outcome=outc;producer_reason=outc==0?0:32'h1234;
            producer_pixels=22'(count);producer_discard=0;producer_done_valid=1;
            do @(posedge core_clk);while(!producer_done_ready);
            @(negedge core_clk);producer_done_valid=0;
        end
    endtask
    task automatic cancel_current;
        begin @(negedge core_clk);cancel_valid=1;cancel_token=request_token;
            @(negedge core_clk);cancel_valid=0;end
    endtask
    task automatic close_ref(input logic[386:0] r);
        begin @(negedge core_clk);oldclosed_ref=r;oldclosed_valid=1;
            do @(posedge core_clk);while(!oldclosed_ready);
            @(negedge core_clk);oldclosed_valid=0;end
    endtask
    task automatic take_completion(input integer outc,input integer st,output logic[386:0] r);
        reply_t b;
        begin
            wait(completion_valid);repeat(4)@(negedge core_clk);
            if(completion_token!=request_token || completion_outcome!=outc || completion_status!=st)
                $fatal(1,"Completion unexpected token=%0d out=%0d status=%0d",completion_token,completion_outcome,completion_status);
            b=completion_bundle;r={dut.applied_sequence,b.result_handle,b.policy,b.origin};
            completion_ready=1;@(posedge core_clk);@(negedge core_clk);completion_ready=0;
        end
    endtask
    task automatic normal_request(input integer mode,output logic[386:0] r);
        reply_t b;
        begin start_request(mode);if(mode!=1 && mode!=2)begin take_job(b);send_done(b,0,PIXELS,0);end
            take_completion(0,OK,r);end
    endtask
    task automatic passed(input string name);
        begin cases=cases+1;$fdisplay(fd,"{\"event\":\"case\",\"name\":\"%s\"}",name);end
    endtask

    initial begin : scenarios
        reply_t b,scratch;command_t c;logic[386:0] r,previous,r2,r3;integer saved_count;
        if($test$plusargs("EXPECT_FATAL"))begin #1;$fatal(1,"fatal exit probe");end
        fd=$fopen("publish-events.jsonl","w");if(!fd)$fatal(1,"Event log open");
        cold();start_request(1);take_completion(1,NO_SOURCE,r);passed("no_source");
        seed_source();previous=0;
        for(integer mode=0;mode<6;mode=mode+1)begin
            if(previous!=0)close_ref(previous);
            normal_request(mode,r);previous=r;passed($sformatf("mode_%0d",mode));
            repeat(16)@(negedge core_clk);
        end
        // 完整引用中任意一个身份位错误，都不能闭合新对象。
        close_ref(previous^387'd1);saved_count=retired;repeat(16)@(negedge core_clk);
        if(retired!=saved_count)$fatal(1,"Wrong oldclosed retired active");passed("wrong_oldclosed");
        close_ref(previous);saved_count=retired;repeat(16)@(negedge core_clk);
        if(retired!=saved_count)$fatal(1,"Early active oldclosed retired before replacement");
        normal_request(1,r);repeat(20)@(negedge core_clk);
        if(retired!=saved_count+1)$fatal(1,"Early closed not retired after APPLY");passed("early_oldclosed");

        cold();seed_source();normal_request(1,r);normal_request(2,r2);normal_request(1,r3);
        if(root_retire_capacity)$fatal(1,"Retiring pool capacity not exhausted");
        start_request(1);take_completion(1,NO_SPACE,previous);passed("full_pool_no_job");
        close_ref(r);repeat(24)@(negedge core_clk);close_ref(r2);repeat(24)@(negedge core_clk);
        normal_request(1,previous);passed("late_close_slot_reuse");

        cold();seed_source();normal_request(1,r);retired_ready=0;close_ref(r);normal_request(2,r2);
        wait(retired_valid);repeat(8)@(negedge core_clk);
        start_request(1);wait(dut.applied_valid);repeat(8)@(negedge core_clk);
        if(completion_valid)$fatal(1,"Completion before held applied accepted");
        retired_ready=1;take_completion(0,OK,r3);passed("retired_event_and_applied_holding");

        cold();seed_source();saved_count=jobs;owner_accept_enable=0;start_request(3);wait(owner_cmd_valid);
        cancel_current();repeat(8)@(negedge core_clk);owner_accept_enable=1;
        take_completion(2,OK,r);if(jobs!=saved_count)$fatal(1,"Unexpected job after prestart cancel");passed("cancel_before_job");

        cold();seed_source();start_request(3);wait(job_valid);cancel_current();repeat(8)@(negedge core_clk);
        take_job(b);repeat(8)@(negedge core_clk);send_done(b,0,PIXELS,0);take_completion(2,OK,r);passed("cancel_held_job");
        cold();seed_source();start_request(3);take_job(b);cancel_current();repeat(8)@(negedge core_clk);
        if(completion_valid)$fatal(1,"Cancel guessed producer close");send_done(b,2,0,0);take_completion(2,OK,r);passed("cancel_wait_done");

        cold();seed_source();route_accept_enable=0;prepare_enable=0;vsync_enable=0;candidate_close_enable=0;
        start_request(1);wait(route_valid);cancel_current();repeat(8)@(negedge core_clk);route_accept_enable=1;
        wait(cancel_candidate);repeat(12)@(negedge core_clk);if(completion_valid)$fatal(1,"Route cancel guessed candidate close");
        candidate_close_enable=1;take_completion(2,OK,r);passed("cancel_held_route_requires_close");

        cold();seed_source();start_request(3);take_job(b);
        for(integer mismatch=1;mismatch<=3;mismatch=mismatch+1)begin
            send_done(b,0,PIXELS,mismatch);repeat(8)@(negedge core_clk);
            if(completion_valid || route_valid)$fatal(1,"Stale producer DONE ended job");
        end
        send_done(b,0,PIXELS,0);take_completion(0,OK,r);passed("wrong_result_scope_origin_done");
        cold();seed_source();start_request(6);take_completion(1,FIELD,r);passed("invalid_mode_field");
        start_request(1,1);take_completion(1,FIELD,r);passed("invalid_cj_field");
        start_request(1,0,1);take_completion(0,OK,r);passed("explicit_complete_source");
        start_request(1,0,2);take_completion(1,IDENTITY,r);passed("explicit_wrong_origin");
        c='0;c.op=ALLOC_SOURCE;c.origin[130:67]=64'h0000000800000014;
        source_transaction(c,scratch);fixture_source=scratch;
        start_request(1,0,1);take_completion(1,NOT_READY,r);passed("explicit_writing_source_no_read");
        c='0;c.op=SOURCE_END;c.flags=6;c.source_handle=scratch.source_handle;c.origin=scratch.origin;
        source_transaction(c,scratch);

        cold();seed_source();start_request(3);take_job(b);owner_accept_enable=0;
        send_done(b,0,PIXELS,0);wait(owner_cmd_valid && public_owner_command.op==RESULT_END);
        cancel_current();repeat(8)@(negedge core_clk);
        if(public_owner_command.flags!=7)$fatal(1,"Cancel rewrote held good END");
        owner_accept_enable=1;take_completion(2,OK,r);passed("cancel_held_good_end_safe_drop");
        cold();seed_source();start_request(3);take_job(b);owner_accept_enable=0;
        send_done(b,0,PIXELS,0);wait(owner_cmd_valid && public_owner_command.op==RESULT_END);
        @(negedge core_clk);halt=1;$fdisplay(fd,"{\"event\":\"halt\",\"cycle\":%0d}",cycle);
        repeat(8)@(negedge core_clk);
        if(public_owner_command.flags!=7)$fatal(1,"Halt rewrote held good END");
        owner_accept_enable=1;take_completion(1,QUARANTINED,r);passed("halt_held_good_end_safe_drop");
        cold();seed_source();start_request(1);wait(route_reply_valid);
        do @(posedge core_clk);while(!route_reply_ready);
        cancel_current();take_completion(0,OK,r);passed("late_cancel_after_display_commit");
        cold();seed_source();start_request(3);take_job(b);send_done(b,1,0,0);take_completion(1,OK,r);passed("safe_producer_error");
        cold();seed_source();start_request(3);take_job(b);send_done(b,0,PIXELS-1,0);take_completion(1,OK,r);passed("bad_normal_count");
        cold();seed_source();sequence_exhausted=1;start_request(1);take_completion(1,EXHAUSTED,r);passed("sequence_exhausted_no_wrap");
        cold();seed_source();sequence_value=0;start_request(1);take_completion(1,FIELD,r);
        if(!quarantined)$fatal(1,"Invalid zero sequence did not quarantine");passed("sequence_zero_safe_drop");

        cold();seed_source();start_request(3);take_job(b);send_done(b,3,0,0);wait(owner_quarantined);
        repeat(12)@(negedge core_clk);if(completion_valid)$fatal(1,"UNKNOWN returned safe completion");passed("unknown_requires_common_cold");
        cold();seed_source();start_request(3);wait(job_valid);halt=1;
        $fdisplay(fd,"{\"event\":\"halt\",\"cycle\":%0d}",cycle);
        repeat(8)@(negedge core_clk);if(!job_valid)$fatal(1,"Halt retracted held job");
        take_job(b);wait(owner_quarantined);repeat(12)@(negedge core_clk);
        if(completion_valid)$fatal(1,"Halted unknown producer safely completed");passed("halt_held_job");
        cold();seed_source();start_request(3);take_job(b);send_done(b,1,0,0);wait(completion_valid);
        halt=1;$fdisplay(fd,"{\"event\":\"halt\",\"cycle\":%0d}",cycle);
        repeat(8)@(negedge core_clk);take_completion(1,OK,r);passed("late_halt_held_safe_completion");

        // Result已经复制给仲裁后，后来Source请求不能替换已公开owner包。
        cold();seed_source();owner_accept_enable=0;start_request(3);wait(owner_cmd_valid);
        c='0;c.op=ALLOC_SOURCE;c.origin[130:67]=64'h0000000800000012;
        fork
            begin source_transaction(c,scratch);end
            begin repeat(8)@(negedge core_clk);owner_accept_enable=1;take_job(b);send_done(b,0,PIXELS,0);take_completion(0,OK,r);end
        join
        c='0;c.op=SOURCE_END;c.flags=6;c.source_handle=scratch.source_handle;c.origin=scratch.origin;
        source_transaction(c,scratch);passed("owner_held_result_source_competition");
        // policy客户端走独占窗口，仅检查控制端；完整冻结路由在父顶层另行闭合。
        pause_new_requests=1;@(negedge core_clk);c='0;c.op=BARRIER;policy_command=c;policy_cmd_valid=1;
        do @(posedge core_clk);while(!policy_cmd_ready);
        @(negedge core_clk);policy_cmd_valid=0;wait(policy_reply_valid);repeat(8)@(negedge core_clk);
        if(policy_reply[937:934]!=OK)$fatal(1,"Policy BARRIER refused");
        policy_reply_ready=1;@(posedge core_clk);@(negedge core_clk);policy_reply_ready=0;passed("policy_window_reply_holding");

        repeat(20)@(negedge core_clk);
        if(owner_commands!=owner_replies)$fatal(1,"Unclosed owner transaction at finish");
        $fclose(fd);metric_fd=$fopen("publish-metrics.json","w");
        $fdisplay(metric_fd,"{\"finished\":true,\"width\":%0d,\"height\":%0d,\"cases\":%0d,\"requests\":%0d,\"jobs\":%0d,\"producer_done\":%0d,\"completions\":%0d,\"retired\":%0d,\"applied\":%0d,\"actor_cancels\":%0d,\"route_cancels\":%0d,\"owner_commands\":%0d,\"owner_replies\":%0d,\"cycles\":%0d,\"endpoint_fixture_only\":true}",TEST_W,TEST_H,cases,requests,jobs,dones,completions,retired,applied,actor_cancels,route_cancels,owner_commands,owner_replies,cycle);
        $fclose(metric_fd);finished=1;$finish;
    end
    initial begin repeat(250000)@(posedge core_clk);$fatal(1,"Protocol test watchdog; preserve original attempt");end
endmodule
