// OBS-B/R：真实J/K/reset组件＋声明typed fixture；不是算法或FE的替代证据。
module tb_r2_observer_supervisor;
    localparam integer W=6,H=5,P=15;
    logic clk=0;always #5 clk=~clk;
    logic manual_rst=1,key1_n=0;wire key_core_rst;wire rst=manual_rst||key_core_rst;
    reset_sync reset_adapter(.clk(clk),.key1_n(key1_n),.core_rst(key_core_rst));
    logic cj_ready=0,class_valid=0,grad_valid=0,status_valid=0;
    logic source_input_fire=0,source_last_fire=0;
    logic [124:0] class_payload=0;logic [184:0] grad_payload=0;logic [591:0] status_payload=0;
    wire cj_valid,job_start,class_ready,grad_ready,status_ready;
    wire [141:0] cj;wire [1:0] pattern;wire fault,source_stop,cancel;
    wire terminal_fixture_match,terminal_complete_ok,terminal_done,last_result_valid,last_fixture_match,last_complete_ok;
    wire [20:0] observed_class_pairs,observed_grad_pairs,observed_strong,observed_weak;
    wire observed_class_eof,observed_grad_eof,record_protocol_ok,observer_fault_sticky;
    wire [591:0] last_cs;wire [31:0] last_crc;
    wire status_fire=status_valid&&status_ready;
    r2_job_controller #(.W(W),.H(H)) controller (
        .clk(clk),.rst(rst),.cj_valid(cj_valid),.cj_ready(cj_ready),.cj(cj),
        .source_input_fire(source_input_fire),.source_last_fire(source_last_fire),
        .status_valid(status_valid),.status_payload(status_payload),.status_fire(status_fire),
        .observed_class_pairs(observed_class_pairs),.observed_grad_pairs(observed_grad_pairs),
        .observed_strong(observed_strong),.observed_weak(observed_weak),
        .observed_class_eof(observed_class_eof),.observed_grad_eof(observed_grad_eof),.record_protocol_ok(record_protocol_ok),
        .observer_fault_sticky(observer_fault_sticky),.terminal_done(terminal_done),
        .last_fixture_match(last_fixture_match),.last_complete_ok(last_complete_ok),.last_crc(last_crc),
        .job_start(job_start),.pattern(pattern),.fault(fault),.source_stop(source_stop),.cancel(cancel),
        .terminal_fixture_match(terminal_fixture_match),.terminal_complete_ok(terminal_complete_ok)
    );
    r2_result_crc_observer #(.W(W),.H(H)) observer (
        .clk(clk),.rst(rst),.job_start(job_start),.cj(cj),.retain_grad(cj[141]),
        .class_valid(class_valid),.class_ready(class_ready),.class_payload(class_payload),
        .grad_valid(grad_valid),.grad_ready(grad_ready),.grad_payload(grad_payload),
        .status_valid(status_valid),.status_ready(status_ready),.status_payload(status_payload),
        .terminal_fixture_match(terminal_fixture_match),.terminal_complete_ok(terminal_complete_ok),
        .observed_class_pairs(observed_class_pairs),.observed_grad_pairs(observed_grad_pairs),
        .observed_strong(observed_strong),.observed_weak(observed_weak),
        .observed_class_eof(observed_class_eof),.observed_grad_eof(observed_grad_eof),.record_protocol_ok(record_protocol_ok),
        .observer_fault_sticky(observer_fault_sticky),.terminal_done(terminal_done),.last_result_valid(last_result_valid),
        .last_fixture_match(last_fixture_match),.last_complete_ok(last_complete_ok),.last_cs(last_cs),.last_crc(last_crc)
    );
    logic [141:0] golden_jobs[0:4],locked_job;
    logic [124:0] class_words[0:15];logic [184:0] grad_words[0:14];
    logic [31:0] job_k;
    logic finished=0,active_job=0,old_c_hold=0,old_g_hold=0,old_s_hold=0;
    logic [124:0] held_c;logic [184:0] held_g;logic [591:0] held_s,captured_cs,previous_last_cs;
    logic [31:0] previous_last_crc;logic previous_last_valid;
    logic captured_candidate_fixture,captured_candidate_complete,owner_drain,source_last_seen;
    logic class_eof,grad_eof;
    integer cycles=0,scenario,result_fd,record_fd,completed=0,phase_hits=0,reset_chunk=-1,reset_jobs=0;
    integer c_count=0,g_count=0,strong_count=0,weak_count=0,source_count=0,records=0;
    integer status_holds=0,fairness_checks=0,expected_rr=0,last_capture=-20,min_interval=16384;
    integer hold_checks=0,processed_chunks=0;
    string case_id,family,input_path,vector_dir,result_path,output_dir,label,records_relative;

    task automatic tick;
        @(posedge clk);#1;@(negedge clk);
    endtask
    task automatic quiet(input integer n);
        repeat(n) tick();
    endtask
    task automatic note_record(input logic [607:0] record);
        integer interval;
        interval=cycles-last_capture;
        if(interval<20) $fatal(1,"K captured on old final CRC chunk");
        if(records!=0&&interval<min_interval) min_interval=interval;
        last_capture=cycles;records=records+1;$fwrite(record_fd,"%0152h\n",record);
    endtask
    always @(posedge clk) begin : independent_actual_ledger
        cycles=cycles+1;
        if(cycles>32768+128*3+5*(48*(2*P+1)+16*P)) $fatal(1,"observer finite timeout");
        if(rst) begin
            if(class_ready||grad_ready||status_ready||cj_valid||job_start) $fatal(1,"rst allowed typed/job fire");
            old_c_hold=0;old_g_hold=0;old_s_hold=0;
        end else if(active_job) begin
            if(old_c_hold&&(!class_valid||class_payload!==held_c)) $fatal(1,"typed CLASS held changed");
            if(old_g_hold&&(!grad_valid||grad_payload!==held_g)) $fatal(1,"typed GRAD held changed");
            if(old_s_hold&&(!status_valid||status_payload!==held_s)) $fatal(1,"typed CS held changed");
            hold_checks=hold_checks+old_c_hold+old_g_hold+old_s_hold;
            old_c_hold=class_valid&&!class_ready;held_c=class_payload;
            old_g_hold=grad_valid&&!grad_ready;held_g=grad_payload;
            old_s_hold=status_valid&&!status_ready;held_s=status_payload;
            if(observer.busy) begin
                if(class_ready||grad_ready||status_ready) $fatal(1,"busy exposed capture ready");
                processed_chunks=processed_chunks+1;
                if(last_result_valid!==previous_last_valid||last_cs!==previous_last_cs||last_crc!==previous_last_crc)
                    $fatal(1,"last snapshot changed before final status chunk");
            end
            if(source_input_fire) source_count=source_count+1;
            if(source_last_fire) source_last_seen=1;
            if(status_valid&&!status_ready) status_holds=status_holds+1;
            if(class_valid&&grad_valid&&(class_ready||grad_ready)) begin
                if(class_ready!==!expected_rr||grad_ready!==1'(expected_rr)) $fatal(1,"round-robin fairness mismatch");
                fairness_checks=fairness_checks+1;
            end
            if(class_valid&&class_ready) begin
                if(class_payload!==class_words[c_count]) $fatal(1,"actual CLASS record differs from complete fixture");
                c_count=c_count+1;expected_rr=1;
                if(class_payload[124]) class_eof=1;
                for(integer lane=0;lane<2;lane=lane+1) begin
                    if(class_payload[lane*2 +: 2]==2) strong_count=strong_count+1;
                    if(class_payload[lane*2 +: 2]==1) weak_count=weak_count+1;
                end
                note_record({481'd0,class_payload,2'd0});
            end
            if(grad_valid&&grad_ready) begin
                if(grad_payload!==grad_words[g_count]) $fatal(1,"actual GRAD record differs from complete fixture");
                g_count=g_count+1;expected_rr=0;if(grad_payload[184]) grad_eof=1;
                note_record({421'd0,grad_payload,2'd1});
            end
            if(status_fire) begin
                if(class_ready||grad_ready) $fatal(1,"CS did not have priority");
                // CS终结本job；同拍未接纳typed候选随后允许随上下文撤销。
                old_c_hold=0;old_g_hold=0;
                captured_cs=status_payload;captured_candidate_fixture=terminal_fixture_match;
                captured_candidate_complete=terminal_complete_ok;owner_drain=controller.state==2;
                note_record({14'd0,status_payload,2'd2});
            end
        end
    end
    task automatic start_fixture(input integer golden_index,input string prefix);
        if(!cj_valid) $fatal(1,"J not at START fixture boundary");
        if(cj!==golden_jobs[golden_index]) $fatal(1,"J fixture identity/parameters mismatch");
        label=prefix;job_k=cj[63:32];locked_job=cj;
        $readmemh({vector_dir,"/",prefix,"/class.hex"},class_words,0,
            family=="B"&&scenario==7&&prefix=="primary"?15:14);
        if(locked_job[141]) $readmemh({vector_dir,"/",prefix,"/grad.hex"},grad_words);
        records_relative={prefix,"-records.hex"};record_fd=$fopen({output_dir,"/",records_relative},"wb");
        if(record_fd==0) $fatal(1,"observer record open");
        c_count=0;g_count=0;strong_count=0;weak_count=0;source_count=0;source_last_seen=0;
        class_eof=0;grad_eof=0;records=0;status_holds=0;fairness_checks=0;expected_rr=0;
        last_capture=-20;min_interval=16384;processed_chunks=0;
        old_c_hold=0;old_g_hold=0;old_s_hold=0;captured_cs=0;
        previous_last_valid=last_result_valid;previous_last_cs=last_cs;previous_last_crc=last_crc;
        active_job=1;cj_ready=1;tick();cj_ready=0;
        if(last_result_valid!==previous_last_valid||last_cs!==previous_last_cs||last_crc!==previous_last_crc)
            $fatal(1,"job_start half-wrote previous complete snapshot");
    endtask
    task automatic feed_source(input integer n);
        for(integer p=0;p<n;p=p+1) begin
            source_input_fire=1;source_last_fire=(n==P&&p==P-1);tick();
        end
        source_input_fire=0;source_last_fire=0;
    endtask
    task automatic feed_both;
        while(c_count<P||(locked_job[141]&&g_count<P)) begin
            class_valid=c_count<P;
            if(class_valid) class_payload=class_words[c_count];
            grad_valid=locked_job[141]&&g_count<P;
            if(grad_valid) grad_payload=grad_words[g_count];
            tick();
        end
        class_valid=0;grad_valid=0;
    endtask
    task automatic feed_one(input logic grad_branch,input integer n);
        while((grad_branch?g_count:c_count)<n) begin
            if(grad_branch) begin grad_valid=1;grad_payload=grad_words[g_count];end
            else begin class_valid=1;class_payload=class_words[c_count];end
            tick();
        end
        class_valid=0;grad_valid=0;
    endtask
    function automatic [591:0] fixture_terminal(input integer kind);
        logic [141:0] raw_cj;logic [162:0] raw_fs;
        logic [167:0] packed_counts;logic [7:0] eof_bits;
        logic [4:0] reason;logic [31:0] mask;logic [3:0] facts;logic [27:0] location;
        begin
            raw_cj=locked_job;reason=0;mask=0;facts=7;location=28'd30;
            packed_counts=0;
            for(integer i=0;i<6;i=i+1) packed_counts[i*21 +: 21]=21'(P);
            packed_counts[126 +: 21]=21'(c_count);packed_counts[147 +: 21]=21'(g_count);
            eof_bits={grad_eof,class_eof,6'h3f};
            raw_fs={22'd0,21'(P),21'(P),locked_job[95:0],3'd0};
            if(kind==1) begin reason=1;mask=2;facts=15;raw_fs[2:0]=1;end
            if(kind==2) begin
                reason=5;mask=32;location={11'd2,11'd2,1'b0,4'd1,1'b1};
                packed_counts=0;packed_counts[20:0]=8;eof_bits=0;
                raw_fs={11'd2,11'd2,21'd0,21'd8,locked_job[95:0],3'd2};
            end
            if(kind==3) raw_cj[32]=~raw_cj[32];
            if(kind==4) packed_counts[42 +: 21]=P-1;
            fixture_terminal={raw_fs,21'(weak_count),21'(strong_count),eof_bits,packed_counts,
                location,facts,mask,reason,raw_cj};
        end
    endfunction
    task automatic accept_terminal(input integer kind,input logic coexist,input logic exact_hold);
        if(exact_hold) begin
            while(!observer.busy||observer.chunk_index!=11) tick();
        end
        status_payload=fixture_terminal(kind);status_valid=1;
        if(coexist) begin class_valid=1;class_payload=class_words[14];end
        #1; // ready包含valid组合仲裁；先让新候选稳定，再判断接纳边沿。
        while(!status_ready) tick();
        tick();status_valid=0;class_valid=0;grad_valid=0;
        // 消费后上游CS可立即变化；K的terminalCS/flags仍须保持完整原捕获。
        status_payload=0;
    endtask
    task automatic save_job;
        if(!last_result_valid||last_cs!==captured_cs||observed_class_pairs!=c_count||observed_grad_pairs!=g_count
            ||observed_strong!=strong_count||observed_weak!=weak_count) $fatal(1,"component last/ledger mismatch");
        $fwrite(result_fd,"{\"k\":%0d,\"records_path\":\"%s\",\"class_count\":%0d,\"grad_count\":%0d,\"strong\":%0d,\"weak\":%0d,\"source_count\":%0d,\"source_last\":%s,\"owner_drain\":%s,\"cs_hex\":\"%0148h\",\"last_cs_hex\":\"%0148h\",\"crc_hex\":\"%08h\",\"candidate_fixture_match\":%s,\"candidate_complete_ok\":%s,\"fixture_match\":%s,\"complete_ok\":%s,\"record_protocol_ok\":%s,\"status_hold_cycles\":%0d,\"fairness_checks\":%0d,\"min_capture_interval\":%0d,\"processed_chunks\":%0d}",
            job_k,records_relative,c_count,g_count,strong_count,weak_count,source_count,
            source_last_seen?"true":"false",owner_drain?"true":"false",captured_cs,last_cs,last_crc,
            captured_candidate_fixture?"true":"false",captured_candidate_complete?"true":"false",
            last_fixture_match?"true":"false",last_complete_ok?"true":"false",record_protocol_ok?"true":"false",
            status_holds,fairness_checks,min_interval,processed_chunks);
        completed=completed+1;active_job=0;$fclose(record_fd);
    endtask
    task automatic finish_fixture;
        while(!terminal_done) tick();
        save_job();tick(); // J在此后沿才依据旧done推进，不与STATUS capture混成一拍。
    endtask
    task automatic reset_and_check(input logic through_key);
        class_valid=0;grad_valid=0;status_valid=0;source_input_fire=0;source_last_fire=0;
        active_job=0;$fclose(record_fd);
        if(through_key) begin key1_n=0;quiet(4);key1_n=1;end
        else begin manual_rst=1;quiet(2);manual_rst=0;end
        if(through_key) begin
            @(posedge clk);#1;if(!key_core_rst) $fatal(1,"KEY synchronizer released before stage2");
            @(negedge clk);@(posedge clk);#1;if(key_core_rst) $fatal(1,"KEY second release edge missing");
            @(negedge clk);
        end
        quiet(1);
        if(last_result_valid||terminal_done||observer.busy||observer.active||observer_fault_sticky
            ||observed_class_pairs!=0||observed_grad_pairs!=0||controller.k!=0||!cj_valid)
            $fatal(1,"reset did not isolate old record/job/last");
    endtask
    initial begin
        if($test$plusargs("FATAL_PROBE")) $fatal(1,"P-FATAL observer intentional failure");
        if(!$value$plusargs("CASE=%s",case_id)||!$value$plusargs("FAMILY=%s",family)
            ||!$value$plusargs("SCENARIO=%d",scenario)||!$value$plusargs("IN=%s",input_path)
            ||!$value$plusargs("VECTOR_DIR=%s",vector_dir)||!$value$plusargs("RESULT=%s",result_path)
            ||!$value$plusargs("OUTPUT_DIR=%s",output_dir)) $fatal(1,"observer args");
        $readmemh(input_path,golden_jobs);@(negedge clk);quiet(4);key1_n=1;manual_rst=0;quiet(3);
        result_fd=$fopen(result_path,"w");if(result_fd==0) $fatal(1,"observer result open");
        $fwrite(result_fd,"{\"schema_version\":1,\"case_id\":\"%s\",\"suite\":\"r2-observer-v1\",\"width\":6,\"height\":5,\"warmup_jobs\":[",case_id);
        for(integer k=0;k<3;k=k+1) begin
            if(k!=0) $fwrite(result_fd,",");
            start_fixture(k,$sformatf("warmup%0d",k));feed_source(P);feed_both();accept_terminal(0,0,0);finish_fixture();
        end
        $fwrite(result_fd,"],\"primary_job\":");
        if(family=="R"&&scenario==24) begin
            // 唯一获批的J入口初始化fixture：START、CJ未接纳；不force业务状态/终态。
            controller.k=32'hffffffff;
            #1;start_fixture(4,"primary");
        end else start_fixture(3,"primary");
        if(family=="B") begin
            feed_source(scenario==13?8:P);
            case(scenario)
                1,4,5,6,7:begin
                    feed_one(0,scenario==7?16:5);
                    if(!observer_fault_sticky) $fatal(1,"CLASS declaration did not set sticky");
                    quiet(1);if(!cancel) $fatal(1,"J did not cancel while retaining CS eligibility");
                    accept_terminal(1,0,0);
                end
                2,3:begin
                    feed_one(1,5);if(!observer_fault_sticky) $fatal(1,"GRAD declaration did not set sticky");
                    quiet(1);if(!cancel) $fatal(1,"J badGRAD failed to request cancel");accept_terminal(1,0,0);
                end
                8:begin feed_both();accept_terminal(3,0,0);end
                9:begin feed_both();accept_terminal(4,0,0);end
                10:begin feed_both();accept_terminal(0,1,0);end
                11,12:begin feed_both();accept_terminal(0,0,0);end
                13:accept_terminal(2,0,0);
                14:begin feed_both();accept_terminal(0,0,1);end
                default:$fatal(1,"OBS-B scenario");
            endcase
            phase_hits=1;finish_fixture();
            if(scenario<=10||scenario==13) begin if(controller.state!=4) $fatal(1,"J did not enter ERROR after real terminal CRC");end
            else if(!cj_valid) $fatal(1,"normal fixture did not permit next CJ");
            // 新历史从k0恢复，不能从ERROR硬插一条新CJ。
            record_fd=0;manual_rst=1;quiet(2);manual_rst=0;quiet(1);
        end else begin
            feed_source(scenario==24?8:P);
            if(scenario==24) begin
                accept_terminal(2,0,0);finish_fixture();quiet(8);
                if(controller.state!=5||cj_valid||controller.k!=32'hffffffff) $fatal(1,"FFFFFFFF wrapped or failed to exhaust");
                phase_hits=1;manual_rst=1;quiet(2);manual_rst=0;quiet(1);
            end else begin
                $fwrite(result_fd,"null");
                if(scenario==1) begin
                    class_valid=1;class_payload=class_words[0];manual_rst=1;tick();
                    if(c_count!=0) $fatal(1,"capture reset accepted old data");manual_rst=0;
                end else if(scenario<=20) begin
                    feed_one(0,1);
                    while(!observer.busy||observer.chunk_index!=scenario-2) tick();
                    reset_chunk=observer.chunk_index;manual_rst=1;
                end else if(scenario==21) begin
                    feed_both();while(!observer.busy||observer.chunk_index!=11) tick();
                    status_payload=fixture_terminal(0);status_valid=1;
                    if(status_ready) $fatal(1,"CSheld reset phase not busy");quiet(1);manual_rst=1;
                end else if(scenario==22) begin
                    feed_both();accept_terminal(0,0,0);while(!terminal_done) tick();
                    if(!last_result_valid) $fatal(1,"terminal_done reset phase missing");manual_rst=1;
                end else if(scenario==23) begin feed_one(0,1);end
                phase_hits=1;reset_jobs=1;reset_and_check(scenario==23);
            end
        end
        $fwrite(result_fd,",\"recovery_jobs\":[");
        start_fixture(0,"recovery");feed_source(P);feed_both();accept_terminal(0,0,0);finish_fixture();
        if(!last_fixture_match||!last_complete_ok||observer_fault_sticky) $fatal(1,"complete recovery fixture failed");
        $fwrite(result_fd,"],\"status\":\"PASS\",\"finished\":true,\"numeric_errors\":0,\"protocol_errors\":0,\"compared_pairs\":%0d,\"completed_jobs\":%0d,\"reset_aborted_jobs\":%0d,\"reset_chunk\":%0d,\"required_event_hits\":%0d,\"hold_checks\":%0d,\"cycles\":%0d}\n",
            completed,completed,reset_jobs,reset_chunk,phase_hits,hold_checks,cycles);
        $fclose(result_fd);finished=1;$finish;
    end
endmodule
