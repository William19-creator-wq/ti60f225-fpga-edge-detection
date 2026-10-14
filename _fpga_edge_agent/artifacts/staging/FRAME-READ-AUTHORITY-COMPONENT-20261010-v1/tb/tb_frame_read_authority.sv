`timescale 1ns/1ps
// RA-T2..6：公开命令/查询，闭合flags是明确环境输入，没有DDR或DUT私有期望。
module tb_frame_read_authority #(
    parameter integer TEST_W=1920,TEST_H=1080,TEST_NEAR_SEQUENCE=0
);
    import frame_owner_pkg::*;
    import display_fetch_pkg::*;
    localparam logic [63:0] INITIAL_LAST=TEST_NEAR_SEQUENCE ? 64'hfffffffffffffffe : 64'd0;
    logic core_clk=0,safe_reset_n=0,finished=0;
    always #5 core_clk=~core_clk;
    logic cmd_valid=0,reply_ready=0,lookup_valid=0;
    logic [940:0] command=0;
    logic [63:0] offer_sequence=0,next_sequence=1;
    logic [478:0] lookup_demand=0;
    wire cmd_ready,reply_valid,lookup_ready,lookup_permitted;
    wire [941:0] reply,lookup_bundle;
    wire [17:0] source_states;wire [8:0] result_states;
    wire [63:0] latest_handle,freeze_handle,policy;
    wire frozen,quarantined,source_exhausted,result_exhausted;
    integer journal,metrics,cycles=0,command_inputs=0,commands=0,queries=0,allowed=0,denied=0,resets=0,query_holds=0;
    integer frame_counter=0;
    command_t accepted_command;
    logic [63:0] accepted_sequence;
    reply_t last_reply,source_saved,result_saved[0:7];
    logic [63:0] result_sequence[0:7];
    frame_owner_read_authority #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H),.FRAME_ALIGNMENT(64),
        .INIT_LAST_OFFER_SEQUENCE(INITIAL_LAST)) dut(.*);

    function automatic command_t source_command(input operation_t op,input logic [7:0] flags=0);
        command_t c;c='0;c.op=op;c.flags=flags;c.source_handle=source_saved.source_handle;c.origin=source_saved.origin;return c;
    endfunction
    function automatic command_t result_command(input operation_t op,input integer index,input logic [7:0] flags=0);
        command_t c;c='0;c.op=op;c.flags=flags;c.source_handle=result_saved[index].source_handle;
        c.result_handle=result_saved[index].result_handle;c.origin=result_saved[index].origin;
        c.cj=result_saved[index].cj;c.policy=result_saved[index].policy;return c;
    endfunction
    function automatic demand_t demand_for(input integer index,input integer y=0,input logic [63:0] scan=1);
        demand_t d;logic [2:0] mode;
        d='0;mode=result_saved[index].body[111:109];d.sequence_id=result_sequence[index];d.scan=scan;
        d.result_handle=result_saved[index].result_handle;d.policy=result_saved[index].policy;d.origin=result_saved[index].origin;
        d.target_y=11'(y);d.mode=mode;d.source_y=11'(mode==0 ? 2*(y%(TEST_H/2)) : y);
        case(mode)
            0:d.required_mask=y<TEST_H/2 ? 3'd1 : 3'd2;
            1,2:d.required_mask=1;3:d.required_mask=2;4:d.required_mask=3;5:d.required_mask=7;
            default:d.required_mask=0;
        endcase
        return d;
    endfunction
    function automatic logic [222:0] public_state;
        return {source_states,result_states,latest_handle,freeze_handle,policy,frozen,quarantined,source_exhausted,result_exhausted};
    endfunction

    // 只在公开fire记录；Python按对象租约及输入字段独立审计实际结果。
    always @(posedge core_clk)begin
        cycles++;
        if(safe_reset_n)begin
            if(cmd_valid && cmd_ready)begin
                accepted_command=command;accepted_sequence=offer_sequence;command_inputs++;
                $fwrite(journal,"COMMAND,%0d,%h,%h\n",cycles,command,offer_sequence);
            end
            if(reply_valid && reply_ready)begin
                $fwrite(journal,"EVENT,%h,%h,%h,%h,%h,%h,%h,%h,%b,%b,%b,%b\n",
                    accepted_command,accepted_sequence,reply,source_states,result_states,latest_handle,freeze_handle,policy,
                    frozen,quarantined,source_exhausted,result_exhausted);commands++;
            end else if(reply_valid)$fwrite(journal,"HREPLY,%0d,%h\n",cycles,reply);
            if(lookup_valid && lookup_ready)begin
                $fwrite(journal,"LOOKUP,%0d,%h,%b,%h,%h,%h,%h,%h,%h,%b,%b,%b,%b\n",
                    cycles,lookup_demand,lookup_permitted,lookup_bundle,source_states,result_states,latest_handle,freeze_handle,policy,
                    frozen,quarantined,source_exhausted,result_exhausted);
                queries++;if(lookup_permitted)allowed++;else denied++;
            end else if(lookup_valid)begin
                $fwrite(journal,"QHOLD,%0d,%h,%b,%h\n",cycles,lookup_demand,lookup_permitted,lookup_bundle);query_holds++;
            end
            if((!lookup_valid || !lookup_ready) && {lookup_permitted,lookup_bundle}!==943'd0)
                $fatal(1,"Busy/invalid query published permission");
            if(cmd_valid && lookup_valid && lookup_ready)$fatal(1,"Command/query priority violated");
            if(reply_valid && cmd_ready)$fatal(1,"Held reply admitted a command");
        end
    end

    task automatic cold;
        @(negedge core_clk);safe_reset_n=0;cmd_valid=0;reply_ready=0;lookup_valid=0;offer_sequence=0;next_sequence=1;
        repeat(5)@(negedge core_clk);safe_reset_n=1;repeat(5)@(negedge core_clk);
        resets++;$fwrite(journal,"RESET,%0d,%0d,1,%h\n",TEST_W,TEST_H,INITIAL_LAST);
    endtask
    task automatic exchange(input command_t c,input integer status_expected=0,
        input logic [63:0] sequence_value=0,input bit manual_sequence=0,
        input bit pending_lookup=0,input demand_t pending='0);
        reply_t held;logic [222:0] before_query;
        @(negedge core_clk);
        if(!cmd_ready)$fatal(1,"Authority command not ready");
        command=c;offer_sequence=0;
        if(c.op==OFFER)begin
            offer_sequence=manual_sequence ? sequence_value : next_sequence;
            if(!manual_sequence)next_sequence++;
        end
        cmd_valid=1;
        if(pending_lookup)begin lookup_valid=1;lookup_demand=pending;end
        @(posedge core_clk);if(!cmd_ready)$fatal(1,"Expected real command fire");
        @(negedge core_clk);cmd_valid=0;
        if(!reply_valid)$fatal(1,"Authority reply absent");held=reply;command='1;
        repeat(7)begin
            @(negedge core_clk);
            if(!reply_valid || reply!==held || cmd_ready)$fatal(1,"Authority reply holding changed");
            if(pending_lookup && lookup_ready)$fatal(1,"Held reply admitted query");
        end
        if(held.status!=status_expected)$fatal(1,"Authority op=%0d status=%0d expected=%0d",c.op,held.status,status_expected);
        last_reply=held;reply_ready=1;@(negedge core_clk);reply_ready=0;
        if(pending_lookup)begin
            before_query=public_state();
            @(posedge core_clk);if(!lookup_ready || !lookup_permitted)$fatal(1,"Pending valid old-scope query not granted");
            @(negedge core_clk);lookup_valid=0;
            if(public_state()!==before_query)$fatal(1,"Pending lookup mutated public ledger");
        end
    endtask
    task automatic lookup(input demand_t d,input bit expected);
        logic [222:0] before_query;
        @(negedge core_clk);lookup_demand=d;lookup_valid=1;before_query=public_state();
        @(posedge core_clk);
        if(!lookup_ready || lookup_permitted!==expected)$fatal(1,"Lookup permit got=%b expected=%b",lookup_permitted,expected);
        if(!expected && lookup_bundle!==0)$fatal(1,"Rejected query returned a bundle");
        @(negedge core_clk);lookup_valid=0;
        if(public_state()!==before_query)$fatal(1,"Lookup mutated public ledger");
    endtask
    task automatic allocate_source;
        command_t c;c='0;c.op=ALLOC_SOURCE;frame_counter++;c.origin[130:67]={32'(frame_counter),32'h4352};
        exchange(c);source_saved=last_reply;
        exchange(source_command(SOURCE_EOF));exchange(source_command(SOURCE_END,8'h07));
    endtask
    task automatic allocate_result(input integer index,mode);
        command_t c;c='0;c.op=ALLOC_RESULT;c.source_handle=source_saved.source_handle;c.origin=source_saved.origin;
        c.cj={2'b11,11'd320,11'd64,11'(TEST_H),11'(TEST_W),32'(index+1),64'd0};
        c.body[111:0]={3'(mode),11'(TEST_H/2),24'hff0000,24'h00ff00,24'h00a0ff,24'hffff00,2'b11};
        exchange(c);result_saved[index]=last_reply;result_sequence[index]=next_sequence;
    endtask
    task automatic offer(input integer index);
        result_sequence[index]=next_sequence;exchange(result_command(OFFER,index));result_saved[index]=last_reply;
    endtask
    task automatic bad_fields(input demand_t correct);
        demand_t wrong;
        // 整个387位FrameRef逐位翻转，避免只检一部分Origin或截断sequence。
        for(integer i=0;i<64;i++)begin wrong=correct;wrong.sequence_id[i]=~wrong.sequence_id[i];lookup(wrong,0);end
        for(integer i=0;i<64;i++)begin wrong=correct;wrong.result_handle[i]=~wrong.result_handle[i];lookup(wrong,0);end
        for(integer i=0;i<64;i++)begin wrong=correct;wrong.policy[i]=~wrong.policy[i];lookup(wrong,0);end
        for(integer i=0;i<195;i++)begin wrong=correct;wrong.origin[i]=~wrong.origin[i];lookup(wrong,0);end
        for(integer i=0;i<11;i++)begin wrong=correct;wrong.source_y[i]=~wrong.source_y[i];lookup(wrong,0);end
        for(integer i=0;i<3;i++)begin wrong=correct;wrong.mode[i]=~wrong.mode[i];lookup(wrong,0);end
        for(integer i=0;i<3;i++)begin wrong=correct;wrong.required_mask[i]=~wrong.required_mask[i];lookup(wrong,0);end
        wrong=correct;wrong.scan=0;lookup(wrong,0);
        wrong=correct;wrong.target_y=11'(TEST_H);lookup(wrong,0);
    endtask

    initial begin
        command_t c;demand_t d,old_d;reply_t old_offer;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"authority fatal exit probe");
        journal=$fopen("authority-events.csv","w");cold();
        if(TEST_NEAR_SEQUENCE)begin
            allocate_source();allocate_result(0,4);exchange(result_command(RESULT_END,0,8'h07));
            exchange(result_command(OFFER,0),IDENTITY,0,1);
            exchange(result_command(OFFER,0),IDENTITY,64'hfffffffffffffffd,1);
            exchange(result_command(OFFER,0),OK,64'hffffffffffffffff,1);result_saved[0]=last_reply;result_sequence[0]=64'hffffffffffffffff;
            lookup(demand_for(0),1);exchange(result_command(APPLY,0));lookup(demand_for(0),1);
            allocate_result(1,4);exchange(result_command(RESULT_END,1,8'h07));
            exchange(result_command(OFFER,1),IDENTITY,64'hffffffffffffffff,1);
            exchange(result_command(OFFER,1),IDENTITY,0,1);lookup(demand_for(1),0);
            exchange(result_command(DROP_RESULT,1,8'h02));lookup(demand_for(0),1);
        end else begin
            for(integer mode=0;mode<6;mode++)begin
                cold();allocate_source();allocate_result(0,mode);
                d=demand_for(0);lookup(d,0);exchange(result_command(OFFER,0),STATE,0,1);
                exchange(result_command(RESULT_END,0,8'h07));lookup(d,0);
                exchange(result_command(OFFER,0),IDENTITY,0,1);offer(0);
                for(integer y=0;y<TEST_H;y++)lookup(demand_for(0,y,64'(y+1)),1);
                d=demand_for(0);bad_fields(d);exchange(result_command(APPLY,0));lookup(d,1);
                c='0;c.op=BARRIER;exchange(c,0,0,0,1,d);lookup(d,1);
                c=result_command(FREEZE,0,8'h01);exchange(c);lookup(d,1);
                c='0;c.op=RESUME;exchange(c);lookup(d,1);
                // 同Source两个结果的权限独立；新policy不能改掉旧Result正文。
                allocate_result(1,mode);exchange(result_command(RESULT_END,1,8'h07));
                exchange(result_command(OFFER,1),IDENTITY,result_sequence[0],1);
                offer(1);lookup(d,1);lookup(demand_for(1),1);exchange(result_command(APPLY,1));lookup(d,1);
                old_d=d;old_offer=result_saved[0];exchange(result_command(RETIRE,0,8'h0a));lookup(old_d,0);
                allocate_result(2,mode);exchange(result_command(RESULT_END,2,8'h07));offer(2);
                if(result_saved[2].result_slot!=old_offer.result_slot)$fatal(1,"Expected actual result slot reuse");
                lookup(old_d,0);lookup(demand_for(2),1);exchange(result_command(APPLY,2));
                exchange(result_command(RETIRE,1,8'h0a));lookup(demand_for(1),0);lookup(demand_for(2),1);
                allocate_source();allocate_result(3,mode);exchange(result_command(RESULT_END,3,8'h07));offer(3);exchange(result_command(APPLY,3));
                exchange(result_command(RETIRE,2,8'h0a));lookup(demand_for(2),0);
                // 全局Q不释放或重新授权现存引用。
                allocate_result(4,mode);exchange(result_command(RESULT_END,4,8'h01),QUARANTINED);lookup(demand_for(3),0);
                // pending lookup与held reply在共同cold后都作废。
                @(negedge core_clk);lookup_demand=demand_for(3);lookup_valid=1;command='0;command[940:937]=BARRIER;cmd_valid=1;
                @(posedge core_clk);if(!cmd_ready || lookup_ready)$fatal(1,"Pending reset priority");
                cold();lookup(old_d,0);
            end
        end
        $fclose(journal);metrics=$fopen("authority-metrics.json","w");
        $fwrite(metrics,"{\"finished\":true,\"width\":%0d,\"height\":%0d,\"command_inputs\":%0d,\"commands\":%0d,\"queries\":%0d,\"allowed\":%0d,\"denied\":%0d,\"resets\":%0d,\"query_holds\":%0d,\"cycles\":%0d,\"near_sequence\":%0d}\n",
            TEST_W,TEST_H,command_inputs,commands,queries,allowed,denied,resets,query_holds,cycles,TEST_NEAR_SEQUENCE);$fclose(metrics);
        finished=1;$display("Frame read authority PASS commands=%0d queries=%0d",commands,queries);$finish;
    end
    initial begin #10000000;if(!finished)$fatal(1,"Authority query suite watchdog");end
endmodule
