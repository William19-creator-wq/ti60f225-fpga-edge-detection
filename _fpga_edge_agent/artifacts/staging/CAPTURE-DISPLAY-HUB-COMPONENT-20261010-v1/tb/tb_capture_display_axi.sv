`timescale 1ns/1ps
// observer只连接actual reader/core公开端口，不从私有状态/数组取期望。
module public_reader_observer(input wire out_valid,out_ready,input wire [73:0] out_fp,input wire [63:0] out_id,
    output wire v,r,output wire [73:0] fp,output wire [63:0] id);
    assign v=out_valid;assign r=out_ready;assign fp=out_fp;assign id=out_id;
endmodule
bind rgb_frame_reader public_reader_observer reader_observer(
    .out_valid,.out_ready,.out_fp,.out_id,
    .v($root.tb_capture_display_axi.reader_v),.r($root.tb_capture_display_axi.reader_r),
    .fp($root.tb_capture_display_axi.reader_fp),.id($root.tb_capture_display_axi.reader_id)
);
module public_capture_rpc_observer(
    input wire camera_req_valid,camera_req_ready,input wire [31:0] camera_addr,input wire [511:0] camera_data,
    input wire algorithm_req_valid,algorithm_write,
    output wire camera_v,camera_r,output wire [31:0] addr,output wire [511:0] data,output wire algorithm_v,algorithm_w
);
    assign camera_v=camera_req_valid;assign camera_r=camera_req_ready;assign addr=camera_addr;assign data=camera_data;
    assign algorithm_v=algorithm_req_valid;assign algorithm_w=algorithm_write;
endmodule
bind capture_canny_rpc public_capture_rpc_observer rpc_observer(
    .camera_req_valid,.camera_req_ready,.camera_addr,.camera_data,.algorithm_req_valid,.algorithm_write,
    .camera_v($root.tb_capture_display_axi.camera_v),.camera_r($root.tb_capture_display_axi.camera_r),
    .addr($root.tb_capture_display_axi.camera_public_addr),.data($root.tb_capture_display_axi.camera_public_data),
    .algorithm_v($root.tb_capture_display_axi.algorithm_v),.algorithm_w($root.tb_capture_display_axi.algorithm_w)
);

module tb_capture_display_axi #(parameter integer TEST_WIDTH=34,TEST_HEIGHT=19,TEST_PROTOCOL=1);
    localparam integer WIDTH=TEST_WIDTH,HEIGHT=TEST_HEIGHT,N=WIDTH*HEIGHT,P=N/2;
    localparam integer S=((3*N+63)/64)*64,C=((N+255)/256)*64,Q=((N+15)/16)*64,E=((N+63)/64)*64;
    localparam integer SB=0,CB=S+64,QB=CB+C+64,EB=QB+Q+64,DB=EB+E+64,MEM=DB+S+64;
    logic clk=0,rst=1,finished=0,axi_enable=1;always #5 clk=~clk;
    logic job_valid=0;wire job_ready;logic [141:0] job_cj=0;logic [194:0] job_origin=0;logic [63:0] job_handle=0;logic [1:0] bayer_phase=0;
    logic [31:0] source_base=SB,class_base=CB,queue_base=QB,result_base=EB;
    logic in_valid=0,in_bad=0;wire in_ready;logic [19:0] raw_pair=0;logic [10:0] in_x_even=0,in_y=0;logic [2:0] in_markers=0;logic [63:0] in_handle=0;
    logic rx_close_valid=0,rx_close_good=1;wire rx_close_ready;logic [63:0] rx_close_handle=0;logic [194:0] rx_close_origin=0;
    logic cancel_valid=0;logic [95:0] cancel_scope=0;wire grad_valid;logic grad_ready=0;wire [184:0] grad_payload;
    wire done_valid,source_stop,quarantined;logic done_ready=0;wire [95:0] done_scope;wire [194:0] done_origin;wire [1:0] outcome;wire [31:0] reason;
    wire [21:0] source_pairs,output_pixels,edge_pixels,discarded_fp;wire [20:0] reader_pairs,canny_input,canny_class;wire [591:0] r2_status_snapshot;wire [3:0] phase;
    wire m_axi_awvalid,m_axi_wvalid,m_axi_wlast,m_axi_bready,m_axi_arvalid,m_axi_rready;
    wire m_axi_awready,m_axi_wready,m_axi_bvalid,m_axi_arready,m_axi_rvalid,m_axi_rlast;
    wire [31:0] m_axi_awaddr,m_axi_araddr;wire [3:0] m_axi_awid,m_axi_arid,m_axi_bid,m_axi_rid;
    wire [7:0] m_axi_awlen,m_axi_arlen;wire [2:0] m_axi_awsize,m_axi_arsize;wire [1:0] m_axi_awburst,m_axi_arburst,m_axi_bresp,m_axi_rresp;
    wire [127:0] m_axi_wdata,m_axi_rdata;wire [15:0] m_axi_wstrb;
    logic display_enable=1,display_cancel=0,span_req_valid=0;wire span_req_ready;
    logic [31:0] span_addr=DB;logic [13:0] span_bytes=0;wire display_data_valid;logic display_data_ready=0;wire [127:0] display_data;
    wire display_done_valid;logic display_done_ready=0;wire [1:0] display_outcome;wire [7:0] display_reason;wire display_drained;
    wire memory_quarantined,algorithm_live,read_occupied,read_physical_idle,write_busy,read_quarantined,write_quarantined,direction_quarantined;
    wire [2:0] read_fault_reason,write_fault_reason;
    logic random_stalls=1,hold_aw=0,hold_w=0,hold_ar=0,hold_b=0,hold_r=0,hold_grad=0,hold_display=0;integer fault_kind=0;
    wire writing,b_pending,reading;
    capture_display_axi #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ADDRESS_BYTES(33'(MEM))) dut(.*);
    axi128_duplex_byte_memory #(.BYTES(MEM),.CLASS_BASE(CB),.CLASS_BYTES(C)) slave(.*);
    wire reader_v,reader_r,camera_v,camera_r,algorithm_v,algorithm_w;wire [73:0] reader_fp;wire [63:0] reader_id;
    wire [31:0] camera_public_addr;wire [511:0] camera_public_data;
    logic [19:0] raw_values[0:P-1];logic [73:0] fp_values[0:P-1];logic [184:0] grad_values[0:P-1];logic [127:0] display_values[0:S/16-1];
    logic [141:0] locked_cj;logic [194:0] locked_origin;logic [63:0] locked_handle;integer expected_edges;
    integer cycles=0,case_start=0,case_id=0,normal_count=0,protocol_count=0,actual_raw=0,actual_fp=0,actual_grad=0;
    integer fp_fd=0,grad_fd=0,display_fd=0,event_fd=0,result_fd=0,metrics_fd,meta_fd,ignored,frame_count;
    integer aws=0,words=0,bs=0,algorithm_ars=0,display_ars=0,rs=0,display_words=0,overlap_cycles=0,read_competition=0;
    integer aw_stalls=0,ar_stalls=0,w_stalls=0,r_stalls=0,grad_stalls=0,done_stalls=0,display_stalls=0;
    bit record_normal=0,reset_logged=0,was_overlap=0,held_done=0,held_aw=0,held_ar=0,held_w=0,held_grad=0,held_fp=0,held_camera=0,held_display=0,held_display_done=0;
    logic [1067:0] saved_done;logic [48:0] saved_aw,saved_ar;logic [144:0] saved_w;logic [184:0] saved_grad;
    logic [137:0] saved_fp;logic [543:0] saved_camera;logic [127:0] saved_display;logic [10:0] saved_display_done;
    logic [31:0] rng=32'hb7560187;string directory;
    always @(negedge clk)begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        grad_ready=!rst&&!hold_grad&&rng[2:0]!=0;
        display_data_ready=!rst&&!hold_display&&rng[5:3]!=0;
    end
    always @(posedge clk)if(event_fd)begin
        cycles++;
        if(rst)begin
            if(!reset_logged)$fwrite(event_fd,"%0d\t%0d\tRESET\t0\n",case_id,cycles);
            reset_logged=1;was_overlap=0;held_done=0;held_aw=0;held_ar=0;held_w=0;held_grad=0;held_fp=0;held_camera=0;held_display=0;held_display_done=0;
        end else begin
            reset_logged=0;
            if(held_done&&(!done_valid||saved_done!=={done_scope,done_origin,outcome,reason,source_pairs,reader_pairs,canny_input,canny_class,output_pixels,edge_pixels,discarded_fp,r2_status_snapshot}))$fatal(1,"Public capture DONE changed");
            if(held_aw&&(!m_axi_awvalid||saved_aw!=={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst}))$fatal(1,"AW holding changed");
            if(held_ar&&(!m_axi_arvalid||saved_ar!=={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst}))$fatal(1,"AR holding changed");
            if(held_w&&(!m_axi_wvalid||saved_w!=={m_axi_wdata,m_axi_wstrb,m_axi_wlast}))$fatal(1,"W holding changed");
            if(held_grad&&(!grad_valid||saved_grad!==grad_payload))$fatal(1,"Gradient holding changed");
            if(held_fp&&(!reader_v||saved_fp!=={reader_id,reader_fp}))$fatal(1,"Public reader FP changed");
            if(held_camera&&(!camera_v||saved_camera!=={camera_public_addr,camera_public_data}))$fatal(1,"Camera PUBLIC packet changed");
            if(held_display&&(!display_data_valid||saved_display!==display_data))$fatal(1,"Display data holding changed");
            if(held_display_done&&(!display_done_valid||saved_display_done!=={display_outcome,display_reason,display_drained}))$fatal(1,"Display DONE holding changed");
            held_done=done_valid&&!done_ready;saved_done={done_scope,done_origin,outcome,reason,source_pairs,reader_pairs,canny_input,canny_class,output_pixels,edge_pixels,discarded_fp,r2_status_snapshot};
            held_aw=m_axi_awvalid&&!m_axi_awready;saved_aw={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst};
            held_ar=m_axi_arvalid&&!m_axi_arready;saved_ar={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst};
            held_w=m_axi_wvalid&&!m_axi_wready;saved_w={m_axi_wdata,m_axi_wstrb,m_axi_wlast};held_grad=grad_valid&&!grad_ready;saved_grad=grad_payload;
            held_fp=reader_v&&!reader_r;saved_fp={reader_id,reader_fp};held_camera=camera_v&&!camera_r;saved_camera={camera_public_addr,camera_public_data};
            held_display=display_data_valid&&!display_data_ready;saved_display=display_data;
            held_display_done=display_done_valid&&!display_done_ready;saved_display_done={display_outcome,display_reason,display_drained};
            if(in_valid&&in_ready)actual_raw++;
            if(reader_v&&reader_r)begin
                if(record_normal)begin if(actual_fp>=P||reader_fp!==fp_values[actual_fp]||reader_id!=locked_handle)$fatal(1,"Actual producer FP differs from RAW math");$fwrite(fp_fd,"%019h\n",reader_fp);end
                actual_fp++;
            end
            if(grad_valid&&grad_ready)begin
                if(record_normal)begin if(!locked_cj[141]||actual_grad>=P||grad_payload!==grad_values[actual_grad])$fatal(1,"Actual producer gradient differs");$fwrite(grad_fd,"%047h\n",grad_payload);end
                actual_grad++;
            end
            if(m_axi_awvalid&&m_axi_awready)begin aws++;$fwrite(event_fd,"%0d\t%0d\tAW\t%h %h %h %h %h\n",case_id,cycles,m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst);end
            if(m_axi_wvalid&&m_axi_wready)begin words++;$fwrite(event_fd,"%0d\t%0d\tW\t%h %h %b\n",case_id,cycles,m_axi_wdata,m_axi_wstrb,m_axi_wlast);end
            if(m_axi_bvalid&&m_axi_bready)begin bs++;$fwrite(event_fd,"%0d\t%0d\tB\t%h %h\n",case_id,cycles,m_axi_bid,m_axi_bresp);end
            if(m_axi_arvalid&&m_axi_arready)begin
                if(m_axi_arid==2)display_ars++;else algorithm_ars++;
                $fwrite(event_fd,"%0d\t%0d\tAR\t%h %h %h %h %h\n",case_id,cycles,m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst);
            end
            if(m_axi_rvalid&&m_axi_rready)begin rs++;$fwrite(event_fd,"%0d\t%0d\tR\t%h %h %b %h\n",case_id,cycles,m_axi_rid,m_axi_rresp,m_axi_rlast,m_axi_rdata);end
            if(reading&&(writing||b_pending))begin overlap_cycles++;if(!was_overlap)$fwrite(event_fd,"%0d\t%0d\tOVERLAP\t1\n",case_id,cycles);was_overlap=1;end else was_overlap=0;
            if(algorithm_v&&!algorithm_w&&reading&&slave.read_identity==2)read_competition++;
            if(m_axi_awvalid&&!m_axi_awready)aw_stalls++;if(m_axi_arvalid&&!m_axi_arready)ar_stalls++;if(m_axi_wvalid&&!m_axi_wready)w_stalls++;if(m_axi_rvalid&&!m_axi_rready)r_stalls++;
            if(grad_valid&&!grad_ready)grad_stalls++;if(done_valid&&!done_ready)done_stalls++;if(display_data_valid&&!display_data_ready)display_stalls++;
            if(display_data_valid&&display_data_ready)display_words++;
        end
        if(cycles-case_start>1000*N+300000)$fatal(1,"Capture/display watchdog case=%0d phase=%0d Q=%b alg_live=%b WR=%b RD=%b",case_id,phase,quarantined,algorithm_live,write_busy,read_occupied);
        if(cycles%5000000==0)$display("PROGRESS cycles=%0d phase=%0d RAW=%0d FP=%0d AR0=%0d AR2=%0d",cycles,phase,actual_raw,actual_fp,algorithm_ars,display_ars);
    end
    task automatic reset_joint(input integer id);
        @(negedge clk);case_id=id;case_start=cycles;rst=1;axi_enable=1;job_valid=0;in_valid=0;in_bad=0;rx_close_valid=0;cancel_valid=0;done_ready=0;
        display_enable=1;display_cancel=0;span_req_valid=0;display_done_ready=0;
        hold_aw=0;hold_ar=0;hold_w=0;hold_b=0;hold_r=0;hold_grad=0;hold_display=0;fault_kind=0;record_normal=0;
        source_base=SB;class_base=CB;queue_base=QB;result_base=EB;actual_raw=0;actual_fp=0;actual_grad=0;
        repeat(3)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic load_case(input integer ordinal);
        integer fd,index,phase_value,retain;logic [141:0] cj;logic [194:0] origin;logic [63:0] handle;
        fd=$fopen({directory,"/cases.txt"},"r");index=0;
        do begin ignored=$fscanf(fd,"%h %h %h %d %d %d\n",cj,origin,handle,phase_value,expected_edges,retain);if(ignored!=6)$fatal(1,"Case parse");end while(index++<ordinal);$fclose(fd);
        job_cj=cj;job_origin=origin;job_handle=handle;bayer_phase=2'(phase_value);locked_cj=cj;locked_origin=origin;locked_handle=handle;
        $readmemh($sformatf("%s/case-%0d.raw",directory,ordinal),raw_values);$readmemh($sformatf("%s/case-%0d.fp",directory,ordinal),fp_values);
        if(retain)$readmemh($sformatf("%s/case-%0d.grad",directory,ordinal),grad_values);
    endtask
    task automatic start_job;
        @(negedge clk);job_valid=1;do @(posedge clk);while(job_ready!==1'b1);
        @(negedge clk);job_valid=0;job_cj=0;job_origin='1;job_handle=0;bayer_phase=bayer_phase^3;
    endtask
    task automatic feed_raw(input integer defect=0);
        for(integer i=0;i<P;i++)begin
            @(negedge clk);if(source_stop)break;
            raw_pair=raw_values[i];in_x_even=11'((i%(WIDTH/2))*2);in_y=11'(i/(WIDTH/2));in_handle=locked_handle;
            in_markers={i==P-1,i%(WIDTH/2)==WIDTH/2-1,i==0};in_bad=0;
            if(defect&&i==0)case(defect)1:in_bad=1;2:in_handle=locked_handle^1;3:in_x_even=2;4:in_markers=in_markers^1;endcase
            in_valid=1;do @(posedge clk);while(in_ready!==1'b1&&source_stop!==1'b1);
            @(negedge clk);in_valid=0;in_bad=0;if(source_stop)break;
        end
    endtask
    task automatic close_rx(input bit good=1,input integer wrong=0);
        @(negedge clk);rx_close_valid=1;rx_close_good=good;rx_close_handle=locked_handle^(wrong==1?64'd1:64'd0);
        rx_close_origin=locked_origin^(wrong==2?(195'd1<<131):195'd0);
        do @(posedge clk);while(rx_close_ready!==1'b1);@(negedge clk);rx_close_valid=0;
    endtask
    task automatic capture_ready;
        integer ticks;ticks=0;while(phase!=2||!in_ready)begin @(negedge clk);if(ticks++>2000||done_valid||quarantined)$fatal(1,"Capture startup failed");end
    endtask
    task automatic dump_bytes(input string name,input integer address,length,input bit first_classes=0);
        integer fd;fd=$fopen({directory,"/",name},"wb");if(!fd)$fatal(1,"Dump open");
        for(integer i=0;i<length;i++)begin
            if(first_classes)begin if(!slave.class_written[i/64])$fatal(1,"Initial class line not physically written");$fwrite(fd,"%c",slave.first_class_bytes[i]);end
            else $fwrite(fd,"%c",slave.memory_bytes[address+i]);
        end
        $fclose(fd);
    endtask
    task automatic display_sweep;
        integer offset,chunk,words_seen;offset=0;words_seen=0;
        while(offset<S)begin
            @(negedge clk);span_addr=32'(DB+offset);chunk=S-offset>8192?8192:S-offset;span_bytes=14'(chunk);span_req_valid=1;
            do @(posedge clk);while(span_req_ready!==1'b1);@(negedge clk);span_req_valid=0;
            while(!display_done_valid)begin
                @(posedge clk);
                if(display_data_valid&&display_data_ready)begin
                    if(words_seen>=S/16||display_data!==display_values[words_seen])$fatal(1,"Display actual Source bytes mismatch");
                    for(integer b=0;b<16;b++)$fwrite(display_fd,"%c",display_data[b*8+:8]);words_seen++;
                end
                @(negedge clk);if(quarantined)$fatal(1,"Normal display caused Q");
            end
            if(display_outcome||display_reason||!display_drained)$fatal(1,"Display normal notice unsafe");
            repeat(7)@(negedge clk);display_done_ready=1;@(posedge clk);@(negedge clk);display_done_ready=0;offset+=chunk;
        end
        if(words_seen!=S/16)$fatal(1,"Incomplete display sweep");
    endtask
    task automatic take_done(input integer expected);
        while(!done_valid)begin @(negedge clk);if(quarantined)$fatal(1,"Unexpected capture Q");end
        if(outcome!=expected||done_scope!=locked_cj[95:0]||done_origin!=locked_origin)$fatal(1,"Capture outcome/identity mismatch");
        repeat(19)@(negedge clk);done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;
    endtask
    task automatic normal(input integer id);
        integer fd;reset_joint(id);load_case(id);record_normal=1;
        fp_fd=$fopen($sformatf("%s/actual-%0d.fp",directory,id),"w");grad_fd=$fopen($sformatf("%s/actual-%0d.grad",directory,id),"w");
        display_fd=$fopen($sformatf("%s/actual-%0d.display.bin",directory,id),"wb");start_job();capture_ready();
        fork
            feed_raw();close_rx();
            begin display_sweep();while(phase<4)@(negedge clk);display_sweep();end
        join
        while(!done_valid)begin @(negedge clk);if(quarantined)$fatal(1,"Normal producer Q");end
        if(outcome||reason||source_pairs!=P||reader_pairs!=P||canny_input!=P||canny_class!=P||output_pixels!=N||edge_pixels!=expected_edges||discarded_fp)$fatal(1,"Normal actual pipeline count mismatch");
        if(actual_fp!=P||actual_raw!=P||actual_grad!=(locked_cj[141]?P:0))$fatal(1,"Actual producer public count");
        dump_bytes($sformatf("actual-%0d.source.bin",id),SB,S);dump_bytes($sformatf("actual-%0d.class.bin",id),0,C,1);
        dump_bytes($sformatf("actual-%0d.state.bin",id),CB,C);dump_bytes($sformatf("actual-%0d.queue.bin",id),QB,expected_edges*4);dump_bytes($sformatf("actual-%0d.result.bin",id),EB,E);
        fd=$fopen($sformatf("%s/actual-%0d.status",directory,id),"w");$fwrite(fd,"%0148h\n",r2_status_snapshot);$fclose(fd);
        fd=$fopen($sformatf("%s/actual-%0d.origin",directory,id),"w");$fwrite(fd,"%049h\n",done_origin);$fclose(fd);
        $fwrite(result_fd,"%0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d\n",id,outcome,reason,source_pairs,reader_pairs,canny_input,canny_class,output_pixels,edge_pixels,discarded_fp,cycles-case_start);
        $fclose(fp_fd);$fclose(grad_fd);$fclose(display_fd);record_normal=0;take_done(0);normal_count++;
    endtask
    task automatic cancel_once;
        @(negedge clk);cancel_valid=1;cancel_scope=locked_cj[95:0];@(posedge clk);@(negedge clk);cancel_valid=0;
    endtask
    task automatic one_span(input integer bytes=64);
        @(negedge clk);span_addr=DB;span_bytes=14'(bytes);span_req_valid=1;
        do @(posedge clk);while(span_req_ready!==1'b1);@(negedge clk);span_req_valid=0;display_done_ready=1;
    endtask
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",directory))$fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected CAPTURE HUB fatal probe");
        event_fd=$fopen({directory,"/axi-events.tsv"},"w");result_fd=$fopen({directory,"/actual-results.txt"},"w");if(!event_fd||!result_fd)$fatal(1,"Trace open");
        $fwrite(event_fd,"case\tcycle\tevent\tvalues\n");$readmemh({directory,"/expected-display.hex"},display_values);
        meta_fd=$fopen({directory,"/cases.txt"},"r");frame_count=0;while(!$feof(meta_fd))begin string row;ignored=$fgets(row,meta_fd);if(ignored>1)frame_count++;end $fclose(meta_fd);
        for(integer i=0;i<frame_count;i++)normal(i);
        if(TEST_PROTOCOL)begin
            for(integer id=101;id<=102;id++)begin
                reset_joint(id);load_case(0);if(id==101)class_base=source_base;else begin job_origin=job_origin^(195'd1<<67);locked_origin=job_origin;end
                start_job();take_done(1);protocol_count++;
            end
            for(integer defect=1;defect<=4;defect++)begin
                reset_joint(102+defect);load_case(0);start_job();capture_ready();fork feed_raw(defect);close_rx();join take_done(1);protocol_count++;
            end
            reset_joint(107);load_case(0);start_job();capture_ready();fork feed_raw();close_rx(0);join take_done(1);protocol_count++;
            reset_joint(108);load_case(0);start_job();capture_ready();feed_raw();close_rx(1,1);while(phase!=3)@(negedge clk);
            repeat(17)begin @(negedge clk);if(done_valid)$fatal(1,"Wrong RX handle falsely closed");end close_rx();take_done(0);protocol_count++;
            for(integer id=109;id<=111;id++)begin
                reset_joint(id);load_case(0);if(id==109)hold_aw=1;if(id==110)hold_w=1;if(id==111)hold_b=1;start_job();capture_ready();
                fork
                    feed_raw();close_rx();
                    begin
                        if(id==109)while(!m_axi_awvalid)@(negedge clk);
                        if(id==110)while(!m_axi_wvalid)@(negedge clk);
                        if(id==111)while(!b_pending)@(negedge clk);
                        cancel_once();repeat(17)begin @(negedge clk);if(done_valid)$fatal(1,"Cancel falsely drained held write");end hold_aw=0;hold_w=0;hold_b=0;
                    end
                join take_done(2);protocol_count++;
            end
            reset_joint(112);load_case(0);fault_kind=1;start_job();capture_ready();fork feed_raw();close_rx();join take_done(1);protocol_count++;
            reset_joint(113);load_case(0);hold_ar=1;start_job();capture_ready();fork feed_raw();close_rx();join
            while(!m_axi_arvalid)@(negedge clk);cancel_once();repeat(17)begin @(negedge clk);if(done_valid)$fatal(1,"Cancel withdrew held AR");end hold_ar=0;take_done(2);protocol_count++;
            reset_joint(114);load_case(0);hold_r=1;start_job();capture_ready();fork feed_raw();close_rx();join
            while(!reading)@(negedge clk);cancel_once();repeat(17)@(negedge clk);hold_r=0;take_done(2);protocol_count++;
            // 跨通道Q：已承诺camera AW/W/B必须继续，不把readQ当write enable下降。
            reset_joint(115);load_case(0);hold_aw=1;fault_kind=4;start_job();capture_ready();
            fork feed_raw();close_rx();begin while(!m_axi_awvalid)@(negedge clk);one_span();end join
            while(!memory_quarantined)@(negedge clk);hold_aw=0;repeat(90)@(negedge clk);
            if(done_valid||job_ready||write_quarantined||write_busy)$fatal(1,"Read Q corrupted old safe write or falsely released job");protocol_count++;
            // 未接纳PUBLIC：真实backend暂不可用，old display read完成/出错之后不得偷接camera。
            reset_joint(116);load_case(0);hold_r=1;start_job();capture_ready();one_span();while(!reading)@(negedge clk);axi_enable=0;fault_kind=4;
            fork feed_raw();begin while(!camera_v)@(negedge clk);hold_r=0;end join
            while(!memory_quarantined)@(negedge clk);axi_enable=1;repeat(41)begin @(negedge clk);if(!camera_v||camera_r||done_valid||job_ready)$fatal(1,"Unaccepted camera PUBLIC falsely closed");end protocol_count++;
            // J1：在safe full-job DONE已公开之后出现无关displayQ，原正文仍保持可消费。
            reset_joint(117);load_case(0);start_job();capture_ready();fork feed_raw();close_rx();join while(!done_valid)@(negedge clk);
            fault_kind=4;one_span();while(!memory_quarantined)@(negedge clk);repeat(29)@(negedge clk);
            if(!done_valid||outcome||reason)$fatal(1,"Unrelated late display Q rewrote safe DONE");done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;
            repeat(17)begin @(negedge clk);if(job_ready||done_valid)$fatal(1,"GlobalQ reused closed capture job");end protocol_count++;
            reset_joint(118);load_case(0);start_job();capture_ready();hold_aw=1;fork feed_raw();begin while(!m_axi_awvalid)@(negedge clk);end join
            reset_joint(119);load_case(0);start_job();capture_ready();fork feed_raw();close_rx();join take_done(0);protocol_count++;
        end
        if(!overlap_cycles||!read_competition)$fatal(1,"Actual clients never exercised duplex/real read contention");
        finished=1;$fclose(event_fd);$fclose(result_fd);metrics_fd=$fopen({directory,"/protocol-metrics.json"},"w");
        $fwrite(metrics_fd,"{\"finished\":true,\"normal_images\":%0d,\"protocol_cases\":%0d,\"cycles\":%0d,\"aw\":%0d,\"w\":%0d,\"b\":%0d,\"algorithm_ar\":%0d,\"display_ar\":%0d,\"r\":%0d,\"display_words\":%0d,\"physical_read_write_overlap\":%0d,\"actual_read_contention\":%0d,\"aw_stalls\":%0d,\"ar_stalls\":%0d,\"w_stalls\":%0d,\"r_stalls\":%0d,\"grad_stalls\":%0d,\"done_stalls\":%0d,\"display_stalls\":%0d}\n",
            normal_count,protocol_count,cycles,aws,words,bs,algorithm_ars,display_ars,rs,display_words,overlap_cycles,read_competition,aw_stalls,ar_stalls,w_stalls,r_stalls,grad_stalls,done_stalls,display_stalls);
        $fclose(metrics_fd);$finish;
    end
endmodule
