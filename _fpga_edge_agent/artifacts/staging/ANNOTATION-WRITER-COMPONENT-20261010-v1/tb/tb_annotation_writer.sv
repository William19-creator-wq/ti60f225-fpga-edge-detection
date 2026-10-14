`timescale 1ns/1ps
// AW01..08：真实ANN writer/bridge/owner lookup/reader；Source、EDGE是明示夹具。
module tb_annotation_writer #(
    parameter integer TEST_W = 34, TEST_H = 20, TEST_HD = 0
);
    import frame_owner_pkg::*;
    import display_row_pkg::*;
    import display_fetch_pkg::*;
    localparam integer N=TEST_W*TEST_H, P=N/2, ROW_PAIRS=TEST_W/2;
    localparam integer ANN_ALLOC=((4224+(N+3)/4+63)/64)*64;
    logic clk=0,rst=1,finished=0;
    always #5 clk=~clk;
    wire safe_reset_n=!rst;
    logic enable=1,random_stalls=1,hold_aw=0,hold_w=0,hold_ar=0,hold_b=0,hold_r=0;
    integer fault_kind=0;

    wire m_axi_awvalid,m_axi_awready,m_axi_wvalid,m_axi_wready,m_axi_wlast,m_axi_bvalid,m_axi_bready;
    wire m_axi_arvalid,m_axi_arready,m_axi_rvalid,m_axi_rready,m_axi_rlast;
    wire [31:0] m_axi_awaddr,m_axi_araddr;
    wire [3:0] m_axi_awid,m_axi_bid,m_axi_arid,m_axi_rid;
    wire [7:0] m_axi_awlen,m_axi_arlen;
    wire [2:0] m_axi_awsize,m_axi_arsize;
    wire [1:0] m_axi_awburst,m_axi_arburst,m_axi_bresp,m_axi_rresp;
    wire [127:0] m_axi_wdata,m_axi_rdata;
    wire [15:0] m_axi_wstrb;
    wire writing,b_pending,reading;

    logic job_valid=0,job_reply_ready=0;
    reply_t job_bundle;
    wire job_ready,job_reply_valid,job_reply_error;
    logic header_valid=0,body_valid=0,cancel_valid=0,done_ready=0,rpc_open=1;
    logic [511:0] header_data=0;
    logic [6:0] header_index=0;
    logic [63:0] header_handle=0,body_handle=0,cancel_handle=0;
    logic [3:0] body_pair=0;
    logic [20:0] body_index=0;
    logic body_last=0;
    wire header_ready,body_ready,done_valid,done_drained,w_q;
    wire [63:0] done_handle;
    wire [95:0] done_scope;
    wire [194:0] done_origin;
    wire [1:0] done_outcome;
    wire [7:0] done_reason;
    wire [6:0] done_headers;
    wire [21:0] done_pairs,done_lines;
    wire w_req_valid,w_req_ready,w_write,w_rsp_valid,w_rsp_ready,w_error,w_drained;
    wire [31:0] w_addr;
    wire [511:0] w_data;

    annotation_frame_writer #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H)) writer(
        .clk,.rst,.job_valid,.job_ready,.job_bundle,.job_reply_valid,.job_reply_ready,.job_reply_error,
        .header_valid,.header_ready,.header_data,.header_index,.header_handle,
        .body_valid,.body_ready,.body_pair,.body_index,.body_handle,.body_last,
        .cancel_valid,.cancel_handle,.done_valid,.done_ready,.done_handle,.done_scope,.done_origin,
        .done_outcome,.done_reason,.done_headers,.done_pairs,.done_lines,.done_drained,.quarantined(w_q),
        .line_req_valid(w_req_valid),.line_req_ready(w_req_ready),.line_write(w_write),.line_addr(w_addr),.line_wdata(w_data),
        .line_rsp_valid(w_rsp_valid),.line_rsp_ready(w_rsp_ready),.line_error(w_error),.line_drained(w_drained));

    wire [1:0] c_req_valid,c_req_ready,c_rsp_valid,c_rsp_ready,c_error,c_drained;
    wire [31:0] c_addr[0:1];wire [511:0] c_data[0:1];
    wire write_busy,write_q,bridge_q,local_q;wire [2:0] write_fault;
    assign c_req_valid={1'b0,w_req_valid&&rpc_open};
    assign w_req_ready=rpc_open&&c_req_ready[0];
    assign c_addr[0]=w_addr;assign c_addr[1]=0;
    assign c_data[0]=w_data;assign c_data[1]=0;
    assign c_rsp_ready={1'b0,w_rsp_ready};
    assign w_rsp_valid=c_rsp_valid[0];assign w_error=c_error[0];assign w_drained=c_drained[0];
    axi_write_pair_service writes(
        .clk,.rst,.enable,.c_req_valid,.c_req_ready,.c_addr,.c_data,.c_rsp_valid,.c_rsp_ready,.c_error,.c_drained,
        .m_axi_awvalid,.m_axi_awready,.m_axi_awaddr,.m_axi_awid,.m_axi_awlen,.m_axi_awsize,.m_axi_awburst,
        .m_axi_wvalid,.m_axi_wready,.m_axi_wdata,.m_axi_wstrb,.m_axi_wlast,
        .m_axi_bvalid,.m_axi_bready,.m_axi_bid,.m_axi_bresp,
        .busy(write_busy),.quarantined(write_q),.bridge_quarantined(bridge_q),.local_quarantined(local_q),.fault_reason(write_fault));

    command_t o_command;reply_t o_reply,allocated,offered,previous_bundle;
    logic o_cmd_valid=0,o_reply_ready=0;
    wire o_cmd_ready,o_reply_valid;
    logic [63:0] offer_sequence=1;
    logic lookup_valid=0;
    demand_t lookup_demand;
    wire lookup_ready,lookup_permitted;
    wire [941:0] lookup_bundle;
    wire [17:0] source_states;wire [8:0] result_states;
    wire [63:0] latest_handle,freeze_handle,policy;
    wire frozen,owner_q,source_exhausted,result_exhausted;
    frame_owner_read_authority #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H),.FRAME_ALIGNMENT(64)) owner(
        .core_clk(clk),.safe_reset_n,.cmd_valid(o_cmd_valid),.cmd_ready(o_cmd_ready),.command(o_command),
        .offer_sequence,.lookup_valid,.lookup_ready,.lookup_demand,.lookup_permitted,.lookup_bundle,
        .reply_valid(o_reply_valid),.reply_ready(o_reply_ready),.reply(o_reply),.source_states,.result_states,
        .latest_handle,.freeze_handle,.policy,.frozen,.quarantined(owner_q),.source_exhausted,.result_exhausted);

    logic r_job_valid=0,r_job_reply_ready=0,r_job_permitted=0,r_done_ready=0,r_out_ready=0;
    logic [1:0] r_job_bank=0;
    row_ticket_t r_ticket;
    reply_t r_bundle;
    wire r_job_ready,r_job_reply_valid,r_out_valid,r_done_valid,r_drained,r_q;
    wire [2:0] r_job_status;
    wire [1:0] r_saved_bank,r_outcome;
    wire [7:0] r_reason;
    wire [542:0] r_saved_ticket;
    wire [53:0] r_out_data;
    wire [9:0] r_out_address;
    wire [63:0] r_out_generation;
    wire [10:0] r_prepared,r_delivered;
    wire [31:0] r_read_beats;
    display_row_reader #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H),.FRAME_ALIGNMENT(64)) reader(
        .clk,.rst,.enable,.job_valid(r_job_valid),.job_ready(r_job_ready),.job_bank(r_job_bank),.job_ticket(r_ticket),
        .job_bundle(r_bundle),.job_permitted(r_job_permitted),.job_reply_valid(r_job_reply_valid),.job_reply_ready(r_job_reply_ready),
        .job_reply_status(r_job_status),.saved_bank(r_saved_bank),.saved_ticket(r_saved_ticket),
        .out_valid(r_out_valid),.out_ready(r_out_ready),.out_data(r_out_data),.out_address(r_out_address),.out_generation(r_out_generation),
        .cancel_valid(1'b0),.cancel_bank(2'd0),.cancel_ticket(543'd0),
        .done_valid(r_done_valid),.done_ready(r_done_ready),.outcome(r_outcome),.reason(r_reason),.drained(r_drained),
        .prepared_pairs(r_prepared),.delivered_pairs(r_delivered),.read_beats(r_read_beats),.quarantined(r_q),
        .m_axi_arvalid,.m_axi_arready,.m_axi_araddr,.m_axi_arid,.m_axi_arlen,.m_axi_arsize,.m_axi_arburst,
        .m_axi_rvalid,.m_axi_rready,.m_axi_rdata,.m_axi_rid,.m_axi_rresp,.m_axi_rlast);
    axi128_annotation_memory #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H)) memory(.*);

    string directory;
    integer log_fd,case_fd,metrics_fd,case_id=0,cycle=0,case_start=0,pattern_id=0;
    integer frames=0,rows=0,pixels=0,protocol_cases=0,queries=0,passed=0;
    integer aws=0,ws=0,bs=0,ars=0,rs=0;
    logic have_previous=0;
    logic [63:0] read_sequence=0;
    logic [31:0] rng=32'ha9876201;

    function automatic logic [1:0] label_value(input integer i,pattern,source_slot);
        integer x,y;
        begin
            x=i%TEST_W;y=i/TEST_W;
            case(pattern)
                0:return 2'd3;
                1:return 2'd0;
                2:return 2'(x+2*y+source_slot);
                3:return i%17==0 ? 2'd2 : 2'd0;
            endcase
            return 2'd0;
        end
    endfunction
    function automatic logic [511:0] header_value(input integer index);
        logic [511:0] data;
        begin
            for(integer b=0;b<64;b++)
                data[b*8+:8]=8'((index*64+b)*37+index*11+pattern_id*17+case_id*3);
            return data;
        end
    endfunction
    function automatic logic [7:0] rgb_byte(input integer slot,index);
        integer i,x,y,ch,f;
        begin
            i=index/3;x=i%TEST_W;y=i/TEST_W;ch=index%3;f=slot+1;
            case(ch)
                0:return 8'(37*x+11*y+3*f);
                1:return 8'(13*x+47*y+7*f);
                2:return 8'(53*x+19*y+17*f);
            endcase
            return 0;
        end
    endfunction
    function automatic logic edge_value(input integer i);
        return (7*(i%TEST_W)+3*(i/TEST_W))%9<2;
    endfunction
    function automatic logic [53:0] expected_pair(input row_ticket_t t,input integer address);
        integer i,s;
        begin
            i=int'(t.source_y)*TEST_W+2*address;s=int'(t.origin[2:0]);
            return {label_value(i+1,pattern_id,s),label_value(i,pattern_id,s),edge_value(i+1),edge_value(i),
                rgb_byte(s,3*i+3),rgb_byte(s,3*i+4),rgb_byte(s,3*i+5),rgb_byte(s,3*i),rgb_byte(s,3*i+1),rgb_byte(s,3*i+2)};
        end
    endfunction
    function automatic command_t command_for(input reply_t b,input operation_t op,input logic [7:0] flags);
        command_t c;
        begin
            c='0;c.op=op;c.flags=flags;c.source_handle=b.source_handle;c.result_handle=b.result_handle;
            c.origin=b.origin;c.cj=b.cj;c.body=b.body;c.policy=b.policy;return c;
        end
    endfunction
    function automatic row_ticket_t ticket_for(input reply_t b,input integer y);
        return {64'(case_id+1),read_sequence,64'(case_id+100),b.result_handle,b.policy,b.origin,
            11'(y),11'(y),3'd5,3'd7};
    endfunction

    // 每拍检查公开保持；独立日志只记真实交接，不把stall当新数据。
    bit held_req=0,held_done=0,held_ack=0,held_out=0,held_aw=0,held_w=0,held_ar=0;
    logic [544:0] old_req;
    logic [416:0] old_done;
    logic old_ack;
    logic [127:0] old_out;
    logic [48:0] old_aw,old_ar;
    logic [144:0] old_w;
    always @(negedge clk) begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        r_out_ready=!rst&&rng[2:0]!=0;
    end
    always @(posedge clk) if(log_fd) begin
        cycle++;
        if(rst) begin
            held_req=0;held_done=0;held_ack=0;held_out=0;held_aw=0;held_w=0;held_ar=0;
        end else begin
            if(held_req&&(!w_req_valid||old_req!=={w_write,w_addr,w_data}))$fatal(1,"ANN RPC holding");
            if(held_done&&(!done_valid||old_done!=={done_handle,done_scope,done_origin,done_outcome,done_reason,done_headers,done_pairs,done_lines,done_drained}))$fatal(1,"ANN DONE holding");
            if(held_ack&&(!job_reply_valid||old_ack!==job_reply_error))$fatal(1,"ANN ACK holding");
            if(held_out&&(!r_out_valid||old_out!=={r_out_generation,r_out_address,r_out_data}))$fatal(1,"ANN reader holding");
            if(held_aw&&(!m_axi_awvalid||old_aw!=={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst}))$fatal(1,"ANN AW holding");
            if(held_ar&&(!m_axi_arvalid||old_ar!=={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst}))$fatal(1,"ANN AR holding");
            if(held_w&&(!m_axi_wvalid||old_w!=={m_axi_wdata,m_axi_wstrb,m_axi_wlast}))$fatal(1,"ANN W holding");
            held_req=w_req_valid&&!w_req_ready;old_req={w_write,w_addr,w_data};
            held_done=done_valid&&!done_ready;old_done={done_handle,done_scope,done_origin,done_outcome,done_reason,done_headers,done_pairs,done_lines,done_drained};
            held_ack=job_reply_valid&&!job_reply_ready;old_ack=job_reply_error;
            held_out=r_out_valid&&!r_out_ready;old_out={r_out_generation,r_out_address,r_out_data};
            held_aw=m_axi_awvalid&&!m_axi_awready;old_aw={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst};
            held_ar=m_axi_arvalid&&!m_axi_arready;old_ar={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst};
            held_w=m_axi_wvalid&&!m_axi_wready;old_w={m_axi_wdata,m_axi_wstrb,m_axi_wlast};
            if(job_valid&&job_ready)$fwrite(log_fd,"%0d\t%0d\tJOB\t%0236h\n",case_id,cycle,job_bundle);
            if(job_reply_valid&&job_reply_ready)$fwrite(log_fd,"%0d\t%0d\tACK\t%0d\n",case_id,cycle,job_reply_error);
            if(header_valid&&header_ready)$fwrite(log_fd,"%0d\t%0d\tHEADER\t%h %0d %0128h\n",case_id,cycle,header_handle,header_index,header_data);
            if(body_valid&&body_ready)$fwrite(log_fd,"%0d\t%0d\tPIXEL\t%h %0d %h %0d\n",case_id,cycle,body_handle,body_index,body_pair,body_last);
            if(cancel_valid)$fwrite(log_fd,"%0d\t%0d\tCANCEL\t%h\n",case_id,cycle,cancel_handle);
            if(w_req_valid&&w_req_ready)$fwrite(log_fd,"%0d\t%0d\tWREQ\t%h %0128h\n",case_id,cycle,w_addr,w_data);
            if(w_rsp_valid&&w_rsp_ready)$fwrite(log_fd,"%0d\t%0d\tWRSP\t%0d %0d\n",case_id,cycle,w_error,w_drained);
            if(done_valid&&done_ready)$fwrite(log_fd,"%0d\t%0d\tDONE\t%h %h %h %0d %h %0d %0d %0d %0d\n",case_id,cycle,done_handle,done_scope,done_origin,done_outcome,done_reason,done_headers,done_pairs,done_lines,done_drained);
            if(o_cmd_valid&&o_cmd_ready)$fwrite(log_fd,"%0d\t%0d\tOCMD\t%0236h %h\n",case_id,cycle,o_command,offer_sequence);
            if(o_reply_valid&&o_reply_ready)$fwrite(log_fd,"%0d\t%0d\tOREPLY\t%0236h\n",case_id,cycle,o_reply);
            if(lookup_valid&&lookup_ready)$fwrite(log_fd,"%0d\t%0d\tLOOKUP\t%0120h %0d %0236h\n",case_id,cycle,lookup_demand,lookup_permitted,lookup_bundle);
            if(r_job_valid&&r_job_ready)$fwrite(log_fd,"%0d\t%0d\tROW\t%0136h %0236h %0d\n",case_id,cycle,r_ticket,r_bundle,r_job_permitted);
            if(r_out_valid&&r_out_ready)$fwrite(log_fd,"%0d\t%0d\tPAIR\t%h %0d %014h\n",case_id,cycle,r_out_generation,r_out_address,r_out_data);
            if(r_done_valid&&r_done_ready)$fwrite(log_fd,"%0d\t%0d\tRDONE\t%0d %0d %0d %0d %0d %0d\n",case_id,cycle,r_outcome,r_reason,r_drained,r_prepared,r_delivered,r_read_beats);
            if(m_axi_awvalid&&m_axi_awready)begin aws++;$fwrite(log_fd,"%0d\t%0d\tAW\t%h %h %h %h %h\n",case_id,cycle,m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst);end
            if(m_axi_wvalid&&m_axi_wready)begin ws++;$fwrite(log_fd,"%0d\t%0d\tW\t%032h %h %0d\n",case_id,cycle,m_axi_wdata,m_axi_wstrb,m_axi_wlast);end
            if(m_axi_bvalid&&m_axi_bready)begin bs++;$fwrite(log_fd,"%0d\t%0d\tB\t%h %h\n",case_id,cycle,m_axi_bid,m_axi_bresp);end
            if(m_axi_arvalid&&m_axi_arready)begin ars++;$fwrite(log_fd,"%0d\t%0d\tAR\t%h %h %h %h %h\n",case_id,cycle,m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst);end
            if(m_axi_rvalid&&m_axi_rready)begin rs++;$fwrite(log_fd,"%0d\t%0d\tR\t%h %h %0d %032h\n",case_id,cycle,m_axi_rid,m_axi_rresp,m_axi_rlast,m_axi_rdata);end
        end
        if(cycle-case_start>30000000)$fatal(1,"ANN watchdog case=%0d",case_id);
    end

    task automatic cold;
        @(negedge clk);rst=1;enable=1;fault_kind=0;rpc_open=1;
        hold_aw=0;hold_w=0;hold_b=0;hold_ar=0;hold_r=0;
        job_valid=0;job_reply_ready=0;header_valid=0;body_valid=0;cancel_valid=0;done_ready=0;
        o_cmd_valid=0;o_reply_ready=0;lookup_valid=0;r_job_valid=0;r_job_reply_ready=0;r_done_ready=0;
        have_previous=0;offer_sequence=1;
        $fwrite(log_fd,"%0d\t%0d\tCOLD\t0\n",case_id,cycle);
        repeat(6)@(negedge clk);rst=0;repeat(6)@(negedge clk);case_start=cycle;
    endtask
    task automatic owner_exchange(input command_t c,output reply_t answer);
        @(negedge clk);o_command=c;o_cmd_valid=1;o_reply_ready=0;
        do @(posedge clk);while(!o_cmd_ready);
        @(negedge clk);o_cmd_valid=0;
        do @(posedge clk);while(!o_reply_valid);answer=o_reply;
        repeat(2)@(negedge clk);o_reply_ready=1;@(posedge clk);@(negedge clk);o_reply_ready=0;
        if(answer.status!=OK)$fatal(1,"ANN owner op=%0d status=%0d",c.op,answer.status);
    endtask
    task automatic source_fixture;
        command_t c;reply_t s,answer;
        c='0;c.op=ALLOC_SOURCE;c.origin[130:67]=64'h1234000000000001+64'(case_id);
        owner_exchange(c,s);
        $fwrite(log_fd,"%0d\t%0d\tSOURCE_FIXTURE\t%h\n",case_id,cycle,s.source_handle);
        owner_exchange(command_for(s,SOURCE_EOF,0),answer);
        owner_exchange(command_for(s,SOURCE_END,7),answer);
    endtask
    task automatic allocate_work;
        command_t c;
        c='0;c.op=ALLOC_RESULT;
        c.cj={1'b0,1'b0,11'd64,11'd8,11'(TEST_H),11'(TEST_W),32'(case_id+1),64'd0};
        c.body={288'd0,3'd5,11'(TEST_H/2),24'hff0000,24'h00ff00,24'hffffff,24'hffff00,2'd3};
        owner_exchange(c,allocated);
    endtask
    task automatic configure(input reply_t b,input bit expect_error=0,input bit cancel_at_ack=0);
        @(negedge clk);job_bundle=b;job_valid=1;job_reply_ready=0;done_ready=0;
        do @(posedge clk);while(!job_ready);
        @(negedge clk);job_valid=0;
        do @(posedge clk);while(!job_reply_valid);
        if(job_reply_error!==expect_error)$fatal(1,"ANN job ack case=%0d",case_id);
        if(cancel_at_ack)begin @(negedge clk);cancel_handle=b.result_handle;cancel_valid=1;end
        repeat(3)@(negedge clk);job_reply_ready=1;@(posedge clk);@(negedge clk);job_reply_ready=0;cancel_valid=0;
    endtask
    task automatic send_headers(input integer count,input integer bad_kind=0);
        for(integer i=0;i<count;i++)begin
            @(negedge clk);header_data=header_value(i);
            header_index=7'(bad_kind==1&&i==count-1 ? i+1 : i);
            header_handle=bad_kind==2&&i==count-1 ? allocated.result_handle^64'd1 : allocated.result_handle;
            header_valid=1;
            do @(posedge clk);while(!header_ready);
            @(negedge clk);header_valid=0;
            if(i%7==0)repeat(2)@(negedge clk);
        end
    endtask
    task automatic send_body(input integer count,input integer bad_kind=0);
        for(integer i=0;i<count;i++)begin
            @(negedge clk);body_index=21'(bad_kind==1&&i==count-1 ? i+1 : i);
            body_handle=bad_kind==2&&i==count-1 ? allocated.result_handle^64'd1 : allocated.result_handle;
            body_last=bad_kind==3&&i==count-1 ? !(i==P-1) : i==P-1;
            body_pair={label_value(2*i+1,pattern_id,int'(allocated.source_slot)),label_value(2*i,pattern_id,int'(allocated.source_slot))};
            body_valid=1;
            do @(posedge clk);while(!body_ready);
            @(negedge clk);body_valid=0;
            if(i%31==0)repeat(2)@(negedge clk);
        end
    endtask
    task automatic pulse_cancel;
        @(negedge clk);cancel_handle=allocated.result_handle;cancel_valid=1;
        repeat(4)@(negedge clk);cancel_valid=0;
    endtask
    task automatic wait_body_phase;
        // C1：第66个header输入接受后仍有请求/回执债务；公开body_ready才证明阶段完成。
        do @(posedge clk);while(!body_ready);
        @(negedge clk);
    endtask
    task automatic take_done(input integer outcome,headers,pairs,lines,input logic [7:0] reason);
        do @(posedge clk);while(!done_valid);
        if(done_outcome!=outcome||done_reason!==reason||!done_drained||done_headers!=headers||done_pairs!=pairs||done_lines!=lines||
            done_handle!==allocated.result_handle||done_scope!==allocated.cj[95:0]||done_origin!==allocated.origin)
            $fatal(1,"ANN DONE case=%0d outcome=%0d hdr=%0d pair=%0d line=%0d reason=%h",case_id,done_outcome,done_headers,done_pairs,done_lines,done_reason);
        repeat(4)@(negedge clk);done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;
    endtask
    task automatic lookup_check(input row_ticket_t t,input bit permitted,output reply_t answer);
        @(negedge clk);lookup_demand=demand_t'(t[478:0]);lookup_valid=1;
        do @(posedge clk);while(!lookup_ready);
        if(lookup_permitted!==permitted)$fatal(1,"ANN ledger permission case=%0d",case_id);
        answer=lookup_bundle;
        if(!permitted&&answer!==942'd0)$fatal(1,"ANN denied lookup exposed bundle");
        queries++;@(negedge clk);lookup_valid=0;
    endtask
    task automatic read_row(input integer y);
        integer index;row_ticket_t t;reply_t authorized;
        t=ticket_for(offered,y);lookup_check(t,1,authorized);
        @(negedge clk);r_ticket=t;r_bundle=authorized;r_job_permitted=1;r_job_bank=2'(y%3);
        r_job_valid=1;r_job_reply_ready=0;r_done_ready=0;
        do @(posedge clk);while(!r_job_ready);
        @(negedge clk);r_job_valid=0;
        do @(posedge clk);while(!r_job_reply_valid);
        if(r_job_status!=0)$fatal(1,"ANN authorized row rejected");
        repeat(2)@(negedge clk);r_job_reply_ready=1;@(posedge clk);@(negedge clk);r_job_reply_ready=0;
        index=0;
        while(index<ROW_PAIRS)begin
            @(posedge clk);
            if(r_out_valid&&r_out_ready)begin
                if(r_out_address!=index||r_out_generation!=t.generation||r_saved_ticket!==t||r_out_data!==expected_pair(t,index))
                    $fatal(1,"ANN pair case=%0d row=%0d col=%0d got=%h expected=%h",case_id,y,index,r_out_data,expected_pair(t,index));
                index++;pixels+=2;
            end
        end
        do @(posedge clk);while(!r_done_valid);
        if(r_outcome||!r_drained||r_prepared!=ROW_PAIRS||r_delivered!=ROW_PAIRS)$fatal(1,"ANN row close");
        repeat(2)@(negedge clk);r_done_ready=1;@(posedge clk);@(negedge clk);r_done_ready=0;rows++;
    endtask
    task automatic finish_case(input string name,input integer kind);
        passed++;$fwrite(case_fd,"%0d\t%s\t%0d\n",case_id,name,kind);
        $fwrite(log_fd,"%0d\t%0d\tCASE_END\t%s %0d\n",case_id,cycle,name,kind);
        $display("ANN case %0d %s %0d passed cycle=%0d",case_id,name,kind,cycle);case_id++;
    endtask
    task automatic normal_frame(input integer pattern,input bit old_cancel=0);
        reply_t answer;row_ticket_t t;
        pattern_id=pattern;case_start=cycle;
        $fwrite(log_fd,"%0d\t%0d\tCASE\tNORMAL %0d\n",case_id,cycle,pattern);
        source_fixture();allocate_work();configure(allocated);
        read_sequence=offer_sequence;
        t=ticket_for(allocated,0);lookup_check(t,0,answer);
        if(old_cancel)begin @(negedge clk);cancel_handle=allocated.result_handle^64'd1;cancel_valid=1;end
        send_headers(66);send_body(P);cancel_valid=0;
        take_done(0,66,P,(P+127)/128,0);
        owner_exchange(command_for(allocated,RESULT_END,7),answer);lookup_check(t,0,answer);
        owner_exchange(command_for(allocated,OFFER,0),offered);offer_sequence++;
        lookup_check(ticket_for(offered,0),1,answer);
        owner_exchange(command_for(offered,APPLY,0),answer);
        if(have_previous)owner_exchange(command_for(previous_bundle,RETIRE,8'h0a),answer);
        t=ticket_for(offered,0);t.sequence_id^=64'h8000000000000000;lookup_check(t,0,answer);
        t=ticket_for(offered,0);t.origin^=195'd8;lookup_check(t,0,answer);
        for(integer y=0;y<TEST_H;y++)read_row(y);
        previous_bundle=offered;have_previous=1;frames++;
        finish_case("NORMAL",pattern);
    endtask
    task automatic config_case(input integer kind);
        reply_t bad,answer;integer before_aw;
        case_start=cycle;pattern_id=2;$fwrite(log_fd,"%0d\t%0d\tCASE\tCONFIG %0d\n",case_id,cycle,kind);
        allocate_work();bad=allocated;before_aw=aws;
        case(kind)
            0:bad.body[111:109]=4;
            1:bad.body[175:144]+=1;
            2:bad.body[207:176]+=64;
            3:bad.cj[106:96]^=11'd2;
            4:bad.origin[66:3]^=64'd1;
            5:bad.op=OFFER;
            6:bad.status=STATE;
            7:bad.result_slot=3;
            8:bad.source_slot=6;
            9:bad.cj[128:118]=11'd80;
        endcase
        configure(bad,1);repeat(6)@(negedge clk);
        if(aws!=before_aw||done_valid||!job_ready)$fatal(1,"ANN invalid job made IO/DONE");
        owner_exchange(command_for(allocated,DROP_RESULT,6),answer);protocol_cases++;finish_case("CONFIG",kind);
    endtask
    task automatic protocol_case(input integer kind);
        integer count;reply_t answer;
        logic [544:0] held;
        case_start=cycle;pattern_id=2;$fwrite(log_fd,"%0d\t%0d\tCASE\tPROTOCOL %0d\n",case_id,cycle,kind);
        allocate_work();configure(allocated,0,kind==11);
        count=P<128 ? P : 128;
        case(kind)
            0,1:begin send_headers(1,kind+1);take_done(1,0,0,0,8'h02);end
            2,3,4:begin send_headers(66);send_body(1,kind-1);take_done(1,66,1,0,8'h04);end
            5:begin
                rpc_open=0;send_headers(1);do @(posedge clk);while(!w_req_valid);
                held={w_write,w_addr,w_data};pulse_cancel();
                if(done_valid||!w_req_valid||held!=={w_write,w_addr,w_data})$fatal(1,"ANN canceled header request withdrawn");
                rpc_open=1;take_done(2,1,0,0,0);
            end
            6:begin
                hold_w=1;send_headers(1);do @(posedge clk);while(!m_axi_wvalid);
                pulse_cancel();if(done_valid)$fatal(1,"ANN canceled before actual W/B");hold_w=0;take_done(2,1,0,0,0);
            end
            7:begin
                hold_b=1;send_headers(1);do @(posedge clk);while(!b_pending);
                pulse_cancel();if(done_valid)$fatal(1,"ANN canceled before B");hold_b=0;take_done(2,1,0,0,0);
            end
            8:begin
                send_headers(66);wait_body_phase();rpc_open=0;send_body(count);do @(posedge clk);while(!w_req_valid);
                held={w_write,w_addr,w_data};pulse_cancel();
                if(done_valid||!w_req_valid||held!=={w_write,w_addr,w_data})$fatal(1,"ANN canceled body request withdrawn");
                rpc_open=1;take_done(2,66,count,1,0);
            end
            9:begin fault_kind=1;send_headers(1);take_done(1,0,0,0,8'h08);fault_kind=0;end
            10:begin send_headers(66);wait_body_phase();fault_kind=1;send_body(count);take_done(1,66,count,0,8'h08);fault_kind=0;end
            11:take_done(2,0,0,0,0);
            12:begin
                send_headers(66);send_body(1);pulse_cancel();take_done(2,66,1,0,0);
            end
            13:begin
                fault_kind=1;hold_b=1;send_headers(1);do @(posedge clk);while(!b_pending);
                pulse_cancel();hold_b=0;take_done(1,0,0,0,8'h08);fault_kind=0;
            end
            14:begin
                @(negedge clk);header_data=header_value(0);header_index=0;header_handle=allocated.result_handle;
                header_valid=1;cancel_valid=1;cancel_handle=allocated.result_handle;
                @(posedge clk);if(header_ready)$fatal(1,"ANN cancel accepted simultaneous header");
                @(negedge clk);header_valid=0;cancel_valid=0;take_done(2,0,0,0,0);
            end
        endcase
        owner_exchange(command_for(allocated,DROP_RESULT,6),answer);protocol_cases++;finish_case("PROTOCOL",kind);
    endtask
    task automatic quarantine_case(input integer body_stage);
        integer count;
        case_start=cycle;pattern_id=2;$fwrite(log_fd,"%0d\t%0d\tCASE\tUNKNOWN %0d\n",case_id,cycle,body_stage);
        if(latest_handle==0)source_fixture();
        allocate_work();configure(allocated);
        if(body_stage)begin send_headers(66);wait_body_phase();end
        fault_kind=2;
        if(body_stage)begin count=P<128 ? P : 128;send_body(count);end
        else send_headers(1);
        do @(posedge clk);while(!w_q);
        repeat(30)@(negedge clk);
        if(done_valid||job_ready||header_ready||body_ready||!write_q)$fatal(1,"ANN UNKNOWN reused or fake DONE");
        $fwrite(log_fd,"%0d\t%0d\tQ\t1\n",case_id,cycle);
        protocol_cases++;finish_case("UNKNOWN",body_stage);cold();
    endtask

    initial begin
        o_command='0;job_bundle='0;r_ticket='0;r_bundle='0;lookup_demand='0;
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected ANNOTATION fatal probe");
        if(!$value$plusargs("RUN_DIR=%s",directory))$fatal(1,"ANN RUN_DIR");
        log_fd=$fopen({directory,"/annotation-events.tsv"},"w");case_fd=$fopen({directory,"/annotation-cases.tsv"},"w");
        cold();
        if(TEST_HD)normal_frame(2);
        else begin
            normal_frame(0);normal_frame(0);normal_frame(1);normal_frame(2,1);normal_frame(3);
            for(integer kind=0;kind<10;kind++)config_case(kind);
            for(integer kind=0;kind<15;kind++)protocol_case(kind);
            quarantine_case(0);quarantine_case(1);normal_frame(1);
        end
        repeat(6)@(negedge clk);
        metrics_fd=$fopen({directory,"/annotation-metrics.json"},"w");
        $fwrite(metrics_fd,"{\"width\":%0d,\"height\":%0d,\"hd\":%0d,\"frames\":%0d,\"rows\":%0d,\"pixels\":%0d,\"protocol_cases\":%0d,\"queries\":%0d,\"passed\":%0d,\"cycles\":%0d,\"aw\":%0d,\"w\":%0d,\"b\":%0d,\"ar\":%0d,\"r\":%0d}\n",
            TEST_W,TEST_H,TEST_HD,frames,rows,pixels,protocol_cases,queries,passed,cycle,aws,ws,bs,ars,rs);
        $fclose(metrics_fd);$fclose(case_fd);$fclose(log_fd);log_fd=0;
        finished=1;$display("ANNOTATION PASS frames=%0d pixels=%0d protocol=%0d",frames,pixels,protocol_cases);$finish;
    end
endmodule
