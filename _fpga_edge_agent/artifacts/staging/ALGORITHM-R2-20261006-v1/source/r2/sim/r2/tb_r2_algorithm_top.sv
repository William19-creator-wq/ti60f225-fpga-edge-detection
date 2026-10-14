// TOP-S001：真J/SRC/C0/FE/G/S/D/FK/N/K/reset/LED；128job及k5忙时KEY复位。
module tb_r2_algorithm_top #(parameter integer HD_MODE=0);
    localparam integer W=HD_MODE ? 1920 : 6,H=HD_MODE ? 1080 : 5,P=(W/2)*H;
    logic clk_25m=0;always #20 clk_25m=~clk_25m;
    logic key1_n=0;wire led0,led1;
    // 生产分支不覆盖参数；小图分支保留128job及忙时复位覆盖。
    generate if(HD_MODE) begin : chosen
        r2_algorithm_top dut (.*);
    end else begin : chosen
        r2_algorithm_top #(.W(6),.H(5)) dut (.*);
    end endgenerate
    logic [141:0] jobs[0:127];
    logic finished=0,active_job=0,warmup=!HD_MODE,reset_requested=0,got_fs=0,got_cs=0;
    logic [162:0] actual_fs;logic [591:0] captured_cs;
    logic [7:0] eof_ledger;logic owner_drain;
    integer ledger[0:7],compares[0:7],gold_fd[0:8];
    integer job_k=0,completed=0,warmup_completed=0,cycles=0,record_fd,result_fd;
    integer strong_count=0,weak_count=0,nw_count=0,record_class=0,record_grad=0,record_total=0;
    integer last_capture_cycle=-20,reset_chunk=-1,key_low_cycles=0;
    // 直接观察原语使能；累计量包含warmup/复位前缀，job差值单独记录。
    integer ram_reads=0,ram_writes=0,ram_checks=0,hold_checks=0;
    integer job_ram_reads=0,job_ram_writes=0,job_ram_checks=0,job_hold_checks=0;
    integer start_events=0,fs_fires=0,cs_fires=0,terminal_events=0,stop_events=0,reset_entries=0;
    logic was_reset=0,was_stopped=0,old_fp_hold=0,old_c_hold=0,old_g_hold=0,old_s_hold=0;
    logic [73:0] held_fp;logic [124:0] held_c;logic [184:0] held_g;logic [591:0] held_s;
    string case_id,input_path,vector_dir,result_path,output_dir,record_relative,job_digits;
    function automatic [120:0] side(input logic [24:0] c,input logic [95:0] identity);
        side={c[24:22],identity,c[21:0]};
    endfunction
    task automatic check_ram(input logic rd,wr,input logic [9:0] ra,wa,input integer planes,input logic private_ram);
        ram_checks=ram_checks+1;
        if(rd) begin ram_reads=ram_reads+planes;if(ra>=W/2) $fatal(1,"TOP RAM read range");end
        if(wr) begin ram_writes=ram_writes+planes;if(wa>=W/2) $fatal(1,"TOP RAM write range");end
        if(rd&&wr&&ra==wa) $fatal(1,"TOP RAM same-address collision");
        if(private_ram&&chosen.dut.stream.data_flush&&(rd||wr)) $fatal(1,"TOP ABORT RAM enabled");
    endtask
    task automatic save_observation_totals;
        $fwrite(result_fd,"\"ram_reads\":%0d,\"ram_writes\":%0d,\"ram_checks\":%0d,\"ram_range_errors\":0,\"ram_collision_errors\":0,\"hold_checks\":%0d,\"start_events\":%0d,\"fs_fires\":%0d,\"cs_fires\":%0d,\"terminal_events\":%0d,\"source_stop_events\":%0d,\"reset_entries\":%0d,",
            ram_reads,ram_writes,ram_checks,hold_checks,start_events,fs_fires,cs_fires,terminal_events,stop_events,reset_entries);
    endtask
    task automatic compare_word(input integer stage,input logic [591:0] actual);
        logic [591:0] expected;
        if($fscanf(gold_fd[stage],"%h\n",expected)!=1) $fatal(1,"TOP golden EOF stage=%0d",stage);
        if(actual!==expected) $fatal(1,"TOP numeric/meta mismatch k=%0d stage=%0d pair=%0d",job_k,stage,compares[stage]);
        compares[stage]=compares[stage]+1;
    endtask
    task automatic open_job;
        string names[0:8];
        job_k=chosen.dut.cj[63:32];
        job_digits=$sformatf("%0d%0d%0d",job_k/100,(job_k/10)%10,job_k%10);
        if(job_k>127||chosen.dut.cj!==jobs[job_k]) $fatal(1,"true J proposed wrong CJ");
        names[0]="fp";names[1]="msrc";names[2]="g8";names[3]="sobel";names[4]="direction";
        names[5]="ninput";names[6]="class";names[7]="grad";names[8]="nwindow";
        for(integer i=0;i<9;i=i+1) begin
            gold_fd[i]=0;
            if(i!=7||chosen.dut.cj[141]) begin
                gold_fd[i]=$fopen($sformatf("%s/job%s/%s.hex",vector_dir,job_digits,names[i]),"r");
                if(gold_fd[i]==0) $fatal(1,"TOP golden open");
            end
        end
        if(warmup) record_relative=$sformatf("warmup-job%s-records.hex",job_digits);
        else record_relative=$sformatf("main-job%s-records.hex",job_digits);
        record_fd=$fopen({output_dir,"/",record_relative},"wb");if(record_fd==0) $fatal(1,"TOP record open");
        for(integer i=0;i<8;i=i+1) begin ledger[i]=0;compares[i]=0;end
        eof_ledger=0;strong_count=0;weak_count=0;nw_count=0;record_class=0;record_grad=0;record_total=0;
        got_fs=0;got_cs=0;actual_fs=0;captured_cs=0;owner_drain=0;active_job=1;last_capture_cycle=-20;
        job_ram_reads=ram_reads;job_ram_writes=ram_writes;job_ram_checks=ram_checks;job_hold_checks=hold_checks;
    endtask
    task automatic close_job;
        for(integer i=0;i<9;i=i+1) if(gold_fd[i]!=0) $fclose(gold_fd[i]);
        $fclose(record_fd);active_job=0;
    endtask
    task automatic capture_record(input logic [607:0] record);
        if(cycles-last_capture_cycle<20) $fatal(1,"K capture interval shorter than 20");
        last_capture_cycle=cycles;record_total=record_total+1;
        $fwrite(record_fd,"%0152h\n",record);
    endtask
    task automatic save_terminal;
        if(!got_cs||!got_fs||!chosen.dut.last_result_valid||!chosen.dut.last_fixture_match||chosen.dut.observer_fault_sticky)
            $fatal(1,"true TOP terminal incomplete/ERROR");
        if(chosen.dut.last_cs!==captured_cs||chosen.dut.last_complete_ok!==!job_k[6]||led0!==!job_k[6]) $fatal(1,"TOP last/LED flags");
        for(integer i=0;i<8;i=i+1) if(ledger[i]!=compares[i]) $fatal(1,"uncompared TOP prefix");
        if(record_total!=ledger[6]+ledger[7]+1||record_class!=ledger[6]||record_grad!=ledger[7]) $fatal(1,"TOP record accounting");
        if(warmup) begin if(warmup_completed!=0) $fwrite(result_fd,",");end
        else if(completed!=0) $fwrite(result_fd,",");
        $fwrite(result_fd,"{\"k\":%0d,\"accepted_counts\":[",job_k);
        for(integer i=0;i<8;i=i+1) $fwrite(result_fd,"%s%0d",i==0?"":",",ledger[i]);
        $fwrite(result_fd,"],\"compared_counts\":[");
        for(integer i=0;i<8;i=i+1) $fwrite(result_fd,"%s%0d",i==0?"":",",compares[i]);
        $fwrite(result_fd,"],\"eof\":%0d,\"strong\":%0d,\"weak\":%0d,\"nwindow_compared\":%0d,\"record_class\":%0d,\"record_grad\":%0d,\"records_path\":\"%s\",\"fs_hex\":\"%041h\",\"cs_hex\":\"%0148h\",\"last_cs_hex\":\"%0148h\",\"crc_hex\":\"%08h\",\"fixture_match\":true,\"complete_ok\":%s,\"led0\":%s,\"record_protocol_ok\":%s,\"owner_drain\":%s,",
            eof_ledger,strong_count,weak_count,nw_count,record_class,record_grad,record_relative,
            actual_fs,captured_cs,chosen.dut.last_cs,chosen.dut.last_crc,chosen.dut.last_complete_ok?"true":"false",led0?"true":"false",
            chosen.dut.record_protocol_ok?"true":"false",owner_drain?"true":"false");
        $fwrite(result_fd,"\"ram_reads\":%0d,\"ram_writes\":%0d,\"ram_checks\":%0d,\"hold_checks\":%0d}",
            ram_reads-job_ram_reads,ram_writes-job_ram_writes,ram_checks-job_ram_checks,hold_checks-job_hold_checks);
        if(warmup) warmup_completed=warmup_completed+1;else completed=completed+1;
        close_job();
    endtask
    always @(posedge clk_25m) begin
        cycles=cycles+1;
        if(cycles>(HD_MODE ? 32768+128*(W/2)+48*(2*(P+1)+1)+16*P
            : 32768+128*3+128*(48*(2*15+1)+16*15)+7*(48*(2*15+1)+16*15)))
            $fatal(1,"TOP finite timeout");
        if(chosen.dut.rst) begin
            if(!was_reset) reset_entries=reset_entries+1;
            was_reset=1;was_stopped=0;old_fp_hold=0;old_c_hold=0;old_g_hold=0;old_s_hold=0;
            if(chosen.dut.cj_valid||chosen.dut.in_ready||chosen.dut.class_ready||chosen.dut.grad_ready||chosen.dut.status_ready||chosen.dut.terminal_done)
                $fatal(1,"TOP reset had fire");
        end else begin
            was_reset=0;
            if(chosen.dut.source_stop&&!was_stopped) stop_events=stop_events+1;
            was_stopped=chosen.dut.source_stop;
            if(chosen.dut.job_start) start_events=start_events+1;
            if(chosen.dut.stream.fs_valid&&chosen.dut.stream.fs_ready) fs_fires=fs_fires+1;
            if(chosen.dut.status_valid&&chosen.dut.status_ready) cs_fires=cs_fires+1;
            if(chosen.dut.terminal_done) terminal_events=terminal_events+1;
            if(old_fp_hold&&!chosen.dut.source_stop&&!chosen.dut.cancel&&!chosen.dut.stream.data_flush
                &&(!chosen.dut.in_valid||chosen.dut.in_fp!==held_fp)) $fatal(1,"TOP FP hold");
            if(old_c_hold&&!chosen.dut.stream.data_flush&&(!chosen.dut.class_valid||chosen.dut.class_payload!==held_c)) $fatal(1,"TOP CLASS hold");
            if(old_g_hold&&!chosen.dut.stream.data_flush&&(!chosen.dut.grad_valid||chosen.dut.grad_payload!==held_g)) $fatal(1,"TOP GRAD hold");
            if(old_s_hold&&(!chosen.dut.status_valid||chosen.dut.status_payload!==held_s)) $fatal(1,"TOP CS hold");
            hold_checks=hold_checks+old_fp_hold+old_c_hold+old_g_hold+old_s_hold;
            // 停源沿已经取消候选；J次沿离开owned时不能恢复其保持义务。
            old_fp_hold=chosen.dut.in_valid&&!chosen.dut.in_ready&&!chosen.dut.source_stop
                &&!chosen.dut.cancel&&!chosen.dut.stream.data_flush;held_fp=chosen.dut.in_fp;
            old_c_hold=chosen.dut.class_valid&&!chosen.dut.class_ready;held_c=chosen.dut.class_payload;
            old_g_hold=chosen.dut.grad_valid&&!chosen.dut.grad_ready;held_g=chosen.dut.grad_payload;
            old_s_hold=chosen.dut.status_valid&&!chosen.dut.status_ready;held_s=chosen.dut.status_payload;
            if(chosen.dut.job_start) open_job();
            if(active_job) begin
                for(integer i=0;i<8;i=i+1) if(chosen.dut.stream.event_fire[i]) begin
                    ledger[i]=ledger[i]+1;if(chosen.dut.stream.event_metadata[i*121+120]) eof_ledger[i]=1;
                end
                if(chosen.dut.stream.event_fire[0]) compare_word(0,{518'd0,chosen.dut.in_fp});
                if(chosen.dut.stream.event_fire[1]) compare_word(1,{455'd0,side(chosen.dut.stream.m_coordinate,chosen.dut.stream.m_ids),chosen.dut.stream.m_pair});
                if(chosen.dut.stream.event_fire[2]) compare_word(2,{455'd0,chosen.dut.stream.g_metadata,chosen.dut.stream.g_pair});
                if(chosen.dut.stream.event_fire[3]) compare_word(3,{405'd0,side(chosen.dut.stream.s_coordinate,chosen.dut.stream.job_ids),chosen.dut.stream.s_pair});
                if(chosen.dut.stream.event_fire[4]) compare_word(4,{401'd0,side(chosen.dut.stream.d_coordinate,chosen.dut.stream.job_ids),chosen.dut.stream.d_pair});
                if(chosen.dut.stream.event_fire[5]) compare_word(5,{439'd0,side(chosen.dut.stream.n_coordinate,chosen.dut.stream.job_ids),chosen.dut.stream.n_pair});
                if(chosen.dut.stream.event_fire[6]) begin
                    compare_word(6,{467'd0,chosen.dut.class_payload});record_class=record_class+1;
                    for(integer lane=0;lane<2;lane=lane+1) begin
                        if(chosen.dut.class_payload[lane*2 +: 2]==2) strong_count=strong_count+1;
                        if(chosen.dut.class_payload[lane*2 +: 2]==1) weak_count=weak_count+1;
                    end
                    capture_record({481'd0,chosen.dut.class_payload,2'd0});
                end
                if(chosen.dut.stream.event_fire[7]) begin
                    compare_word(7,{407'd0,chosen.dut.grad_payload});record_grad=record_grad+1;
                    capture_record({421'd0,chosen.dut.grad_payload,2'd1});
                end
                if(chosen.dut.stream.nw_valid&&chosen.dut.stream.class_in_ready&&chosen.dut.stream.data_open) begin
                    logic [591:0] expected;
                    if($fscanf(gold_fd[8],"%h\n",expected)!=1) $fatal(1,"TOP NW EOF");
                    if({183'd0,side(chosen.dut.stream.nw_coordinate,chosen.dut.stream.job_ids),chosen.dut.stream.nw_pair}!==expected) $fatal(1,"TOP NW mismatch");
                    nw_count=nw_count+1;
                end
                if(chosen.dut.stream.fs_valid&&chosen.dut.stream.fs_ready) begin
                    if(got_fs) $fatal(1,"TOP duplicated FS");got_fs=1;actual_fs=chosen.dut.stream.fs;
                end
                if(chosen.dut.status_valid&&chosen.dut.status_ready) begin
                    if(got_cs||chosen.dut.class_valid||chosen.dut.grad_valid) $fatal(1,"TOP duplicated/coexistent CS");
                    got_cs=1;captured_cs=chosen.dut.status_payload;owner_drain=chosen.dut.job_controller.state==2;
                    capture_record({14'd0,chosen.dut.status_payload,2'd2});
                end
                if(warmup&&job_k==5&&chosen.dut.observer.busy&&!reset_requested) begin
                    reset_requested=1;reset_chunk=chosen.dut.observer.chunk_index;
                end
                if(chosen.dut.terminal_done) save_terminal();
            end
            for(integer b=0;b<4;b=b+1) check_ram(chosen.dut.stream.gaussian.rd_en[b],chosen.dut.stream.gaussian.wr_en[b],chosen.dut.stream.gaussian.rd_addr,chosen.dut.stream.gaussian.pending_q,2,1);
            check_ram(chosen.dut.stream.nms_window.rd_en,chosen.dut.stream.nms_window.recent_wr_en,chosen.dut.stream.nms_window.rd_addr,chosen.dut.stream.nms_window.wr_addr,4,1);
            check_ram(chosen.dut.stream.nms_window.rd_en,chosen.dut.stream.nms_window.older_wr_en,chosen.dut.stream.nms_window.rd_addr,chosen.dut.stream.nms_window.wr_addr,4,1);
            check_ram(chosen.dut.stream.sobel_window.recent.rd_en,chosen.dut.stream.sobel_window.recent.wr_en,chosen.dut.stream.sobel_window.recent.rd_addr,chosen.dut.stream.sobel_window.recent.wr_addr,2,1);
            check_ram(chosen.dut.stream.sobel_window.older.rd_en,chosen.dut.stream.sobel_window.older.wr_en,chosen.dut.stream.sobel_window.older.rd_addr,chosen.dut.stream.sobel_window.older.wr_addr,2,1);
            check_ram(chosen.dut.stream.frontend.window_before_median.recent.rd_en,chosen.dut.stream.frontend.window_before_median.recent.wr_en,chosen.dut.stream.frontend.window_before_median.recent.rd_addr,chosen.dut.stream.frontend.window_before_median.recent.wr_addr,2,0);
            check_ram(chosen.dut.stream.frontend.window_before_median.older.rd_en,chosen.dut.stream.frontend.window_before_median.older.wr_en,chosen.dut.stream.frontend.window_before_median.older.rd_addr,chosen.dut.stream.frontend.window_before_median.older.wr_addr,2,0);
            check_ram(chosen.dut.stream.frontend.window_before_sobel.recent.rd_en,chosen.dut.stream.frontend.window_before_sobel.recent.wr_en,chosen.dut.stream.frontend.window_before_sobel.recent.rd_addr,chosen.dut.stream.frontend.window_before_sobel.recent.wr_addr,2,0);
            check_ram(chosen.dut.stream.frontend.window_before_sobel.older.rd_en,chosen.dut.stream.frontend.window_before_sobel.older.wr_en,chosen.dut.stream.frontend.window_before_sobel.older.rd_addr,chosen.dut.stream.frontend.window_before_sobel.older.wr_addr,2,0);
        end
    end
    initial begin
        if(!$value$plusargs("CASE=%s",case_id)||!$value$plusargs("IN=%s",input_path)
            ||!$value$plusargs("VECTOR_DIR=%s",vector_dir)||!$value$plusargs("RESULT=%s",result_path)
            ||!$value$plusargs("OUTPUT_DIR=%s",output_dir)) $fatal(1,"TOP-S args");
        if(HD_MODE) $readmemh(input_path,jobs,0,0);
        else $readmemh(input_path,jobs);
        result_fd=$fopen(result_path,"w");if(result_fd==0) $fatal(1,"TOP result open");
        $fwrite(result_fd,"{\"schema_version\":1,\"case_id\":\"%s\",\"suite\":\"r2-observer-v1\",\"width\":%0d,\"height\":%0d,\"warmup_jobs\":[",case_id,W,H);
        repeat(4) begin @(negedge clk_25m);key_low_cycles=key_low_cycles+1;end
        key1_n=1;
        if(HD_MODE) begin
            $fwrite(result_fd,"],\"initial_key_low_cycles\":%0d,\"jobs\":[",key_low_cycles);
            while(completed<1) @(negedge clk_25m);
            // terminal_done在真实J边沿被采样；NBA后必须已经回到START/k1。
            if(chosen.dut.job_controller.k!==32'd1||chosen.dut.job_controller.state!==3'd0)
                $fatal(1,"TOP-HD J did not advance after terminal CRC");
            key1_n=0;
            $fwrite(result_fd,"],");save_observation_totals();
            $fwrite(result_fd,"\"next_k\":1,\"next_state\":0,\"status\":\"PASS\",\"finished\":true,\"numeric_errors\":0,\"protocol_errors\":0,\"compared_pairs\":%0d,\"completed_jobs\":1,\"reset_aborted_jobs\":0,\"cycles\":%0d}\n",P,cycles);
            $fclose(result_fd);finished=1;$finish;
        end
        key_low_cycles=0;
        while(!reset_requested) @(negedge clk_25m);
        if(warmup_completed!=5||!active_job) $fatal(1,"TOP k5 reset phase not reached");
        key1_n=0;close_job();warmup=0;
        repeat(4) begin @(negedge clk_25m);key_low_cycles=key_low_cycles+1;end
        $fwrite(result_fd,"],\"reset_k\":5,\"reset_chunk\":%0d,\"key_low_cycles\":%0d,\"jobs\":[",reset_chunk,key_low_cycles);
        key1_n=1;
        while(completed<128) @(negedge clk_25m);
        if(chosen.dut.job_controller.state==4) $fatal(1,"TOP ended ERROR");
        key1_n=0;
        $fwrite(result_fd,"],");save_observation_totals();
        $fwrite(result_fd,"\"status\":\"PASS\",\"finished\":true,\"numeric_errors\":0,\"protocol_errors\":0,\"compared_pairs\":128,\"completed_jobs\":128,\"reset_aborted_jobs\":1,\"cycles\":%0d}\n",cycles);
        $fclose(result_fd);finished=1;$finish;
    end
endmodule
