`timescale 1ns/1ps
// 仅观察真实 reader 的公共 FP，不从私有状态/内存取期望。
module fa_reader_observer(input wire out_valid,out_ready,input wire [73:0] out_fp,input wire [63:0] out_id,
    output wire v,r,output wire [73:0] fp,output wire [63:0] id);
    assign v=out_valid; assign r=out_ready; assign fp=out_fp; assign id=out_id;
endmodule
bind rgb_frame_reader fa_reader_observer reader_observer(
    .out_valid,.out_ready,.out_fp,.out_id,
    .v($root.tb_frame_actors_axi.reader_v),.r($root.tb_frame_actors_axi.reader_r),
    .fp($root.tb_frame_actors_axi.reader_fp),.id($root.tb_frame_actors_axi.reader_id)
);

module tb_frame_actors_axi #(parameter integer TEST_WIDTH=34,TEST_HEIGHT=19,TEST_PROTOCOL=1);
    localparam integer WIDTH=TEST_WIDTH,HEIGHT=TEST_HEIGHT,N=WIDTH*HEIGHT,P=N/2;
    localparam integer S=((3*N+63)/64)*64,C=((N+255)/256)*64,Q=((N+15)/16)*64,E=((N+511)/512)*64;
    localparam integer SB=0,CB=S+64,QB=CB+C+64,EB=QB+Q+64,DB=EB+E+64,MEM=DB+S+64;
    logic clk=0,rst=1,finished=0,axi_enable=1; always #5 clk=~clk;
    logic cap_job_valid=0; wire cap_job_ready;
    logic [31:0] cap_base=SB; logic [63:0] cap_handle=0; logic [95:0] cap_scope=0; logic [1:0] cap_bayer=0;
    logic in_valid=0,in_bad=0; wire in_ready; logic [19:0] raw_pair=0;
    logic [10:0] in_x_even=0,in_y=0; logic [2:0] in_markers=0; logic [63:0] in_handle=0;
    logic cap_cancel_valid=0; logic [63:0] cap_cancel_id=0;
    wire cap_done_valid; logic cap_done_ready=0; wire [63:0] cap_done_id; wire [95:0] cap_done_scope;
    wire [1:0] cap_outcome,cap_failed_stage; wire [7:0] cap_reason;
    wire [21:0] cap_raw_pairs,cap_rgb_pairs,cap_written_lines,cap_discarded_rgb;
    wire [31:0] cap_logical_bytes,cap_physical_bytes; wire cap_stop,cap_quarantined;
    logic alg_job_valid=0; wire alg_job_ready;
    logic [141:0] alg_cj=0; logic [194:0] alg_origin=0; logic [63:0] alg_handle=0;
    logic [31:0] source_base=SB,class_base=CB,queue_base=QB,result_base=EB;
    logic alg_cancel_valid=0; logic [95:0] alg_cancel_scope=0;
    wire grad_valid; logic grad_ready=0; wire [184:0] grad_payload;
    wire alg_done_valid; logic alg_done_ready=0; wire [95:0] alg_done_scope; wire [194:0] alg_done_origin;
    wire [1:0] alg_outcome; wire [31:0] alg_reason;
    wire [20:0] reader_pairs,canny_input,canny_class; wire [21:0] output_pixels,edge_pixels,discarded_fp;
    wire [591:0] r2_status_snapshot; wire [3:0] alg_phase; wire alg_quarantined,quarantined;
    logic display_enable=1,display_cancel=0,span_req_valid=0; wire span_req_ready;
    logic [31:0] span_addr=SB; logic [13:0] span_bytes=0;
    wire display_data_valid; logic display_data_ready=0; wire [127:0] display_data;
    wire display_done_valid; logic display_done_ready=0; wire [1:0] display_outcome;
    wire [7:0] display_reason; wire display_drained;
    wire memory_quarantined,algorithm_live,read_occupied,read_physical_idle,write_busy;
    wire read_quarantined,write_quarantined,direction_quarantined; wire [2:0] read_fault_reason,write_fault_reason;
    wire m_axi_awvalid,m_axi_wvalid,m_axi_wlast,m_axi_bready,m_axi_arvalid,m_axi_rready;
    wire m_axi_awready,m_axi_wready,m_axi_bvalid,m_axi_arready,m_axi_rvalid,m_axi_rlast;
    wire [31:0] m_axi_awaddr,m_axi_araddr; wire [3:0] m_axi_awid,m_axi_arid,m_axi_bid,m_axi_rid;
    wire [7:0] m_axi_awlen,m_axi_arlen; wire [2:0] m_axi_awsize,m_axi_arsize;
    wire [1:0] m_axi_awburst,m_axi_arburst,m_axi_bresp,m_axi_rresp; wire [127:0] m_axi_wdata,m_axi_rdata;
    wire [15:0] m_axi_wstrb;
    logic random_stalls=1,hold_aw=0,hold_w=0,hold_ar=0,hold_b=0,hold_r=0;
    integer fault_kind=0; wire writing,b_pending,reading;
    frame_actors_axi #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ADDRESS_BYTES(33'(MEM))) dut(.*);
    axi128_duplex_byte_memory #(.BYTES(MEM),.CLASS_BASE(CB),.CLASS_BYTES(C)) slave(.*);
    wire reader_v,reader_r; wire [73:0] reader_fp; wire [63:0] reader_id;
    logic [19:0] raw_values[0:P-1]; logic [73:0] fp_values[0:P-1]; logic [184:0] grad_values[0:P-1];
    logic [127:0] display_values[0:S/16-1];
    logic [141:0] locked_cj; logic [194:0] locked_origin; logic [63:0] locked_handle,locked_cap_handle;
    logic [95:0] locked_cap_scope;
    integer expected_edges,frame_count,cycles=0,case_id=0,case_start=0;
    integer fp_fd=0,grad_fd=0,display_fd=0,event_fd=0,ignored,actual_fp=0,actual_grad=0;
    integer capture_jobs=0,algorithm_jobs=0,capture_done=0,algorithm_done=0,normal_images=0,protocol_cases=0,replay_jobs=0;
    integer aw_count=0,w_count=0,b_count=0,algorithm_ar=0,display_ar=0,r_count=0;
    integer raw_overlap=0,case_raw_overlap=0,physical_overlap=0;
    bit record_math=0,reset_logged=0,was_overlap=0,alg_running=0;
    bit held_alg_done=0,held_cap_done=0,held_aw=0,held_ar=0,held_w=0,held_grad=0,held_fp=0,held_display=0;
    logic [1045:0] saved_alg_done; logic [323:0] saved_cap_done;
    logic [48:0] saved_aw,saved_ar; logic [144:0] saved_w; logic [184:0] saved_grad;
    logic [137:0] saved_fp; logic [127:0] saved_display;
    logic [31:0] rng=32'hb7560187; string directory;
    always @(negedge clk) begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        grad_ready=!rst&&rng[2:0]!=0; display_data_ready=!rst&&rng[5:3]!=0;
    end
    always @(posedge clk) if(event_fd) begin
        cycles++;
        if(rst) begin
            if(!reset_logged)$fwrite(event_fd,"%0d\t%0d\tRESET\t0\n",case_id,cycles);
            reset_logged=1; was_overlap=0; alg_running=0;
            held_alg_done=0; held_cap_done=0; held_aw=0; held_ar=0; held_w=0; held_grad=0; held_fp=0; held_display=0;
        end else begin
            reset_logged=0;
            if(held_alg_done&&(!alg_done_valid||saved_alg_done!=={alg_done_scope,alg_done_origin,alg_outcome,alg_reason,reader_pairs,canny_input,canny_class,output_pixels,edge_pixels,discarded_fp,r2_status_snapshot}))$fatal(1,"Algorithm DONE holding changed");
            if(held_cap_done&&(!cap_done_valid||saved_cap_done!=={cap_done_id,cap_done_scope,cap_outcome,cap_failed_stage,cap_reason,cap_raw_pairs,cap_rgb_pairs,cap_written_lines,cap_discarded_rgb,cap_logical_bytes,cap_physical_bytes}))$fatal(1,"Capture DONE holding changed");
            if(held_aw&&(!m_axi_awvalid||saved_aw!=={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst}))$fatal(1,"AW holding changed");
            if(held_ar&&(!m_axi_arvalid||saved_ar!=={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst}))$fatal(1,"AR holding changed");
            if(held_w&&(!m_axi_wvalid||saved_w!=={m_axi_wdata,m_axi_wstrb,m_axi_wlast}))$fatal(1,"W holding changed");
            if(held_grad&&(!grad_valid||saved_grad!==grad_payload))$fatal(1,"Gradient holding changed");
            if(held_fp&&(!reader_v||saved_fp!=={reader_id,reader_fp}))$fatal(1,"FP holding changed");
            if(held_display&&(!display_data_valid||saved_display!==display_data))$fatal(1,"Display holding changed");
            held_alg_done=alg_done_valid&&!alg_done_ready; saved_alg_done={alg_done_scope,alg_done_origin,alg_outcome,alg_reason,reader_pairs,canny_input,canny_class,output_pixels,edge_pixels,discarded_fp,r2_status_snapshot};
            held_cap_done=cap_done_valid&&!cap_done_ready; saved_cap_done={cap_done_id,cap_done_scope,cap_outcome,cap_failed_stage,cap_reason,cap_raw_pairs,cap_rgb_pairs,cap_written_lines,cap_discarded_rgb,cap_logical_bytes,cap_physical_bytes};
            held_aw=m_axi_awvalid&&!m_axi_awready; saved_aw={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst};
            held_ar=m_axi_arvalid&&!m_axi_arready; saved_ar={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst};
            held_w=m_axi_wvalid&&!m_axi_wready; saved_w={m_axi_wdata,m_axi_wstrb,m_axi_wlast};
            held_grad=grad_valid&&!grad_ready; saved_grad=grad_payload; held_fp=reader_v&&!reader_r; saved_fp={reader_id,reader_fp};
            held_display=display_data_valid&&!display_data_ready; saved_display=display_data;
            if(cap_job_valid&&cap_job_ready)begin capture_jobs++; $fwrite(event_fd,"%0d\t%0d\tCAP_START\t%h %h %h\n",case_id,cycles,cap_base,cap_handle,cap_scope); end
            if(alg_job_valid&&alg_job_ready)begin algorithm_jobs++; alg_running=1; $fwrite(event_fd,"%0d\t%0d\tALG_START\t%h %h %h\n",case_id,cycles,alg_cj,alg_origin,alg_handle); end
            if(cap_done_valid&&cap_done_ready)begin capture_done++; $fwrite(event_fd,"%0d\t%0d\tCAP_DONE\t%h %h %h %h %h %h %h %h %h %h\n",case_id,cycles,cap_done_id,cap_done_scope,cap_outcome,cap_reason,cap_raw_pairs,cap_rgb_pairs,cap_written_lines,cap_discarded_rgb,cap_logical_bytes,cap_physical_bytes); end
            if(alg_done_valid&&alg_done_ready)begin algorithm_done++; alg_running=0; $fwrite(event_fd,"%0d\t%0d\tALG_DONE\t%h %h %h %h %h %h %h %h %h %h\n",case_id,cycles,alg_done_scope,alg_done_origin,alg_outcome,alg_reason,reader_pairs,canny_input,canny_class,output_pixels,edge_pixels,discarded_fp); end
            if(in_valid&&in_ready&&alg_running&&!alg_done_valid)begin raw_overlap++;case_raw_overlap++;end
            if(reader_v&&reader_r)begin
                if(record_math)begin if(actual_fp>=P||reader_fp!==fp_values[actual_fp]||reader_id!=locked_handle)$fatal(1,"Source reader mathematical FP mismatch"); $fwrite(fp_fd,"%019h\n",reader_fp); end
                actual_fp++;
            end
            if(grad_valid&&grad_ready)begin
                if(record_math)begin if(!locked_cj[141]||actual_grad>=P||grad_payload!==grad_values[actual_grad])$fatal(1,"Algorithm mathematical gradient mismatch"); $fwrite(grad_fd,"%047h\n",grad_payload); end
                actual_grad++;
            end
            if(m_axi_awvalid&&m_axi_awready)begin aw_count++;$fwrite(event_fd,"%0d\t%0d\tAW\t%h %h %h %h %h\n",case_id,cycles,m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst);end
            if(m_axi_wvalid&&m_axi_wready)begin w_count++;$fwrite(event_fd,"%0d\t%0d\tW\t%h %h %h\n",case_id,cycles,m_axi_wdata,m_axi_wstrb,m_axi_wlast);end
            if(m_axi_bvalid&&m_axi_bready)begin b_count++;$fwrite(event_fd,"%0d\t%0d\tB\t%h %h\n",case_id,cycles,m_axi_bid,m_axi_bresp);end
            if(m_axi_arvalid&&m_axi_arready)begin if(m_axi_arid==2)display_ar++;else algorithm_ar++;$fwrite(event_fd,"%0d\t%0d\tAR\t%h %h %h %h %h\n",case_id,cycles,m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst);end
            if(m_axi_rvalid&&m_axi_rready)begin r_count++;$fwrite(event_fd,"%0d\t%0d\tR\t%h %h %h %h\n",case_id,cycles,m_axi_rid,m_axi_rresp,m_axi_rlast,m_axi_rdata);end
            if(reading&&(writing||b_pending))begin physical_overlap++;if(!was_overlap)$fwrite(event_fd,"%0d\t%0d\tPHYSICAL_OVERLAP\t1\n",case_id,cycles);was_overlap=1;end else was_overlap=0;
        end
        if(cycles-case_start>1000*N+300000)$fatal(1,"Actors watchdog case=%0d phase=%0d Q=%b",case_id,alg_phase,quarantined);
        if(cycles%5000000==0)$display("PROGRESS cycles=%0d case=%0d phase=%0d FP=%0d RAW_overlap=%0d",cycles,case_id,alg_phase,actual_fp,raw_overlap);
    end
    task automatic reset_joint(input integer id);
        @(negedge clk);case_id=id;case_start=cycles;rst=1;axi_enable=1;
        cap_job_valid=0;alg_job_valid=0;in_valid=0;in_bad=0;cap_cancel_valid=0;alg_cancel_valid=0;cap_done_ready=0;alg_done_ready=0;
        span_req_valid=0;display_enable=1;display_cancel=0;display_done_ready=0;
        hold_aw=0;hold_w=0;hold_ar=0;hold_b=0;hold_r=0;fault_kind=0;record_math=0;actual_fp=0;actual_grad=0;case_raw_overlap=0;
        source_base=SB;class_base=CB;queue_base=QB;result_base=EB;
        repeat(3)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic read_case(input integer ordinal,input bit replay,
        output logic [141:0] cj,output logic [194:0] origin,output logic [63:0] handle,
        output integer bayer,edges,retain);
        integer fd,index;fd=$fopen({directory,replay?"/replay.txt":ordinal<0?"/capture-b.txt":"/cases.txt"},"r");index=0;
        do begin ignored=$fscanf(fd,"%h %h %h %d %d %d\n",cj,origin,handle,bayer,edges,retain);if(ignored!=6)$fatal(1,"Vector case parse");end while(index++<ordinal);
        $fclose(fd);
    endtask
    task automatic load_capture(input integer ordinal,input integer address);
        logic [141:0] cj;logic [194:0] origin;logic [63:0] handle;integer bayer,edges,retain;
        read_case(ordinal,0,cj,origin,handle,bayer,edges,retain);
        cap_base=32'(address);cap_handle=handle;cap_scope=cj[95:0];cap_bayer=2'(bayer);
        locked_cap_handle=handle;locked_cap_scope=cj[95:0];
        if(ordinal<0)$readmemh({directory,"/capture-b.raw"},raw_values);
        else $readmemh($sformatf("%s/case-%0d.raw",directory,ordinal),raw_values);
    endtask
    task automatic load_algorithm(input integer ordinal,input bit replay=0);
        integer bayer,retain;string stem;
        read_case(ordinal,replay,alg_cj,alg_origin,alg_handle,bayer,expected_edges,retain);
        locked_cj=alg_cj;locked_origin=alg_origin;locked_handle=alg_handle;
        stem=replay?"replay":$sformatf("case-%0d",ordinal);
        $readmemh({directory,"/",stem,".fp"},fp_values);
        if(retain)$readmemh({directory,"/",stem,".grad"},grad_values);
        actual_fp=0;actual_grad=0;
    endtask
    task automatic start_capture;
        @(negedge clk);cap_job_valid=1;do @(posedge clk);while(!cap_job_ready);
        @(negedge clk);cap_job_valid=0;
        // 接受后扰动当前配置输入：执行模块必须使用自己的锁定上下文。
        cap_base=32'hfffffff1;cap_handle=~cap_handle;cap_scope=~cap_scope;cap_bayer=~cap_bayer;
    endtask
    task automatic start_algorithm;
        @(negedge clk);alg_job_valid=1;do @(posedge clk);while(!alg_job_ready);
        @(negedge clk);alg_job_valid=0;
        alg_cj=~alg_cj;alg_origin=~alg_origin;alg_handle=~alg_handle;
        source_base=32'hffffffff;class_base=32'hffffffff;queue_base=32'hffffffff;result_base=32'hffffffff;
    endtask
    task automatic feed_raw;
        for(integer index=0;index<P;index++)begin
            @(negedge clk);in_valid=1;raw_pair=raw_values[index];in_handle=locked_cap_handle;
            in_x_even=11'(2*(index%(WIDTH/2)));in_y=11'(index/(WIDTH/2));
            in_markers={index==P-1,index%(WIDTH/2)==WIDTH/2-1,index==0};
            do @(posedge clk);while(!in_ready);
            @(negedge clk);in_valid=0;if(index%7==0)@(negedge clk);
        end
    endtask
    task automatic take_capture;
        while(!cap_done_valid)begin @(negedge clk);if(quarantined)$fatal(1,"Normal capture quarantined");end
        if(cap_outcome||cap_reason||cap_done_id!=locked_cap_handle||cap_done_scope!=locked_cap_scope||
            cap_raw_pairs!=P||cap_rgb_pairs!=P||cap_written_lines!=S/64||cap_discarded_rgb||cap_logical_bytes!=3*N||cap_physical_bytes!=S)$fatal(1,"Independent capture DONE mismatch");
        repeat(17)@(negedge clk);cap_done_ready=1;@(posedge clk);@(negedge clk);cap_done_ready=0;
    endtask
    task automatic take_algorithm(input integer expected);
        while(!alg_done_valid)begin @(negedge clk);if(quarantined)$fatal(1,"Unexpected algorithm Q");end
        if(alg_outcome!=expected||alg_done_scope!=locked_cj[95:0]||alg_done_origin!=locked_origin)$fatal(1,"Algorithm outcome/identity mismatch");
        repeat(19)@(negedge clk);alg_done_ready=1;@(posedge clk);@(negedge clk);alg_done_ready=0;
    endtask
    task automatic dump_bytes(input string file_name,input integer address,length);
        integer fd;fd=$fopen({directory,"/",file_name},"wb");for(integer i=0;i<length;i++)$fwrite(fd,"%c",slave.memory_bytes[address+i]);$fclose(fd);
    endtask
    task automatic save_algorithm(input integer id);
        integer fd;
        if(alg_outcome||alg_reason||reader_pairs!=P||canny_input!=P||canny_class!=P||output_pixels!=N||edge_pixels!=expected_edges||discarded_fp||actual_fp!=P||actual_grad!=(locked_cj[141]?P:0))$fatal(1,"Actual complete Canny mismatch");
        dump_bytes($sformatf("actual-%0d.source.bin",id),SB,S);dump_bytes($sformatf("actual-%0d.state.bin",id),CB,C);
        dump_bytes($sformatf("actual-%0d.queue.bin",id),QB,expected_edges*4);dump_bytes($sformatf("actual-%0d.result.bin",id),EB,E);
        fd=$fopen($sformatf("%s/actual-%0d.status",directory,id),"w");$fwrite(fd,"%0148h\n",r2_status_snapshot);$fclose(fd);
        $fclose(fp_fd);$fclose(grad_fd);record_math=0;
    endtask
    task automatic display_sweep(input integer id);
        integer offset,chunk,words_seen;offset=0;words_seen=0;
        display_fd=$fopen($sformatf("%s/actual-%0d.display.bin",directory,id),"wb");
        while(offset<S)begin
            @(negedge clk);span_addr=32'(SB+offset);chunk=S-offset>8192?8192:S-offset;span_bytes=14'(chunk);span_req_valid=1;
            do @(posedge clk);while(!span_req_ready);@(negedge clk);span_req_valid=0;
            while(!display_done_valid)begin
                @(posedge clk);if(display_data_valid&&display_data_ready)begin
                    if(words_seen>=S/16||display_data!==display_values[words_seen])$fatal(1,"Display actual captured Source mismatch");
                    for(integer b=0;b<16;b++)$fwrite(display_fd,"%c",display_data[b*8+:8]);words_seen++;
                end
                @(negedge clk);if(quarantined)$fatal(1,"Normal display Q");
            end
            if(display_outcome||display_reason||!display_drained)$fatal(1,"Display did not safely close");
            repeat(7)@(negedge clk);display_done_ready=1;@(posedge clk);@(negedge clk);display_done_ready=0;offset+=chunk;
        end
        if(words_seen!=S/16)$fatal(1,"Incomplete display Source sweep");$fclose(display_fd);
    endtask
    task automatic normal(input integer id);
        integer next_id;reset_joint(id);load_capture(id,SB);start_capture();feed_raw();take_capture();
        // 已有 SourceA 的显示期望来自独立数学生成，不从 slave 回读形成期望。
        $readmemh($sformatf("%s/case-%0d.display.hex",directory,id),display_values);
        load_algorithm(id);record_math=1;fp_fd=$fopen($sformatf("%s/actual-%0d.fp",directory,id),"w");grad_fd=$fopen($sformatf("%s/actual-%0d.grad",directory,id),"w");
        source_base=SB;class_base=CB;queue_base=QB;result_base=EB;start_algorithm();next_id=frame_count==1?-1:(id+1)%frame_count;
        load_capture(next_id,DB);start_capture();
        if(locked_cap_handle==locked_handle||locked_cap_scope[63:0]==locked_cj[63:0])$fatal(1,"Capture B must have a different frame identity");
        if(alg_done_valid)$fatal(1,"Capture B did not overlap active algorithm A");
        fork feed_raw();display_sweep(id);join
        while(!alg_done_valid)begin @(negedge clk);if(quarantined)$fatal(1,"Normal algorithm Q");end
        save_algorithm(id);take_capture();dump_bytes($sformatf("actual-%0d.source-b.bin",id),DB,S);
        $fwrite(event_fd,"%0d\t%0d\tRAW_DURING_ALGORITHM\t%0d\n",case_id,cycles,case_raw_overlap);
        if(!case_raw_overlap)$fatal(1,"No actual RAW accepted during algorithm");take_algorithm(0);normal_images++;
    endtask
    task automatic prepare_source(input integer id);
        reset_joint(id);load_capture(0,SB);start_capture();feed_raw();take_capture();load_algorithm(0);
        source_base=SB;class_base=CB;queue_base=QB;result_base=EB;
    endtask
    task automatic cancel_algorithm;
        @(negedge clk);alg_cancel_valid=1;alg_cancel_scope=locked_cj[95:0];@(posedge clk);@(negedge clk);alg_cancel_valid=0;
    endtask
    initial begin
        integer fd;string row;
        if(!$value$plusargs("RUN_DIR=%s",directory))$fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected FRAME ACTORS fatal probe");
        event_fd=$fopen({directory,"/axi-events.tsv"},"w");$fwrite(event_fd,"case\tcycle\tevent\tvalues\n");
        fd=$fopen({directory,"/cases.txt"},"r");frame_count=0;while(!$feof(fd))begin ignored=$fgets(row,fd);if(ignored>1)frame_count++;end $fclose(fd);
        for(integer i=0;i<frame_count;i++)normal(i);
        // 冻结 SourceA 重处理：无复位、无 cap job/RAW，改变 CJ 配置。
        @(negedge clk);case_id=100;case_start=cycles;load_algorithm(0,1);record_math=1;
        fp_fd=$fopen({directory,"/actual-100.fp"},"w");grad_fd=$fopen({directory,"/actual-100.grad"},"w");
        source_base=SB;class_base=CB;queue_base=QB;result_base=EB;start_algorithm();
        while(!alg_done_valid)begin @(negedge clk);if(quarantined)$fatal(1,"Replay Q");end save_algorithm(100);take_algorithm(0);replay_jobs++;
        if(TEST_PROTOCOL)begin
            for(integer id=201;id<=202;id++)begin
                reset_joint(id);load_algorithm(0);if(id==201)class_base=source_base;else begin alg_origin=alg_origin^(195'd1<<67);locked_origin=alg_origin;end
                start_algorithm();take_algorithm(1);protocol_cases++;
            end
            for(integer id=203;id<=204;id++)begin
                prepare_source(id);if(id==203)hold_ar=1;else hold_r=1;start_algorithm();
                if(id==203)while(!m_axi_arvalid)@(negedge clk);else while(!reading)@(negedge clk);
                cancel_algorithm();repeat(17)begin @(negedge clk);if(alg_done_valid)$fatal(1,"Cancel falsely closed held physical read");end
                hold_ar=0;hold_r=0;take_algorithm(2);protocol_cases++;
            end
            prepare_source(205);fault_kind=3;start_algorithm();take_algorithm(1);protocol_cases++;
            prepare_source(206);fault_kind=4;start_algorithm();while(!memory_quarantined)@(negedge clk);
            $fwrite(event_fd,"%0d\t%0d\tQ\t1\n",case_id,cycles);
            repeat(31)begin @(negedge clk);if(alg_done_valid||alg_job_ready||cap_job_ready)$fatal(1,"UNKNOWN read reused or falsely closed actor");end protocol_cases++;
            prepare_source(207);start_algorithm();while(!alg_done_valid)@(negedge clk);
            fault_kind=4;span_addr=SB;span_bytes=64;span_req_valid=1;do @(posedge clk);while(!span_req_ready);@(negedge clk);span_req_valid=0;
            while(!memory_quarantined)@(negedge clk);repeat(23)@(negedge clk);
            if(!alg_done_valid||alg_outcome||alg_reason)$fatal(1,"Unrelated late Q rewrote safe DONE");
            alg_done_ready=1;@(posedge clk);@(negedge clk);alg_done_ready=0;
            repeat(11)begin @(negedge clk);if(alg_job_ready||cap_job_ready)$fatal(1,"GlobalQ accepted next job");end protocol_cases++;
            prepare_source(208);start_algorithm();take_algorithm(0);protocol_cases++;
        end
        if(!raw_overlap||!physical_overlap)$fatal(1,"No actual actor/physical concurrency");
        finished=1;$fclose(event_fd);fd=$fopen({directory,"/protocol-metrics.json"},"w");
        $fwrite(fd,"{\"finished\":true,\"normal_images\":%0d,\"replay_jobs\":%0d,\"protocol_cases\":%0d,\"cycles\":%0d,\"capture_jobs\":%0d,\"algorithm_jobs\":%0d,\"capture_done\":%0d,\"algorithm_done\":%0d,\"aw\":%0d,\"w\":%0d,\"b\":%0d,\"algorithm_ar\":%0d,\"display_ar\":%0d,\"r\":%0d,\"raw_during_algorithm\":%0d,\"physical_overlap_cycles\":%0d}\n",normal_images,replay_jobs,protocol_cases,cycles,capture_jobs,algorithm_jobs,capture_done,algorithm_done,aw_count,w_count,b_count,algorithm_ar,display_ar,r_count,raw_overlap,physical_overlap);
        $fclose(fd);$finish;
    end
endmodule
