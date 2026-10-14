`timescale 1ns/1ps
// CO-T01..07：主路径是真实owner/RAW/CFA/writer/AXI；UNIT明确只测试manager公开端口。
module tb_capture_owned #(parameter integer TEST_W=34,TEST_H=20,TEST_HD=0);
    import frame_owner_pkg::*;
    localparam integer N=TEST_W*TEST_H,P=N/2,S=((3*N+63)/64)*64;
    logic clk=0,rst=1,finished=0;always #5 clk=~clk;
    logic axi_enable=1,frame_valid=0,grant_ready=0,in_valid=0,in_bad=0,rx_valid=0,rx_good=1,cancel_valid=0,done_ready=0;
    logic [95:0] frame_scope=0,rx_scope=0;
    logic [1:0] frame_bayer=0;
    logic [19:0] raw_pair=0;
    logic [10:0] in_x_even=0,in_y=0;
    logic [2:0] in_markers=0;
    logic [63:0] in_handle=0,rx_handle=0,cancel_handle=0;
    logic [194:0] rx_origin=0;
    wire frame_ready,grant_valid,in_ready,rx_ready,done_valid,source_stop,quarantined;
    wire [3:0] grant_status;wire [63:0] grant_handle,done_handle,latest_handle;
    wire [194:0] grant_origin,done_origin;wire [95:0] grant_scope,done_scope;wire [1:0] grant_bayer,done_outcome;
    wire [7:0] done_reason;wire [17:0] source_states;
    wire m_axi_awvalid,m_axi_awready,m_axi_wvalid,m_axi_wready,m_axi_wlast,m_axi_bvalid,m_axi_bready;
    wire [31:0] m_axi_awaddr;wire [3:0] m_axi_awid,m_axi_bid;
    wire [7:0] m_axi_awlen;wire [2:0] m_axi_awsize;wire [1:0] m_axi_awburst,m_axi_bresp;
    wire [127:0] m_axi_wdata;wire [15:0] m_axi_wstrb;
    frame_capture_owned_axi #(.WIDTH(TEST_W),.HEIGHT(TEST_H)) dut(.*);

    logic random_stalls=1,hold_aw=0,hold_w=0,hold_ar=0,hold_b=0,hold_r=0;
    integer fault_kind=0;
    wire m_axi_arvalid=0,m_axi_rready=0;
    wire [31:0] m_axi_araddr=0;wire [3:0] m_axi_arid=0;
    wire [7:0] m_axi_arlen=0;wire [2:0] m_axi_arsize=4;wire [1:0] m_axi_arburst=1;
    wire m_axi_arready,m_axi_rvalid,m_axi_rlast;wire [127:0] m_axi_rdata;
    wire [3:0] m_axi_rid;wire [1:0] m_axi_rresp;wire writing,b_pending,reading;
    axi128_capture_owned_memory #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H)) memory(.*);

    // 纯manager对抗测试：真正独立owner，producer字段是显式UNIT模型，不声称像素或存储验证。
    logic u_rst=1,u_halt=0,u_frame_valid=0,u_grant_ready=0,u_done_ready=0,u_owner_gate=1,u_job_ready=1;
    logic u_cap_done_valid=0,u_eof_valid=0,u_rx_valid=0;
    logic [21:0] u_raw_count=0;
    wire u_frame_ready,u_grant_valid,u_done_valid,u_cmd_valid,u_cmd_ready,u_reply_valid,u_reply_ready,u_native_cmd_ready;
    wire [940:0] u_command;wire [941:0] u_reply;
    wire [3:0] u_grant_status;wire [63:0] u_handle,u_grant_handle,u_done_handle;
    wire [194:0] u_grant_origin,u_done_origin;wire [95:0] u_grant_scope,u_done_scope,u_cap_scope;
    wire [1:0] u_grant_bayer,u_cap_bayer,u_outcome;wire [7:0] u_reason;
    wire u_job_valid,u_cap_done_ready,u_cancel_valid,u_rx_ready,u_q;wire [31:0] u_base;
    wire [17:0] u_source_states;wire [8:0] u_result_states;wire [63:0] u_latest,u_freeze,u_policy;
    wire u_frozen,u_owner_q,u_source_limit,u_result_limit;
    frame_owner_read_authority #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H),.FRAME_ALIGNMENT(64)) unit_owner(
        .core_clk(clk),.safe_reset_n(!u_rst),.cmd_valid(u_cmd_valid&&u_owner_gate),.cmd_ready(u_native_cmd_ready),.command(u_command),
        .offer_sequence(64'd0),.lookup_valid(1'b0),.lookup_ready(),.lookup_demand(479'd0),.lookup_permitted(),.lookup_bundle(),
        .reply_valid(u_reply_valid),.reply_ready(u_reply_ready),.reply(u_reply),.source_states(u_source_states),.result_states(u_result_states),
        .latest_handle(u_latest),.freeze_handle(u_freeze),.policy(u_policy),.frozen(u_frozen),.quarantined(u_owner_q),.source_exhausted(u_source_limit),.result_exhausted(u_result_limit));
    assign u_cmd_ready=u_native_cmd_ready&&u_owner_gate;
    frame_capture_manager #(.WIDTH(TEST_W),.HEIGHT(TEST_H)) unit_manager(
        .clk,.rst(u_rst),.halt(u_halt),.capture_quarantined(1'b0),
        .frame_valid(u_frame_valid),.frame_ready(u_frame_ready),.frame_scope(96'h90123456a000000200000001),.frame_bayer(2'd2),
        .grant_valid(u_grant_valid),.grant_ready(u_grant_ready),.grant_status(u_grant_status),.grant_handle(u_grant_handle),.grant_origin(u_grant_origin),.grant_scope(u_grant_scope),.grant_bayer(u_grant_bayer),
        .owner_cmd_valid(u_cmd_valid),.owner_cmd_ready(u_cmd_ready),.owner_command(u_command),.owner_reply_valid(u_reply_valid),.owner_reply_ready(u_reply_ready),.owner_reply(u_reply),
        .cap_job_valid(u_job_valid),.cap_job_ready(u_job_ready),.cap_base(u_base),.cap_handle(u_handle),.cap_scope(u_cap_scope),.cap_bayer(u_cap_bayer),
        .cap_done_valid(u_cap_done_valid),.cap_done_ready(u_cap_done_ready),.cap_done_handle(u_handle),.cap_done_scope(u_cap_scope),.cap_outcome(2'd0),.cap_reason(8'd0),
        .cap_raw_pairs(u_raw_count),.cap_rgb_pairs(22'(P)),.cap_lines(22'(S/64)),.cap_discarded(22'd0),.cap_logical_bytes(32'(3*N)),.cap_physical_bytes(32'(S)),
        .cap_cancel_valid(u_cancel_valid),.cap_cancel_handle(),.raw_eof_valid(u_eof_valid),.raw_eof_handle(u_handle),.raw_eof_scope(u_cap_scope),
        .rx_valid(u_rx_valid),.rx_ready(u_rx_ready),.rx_handle(u_grant_handle),.rx_scope(u_grant_scope),.rx_origin(u_grant_origin),.rx_good(1'b1),
        .cancel_valid(1'b0),.cancel_handle(64'd0),.done_valid(u_done_valid),.done_ready(u_done_ready),.done_handle(u_done_handle),.done_origin(u_done_origin),.done_scope(u_done_scope),.done_outcome(u_outcome),.done_reason(u_reason),.quarantined(u_q));

    logic [19:0] raw_values[0:P-1];
    logic [63:0] saved_handle=0,previous_latest=0;
    logic [194:0] saved_origin=0;
    logic [95:0] saved_scope=0,last_good_scope=0;
    string directory;integer log_fd,case_fd,metrics_fd,case_id=0,cycle=0,case_start=0,vector_id=0;
    integer frames=0,pixels=0,protocol_cases=0,unit_cases=0,passed=0;
    integer aws=0,ws=0,bs=0,cap_jobs=0,cap_done=0,frame_done=0,cap_cancels=0;
    bit held_cmd=0,held_job=0,held_grant=0,held_done=0,held_aw=0,held_w=0;
    logic [940:0] old_cmd;
    logic [193:0] old_job;
    logic [360:0] old_grant;
    logic [364:0] old_done;
    logic [48:0] old_aw;logic [144:0] old_w;
    always @(posedge clk)if(log_fd)begin
        cycle++;
        if(rst)begin held_cmd=0;held_job=0;held_grant=0;held_done=0;held_aw=0;held_w=0;end
        else begin
            if(held_cmd&&(!dut.owner_cmd_valid||old_cmd!==dut.owner_command))$fatal(1,"CO owner command holding");
            if(held_job&&(!dut.cap_job_valid||old_job!=={dut.cap_base,dut.cap_handle,dut.cap_scope,dut.cap_bayer}))$fatal(1,"CO cap job holding");
            if(held_grant&&(!grant_valid||old_grant!=={grant_status,grant_handle,grant_origin,grant_scope,grant_bayer}))$fatal(1,"CO grant holding");
            if(held_done&&(!done_valid||old_done!=={done_handle,done_origin,done_scope,done_outcome,done_reason}))$fatal(1,"CO frame done holding");
            if(held_aw&&(!m_axi_awvalid||old_aw!=={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst}))$fatal(1,"CO AW holding");
            if(held_w&&(!m_axi_wvalid||old_w!=={m_axi_wdata,m_axi_wstrb,m_axi_wlast}))$fatal(1,"CO W holding");
            held_cmd=dut.owner_cmd_valid&&!dut.owner_cmd_ready;old_cmd=dut.owner_command;
            held_job=dut.cap_job_valid&&!dut.cap_job_ready;old_job={dut.cap_base,dut.cap_handle,dut.cap_scope,dut.cap_bayer};
            held_grant=grant_valid&&!grant_ready;old_grant={grant_status,grant_handle,grant_origin,grant_scope,grant_bayer};
            held_done=done_valid&&!done_ready;old_done={done_handle,done_origin,done_scope,done_outcome,done_reason};
            held_aw=m_axi_awvalid&&!m_axi_awready;old_aw={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst};
            held_w=m_axi_wvalid&&!m_axi_wready;old_w={m_axi_wdata,m_axi_wstrb,m_axi_wlast};
            if(frame_valid&&frame_ready)$fwrite(log_fd,"%0d\t%0d\tFRAME\t%h %h\n",case_id,cycle,frame_scope,frame_bayer);
            if(dut.owner_cmd_valid&&dut.owner_cmd_ready)$fwrite(log_fd,"%0d\t%0d\tOCMD\t%0236h\n",case_id,cycle,dut.owner_command);
            if(dut.owner_reply_valid&&dut.owner_reply_ready)$fwrite(log_fd,"%0d\t%0d\tOREPLY\t%0236h\n",case_id,cycle,dut.owner_reply);
            if(dut.cap_job_valid&&dut.cap_job_ready)begin cap_jobs++;$fwrite(log_fd,"%0d\t%0d\tCAP_JOB\t%h %h %h %h\n",case_id,cycle,dut.cap_base,dut.cap_handle,dut.cap_scope,dut.cap_bayer);end
            if(grant_valid&&grant_ready)$fwrite(log_fd,"%0d\t%0d\tGRANT\t%h %h %h %h %h\n",case_id,cycle,grant_status,grant_handle,grant_origin,grant_scope,grant_bayer);
            if(in_valid&&in_ready)$fwrite(log_fd,"%0d\t%0d\tRAW\t%h %h %0d %0d %h %0d\n",case_id,cycle,in_handle,raw_pair,in_x_even,in_y,in_markers,in_bad);
            if(dut.manager.raw_eof_valid)$fwrite(log_fd,"%0d\t%0d\tEOF_HOOK\t%h %h\n",case_id,cycle,dut.manager.raw_eof_handle,dut.manager.raw_eof_scope);
            if(dut.cap_done_valid&&dut.cap_done_ready)begin cap_done++;$fwrite(log_fd,"%0d\t%0d\tCAP_DONE\t%h %h %h %h %0d %0d %0d %0d %0d %0d\n",case_id,cycle,dut.cap_done_handle,dut.cap_done_scope,dut.cap_outcome,dut.cap_reason,dut.cap_raw_pairs,dut.cap_rgb_pairs,dut.cap_lines,dut.cap_discarded,dut.cap_logical_bytes,dut.cap_physical_bytes);end
            if(rx_valid&&rx_ready)$fwrite(log_fd,"%0d\t%0d\tRX\t%h %h %h %0d\n",case_id,cycle,rx_handle,rx_scope,rx_origin,rx_good);
            if(cancel_valid)$fwrite(log_fd,"%0d\t%0d\tCANCEL\t%h\n",case_id,cycle,cancel_handle);
            if(dut.cap_cancel_valid)begin cap_cancels++;$fwrite(log_fd,"%0d\t%0d\tCAP_CANCEL\t%h\n",case_id,cycle,dut.cap_cancel_handle);end
            if(dut.line_req_valid&&dut.line_req_ready)$fwrite(log_fd,"%0d\t%0d\tWREQ\t%h %0128h\n",case_id,cycle,dut.line_addr,dut.line_data);
            if(dut.line_rsp_valid&&dut.line_rsp_ready)$fwrite(log_fd,"%0d\t%0d\tWRSP\t%0d %0d\n",case_id,cycle,dut.line_error,dut.line_drained);
            if(done_valid&&done_ready)begin frame_done++;$fwrite(log_fd,"%0d\t%0d\tDONE\t%h %h %h %h %h %h %h\n",case_id,cycle,done_handle,done_scope,done_origin,done_outcome,done_reason,source_states,latest_handle);end
            if(m_axi_awvalid&&m_axi_awready)begin aws++;$fwrite(log_fd,"%0d\t%0d\tAW\t%h %h %h %h %h\n",case_id,cycle,m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst);end
            if(m_axi_wvalid&&m_axi_wready)begin ws++;$fwrite(log_fd,"%0d\t%0d\tW\t%032h %h %0d\n",case_id,cycle,m_axi_wdata,m_axi_wstrb,m_axi_wlast);end
            if(m_axi_bvalid&&m_axi_bready)begin bs++;$fwrite(log_fd,"%0d\t%0d\tB\t%h %h\n",case_id,cycle,m_axi_bid,m_axi_bresp);end
        end
        if(cycle-case_start>10000000)$fatal(1,"CO watchdog case=%0d",case_id);
    end

    task automatic cold;
        @(negedge clk);rst=1;axi_enable=1;frame_valid=0;grant_ready=0;in_valid=0;rx_valid=0;cancel_valid=0;done_ready=0;
        hold_aw=0;hold_w=0;hold_b=0;fault_kind=0;
        $fwrite(log_fd,"%0d\t%0d\tCOLD\t0\n",case_id,cycle);
        repeat(6)@(negedge clk);rst=0;repeat(6)@(negedge clk);case_start=cycle;
    endtask
    task automatic start_frame(input integer vector,input logic [95:0] scope,input integer expected_status=0);
        integer phase;
        phase=vector/2;vector_id=vector;case_start=cycle;
        $readmemh($sformatf("%s/vector-%0d.raw",directory,vector),raw_values);
        @(negedge clk);frame_scope=scope;frame_bayer=2'(phase);frame_valid=1;grant_ready=0;done_ready=0;
        do @(posedge clk);while(!frame_ready);
        @(negedge clk);frame_valid=0;frame_scope=~scope;frame_bayer=~2'(phase);
        do @(posedge clk);while(!grant_valid);
        if(grant_status!=expected_status)$fatal(1,"CO grant status case=%0d got=%0d expected=%0d",case_id,grant_status,expected_status);
        saved_handle=grant_handle;saved_scope=grant_scope;saved_origin=grant_origin;
        if(grant_scope!==scope||grant_bayer!=phase)$fatal(1,"CO frame snapshot drift");
        if(expected_status==0)begin
            if(!saved_handle||saved_origin[194:131]!=saved_handle||saved_origin[66:3]!=saved_handle||saved_origin[130:67]!=scope[63:0]||saved_origin[2:0]>=6)$fatal(1,"CO canonical Source grant");
            repeat(5)begin @(negedge clk);if(rx_ready||in_ready)$fatal(1,"CO input accepted before grant delivery");end
        end else if(saved_handle||saved_origin)$fatal(1,"CO error grant exposed Source");
        @(negedge clk);grant_ready=1;@(posedge clk);@(negedge clk);grant_ready=0;
    endtask
    function automatic logic [95:0] scope_for(input integer index);
        return {32'(32'h90123400+index),32'(32'habcd0000+index),32'(32'h5a431000+index)};
    endfunction
    task automatic feed(input integer count,input bit until_stop=0);
        bit stopped;
        stopped=0;
        for(integer index=0;index<count&&!stopped;index++)begin
            @(negedge clk);in_valid=1;raw_pair=raw_values[index];in_handle=saved_handle;
            in_x_even=11'(2*(index%(TEST_W/2)));in_y=11'(index/(TEST_W/2));
            in_markers={index==P-1,index%(TEST_W/2)==TEST_W/2-1,index==0};in_bad=0;
            do begin
                @(posedge clk);
                // RAW子模块尚未arm时也会stop；先等第一个真实RAW接受，不能把启动等待当存储错误。
                if(until_stop&&index>0&&source_stop&&!in_ready)stopped=1;
            end while(!in_ready&&!stopped);
            @(negedge clk);in_valid=0;
            if(index%13==0)@(negedge clk);
        end
    endtask
    task automatic rx_close(input bit good,input integer bad_identity=0);
        @(negedge clk);rx_handle=bad_identity==1?saved_handle^64'd1:saved_handle;
        rx_scope=bad_identity==2?saved_scope^96'd1:saved_scope;
        rx_origin=bad_identity==3?saved_origin^195'd8:saved_origin;
        rx_good=good;rx_valid=1;
        do @(posedge clk);while(!rx_ready);
        @(negedge clk);rx_valid=0;
    endtask
    task automatic take_done(input integer outcome,input logic [7:0] reason,input bit allow_q=0);
        do @(posedge clk);while(!done_valid);
        if(done_handle!==saved_handle||done_scope!==saved_scope||done_origin!==saved_origin||done_outcome!=outcome||done_reason!==reason)$fatal(1,"CO terminal case=%0d outcome=%0d reason=%h",case_id,done_outcome,done_reason);
        if(outcome==0)begin
            if(latest_handle!=saved_handle||source_states[int'(saved_origin[2:0])*3+:3]!=S_COMPLETE)$fatal(1,"CO normal Source not retained COMPLETE");
        end else if(latest_handle!=previous_latest)$fatal(1,"CO bad Source changed latest");
        repeat(5)@(negedge clk);done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;
        if(!allow_q&&quarantined)$fatal(1,"CO safe path quarantined");
    endtask
    task automatic end_case(input string name,input integer variant);
        passed++;$fwrite(case_fd,"%0d\t%s\t%0d\n",case_id,name,variant);
        $fwrite(log_fd,"%0d\t%0d\tCASE_END\t%s %0d\n",case_id,cycle,name,variant);
        $display("CO case %0d %s %0d PASS cycle=%0d",case_id,name,variant,cycle);case_id++;
    endtask
    task automatic normal_frame(input integer vector,input bit stale=0,input bit held_q=0);
        integer before_cancel;logic [95:0] scope;
        scope=scope_for(case_id);previous_latest=latest_handle;
        $fwrite(log_fd,"%0d\t%0d\tCASE\t%s %0d\n",case_id,cycle,held_q?"HELD_DONE_Q":stale?"STALE":"NORMAL",vector);
        start_frame(vector,scope);before_cancel=cap_cancels;
        if(stale)begin @(negedge clk);cancel_valid=1;cancel_handle=saved_handle^64'd1;end
        feed(P);cancel_valid=0;
        if(stale)begin
            rx_close(1,1);rx_close(1,2);rx_close(1,3);
            repeat(5)@(negedge clk);if(done_valid||cap_cancels!=before_cancel)$fatal(1,"CO stale event affected current work");
        end
        // 一半场景在真实actor DONE之后才提供接收结束；另一半在最后RAW后立即提供。
        if(vector%2==0)begin
            do @(posedge clk);while(!dut.cap_done_valid);
            repeat(8)@(negedge clk);if(done_valid)$fatal(1,"CO finished without RX closure");
        end
        rx_close(1);
        if(held_q)begin
            do @(posedge clk);while(!done_valid);
            @(negedge clk);axi_enable=0;repeat(6)@(negedge clk);
            if(!done_valid||done_outcome||!quarantined)$fatal(1,"CO held safe DONE lost after Q");
        end
        take_done(0,0,held_q);last_good_scope=scope;frames++;pixels+=N;
        end_case(held_q?"HELD_DONE_Q":stale?"STALE":"NORMAL",vector);
        if(held_q)cold();
    endtask
    task automatic negative_case(input string kind);
        integer count,before_cancel,before_jobs,before_aw;logic [95:0] scope;
        previous_latest=latest_handle;scope=scope_for(case_id);
        $fwrite(log_fd,"%0d\t%0d\tCASE\t%s 0\n",case_id,cycle,kind);
        before_cancel=cap_cancels;before_jobs=cap_jobs;before_aw=aws;
        if(kind=="DUPLICATE")begin
            start_frame(0,last_good_scope^96'h10000000000000000,4);
            repeat(6)@(negedge clk);
            if(cap_jobs!=before_jobs||aws!=before_aw||done_valid)$fatal(1,"CO refused allocation started work");
        end else begin
            start_frame(0,scope);
            count=P/2;if(count>16)count=16;if(count<1)count=1;
            if(kind=="RX_BAD"||kind=="CANCEL"||kind=="EARLY_CLOSED")begin
                feed(count);
                if(kind=="CANCEL")begin
                    @(negedge clk);cancel_handle=saved_handle;cancel_valid=1;repeat(4)@(negedge clk);cancel_valid=0;
                    repeat(8)@(negedge clk);if(done_valid)$fatal(1,"CO cancel released without RX no-future");
                    rx_close(1);take_done(2,8'h08);
                end else if(kind=="RX_BAD")begin rx_close(0);take_done(1,8'h0c);end
                else begin
                    rx_close(1);repeat(40)@(negedge clk);
                    if(done_valid||frame_ready||source_states[int'(saved_origin[2:0])*3+:3]!=S_WRITING)$fatal(1,"CO incomplete capture falsely completed");
                    $fwrite(log_fd,"%0d\t%0d\tOPEN_WAIT\t1\n",case_id,cycle);
                end
            end else if(kind=="BRESP")begin
                fault_kind=1;feed(P,1);rx_close(1);take_done(1,8'h01);fault_kind=0;
            end else if(kind=="UNKNOWN")begin
                fault_kind=2;feed(P,1);do @(posedge clk);while(!dut.owner_q);
                repeat(20)@(negedge clk);
                if(done_valid||frame_ready||source_states[int'(saved_origin[2:0])*3+:3]!=S_Q)$fatal(1,"CO UNKNOWN not isolated");
                $fwrite(log_fd,"%0d\t%0d\tQ\t1\n",case_id,cycle);
            end
            if(kind=="RX_BAD"||kind=="CANCEL")if(cap_cancels-before_cancel!=1)$fatal(1,"CO cancel pulse duplicated or missing");
        end
        protocol_cases++;end_case(kind,0);
        if(kind=="EARLY_CLOSED"||kind=="UNKNOWN")cold();
    endtask

    task automatic unit_reset;
        @(negedge clk);u_rst=1;u_halt=0;u_frame_valid=0;u_grant_ready=0;u_done_ready=0;
        u_cap_done_valid=0;u_eof_valid=0;u_rx_valid=0;u_owner_gate=1;u_job_ready=1;u_raw_count=0;
        repeat(5)@(negedge clk);u_rst=0;repeat(5)@(negedge clk);
    endtask
    task automatic unit_start;
        @(negedge clk);u_frame_valid=1;
        do @(posedge clk);while(!u_frame_ready);
        @(negedge clk);u_frame_valid=0;
    endtask
    task automatic unit_case(input integer kind);
        logic [940:0] command_hold;logic [193:0] job_hold;
        case_start=cycle;$fwrite(log_fd,"%0d\t%0d\tCASE\tUNIT %0d\n",case_id,cycle,kind);unit_reset();
        if(kind==0)u_job_ready=0;
        if(kind==1)u_owner_gate=0;
        unit_start();
        if(kind==0)begin
            do @(posedge clk);while(!u_job_valid);job_hold={u_base,u_handle,u_cap_scope,u_cap_bayer};
            @(negedge clk);u_halt=1;repeat(6)@(negedge clk);
            if(!u_job_valid||job_hold!=={u_base,u_handle,u_cap_scope,u_cap_bayer}||u_done_valid||u_source_states[2:0]!=S_WRITING)$fatal(1,"CO UNIT publicjob withdrawn/free");
            u_job_ready=1;do @(posedge clk);while(!u_owner_q);repeat(6)@(negedge clk);
            if(u_done_valid||!u_grant_valid||u_grant_status!=OK)$fatal(1,"CO UNIT Q changed published grant");
        end else if(kind==1)begin
            do @(posedge clk);while(!u_cmd_valid);command_hold=u_command;
            @(negedge clk);u_halt=1;repeat(6)@(negedge clk);
            if(!u_cmd_valid||u_command!==command_hold||u_job_valid||u_done_valid)$fatal(1,"CO UNIT owner command holding");
            u_owner_gate=1;do @(posedge clk);while(!u_owner_q);repeat(6)@(negedge clk);
            if(u_done_valid||!u_grant_valid||u_grant_status!=QUARANTINED||u_grant_handle!=0)$fatal(1,"CO UNIT prestart Q fabricated actor");
        end else begin
            do @(posedge clk);while(!u_grant_valid);
            @(negedge clk);u_grant_ready=1;@(posedge clk);@(negedge clk);u_grant_ready=0;
            if(kind==2)begin u_eof_valid=1;@(posedge clk);@(negedge clk);u_eof_valid=0;end
            u_raw_count=22'(kind==2?P-1:P);u_cap_done_valid=1;
            do @(posedge clk);while(!u_cap_done_ready);
            @(negedge clk);u_cap_done_valid=0;u_rx_valid=1;
            do @(posedge clk);while(!u_rx_ready);
            @(negedge clk);u_rx_valid=0;
            if(kind==2)begin
                do @(posedge clk);while(!u_done_valid);
                if(u_outcome!=1||u_reason!=2||u_latest!=0||u_source_states[2:0]!=S_FREE)$fatal(1,"CO UNIT bad count succeeded");
                @(negedge clk);u_done_ready=1;@(posedge clk);@(negedge clk);u_done_ready=0;
            end else begin
                repeat(30)@(negedge clk);
                if(u_done_valid||u_frame_ready||u_source_states[2:0]!=S_WRITING)$fatal(1,"CO UNIT inferred EOF from count");
            end
        end
        $fwrite(log_fd,"%0d\t%0d\tUNIT_CHECK\t%0d %0d %h %h\n",case_id,cycle,kind,u_done_valid,u_source_states,u_latest);
        unit_cases++;end_case("UNIT",kind);unit_reset();
    endtask
    initial begin
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected CAPTURE OWNED fatal probe");
        if(!$value$plusargs("RUN_DIR=%s",directory))$fatal(1,"CO RUN_DIR");
        log_fd=$fopen({directory,"/capture-events.tsv"},"w");case_fd=$fopen({directory,"/capture-cases.tsv"},"w");cold();
        if(TEST_HD)normal_frame(1);
        else begin
            for(integer vector=0;vector<8;vector++)normal_frame(vector);
            negative_case("DUPLICATE");normal_frame(1,1);
            negative_case("RX_BAD");negative_case("CANCEL");negative_case("BRESP");
            negative_case("UNKNOWN");normal_frame(0);negative_case("EARLY_CLOSED");normal_frame(1,0,1);
            for(integer kind=0;kind<4;kind++)unit_case(kind);
        end
        repeat(5)@(negedge clk);
        metrics_fd=$fopen({directory,"/capture-metrics.json"},"w");
        $fwrite(metrics_fd,"{\"width\":%0d,\"height\":%0d,\"hd\":%0d,\"frames\":%0d,\"pixels\":%0d,\"protocol_cases\":%0d,\"unit_cases\":%0d,\"passed\":%0d,\"cycles\":%0d,\"aw\":%0d,\"w\":%0d,\"b\":%0d,\"cap_jobs\":%0d,\"cap_done\":%0d,\"frame_done\":%0d,\"cap_cancels\":%0d}\n",
            TEST_W,TEST_H,TEST_HD,frames,pixels,protocol_cases,unit_cases,passed,cycle,aws,ws,bs,cap_jobs,cap_done,frame_done,cap_cancels);
        $fclose(metrics_fd);$fclose(case_fd);$fclose(log_fd);log_fd=0;finished=1;
        $display("CAPTURE OWNED PASS frames=%0d pixels=%0d protocols=%0d units=%0d",frames,pixels,protocol_cases,unit_cases);$finish;
    end
endmodule
