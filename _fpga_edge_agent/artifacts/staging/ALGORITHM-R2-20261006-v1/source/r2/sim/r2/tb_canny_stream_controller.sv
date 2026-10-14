// C0§8逐案端口fixture；人工FS只验证C0合同，不冒充真实FE数值链。
module tb_canny_stream_controller;
    localparam integer W=6,H=5,P=15;
    logic clk=0;always #5 clk=~clk;
    logic rst=1,cancel=0,cj_valid=0,fj_ready=0,fs_valid=0,derr_valid=0,status_ready=0;
    logic [141:0] cj=0;logic [162:0] fs=0;logic [119:0] derr=0;
    logic [7:0] event_fire=0;logic [967:0] event_metadata=0;
    logic [3:0] event_classes=6;logic [63:0] event_grad=0;logic [4:0] private_empty=31;
    wire cj_ready,fj_valid,fs_ready,derr_ready,fe_cancel,fp_allow,stream_start,data_flush,ctx_live,status_valid;
    wire [109:0] fj;wire [141:0] ctx_cj;wire [591:0] status_payload;
    canny_stream_controller #(.W(W),.H(H)) dut (.*);
    logic [141:0] jobs[0:1];logic [591:0] golden[0:1];
    string case_id,input_path,expected_path,result_path;
    integer scenario,fd,compared=0,cycles=0,hold_cycles=0,fj_hold_cycles=0,recovered=0;
    integer ledger[0:7];integer strong_ledger=0,weak_ledger=0;
    logic [7:0] eof_ledger=0;logic [162:0] fs_ledger=0;
    logic previous_fj_hold=0,previous_cs_hold=0;
    logic [109:0] held_fj;logic [591:0] held_cs;
    logic finished=0;
    integer status_jobs=0,cancel_events=0,fe_cancel_cycles=0,fs_fires=0,cs_fires=0,start_events=0,reset_entries=0;
    logic logged_status=0,was_reset=0,was_cancel=0;

    // 在真实边沿记账，与DUT内部游标和状态无关。
    always @(posedge clk) begin
        cycles=cycles+1;
        if(cycles>16384) $fatal(1,"C0 finite timeout");
        if(rst) begin
            if(!was_reset) reset_entries=reset_entries+1;
            was_reset=1;was_cancel=0;
            if(cj_ready||fj_valid||fs_ready||derr_ready||status_valid||fp_allow||stream_start)
                $fatal(1,"reset did not mask fire");
            previous_fj_hold=0;previous_cs_hold=0;
            for(integer i=0;i<8;i=i+1) ledger[i]=0;
            strong_ledger=0;weak_ledger=0;eof_ledger=0;fs_ledger=0;
        end else begin
            was_reset=0;
            if(cancel&&!was_cancel) cancel_events=cancel_events+1;
            was_cancel=cancel;
            if(fe_cancel) fe_cancel_cycles=fe_cancel_cycles+1;
            if(fs_valid&&fs_ready) fs_fires=fs_fires+1;
            if(status_valid&&status_ready) cs_fires=cs_fires+1;
            if(stream_start) start_events=start_events+1;
            if(previous_fj_hold&&(!fj_valid||fj!==held_fj)) $fatal(1,"held FJ changed");
            if(previous_cs_hold&&(!status_valid||status_payload!==held_cs)) $fatal(1,"held CS changed");
            previous_fj_hold=fj_valid&&!fj_ready;held_fj=fj;
            previous_cs_hold=status_valid&&!status_ready;held_cs=status_payload;
            if(previous_fj_hold) fj_hold_cycles=fj_hold_cycles+1;
            if(previous_cs_hold) hold_cycles=hold_cycles+1;
            if(cj_valid&&cj_ready) begin
                logged_status=0;
                for(integer i=0;i<8;i=i+1) ledger[i]=0;
                strong_ledger=0;weak_ledger=0;eof_ledger=0;fs_ledger=0;
                if(fj_valid||fp_allow) $fatal(1,"CJ transparent start");
            end
            if(fj_valid&&fj_ready&&fp_allow) $fatal(1,"FJ transparent FP");
            if(fs_valid&&fs_ready) fs_ledger=fs;
            if(ctx_live&&!status_valid) begin
                for(integer i=0;i<8;i=i+1) if(event_fire[i]) begin
                    ledger[i]=ledger[i]+1;
                    if(event_metadata[i*121+120]) eof_ledger[i]=1;
                end
                if(event_fire[6]) for(integer lane=0;lane<2;lane=lane+1) begin
                    if(event_classes[lane*2 +: 2]==2) strong_ledger=strong_ledger+1;
                    if(event_classes[lane*2 +: 2]==1) weak_ledger=weak_ledger+1;
                end
            end
        end
    end
    // 返回下降沿，随后修改driver；所有检查采样沿前fire/沿后提交。
    task automatic tick;
        @(posedge clk);#1;@(negedge clk);
    endtask
    task automatic quiet(input integer n);
        repeat(n) tick();
    endtask
    task automatic offer_job(input logic [141:0] word);
        cj=word;cj_valid=1;
        if(!cj_ready) $fatal(1,"CJ not ready at independent job boundary");
        tick();cj_valid=0;
    endtask
    task automatic enter_run;
        private_empty=0;fj_ready=1;
        tick(); // ARM共同start，FJ尚未在此沿接纳。
        if(!fj_valid||fp_allow) $fatal(1,"ARM/FJ contract");
        tick();
        if(!fp_allow) $fatal(1,"FJ did not enter RUN");
    endtask
    task automatic prepare_events(input logic [7:0] ports);
        integer x,y;
        event_fire=ports;event_metadata=0;
        for(integer i=0;i<8;i=i+1) begin
            x=2*(ledger[i]%(W/2));y=ledger[i]/(W/2);
            event_metadata[i*121 +: 121]={1'(x==W-2&&y==H-1),1'(x==W-2),1'(x==0&&y==0),
                ctx_cj[95:0],11'(y),11'(x)};
        end
    endtask
    task automatic send_events(input logic [7:0] ports,input integer n);
        repeat(n) begin prepare_events(ports);tick();event_fire=0;end
    endtask
    function automatic [162:0] make_fs(input logic [2:0] code,input logic [95:0] identity,
        input integer n_in,n_out,x,y);
        make_fs={11'(y),11'(x),21'(n_out),21'(n_in),identity,code};
    endfunction
    task automatic send_fs(input logic [2:0] code,input integer x,y);
        fs=make_fs(code,ctx_cj[95:0],ledger[0],ledger[1],x,y);fs_valid=1;
        if(!fs_ready) $fatal(1,"FS ready depends on data drain");
        tick();fs_valid=0;
        if(fs_ready) $fatal(1,"duplicate FS slot open");
    endtask
    task automatic drain_abort(input logic [2:0] code);
        quiet(2); // 让旧FEcancel至少在原FS尚未valid时真实可见一沿。
        send_fs(code,0,0);private_empty=31;
    endtask
    task automatic check_status(input integer index);
        integer waits;
        waits=0;
        while(!status_valid&&waits<128) begin tick();waits=waits+1;end
        if(!status_valid) $fatal(1,"missing CS");
        if(status_payload!==golden[index]) begin
            $display("actual=%h expected=%h",status_payload,golden[index]);
            $fatal(1,"CS592 differs from independent scenario oracle");
        end
        for(integer i=0;i<8;i=i+1)
            if(status_payload[211+i*21 +: 21]!==21'(ledger[i])) $fatal(1,"actual prefix differs");
        if(status_payload[386:379]!==eof_ledger||status_payload[407:387]!==21'(strong_ledger)
            ||status_payload[428:408]!==21'(weak_ledger)||status_payload[591:429]!==fs_ledger)
            $fatal(1,"CS facts differ from actual port ledger");
        // C14重复检查同一个held终态不重复记job；原逐位断言仍照常执行。
        if(!logged_status) begin
            if(status_jobs!=0) $fwrite(fd,",");
            $fwrite(fd,"{\"cj_hex\":\"%036h\",\"fs_hex\":\"%041h\",\"cs_hex\":\"%0148h\",\"accepted_counts\":[",ctx_cj,fs_ledger,status_payload);
            for(integer i=0;i<8;i=i+1) $fwrite(fd,"%s%0d",i==0?"":",",ledger[i]);
            $fwrite(fd,"],\"eof\":%0d,\"strong\":%0d,\"weak\":%0d,\"cs_bits_compared\":592}",eof_ledger,strong_ledger,weak_ledger);
            status_jobs=status_jobs+1;logged_status=1;
        end
        compared=compared+1;
    endtask
    task automatic release_status;
        status_ready=1;tick();status_ready=0;cancel=0;
        if(status_valid||!cj_ready) $fatal(1,"CS did not release context");
    endtask
    task automatic complete_job(input logic [141:0] word,input integer index);
        offer_job(word);enter_run();send_events(8'hff,P);send_fs(0,0,0);private_empty=31;
        check_status(index);release_status();
    endtask

    initial begin
        if(!$value$plusargs("CASE=%s",case_id)||!$value$plusargs("IN=%s",input_path)
            ||!$value$plusargs("EXPECTED=%s",expected_path)||!$value$plusargs("RESULT=%s",result_path)
            ||!$value$plusargs("SCENARIO=%d",scenario)) $fatal(1,"C0 arguments");
        $readmemh(input_path,jobs);$readmemh(expected_path,golden,0,scenario==16?0:1);
        fd=$fopen(result_path,"w");if(fd==0) $fatal(1,"result open");
        $fwrite(fd,"{\"schema_version\":1,\"case_id\":\"%s\",\"suite\":\"r2-stream-v1\",\"width\":%0d,\"height\":%0d,\"jobs\":[",case_id,W,H);
        @(negedge clk);quiet(3);rst=0;quiet(1);
        offer_job(jobs[0]);
        case(scenario)
            1:begin end
            2:begin cancel=1;tick();end
            3:begin
                private_empty=0;tick();cancel=1;quiet(8);
                if(!fj_valid||fp_allow||stream_start||fe_cancel) $fatal(1,"held FJ abort obligations");
                fj_ready=1;tick();drain_abort(1);
            end
            4:begin private_empty=0;tick();fj_ready=1;cancel=1;tick();drain_abort(1);end
            5:begin enter_run();send_events(1,1);send_fs(2,0,0);private_empty=31;end
            6:begin
                enter_run();send_events(1,P-1);prepare_events(1);event_metadata[120]=0;tick();event_fire=0;
                send_fs(4,4,4);private_empty=31;
            end
            7:begin
                enter_run();send_events(8'h3f,P);send_fs(0,0,0);quiet(8);
                if(status_valid||!ctx_live) $fatal(1,"early FS ended held tail");
                send_events(8'hc0,P);private_empty=31;
            end
            8:begin
                enter_run();send_events(3,P);prepare_events(8'h40);cancel=1;
                fs=make_fs(0,ctx_cj[95:0],P,P,0,0);fs_valid=1;
                tick();event_fire=0;fs_valid=0;private_empty=31;
            end
            9:begin enter_run();send_events(8'h7f,P);send_fs(0,0,0);private_empty=31;end
            10:begin
                enter_run();send_events(8'hf8,1);
                derr={ctx_cj[95:0],1'b1,1'b0,11'd0,11'd0};derr_valid=1;tick();derr_valid=0;drain_abort(1);
            end
            11:begin enter_run();send_events(3,P);send_fs(0,0,0);private_empty=31;end
            12:begin
                enter_run();fs=make_fs(7,ctx_cj[95:0]^96'd1,1,1,0,0);fs_valid=1;
                tick();fs_valid=0;private_empty=31;
            end
            13:begin
                enter_run();send_events(8'h08,1);
                derr={ctx_cj[95:0],1'b1,1'b1,11'd0,11'd1};derr_valid=1;tick();derr_valid=0;drain_abort(1);
            end
            14,15:begin enter_run();send_events(8'hff,P);send_fs(0,0,0);private_empty=31;end
            16:begin
                private_empty=0;tick();derr_valid=1;rst=1;quiet(2);
                derr_valid=0;rst=0;private_empty=31;quiet(2);
                if(status_valid||fj_valid||ctx_live) $fatal(1,"reset retained old job");
            end
            17:begin
                enter_run();prepare_events(8'hfe);
                event_metadata[121+22]=~event_metadata[121+22];
                event_metadata[121 +: 11]=11'd3;event_metadata[121+118]=0;
                event_metadata[242+22]=~event_metadata[242+22];event_classes=4'he;
                tick();event_fire=0;event_classes=6;drain_abort(1);
            end
            18:begin
                enter_run();send_events(8'hfd,P);send_events(8'h02,P-1);prepare_events(8'h02);
                fs=make_fs(0,ctx_cj[95:0],P,P,0,0);fs_valid=1;
                tick();event_fire=0;fs_valid=0;private_empty=31;
            end
            19:begin
                enter_run();fs=make_fs(1,ctx_cj[95:0],0,0,0,0);fs_valid=1;cancel=1;
                tick();fs_valid=0;private_empty=31;
            end
            20:begin enter_run();cancel=1;tick();drain_abort(1);end
            21:begin
                enter_run();prepare_events(4);event_metadata[242 +: 22]={11'd2047,11'd2047};
                tick();event_fire=0;drain_abort(1);
            end
            default:$fatal(1,"unknown C0 scenario");
        endcase
        if(scenario!=16) begin
            check_status(0);
            if(scenario==14) begin
                cancel=1;quiet(8);check_status(0);compared=compared-1;
                cj=jobs[1];cj_valid=1;status_ready=1;
                if(cj_ready) $fatal(1,"CS and next CJ accepted on same edge");
                tick();cj_valid=0;status_ready=0;cancel=0;
            end else if(scenario==15) begin
                // 清旧来源candidate后才提出下一CJ；FP不含ID，责任在父源。
                event_fire=0;event_metadata=0;cj=jobs[1];cj_valid=1;status_ready=1;
                if(cj_ready) $fatal(1,"source isolation boundary lacks idle edge");
                tick();status_ready=0;
                if(!cj_ready||fp_allow) $fatal(1,"next job boundary");
                tick();cj_valid=0;enter_run();send_events(8'hff,P);send_fs(0,0,0);private_empty=31;
                check_status(1);release_status();recovered=1;
            end else begin quiet(8);release_status();end
        end
        if(!recovered) begin
            complete_job(jobs[1],scenario==16?0:1);recovered=1;
        end
        $fwrite(fd,"],\"cancel_events\":%0d,\"fe_cancel_cycles\":%0d,\"fs_fires\":%0d,\"cs_fires\":%0d,\"start_events\":%0d,\"reset_entries\":%0d,\"status\":\"PASS\",\"finished\":true,\"numeric_errors\":0,\"protocol_errors\":0,\"compared_pairs\":%0d,\"compared_statuses\":%0d,\"recovery_jobs\":%0d,\"reset_aborted_jobs\":%0d,\"cs_hold_cycles\":%0d,\"fj_hold_cycles\":%0d,\"cycles\":%0d}\n",
            cancel_events,fe_cancel_cycles,fs_fires,cs_fires,start_events,reset_entries,compared,compared,recovered,scenario==16?1:0,hold_cycles,fj_hold_cycles,cycles);
        $fclose(fd);finished=1;$finish;
    end
endmodule
