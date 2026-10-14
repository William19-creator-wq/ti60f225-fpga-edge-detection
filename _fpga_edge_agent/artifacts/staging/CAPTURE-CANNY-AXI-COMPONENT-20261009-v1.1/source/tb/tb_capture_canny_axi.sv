`timescale 1ns/1ps
// CA-T01：只喂RAW，FP由实际128bit源读回产生；所有最终plane都从AXI端点导出。
module tb_capture_canny_axi #(parameter integer WIDTH=34,HEIGHT=19,RUN_PROTOCOL=1);
    localparam integer N=WIDTH*HEIGHT,P=N/2,S=((3*N+63)/64)*64,C=((N+255)/256)*64,Q=((N+15)/16)*64,E=((N+63)/64)*64;
    localparam integer SB=0,CB=S+64,QB=CB+C+64,EB=QB+Q+64,MEM=EB+E+64;
    logic clk=0,rst=1,finished=0,axi_enable=1;always #5 clk=~clk;
    logic job_valid=0,job_ready;logic [141:0] job_cj=0;logic [194:0] job_origin=0;logic [63:0] job_handle=0;logic [1:0] bayer_phase=0;
    logic [31:0] source_base=SB,class_base=CB,queue_base=QB,result_base=EB;
    logic in_valid=0,in_ready,in_bad=0;logic [19:0] raw_pair=0;logic [10:0] in_x_even=0,in_y=0;logic [2:0] in_markers=0;logic [63:0] in_handle=0;
    logic rx_close_valid=0,rx_close_ready,rx_close_good=1;logic [63:0] rx_close_handle=0;logic [194:0] rx_close_origin=0;
    logic cancel_valid=0;logic [95:0] cancel_scope=0;logic grad_valid,grad_ready=0;logic [184:0] grad_payload;
    logic done_valid,done_ready=0,source_stop,quarantined;logic [95:0] done_scope;logic [194:0] done_origin;logic [1:0] outcome;logic [31:0] reason;
    logic [21:0] source_pairs,output_pixels,edge_pixels,discarded_fp;logic [20:0] reader_pairs,canny_input,canny_class;logic [591:0] r2_status_snapshot;logic [3:0] phase;
    logic m_axi_awvalid,m_axi_awready,m_axi_wvalid,m_axi_wready,m_axi_wlast,m_axi_bvalid,m_axi_bready,m_axi_arvalid,m_axi_arready,m_axi_rvalid,m_axi_rready,m_axi_rlast;
    logic [31:0] m_axi_awaddr,m_axi_araddr;logic [3:0] m_axi_awid,m_axi_arid,m_axi_bid,m_axi_rid;
    logic [7:0] m_axi_awlen,m_axi_arlen;logic [2:0] m_axi_awsize,m_axi_arsize;logic [1:0] m_axi_awburst,m_axi_arburst,m_axi_bresp,m_axi_rresp;
    logic [127:0] m_axi_wdata,m_axi_rdata;logic [15:0] m_axi_wstrb;
    logic random_stalls=1,hold_aw=0,hold_w=0,hold_ar=0,hold_b=0,hold_r=0;integer fault_kind=0;
    capture_canny_axi #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ADDRESS_BYTES(33'(MEM))) dut(.*);
    axi128_byte_memory #(.BYTES(MEM)) slave(.*);
    logic [19:0] raw_values[0:P-1];logic [73:0] fp_values[0:P-1];logic [184:0] grad_values[0:P-1];
    logic [141:0] locked_cj;logic [194:0] locked_origin;logic [63:0] locked_handle;logic [1:0] locked_bayer;
    logic record_normal=0,snapshot_saved=0,held_done=0,hold_grad=0;
    logic held_aw=0,held_ar=0,held_w=0,held_fp=0;
    logic [48:0] aw_body,ar_body;logic [144:0] w_body;logic [137:0] fp_body;
    logic [1067:0] done_body;logic [31:0] rng=32'hb7560187;
    integer cycles=0,case_id=0,actual_fp=0,actual_grads=0,actual_raw=0,fp_file=0,grad_file=0;
    integer cases=0,cancels=0,errors=0,aw_events=0,ar_events=0,w_events=0,r_events=0,b_events=0,source_reads=0,source_writes=0;
    integer failed_fp_discards=0,held_fp_failure_witness=0;
    task automatic dump_bytes(input string filename,input integer address,input integer length);
        integer handle;
        handle=$fopen(filename,"wb");if(!handle)$fatal(1,"Capture-Canny output file");
        for(integer i=0;i<length;i++)$fwrite(handle,"%c",slave.memory_bytes[address+i]);$fclose(handle);
    endtask
    always @(negedge clk)begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};grad_ready=!rst && !hold_grad && rng[2:0]!=0;
    end
    always @(posedge clk)begin
        cycles++;
        if(rst)begin held_done=0;held_aw=0;held_ar=0;held_w=0;held_fp=0;end
        else begin
            if(held_aw && (!m_axi_awvalid || {m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst}!==aw_body))$fatal(1,"Held AW changed");
            if(held_ar && (!m_axi_arvalid || {m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst}!==ar_body))$fatal(1,"Held AR changed");
            if(held_w && (!m_axi_wvalid || {m_axi_wdata,m_axi_wstrb,m_axi_wlast}!==w_body))$fatal(1,"Held W changed");
            if(held_fp && (!dut.r_out_valid || {dut.r_id,dut.r_fp}!==fp_body))$fatal(1,"Held source FP changed");
            held_aw=m_axi_awvalid && !m_axi_awready;aw_body={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst};
            held_ar=m_axi_arvalid && !m_axi_arready;ar_body={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst};
            held_w=m_axi_wvalid && !m_axi_wready;w_body={m_axi_wdata,m_axi_wstrb,m_axi_wlast};
            held_fp=dut.r_out_valid && !dut.r_out_ready;fp_body={dut.r_id,dut.r_fp};
            if(held_done && (!done_valid || done_body!=={done_scope,done_origin,outcome,reason,source_pairs,reader_pairs,canny_input,canny_class,output_pixels,edge_pixels,discarded_fp,r2_status_snapshot}))$fatal(1,"Capture-Canny held done changed");
            held_done=done_valid && !done_ready;done_body={done_scope,done_origin,outcome,reason,source_pairs,reader_pairs,canny_input,canny_class,output_pixels,edge_pixels,discarded_fp,r2_status_snapshot};
            if(in_valid && in_ready)actual_raw++;
            if(dut.r_out_valid && dut.r_out_ready)begin
                if(actual_fp>=P || dut.r_fp!==fp_values[actual_fp] || dut.r_id!=locked_handle)$fatal(1,"Actual source reader FP mismatch %0d",actual_fp);
                if(record_normal)$fwrite(fp_file,"%019h\n",dut.r_fp);actual_fp++;
            end
            if(grad_valid && grad_ready)begin
                if(record_normal)begin
                    if(!locked_cj[141] || actual_grads>=P || grad_payload!==grad_values[actual_grads])$fatal(1,"Same-source gradient mismatch");
                    $fwrite(grad_file,"%047h\n",grad_payload);
                end
                actual_grads++;
            end
            if(record_normal && !snapshot_saved && dut.canny.state==5 && dut.canny.active_cj==locked_cj)begin
                dump_bytes($sformatf("actual-%0d.class.bin",case_id),CB,C);snapshot_saved=1;
                if(dut.canny.line_req_valid || dut.canny.memory_algorithm.control!=0)$fatal(1,"Class phase snapshot with HY already active");
            end
            if(m_axi_awvalid && m_axi_awready)begin aw_events++;if(m_axi_awaddr<S)source_writes++;end
            if(m_axi_arvalid && m_axi_arready)begin ar_events++;if(m_axi_araddr<S)source_reads++;end
            if(m_axi_wvalid && m_axi_wready)w_events++;
            if(m_axi_rvalid && m_axi_rready)r_events++;
            if(m_axi_bvalid && m_axi_bready)b_events++;
        end
        if(cycles<64)$display("BOOT %0d rst=%b phase=%0d ready=%b legal=%b child_ready=%b%b%b Q=%b%b%b%b%b%b topQ=%b capture_state=%0d reader_state=%0d canny_state=%0d",cycles,rst,phase,job_ready,dut.legal,dut.s_job_ready,dut.r_job_ready,dut.c_job_ready,dut.s_q,dut.r_q,dut.c_q,dut.sr_q,dut.outer_q,dut.bridge_q,quarantined,dut.capture.state,dut.reader.state,dut.canny.state);
        if(cycles>1000*N+100000)$fatal(1,"Capture-Canny watchdog phase=%0d protocol=%0d started=%b%b%b closed=%b%b%b rx=%b stopping=%b states=%0d/%0d/%0d AXI=%0d public=%b%b%b rFP=%b/%b",phase,cases,dut.s_started,dut.r_started,dut.c_started,dut.s_closed,dut.r_closed,dut.c_closed,dut.rx_seen,dut.stopping,dut.capture.state,dut.reader.state,dut.canny.state,dut.memory_bridge.state,m_axi_awvalid,m_axi_arvalid,m_axi_rvalid,dut.r_out_valid,dut.r_out_ready);
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;axi_enable=1;job_valid=0;in_valid=0;in_bad=0;rx_close_valid=0;cancel_valid=0;done_ready=0;
        hold_aw=0;hold_ar=0;hold_w=0;hold_b=0;hold_r=0;hold_grad=0;fault_kind=0;random_stalls=1;record_normal=0;
        source_base=SB;class_base=CB;queue_base=QB;result_base=EB;actual_raw=0;actual_fp=0;actual_grads=0;snapshot_saved=0;
        repeat(3)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic load_case(input integer ordinal);
        integer handle,ignored,phase_value,edges,retain,index;
        logic [141:0] cfg;logic [194:0] source;logic [63:0] local_id;
        handle=$fopen("cases.txt","r");if(!handle)$fatal(1,"Missing capture cases");index=0;
        do begin ignored=$fscanf(handle,"%h %h %h %d %d %d\n",cfg,source,local_id,phase_value,edges,retain);if(ignored!=6)$fatal(1,"Capture case parse");end while(index++<ordinal);
        $fclose(handle);job_cj=cfg;job_origin=source;job_handle=local_id;bayer_phase=2'(phase_value);
        locked_cj=cfg;locked_origin=source;locked_handle=local_id;locked_bayer=2'(phase_value);
        $readmemh($sformatf("case-%0d.raw",ordinal),raw_values);$readmemh($sformatf("case-%0d.fp",ordinal),fp_values);
        if(retain)$readmemh($sformatf("case-%0d.grad",ordinal),grad_values);
    endtask
    task automatic start_job;
        $display("START case=%0d cfg=%h origin=%h legal=%b",case_id,job_cj,job_origin,dut.legal);
        @(negedge clk);job_valid=1;do @(posedge clk);while(job_ready!==1'b1);
        @(negedge clk);job_valid=0;job_cj=0;job_origin='1;job_handle=0;bayer_phase=locked_bayer^2'd3;
    endtask
    task automatic feed_raw(input integer corruption=0);
        for(integer n=0;n<P;n++)begin
            @(negedge clk);if(source_stop)break;
            raw_pair=raw_values[n];in_x_even=11'((n%(WIDTH/2))*2);in_y=11'(n/(WIDTH/2));in_handle=locked_handle;
            in_markers={n==P-1,n%(WIDTH/2)==WIDTH/2-1,n==0};in_bad=0;
            if(corruption && n==0)begin
                case(corruption)
                    1:in_bad=1;
                    2:in_handle=locked_handle^64'd1;
                    3:in_x_even=2;
                    4:in_markers=in_markers^3'd1;
                endcase
            end
            in_valid=1;do @(posedge clk);while(in_ready!==1'b1 && source_stop!==1'b1);
            @(negedge clk);in_valid=0;in_bad=0;if(source_stop)break;
        end
    endtask
    task automatic close_rx(input logic good=1,input integer wrong=0);
        @(negedge clk);rx_close_valid=1;rx_close_handle=locked_handle^(wrong==1 ? 64'd1 : 64'd0);
        rx_close_origin=locked_origin^(wrong==2 ? (195'd1<<131) : 195'd0);rx_close_good=good;
        do @(posedge clk);while(rx_close_ready!==1'b1);
        @(negedge clk);rx_close_valid=0;
    endtask
    task automatic wait_capture_ready;
        integer waited=0;
        while(phase!=2 || !in_ready)begin
            @(negedge clk);waited++;
            if(waited>1000 || done_valid || quarantined)$fatal(1,"Capture never ready phase=%0d outcome=%0d reason=%h cfg=%h origin=%h locked_cfg=%h",phase,outcome,reason,job_cj,job_origin,dut.cj);
        end
    endtask
    task automatic take_done(input integer expected);
        while(!done_valid)begin @(negedge clk);if(quarantined)$fatal(1,"Unexpected capture quarantine");end
        if(outcome!=expected || done_scope!=locked_cj[95:0] || done_origin!=locked_origin || dut.line_req_valid || slave.reading || slave.writing || slave.b_pending)$fatal(1,"Capture-Canny closure/identity out=%0d reason=%h expected=%0d",outcome,reason,expected);
        repeat(12)@(negedge clk);done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;if(!job_ready)$fatal(1,"Capture job not released");
    endtask
    task automatic cancel_once(input logic keep=0);
        // 无ready的取消是采样事件；keep同时验证父的持续电平适配。
        cancel_scope=locked_cj[95:0];cancel_valid=1;@(posedge clk);@(negedge clk);if(!keep)cancel_valid=0;
    endtask
    task automatic prepare_source(input integer ordinal=1);
        reset_joint();load_case(ordinal);start_job();wait_capture_ready();fork feed_raw();close_rx();join
        while(!dut.s_closed || !dut.rx_seen)@(negedge clk);
    endtask
    task automatic run_normal(input integer ordinal,input integer late_rx=0);
        integer result_file,status_file,origin_file,start_cycles;logic [1:0] old_bayer;
        reset_joint();load_case(ordinal);start_job();wait_capture_ready();record_normal=1;
        fp_file=$fopen($sformatf("actual-%0d.fp",ordinal),"w");grad_file=$fopen($sformatf("actual-%0d.grad",ordinal),"w");start_cycles=cycles;
        cancel_scope=locked_cj[95:0]^(96'd1<<64);cancel_valid=1;
        if(late_rx)begin
            feed_raw();while(phase!=3)@(negedge clk);repeat(20)@(negedge clk);
            if(dut.c_started || done_valid)$fatal(1,"Processed source before RX closure");
            close_rx(1,1);close_rx(1,2);repeat(10)@(negedge clk);if(dut.rx_seen || dut.c_started)$fatal(1,"Wrong RX identity closed source");close_rx();
        end else fork feed_raw();close_rx();join
        cancel_valid=0;take_done(0);record_normal=0;$fclose(fp_file);$fclose(grad_file);
        if(!snapshot_saved || source_pairs!=P || reader_pairs!=P || canny_input!=P || canny_class!=P || output_pixels!=N || actual_fp!=P || actual_raw!=P || discarded_fp || actual_grads!=(locked_cj[141] ? P : 0))$fatal(1,"Same-source totals/snapshot");
        dump_bytes($sformatf("actual-%0d.source.bin",ordinal),SB,S);dump_bytes($sformatf("actual-%0d.state.bin",ordinal),CB,C);
        dump_bytes($sformatf("actual-%0d.queue.bin",ordinal),QB,edge_pixels*4);dump_bytes($sformatf("actual-%0d.result.bin",ordinal),EB,E);
        status_file=$fopen($sformatf("actual-%0d.status",ordinal),"w");$fwrite(status_file,"%h\n",r2_status_snapshot);$fclose(status_file);
        origin_file=$fopen($sformatf("actual-%0d.origin",ordinal),"w");$fwrite(origin_file,"%h\n",done_origin);$fclose(origin_file);
        result_file=$fopen("actual-results.txt","a");$fwrite(result_file,"%0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d\n",ordinal,outcome,reason,source_pairs,reader_pairs,canny_input,canny_class,output_pixels,edge_pixels,discarded_fp,cycles-start_cycles);$fclose(result_file);
    endtask
    initial begin
        integer list_file,ignored,total=0,phase_value,edges,retain,metrics_file,requests_before,held_wait;
        logic [141:0] cfg;logic [194:0] origin;logic [63:0] handle;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        list_file=$fopen("cases.txt","r");if(!list_file)$fatal(1,"Missing capture vectors");
        while(!$feof(list_file))begin ignored=$fscanf(list_file,"%h %h %h %d %d %d\n",cfg,origin,handle,phase_value,edges,retain);if(ignored!=6)$fatal(1,"Capture fixture list parse");total++;end
        $fclose(list_file);
        for(case_id=0;case_id<total;case_id++)run_normal(case_id,case_id==0);
        if(RUN_PROTOCOL)begin
            $display("PROTOCOL RX bad");
            // late CRC失败时已经写好的源也不能进入算法。
            reset_joint();load_case(1);start_job();wait_capture_ready();feed_raw();while(phase!=3)@(negedge clk);close_rx(0);take_done(1);
            if(canny_input || output_pixels || (reason&2)==0)$fatal(1,"Bad RX source processed");cases++;errors++;
            for(integer bad=1;bad<=4;bad++)begin
                $display("PROTOCOL RAW bad=%0d",bad);
                reset_joint();load_case(1);start_job();wait_capture_ready();feed_raw(bad);close_rx();take_done(1);
                if(source_pairs!=1 || (reason&4)==0)$fatal(1,"RAW bad acceptance/error missing");cases++;errors++;
            end
            for(integer bad=0;bad<4;bad++)begin
                $display("PROTOCOL config bad=%0d",bad);
                reset_joint();load_case(1);requests_before=aw_events+ar_events;
                if(bad==0)source_base=1;else if(bad==1)result_base=source_base;else if(bad==2)job_origin[67]=!job_origin[67];else source_base=32'hffffffc0;
                locked_origin=job_origin;
                start_job();take_done(1);if(reason!=1 || aw_events+ar_events!=requests_before)$fatal(1,"Illegal source job touched AXI");cases++;errors++;
            end
            $display("PROTOCOL held source AW cancel");reset_joint();load_case(1);start_job();wait_capture_ready();hold_aw=1;
            fork
                begin feed_raw();close_rx();end
                begin while(!m_axi_awvalid)@(negedge clk);cancel_scope=locked_cj[95:0];cancel_valid=1;@(posedge clk);@(negedge clk);cancel_valid=0;repeat(15)@(negedge clk);if(!m_axi_awvalid || done_valid)$fatal(1,"Cancelled source AW withdrawn");hold_aw=0;end
            join
            take_done(2);cases++;cancels++;
            $display("PROTOCOL source BRESP");reset_joint();load_case(1);start_job();wait_capture_ready();fault_kind=1;fork feed_raw();close_rx();join;take_done(1);cases++;errors++;
            $display("PROTOCOL reader RRESP");reset_joint();load_case(1);start_job();wait_capture_ready();fork feed_raw();close_rx();join;
            while(!m_axi_arvalid)@(negedge clk);fault_kind=3;take_done(1);cases++;errors++;
            $display("PROTOCOL unknown source BID");reset_joint();load_case(1);start_job();wait_capture_ready();fault_kind=2;fork feed_raw();close_rx();join;
            while(!quarantined)@(negedge clk);repeat(20)@(negedge clk);if(done_valid || job_ready || in_ready)$fatal(1,"Unknown source borrow released");cases++;
            reset_joint();load_case(1);start_job();wait_capture_ready();fork feed_raw();close_rx();join;take_done(0);cases++;
            // 每个配置/阶段交接都用真实父状态触发；子job提案不能被取消撤回。
            $display("PROTOCOL simultaneous job/cancel");reset_joint();load_case(1);requests_before=aw_events+ar_events;
            cancel_scope=locked_cj[95:0];cancel_valid=1;start_job();take_done(2);
            if(dut.s_started || aw_events+ar_events!=requests_before)$fatal(1,"Same-edge cancel acquired source");cases++;cancels++;
            for(integer target=1;target<=6;target++)if(target!=2)begin
                $display("PROTOCOL cancel phase=%0d held level",target);
                reset_joint();load_case(1);start_job();
                if(target==3)begin wait_capture_ready();feed_raw();while(phase!=3)@(negedge clk);end
                else if(target>=4)begin wait_capture_ready();fork feed_raw();close_rx();join;while(phase!=target)@(negedge clk);end
                else while(phase!=target)@(negedge clk);
                cancel_once(1);if(!dut.rx_seen)close_rx();take_done(2);cases++;cancels++;
            end
            for(integer channel=0;channel<2;channel++)begin
                $display("PROTOCOL source %s cancel",channel==0 ? "W" : "B");
                reset_joint();load_case(1);start_job();wait_capture_ready();hold_w=channel==0;hold_b=channel==1;
                fork
                    begin feed_raw();close_rx();end
                    begin
                        if(channel==0)while(!m_axi_wvalid)@(negedge clk);else while(!slave.b_pending)@(negedge clk);
                        cancel_once();repeat(15)@(negedge clk);if(done_valid)$fatal(1,"Cancelled source closed held borrow");hold_w=0;hold_b=0;
                    end
                join
                take_done(2);cases++;cancels++;
            end
            for(integer channel=0;channel<2;channel++)begin
                $display("PROTOCOL reader %s cancel",channel==0 ? "AR" : "R");
                reset_joint();load_case(1);start_job();wait_capture_ready();hold_ar=channel==0;hold_r=channel==1;
                fork feed_raw();close_rx();join
                if(channel==0)while(!m_axi_arvalid)@(negedge clk);else while(!slave.reading)@(negedge clk);
                cancel_once();repeat(15)@(negedge clk);if(done_valid)$fatal(1,"Cancelled reader closed held borrow");hold_ar=0;hold_r=0;
                take_done(2);cases++;cancels++;
            end
            $display("PROTOCOL reader held FP cancel");prepare_source(8);hold_grad=1;
            while(!dut.r_out_valid || dut.r_out_ready)@(negedge clk);cancel_once();hold_grad=0;take_done(2);cases++;cancels++;
            for(integer stage=0;stage<3;stage++)begin
                $display("PROTOCOL Canny memory failure stage=%0d",stage);prepare_source(8);
                if(stage==1)begin
                    while(!m_axi_arvalid || m_axi_araddr<CB || m_axi_araddr>=CB+C)@(negedge clk);
                    fault_kind=3;
                    do @(posedge clk);while(!(m_axi_rvalid && m_axi_rready && m_axi_rlast));@(negedge clk);fault_kind=0;
                end else begin
                    while(!m_axi_awvalid || (stage==0 ? (m_axi_awaddr<CB || m_axi_awaddr>=CB+C) : (m_axi_awaddr<EB || m_axi_awaddr>=EB+E)))@(negedge clk);
                    hold_b=1;
                    while(!slave.b_pending)@(negedge clk);
                    if(stage==0)begin
                        hold_grad=1;held_wait=0;
                        while((!dut.r_out_valid || dut.r_out_ready) && held_wait<100)begin @(negedge clk);held_wait++;end
                        if(dut.r_out_valid && !dut.r_out_ready)held_fp_failure_witness++;
                        else if(WIDTH==6)$fatal(1,"Dedicated narrow test did not create held FP failure precondition");
                    end
                    fault_kind=1;repeat(2)@(negedge clk);hold_b=0;
                    do @(posedge clk);while(!(m_axi_bvalid && m_axi_bready));@(negedge clk);fault_kind=0;hold_grad=0;
                end
                take_done(1);if(!(reason&16))$fatal(1,"Canny memory error not propagated");
                if(stage==0)begin
                    failed_fp_discards+=discarded_fp;
                    if(held_fp_failure_witness && discarded_fp==0)$fatal(1,"Held source FP not discarded after Canny failure");
                end
                cases++;errors++;
            end
            for(integer stage=0;stage<2;stage++)begin
                $display("PROTOCOL Canny borrow cancel stage=%0d",stage);prepare_source();
                if(stage==0)while(!m_axi_arvalid || m_axi_araddr<CB || m_axi_araddr>=CB+C)@(negedge clk);
                else while(!m_axi_awvalid || m_axi_awaddr<EB || m_axi_awaddr>=EB+E)@(negedge clk);
                cancel_once();take_done(2);cases++;cancels++;
            end
            for(integer kind=4;kind<=6;kind+=2)begin
                $display("PROTOCOL reader unknown kind=%0d",kind);prepare_source();
                while(!m_axi_arvalid)@(negedge clk);fault_kind=kind;
                while(!quarantined)@(negedge clk);repeat(20)@(negedge clk);
                if(done_valid || job_ready || in_ready)$fatal(1,"Unknown reader borrow released");cases++;
            end
            $display("PROTOCOL enable loss on real source W");reset_joint();load_case(1);start_job();wait_capture_ready();hold_w=1;
            fork
                begin feed_raw();end
                begin while(!m_axi_wvalid)@(negedge clk);axi_enable=0;repeat(3)@(negedge clk);hold_w=0;end
            join
            while(!quarantined)@(negedge clk);axi_enable=1;repeat(20)@(negedge clk);if(done_valid || job_ready)$fatal(1,"Enable recovery released unknown job");cases++;
            prepare_source();take_done(0);cases++;
        end
        metrics_file=$fopen("protocol-metrics.json","w");
        $fwrite(metrics_file,"{\"finished\":true,\"images\":%0d,\"cases\":%0d,\"cancels\":%0d,\"errors\":%0d,\"aw\":%0d,\"ar\":%0d,\"w_beats\":%0d,\"r_beats\":%0d,\"b\":%0d,\"source_reads\":%0d,\"source_writes\":%0d,\"cycles\":%0d,\"failed_fp_discards\":%0d,\"held_fp_failure_witness\":%0d}\n",total,cases,cancels,errors,aw_events,ar_events,w_events,r_events,b_events,source_reads,source_writes,cycles,failed_fp_discards,held_fp_failure_witness);$fclose(metrics_file);
        finished=1;$display("Capture-Canny AXI PASS images=%0d cases=%0d cycles=%0d",total,cases,cycles);$finish;
    end
endmodule
