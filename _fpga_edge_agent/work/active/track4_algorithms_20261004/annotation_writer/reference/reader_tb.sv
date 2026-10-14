`timescale 1ns/1ps
// PB-C1：真实writer/AXI/账本/reader；期望来自输入公式或冻结golden，不读取DUT私有数据。
module tb_bitmap_display_contract #(parameter integer TEST_BITMAP_W=34,TEST_BITMAP_H=20,TEST_BITMAP_HD=0);
    import frame_owner_pkg::*;
    import display_row_pkg::*;
    localparam integer W=TEST_BITMAP_W,H=TEST_BITMAP_H,N=W*H,P=W/2;
    localparam integer S=((3*N+63)/64)*64,E=((N+511)/512)*64,A=((4224+(N+3)/4+63)/64)*64;
    logic clk=0,rst=1,finished=0;always #5 clk=~clk;
    wire safe_reset_n=!rst;
    logic enable=1,random_stalls=1,hold_aw=0,hold_w=0,hold_ar=0,hold_b=0,hold_r=0;
    integer fault_kind=0;
    logic seed_ann_valid=0;logic [1:0] seed_ann_slot=0;logic [2:0] seed_ann_source=0;
    wire m_axi_awvalid,m_axi_awready,m_axi_wvalid,m_axi_wready,m_axi_wlast,m_axi_bvalid,m_axi_bready;
    wire m_axi_arvalid,m_axi_arready,m_axi_rvalid,m_axi_rready,m_axi_rlast;
    wire [31:0] m_axi_awaddr,m_axi_araddr;wire [3:0] m_axi_awid,m_axi_bid,m_axi_arid,m_axi_rid;
    wire [7:0] m_axi_awlen,m_axi_arlen;wire [2:0] m_axi_awsize,m_axi_arsize;
    wire [1:0] m_axi_awburst,m_axi_arburst,m_axi_bresp,m_axi_rresp;
    wire [127:0] m_axi_wdata,m_axi_rdata;wire [15:0] m_axi_wstrb;wire writing,b_pending,reading;

    logic w_cfg_valid=0,w_cfg_rsp_ready=0,w_in_valid=0,w_abort_valid=0,w_done_ready=0,rpc_open=1;
    logic [31:0] w_cfg_base=32'h03000000;logic [63:0] w_cfg_id=0,w_in_id=0,w_abort_id=0;
    logic [20:0] w_in_index=0;logic w_in_edge=0;
    wire w_cfg_ready,w_cfg_rsp_valid,w_cfg_error,w_in_ready,w_done_valid,w_done_error,w_done_aborted,w_done_drained,w_q;
    wire [21:0] w_count;wire w_req_valid,w_req_ready,w_write,w_rsp_valid,w_rsp_ready,w_error,w_drained;
    wire [31:0] w_addr;wire [511:0] w_data;
    wire [1:0] c_req_valid,c_req_ready,c_rsp_valid,c_rsp_ready,c_error,c_drained;
    wire [31:0] c_addr[0:1];wire [511:0] c_data[0:1];wire write_busy,write_q,bridge_q,local_q;wire [2:0] write_fault;
    assign c_req_valid={1'b0,w_req_valid&&rpc_open};assign w_req_ready=rpc_open&&c_req_ready[0];
    assign c_addr[0]=w_addr;assign c_addr[1]=0;assign c_data[0]=w_data;assign c_data[1]=0;
    assign c_rsp_ready={1'b0,w_rsp_ready};assign w_rsp_valid=c_rsp_valid[0];assign w_error=c_error[0];assign w_drained=c_drained[0];
    edge_frame_writer #(.WIDTH(W),.HEIGHT(H),.ITEM_BITS(1)) writer(
        .clk,.rst,.cfg_valid(w_cfg_valid),.cfg_ready(w_cfg_ready),.cfg_base(w_cfg_base),.cfg_id(w_cfg_id),
        .cfg_rsp_valid(w_cfg_rsp_valid),.cfg_rsp_ready(w_cfg_rsp_ready),.cfg_rsp_error(w_cfg_error),
        .in_valid(w_in_valid),.in_ready(w_in_ready),.in_index(w_in_index),.in_edge(w_in_edge),.in_id(w_in_id),
        .abort_valid(w_abort_valid),.abort_id(w_abort_id),.done_valid(w_done_valid),.done_ready(w_done_ready),
        .done_error(w_done_error),.done_aborted(w_done_aborted),.done_drained(w_done_drained),.count(w_count),
        .line_req_valid(w_req_valid),.line_req_ready(w_req_ready),.line_write(w_write),.line_addr(w_addr),.line_wdata(w_data),
        .line_rsp_valid(w_rsp_valid),.line_rsp_ready(w_rsp_ready),.line_rdata(512'd0),.line_error(w_error),.line_drained(w_drained),.quarantined(w_q));
    axi_write_pair_service writes(.clk,.rst,.enable,.c_req_valid,.c_req_ready,.c_addr,.c_data,.c_rsp_valid,.c_rsp_ready,.c_error,.c_drained,
        .m_axi_awvalid,.m_axi_awready,.m_axi_awaddr,.m_axi_awid,.m_axi_awlen,.m_axi_awsize,.m_axi_awburst,
        .m_axi_wvalid,.m_axi_wready,.m_axi_wdata,.m_axi_wstrb,.m_axi_wlast,.m_axi_bvalid,.m_axi_bready,.m_axi_bid,.m_axi_bresp,
        .busy(write_busy),.quarantined(write_q),.bridge_quarantined(bridge_q),.local_quarantined(local_q),.fault_reason(write_fault));

    command_t o_command;reply_t o_reply,allocated,offered,previous_bundle;
    logic o_cmd_valid=0,o_reply_ready=0;wire o_cmd_ready,o_reply_valid;
    wire [17:0] source_states;wire [8:0] result_states;wire [63:0] latest_handle,freeze_handle,policy;
    wire frozen,owner_q,source_exhausted,result_exhausted;
    frame_owner #(.IMAGE_WIDTH(W),.IMAGE_HEIGHT(H),.FRAME_ALIGNMENT(64)) owner(
        .core_clk(clk),.safe_reset_n,.cmd_valid(o_cmd_valid),.cmd_ready(o_cmd_ready),.command(o_command),
        .reply_valid(o_reply_valid),.reply_ready(o_reply_ready),.reply(o_reply),.source_states,.result_states,
        .latest_handle,.freeze_handle,.policy,.frozen,.quarantined(owner_q),.source_exhausted,.result_exhausted);

    logic r_job_valid=0,r_job_reply_ready=0,r_job_permitted=1,r_cancel_valid=0,r_done_ready=0,r_out_ready=0;
    logic [1:0] r_job_bank=0,r_cancel_bank=0;row_ticket_t r_ticket,r_cancel_ticket;reply_t r_bundle;
    wire r_job_ready,r_job_reply_valid,r_out_valid,r_done_valid,r_drained,r_q;
    wire [2:0] r_job_status;wire [1:0] r_saved_bank,r_outcome;wire [7:0] r_reason;
    wire [542:0] r_saved_ticket;wire [53:0] r_out_data;wire [9:0] r_out_address;wire [63:0] r_out_generation;
    wire [10:0] r_prepared,r_delivered;wire [31:0] r_read_beats;
    display_row_reader #(.IMAGE_WIDTH(W),.IMAGE_HEIGHT(H),.FRAME_ALIGNMENT(64)) reader(
        .clk,.rst,.enable,.job_valid(r_job_valid),.job_ready(r_job_ready),.job_bank(r_job_bank),.job_ticket(r_ticket),
        .job_bundle(r_bundle),.job_permitted(r_job_permitted),.job_reply_valid(r_job_reply_valid),.job_reply_ready(r_job_reply_ready),
        .job_reply_status(r_job_status),.saved_bank(r_saved_bank),.saved_ticket(r_saved_ticket),
        .out_valid(r_out_valid),.out_ready(r_out_ready),.out_data(r_out_data),.out_address(r_out_address),.out_generation(r_out_generation),
        .cancel_valid(r_cancel_valid),.cancel_bank(r_cancel_bank),.cancel_ticket(r_cancel_ticket),
        .done_valid(r_done_valid),.done_ready(r_done_ready),.outcome(r_outcome),.reason(r_reason),.drained(r_drained),
        .prepared_pairs(r_prepared),.delivered_pairs(r_delivered),.read_beats(r_read_beats),.quarantined(r_q),
        .m_axi_arvalid,.m_axi_arready,.m_axi_araddr,.m_axi_arid,.m_axi_arlen,.m_axi_arsize,.m_axi_arburst,
        .m_axi_rvalid,.m_axi_rready,.m_axi_rdata,.m_axi_rid,.m_axi_rresp,.m_axi_rlast);
    axi128_bitmap_frame_memory #(.IMAGE_WIDTH(W),.IMAGE_HEIGHT(H),.HD_FIXTURE(TEST_BITMAP_HD)) memory(.*);

    byte unsigned source_input[0:S-1],edge_input[0:N-1];
    string directory;integer log_fd,case_fd,metrics_fd,fd,bytes_read,case_id=0,cycle=0,case_start=0,pattern_id=0;
    integer frames=0,rows=0,pixels=0,rejected=0,writer_cases=0,passed=0,aws=0,ws=0,bs=0,ars=0,rs=0;
    logic [63:0] sequence_counter=1;logic have_previous=0;logic [31:0] rng=32'ha9876201;
    function automatic logic edge_value(input integer index,pattern);
        integer x,y;begin x=index%W;y=index/W;
            case(pattern)0:return 1;1:return 0;2:return (x+y)%2;3:return index%17==0;4:return (31*x+7*y)%29<4;5:return edge_input[index]!=0;endcase
            return 0;
        end
    endfunction
    function automatic logic [7:0] rgb_byte(input integer slot,index);
        integer pixel,x,y,ch,f;begin
            if(TEST_BITMAP_HD)return source_input[index]^8'(slot*29);
            pixel=index/3;x=pixel%W;y=pixel/W;ch=index%3;f=slot+1;
            case(ch)0:return 8'(37*x+11*y+3*f);1:return 8'(13*x+47*y+7*f);2:return 8'(53*x+19*y+17*f);endcase
            return 0;
        end
    endfunction
    function automatic logic [53:0] expected_pair(input row_ticket_t t,input integer address);
        integer i,slot,x,y;logic [47:0] rgb;logic [1:0] edge_pair;logic [3:0] ann;
        begin
            i=int'(t.source_y)*W+2*address;slot=int'(t.origin[2:0]);x=2*address;y=int'(t.source_y);
            rgb=t.required_mask[0] ? {rgb_byte(slot,3*i+3),rgb_byte(slot,3*i+4),rgb_byte(slot,3*i+5),rgb_byte(slot,3*i),rgb_byte(slot,3*i+1),rgb_byte(slot,3*i+2)} : 48'd0;
            edge_pair=t.required_mask[1] ? {edge_value(i+1,pattern_id),edge_value(i,pattern_id)} : 2'd0;
            ann=t.required_mask[2] ? {2'(7*(x+1)+3*y+slot+1),2'(7*x+3*y+slot+1)} : 4'd0;
            return {ann,edge_pair,rgb};
        end
    endfunction
    function automatic command_t command_for(input reply_t b,input operation_t op,input logic [7:0] flags);
        command_t c;begin c='0;c.op=op;c.flags=flags;c.source_handle=b.source_handle;c.result_handle=b.result_handle;
            c.origin=b.origin;c.cj=b.cj;c.body=b.body;c.policy=b.policy;return c;end
    endfunction
    function automatic row_ticket_t ticket_for(input reply_t b,input integer y);
        row_ticket_t t;integer mode,sy,mask;
        begin
            mode=int'(b.body[111:109]);sy=y;mask=0;
            case(mode)0:begin mask=y<H/2 ? 1 : 2;sy=2*(y%(H/2));end 1,2:mask=1;3:mask=2;4:mask=3;5:mask=7;endcase
            t={64'(case_id+1),sequence_counter,64'(case_id+100),b.result_handle,b.policy,b.origin,11'(y),11'(sy),3'(mode),3'(mask)};return t;
        end
    endfunction
    // 日志只记录公开接受/交付和holding；所有期望独立，不读取writer/reader内部。
    bit held_wr=0,held_wdone=0,held_out=0,held_reply=0,held_aw=0,held_ar=0,held_w=0;
    logic [544:0] old_wr;logic [24:0] old_wdone;logic [127:0] old_out;reply_t old_reply;
    logic [48:0] old_aw,old_ar;logic [144:0] old_w;
    always @(negedge clk)begin rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};r_out_ready=!rst&&rng[2:0]!=0;end
    always @(posedge clk)if(log_fd)begin
        cycle++;
        if(rst)begin held_wr=0;held_wdone=0;held_out=0;held_reply=0;held_aw=0;held_ar=0;held_w=0;end
        else begin
            if(held_wr&&(!w_req_valid||old_wr!=={w_write,w_addr,w_data}))$fatal(1,"C1 writer RPC holding");
            if(held_wdone&&(!w_done_valid||old_wdone!=={w_done_error,w_done_aborted,w_done_drained,w_count}))$fatal(1,"C1 writer DONE holding");
            if(held_out&&(!r_out_valid||old_out!=={r_out_generation,r_out_address,r_out_data}))$fatal(1,"C1 row pair holding");
            if(held_reply&&(!o_reply_valid||old_reply!==o_reply))$fatal(1,"C1 owner reply holding");
            if(held_aw&&(!m_axi_awvalid||old_aw!=={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst}))$fatal(1,"C1 AW holding");
            if(held_ar&&(!m_axi_arvalid||old_ar!=={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst}))$fatal(1,"C1 AR holding");
            if(held_w&&(!m_axi_wvalid||old_w!=={m_axi_wdata,m_axi_wstrb,m_axi_wlast}))$fatal(1,"C1 W holding");
            held_wr=w_req_valid&&!w_req_ready;old_wr={w_write,w_addr,w_data};held_wdone=w_done_valid&&!w_done_ready;old_wdone={w_done_error,w_done_aborted,w_done_drained,w_count};
            held_out=r_out_valid&&!r_out_ready;old_out={r_out_generation,r_out_address,r_out_data};held_reply=o_reply_valid&&!o_reply_ready;old_reply=o_reply;
            held_aw=m_axi_awvalid&&!m_axi_awready;old_aw={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst};
            held_ar=m_axi_arvalid&&!m_axi_arready;old_ar={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst};held_w=m_axi_wvalid&&!m_axi_wready;old_w={m_axi_wdata,m_axi_wstrb,m_axi_wlast};
            if(o_cmd_valid&&o_cmd_ready)$fwrite(log_fd,"%0d\t%0d\tOCMD\t%0236h\n",case_id,cycle,o_command);
            if(o_reply_valid&&o_reply_ready)$fwrite(log_fd,"%0d\t%0d\tOREPLY\t%0236h\n",case_id,cycle,o_reply);
            if(w_cfg_valid&&w_cfg_ready)$fwrite(log_fd,"%0d\t%0d\tWCFG\t%h %h\n",case_id,cycle,w_cfg_base,w_cfg_id);
            if(w_cfg_rsp_valid&&w_cfg_rsp_ready)$fwrite(log_fd,"%0d\t%0d\tWCFG_REPLY\t%0d\n",case_id,cycle,w_cfg_error);
            if(w_abort_valid)$fwrite(log_fd,"%0d\t%0d\tABORT\t%h\n",case_id,cycle,w_abort_id);
            if(w_in_valid&&w_in_ready)$fwrite(log_fd,"%0d\t%0d\tPIXEL\t%h %0d %0d\n",case_id,cycle,w_in_id,w_in_index,w_in_edge);
            if(w_req_valid&&w_req_ready)$fwrite(log_fd,"%0d\t%0d\tWREQ\t%h %0128h\n",case_id,cycle,w_addr,w_data);
            if(w_rsp_valid&&w_rsp_ready)$fwrite(log_fd,"%0d\t%0d\tWRSP\t%0d %0d\n",case_id,cycle,w_error,w_drained);
            if(w_done_valid&&w_done_ready)$fwrite(log_fd,"%0d\t%0d\tWDONE\t%0d %0d %0d %0d\n",case_id,cycle,w_done_error,w_done_aborted,w_done_drained,w_count);
            if(r_job_valid&&r_job_ready)$fwrite(log_fd,"%0d\t%0d\tRJOB\t%0136h %0236h %0d\n",case_id,cycle,r_ticket,r_bundle,r_job_permitted);
            if(r_job_reply_valid&&r_job_reply_ready)$fwrite(log_fd,"%0d\t%0d\tRACK\t%0d\n",case_id,cycle,r_job_status);
            if(r_out_valid&&r_out_ready)$fwrite(log_fd,"%0d\t%0d\tPAIR\t%h %0d %014h\n",case_id,cycle,r_out_generation,r_out_address,r_out_data);
            if(r_done_valid&&r_done_ready)$fwrite(log_fd,"%0d\t%0d\tRDONE\t%0d %0d %0d %0d %0d\n",case_id,cycle,r_outcome,r_reason,r_drained,r_prepared,r_delivered);
            if(m_axi_awvalid&&m_axi_awready)begin aws++;$fwrite(log_fd,"%0d\t%0d\tAW\t%h %h %h %h %h\n",case_id,cycle,m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst);end
            if(m_axi_wvalid&&m_axi_wready)begin ws++;$fwrite(log_fd,"%0d\t%0d\tW\t%032h %h %0d\n",case_id,cycle,m_axi_wdata,m_axi_wstrb,m_axi_wlast);end
            if(m_axi_bvalid&&m_axi_bready)begin bs++;$fwrite(log_fd,"%0d\t%0d\tB\t%h %h\n",case_id,cycle,m_axi_bid,m_axi_bresp);end
            if(m_axi_arvalid&&m_axi_arready)begin ars++;$fwrite(log_fd,"%0d\t%0d\tAR\t%h %h %h %h %h\n",case_id,cycle,m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst);end
            if(m_axi_rvalid&&m_axi_rready)begin rs++;$fwrite(log_fd,"%0d\t%0d\tR\t%h %h %0d %032h\n",case_id,cycle,m_axi_rid,m_axi_rresp,m_axi_rlast,m_axi_rdata);end
            if(seed_ann_valid)$fwrite(log_fd,"%0d\t%0d\tANN_SEED\t%0d %0d\n",case_id,cycle,seed_ann_slot,seed_ann_source);
            if(w_req_valid&&!w_req_ready)$fwrite(log_fd,"%0d\t%0d\tH_WREQ\t%h %0128h\n",case_id,cycle,w_addr,w_data);
            if(w_done_valid&&!w_done_ready)$fwrite(log_fd,"%0d\t%0d\tH_WDONE\t%0d %0d %0d %0d\n",case_id,cycle,w_done_error,w_done_aborted,w_done_drained,w_count);
            if(o_reply_valid&&!o_reply_ready)$fwrite(log_fd,"%0d\t%0d\tH_OREPLY\t%0236h\n",case_id,cycle,o_reply);
            if(r_job_reply_valid&&!r_job_reply_ready)$fwrite(log_fd,"%0d\t%0d\tH_RACK\t%0d\n",case_id,cycle,r_job_status);
            if(r_out_valid&&!r_out_ready)$fwrite(log_fd,"%0d\t%0d\tH_PAIR\t%h %0d %014h\n",case_id,cycle,r_out_generation,r_out_address,r_out_data);
            if(m_axi_awvalid&&!m_axi_awready)$fwrite(log_fd,"%0d\t%0d\tH_AW\t%h %h %h %h %h\n",case_id,cycle,m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst);
            if(m_axi_arvalid&&!m_axi_arready)$fwrite(log_fd,"%0d\t%0d\tH_AR\t%h %h %h %h %h\n",case_id,cycle,m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst);
            if(m_axi_wvalid&&!m_axi_wready)$fwrite(log_fd,"%0d\t%0d\tH_W\t%032h %h %0d\n",case_id,cycle,m_axi_wdata,m_axi_wstrb,m_axi_wlast);
            if(m_axi_rvalid&&!m_axi_rready)$fwrite(log_fd,"%0d\t%0d\tH_R\t%h %h %0d %032h\n",case_id,cycle,m_axi_rid,m_axi_rresp,m_axi_rlast,m_axi_rdata);
        end
        if(cycle-case_start>100000000)$fatal(1,"C1 watchdog case=%0d",case_id);
    end
    task automatic cold;
        @(negedge clk);rst=1;enable=1;fault_kind=0;rpc_open=1;hold_aw=0;hold_b=0;w_in_valid=0;w_cfg_valid=0;w_cfg_rsp_ready=0;w_abort_valid=0;w_done_ready=0;
        r_job_valid=0;r_job_reply_ready=0;r_cancel_valid=0;r_done_ready=0;o_cmd_valid=0;o_reply_ready=0;seed_ann_valid=0;have_previous=0;
        $fwrite(log_fd,"%0d\t%0d\tCOLD\t0\n",case_id,cycle);repeat(6)@(negedge clk);rst=0;repeat(6)@(negedge clk);case_start=cycle;
    endtask
    task automatic owner_exchange(input command_t c,output reply_t answer);
        @(negedge clk);o_command=c;o_cmd_valid=1;o_reply_ready=0;
        do @(posedge clk);while(!o_cmd_ready);
        @(negedge clk);o_cmd_valid=0;do @(posedge clk);while(!o_reply_valid);answer=o_reply;
        repeat(3)@(negedge clk);o_reply_ready=1;@(posedge clk);@(negedge clk);o_reply_ready=0;
        if(answer.status!=OK)$fatal(1,"C1 owner command=%0d status=%0d",c.op,answer.status);
    endtask
    task automatic configure_writer(input logic [31:0] base,input bit expect_error=0);
        @(negedge clk);w_cfg_base=base;w_cfg_id=64'hfedcaa0000000001+64'(case_id)*256;w_cfg_valid=1;w_cfg_rsp_ready=0;w_done_ready=0;
        do @(posedge clk);while(!w_cfg_ready);
        @(negedge clk);w_cfg_valid=0;do @(posedge clk);while(!w_cfg_rsp_valid);
        if(w_cfg_error!==expect_error)$fatal(1,"C1 cfg reply differs case=%0d",case_id);
        repeat(2)@(negedge clk);w_cfg_rsp_ready=1;@(posedge clk);@(negedge clk);w_cfg_rsp_ready=0;
    endtask
    task automatic send_pixels(input integer count,input integer bad_kind=0);
        for(integer i=0;i<count;i++)begin
            @(negedge clk);w_in_id=bad_kind==2&&i==count-1 ? w_cfg_id^64'd1 : w_cfg_id;
            w_in_index=21'(bad_kind==1&&i==count-1 ? i+1 : i);w_in_edge=edge_value(i,pattern_id);w_in_valid=1;
            do @(posedge clk);while(!w_in_ready);
            @(negedge clk);w_in_valid=0;if(i%19==0)repeat(2)@(negedge clk);
        end
    endtask
    task automatic take_writer_done(input bit error,aborted,input integer count);
        do @(posedge clk);while(!w_done_valid);
        if(w_done_error!==error||w_done_aborted!==aborted||!w_done_drained||w_count!=count)$fatal(1,"C1 writer terminal differs case=%0d count=%0d",case_id,w_count);
        repeat(4)@(negedge clk);w_done_ready=1;@(posedge clk);@(negedge clk);w_done_ready=0;
    endtask
    task automatic read_row(input reply_t b,input integer y,input integer bad_kind=0);
        integer index,before_ar,expected_status;row_ticket_t t;
        begin
            t=ticket_for(b,y);sequence_counter++;r_bundle=b;r_ticket=t;r_job_permitted=1;expected_status=0;
            case(bad_kind)
                1:begin r_job_permitted=0;expected_status=2;end
                2:begin r_bundle.body[271:240]=32'((N+7)/8);r_bundle.body[239:208]=32'((((N+7)/8+15)/16)*16);expected_status=1;end
                3:begin r_bundle.origin^=195'd1;expected_status=1;end
                4:begin r_ticket.result_handle^=64'd1;expected_status=1;end
                5:begin r_bundle.body[111:109]=6;expected_status=1;end
                6:begin r_bundle.body[367:336]=32'(3*N+1);expected_status=1;end
            endcase
            @(negedge clk);r_job_bank=2'(y%3);r_cancel_bank=r_job_bank;r_cancel_ticket=r_ticket;r_cancel_valid=bad_kind==7;r_job_reply_ready=0;r_done_ready=0;r_job_valid=1;before_ar=ars;
            do @(posedge clk);while(!r_job_ready);
            @(negedge clk);r_job_valid=0;r_cancel_valid=0;do @(posedge clk);while(!r_job_reply_valid);
            if(r_job_status!=expected_status)$fatal(1,"C1 reader cfg case=%0d got=%0d expected=%0d",case_id,r_job_status,expected_status);
            repeat(3)@(negedge clk);r_job_reply_ready=1;@(posedge clk);@(negedge clk);r_job_reply_ready=0;
            if(expected_status!=0)begin
                repeat(4)@(negedge clk);if(ars!=before_ar||r_out_valid||r_done_valid)$fatal(1,"C1 rejected row issued IO");rejected++;
            end else if(bad_kind==7)begin
                do @(posedge clk);while(!r_done_valid);
                if(r_outcome!=2||!r_drained||r_prepared||r_delivered||ars!=before_ar)$fatal(1,"C1 same-edge row cancel");
                @(negedge clk);r_done_ready=1;@(posedge clk);@(negedge clk);r_done_ready=0;rejected++;
            end else begin
                index=0;
                while(index<P)begin
                    @(posedge clk);
                    if(r_out_valid&&r_out_ready)begin
                        if(r_out_generation!=t.generation||r_out_address!=index||r_out_data!==expected_pair(t,index)||r_saved_ticket!==t)$fatal(1,"C1 pair case=%0d y=%0d index=%0d got=%h expected=%h",case_id,y,index,r_out_data,expected_pair(t,index));
                        index++;pixels+=2;
                    end
                end
                do @(posedge clk);while(!r_done_valid);
                if(r_outcome||!r_drained||r_prepared!=P||r_delivered!=P)$fatal(1,"C1 reader terminal");
                repeat(3)@(negedge clk);r_done_ready=1;@(posedge clk);@(negedge clk);r_done_ready=0;rows++;
            end
        end
    endtask
    task automatic frame_case(input integer mode,pattern);
        command_t c;reply_t answer,source;logic [111:0] render;
        begin
            pattern_id=pattern;case_start=cycle;$fwrite(log_fd,"%0d\t%0d\tFRAME\t%0d %0d\n",case_id,cycle,mode,pattern);
            c='0;c.op=ALLOC_SOURCE;c.origin[130:67]=64'haaaa000000000001+64'(case_id);owner_exchange(c,source);
            owner_exchange(command_for(source,SOURCE_EOF,0),answer);owner_exchange(command_for(source,SOURCE_END,7),answer);
            c=command_for(source,ALLOC_RESULT,0);c.cj={1'b0,1'b0,11'd64,11'd0,11'(H),11'(W),32'(case_id+1),source.origin[130:67]};
            render={3'(mode),11'(H/2),24'hff0000,24'h00ff00,24'hffffff,24'hffff00,2'd3};c.body={288'd0,render};owner_exchange(c,allocated);
            if(allocated.body[399:112]!=={32'(allocated.source_slot)*32'h00800000,32'(3*N),32'(S),
                (mode==1||mode==2 ? 96'd0 : {32'h03000000+32'(allocated.result_slot)*32'h00800000,32'((N+7)/8),32'(E)}),
                (mode==5 ? {32'h03100000+32'(allocated.result_slot)*32'h00800000,32'(4224+(N+3)/4),32'(A)} : 96'd0)})$fatal(1,"C1 owner A64 descriptors");
            @(negedge clk);seed_ann_slot=allocated.result_slot;seed_ann_source=allocated.source_slot;seed_ann_valid=1;@(posedge clk);@(negedge clk);seed_ann_valid=0;
            if(mode!=1&&mode!=2)begin configure_writer(allocated.body[303:272]);send_pixels(N);take_writer_done(0,0,N);end
            owner_exchange(command_for(allocated,RESULT_END,7),answer);owner_exchange(command_for(allocated,OFFER,0),offered);owner_exchange(command_for(offered,APPLY,0),answer);
            if(have_previous)owner_exchange(command_for(previous_bundle,RETIRE,8'h0a),answer);
            for(integer y=0;y<H;y++)read_row(offered,y);
            previous_bundle=offered;have_previous=1;frames++;passed++;$fwrite(case_fd,"%0d\tFRAME\t%0d %0d\n",case_id,mode,pattern);case_id++;
        end
    endtask
    task automatic writer_negative(input integer kind);
        integer count;logic [544:0] held;
        begin
            case_start=cycle;pattern_id=2;$fwrite(log_fd,"%0d\t%0d\tWNEG\t%0d\n",case_id,cycle,kind);
            case(kind)
                0:configure_writer(32'h03000001,1);
                1:begin
                    if(E>64)configure_writer(32'hffffffc0,1);
                    else begin configure_writer(32'hffffffc0);send_pixels(N);take_writer_done(1,0,N);end
                end
                2,3:begin configure_writer(32'h03000000);send_pixels(1,kind==2 ? 1 : 2);take_writer_done(1,0,1);end
                4:begin
                    configure_writer(32'h03000000);rpc_open=0;count=N<512?N:512;send_pixels(count);do @(posedge clk);while(!w_req_valid);
                    held={w_write,w_addr,w_data};@(negedge clk);w_abort_id=w_cfg_id;w_abort_valid=1;repeat(4)@(negedge clk);
                    if(!w_req_valid||held!=={w_write,w_addr,w_data})$fatal(1,"C1 canceled public request lost");w_abort_valid=0;rpc_open=1;take_writer_done(1,1,count);
                end
                5:begin fault_kind=1;configure_writer(32'h03000000);count=N<512?N:512;send_pixels(count);take_writer_done(1,0,count);fault_kind=0;end
                6:begin
                    fault_kind=2;configure_writer(32'h03000000);count=N<512?N:512;send_pixels(count);do @(posedge clk);while(!w_q);
                    repeat(30)@(negedge clk);if(w_cfg_ready||w_done_valid)$fatal(1,"C1 unsafe writer reused");$fwrite(log_fd,"%0d\t%0d\tWQ\t1\n",case_id,cycle);cold();
                end
                7:begin
                    configure_writer(32'h03000000);@(negedge clk);w_abort_id=w_cfg_id^64'd1;w_abort_valid=1;send_pixels(N);w_abort_valid=0;take_writer_done(0,0,N);
                end
                8:begin configure_writer(32'h03000000);send_pixels(1);@(negedge clk);w_abort_id=w_cfg_id;w_abort_valid=1;repeat(2)@(negedge clk);w_abort_valid=0;take_writer_done(1,1,1);end
            endcase
            writer_cases++;passed++;$fwrite(case_fd,"%0d\tWNEG\t%0d\n",case_id,kind);case_id++;
        end
    endtask
    initial begin
        o_command='0;r_ticket='0;r_cancel_ticket='0;r_bundle='0;
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected BITMAP CONSUMER fatal probe");
        if(!$value$plusargs("RUN_DIR=%s",directory))$fatal(1,"C1 RUN_DIR");
        if(TEST_BITMAP_HD)begin
            fd=$fopen({directory,"/source-input.bin"},"rb");bytes_read=$fread(source_input,fd);$fclose(fd);if(bytes_read!=S)$fatal(1,"C1 HD Source bytes");
            fd=$fopen({directory,"/edge-input.bin"},"rb");bytes_read=$fread(edge_input,fd);$fclose(fd);if(bytes_read!=N)$fatal(1,"C1 HD edge pixels");
        end
        log_fd=$fopen({directory,"/consumer-events.tsv"},"w");case_fd=$fopen({directory,"/consumer-cases.tsv"},"w");cold();
        if(TEST_BITMAP_HD)frame_case(4,5);
        else begin
            frame_case(4,0);frame_case(4,1);frame_case(4,1);frame_case(4,2);frame_case(0,3);frame_case(1,3);frame_case(2,3);frame_case(3,4);frame_case(5,2);
            for(integer kind=1;kind<=7;kind++)begin
                if(kind!=2||((((N+7)/8+15)/16)*16!=E))begin
                    case_start=cycle;$fwrite(log_fd,"%0d\t%0d\tRNEG\t%0d\n",case_id,cycle,kind);read_row(offered,0,kind);passed++;$fwrite(case_fd,"%0d\tRNEG\t%0d\n",case_id,kind);case_id++;
                end
            end
            for(integer kind=0;kind<9;kind++)writer_negative(kind);
        end
        repeat(6)@(negedge clk);
        metrics_fd=$fopen({directory,"/consumer-metrics.json"},"w");
        $fwrite(metrics_fd,"{\"finished\":true,\"width\":%0d,\"height\":%0d,\"hd\":%0d,\"cases\":%0d,\"frames\":%0d,\"rows\":%0d,\"pixels\":%0d,\"rejected\":%0d,\"writer_cases\":%0d,\"cycles\":%0d,\"aw\":%0d,\"w\":%0d,\"b\":%0d,\"ar\":%0d,\"r\":%0d}\n",W,H,TEST_BITMAP_HD,passed,frames,rows,pixels,rejected,writer_cases,cycle,aws,ws,bs,ars,rs);
        $fclose(metrics_fd);$fclose(log_fd);$fclose(case_fd);log_fd=0;finished=1;$finish;
    end
endmodule
