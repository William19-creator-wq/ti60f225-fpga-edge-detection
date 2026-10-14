`timescale 1ns/1ps
// 只观察rgb_source_writer的公开端口；不读取carry/bank/packet等内部状态。
module rgb_source_public_monitor(
    input wire clk,rst,job_valid,job_ready,in_valid,in_ready,
    input wire [31:0] job_base,line_addr,input wire [63:0] job_handle,
    input wire line_req_valid,line_req_ready,line_rsp_valid,line_rsp_ready,line_error,line_drained,
    input wire [511:0] line_wdata,
    output wire observed_request,observed_response,observed_job_fire,observed_pixel_fire
);
    assign observed_request=line_req_valid;assign observed_response=line_rsp_valid;
    assign observed_job_fire=job_valid&&job_ready;assign observed_pixel_fire=in_valid&&in_ready;
    integer fd;string directory;bit held=0,was_valid=0;logic [543:0] saved;
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",directory))$fatal(1,"Monitor RUN_DIR missing");
        if(!$test$plusargs("FATAL_PROBE"))begin
            fd=$fopen({directory,"/source-public.tsv"},"w");if(!fd)$fatal(1,"Public trace open");
            $fwrite(fd,"case\tcycle\tevent\tvalues\n");
        end
    end
    always @(posedge clk)if(fd)begin
        if(rst)begin held=0;was_valid=0;end
        else begin
            if(held && (!line_req_valid || {line_addr,line_wdata}!==saved))$fatal(1,"Source PUBLIC request changed before acceptance");
            if(observed_job_fire)$fwrite(fd,"%0d\t%0d\tJ\t%h %h\n",$root.tb_rgb_axi_write_join.case_id,$root.tb_rgb_axi_write_join.cycle,job_base,job_handle);
            if(line_req_valid&&!was_valid)$fwrite(fd,"%0d\t%0d\tE\t%h %h\n",$root.tb_rgb_axi_write_join.case_id,$root.tb_rgb_axi_write_join.cycle,line_addr,line_wdata);
            if(line_req_valid&&line_req_ready)$fwrite(fd,"%0d\t%0d\tL\t%h %h\n",$root.tb_rgb_axi_write_join.case_id,$root.tb_rgb_axi_write_join.cycle,line_addr,line_wdata);
            if(line_rsp_valid&&line_rsp_ready)$fwrite(fd,"%0d\t%0d\tR\t%b %b\n",$root.tb_rgb_axi_write_join.case_id,$root.tb_rgb_axi_write_join.cycle,line_error,line_drained);
            held=line_req_valid&&!line_req_ready;saved={line_addr,line_wdata};was_valid=line_req_valid;
        end
    end
endmodule
bind rgb_source_writer rgb_source_public_monitor public_observer(
    .clk,.rst,.job_valid,.job_ready,.in_valid,.in_ready,.job_base,.job_handle,
    .line_addr,.line_req_valid,.line_req_ready,.line_rsp_valid,.line_rsp_ready,.line_error,.line_drained,.line_wdata,
    .observed_request($root.tb_rgb_axi_write_join.source_public_valid),
    .observed_response($root.tb_rgb_axi_write_join.source_response_valid),
    .observed_job_fire($root.tb_rgb_axi_write_join.source_job_fire),
    .observed_pixel_fire($root.tb_rgb_axi_write_join.source_pixel_fire)
);

module tb_rgb_axi_write_join #(
    parameter integer TEST_WIDTH=34,TEST_HEIGHT=19,TEST_PROTOCOL=1
);
    localparam integer PAIRS=TEST_WIDTH*TEST_HEIGHT/2,LOGICAL=TEST_WIDTH*TEST_HEIGHT*3;
    localparam integer ALLOCATION=((LOGICAL+63)/64)*64,MAX_ALGO=4096;
    logic clk=0,rst=1,backend_enable=1;always #5 clk=~clk;
    logic job_valid=0,job_rsp_ready=0,in_valid=0,in_bad=0,cancel_valid=0,done_ready=0;
    logic [31:0] job_base=0;logic [63:0] job_handle=0,in_handle=0,cancel_id=0;
    logic [47:0] in_rgb=0;logic [10:0] in_x_even=0,in_y=0;logic [2:0] in_markers=0;
    wire job_ready,job_rsp_valid,job_rsp_error,in_ready,done_valid;
    wire [63:0] done_id;wire [1:0] outcome;wire [7:0] reason;
    wire [21:0] accepted_pairs,written_lines;wire [31:0] logical_bytes,physical_bytes;
    logic algo_req_valid=0,algo_rsp_ready=0;logic [31:0] algo_addr=0;logic [511:0] algo_data=0;
    wire algo_req_ready,algo_rsp_valid,algo_error,algo_drained;
    wire m_axi_awvalid,m_axi_wvalid,m_axi_wlast,m_axi_bready;
    logic m_axi_awready=0,m_axi_wready=0,m_axi_bvalid=0;
    wire [31:0] m_axi_awaddr;wire [3:0] m_axi_awid;wire [7:0] m_axi_awlen;
    wire [2:0] m_axi_awsize;wire [1:0] m_axi_awburst;wire [127:0] m_axi_wdata;wire [15:0] m_axi_wstrb;
    logic [3:0] m_axi_bid=0;logic [1:0] m_axi_bresp=0;
    wire source_stop,source_quarantined,write_quarantined,quarantined,write_busy;wire [2:0] fault_reason;
    wire source_public_valid,source_response_valid,source_job_fire,source_pixel_fire;
    rgb_axi_write_join #(.WIDTH(TEST_WIDTH),.HEIGHT(TEST_HEIGHT)) dut(.*);
    bit finished=0,jf,cf,pf,df,af,wf,bf,aqf,arf;
    bit bus_live=0,bus_camera=0,wrong_sent=0,force_aw_stall=0,force_b_hold=0;
    integer bus_beat=0,response_due=0,response_mode=0,case_id=0,cycle=0,case_start=0,completed_cases=0;
    integer event_fd,result_fd,list_fd,frame_count,rc,camera_inputs=0,algo_requests=0,algo_replies=0;
    integer aw_count=0,w_count=0,b_count=0,aw_stalls=0,w_stalls=0,b_stalls=0,input_stalls=0;
    integer cfg_stalls=0,done_stalls=0,algo_stalls=0,q_cycles=0;
    logic [31:0] active_base=0,bus_address=0;
    logic [63:0] active_handle=0;
    logic [47:0] input_pairs[0:PAIRS-1];logic [511:0] algorithm_vectors[0:MAX_ALGO-1];
    byte unsigned camera_memory[0:ALLOCATION-1],algorithm_memory[0:MAX_ALGO*64-1];
    bit camera_line_written[0:ALLOCATION/64-1];bit algorithm_line_written[0:MAX_ALGO-1];
    string run_dir,stem;
    bit hold_cfg=0,hold_done=0,hold_aw=0,hold_w=0,hold_algo=0;
    logic saved_cfg;logic [181:0] saved_done;logic [48:0] saved_aw;logic [144:0] saved_w;logic [1:0] saved_algo;
    logic [66:0] last_control='x;logic [2:0] last_q='x;

    task automatic step;
        @(posedge clk);
        jf=job_valid&&job_ready;cf=job_rsp_valid&&job_rsp_ready;pf=in_valid&&in_ready;df=done_valid&&done_ready;
        aqf=algo_req_valid&&algo_req_ready;arf=algo_rsp_valid&&algo_rsp_ready;
        af=m_axi_awvalid&&m_axi_awready;wf=m_axi_wvalid&&m_axi_wready;bf=m_axi_bvalid&&m_axi_bready;
        if(last_control!=={rst,backend_enable,cancel_valid,cancel_id})begin
            $fwrite(event_fd,"%0d\t%0d\tCTRL\t%b %b %b %h\n",case_id,cycle,rst,backend_enable,cancel_valid,cancel_id);
            last_control={rst,backend_enable,cancel_valid,cancel_id};
        end
        if(rst)begin bus_live=0;bus_beat=0;hold_cfg=0;hold_done=0;hold_aw=0;hold_w=0;hold_algo=0;last_q='x;end
        else begin
            if(hold_cfg&&(!job_rsp_valid||job_rsp_error!==saved_cfg))$fatal(1,"CFG holding changed");
            if(hold_done&&(!done_valid||{done_id,outcome,reason,accepted_pairs,written_lines,logical_bytes,physical_bytes}!==saved_done))$fatal(1,"DONE holding changed");
            if(hold_aw&&(!m_axi_awvalid||{m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst}!==saved_aw))$fatal(1,"AW holding changed");
            if(hold_w&&(!m_axi_wvalid||{m_axi_wdata,m_axi_wstrb,m_axi_wlast}!==saved_w))$fatal(1,"W holding changed");
            if(hold_algo&&(!algo_rsp_valid||{algo_error,algo_drained}!==saved_algo))$fatal(1,"Algorithm reply holding changed");
            hold_cfg=job_rsp_valid&&!job_rsp_ready;saved_cfg=job_rsp_error;
            hold_done=done_valid&&!done_ready;saved_done={done_id,outcome,reason,accepted_pairs,written_lines,logical_bytes,physical_bytes};
            hold_aw=m_axi_awvalid&&!m_axi_awready;saved_aw={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst};
            hold_w=m_axi_wvalid&&!m_axi_wready;saved_w={m_axi_wdata,m_axi_wstrb,m_axi_wlast};
            hold_algo=algo_rsp_valid&&!algo_rsp_ready;saved_algo={algo_error,algo_drained};
            if(pf!==source_pixel_fire)$fatal(1,"Wrapper created a one-sided pixel fire");
            if(quarantined)begin q_cycles++;if(job_ready||in_ready||algo_req_ready||!source_stop)$fatal(1,"Q accepted new work");end
            if(jf)$fwrite(event_fd,"%0d\t%0d\tJ\t%h %h\n",case_id,cycle,job_base,job_handle);
            if(cf)$fwrite(event_fd,"%0d\t%0d\tC\t%b\n",case_id,cycle,job_rsp_error);
            if(pf)begin camera_inputs++;$fwrite(event_fd,"%0d\t%0d\tP\t%h %h %h %h %b %h\n",case_id,cycle,in_rgb,in_x_even,in_y,in_markers,in_bad,in_handle);end
            if(aqf)begin algo_requests++;$fwrite(event_fd,"%0d\t%0d\tA\t%h %h\n",case_id,cycle,algo_addr,algo_data);end
            if(arf)begin algo_replies++;$fwrite(event_fd,"%0d\t%0d\tR\t%b %b\n",case_id,cycle,algo_error,algo_drained);end
            if(df)$fwrite(event_fd,"%0d\t%0d\tD\t%h %h %h %0d %0d %0d %0d\n",case_id,cycle,done_id,outcome,reason,accepted_pairs,written_lines,logical_bytes,physical_bytes);
            if(last_q!=={source_quarantined,write_quarantined,write_busy})begin
                $fwrite(event_fd,"%0d\t%0d\tQ\t%b %b %b\n",case_id,cycle,source_quarantined,write_quarantined,write_busy);last_q={source_quarantined,write_quarantined,write_busy};
            end
            if(job_rsp_valid&&!job_rsp_ready)cfg_stalls++;if(done_valid&&!done_ready)done_stalls++;
            if(in_valid&&!in_ready)input_stalls++;if(algo_rsp_valid&&!algo_rsp_ready)algo_stalls++;
            if(m_axi_awvalid&&!m_axi_awready)aw_stalls++;if(m_axi_wvalid&&!m_axi_wready)w_stalls++;if(m_axi_bvalid&&!m_axi_bready)b_stalls++;
            if(af)begin
                aw_count++;if(bus_live)$fatal(1,"Overlapping physical AW");
                if({m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst}!==17'h00071)$fatal(1,"AW identity/length/format");
                bus_live=1;bus_address=m_axi_awaddr;bus_beat=0;wrong_sent=0;
                bus_camera=m_axi_awaddr>=active_base&&{1'b0,m_axi_awaddr}-{1'b0,active_base}<33'(ALLOCATION);
                if(!bus_camera&&!(m_axi_awaddr>=32'h02000000&&m_axi_awaddr<32'h02000000+32'(MAX_ALGO*64)))$fatal(1,"AW outside either grant");
                $fwrite(event_fd,"%0d\t%0d\tAW\t%h %h %h %h %h\n",case_id,cycle,m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst);
            end
            if(wf)begin
                w_count++;if(!bus_live||bus_beat>=4||m_axi_wstrb!==16'hffff||m_axi_wlast!==(bus_beat==3))$fatal(1,"W ownership/strobe/last");
                for(integer i=0;i<16;i++)begin
                    if(bus_camera)camera_memory[int'(bus_address-active_base)+bus_beat*16+i]=m_axi_wdata[i*8+:8];
                    else algorithm_memory[int'(bus_address-32'h02000000)+bus_beat*16+i]=m_axi_wdata[i*8+:8];
                end
                bus_beat++;if(bus_beat==4)response_due=cycle+11;
                $fwrite(event_fd,"%0d\t%0d\tW\t%h %h %b\n",case_id,cycle,m_axi_wdata,m_axi_wstrb,m_axi_wlast);
            end
            if(bf)begin
                b_count++;if(!bus_live||bus_beat!=4)$fatal(1,"B outside completed physical write");
                $fwrite(event_fd,"%0d\t%0d\tB\t%h %h\n",case_id,cycle,m_axi_bid,m_axi_bresp);
                if(m_axi_bid==0)begin
                    if(bus_camera)camera_line_written[int'(bus_address-active_base)/64]=1;
                    else algorithm_line_written[int'(bus_address-32'h02000000)/64]=1;
                    bus_live=0;
                end else begin wrong_sent=1;response_due=cycle+17;end
            end
        end
        #1;if(bf)m_axi_bvalid=0;cycle++;@(negedge clk);
    endtask
    task automatic bus_tick(input bit stalls=1);
        m_axi_awready=!force_aw_stall&&(!stalls||cycle%23>=9);
        m_axi_wready=!stalls||cycle%29>=12;
        if(!m_axi_bvalid&&bus_live&&bus_beat==4&&cycle>=response_due&&!force_b_hold)begin
            m_axi_bvalid=1;m_axi_bid=(response_mode==2&&!wrong_sent)?4'd7:4'd0;
            m_axi_bresp=response_mode==1&&bus_camera?2'd2:2'd0;
        end
    endtask
    task automatic cold(input integer id,input logic [31:0] base=32'h01000000);
        case_id=id;case_start=cycle;rst=1;backend_enable=1;job_valid=0;job_rsp_ready=0;in_valid=0;in_bad=0;
        cancel_valid=0;cancel_id=0;done_ready=0;algo_req_valid=0;algo_rsp_ready=0;
        m_axi_awready=0;m_axi_wready=0;m_axi_bvalid=0;m_axi_bid=0;m_axi_bresp=0;
        force_aw_stall=0;force_b_hold=0;response_mode=0;active_base=base;active_handle=64'h4310000000000000+64'(id);
        for(integer i=0;i<ALLOCATION/64;i++)camera_line_written[i]=0;
        for(integer i=0;i<MAX_ALGO;i++)algorithm_line_written[i]=0;
        repeat(3)step();rst=0;step();if(quarantined||write_busy)$fatal(1,"Cold failed to establish empty ownership");
    endtask
    task automatic submit(input logic [31:0] base,input logic [63:0] handle,input bit reject=0,input bit hold_reply=1);
        integer ticks; ticks=0;job_valid=1;job_base=base;job_handle=handle;
        do begin step();if(ticks++>200)$fatal(1,"Job timeout");end while(!jf);
        job_valid=0;job_base=32'hdeadbeef;job_handle=~handle;
        while(!job_rsp_valid)begin step();if(ticks++>220)$fatal(1,"CFG timeout");end
        if(job_rsp_error!==reject)$fatal(1,"Grant response mismatch");
        if(hold_reply)repeat(17)begin job_base=job_base+1;job_handle=job_handle+1;step();if(in_ready||job_ready)$fatal(1,"Held CFG accepted data/job");end
        job_rsp_ready=1;step();if(!cf)$fatal(1,"CFG not consumed");job_rsp_ready=0;
    endtask
    task automatic present_pair(input integer index,input integer defect=0);
        in_valid=1;in_rgb=input_pairs[index];in_x_even=11'((index%(TEST_WIDTH/2))*2);in_y=11'(index/(TEST_WIDTH/2));
        in_markers={index==PAIRS-1,in_x_even==TEST_WIDTH-2,index==0};in_handle=active_handle;in_bad=0;
        case(defect)
            1:in_bad=1;2:in_handle=active_handle^64'd1;3:in_y=in_y+1;4:in_markers=in_markers^3'd1;
        endcase
    endtask
    task automatic load_frame(input string name);
        stem=name;$readmemh({run_dir,"/",stem,".input.hex"},input_pairs);
    endtask
    task automatic feed_to_public;
        integer sent,ticks;sent=0;ticks=0;
        while(!source_public_valid)begin
            if(!in_valid&&sent<PAIRS)present_pair(sent);
            bus_tick();step();if(pf)begin sent++;in_valid=0;end
            if(ticks++>PAIRS*8+5000)$fatal(1,"No publicly exposed camera packet");
        end
        // 若刚公开packet时还有一个已提出的pixel，先完成该pixel交接再暂停。
        if(in_valid)begin
            do begin bus_tick();step();if(ticks++>PAIRS*8+6000)$fatal(1,"Pending pixel could not finish");end while(!pf);
            in_valid=0;
        end
    endtask
    task automatic wait_done(input integer expected_outcome,expected_reason);
        integer ticks;ticks=0;in_valid=0;algo_req_valid=0;algo_rsp_ready=1;
        while(!done_valid)begin bus_tick();step();if(ticks++>PAIRS*20+10000)$fatal(1,"DONE timeout case=%0d",case_id);end
        if(outcome!==2'(expected_outcome)||reason!==8'(expected_reason)||done_id!==active_handle)$fatal(1,"Terminal outcome mismatch case=%0d",case_id);
        repeat(19)begin bus_tick();step();end
        done_ready=1;bus_tick();step();if(!df)$fatal(1,"DONE not consumed");done_ready=0;
        repeat(3)begin bus_tick();step();end
    endtask
    task automatic case_record(input string kind,input integer expected_outcome,expected_reason);
        $fwrite(result_fd,"{\"case\":%0d,\"kind\":\"%s\",\"stem\":\"%s\",\"base\":%0d,\"handle\":%0d,\"expected_outcome\":%0d,\"expected_reason\":%0d,\"cycles\":%0d}\n",
            case_id,kind,stem,active_base,active_handle,expected_outcome,expected_reason,cycle-case_start);
        completed_cases++;
    endtask
    task automatic dump_memory(input string name,input integer algorithm_count);
        integer output_fd;output_fd=$fopen({run_dir,"/",name,".actual.rgb"},"wb");if(!output_fd)$fatal(1,"Camera dump open");
        for(integer i=0;i<ALLOCATION;i++)begin if(!camera_line_written[i/64])$fatal(1,"Full camera frame contains unwritten line");$fwrite(output_fd,"%c",camera_memory[i]);end
        $fclose(output_fd);output_fd=$fopen({run_dir,"/",name,".actual.algorithm"},"wb");
        for(integer i=0;i<algorithm_count*64;i++)begin if(!algorithm_line_written[i/64])$fatal(1,"Algorithm line missing");$fwrite(output_fd,"%c",algorithm_memory[i]);end
        $fclose(output_fd);
    endtask
    task automatic normal(input integer id,input string name,input integer algorithm_count,input logic [31:0] base=32'h01000000,input integer special=0);
        integer sent,issued,consumed,ticks;bit cancelled_wrong;
        cold(id,base);load_frame(name);submit(base,active_handle);sent=0;issued=0;consumed=0;ticks=0;cancelled_wrong=0;
        while(!done_valid||consumed<algorithm_count)begin
            if(ticks++>PAIRS*30+algorithm_count*150+20000)$fatal(1,"Normal timeout");
            if(!in_valid&&sent<PAIRS&&cycle%13>=3)present_pair(sent);
            if(!algo_req_valid&&issued<algorithm_count)begin algo_req_valid=1;algo_addr=32'h02000000+32'(issued*64);algo_data=algorithm_vectors[issued];end
            algo_rsp_ready=cycle%37>=17;
            if(special==1&&!cancelled_wrong&&sent>=PAIRS/2)begin cancel_valid=1;cancel_id=active_handle^64'd1;cancelled_wrong=1;end
            else cancel_valid=0;
            bus_tick();step();if(pf)begin sent++;in_valid=0;end
            if(aqf)begin issued++;algo_req_valid=0;end
            if(arf)begin consumed++;if(algo_error||!algo_drained)$fatal(1,"Normal algorithm reply unsafe");end
            if(quarantined)$fatal(1,"Normal frame isolated");
        end
        in_valid=0;algo_req_valid=0;cancel_valid=0;
        if(sent!=PAIRS||accepted_pairs!=PAIRS||logical_bytes!=LOGICAL||physical_bytes!=ALLOCATION||written_lines!=ALLOCATION/64)$fatal(1,"Full camera count mismatch");
        if(special==2)begin backend_enable=0;repeat(19)step();backend_enable=1;if(quarantined)$fatal(1,"Held DONE corrupted by late disable");end
        if(special==3)begin cancel_valid=1;cancel_id=active_handle;repeat(19)begin bus_tick();step();end cancel_valid=0;end
        dump_memory(name,algorithm_count);wait_done(0,0);case_record(special==1?"wrong_cancel_normal":special==2?"late_disable_done":special==3?"late_cancel_done":"normal",0,0);
    endtask
    task automatic isolated_tail;
        integer ticks;ticks=0;in_valid=1;algo_req_valid=1;algo_addr=32'h02008000;algo_data=algorithm_vectors[0];job_valid=1;job_base=32'h01000000;job_handle=99;algo_rsp_ready=1;
        repeat(70)begin bus_tick();step();if(jf||pf||aqf||df)$fatal(1,"Unsafe frame falsely closed/reused");end
        if(!quarantined||!source_stop)$fatal(1,"Unsafe state recovered without trusted reset");
        job_valid=0;in_valid=0;algo_req_valid=0;
    endtask
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir))$fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected RGB JOIN fatal probe");
        event_fd=$fopen({run_dir,"/join-events.tsv"},"w");result_fd=$fopen({run_dir,"/case-results.jsonl"},"w");
        if(!event_fd||!result_fd)$fatal(1,"Trace files missing");$fwrite(event_fd,"case\tcycle\tevent\tvalues\n");
        $readmemh({run_dir,"/algorithm.hex"},algorithm_vectors);
        list_fd=$fopen({run_dir,"/frame-list.txt"},"r");rc=$fscanf(list_fd,"%d\n",frame_count);
        for(integer i=0;i<frame_count;i++)begin rc=$fscanf(list_fd,"%s\n",stem);normal(i+1,stem,TEST_WIDTH==1920?4096:16);end
        $fclose(list_fd);
        if(TEST_PROTOCOL)begin
            normal(10,"frame_00",16,32'h01000000,3);
            // T2：PUBLIC取消不能撤AW；等待真实B，终态保持后才归还。
            for(integer id=11;id<=12;id++)begin
                cold(id);load_frame("frame_00");submit(active_base,active_handle);force_aw_stall=id==11;force_b_hold=id==12;feed_to_public();
                if(id==12)begin while(!bus_live||bus_beat!=4)begin bus_tick();step();end end
                cancel_valid=1;cancel_id=active_handle;bus_tick();step();cancel_valid=0;force_aw_stall=0;force_b_hold=0;
                wait_done(2,128);case_record("cancel_public",2,128);
            end
            normal(13,"frame_00",16,32'h01000000,1);
            for(integer defect=1;defect<=4;defect++)begin
                cold(13+defect);load_frame("frame_00");submit(active_base,active_handle);present_pair(0,defect);
                do begin bus_tick();step();end while(!pf);in_valid=0;in_bad=0;
                wait_done(1,defect);case_record("input_error",1,defect);
            end
            cold(18);load_frame("frame_00");submit(active_base,active_handle);response_mode=1;force_b_hold=1;feed_to_public();
            while(!bus_live||bus_beat!=4)begin bus_tick();step();end
            force_b_hold=0;while(!bf)begin bus_tick();step();end
            cancel_valid=1;cancel_id=active_handle;bus_tick();step();cancel_valid=0;
            wait_done(1,16);case_record("memory_error_over_cancel",1,16);
            // T3：通知先到，错误B不能被当成已排空；晚来的正确B仍接，Q保持。
            cold(19);load_frame("frame_00");submit(active_base,active_handle);response_mode=2;feed_to_public();
            while(!source_quarantined)begin bus_tick();step();end
            isolated_tail();if(bus_live)$fatal(1,"Old correct B was not drained");case_record("camera_wrong_bid",1,16);
            for(integer id=20;id<=21;id++)begin
                cold(id);load_frame("frame_00");submit(active_base,active_handle);force_aw_stall=id==20;force_b_hold=id==21;feed_to_public();
                if(id==21)begin while(!bus_live||bus_beat!=4)begin bus_tick();step();end end
                else while(!m_axi_awvalid)begin bus_tick();step();end
                backend_enable=0;repeat(13)begin bus_tick();step();end backend_enable=1;force_aw_stall=0;force_b_hold=0;
                while(!source_quarantined)begin bus_tick();step();end
                isolated_tail();case_record("live_backend_disable",1,16);
            end
            cold(22);load_frame("frame_00");submit(active_base,active_handle);force_aw_stall=1;
            algo_req_valid=1;algo_addr=32'h02000000;algo_data=algorithm_vectors[0];algo_rsp_ready=1;
            do begin bus_tick();step();end while(!aqf);algo_req_valid=0;feed_to_public();
            if(!source_public_valid)$fatal(1,"No camera PUBLIC borrower before algorithm fault");
            response_mode=2;force_aw_stall=0;while(!write_quarantined)begin bus_tick();step();end
            isolated_tail();if(!source_public_valid||source_quarantined||done_valid)$fatal(1,"Unaccepted PUBLIC packet falsely returned");case_record("algorithm_q_camera_public",0,0);
            // T4：非法配置没有child job/pixel/AW；固定错误回执可以跨停用/cancel保持。
            for(integer id=23;id<=27;id++)begin
                cold(id);stem="frame_00";job_base=id==23?32'h01000001:id==24?32'h10000000:32'h10000000-32'(ALLOCATION)+32'd64;job_handle=active_handle;
                if(id==26)job_base[19]=1'bx;if(id==27)job_handle[37]=1'bz;
                job_valid=1;do begin step();end while(!jf);job_valid=0;
                if(!job_rsp_valid||!job_rsp_error||source_job_fire)$fatal(1,"Reject not local");
                backend_enable=0;cancel_valid=1;cancel_id=active_handle;in_valid=1;
                repeat(31)begin job_base=job_base+1;job_handle=job_handle+1;step();if(pf||af||df||source_job_fire||!job_rsp_error)$fatal(1,"Rejected grant has side effects");end
                job_rsp_ready=1;step();job_rsp_ready=0;backend_enable=1;cancel_valid=0;in_valid=0;step();case_record("rejected_grant",1,0);
            end
            normal(28,"frame_00",16,32'h10000000-32'(ALLOCATION));
            cold(29);load_frame("frame_00");backend_enable=0;job_valid=1;job_base=active_base;job_handle=active_handle;
            repeat(31)begin step();if(jf||pf||af||source_job_fire)$fatal(1,"Disabled grant accepted");end
            job_valid=0;backend_enable=1;submit(active_base,active_handle);
            job_rsp_ready=0;present_pair(0);do begin bus_tick();step();end while(!pf);in_valid=0;
            cancel_valid=1;cancel_id=active_handle;step();cancel_valid=0;wait_done(2,128);case_record("disabled_idle_then_cancel",2,128);
            cold(30);load_frame("frame_00");job_valid=1;job_base=active_base;job_handle=active_handle;step();job_valid=0;
            backend_enable=0;repeat(29)step();if(!job_rsp_valid||job_rsp_error||quarantined)$fatal(1,"Held legal CFG corrupted");
            backend_enable=1;job_rsp_ready=1;step();job_rsp_ready=0;cancel_valid=1;cancel_id=active_handle;step();cancel_valid=0;
            wait_done(2,128);case_record("late_disable_cfg",2,128);
            normal(31,"frame_00",16,32'h01000000,2);
            // 可信共同cold reset包括数学slave；保留中止事务的事件，不声称暖reset排空。
            cold(32);load_frame("frame_00");submit(active_base,active_handle);force_aw_stall=1;feed_to_public();
            while(!m_axi_awvalid)begin bus_tick();step();end
            normal(32,"frame_00",16);
            cold(33);load_frame("frame_00");submit(active_base,active_handle);response_mode=2;feed_to_public();
            while(!source_quarantined)begin bus_tick();step();end
            normal(33,"frame_00",16);
            cold(34);load_frame("frame_00");submit(active_base,active_handle);force_b_hold=1;feed_to_public();
            while(!bus_live||bus_beat<2)begin bus_tick();step();end
            cancel_valid=1;cancel_id=active_handle;bus_tick();step();cancel_valid=0;force_b_hold=0;
            wait_done(2,128);case_record("cancel_in_w",2,128);
            // safe DONE已形成后发生算法Q，旧DONE仍能消费，下一帧仍禁止。
            cold(35);load_frame("frame_00");submit(active_base,active_handle);
            begin integer sent;sent=0;while(!done_valid)begin
                if(!in_valid&&sent<PAIRS)present_pair(sent);bus_tick();step();if(pf)begin sent++;in_valid=0;end
            end end
            response_mode=2;algo_req_valid=1;algo_addr=32'h02000000;algo_data=algorithm_vectors[0];algo_rsp_ready=1;
            do begin bus_tick();step();end while(!aqf);algo_req_valid=0;
            while(!write_quarantined)begin bus_tick();step();end
            if(!done_valid||outcome||reason)$fatal(1,"Old safe DONE rewritten by unrelated Q");
            done_ready=1;bus_tick();step();if(!df)$fatal(1,"Safe DONE gated by Q");done_ready=0;
            isolated_tail();case_record("safe_done_then_algorithm_q",0,0);
        end
        finished=1;$fclose(event_fd);$fclose(result_fd);
        result_fd=$fopen({run_dir,"/join-result.json"},"w");
        $fwrite(result_fd,"{\"finished\":true,\"cases\":%0d,\"cycles\":%0d,\"camera_inputs\":%0d,\"algorithm_requests\":%0d,\"algorithm_replies\":%0d,\"aw\":%0d,\"w\":%0d,\"b\":%0d,\"aw_stalls\":%0d,\"w_stalls\":%0d,\"b_stalls\":%0d,\"input_stalls\":%0d,\"cfg_stalls\":%0d,\"done_stalls\":%0d,\"algorithm_reply_stalls\":%0d,\"q_cycles\":%0d}\n",
            completed_cases,cycle,camera_inputs,algo_requests,algo_replies,aw_count,w_count,b_count,aw_stalls,w_stalls,b_stalls,input_stalls,cfg_stalls,done_stalls,algo_stalls,q_cycles);
        $fclose(result_fd);$finish;
    end
endmodule
