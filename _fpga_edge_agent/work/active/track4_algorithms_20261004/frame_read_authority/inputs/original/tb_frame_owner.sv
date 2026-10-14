`timescale 1ns/1ps
module tb_frame_owner #(
    parameter integer TEST_W=1920,TEST_H=1080,TEST_NEAR_MAX=0
);
    import frame_owner_pkg::*;
    localparam logic [63:0] INITIAL=TEST_NEAR_MAX ? 64'hfffffffffffffffe : 64'd1;
    logic core_clk=0,safe_reset_n=0,finished=0;
    always #5 core_clk=~core_clk;
    logic cmd_valid=0;wire cmd_ready;logic [940:0] command=0;
    wire reply_valid;logic reply_ready=0;wire [941:0] reply;
    wire [17:0] source_states;wire [8:0] result_states;
    wire [63:0] latest_handle,freeze_handle,policy;wire frozen,quarantined,source_exhausted,result_exhausted;
    integer journal,metrics,transactions=0,resets=0,frame_counter=0,hold_cycles=0;
    logic [31:0] random_state=32'h8a27315b;
    reply_t last_reply,sources_saved[0:31],results_saved[0:31];
`ifdef OWNER_POST_MAP
    frame_owner dut(.*);
`else
    frame_owner #(.IMAGE_WIDTH(TEST_W),.IMAGE_HEIGHT(TEST_H),.INIT_SOURCE_HANDLE(INITIAL),.INIT_RESULT_HANDLE(INITIAL),.INIT_POLICY(INITIAL)) dut(.*);
`endif
    function automatic logic [31:0] rnd();
        random_state={random_state[30:0],random_state[31]^random_state[21]^random_state[1]^random_state[0]};return random_state;
    endfunction
    function automatic logic [141:0] cfg(input integer id=1);
        return {1'b1,1'b1,11'd320,11'd64,11'(TEST_H),11'(TEST_W),32'(id),32'd0,32'd0};
    endfunction
    function automatic logic [111:0] render(input integer mode=4);
        return {3'(mode),11'(TEST_H/2),24'hff0000,24'h00ff00,24'h00a0ff,24'hffff00,2'b11};
    endfunction
    function automatic command_t for_source(input integer op,input reply_t snapshot,input logic [7:0] flags=0);
        command_t c;c='0;c.op=4'(op);c.flags=flags;c.source_handle=snapshot.source_handle;c.origin=snapshot.origin;return c;
    endfunction
    function automatic command_t for_result(input integer op,input reply_t snapshot,input logic [7:0] flags=0);
        command_t c;c='0;c.op=4'(op);c.flags=flags;c.source_handle=snapshot.source_handle;c.result_handle=snapshot.result_handle;
        c.origin=snapshot.origin;c.cj=snapshot.cj;c.policy=snapshot.policy;return c;
    endfunction
    task automatic cold_reset;
        @(negedge core_clk);safe_reset_n=0;cmd_valid=0;reply_ready=0;
        repeat(5)@(negedge core_clk);safe_reset_n=1;repeat(5)@(negedge core_clk);resets++;
        $fwrite(journal,"RESET,%0d,%0d,%h\n",TEST_W,TEST_H,INITIAL);
    endtask
    task automatic exchange(input command_t c,input integer expected_status=0,input integer forced_hold=-1);
        integer idle,held;reply_t snapshot;
        repeat(rnd()%3)@(negedge core_clk);
        idle=0;while(!cmd_ready && idle<100)begin @(negedge core_clk);idle++;end
        if(!cmd_ready)$fatal(1,"Owner command stuck");
        command=c;cmd_valid=1;@(negedge core_clk);cmd_valid=0;
        if(!reply_valid)$fatal(1,"No reply after actual command fire");
        snapshot=reply;held=forced_hold>=0 ? forced_hold : int'(rnd()%13);
        // 改无效command验证holding不热读外部字段；不得重复提交旧valid。
        command='1;
        repeat(held)begin
            @(negedge core_clk);if(!reply_valid || reply!==snapshot || cmd_ready)$fatal(1,"Owner holding changed/accepted extra event");hold_cycles++;
        end
        if(snapshot.status!=expected_status)$fatal(1,"Owner status op=%0d got=%0d want=%0d transaction=%0d",c.op,snapshot.status,expected_status,transactions);
        if($isunknown({reply,source_states,result_states,latest_handle,freeze_handle,policy,frozen,quarantined}))$fatal(1,"Unknown owner boundary");
        $fwrite(journal,"EVENT,%h,%h,%h,%h,%h,%h,%h,%b,%b,%b,%b\n",c,snapshot,source_states,result_states,latest_handle,freeze_handle,policy,frozen,quarantined,source_exhausted,result_exhausted);
        last_reply=snapshot;transactions++;reply_ready=1;@(negedge core_clk);reply_ready=0;
    endtask
    task automatic allocate_source(input integer index,input bit finish_source=1);
        command_t c;c='0;c.op=ALLOC_SOURCE;frame_counter++;c.origin[130:67]={32'(frame_counter),32'h35};
        exchange(c);sources_saved[index]=last_reply;
        if(finish_source)begin exchange(for_source(SOURCE_EOF,sources_saved[index]));exchange(for_source(SOURCE_END,sources_saved[index],8'h07));end
    endtask
    task automatic allocate_result(input integer index,input integer source_index=-1,input bit live=0,input integer mode=4);
        command_t c;c='0;c.op=ALLOC_RESULT;c.cj=cfg(index+1);c.body={288'd0,render(mode)};
        if(source_index>=0)begin c.source_handle=sources_saved[source_index].source_handle;c.origin=sources_saved[source_index].origin;end
        c.flags=live ? 8'h10 : 0;exchange(c);results_saved[index]=last_reply;
    endtask
    task automatic finish_offer_apply(input integer index);
        exchange(for_result(RESULT_END,results_saved[index],8'h07));exchange(for_result(OFFER,results_saved[index]));exchange(for_result(APPLY,results_saved[index]));
    endtask
    initial begin
        command_t c;reply_t old_result;integer status_expected;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        journal=$fopen("events.csv","w");cold_reset();
        if(TEST_NEAR_MAX)begin
            allocate_source(0);allocate_result(0,0);exchange(for_result(RESULT_END,results_saved[0],8'h07));exchange(for_result(DROP_RESULT,results_saved[0],8'h02));
            allocate_source(1);allocate_result(1,1);exchange(for_result(RESULT_END,results_saved[1],8'h07));exchange(for_result(DROP_RESULT,results_saved[1],8'h02));
            c='0;c.op=ALLOC_SOURCE;c.origin[130:67]={32'd900,32'h35};exchange(c,EXHAUSTED);
            c='0;c.op=ALLOC_RESULT;c.cj=cfg();c.body={288'd0,render()};exchange(c,EXHAUSTED);
            c='0;c.op=BARRIER;exchange(c);exchange(c,EXHAUSTED);
            c='0;c.op=FREEZE;exchange(c,EXHAUSTED);
        end else begin
            // 单一DISPLAY及两个RETIRING；乱序归还和旧ACK不释放当前代次。
            for(integer i=0;i<3;i++)begin allocate_source(i);allocate_result(i,i);finish_offer_apply(i);end
            if(result_states!={3'(R_DISPLAY),3'(R_RETIRING),3'(R_RETIRING)})$fatal(1,"D+R+R missing");
            c='0;c.op=ALLOC_RESULT;c.cj=cfg();c.body={288'd0,render()};exchange(c,NO_SPACE);
            exchange(for_result(RETIRE,results_saved[1],8'h0a));exchange(for_result(RETIRE,results_saved[0],8'h0a));
            exchange(for_result(RETIRE,results_saved[0],8'h0a),IDENTITY);

            // 冻结实际已经B但core尚A：B仍OFFERED，snapshot先为B加保留。
            cold_reset();allocate_source(0);allocate_result(0,0);finish_offer_apply(0);
            allocate_source(1);allocate_result(1,1);exchange(for_result(RESULT_END,results_saved[1],8'h07));exchange(for_result(OFFER,results_saved[1]));
            c=for_result(FREEZE,results_saved[1],8'h01);exchange(c,OK,39);
            if(freeze_handle!=sources_saved[1].source_handle)$fatal(1,"Freeze used core shadow A");
            exchange(for_result(APPLY,results_saved[1]));allocate_result(2,-1,0,5);
            if(results_saved[2].origin!==sources_saved[1].origin)$fatal(1,"Frozen reprocessing changed source");
            exchange(for_result(RESULT_END,results_saved[2],8'h07));exchange(for_result(OFFER,results_saved[2]));exchange(for_result(APPLY,results_saved[2]));
            exchange(for_result(RETIRE,results_saved[1],8'h0a));exchange(for_result(RETIRE,results_saved[0],8'h0a));
            c='0;c.op=RESUME;exchange(c);

            // latest迟完成、LIVE绑定、首次冻结源与配置快照。
            cold_reset();c='0;c.op=FREEZE;exchange(c);allocate_source(0,0);allocate_source(1,0);
            allocate_result(0,0,1);exchange(for_result(OFFER,results_saved[0]),STATE);
            exchange(for_source(SOURCE_EOF,sources_saved[1]));exchange(for_source(SOURCE_END,sources_saved[1],8'h07));
            if(freeze_handle!=sources_saved[1].source_handle)$fatal(1,"First freeze completion not pinned atomically");
            exchange(for_source(SOURCE_EOF,sources_saved[0]));exchange(for_source(SOURCE_END,sources_saved[0],8'h07));
            if(latest_handle!=sources_saved[1].source_handle)$fatal(1,"Old completion replaced latest");
            allocate_result(1);exchange(for_result(RESULT_END,results_saved[0],8'h07));
            c='0;c.op=BARRIER;exchange(c);exchange(for_result(OFFER,results_saved[0]),NOT_READY);
            exchange(for_result(DROP_RESULT,results_saved[0],8'h02));
            exchange(for_result(RESULT_END,results_saved[1],8'h06));c='0;c.op=RESUME;exchange(c);

            // 一个OFFERED阻止第二个DONE发布，DONE和BIND仍保持。
            cold_reset();allocate_source(0);allocate_result(0,0);allocate_result(1,0);
            exchange(for_result(RESULT_END,results_saved[0],8'h07));exchange(for_result(RESULT_END,results_saved[1],8'h07));
            exchange(for_result(OFFER,results_saved[0]));exchange(for_result(OFFER,results_saved[1]),NO_SPACE);
            exchange(for_result(DROP_RESULT,results_saved[0],8'h0a));exchange(for_result(OFFER,results_saved[1]));exchange(for_result(APPLY,results_saved[1]));
            c=for_result(FREEZE,results_saved[1],8'h01);exchange(c);allocate_source(1);allocate_result(2,1);
            exchange(for_result(RESULT_END,results_saved[2],8'h07));exchange(for_result(OFFER,results_saved[2]),NOT_READY);
            exchange(for_result(DROP_RESULT,results_saved[2],8'h02));

            // LIVE源变坏不进入latest；失败结果与closed WORKING各自释放最后BIND。
            cold_reset();allocate_source(0,0);allocate_result(0,0,1);
            exchange(for_source(SOURCE_END,sources_saved[0],8'h06));exchange(for_result(RESULT_END,results_saved[0],8'h06));
            if(source_states!=0 || result_states!=0)$fatal(1,"Bad LIVE source/result leaked reference");
            allocate_source(1);allocate_result(1,1);exchange(for_result(DROP_RESULT,results_saved[1],8'h06));

            // 六个WRITING全占；字段/身份/重复/坏但闭合源不会覆盖。
            cold_reset();for(integer i=0;i<6;i++)allocate_source(i,0);
            c='0;c.op=ALLOC_SOURCE;c.origin[130:67]={32'd9999,32'h35};exchange(c,NO_SPACE);
            c='0;c.op=ALLOC_SOURCE;c.origin=sources_saved[0].origin;exchange(c,IDENTITY);
            c=for_source(SOURCE_EOF,sources_saved[0]);c.origin^=195'h100;exchange(c,IDENTITY);
            exchange(for_source(SOURCE_END,sources_saved[0],8'h07),STATE);
            exchange(for_source(SOURCE_EOF,sources_saved[0]));exchange(for_source(SOURCE_EOF,sources_saved[0]),STATE);
            exchange(for_source(SOURCE_END,sources_saved[0],8'h06));allocate_source(6,0);
            exchange(for_source(SOURCE_END,sources_saved[0],8'h06),IDENTITY);

            // 每个缺闭合路径隔离：不能当完整源/结果或回收。
            for(integer missing=1;missing<=2;missing++)begin
                cold_reset();allocate_source(0,0);exchange(for_source(SOURCE_EOF,sources_saved[0]));
                exchange(for_source(SOURCE_END,sources_saved[0],8'h07^(8'h01<<missing)),QUARANTINED);
                c='0;c.op=ALLOC_SOURCE;exchange(c,QUARANTINED);
            end
            for(integer missing=1;missing<=2;missing++)begin
                cold_reset();allocate_source(0);allocate_result(0,0);exchange(for_result(RESULT_END,results_saved[0],8'h07^(8'h01<<missing)),QUARANTINED);
                c='0;c.op=ALLOC_RESULT;exchange(c,QUARANTINED);
            end
            cold_reset();allocate_source(0);allocate_result(0,0);exchange(for_result(RESULT_END,results_saved[0],8'h07));exchange(for_result(OFFER,results_saved[0]));
            exchange(for_result(DROP_RESULT,results_saved[0],8'h02),QUARANTINED);
            cold_reset();allocate_source(0);allocate_result(0,0);finish_offer_apply(0);
            allocate_source(1);allocate_result(1,1);finish_offer_apply(1);
            exchange(for_result(RETIRE,results_saved[0],8'h02),QUARANTINED);

            // 非法CJ/render/flags/op及wrong完整身份。
            cold_reset();allocate_source(0);
            c='0;c.op=ALLOC_RESULT;c.cj=cfg();c.body={288'd0,render(7)};exchange(c,FIELD);
            c.body={288'd0,render()};c.cj[106:96]=0;exchange(c,FIELD);
            c.cj=cfg();c.cj[128:118]=11'd400;exchange(c,FIELD);
            c.cj=cfg();c.flags=8'h80;exchange(c,FIELD);
            c.flags=0;c.op=15;exchange(c,FIELD);
            for(integer mode_index=0;mode_index<6;mode_index++)begin
                allocate_result(0,-1,0,mode_index);old_result=results_saved[0];
                c=for_result(RESULT_END,old_result,8'h07);c.cj^=142'h10000000000000000;exchange(c,IDENTITY);
                exchange(for_result(RESULT_END,old_result,8'h07));exchange(for_result(DROP_RESULT,old_result,8'h02));
                exchange(for_result(DROP_RESULT,old_result,8'h02),IDENTITY);
            end
            // 有限正常随机工作流及长holding，保留全部成功/失败而不改期望。
            cold_reset();
            for(integer i=0;i<100;i++)begin
                allocate_source(0);allocate_result(0,0,0,int'(rnd()%6));
                if((rnd()%4)==0)begin exchange(for_result(RESULT_END,results_saved[0],8'h06));end
                else begin
                    exchange(for_result(RESULT_END,results_saved[0],8'h07));exchange(for_result(OFFER,results_saved[0]));
                    exchange(for_result(DROP_RESULT,results_saved[0],8'h0a));
                end
                if((rnd()%7)==0)begin c='0;c.op=FREEZE;exchange(c);c.op=RESUME;exchange(c);end
            end
        end
        $fclose(journal);metrics=$fopen("protocol-metrics.json","w");
        $fwrite(metrics,"{\"finished\":true,\"width\":%0d,\"height\":%0d,\"transactions\":%0d,\"resets\":%0d,\"hold_cycles\":%0d,\"near_max\":%s,\"physical_fence_verified\":false}\n",TEST_W,TEST_H,transactions,resets,hold_cycles,TEST_NEAR_MAX!=0 ? "true" : "false");$fclose(metrics);
        finished=1;$display("Frame owner PASS transactions=%0d resets=%0d",transactions,resets);$finish;
    end
    initial begin #10000000;if(!finished)$fatal(1,"Owner suite watchdog");end
endmodule
