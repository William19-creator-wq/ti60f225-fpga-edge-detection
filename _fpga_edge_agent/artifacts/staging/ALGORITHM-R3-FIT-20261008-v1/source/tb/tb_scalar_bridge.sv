`timescale 1ns/1ps
// FT-T07/08：真实child测试与隔离故障分别记录；MAX种子是静态测试参数。
module tb_scalar_bridge;
    import fit_protocol_pkg::*;
    logic clk=0,rst=1;
    always #20 clk=~clk;
    bit finished=0;
    logic cmd_valid=0,cmd_ready,result_valid,result_ready=0,abort=0,bridge_quiet;
    logic [405:0] cmd_body=0;
    logic [402:0] result_body;
    logic child_req_valid,child_req_ready,child_rsp_valid,child_rsp_ready,child_cancel_valid,child_quiet;
    logic [621:0] child_req_body;
    logic [584:0] child_rsp_body;
    logic [175:0] child_cancel_id;
    logic actual_req_ready,actual_rsp_valid,actual_quiet;
    logic [584:0] actual_rsp_body;
    logic request_enable=1,response_enable=1;
    logic fault_quiet_block=0;
    integer fault_mode=0,tests=0,cycle=0;
    logic fake_live=0,fake_valid=0;
    logic [584:0] fake_response;
    logic [621:0] fake_request;
    logic [621:0] held_offer;
    logic offer_stall=0;
    logic [402:0] held_result;
    logic result_stall=0;
    integer actual_calls=0,fault_calls=0;
    scalar_bridge dut(.*);
    scalar_core actual_child(.clk(clk),.rst(rst),
        .req_valid(child_req_valid && request_enable && fault_mode==0),.req_ready(actual_req_ready),.req_body(child_req_body),
        .rsp_valid(actual_rsp_valid),.rsp_ready(child_rsp_ready && response_enable && fault_mode==0),.rsp_body(actual_rsp_body),
        .cancel_valid(child_cancel_valid),.cancel_id(child_cancel_id),.quiet(actual_quiet));
    always_comb begin
        child_req_ready=request_enable && (fault_mode==0?actual_req_ready:!fake_live);
        child_rsp_valid=response_enable && (fault_mode==0?actual_rsp_valid:fake_valid);
        child_rsp_body=fault_mode==0?actual_rsp_body:fake_response;
        child_quiet=fault_mode==0?actual_quiet:(!fake_live && !fault_quiet_block);
    end
    always @(posedge clk) begin
        cycle=cycle+1;
        if(rst) begin fake_live=0; fake_valid=0; offer_stall=0; result_stall=0; end
        else begin
            if(offer_stall && (!child_req_valid || child_req_body!==held_offer)) $fatal(1,"bridge withdrew child offer");
            offer_stall=child_req_valid && !child_req_ready; held_offer=child_req_body;
            if(result_stall && (!result_valid || result_body!==held_result)) $fatal(1,"bridge held result changed");
            result_stall=result_valid && !result_ready; held_result=result_body;
            if(child_req_valid && child_req_ready) begin
                if(fault_mode==0) actual_calls=actual_calls+1;
                else begin
                    fault_calls=fault_calls+1; fake_request=child_req_body; fake_live=1;
                    fake_response=pack_response(fake_request,VALUE,NONE,385'd3);
                    case(fault_mode)
                        1:fake_response[0]=~fake_response[0];
                        2:fake_response[176]=~fake_response[176];
                        3:fake_response[181]=~fake_response[181];
                        4:fake_response[REASON_LO+:8]=FORMAT;
                        5:fake_response=pack_response(fake_request,FRAME_FAIL,FORMAT,385'd1);
                        6:fake_response=pack_response(fake_request,FRAME_FAIL,CAPACITY,0);
                        7:fake_response=pack_response(fake_request,CANCEL_DROP,NONE,0);
                        8:fake_response=pack_response(fake_request,FRAME_FAIL,OVERFLOW,0);
                        default:fake_response=pack_response(fake_request,VALUE,NONE,385'd3);
                    endcase
                    fake_valid=1;
                end
            end else if(fault_mode!=0 && fake_valid && child_rsp_ready && response_enable) begin fake_valid=0; fake_live=0; end
        end
    end
    task automatic command(input logic [2:0] op,input logic sa,sb,input logic [8:0] target,
                           input logic [191:0] a,b);
        begin
            @(negedge clk); cmd_body={b,a,target,sb,sa,op,8'd7}; cmd_valid=1;
            do @(posedge clk); while(!cmd_ready);
            @(negedge clk); cmd_valid=0;
        end
    endtask
    task automatic result(input logic [1:0] outcome,input logic [7:0] reason,input logic [384:0] value,input integer hold);
        integer began;
        logic [402:0] expected;
        begin
            began=cycle; expected={value,reason,outcome,8'd7};
            while(!result_valid) begin @(negedge clk); if(cycle-began>16384) $fatal(1,"bridge did not close"); end
            if(result_body!==expected || !child_quiet) $fatal(1,"bridge result expected=%h got=%h",expected,result_body);
            repeat(hold) @(negedge clk);
            result_ready=1; @(posedge clk); @(negedge clk); result_ready=0; tests=tests+1;
        end
    endtask

    // 第二套独立测试域只测序号耗尽；不和生产桥/真实算术混接。
    logic tail_valid=0,tail_ready,tail_result_valid,tail_result_ready=0,tail_quiet;
    logic [405:0] tail_command=0;
    logic [402:0] tail_result;
    logic tail_req_valid,tail_req_ready,tail_rsp_valid,tail_rsp_ready,tail_cancel_valid,tail_child_quiet;
    logic [621:0] tail_req;
    logic [584:0] tail_rsp;
    logic [175:0] tail_cancel_id;
    scalar_bridge #(.RESET_SEQUENCE(64'hfffffffffffffffe)) tail_bridge(
        .clk(clk),.rst(rst),.cmd_valid(tail_valid),.cmd_ready(tail_ready),.cmd_body(tail_command),
        .result_valid(tail_result_valid),.result_body(tail_result),.result_ready(tail_result_ready),.abort(1'b0),.bridge_quiet(tail_quiet),
        .child_req_valid(tail_req_valid),.child_req_body(tail_req),.child_req_ready(tail_req_ready),
        .child_rsp_valid(tail_rsp_valid),.child_rsp_body(tail_rsp),.child_rsp_ready(tail_rsp_ready),
        .child_cancel_valid(tail_cancel_valid),.child_cancel_id(tail_cancel_id),.child_quiet(tail_child_quiet));
    scalar_core tail_child(.clk(clk),.rst(rst),.req_valid(tail_req_valid),.req_body(tail_req),.req_ready(tail_req_ready),
        .rsp_valid(tail_rsp_valid),.rsp_body(tail_rsp),.rsp_ready(tail_rsp_ready),
        .cancel_valid(tail_cancel_valid),.cancel_id(tail_cancel_id),.quiet(tail_child_quiet));
    integer tail_calls=0;
    always @(posedge clk) if(!rst && tail_req_valid && tail_req_ready) begin
        if(tail_req[104+:64]!==64'hfffffffffffffffe+tail_calls) $fatal(1,"tail private sequence");
        tail_calls=tail_calls+1;
    end

    initial begin
        integer began;
        repeat(3) @(negedge clk); rst=0;
        command(0,0,0,8,9,7); result(VALUE,NONE,63,1);
        command(1,1,0,8,-192'd9,7); result(VALUE,NONE,-385'd2,7);
        command(2,0,0,8,9,17); result(VALUE,NONE,-385'd8,31);
        command(3,1,0,8,-192'd9,2); result(VALUE,NONE,-385'd4,257);
        command(4,0,0,8,30,0); result(VALUE,NONE,5,1);
        command(5,1,0,2,-192'd1,1); result(VALUE,NONE,1,7);
        command(6,0,0,8,9,2); result(VALUE,NONE,4,31);
        command(7,0,0,8,30,0); result(VALUE,NONE,5,257);
        // FT-T07：完整385位正大值和最负192位，防止桥错误地只保留低192位。
        command(0,0,0,385,0,{192{1'b1}}); result(VALUE,NONE,0,7);
        command(0,0,0,385,{192{1'b1}},{192{1'b1}});
        result(VALUE,NONE,(385'b1<<384)-(385'b1<<193)+385'd1,31);
        command(0,1,1,385,192'b1<<191,192'b1<<191); result(VALUE,NONE,385'b1<<382,7);
        command(1,1,1,193,192'b1<<191,192'b1<<191); result(VALUE,NONE,-(385'b1<<192),7);
        command(2,0,0,193,0,{192{1'b1}}); result(VALUE,NONE,-((385'b1<<192)-385'd1),7);
        command(3,0,0,193,1,0); result(FRAME_FAIL,DIV_ZERO,0,7);
        command(3,0,1,193,1,-192'd1); result(FRAME_FAIL,FORMAT,0,7);
        command(4,0,0,97,30,1); result(FRAME_FAIL,FORMAT,0,7);
        command(4,0,0,97,{192{1'b1}},0); result(VALUE,NONE,385'b1<<96,7);
        command(7,0,0,96,{192{1'b1}},0); result(VALUE,NONE,(385'b1<<96)-385'd1,7);
        command(5,1,0,2,192'b1<<191,{192{1'b1}}); result(VALUE,NONE,1,7);
        command(1,0,0,1,9,7); result(FRAME_FAIL,OVERFLOW,0,7);
        command(4,0,0,0,30,0); result(FRAME_FAIL,FORMAT,0,7);
        // SEND停顿257沿，abort不撤回已valid请求，恢复后必须真正接受并关闭。
        request_enable=0; command(0,0,0,8,9,7);
        while(!child_req_valid) @(negedge clk);
        abort=1; repeat(257) @(negedge clk); request_enable=1;
        result(CANCEL_DROP,NONE,0,31); abort=0;
        // 接纳同沿取消、尚未公开child：不消耗私有序号。
        began=actual_calls; abort=1; command(1,0,0,8,1,2); result(CANCEL_DROP,NONE,0,31); abort=0;
        if(actual_calls!=began) $fatal(1,"prepublication abort issued child request");
        // 子已HELD而桥尚不可消费：旧VALUE保持，桥在自己发布前改为DROP。
        response_enable=0; command(1,0,0,8,1,2);
        while(!actual_rsp_valid) @(negedge clk);
        abort=1; repeat(31) @(negedge clk); response_enable=1;
        result(CANCEL_DROP,NONE,0,31); abort=0;
        for(integer fault=1;fault<=8;fault=fault+1) begin
            fault_mode=fault; command(1,0,0,8,1,2);
            result(FRAME_FAIL,fault==8?OVERFLOW:INTERNAL,0,7);
        end
        // 隔离fake child延迟quiet：返回已消费仍不得发布桥结果或伪造关闭。
        fault_mode=9; command(1,0,0,8,1,2);
        while(!child_rsp_valid) @(negedge clk);
        fault_quiet_block=1;
        while(dut.state!=dut.CHILD_CLOSE) @(negedge clk);
        repeat(257) begin @(negedge clk); if(result_valid || bridge_quiet) $fatal(1,"quiet fence bypassed"); end
        fault_quiet_block=0; result(VALUE,NONE,3,7);
        fault_mode=0;
        command(1,0,0,8,1,2); while(!result_valid) @(negedge clk); abort=1;
        result(VALUE,NONE,3,257); abort=0;
        for(integer index=0;index<3;index=index+1) begin
            @(negedge clk); tail_command={192'd2,192'd1,9'd8,2'd0,3'd1,8'd7}; tail_valid=1;
            do @(posedge clk); while(!tail_ready);
            @(negedge clk); tail_valid=0; began=cycle;
            while(!tail_result_valid) begin @(negedge clk); if(cycle-began>16384) $fatal(1,"tail close"); end
            if(tail_result!== (index<2?{385'd3,NONE,VALUE,8'd7}:{385'd0,CAPACITY,FRAME_FAIL,8'd7})) $fatal(1,"tail result");
            tail_result_ready=1; @(posedge clk); @(negedge clk); tail_result_ready=0;
        end
        if(tail_calls!=2 || dut.next_sequence!=actual_calls+fault_calls) $fatal(1,"private sequence counted wrong event");
        finished=1; $display("PASS bridge tests=%0d actual_calls=%0d isolated_fault_calls=%0d tail_calls=%0d",tests,actual_calls,fault_calls,tail_calls); $finish;
    end
endmodule
