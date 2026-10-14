// MD：真实FE/G/S/D/FK/N/C0。只注入获批raw G8 metadata，不force任何控制。
module tb_canny_stream_top #(parameter integer W=8,H=5);
    localparam integer P=W*H/2;
    logic clk=0;always #5 clk=~clk;
    logic rst=1,cancel=0,cj_valid=0,in_valid=0,class_ready=1,grad_ready=1,status_ready=0;
    logic [141:0] cj=0;logic [73:0] in_fp=0;
    wire cj_ready,in_ready,class_valid,grad_valid,status_valid;
    wire [124:0] class_payload;wire [184:0] grad_payload;wire [591:0] status_payload;
    canny_stream_top #(.W(W),.H(H)) dut (.*);
    logic [141:0] jobs[0:1];logic [120:0] forced_g_meta;
    logic [31:0] lfsr=32'h431;
    logic finished=0,job_active=0,mutated=0,injection_live=0,reset_triggered=0;
    logic got_fs=0,cancel_sent=0,start_seen=0,fj_seen=0;
    logic [162:0] actual_fs=0;logic [7:0] eof_ledger=0;
    logic old_fp_hold=0,old_class_hold=0,old_grad_hold=0,old_cs_hold=0;
    logic [73:0] held_fp;logic [124:0] held_class;logic [184:0] held_grad;logic [591:0] held_cs;
    integer ledger[0:7],compares[0:7],file_id[0:8],stall_run[0:2];
    integer cycles=0,job_index=0,phase_stall=0,phase_hits=0,mutated_fires=0;
    integer ready_stall_cycles=0;
    integer strong_ledger=0,weak_ledger=0,nwindow_compared=0;
    integer ram_reads=0,ram_writes=0,ram_checks=0,hold_checks=0;
    integer scenario,schedule,mutation,result_fd,source_fd;
    string case_id,input_path,vector_dir,result_path,job_prefix;

    function automatic [120:0] side(input logic [24:0] coordinate,input logic [95:0] identity);
        side={coordinate[24:22],identity,coordinate[21:0]};
    endfunction
    task automatic compare_transaction(input integer stage,input logic [591:0] word);
        logic [591:0] expected;
        if($fscanf(file_id[stage],"%h\n",expected)!=1) $fatal(1,"golden premature EOF stage=%0d",stage);
        if(word!==expected) begin
            $display("stage=%0d pair=%0d actual=%h expected=%h",stage,compares[stage],word,expected);
            $fatal(1,"true stream numeric/metadata mismatch");
        end
        compares[stage]=compares[stage]+1;
    endtask
    task automatic check_ram(input logic rd,wr,input logic [9:0] ra,wa,input integer planes,input logic private_ram);
        ram_checks=ram_checks+1;
        if(rd) begin ram_reads=ram_reads+planes;if(ra>=W/2) $fatal(1,"RAM read range");end
        if(wr) begin ram_writes=ram_writes+planes;if(wa>=W/2) $fatal(1,"RAM write range");end
        if(rd&&wr&&ra==wa) $fatal(1,"RAM collision");
        if(private_ram&&dut.data_flush&&(rd||wr)) $fatal(1,"old ABORT enabled private RAM");
    endtask
    always @(posedge clk) begin : observe_real_edges
        cycles=cycles+1;
        if(cycles>8192+128*(W/2)+128*(2*P)) $fatal(1,"MD finite timeout");
        if(rst) begin
            if(cj_ready||in_ready||class_valid||grad_valid||status_valid||dut.event_fire!=0)
                $fatal(1,"reset had actual fire");
            old_fp_hold=0;old_class_hold=0;old_grad_hold=0;old_cs_hold=0;
        end else if(job_active) begin
            // cancel/abort允许作废数据候选；普通反压必须全payload保持。
            if(old_fp_hold&&!cancel&&!dut.data_flush&&(!in_valid||in_fp!==held_fp)) $fatal(1,"FP held changed");
            if(old_class_hold&&!dut.data_flush&&(!class_valid||class_payload!==held_class)) $fatal(1,"CLASS held changed");
            if(old_grad_hold&&!dut.data_flush&&(!grad_valid||grad_payload!==held_grad)) $fatal(1,"GRAD held changed");
            if(old_cs_hold&&(!status_valid||status_payload!==held_cs)) $fatal(1,"CS held changed");
            hold_checks=hold_checks+old_fp_hold+old_class_hold+old_grad_hold+old_cs_hold;
            old_fp_hold=in_valid&&!in_ready;held_fp=in_fp;
            old_class_hold=class_valid&&!class_ready;held_class=class_payload;
            old_grad_hold=grad_valid&&!grad_ready;held_grad=grad_payload;
            old_cs_hold=status_valid&&!status_ready;held_cs=status_payload;
            if(dut.stream_start) start_seen=1;
            if(dut.fj_valid&&dut.fj_ready) fj_seen=1;
            if(dut.fe_cancel&&!dut.fs_valid) cancel_sent=1;
            if(dut.fs_valid&&dut.fs_ready) begin
                if(got_fs) $fatal(1,"two real FS snapshots");
                actual_fs=dut.fs;got_fs=1;
            end
            for(integer i=0;i<8;i=i+1) if(dut.event_fire[i]) begin
                ledger[i]=ledger[i]+1;
                if(dut.event_metadata[i*121+120]) eof_ledger[i]=1;
            end
            if(dut.event_fire[0]) compare_transaction(0,{518'd0,in_fp});
            if(dut.event_fire[1]) compare_transaction(1,{455'd0,side(dut.m_coordinate,dut.m_ids),dut.m_pair});
            if(dut.event_fire[2]) begin
                compare_transaction(2,{455'd0,dut.g_metadata,dut.g_pair});
                if(job_index==0&&injection_live) mutated_fires=mutated_fires+1;
            end
            if(dut.event_fire[3]) compare_transaction(3,{405'd0,side(dut.s_coordinate,dut.job_ids),dut.s_pair});
            if(dut.event_fire[4]) compare_transaction(4,{401'd0,side(dut.d_coordinate,dut.job_ids),dut.d_pair});
            if(dut.event_fire[5]) compare_transaction(5,{439'd0,side(dut.n_coordinate,dut.job_ids),dut.n_pair});
            if(dut.event_fire[6]) begin
                compare_transaction(6,{467'd0,class_payload});
                for(integer lane=0;lane<2;lane=lane+1) begin
                    if(class_payload[lane*2 +: 2]==2) strong_ledger=strong_ledger+1;
                    if(class_payload[lane*2 +: 2]==1) weak_ledger=weak_ledger+1;
                    if(class_payload[lane*2 +: 2]==3) $fatal(1,"real class11");
                end
            end
            if(dut.event_fire[7]) compare_transaction(7,{407'd0,grad_payload});
            if(dut.nw_valid&&dut.class_in_ready&&dut.data_open) begin
                logic [591:0] expected;
                if($fscanf(file_id[8],"%h\n",expected)!=1) $fatal(1,"NW premature EOF");
                if({183'd0,side(dut.nw_coordinate,dut.job_ids),dut.nw_pair}!==expected) $fatal(1,"true NW mismatch");
                nwindow_compared=nwindow_compared+1;
            end
        end
        // 28个真正RAM10的使能/地址，同址禁止；每组planes是实际primitive数。
        for(integer b=0;b<4;b=b+1)
            check_ram(dut.gaussian.rd_en[b],dut.gaussian.wr_en[b],dut.gaussian.rd_addr,dut.gaussian.pending_q,2,1);
        check_ram(dut.nms_window.rd_en,dut.nms_window.recent_wr_en,dut.nms_window.rd_addr,dut.nms_window.wr_addr,4,1);
        check_ram(dut.nms_window.rd_en,dut.nms_window.older_wr_en,dut.nms_window.rd_addr,dut.nms_window.wr_addr,4,1);
        check_ram(dut.sobel_window.recent.rd_en,dut.sobel_window.recent.wr_en,
            dut.sobel_window.recent.rd_addr,dut.sobel_window.recent.wr_addr,2,1);
        check_ram(dut.sobel_window.older.rd_en,dut.sobel_window.older.wr_en,
            dut.sobel_window.older.rd_addr,dut.sobel_window.older.wr_addr,2,1);
        check_ram(dut.frontend.window_before_median.recent.rd_en,dut.frontend.window_before_median.recent.wr_en,
            dut.frontend.window_before_median.recent.rd_addr,dut.frontend.window_before_median.recent.wr_addr,2,0);
        check_ram(dut.frontend.window_before_median.older.rd_en,dut.frontend.window_before_median.older.wr_en,
            dut.frontend.window_before_median.older.rd_addr,dut.frontend.window_before_median.older.wr_addr,2,0);
        check_ram(dut.frontend.window_before_sobel.recent.rd_en,dut.frontend.window_before_sobel.recent.wr_en,
            dut.frontend.window_before_sobel.recent.rd_addr,dut.frontend.window_before_sobel.recent.wr_addr,2,0);
        check_ram(dut.frontend.window_before_sobel.older.rd_en,dut.frontend.window_before_sobel.older.wr_en,
            dut.frontend.window_before_sobel.older.rd_addr,dut.frontend.window_before_sobel.older.wr_addr,2,0);
    end
    task automatic tick;
        @(posedge clk);#1;
        // 指定raw metadata只持有到真实G8 fire或reset已提交，不影响下一candidate。
        if(injection_live&&(mutated_fires!=0||rst)) begin release dut.g_metadata;injection_live=0;end
        @(negedge clk);
    endtask
    task automatic open_vectors(input string prefix);
        string names[0:8];
        names[0]="fp";names[1]="msrc";names[2]="g8";names[3]="sobel";names[4]="direction";
        names[5]="ninput";names[6]="class";names[7]="grad";names[8]="nwindow";
        for(integer i=0;i<9;i=i+1) begin
            file_id[i]=$fopen({vector_dir,"/",prefix,"/",names[i],".hex"},"r");
            if(file_id[i]==0) $fatal(1,"golden open %s",names[i]);
        end
        source_fd=$fopen({vector_dir,"/",prefix,"/fp.hex"},"r");if(source_fd==0) $fatal(1,"source open");
    endtask
    task automatic close_vectors;
        for(integer i=0;i<9;i=i+1) $fclose(file_id[i]);$fclose(source_fd);
    endtask
    task automatic save_job(input logic aborted);
        $fwrite(result_fd,"{\"index\":%0d,\"reset_aborted\":%s,\"accepted_counts\":[",job_index,aborted?"true":"false");
        for(integer i=0;i<8;i=i+1) $fwrite(result_fd,"%s%0d",i==0?"":",",ledger[i]);
        $fwrite(result_fd,"],\"compared_counts\":[");
        for(integer i=0;i<8;i=i+1) $fwrite(result_fd,"%s%0d",i==0?"":",",compares[i]);
        $fwrite(result_fd,"],\"eof\":%0d,\"strong\":%0d,\"weak\":%0d,\"nwindow_compared\":%0d,\"mutated_fires\":%0d,\"ready_stall_cycles\":%0d,\"cancel_sent_before_fs\":%s,\"fs_hex\":",
            eof_ledger,strong_ledger,weak_ledger,nwindow_compared,mutated_fires,ready_stall_cycles,cancel_sent?"true":"false");
        if(aborted) $fwrite(result_fd,"null,\"cs_hex\":null}");
        else $fwrite(result_fd,"\"%041h\",\"cs_hex\":\"%0148h\"}",actual_fs,status_payload);
    endtask
    task automatic run_job(input integer index);
        integer sent=0;
        logic source_loaded=0;
        job_index=index;
        open_vectors(index==0?"primary":"recovery");
        for(integer i=0;i<8;i=i+1) begin ledger[i]=0;compares[i]=0;end
        strong_ledger=0;weak_ledger=0;nwindow_compared=0;eof_ledger=0;actual_fs=0;
        got_fs=0;cancel_sent=0;start_seen=0;fj_seen=0;mutated=0;mutated_fires=0;ready_stall_cycles=0;
        old_fp_hold=0;old_class_hold=0;old_grad_hold=0;old_cs_hold=0;reset_triggered=0;
        for(integer i=0;i<3;i=i+1) stall_run[i]=0;
        cj=jobs[index];cj_valid=1;
        if(!cj_ready) $fatal(1,"true wrapper CJ boundary");
        job_active=1;tick();cj_valid=0;status_ready=0;cancel=0;
        while(!status_valid&&!reset_triggered) begin
            lfsr={lfsr[30:0],lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
            if(source_loaded&&ledger[0]>sent) begin source_loaded=0;in_valid=0;sent=ledger[0];end
            if(!source_loaded&&sent<P&&!dut.data_flush&&!cancel&&(lfsr[0]||stall_run[0]==8)) begin
                if($fscanf(source_fd,"%h\n",in_fp)!=1) $fatal(1,"input premature EOF");
                in_valid=1;source_loaded=1;stall_run[0]=0;
            end else if(!source_loaded) stall_run[0]=stall_run[0]+1;
            class_ready=index==0||lfsr[1]||stall_run[1]==8;
            grad_ready=index==0||lfsr[2]||stall_run[2]==8;
            stall_run[1]=class_ready?0:stall_run[1]+1;stall_run[2]=grad_ready?0:stall_run[2]+1;
            if(index==0&&!mutated&&dut.g_valid&&ledger[2]==4) begin
                forced_g_meta=dut.g_metadata;
                case(mutation)
                    1:forced_g_meta[10:0]=1;
                    2:forced_g_meta[10:0]=2047;
                    3:forced_g_meta[21:11]=2047;
                    4:forced_g_meta[120]=~forced_g_meta[120];
                    5:forced_g_meta[119]=~forced_g_meta[119];
                    6:forced_g_meta[22]=~forced_g_meta[22];
                    default:$fatal(1,"MD mutation");
                endcase
                force dut.g_metadata=forced_g_meta;
                injection_live=1;mutated=1;phase_hits=phase_hits+1;
                if(schedule==2) phase_stall=8;
            end
            if(phase_stall>0) begin
                class_ready=0;grad_ready=0;phase_stall=phase_stall-1;ready_stall_cycles=ready_stall_cycles+1;
            end
            if(index==0&&injection_live&&dut.s_window_in_ready&&dut.data_open) begin
                if(schedule==3) cancel=1;
                if(schedule==4) begin rst=1;reset_triggered=1;in_valid=0;source_loaded=0;end
            end
            if(dut.data_flush) begin in_valid=0;source_loaded=0;end
            tick();
        end
        in_valid=0;
        // 失败CS可能早到；既定8沿ready事件仍做完，不能把案例名当命中证据。
        while(phase_stall>0) begin
            class_ready=0;grad_ready=0;phase_stall=phase_stall-1;ready_stall_cycles=ready_stall_cycles+1;tick();
        end
        class_ready=1;grad_ready=1;
        if(index==0&&schedule==2&&ready_stall_cycles!=8) $fatal(1,"MD exact8 ready phase missing");
        if(reset_triggered) begin
            if(status_valid||dut.event_fire!=0) $fatal(1,"MD reset produced terminal/fire");
            tick();save_job(1);rst=0;tick();
        end else begin
            if(!got_fs||!start_seen||!fj_seen) $fatal(1,"real lifecycle incomplete");
            // status反压8沿，原592位仍由独立Python端口政策逐位审计。
            repeat(8) tick();
            if(!status_valid) $fatal(1,"CS withdrawn");
            if(index==1) begin
                for(integer i=0;i<8;i=i+1) if(ledger[i]!=P||compares[i]!=P) $fatal(1,"short recovery stage");
                if(nwindow_compared!=P||status_payload[146:142]!=0) $fatal(1,"recovery not complete");
            end
            save_job(0);status_ready=1;tick();status_ready=0;cancel=0;
        end
        job_active=0;close_vectors();tick();
    endtask
    initial begin
        if($test$plusargs("FATAL_PROBE")) $fatal(1,"P-FATAL wrapper intentional failure");
        if(!$value$plusargs("CASE=%s",case_id)||!$value$plusargs("IN=%s",input_path)
            ||!$value$plusargs("VECTOR_DIR=%s",vector_dir)||!$value$plusargs("RESULT=%s",result_path)
            ||!$value$plusargs("MUTATION=%d",mutation)||!$value$plusargs("SCHEDULE=%d",schedule)) $fatal(1,"MD args");
        $readmemh(input_path,jobs);@(negedge clk);repeat(3) tick();rst=0;tick();
        result_fd=$fopen(result_path,"w");if(result_fd==0) $fatal(1,"MD result open");
        $fwrite(result_fd,"{\"schema_version\":1,\"case_id\":\"%s\",\"suite\":\"r2-stream-v1\",\"width\":%0d,\"height\":%0d,\"jobs\":[",case_id,W,H);
        run_job(0);$fwrite(result_fd,",");run_job(1);
        if(phase_hits!=1) $fatal(1,"required mutation phase not hit");
        $fwrite(result_fd,"],\"status\":\"PASS\",\"finished\":true,\"numeric_errors\":0,\"protocol_errors\":0,\"compared_pairs\":%0d,\"recovery_jobs\":1,\"required_event_hits\":%0d,\"ram_reads\":%0d,\"ram_writes\":%0d,\"ram_checks\":%0d,\"ram_range_errors\":0,\"ram_collision_errors\":0,\"hold_checks\":%0d,\"reset_aborted_jobs\":%0d,\"cycles\":%0d}\n",
            P,phase_hits,ram_reads,ram_writes,ram_checks,hold_checks,schedule==4?1:0,cycles);
        $fclose(result_fd);finished=1;$finish;
    end
endmodule

// HD/HD-F：真实SRC和K，合法外CJ driver；没有MD force或生产测试端口。
module tb_r2_hd_chain #(parameter integer W=1920,H=1080);
    localparam integer D=W/2,P=D*H;
    logic clk=0;always #20 clk=~clk;
    logic rst=1,cancel=0,cj_valid=0;logic [141:0] cj=0;
    wire cj_ready,in_valid,in_ready,class_valid,grad_valid,status_valid;
    wire [73:0] in_fp;wire [124:0] class_payload;wire [184:0] grad_payload;wire [591:0] status_payload;
    wire job_start=cj_valid&&cj_ready;
    logic source_stop=0;wire source_last_fire;
    wire [1:0] pattern=cj[67:66];wire fault=cj[38];
    logic class_gate=1,grad_gate=1,status_gate=1;
    wire k_class_ready,k_grad_ready,k_status_ready;
    wire class_ready=k_class_ready&&class_gate,grad_ready=k_grad_ready&&grad_gate,status_ready=k_status_ready&&status_gate;
    wire k_class_valid=class_valid&&class_gate,k_grad_valid=grad_valid&&grad_gate,k_status_valid=status_valid&&status_gate;
    canny_stream_top #(.W(W),.H(H)) dut (.*);
    r2_pattern_pair_source #(.W(W),.H(H)) source (
        .clk(clk),.rst(rst),.job_start(job_start),.cj(cj),.pattern(pattern),.fault(fault),.source_stop(source_stop),
        .out_valid(in_valid),.out_ready(in_ready),.out_fp(in_fp),.source_last_fire(source_last_fire)
    );
    wire [20:0] observed_class_pairs,observed_grad_pairs,observed_strong,observed_weak;
    wire observed_class_eof,observed_grad_eof,record_protocol_ok,observer_fault_sticky;
    wire terminal_done,last_result_valid,last_fixture_match,last_complete_ok;
    wire [591:0] last_cs;wire [31:0] last_crc;
    logic terminal_fixture_match,terminal_complete_ok;
    r2_result_crc_observer #(.W(W),.H(H)) observer (
        .clk(clk),.rst(rst),.job_start(job_start),.cj(cj),.retain_grad(cj[141]),
        .class_valid(k_class_valid),.class_ready(k_class_ready),.class_payload(class_payload),
        .grad_valid(k_grad_valid),.grad_ready(k_grad_ready),.grad_payload(grad_payload),
        .status_valid(k_status_valid),.status_ready(k_status_ready),.status_payload(status_payload),
        .terminal_fixture_match(terminal_fixture_match),.terminal_complete_ok(terminal_complete_ok),
        .observed_class_pairs(observed_class_pairs),.observed_grad_pairs(observed_grad_pairs),
        .observed_strong(observed_strong),.observed_weak(observed_weak),
        .observed_class_eof(observed_class_eof),.observed_grad_eof(observed_grad_eof),.record_protocol_ok(record_protocol_ok),
        .observer_fault_sticky(observer_fault_sticky),.terminal_done(terminal_done),.last_result_valid(last_result_valid),
        .last_fixture_match(last_fixture_match),.last_complete_ok(last_complete_ok),.last_cs(last_cs),.last_crc(last_crc)
    );
    always_ff @(posedge clk) begin
        if(rst||job_start) source_stop<=0;
        else if(status_valid) source_stop<=1;
    end
    logic [141:0] jobs[0:1],locked_job;
    logic finished=0,job_active=0,got_fs=0,got_cs=0,source_last_seen=0;
    logic [162:0] actual_fs;logic [591:0] captured_cs;
    logic [7:0] eof_ledger;
    logic c_pending=0,g_pending=0,s_pending=0;
    logic old_c_hold=0,old_g_hold=0,old_s_hold=0;
    logic [124:0] held_c;logic [184:0] held_g;logic [591:0] held_s;
    logic [31:0] random_state=32'h431;
    integer ledger[0:7],compares[0:8],gold_fd[0:8];
    integer cycles=0,job_index=0,job_count,completed=0,result_fd,record_fd;
    integer strong_count=0,weak_count=0,nw_count=0,record_total=0,last_capture=-20;
    integer c_stall=0,g_stall=0,s_stall=0,hold_checks=0,gate_stalls=0;
    integer ram_reads=0,ram_writes=0,ram_checks=0;
    string case_id,input_path,vector_dir,result_path,output_dir,prefix,record_relative;
    function automatic [120:0] side(input logic [24:0] c,input logic [95:0] identity);
        side={c[24:22],identity,c[21:0]};
    endfunction
    always_comb begin : independent_terminal_candidate
        terminal_fixture_match=got_fs&&status_payload[141:0]==locked_job&&status_payload[591:429]==actual_fs
            &&status_payload[182:179]==4'd7&&record_protocol_ok&&!observer_fault_sticky
            &&observed_class_pairs==ledger[6]&&observed_grad_pairs==ledger[7]
            &&observed_strong==strong_count&&observed_weak==weak_count
            &&observed_class_eof==eof_ledger[6]&&observed_grad_eof==eof_ledger[7]
            &&status_payload[386:379]==eof_ledger&&status_payload[407:387]==strong_count
            &&status_payload[428:408]==weak_count;
        for(integer i=0;i<8;i=i+1)
            if(status_payload[211+i*21 +: 21]!=ledger[i]) terminal_fixture_match=0;
        if(locked_job[38]) begin
            if(status_payload[146:142]!=5||status_payload[178:147]!=32
                ||status_payload[210:183]!={11'(H/2),11'd2,1'b0,4'd1,1'b1}
                ||ledger[0]!=(H/2)*D+2||source_last_seen||eof_ledger!=0||actual_fs[2:0]!=2)
                terminal_fixture_match=0;
        end else begin
            if(status_payload[146:142]!=0||status_payload[178:147]!=0||status_payload[210:183]!=28'd30
                ||!source_last_seen||actual_fs[2:0]!=0||eof_ledger!=(locked_job[141]?8'hff:8'h7f))
                terminal_fixture_match=0;
            for(integer i=0;i<8;i=i+1)
                if(ledger[i]!=(i==7&&!locked_job[141]?0:P)) terminal_fixture_match=0;
        end
        terminal_complete_ok=terminal_fixture_match&&!locked_job[38];
    end
    task automatic tick;
        @(posedge clk);#1;@(negedge clk);
    endtask
    task automatic compare_word(input integer stage,input logic [591:0] word);
        logic [591:0] expected;
        if($fscanf(gold_fd[stage],"%h\n",expected)!=1) $fatal(1,"HD golden EOF stage=%0d",stage);
        if(word!==expected) $fatal(1,"HD numeric/meta mismatch job=%0d stage=%0d pair=%0d got=%h expected=%h",
            job_index,stage,compares[stage],word,expected);
        compares[stage]=compares[stage]+1;
    endtask
    task automatic capture_record(input logic [607:0] record);
        if(cycles-last_capture<20) $fatal(1,"HD CRC capture spacing");
        last_capture=cycles;record_total=record_total+1;$fwrite(record_fd,"%0152h\n",record);
    endtask
    task automatic check_ram(input logic rd,wr,input logic [9:0] ra,wa,input integer planes,input logic private_ram);
        ram_checks=ram_checks+1;
        if(rd) begin ram_reads=ram_reads+planes;if(ra>=D) $fatal(1,"HD RAM read range");end
        if(wr) begin ram_writes=ram_writes+planes;if(wa>=D) $fatal(1,"HD RAM write range");end
        if(rd&&wr&&ra==wa) $fatal(1,"HD RAM same-address collision");
        if(private_ram&&dut.data_flush&&(rd||wr)) $fatal(1,"HD ABORT RAM enabled");
    endtask
    // 随机只决定新的呈现；K看到valid后若未fire，pending强制保持到fire。
    always @(negedge clk) if(!rst&&job_active) begin
        random_state={random_state[30:0],random_state[31]^random_state[21]^random_state[1]^random_state[0]};
        class_gate=c_pending||random_state[1]||c_stall==8;
        grad_gate=g_pending||random_state[2]||g_stall==8;
        status_gate=s_pending||random_state[3]||s_stall==8;
        c_stall=class_gate?0:c_stall+1;g_stall=grad_gate?0:g_stall+1;s_stall=status_gate?0:s_stall+1;
        gate_stalls=gate_stalls+!class_gate+!grad_gate+!status_gate;
    end
    always @(posedge clk) begin : actual_chain_ledger
        cycles=cycles+1;
        if(cycles>32768+128*D+job_count*(48*(2*(P+1)+1)+16*P)) $fatal(1,"HD finite timeout");
        if(rst) begin
            if(cj_ready||in_ready||class_ready||grad_ready||status_ready||terminal_done) $fatal(1,"HD rst fire");
            c_pending=0;g_pending=0;s_pending=0;old_c_hold=0;old_g_hold=0;old_s_hold=0;
        end else if(job_active) begin
            if(old_c_hold&&!dut.data_flush&&(!class_valid||class_payload!==held_c)) $fatal(1,"HD CLASS hold");
            if(old_g_hold&&!dut.data_flush&&(!grad_valid||grad_payload!==held_g)) $fatal(1,"HD GRAD hold");
            if(old_s_hold&&(!status_valid||status_payload!==held_s)) $fatal(1,"HD CS hold");
            hold_checks=hold_checks+old_c_hold+old_g_hold+old_s_hold;
            old_c_hold=class_valid&&!class_ready;held_c=class_payload;
            old_g_hold=grad_valid&&!grad_ready;held_g=grad_payload;
            old_s_hold=status_valid&&!status_ready;held_s=status_payload;
            c_pending=k_class_valid&&!k_class_ready;g_pending=k_grad_valid&&!k_grad_ready;s_pending=k_status_valid&&!k_status_ready;
            if(dut.data_flush) begin c_pending=0;g_pending=0;end
            if(source_last_fire) source_last_seen=1;
            for(integer i=0;i<8;i=i+1) if(dut.event_fire[i]) begin
                ledger[i]=ledger[i]+1;if(dut.event_metadata[i*121+120]) eof_ledger[i]=1;
            end
            if(dut.event_fire[0]) compare_word(0,{518'd0,in_fp});
            if(dut.event_fire[1]) compare_word(1,{455'd0,side(dut.m_coordinate,dut.m_ids),dut.m_pair});
            if(dut.event_fire[2]) compare_word(2,{455'd0,dut.g_metadata,dut.g_pair});
            if(dut.event_fire[3]) compare_word(3,{405'd0,side(dut.s_coordinate,dut.job_ids),dut.s_pair});
            if(dut.event_fire[4]) compare_word(4,{401'd0,side(dut.d_coordinate,dut.job_ids),dut.d_pair});
            if(dut.event_fire[5]) compare_word(5,{439'd0,side(dut.n_coordinate,dut.job_ids),dut.n_pair});
            if(dut.event_fire[6]) begin
                compare_word(6,{467'd0,class_payload});capture_record({481'd0,class_payload,2'd0});
                for(integer lane=0;lane<2;lane=lane+1) begin
                    if(class_payload[lane*2 +: 2]==2) strong_count=strong_count+1;
                    if(class_payload[lane*2 +: 2]==1) weak_count=weak_count+1;
                    if(class_payload[lane*2 +: 2]==3) $fatal(1,"HD algorithm class11");
                end
            end
            if(dut.event_fire[7]) begin compare_word(7,{407'd0,grad_payload});capture_record({421'd0,grad_payload,2'd1});end
            if(dut.nw_valid&&dut.class_in_ready&&dut.data_open) begin
                compare_word(8,{183'd0,side(dut.nw_coordinate,dut.job_ids),dut.nw_pair});nw_count=nw_count+1;
            end
            if(dut.fs_valid&&dut.fs_ready) begin if(got_fs) $fatal(1,"HD duplicate FS");got_fs=1;actual_fs=dut.fs;end
            if(status_valid&&status_ready) begin
                if(got_cs||class_valid||grad_valid||!terminal_fixture_match) $fatal(1,"HD terminal contract/coexistence");
                got_cs=1;captured_cs=status_payload;capture_record({14'd0,status_payload,2'd2});
            end
        end
        if(!rst) begin
            for(integer b=0;b<4;b=b+1) check_ram(dut.gaussian.rd_en[b],dut.gaussian.wr_en[b],dut.gaussian.rd_addr,dut.gaussian.pending_q,2,1);
            check_ram(dut.nms_window.rd_en,dut.nms_window.recent_wr_en,dut.nms_window.rd_addr,dut.nms_window.wr_addr,4,1);
            check_ram(dut.nms_window.rd_en,dut.nms_window.older_wr_en,dut.nms_window.rd_addr,dut.nms_window.wr_addr,4,1);
            check_ram(dut.sobel_window.recent.rd_en,dut.sobel_window.recent.wr_en,dut.sobel_window.recent.rd_addr,dut.sobel_window.recent.wr_addr,2,1);
            check_ram(dut.sobel_window.older.rd_en,dut.sobel_window.older.wr_en,dut.sobel_window.older.rd_addr,dut.sobel_window.older.wr_addr,2,1);
            check_ram(dut.frontend.window_before_median.recent.rd_en,dut.frontend.window_before_median.recent.wr_en,dut.frontend.window_before_median.recent.rd_addr,dut.frontend.window_before_median.recent.wr_addr,2,0);
            check_ram(dut.frontend.window_before_median.older.rd_en,dut.frontend.window_before_median.older.wr_en,dut.frontend.window_before_median.older.rd_addr,dut.frontend.window_before_median.older.wr_addr,2,0);
            check_ram(dut.frontend.window_before_sobel.recent.rd_en,dut.frontend.window_before_sobel.recent.wr_en,dut.frontend.window_before_sobel.recent.rd_addr,dut.frontend.window_before_sobel.recent.wr_addr,2,0);
            check_ram(dut.frontend.window_before_sobel.older.rd_en,dut.frontend.window_before_sobel.older.wr_en,dut.frontend.window_before_sobel.older.rd_addr,dut.frontend.window_before_sobel.older.wr_addr,2,0);
        end
    end
    task automatic run_job(input integer index);
        string names[0:8];
        job_index=index;cj=jobs[index];locked_job=cj;prefix=index==0?"primary":"recovery";
        names[0]="fp";names[1]="msrc";names[2]="g8";names[3]="sobel";names[4]="direction";
        names[5]="ninput";names[6]="class";names[7]="grad";names[8]="nwindow";
        for(integer i=0;i<9;i=i+1) begin
            gold_fd[i]=0;
            if(i!=7||cj[141]) begin
                gold_fd[i]=$fopen({vector_dir,"/",prefix,"/",names[i],".hex"},"r");
                if(!gold_fd[i]) $fatal(1,"HD golden open");
            end
        end
        record_relative={prefix,"-records.hex"};record_fd=$fopen({output_dir,"/",record_relative},"wb");
        if(!record_fd) $fatal(1,"HD record open");
        for(integer i=0;i<8;i=i+1) ledger[i]=0;
        for(integer i=0;i<9;i=i+1) compares[i]=0;
        got_fs=0;got_cs=0;eof_ledger=0;strong_count=0;weak_count=0;nw_count=0;record_total=0;
        source_last_seen=0;last_capture=-20;job_active=1;cj_valid=1;
        #1;while(!cj_ready) tick();tick();cj_valid=0;
        while(!terminal_done) tick();
        if(!got_cs||!last_result_valid||last_cs!==captured_cs||!last_fixture_match
            ||last_complete_ok!==!locked_job[38]||observer_fault_sticky||record_total!=ledger[6]+ledger[7]+1)
            $fatal(1,"HD completed snapshot mismatch");
        for(integer i=0;i<8;i=i+1) if(ledger[i]!=compares[i]) $fatal(1,"HD uncompared prefix");
        if(!locked_job[38]&&nw_count!=P) $fatal(1,"HD short NW");
        $fwrite(result_fd,"{\"k\":%0d,\"accepted_counts\":[",locked_job[63:32]);
        for(integer i=0;i<8;i=i+1) $fwrite(result_fd,"%s%0d",i==0?"":",",ledger[i]);
        $fwrite(result_fd,"],\"compared_counts\":[");
        for(integer i=0;i<8;i=i+1) $fwrite(result_fd,"%s%0d",i==0?"":",",compares[i]);
        $fwrite(result_fd,"],\"eof\":%0d,\"strong\":%0d,\"weak\":%0d,\"nwindow_compared\":%0d,\"record_class\":%0d,\"record_grad\":%0d,\"records_path\":\"%s\",\"fs_hex\":\"%041h\",\"cs_hex\":\"%0148h\",\"last_cs_hex\":\"%0148h\",\"crc_hex\":\"%08h\",\"fixture_match\":true,\"complete_ok\":%s,\"record_protocol_ok\":true}",
            eof_ledger,strong_count,weak_count,nw_count,ledger[6],ledger[7],record_relative,actual_fs,captured_cs,last_cs,last_crc,last_complete_ok?"true":"false");
        for(integer i=0;i<9;i=i+1) if(gold_fd[i]) $fclose(gold_fd[i]);
        $fclose(record_fd);completed=completed+1;job_active=0;tick();
        // 不复位恢复：旧CS/K完整结束后下一合法CJ换身份并重建行历史。
    endtask
    initial begin
        if(!$value$plusargs("CASE=%s",case_id)||!$value$plusargs("IN=%s",input_path)
            ||!$value$plusargs("VECTOR_DIR=%s",vector_dir)||!$value$plusargs("RESULT=%s",result_path)
            ||!$value$plusargs("OUTPUT_DIR=%s",output_dir)||!$value$plusargs("JOB_COUNT=%d",job_count)) $fatal(1,"HD args");
        if(W!=1920||H!=1080||job_count<1||job_count>2) $fatal(1,"HD production dimensions/count");
        $readmemh(input_path,jobs,0,job_count-1);@(negedge clk);repeat(4) tick();rst=0;tick();
        result_fd=$fopen(result_path,"w");if(!result_fd) $fatal(1,"HD result open");
        $fwrite(result_fd,"{\"schema_version\":1,\"case_id\":\"%s\",\"suite\":\"r2-stream-v1\",\"width\":1920,\"height\":1080,\"jobs\":[",case_id);
        for(integer i=0;i<job_count;i=i+1) begin if(i) $fwrite(result_fd,",");run_job(i);end
        if(gate_stalls==0||ram_reads==0||ram_writes==0) $fatal(1,"HD required stalls/RAM events missing");
        $fwrite(result_fd,"],\"status\":\"PASS\",\"finished\":true,\"numeric_errors\":0,\"protocol_errors\":0,\"compared_pairs\":%0d,\"completed_jobs\":%0d,\"required_event_hits\":%0d,\"restore_jobs\":%0d,\"reset_aborted_jobs\":0,\"ram_reads\":%0d,\"ram_writes\":%0d,\"ram_checks\":%0d,\"ram_range_errors\":0,\"ram_collision_errors\":0,\"hold_checks\":%0d,\"gate_stall_cycles\":%0d,\"cycles\":%0d}\n",
            P,completed,completed,job_count-1,ram_reads,ram_writes,ram_checks,hold_checks,gate_stalls,cycles);
        $fclose(result_fd);finished=1;$finish;
    end
endmodule
