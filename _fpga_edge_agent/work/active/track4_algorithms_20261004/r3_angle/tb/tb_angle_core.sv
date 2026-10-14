`timescale 1ns/1ps
module tb_angle_core;
    logic clk=0,rst=1;always #5 clk=~clk;
    logic req_valid=0,rsp_ready=0,cancel_valid=0;logic [621:0] req_body=0;logic [175:0] cancel_id=0;
    wire req_ready,rsp_valid,quiet;wire [584:0] rsp_body;
    angle_core dut(.*);
    logic finished=0;string run_dir;integer input_file,protocol_file,numeric_file,result_file,ncases,rc;
    integer accepted=0,consumed=0,reset_aborted=0,live=0,rom_reads=0,rom_returns=0,rom_reset=0;
    integer products=0,product_returns=0,product_reset=0,formation_max=0,cancel_checks=0,reset_checks=0;
    logic [621:0] protocol_req[0:3],golden_req,last_actual_request;
    logic [584:0] protocol_rsp[0:3],golden_rsp;
    always @(posedge clk)begin
        if(rst)begin
            if(live)begin reset_aborted++;live=0;end
            if(dut.rom_pending===1'b1)rom_reset++;
            if(dut.product_pending===1'b1)product_reset++;
        end else begin
            if(req_valid && req_ready)begin accepted++;live++;last_actual_request=req_body;end
            if(rsp_valid && rsp_ready)begin consumed++;live--;end
            if(live<0 || live>1)$fatal(1,"angle context live count");
            if(dut.rom_re)rom_reads++;
            if(dut.rom_pending)rom_returns++;
            if(dut.product_start)products++;
            if(dut.product_pending)begin product_returns++;if(!dut.product_valid)$fatal(1,"missing product return");end
            if(dut.product_valid && !dut.product_pending)$fatal(1,"orphan product");
        end
    end
    task automatic cold_reset;
        begin
            @(negedge clk);rst=1;req_valid=0;rsp_ready=0;cancel_valid=0;repeat(2)@(posedge clk);
            @(negedge clk);rst=0;#1;if(!quiet || rsp_valid)$fatal(1,"reset did not clear qualification");
        end
    endtask
    task automatic launch(input logic [621:0] request,input logic same_cancel=0,input logic wrong_cancel=0);
        begin
            @(negedge clk);req_body=request;req_valid=1;cancel_valid=same_cancel || wrong_cancel;cancel_id=request[175:0]^(wrong_cancel?176'd1:176'd0);
            do @(posedge clk);while(!req_ready);
            #1;@(negedge clk);req_valid=0;cancel_valid=0;
        end
    endtask
    task automatic receive(input logic [584:0] expected,input integer hold_cycles,input integer deadline=96);
        integer waits;
        begin
            waits=0;while(!rsp_valid)begin @(posedge clk);#1;waits++;if(waits>deadline)$fatal(1,"angle formation bound");end
            if(waits>formation_max)formation_max=waits;
            if(rsp_body!==expected)$fatal(1,"angle response actual=%h expected=%h",rsp_body,expected);
            repeat(hold_cycles)begin @(posedge clk);#1;if(!rsp_valid || rsp_body!==expected || req_ready)$fatal(1,"angle held response changed");end
            @(negedge clk);rsp_ready=1;@(posedge clk);#1;@(negedge clk);rsp_ready=0;
            if(!quiet)$fatal(1,"angle quiet did not release");
        end
    endtask
    task automatic reach(input integer target,input integer choice);
        integer waits;
        begin
            launch(protocol_req[choice]);waits=0;
            while(dut.state!=target)begin @(negedge clk);waits++;if(waits>96 || (rsp_valid && dut.state!=target))$fatal(1,"state%0d not reached choice%0d",target,choice);end
        end
    endtask
    task automatic cancel_stage(input integer target);
        integer choice;
        logic [584:0] expected;
        begin
            cold_reset();choice=(target==13 || (target>=14 && target<=18))?3:0;
            expected=angle_protocol_pkg::pack_response(protocol_req[choice],angle_protocol_pkg::CANCEL_DROP,8'd0,385'd0);
            if(target==0)launch(protocol_req[choice],1,0);
            else begin
                reach(target,choice);cancel_id=protocol_req[choice][175:0];cancel_valid=1;
                @(posedge clk);#1;@(negedge clk);cancel_valid=0;
            end
            if(target==20)expected=protocol_rsp[choice]; // 已公开HELD只能消费/丢弃原体。
            receive(expected,1,3);cancel_checks++;
        end
    endtask
    task automatic reset_stage(input integer target);
        integer choice;
        logic [621:0] recovery;logic [584:0] expected;
        begin
            cold_reset();choice=(target==13 || (target>=14 && target<=18))?3:0;
            if(target!=0)reach(target,choice);
            cold_reset();repeat(3)begin @(posedge clk);#1;if(rsp_valid || !quiet)$fatal(1,"reset leaked old result");end
            recovery=protocol_req[2];recovery[175:0]=recovery[175:0]^176'd2;
            expected=protocol_rsp[2];expected[175:0]=recovery[175:0];launch(recovery);receive(expected,1);reset_checks++;
        end
    endtask
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir))$fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected ANGLE fatal probe");
        input_file=$fopen({run_dir,"/vectors/cases.txt"},"r");protocol_file=$fopen({run_dir,"/vectors/protocol.txt"},"r");
        numeric_file=$fopen({run_dir,"/core-numeric.tsv"},"w");if(!input_file || !protocol_file || !numeric_file)$fatal(1,"core files");
        for(integer i=0;i<4;i++)begin rc=$fscanf(protocol_file,"%h %h\n",protocol_req[i],protocol_rsp[i]);if(rc!=2)$fatal(1,"protocol requests");end
        rc=$fscanf(input_file,"%d\n",ncases);if(rc!=1)$fatal(1,"numeric case count");cold_reset();
        for(integer i=0;i<ncases;i++)begin
            integer hold_cycles;
            rc=$fscanf(input_file,"%h %h\n",golden_req,golden_rsp);if(rc!=2)$fatal(1,"numeric descriptor%0d",i);
            case(i%4)0:hold_cycles=1;1:hold_cycles=7;2:hold_cycles=31;default:hold_cycles=257;endcase
            launch(golden_req);receive(golden_rsp,hold_cycles);
            $fwrite(numeric_file,"%0d %h %h\n",i,last_actual_request,rsp_body);
            if(i%8192==0)$display("ANGLE numeric case%0d/%0d",i,ncases);
        end
        for(integer target=0;target<=20;target++)begin cancel_stage(target);reset_stage(target);end
        begin: held_nonvalue_checks
            logic [621:0] bad;logic [584:0] error_response,drop_response;
            bad=protocol_req[0];bad[176+:11]=7;
            error_response=angle_protocol_pkg::pack_response(bad,2,3,0);
            drop_response=angle_protocol_pkg::pack_response(protocol_req[0],3,0,0);
            cold_reset();launch(bad);while(!rsp_valid)begin @(posedge clk);#1;end
            @(negedge clk);cancel_id=bad[175:0];cancel_valid=1;@(posedge clk);#1;
            @(negedge clk);cancel_valid=0;receive(error_response,1);cancel_checks++;
            launch(protocol_req[0],1,0);while(!rsp_valid)begin @(posedge clk);#1;end
            @(negedge clk);cancel_id=protocol_req[0][175:0];cancel_valid=1;@(posedge clk);#1;
            @(negedge clk);cancel_valid=0;receive(drop_response,1);cancel_checks++;
            launch(bad);while(!rsp_valid)begin @(posedge clk);#1;end
            cold_reset();reset_checks++;
            launch(protocol_req[0],1,0);while(!rsp_valid)begin @(posedge clk);#1;end
            cold_reset();reset_checks++;
        end
        // pending ROM取消后再取消DROP_WAIT，不能重新发读或延长收尾。
        cold_reset();reach(5,0);cancel_id=protocol_req[0][175:0];cancel_valid=1;@(posedge clk);#1;
        if(dut.state!=dut.DROP_WAIT)$fatal(1,"pending cancellation did not enter DROP_WAIT");
        @(negedge clk);cancel_valid=1;@(posedge clk);#1;@(negedge clk);cancel_valid=0;
        receive(angle_protocol_pkg::pack_response(protocol_req[0],3,0,0),1,3);cancel_checks++;
        cold_reset();reach(5,0);cancel_id=protocol_req[0][175:0];cancel_valid=1;@(posedge clk);#1;cold_reset();reset_checks++;
        // 错ID不能取消，响应fire同拍取消也不能重写已经公开的数据。
        launch(protocol_req[1],0,1);receive(protocol_rsp[1],7);cancel_checks++;
        launch(protocol_req[2]);while(!rsp_valid)begin @(posedge clk);#1;end
        @(negedge clk);cancel_valid=1;cancel_id=protocol_req[2][175:0];rsp_ready=1;
        @(posedge clk);if(rsp_body!==protocol_rsp[2])$fatal(1,"rsp fire cancel changed old body");#1;
        @(negedge clk);cancel_valid=0;rsp_ready=0;cancel_checks++;
        // 一个已公开的第二请求保持到旧响应释放，再真正fire。
        launch(protocol_req[0]);@(negedge clk);req_valid=1;req_body=protocol_req[2];
        while(!rsp_valid)begin @(posedge clk);#1;if(req_ready)$fatal(1,"second request accepted while live");end
        repeat(7)begin @(posedge clk);#1;if(req_ready || rsp_body!==protocol_rsp[0])$fatal(1,"busy request/held response");end
        @(negedge clk);rsp_ready=1;@(posedge clk);#1;@(negedge clk);rsp_ready=0;
        @(posedge clk);if(!req_ready)$fatal(1,"second request did not progress");#1;@(negedge clk);req_valid=0;
        receive(protocol_rsp[2],1);
        if(live || accepted!=consumed+reset_aborted || rom_reads!=rom_returns+rom_reset || products!=product_returns+product_reset)$fatal(1,"angle final three ledgers");
        $fclose(input_file);$fclose(protocol_file);$fclose(numeric_file);result_file=$fopen({run_dir,"/core-result.json"},"w");
        $fwrite(result_file,"{\"status\":\"PASS\",\"finished\":true,\"cases\":%0d,\"formation_max\":%0d,\"accepted\":%0d,\"consumed\":%0d,\"reset_aborted\":%0d,\"rom_reads\":%0d,\"rom_returns\":%0d,\"rom_reset\":%0d,\"products\":%0d,\"product_returns\":%0d,\"product_reset\":%0d,\"cancel_checks\":%0d,\"reset_checks\":%0d}\n",ncases,formation_max,accepted,consumed,reset_aborted,rom_reads,rom_returns,rom_reset,products,product_returns,product_reset,cancel_checks,reset_checks);
        $fclose(result_file);$display("PASS ANGLE numeric and protocol");finished=1;#1;$finish;
    end
    initial begin repeat(30000000)@(posedge clk);$fatal(1,"ANGLE total cycle watchdog");end
endmodule
