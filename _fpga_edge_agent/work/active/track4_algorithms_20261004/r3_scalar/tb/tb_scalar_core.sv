`timescale 1ns/1ps
module tb_scalar_core;
    import scalar_protocol_pkg::*;
    reg clk=0;always #20 clk=~clk;
    reg rst=1,req_valid=0,rsp_ready=0,cancel_valid=0;
    reg [621:0] req_body='0;
    reg [175:0] cancel_id='0;
    wire req_ready,rsp_valid,quiet;
    wire [584:0] rsp_body;
    reg finished=0;
    scalar_core dut(.*);
    string run_dir;
    integer cycles=0,accepted=0,consumed=0,formed=0,aborted=0;
    integer req_holds=0,rsp_holds=0,cancels=0,resets=0,max_latency=0;
    integer state_seen[0:18];
    integer numeric_count=0,cancel_checks=0,reset_checks=0,pair_checks=0;
    reg live=0,previous_req_held=0,previous_rsp_held=0;
    reg [175:0] live_id;
    reg [621:0] previous_request;
    reg [584:0] previous_response;
    reg old_rsp_valid;
    longint unsigned fixture_sequence=2000000;
    reg [621:0] fixture_request[0:7];
    reg [584:0] fixture_response[0:7];
    integer observed_file,result_file,vector_file,fixture_file,scan,gap,stall;
    reg [621:0] vector_request;
    reg [584:0] vector_response;

    // 沿前记真实fire，沿后观察形成；全body保持与一笔资格不靠TB调用次数代替。
    always @(posedge clk) begin
        cycles=cycles+1;
        old_rsp_valid=rsp_valid;
        if(rst) begin
            if(live) begin aborted=aborted+1;live=0;end
            previous_req_held=0;previous_rsp_held=0;resets=resets+1;
            if(req_ready || rsp_valid) $fatal(1,"reset permitted a transfer");
        end else begin
            if(previous_req_held && (!req_valid || req_body!==previous_request))
                $fatal(1,"held request changed");
            if(previous_rsp_held && (!rsp_valid || rsp_body!==previous_response))
                $fatal(1,"held response changed");
            if(req_valid && !req_ready) req_holds=req_holds+1;
            if(rsp_valid && !rsp_ready) rsp_holds=rsp_holds+1;
            previous_req_held=req_valid && !req_ready;
            previous_rsp_held=rsp_valid && !rsp_ready;
            previous_request=req_body;previous_response=rsp_body;
            if(req_valid && req_ready) begin
                if(live) $fatal(1,"second in-flight request");
                accepted=accepted+1;live=1;live_id=req_body[175:0];
            end
            if(rsp_valid && rsp_ready) begin
                if(!live || rsp_body[175:0]!==live_id) $fatal(1,"response ownership");
                consumed=consumed+1;live=0;
            end
            if(cancel_valid && live && cancel_id==live_id) cancels=cancels+1;
        end
        #1;
        if(!rst) begin
            if(rsp_valid && !old_rsp_valid) formed=formed+1;
            if($isunknown(dut.state) || dut.state>18) $fatal(1,"invalid state");
            state_seen[dut.state]=state_seen[dut.state]+1;
            if(accepted!=consumed+aborted+live) $fatal(1,"transaction conservation");
        end
    end

    task automatic send_request(input reg [621:0] body,output integer accepted_cycle);
        reg fire;
        begin
            @(negedge clk);req_body=body;req_valid=1;
            do begin @(posedge clk);fire=req_ready && !rst;#2;end while(!fire);
            accepted_cycle=cycles;
            @(negedge clk);req_valid=0;
        end
    endtask
    task automatic wait_response(input integer accepted_cycle);
        begin
            while(!rsp_valid) begin
                @(negedge clk);
                if(cycles-accepted_cycle>4096) $fatal(1,"response formation bound");
            end
            if(cycles-accepted_cycle>max_latency) max_latency=cycles-accepted_cycle;
        end
    endtask
    task automatic consume_checked(input reg [584:0] expected,input integer hold_cycles);
        begin
            repeat(hold_cycles) @(negedge clk);
            if(!rsp_valid || rsp_body!==expected) begin
                $display("kind=%0d expected=%h actual=%h",expected[176+:5],expected,rsp_body);
                $fatal(1,"complete response mismatch");
            end
            rsp_ready=1;
            @(posedge clk);#2;
            @(negedge clk);rsp_ready=0;
        end
    endtask
    task automatic decorate(input integer kind,output reg [621:0] request,output reg [584:0] expected);
        begin
            request=fixture_request[kind];expected=fixture_response[kind];
            request[104+:64]=fixture_sequence;expected[104+:64]=fixture_sequence;
            fixture_sequence=fixture_sequence+1;
        end
    endtask
    function automatic [584:0] cancelled_response(input reg [584:0] expected);
        reg [584:0] body;
        begin
            body='0;body[189:0]=expected[189:0];body[190+:2]=CANCEL_DROP;
            cancelled_response=body;
        end
    endfunction

    task automatic cancel_at(input integer kind,input integer wanted_state,input integer purpose);
        reg [621:0] request;
        reg [584:0] expected;
        integer start,waiting,cancel_cycle;
        reg already_visible;
        begin
            decorate(kind,request,expected);send_request(request,start);waiting=0;
            while(dut.state!=wanted_state || (purpose>=0 && dut.multiply_purpose!=purpose)) begin
                @(negedge clk);waiting=waiting+1;
                if(waiting>4096) $fatal(1,"cancel fixture did not reach target state");
            end
            already_visible=rsp_valid;
            cancel_cycle=cycles;cancel_valid=1;cancel_id=request[175:0];
            wait_response(start);
            if(!already_visible && cycles-cancel_cycle>3) $fatal(1,"cancel latency");
            if(!already_visible) expected=cancelled_response(expected);
            consume_checked(expected,2);cancel_valid=0;cancel_checks=cancel_checks+1;
        end
    endtask
    task automatic cancel_on_accept;
        reg [621:0] request;
        reg [584:0] expected;
        integer start;
        begin
            decorate(0,request,expected);
            cancel_valid=1;cancel_id=request[175:0];send_request(request,start);
            wait_response(start);consume_checked(cancelled_response(expected),3);
            cancel_valid=0;cancel_checks=cancel_checks+1;
        end
    endtask
    task automatic wrong_cancel;
        reg [621:0] request;
        reg [584:0] expected;
        integer start;
        begin
            decorate(4,request,expected);send_request(request,start);
            cancel_valid=1;cancel_id=request[175:0]^176'd1;
            wait_response(start);consume_checked(expected,3);
            cancel_valid=0;cancel_checks=cancel_checks+1;
        end
    endtask
    task automatic held_cancel_and_fire;
        reg [621:0] request;
        reg [584:0] expected;
        integer start;
        begin
            decorate(0,request,expected);send_request(request,start);wait_response(start);
            cancel_valid=1;cancel_id=request[175:0];consume_checked(expected,0);
            cancel_valid=0;cancel_checks=cancel_checks+1;
        end
    endtask
    task automatic reset_at(input integer kind,input integer wanted_state,input integer purpose);
        reg [621:0] request;
        reg [584:0] expected;
        integer start,waiting;
        begin
            decorate(kind,request,expected);
            if(wanted_state!=0) begin
                send_request(request,start);waiting=0;
                while(dut.state!=wanted_state || (purpose>=0 && dut.multiply_purpose!=purpose)) begin
                    @(negedge clk);waiting=waiting+1;
                    if(waiting>4096) $fatal(1,"reset fixture did not reach target state");
                end
            end else @(negedge clk);
            rst=1;req_valid=1;req_body=request;rsp_ready=1;
            @(posedge clk);#2;
            if(rsp_valid || req_ready || dut.state!=0) $fatal(1,"cold reset did not isolate");
            @(negedge clk);rst=0;req_valid=0;rsp_ready=0;cancel_valid=0;
            decorate(3,request,expected);send_request(request,start);
            wait_response(start);consume_checked(expected,1);
            reset_checks=reset_checks+1;
        end
    endtask
    task automatic overlapping_offer;
        reg [621:0] request0,request1;
        reg [584:0] expected0,expected1;
        integer start,second_start;
        reg fire;
        begin
            decorate(0,request0,expected0);decorate(3,request1,expected1);
            send_request(request0,start);
            req_valid=1;req_body=request1;
            wait_response(start);consume_checked(expected0,31);
            do begin @(posedge clk);fire=req_ready;#2;end while(!fire);
            second_start=cycles;@(negedge clk);req_valid=0;
            wait_response(second_start);consume_checked(expected1,7);
            pair_checks=pair_checks+1;
        end
    endtask

    initial begin : execute_suite
        integer start;
        if(!$value$plusargs("RUN_DIR=%s",run_dir)) $fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE")) $fatal(1,"expected scalar fatal probe");
        for(integer i=0;i<19;i=i+1) state_seen[i]=0;
        fixture_file=$fopen({run_dir,"/vectors/fixtures.txt"},"r");
        if(!fixture_file) $fatal(1,"fixture file missing");
        for(integer kind=0;kind<8;kind=kind+1) begin
            scan=$fscanf(fixture_file,"%h %h\n",fixture_request[kind],fixture_response[kind]);
            if(scan!=2) $fatal(1,"fixture parse");
        end
        $fclose(fixture_file);
        vector_file=$fopen({run_dir,"/vectors/core.txt"},"r");
        observed_file=$fopen({run_dir,"/core-observed.txt"},"w");
        if(!vector_file || !observed_file) $fatal(1,"vector/observed file missing");
        repeat(3) @(negedge clk);rst=0;
        while(1) begin
            scan=$fscanf(vector_file,"%h %h %d %d\n",vector_request,vector_response,gap,stall);
            if(scan==-1) break;
            if(scan!=4 || gap<0 || gap>2 || stall<0 || stall>31) $fatal(1,"vector parse/range");
            repeat(gap) @(negedge clk);
            send_request(vector_request,start);wait_response(start);
            $fwrite(observed_file,"%0d %0147h\n",numeric_count,rsp_body);
            consume_checked(vector_response,stall);numeric_count=numeric_count+1;
        end
        $fclose(vector_file);$fclose(observed_file);
        // 所有公开大状态/私有状态均实际达到后再取消；未达到就失败。
        cancel_on_accept();wrong_cancel();held_cancel_and_fire();
        for(integer s=1;s<=18;s=s+1) begin
            integer kind;
            kind=(s==8 || s==9)?1:(s==10)?5:(s>=11 && s<=13)?3:(s==14 || s==15)?4:0;
            cancel_at(kind,s,-1);
        end
        for(integer purpose=1;purpose<=3;purpose=purpose+1) cancel_at(4,7,purpose);
        for(integer s=0;s<=18;s=s+1) begin
            integer kind;
            kind=(s==8 || s==9)?1:(s==10)?5:(s>=11 && s<=13)?3:(s==14 || s==15)?4:0;
            reset_at(kind,s,-1);
        end
        for(integer purpose=1;purpose<=3;purpose=purpose+1) reset_at(4,7,purpose);
        overlapping_offer();
        @(negedge clk);
        if(live || !quiet || accepted!=consumed+aborted || req_holds==0 || rsp_holds==0)
            $fatal(1,"terminal protocol ledger");
        for(integer s=0;s<=18;s=s+1) if(state_seen[s]==0) $fatal(1,"state coverage missing");
        result_file=$fopen({run_dir,"/core-result.json"},"w");
        if(!result_file) $fatal(1,"result file missing");
        $fwrite(result_file,"{\"status\":\"PASS\",\"finished\":true,\"numeric_count\":%0d,\"accepted\":%0d,\"consumed\":%0d,\"formed\":%0d,\"reset_aborted\":%0d,\"req_hold_checks\":%0d,\"rsp_hold_checks\":%0d,\"cancel_active_cycles\":%0d,\"cancel_scenarios\":%0d,\"reset_scenarios\":%0d,\"overlap_scenarios\":%0d,\"max_formation_cycles\":%0d,\"cycles\":%0d,\"state_observations\":[",numeric_count,accepted,consumed,formed,aborted,req_holds,rsp_holds,cancels,cancel_checks,reset_checks,pair_checks,max_latency,cycles);
        for(integer s=0;s<=18;s=s+1) begin
            if(s!=0) $fwrite(result_file,",");$fwrite(result_file,"%0d",state_seen[s]);
        end
        $fwrite(result_file,"]}\n");$fclose(result_file);
        $display("SCALAR_CORE_PASS numeric=%0d accepted=%0d consumed=%0d aborted=%0d",numeric_count,accepted,consumed,aborted);
        finished=1;$finish;
    end
endmodule
