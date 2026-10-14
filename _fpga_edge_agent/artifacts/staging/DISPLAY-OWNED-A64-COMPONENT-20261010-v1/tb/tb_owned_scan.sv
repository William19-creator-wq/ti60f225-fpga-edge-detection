`timescale 1ns/1ps
// ST21..24：真实owner产生OFFER，真实native资格与fence关闭；不存在TB prepared/closed输入。
module tb_owned_scan #(parameter integer TEST_W=20,TEST_H=8,TEST_FAULTS=1);
    import frame_owner_pkg::*;
    import display_handoff_pkg::*;
    import display_fetch_pkg::*;
    import display_row_pkg::*;
    localparam integer P=TEST_W/2,HT=P+140,VT=TEST_H+45;
    logic core_clk=0,video_clk=0,safe_reset_n=0,video_clock_running=1,video_run=0,finished=0;
    always #5 core_clk=~core_clk;
    always #6.734 if(video_clock_running)video_clk=~video_clk;
    logic [1:0] reset_pipe=3;
    always @(posedge video_clk or negedge safe_reset_n)
        if(!safe_reset_n)reset_pipe<=3;else reset_pipe<={reset_pipe[0],1'b0};
    wire de,hs,vs,start;wire [10:0] x,y;
    logic [10:0] small_h=0,small_v=0;
    generate if(TEST_W==1920 && TEST_H==1080)begin
        video_timing_1080p_pair timing(.clk(video_clk),.rst(!video_run || reset_pipe!=0),.de,.hs,.vs,.frame_start(start),.x_even(x),.y);
    end else begin
        always @(posedge video_clk)if(!video_run || reset_pipe!=0)begin small_h<=0;small_v<=0;end
            else if(small_h==HT-1)begin small_h<=0;small_v<=small_v==VT-1 ? 0 : small_v+1'b1;end
            else small_h<=small_h+1'b1;
        assign de=small_h<P && small_v<TEST_H;assign hs=small_h>=P+44 && small_h<P+66;
        assign vs=small_v>=TEST_H+4 && small_v<TEST_H+9;assign start=small_h==0 && small_v==0;
        assign x=de ? 11'(2*small_h) : 0;assign y=de ? small_v : 0;
    end endgenerate
    wire raw_de=video_run && de,raw_hs=video_run && hs,raw_vs=video_run && vs,raw_start=video_run && start;
    logic control_valid=0,control_response_ready=0,cancel_valid=0,old_closed_ready=1;
    wire control_ready,control_response_valid;
    route_request_t control_request;
    route_response_t response_view,last_response;
    wire [1206:0] control_response;
    logic [63:0] cancel_sequence=0,sequence_counter=64'h1234000000000001,stall_result=0;
    wire lookup_valid,lookup_ready;wire [478:0] lookup_demand;
    reply_t lookup_bundle;
    wire lookup_permitted;logic root_retire_capacity;
    wire old_closed_valid;wire [386:0] old_closed_ref;
    wire arvalid,arready,rvalid,rready,rlast;
    wire [31:0] araddr,ar_count,r_count;
    wire [3:0] arid,rid;wire [7:0] arlen;wire [2:0] arsize;wire [1:0] arburst,rresp;wire [127:0] rdata;
    wire [47:0] rgb;wire out_de,out_hs,out_vs,out_start;wire [10:0] out_x,out_y;wire [1:0] error;
    wire active_valid,frozen,committed,snapshot_hold,q;
    wire [941:0] active_bundle;wire [63:0] active_sequence,scan_token,video_policy;wire [31:0] underruns;
    logic cmd_valid=0,reply_ready=0;wire cmd_ready,reply_valid;
    command_t command;wire [941:0] reply;
    wire [17:0] source_states;wire [8:0] result_states;
    wire [63:0] latest_handle,freeze_handle,owner_policy;wire owner_frozen,owner_q,source_exhausted,result_exhausted;
    reply_t owner_reply,sources_saved[0:15],offers_saved[0:15];
    frame_ref_t closed_saved[0:15];
    logic [2:0][2:0] source_for_result=0;
    request_t service_view;
    demand_t lookup_view;
    wire ar_pause=stall_result!=0 && service_view.demand.result_handle==stall_result;
    wire slave_idle;
    integer journal,owner_journal,outfile,nativefile,metrics,owner_metrics;
    integer transactions=0,frame_counter=0,frames=0,completed_frames=0,vs_count=0,changes=0,closed_count=0,retired_count=0;
    integer writes=0,pops=0,requests=0,returns=0,internal_returns=0,lookup_count=0,output_slots=0,missed_tests=0,cancel_tests=0,holds=0;
    integer tag0=0,tag1=0;
    logic [63:0] frame_tags[0:63];
    logic previous_vs=0,previous_candidate=0,previous_cancel=0;
    logic [63:0] last_candidate_seq=0,last_candidate_scan=0;
    logic [2:0] return_pending=0;
    logic [2:0][544:0] sent_return;
    logic [480:0] held_request;
    logic held_request_valid=0;
    logic last_transport_live=0;
    logic [386:0] held_old_ref;logic held_old_valid=0;
    assign response_view=control_response;assign service_view=dut.scan.service_request;assign lookup_view=lookup_demand;
    // DA03：容量观察实际owner；只读授权由dut.owner直接提供。
    always_comb begin
        integer retiring;retiring=0;
        for(integer r=0;r<3;r++)if(result_states[r*3+:3]==R_RETIRING)retiring++;
        root_retire_capacity=retiring<2;
    end
    display_owned_scan #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H)) dut (
        .cmd_valid,.cmd_ready,.command,.offer_sequence(sequence_counter),.reply_valid,.reply_ready,.reply,
        .source_states,.result_states,.latest_handle,.freeze_handle,.owner_policy,.owner_frozen,
        .owner_quarantined(owner_q),.source_exhausted,.result_exhausted,
        .core_clk,.video_clk,.safe_reset_n,.enable(1'b1),.control_valid,.control_ready,.control_request,
        .control_response_valid,.control_response_ready,.control_response,.cancel_valid,.cancel_sequence,.root_retire_capacity,
        .in_de(raw_de),.in_hs(raw_hs),.in_vs(raw_vs),.in_frame_start(raw_start),.in_x_even(x),.in_y(y),
        .out_rgb_pair(rgb),.out_de,.out_hs,.out_vs,.out_frame_start(out_start),.out_x_even(out_x),.out_y,.out_error(error),
        .lookup_valid,.lookup_ready,.lookup_demand,.lookup_bundle,.lookup_permitted,
        .old_closed_valid,.old_closed_ready,.old_closed_ref,
        .m_axi_arvalid(arvalid),.m_axi_arready(arready),.m_axi_araddr(araddr),.m_axi_arid(arid),.m_axi_arlen(arlen),.m_axi_arsize(arsize),.m_axi_arburst(arburst),
        .m_axi_rvalid(rvalid),.m_axi_rready(rready),.m_axi_rdata(rdata),.m_axi_rid(rid),.m_axi_rresp(rresp),.m_axi_rlast(rlast),
        .active_valid,.active_bundle,.active_sequence,.scan_token,.video_policy,.frozen,.committed,.snapshot_hold,.quarantined(q),.underrun_lines(underruns));
    axi_read_byte_slave #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H)) memory (
        .clk(core_clk),.rst(!safe_reset_n),.source_for_result,.ideal(1'b1),.ar_pause,.r_pause(1'b0),.fault_mode(3'd0),
        .arvalid,.arready,.araddr,.arid,.arlen,.arsize,.arburst,.rvalid,.rready,.rdata,.rid,.rresp,.rlast,.ar_count,.r_count,.idle(slave_idle));
    function automatic command_t source_command(input integer op,input reply_t b,input logic [7:0] flags=0);
        command_t c;c='0;c.op=4'(op);c.flags=flags;c.source_handle=b.source_handle;c.origin=b.origin;return c;
    endfunction
    function automatic command_t result_command(input integer op,input reply_t b,input logic [7:0] flags=0);
        command_t c;c='0;c.op=4'(op);c.flags=flags;c.source_handle=b.source_handle;c.result_handle=b.result_handle;
        c.origin=b.origin;c.cj=b.cj;c.policy=b.policy;return c;
    endfunction
    task automatic owner_exchange(input command_t c);
        reply_t saved;
        @(negedge core_clk);while(!cmd_ready)@(negedge core_clk);command=c;cmd_valid=1;
        @(negedge core_clk);cmd_valid=0;wait(reply_valid);@(negedge core_clk);saved=reply;
        if(saved.status!=OK)$fatal(1,"Actual owner rejected op=%0d status=%0d",c.op,saved.status);
        $fdisplay(owner_journal,"EVENT,%h,%h,%h,%h,%h,%h,%h,%b,%b,%b,%b",c,saved,source_states,result_states,latest_handle,freeze_handle,owner_policy,owner_frozen,owner_q,source_exhausted,result_exhausted);
        $fdisplay(journal,"{\"event\":\"owner\",\"command\":\"%h\",\"reply\":\"%h\",\"offer_sequence\":\"%h\"}",c,saved,sequence_counter);
        owner_reply=saved;transactions++;reply_ready=1;@(negedge core_clk);reply_ready=0;
    endtask
    task automatic make_source(input integer index);
        command_t c;c='0;c.op=ALLOC_SOURCE;frame_counter++;c.origin[130:67]={32'(frame_counter),32'h77};
        owner_exchange(c);sources_saved[index]=owner_reply;
        // 该Source是标准byte-slave的已完成数学输入，非摄像头实际闭合。
        owner_exchange(source_command(SOURCE_EOF,sources_saved[index]));owner_exchange(source_command(SOURCE_END,sources_saved[index],7));
    endtask
    task automatic make_offer(input integer index,input integer source_index,input integer mode);
        command_t c;c='0;c.op=ALLOC_RESULT;c.source_handle=sources_saved[source_index].source_handle;c.origin=sources_saved[source_index].origin;
        c.cj={1'b1,1'b1,11'd320,11'd64,11'(TEST_H),11'(TEST_W),32'(index+1),64'd0};
        c.body={288'd0,3'(mode),11'(TEST_H/2),24'hff0000,24'h00ff00,24'h00a0ff,24'hffff00,2'b11};
        owner_exchange(c);offers_saved[index]=owner_reply;
        owner_exchange(result_command(RESULT_END,offers_saved[index],7));owner_exchange(result_command(OFFER,offers_saved[index]));
        offers_saved[index]=owner_reply;source_for_result[owner_reply.result_slot]=owner_reply.source_slot;
        $fdisplay(journal,"{\"event\":\"offer\",\"bundle\":\"%h\"}",owner_reply);
    endtask
    task automatic submit(input integer kind,input logic [941:0] bundle=0,input logic [63:0] target=1,input logic [63:0] cause=0);
        route_request_t c;c='0;c.kind=3'(kind);c.sequence_id=sequence_counter;sequence_counter++;c.bundle=bundle;c.target_policy=target;c.cause=cause;
        @(negedge core_clk);while(!control_ready)@(negedge core_clk);control_request=c;control_valid=1;
        @(negedge core_clk);control_valid=0;
    endtask
    task automatic receive(input integer expected=0);
        route_response_t b;wait(control_response_valid);@(negedge core_clk);b=control_response;
        if(b.status!=expected)$fatal(1,"Handoff response status=%0d expected=%0d seq=%h",b.status,expected,b.sequence_id);
        last_response=b;control_response_ready=1;@(negedge core_clk);control_response_ready=0;repeat(12)@(negedge core_clk);
    endtask
    task automatic retire_closed;
        integer target;
        while(retired_count<closed_count)begin
            target=-1;
            for(integer i=0;i<16;i++)if(offers_saved[i].result_handle==closed_saved[retired_count].result_handle)target=i;
            if(target<0)$fatal(1,"Closed unknown actual result");
            owner_exchange(result_command(RETIRE,offers_saved[target],8'h0a));retired_count++;
        end
    endtask
    task automatic watch_full(input logic [63:0] seq);
        integer index;
        wait(frames>0 && frame_tags[frames]==seq);index=frames;
        wait(completed_frames>=index);repeat(3)@(negedge video_clk);
        $fdisplay(journal,"{\"event\":\"watched\",\"frame\":%0d,\"sequence\":\"%h\"}",index,seq);
    endtask
    task automatic cancel_current(input logic [63:0] seq);
        @(negedge core_clk);cancel_valid=1;cancel_sequence=seq;
        @(negedge core_clk);cancel_valid=0;
    endtask
    initial begin
        logic [63:0] seq,prepare_seq;integer prior_vs;reply_t pin;command_t c;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        journal=$fopen("scan-events.jsonl","w");owner_journal=$fopen("events.csv","w");outfile=$fopen("output.bin","wb");nativefile=$fopen("native.bin","wb");
        if(!journal || !owner_journal || !outfile || !nativefile)$fatal(1,"Trace file open");
        for(integer i=0;i<16;i++)begin offers_saved[i]=0;sources_saved[i]=0;closed_saved[i]=0;end
        control_request=0;command=0;
        repeat(10)@(negedge core_clk);safe_reset_n=1;repeat(16)@(negedge core_clk);
        $fdisplay(owner_journal,"RESET,%0d,%0d,1",TEST_W,TEST_H);
        $fdisplay(journal,"{\"event\":\"reset\",\"width\":%0d,\"height\":%0d}",TEST_W,TEST_H);
        @(negedge video_clk);video_run=1;
        for(integer mode=0;mode<6;mode++)begin
            make_source(mode);make_offer(mode,mode,mode);seq=sequence_counter;
            if(mode==1)old_closed_ready=0;
            submit(HC_OFFER,offers_saved[mode],owner_policy);receive();
            owner_exchange(result_command(APPLY,offers_saved[mode]));
            if(mode==1)begin
                wait(old_closed_valid);held_old_ref=old_closed_ref;
                repeat(20)begin @(negedge core_clk);if(!old_closed_valid || old_closed_ref!=held_old_ref)$fatal(1,"Closed holding changed");holds++;end
                old_closed_ready=1;repeat(8)@(negedge core_clk);
            end
            retire_closed();watch_full(seq);
        end
        if(TEST_FAULTS)begin
            // 候选真正AR承诺被暂停，错过一次VS；随后兑现并重做新scan，不修改旧票据。
            make_source(6);make_offer(6,6,4);seq=sequence_counter;stall_result=offers_saved[6].result_handle;
            submit(HC_OFFER,offers_saved[6],owner_policy);
            wait(arvalid && ar_pause);prior_vs=vs_count;wait(vs_count>prior_vs);
            @(negedge video_clk);if(active_sequence==seq || dut.scan.prepared_valid)$fatal(1,"Late candidate falsely switched");
            $fdisplay(journal,"{\"event\":\"missed_test\",\"sequence\":\"%h\"}",seq);missed_tests++;
            stall_result=0;receive();
            // B已显示而owner仍A，冻结快照与pin必须B。
            prepare_seq=sequence_counter;submit(HC_PREPARE,0,owner_policy+64'd1);receive();
            if(last_response.bundle!==offers_saved[6] || !snapshot_hold)$fatal(1,"Snapshot did not retain actual B");
            owner_exchange(result_command(FREEZE,offers_saved[6],1));pin=owner_reply;
            submit(HC_COMMIT,pin,owner_policy,prepare_seq);receive();
            owner_exchange(result_command(APPLY,offers_saved[6]));retire_closed();watch_full(seq);
            // 真prepared后取消，原首行必须drain/归还且完整fence才回应closed1。
            make_offer(7,6,2);seq=sequence_counter;submit(HC_OFFER,offers_saved[7],owner_policy);
            wait(dut.scan.prepared_valid);cancel_current(seq);receive(HC_CANCELED);
            if(!last_response.candidate_closed || active_sequence==seq)$fatal(1,"Cancel lacks actual closed");
            owner_exchange(result_command(DROP_RESULT,offers_saved[7],8'h0a));cancel_tests++;
            // AR未接受时取消，valid必须保持直到释放pause并实际握手。
            make_offer(8,6,5);seq=sequence_counter;stall_result=offers_saved[8].result_handle;
            submit(HC_OFFER,offers_saved[8],owner_policy);wait(arvalid && ar_pause);cancel_current(seq);
            wait(dut.scan.cancel_candidate);repeat(30)@(negedge core_clk);
            if(control_response_valid || !arvalid)$fatal(1,"Canceled held AR closed/withdrawn early");
            stall_result=0;receive(HC_CANCELED);if(!last_response.candidate_closed)$fatal(1,"AR cancellation lacks fence");
            owner_exchange(result_command(DROP_RESULT,offers_saved[8],8'h0a));cancel_tests++;
            make_offer(9,6,2);seq=sequence_counter;submit(HC_OFFER,offers_saved[9],owner_policy);receive();
            owner_exchange(result_command(APPLY,offers_saved[9]));retire_closed();watch_full(seq);
            submit(HC_RESUME,0,owner_policy+64'd1);receive();c='0;c.op=RESUME;owner_exchange(c);
            if(frozen || owner_frozen || active_bundle!==offers_saved[9])$fatal(1,"Resume replaced immutable active");
        end
        // 保留最终持续显示对象；停在消隐且实际取数无IO后，不宣称active引用已经释放。
        wait(!raw_de && dut.scan.prepared==3'b111 && dut.scan.core_idle && !dut.scan.transport_live && slave_idle);
        @(negedge video_clk);video_clock_running=0;
        // J2：core_idle是NBA后事实，下一core采样沿才把末次transport下降写入证据。
        repeat(2)@(negedge core_clk);#1;
        if(q || owner_q || underruns!=0)$fatal(1,"Integrated scan errors Q=%b ownerQ=%b underruns=%0d",q,owner_q,underruns);
        $fdisplay(journal,"{\"event\":\"end\",\"retained_rows\":3,\"active_sequence\":\"%h\",\"active_bundle\":\"%h\"}",active_sequence,active_bundle);
        $fclose(outfile);$fclose(nativefile);$fclose(journal);$fclose(owner_journal);
        owner_metrics=$fopen("protocol-metrics.json","w");$fdisplay(owner_metrics,"{\"finished\":true,\"transactions\":%0d,\"resets\":1}",transactions);$fclose(owner_metrics);
        metrics=$fopen("scan-metrics.json","w");
        $fdisplay(metrics,"{\"finished\":true,\"width\":%0d,\"height\":%0d,\"frames\":%0d,\"completed_frames\":%0d,\"changes\":%0d,\"owner_transactions\":%0d,\"writes\":%0d,\"pops\":%0d,\"requests\":%0d,\"returns\":%0d,\"internal_returns\":%0d,\"closed\":%0d,\"retired\":%0d,\"lookup\":%0d,\"output_slots\":%0d,\"missed_tests\":%0d,\"cancel_tests\":%0d,\"closed_hold_cycles\":%0d,\"retained_rows\":3}",TEST_W,TEST_H,frames,completed_frames,changes,transactions,writes,pops,requests,returns,internal_returns,closed_count,retired_count,lookup_count,output_slots,missed_tests,cancel_tests,holds);
        $fclose(metrics);finished=1;$finish;
    end
    always @(posedge core_clk)if(safe_reset_n)begin
        if(control_valid && control_ready)$fdisplay(journal,"{\"event\":\"control\",\"packet\":\"%h\"}",control_request);
        if(control_response_valid && control_response_ready)$fdisplay(journal,"{\"event\":\"control_reply\",\"packet\":\"%h\"}",control_response);
        if(cancel_valid)$fdisplay(journal,"{\"event\":\"cancel\",\"sequence\":\"%h\"}",cancel_sequence);
        if(lookup_valid && lookup_ready)begin lookup_count++;$fdisplay(journal,"{\"event\":\"lookup\",\"demand\":\"%h\",\"bundle\":\"%h\",\"permitted\":%0d}",lookup_demand,lookup_bundle,lookup_permitted);end
        if(dut.scan.service_valid && dut.scan.service_ready)$fdisplay(journal,"{\"event\":\"service\",\"request\":\"%h\"}",dut.scan.service_request);
        if(dut.scan.service_receipt_valid && dut.scan.service_receipt_ready)$fdisplay(journal,"{\"event\":\"core_receipt\",\"packet\":\"%h\"}",dut.scan.service_receipt);
        if(dut.scan.transport_live!=last_transport_live)begin
            $fdisplay(journal,"{\"event\":\"transport\",\"live\":%0d,\"ref\":\"%h\"}",dut.scan.transport_live,dut.scan.transport_ref);last_transport_live=dut.scan.transport_live;
        end
        if(arvalid && arready)$fdisplay(journal,"{\"event\":\"ar\",\"address\":%0d,\"length\":%0d,\"id\":%0d}",araddr,arlen+1,arid);
        if(rvalid && rready)$fdisplay(journal,"{\"event\":\"r\",\"last\":%0d,\"id\":%0d,\"response\":%0d}",rlast,rid,rresp);
        for(integer b=0;b<3;b++)begin
            if(dut.scan.prefetch.fill_reply_valid[b] && dut.scan.prefetch.fill_reply_ready[b] && dut.scan.prefetch.fill_reply_status[b]==0)
                $fdisplay(journal,"{\"event\":\"grant\",\"bank\":%0d,\"ticket\":\"%h\"}",b,dut.scan.prefetch.fill_reply_ticket[b]);
            if(dut.scan.prefetch.wr_valid[b] && dut.scan.prefetch.wr_ready[b])writes++;
            if(dut.scan.return_valid[b] && dut.scan.return_ready[b])begin
                returns++;return_pending[b]=1;sent_return[b]={dut.scan.return_ticket[b],dut.scan.return_kind[b]};
                $fdisplay(journal,"{\"event\":\"return_core\",\"bank\":%0d,\"packet\":\"%h\"}",b,sent_return[b]);
            end else if(return_pending[b] && dut.scan.return_ready[b])begin
                return_pending[b]=0;$fdisplay(journal,"{\"event\":\"return_ack\",\"bank\":%0d,\"packet\":\"%h\"}",b,sent_return[b]);
            end
            if(dut.scan.prefetch.bank_return_valid[b] && dut.scan.prefetch.bank_return_ready[b] && !dut.scan.return_valid[b])begin
                internal_returns++;$fdisplay(journal,"{\"event\":\"return_internal\",\"bank\":%0d,\"ticket\":\"%h\"}",b,dut.scan.prefetch.bank_return_ticket[b]);
            end
        end
        if(old_closed_valid && old_closed_ready)begin
            if(dut.scan.scope_live || dut.scan.engine_q || dut.scan.fetch_core_q)$fatal(1,"Closed live/unknown core object");
            closed_saved[closed_count]=old_closed_ref;closed_count++;
            $fdisplay(journal,"{\"event\":\"old_closed\",\"ref\":\"%h\"}",old_closed_ref);
        end
        if(old_closed_valid && !old_closed_ready)begin
            if(held_old_valid && old_closed_ref!=held_old_ref)$fatal(1,"Old notification changed under backpressure");
            held_old_valid=1;held_old_ref=old_closed_ref;
        end else held_old_valid=0;
    end
    always @(posedge video_clk)if(safe_reset_n && reset_pipe==0)begin
        if(raw_start)begin
            completed_frames=frames;frames++;frame_tags[frames]=active_sequence;
            $fdisplay(journal,"{\"event\":\"frame\",\"frame\":%0d,\"active\":%0d,\"sequence\":\"%h\",\"scan\":\"%h\",\"bundle\":\"%h\"}",frames,active_valid,active_sequence,scan_token,active_bundle);
        end
        tag0<=video_run ? frames : 0;tag1<=tag0;
        if(dut.scan.vsync_tick)begin
            for(integer b=0;b<3;b++)$fdisplay(journal,"{\"event\":\"qualification\",\"bank\":%0d,\"ticket\":\"%h\",\"owned\":%0d,\"valid\":%0d,\"error\":%0d,\"address\":%0d,\"data\":\"%h\",\"issued\":%0d}",b,dut.scan.row_ticket[b],dut.scan.owned[b],dut.scan.rd_response_valid[b],dut.scan.rd_error[b],dut.scan.rd_response_address[b],dut.scan.rd_data[b],dut.scan.issued[b]);
            vs_count++;$fdisplay(journal,"{\"event\":\"vs\",\"scan_before\":\"%h\",\"prepared\":%0d,\"retire_capacity\":%0d,\"candidate\":%0d,\"cancel\":%0d,\"sequence\":\"%h\",\"target_scan\":\"%h\"}",scan_token,dut.scan.prepared_valid,dut.scan.capacity_sync[1] && dut.scan.close_capacity,dut.scan.candidate_valid,dut.scan.cancel_candidate,dut.scan.candidate_sequence,dut.scan.candidate_target_scan);
        end
        if(dut.scan.candidate_valid && (!previous_candidate || last_candidate_seq!=dut.scan.candidate_sequence || last_candidate_scan!=dut.scan.candidate_target_scan))
            $fdisplay(journal,"{\"event\":\"candidate\",\"sequence\":\"%h\",\"scan\":\"%h\",\"bundle\":\"%h\"}",dut.scan.candidate_sequence,dut.scan.candidate_target_scan,dut.scan.candidate_bundle);
        previous_candidate=dut.scan.candidate_valid;last_candidate_seq=dut.scan.candidate_sequence;last_candidate_scan=dut.scan.candidate_target_scan;
        if(dut.scan.cancel_candidate && !previous_cancel)$fdisplay(journal,"{\"event\":\"candidate_cancel\",\"sequence\":\"%h\"}",dut.scan.candidate_sequence);
        previous_cancel=dut.scan.cancel_candidate;
        if(dut.scan.active_changed)begin
            changes++;$fdisplay(journal,"{\"event\":\"active\",\"sequence\":\"%h\",\"scan\":\"%h\",\"bundle\":\"%h\"}",active_sequence,scan_token,active_bundle);
        end
        if(dut.scan.request_valid)begin
            if(held_request_valid && dut.scan.request!=held_request)$fatal(1,"481 request changed before acceptance");
            if(!held_request_valid)$fdisplay(journal,"{\"event\":\"promise\",\"request\":\"%h\"}",dut.scan.request);
            held_request=dut.scan.request;held_request_valid=!dut.scan.request_ready;
        end else if(held_request_valid)$fatal(1,"481 valid withdrawn");
        if(dut.scan.request_valid && dut.scan.request_ready)$fdisplay(journal,"{\"event\":\"request\",\"request\":\"%h\"}",dut.scan.request);
        if(dut.scan.receipt_valid && dut.scan.receipt_ready)$fdisplay(journal,"{\"event\":\"receipt\",\"packet\":\"%h\"}",dut.scan.receipt);
        for(integer b=0;b<3;b++)begin
            row_ticket_t t;t=dut.scan.row_ticket[b];
            if(dut.scan.reserve_valid[b] && dut.scan.reserve_ready[b])$fdisplay(journal,"{\"event\":\"reserve\",\"bank\":%0d,\"ticket\":\"%h\",\"discard\":%0d}",b,t,dut.scan.reserve_discard[b]);
            if(dut.scan.rd_request_valid[b] && dut.scan.rd_request_ready[b])requests++;
            if(dut.scan.rd_response_valid[b] && dut.scan.rd_response_ready[b])begin
                pops++;
                $fwrite(nativefile,"%c",8'(b));
                for(integer k=0;k<8;k++)$fwrite(nativefile,"%c",8'(t.generation>>(8*k)));
                for(integer k=0;k<8;k++)$fwrite(nativefile,"%c",8'(t.sequence_id>>(8*k)));
                for(integer k=0;k<2;k++)$fwrite(nativefile,"%c",8'(t.target_y>>(8*k)));
                for(integer k=0;k<2;k++)$fwrite(nativefile,"%c",8'(dut.scan.rd_response_address[b]>>(8*k)));
                for(integer k=0;k<8;k++)$fwrite(nativefile,"%c",8'(dut.scan.rd_data[b]>>(8*k)));
                $fwrite(nativefile,"%c",8'(dut.scan.stream_pixels_valid[b]));
            end
            if(dut.scan.release_valid[b] && dut.scan.release_ready[b])$fdisplay(journal,"{\"event\":\"release\",\"bank\":%0d,\"ticket\":\"%h\",\"kind\":%0d,\"shown\":%0d,\"issued\":%0d,\"popped\":%0d}",b,t,dut.scan.release_kind[b],dut.scan.shown[b],dut.scan.issued[b],dut.scan.popped[b]);
            if(dut.scan.returned_valid[b] && dut.scan.returned_ready[b])$fdisplay(journal,"{\"event\":\"return_video\",\"bank\":%0d,\"packet\":\"%h\"}",b,dut.scan.returned[b]);
        end
        if(dut.scan.fence_valid && dut.scan.fence_ready)$fdisplay(journal,"{\"event\":\"fence\",\"packet\":\"%h\"}",dut.scan.fence_request);
        if(dut.scan.fence_done_valid && dut.scan.fence_done_ready)$fdisplay(journal,"{\"event\":\"fence_done\",\"packet\":\"%h\"}",dut.scan.fence_done);
        if(q)$fatal(1,"Integrated component quarantined");
    end
    always @(negedge video_clk)if(safe_reset_n && tag1>0)begin
        logic [15:0] flags;
        flags={10'd0,error,out_start,out_vs,out_hs,out_de};
        for(integer k=0;k<4;k++)$fwrite(outfile,"%c",8'(tag1>>(8*k)));
        for(integer k=0;k<6;k++)$fwrite(outfile,"%c",8'(rgb>>(8*k)));
        for(integer k=0;k<2;k++)$fwrite(outfile,"%c",8'(out_x>>(8*k)));
        for(integer k=0;k<2;k++)$fwrite(outfile,"%c",8'(out_y>>(8*k)));
        for(integer k=0;k<2;k++)$fwrite(outfile,"%c",8'(flags>>(8*k)));
        output_slots++;
        if(out_de && error!=0 && frame_tags[tag1]!=0)$fatal(1,"Actual active frame missing pixels frame=%0d x=%0d y=%0d error=%0d",tag1,out_x,out_y,error);
    end
    initial begin #2000000000;$fatal(1,"Scan test timeout");end
endmodule
