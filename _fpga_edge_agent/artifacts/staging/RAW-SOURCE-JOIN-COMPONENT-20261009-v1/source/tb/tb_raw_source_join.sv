`timescale 1ns/1ps
// RJ-T01..03：完整源字节与独立二维参考相同；公开端口故障及两个实际终态。
module tb_raw_source_join #(parameter integer WIDTH=64,HEIGHT=32,RUN_PROTOCOL=1);
    localparam integer P=WIDTH*HEIGHT/2,L=WIDTH*HEIGHT*3,A=((L+63)/64)*64,LINES=A/64;
    logic clk=0,rst=1,finished=0;always #5 clk=~clk;
    logic job_valid=0,job_ready;logic [31:0] job_base=32'h100000;
    logic [63:0] job_handle=64'hf431abce12345678;logic [95:0] job_scope=96'h98765432fedcba0112345678;logic [1:0] phase=0;
    logic in_valid=0,in_ready,in_bad=0;logic [19:0] raw_pair=0;
    logic [10:0] in_x_even=0,in_y=0;logic [2:0] in_markers=0;logic [63:0] in_handle=64'hf431abce12345678;
    logic cancel_valid=0;logic [63:0] cancel_id=64'hf431abce12345678;
    logic done_valid,done_ready=0,source_stop,quarantined;
    logic [63:0] done_id;logic [95:0] done_scope;logic [1:0] outcome,failed_stage;logic [7:0] reason;
    logic [21:0] accepted_raw,accepted_rgb,written_lines,discarded_rgb;logic [31:0] logical_bytes,physical_bytes;
    logic line_req_valid,line_req_ready=0,line_write,line_rsp_valid=0,line_rsp_ready,line_error=0,line_drained=1;
    logic [31:0] line_addr;logic [511:0] line_wdata;
    raw_source_join #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) dut(.*,.line_rdata(512'd0));
    logic [19:0] input_values[0:P-1];logic [511:0] expected_lines[0:LINES-1];byte unsigned memory_bytes[0:A-1];
    logic pending=0,hold_request=0,hold_response=0,next_error=0,next_drained=1,random_stalls=0,held_request=0,held_done=0;
    logic [544:0] request_body;logic [323:0] done_body;
    logic [31:0] active_base;logic [63:0] active_id;logic [95:0] active_scope;
    logic [31:0] rng=32'hb719ade5;
    integer cycles=0,request_count=0,input_events=0,delay_count=0,normal_frames=0,cases=0,cancels=0,errors=0;
    integer writer_first=0,raw_first=0,discard_faults=0,maximum_latency=3;
    always @(negedge clk)begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        line_req_ready=!rst && !pending && !hold_request && (!random_stalls || rng[2:0]!=0);
        line_rsp_valid=!rst && pending && delay_count==0 && !hold_response && (!random_stalls || rng[5:3]!=0);
    end
    always @(posedge clk)begin
        cycles++;
        if(rst)begin pending=0;held_request=0;held_done=0;request_count=0;input_events=0;end
        else begin
            if(held_request && (!line_req_valid || {line_write,line_addr,line_wdata}!==request_body))$fatal(1,"Join held line changed");
            if(held_done && (!done_valid || {done_id,done_scope,outcome,reason,failed_stage,accepted_raw,accepted_rgb,logical_bytes,physical_bytes,written_lines,discarded_rgb}!==done_body))$fatal(1,"Join held completion changed");
            held_request=line_req_valid && !line_req_ready;request_body={line_write,line_addr,line_wdata};
            held_done=done_valid && !done_ready;done_body={done_id,done_scope,outcome,reason,failed_stage,accepted_raw,accepted_rgb,logical_bytes,physical_bytes,written_lines,discarded_rgb};
            if(job_valid && job_ready)begin active_base=job_base;active_id=job_handle;active_scope=job_scope;request_count=0;input_events=0;end
            if(in_valid && in_ready)input_events++;
            if(dut.raw_done_fire && !dut.writer_closed)raw_first++;
            if(dut.writer_done_fire && !dut.raw_closed)writer_first++;
            if(line_req_valid && line_req_ready)begin
                integer offset;
                offset=integer'({1'b0,line_addr}-{1'b0,active_base});
                if(pending || !line_write || line_addr[5:0]!=0 || offset!=request_count*64 || offset<0 || offset+64>A)$fatal(1,"Join line grant/order");
                if(line_wdata!==expected_lines[offset/64])$fatal(1,"Join RGB source bytes mismatch offset=%0d actual=%h expected=%h",offset,line_wdata,expected_lines[offset/64]);
                for(integer b=0;b<64;b++)memory_bytes[offset+b]=line_wdata[b*8+:8];
                request_count++;pending=1;delay_count=maximum_latency;line_error=next_error;line_drained=next_drained;
            end else if(pending && delay_count>0)delay_count--;
            if(line_rsp_valid && line_rsp_ready)pending=0;
        end
        if(cycles>(RUN_PROTOCOL ? 4000000 : 120000000))$fatal(1,"RAW-source join watchdog state=%0d cases=%0d",dut.state,cases);
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;job_valid=0;in_valid=0;in_bad=0;cancel_valid=0;done_ready=0;
        hold_request=0;hold_response=0;next_error=0;next_drained=1;random_stalls=0;maximum_latency=3;
        job_base=32'h100000;job_handle=64'hf431abce12345678;job_scope=96'h98765432fedcba0112345678;in_handle=job_handle;cancel_id=job_handle;
        for(integer b=0;b<A;b++)memory_bytes[b]=8'hcb;
        repeat(3)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic start_job(input integer phase_value,input logic reject=0);
        @(negedge clk);phase=2'(phase_value);job_valid=1;do @(posedge clk);while(!job_ready);
        @(negedge clk);job_valid=0;job_scope=96'h111122223333444455556666;job_handle=64'h1111222233334444;phase=2'(phase_value^3);job_base=32'h500000;
        if(reject)begin while(!done_valid)@(negedge clk);end
        else while(!in_ready)@(negedge clk);
    endtask
    task automatic prepare(input integer n,input integer corruption=0);
        raw_pair=input_values[n];in_x_even=11'((n%(WIDTH/2))*2);in_y=11'(n/(WIDTH/2));
        in_markers={n==P-1,n%(WIDTH/2)==WIDTH/2-1,n==0};in_handle=active_id;in_bad=0;
        case(corruption)
            1:in_bad=1;
            2:in_handle=active_id^64'd1;
            3:in_x_even=in_x_even^11'd2;
            4:in_markers=in_markers^3'd1;
            default:begin end
        endcase
    endtask
    task automatic send_one(input integer n,input integer corruption=0);
        @(negedge clk);prepare(n,corruption);in_valid=1;do @(posedge clk);while(!in_ready);
        @(negedge clk);in_valid=0;in_bad=0;
    endtask
    task automatic feed_until_stop;
        integer n;
        n=0;@(negedge clk);prepare(0);in_valid=1;
        while(n<P && !source_stop)begin
            @(posedge clk);if(in_valid && in_ready)n++;
            @(negedge clk);if(n<P && !source_stop)begin prepare(n);in_valid=!random_stalls || rng[7:6]!=0;end
        end
        in_valid=0;
    endtask
    task automatic cancel_matching;
        @(negedge clk);cancel_valid=1;cancel_id=active_id;
        @(posedge clk);@(negedge clk);cancel_valid=0;
    endtask
    task automatic take_done(input integer expected_outcome,input integer expected_reason,input integer stage=-1);
        while(!done_valid)@(negedge clk);
        if(outcome!=expected_outcome || reason!=expected_reason || (stage>=0 && failed_stage!=stage) || done_id!=active_id || done_scope!=active_scope || pending || line_req_valid || line_rsp_ready || quarantined)$fatal(1,"Join final closure/scope out=%0d reason=%0d stage=%0d expected=%0d/%0d/%0d",outcome,reason,failed_stage,expected_outcome,expected_reason,stage);
        if(accepted_raw!=input_events)$fatal(1,"Join RAW actual acceptance mismatch");
        repeat(5)@(negedge clk);done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;
        if(!job_ready)$fatal(1,"Join context not released");
    endtask
    initial begin
        integer listing,frame_count,ignored,file_results,file_output,protocol_file,start_cycles,phase_value;
        string stem;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        listing=$fopen("frame-list.txt","r");if(!listing)$fatal(1,"Missing join list");ignored=$fscanf(listing,"%d\n",frame_count);
        file_results=$fopen("actual-results.txt","w");
        for(integer f=0;f<frame_count;f++)begin
            ignored=$fscanf(listing,"%s %d\n",stem,phase_value);$readmemh({stem,".input.hex"},input_values);$readmemh({stem,".lines.hex"},expected_lines);
            reset_joint();start_job(phase_value);random_stalls=f%2==0;maximum_latency=f%5==3 ? 20 : 3;start_cycles=cycles;
            cancel_valid=1;cancel_id=active_id^64'd1;feed_until_stop();cancel_valid=0;
            while(!done_valid)@(negedge clk);
            if(accepted_raw!=P || accepted_rgb!=P || logical_bytes!=L || physical_bytes!=A || written_lines!=LINES || discarded_rgb!=0)$fatal(1,"Join whole source counts");
            $fwrite(file_results,"%s %0d %0d %0d %0d %0d %0d %0d %0d %0d\n",stem,accepted_raw,accepted_rgb,logical_bytes,physical_bytes,written_lines,discarded_rgb,outcome,reason,cycles-start_cycles);
            file_output=$fopen({stem,".actual.rgb"},"wb");for(integer b=0;b<A;b++)$fwrite(file_output,"%c",memory_bytes[b]);$fclose(file_output);
            cancel_matching();take_done(0,0,0);normal_frames++;
        end
        $fclose(file_results);$fclose(listing);
        if(RUN_PROTOCOL)begin
            reset_joint();job_base++;start_job(phase_value,1);take_done(1,32,3);cases++;
            for(integer bad=1;bad<=4;bad++)begin reset_joint();start_job(phase_value);send_one(0,bad);take_done(1,bad,2);cases++;errors++;end
            reset_joint();start_job(phase_value);send_one(0);cancel_matching();take_done(2,128);cases++;cancels++;
            // REQUEST保持时cancel，两个子模块的实际关闭顺序不同。
            reset_joint();start_job(phase_value);hold_request=1;
            fork
                feed_until_stop();
                begin
                    while(!line_req_valid)@(negedge clk);cancel_matching();repeat(15)@(negedge clk);
                    if(done_valid || !line_req_valid)$fatal(1,"Join cancelled public request lost");hold_request=0;
                end
            join
            take_done(2,128);cases++;cancels++;
            // WAIT回执保持时cancel，不凭最后W提前done。
            reset_joint();start_job(phase_value);hold_response=1;
            fork
                feed_until_stop();
                begin
                    while(!pending)@(negedge clk);cancel_matching();repeat(15)@(negedge clk);
                    if(done_valid || job_ready)$fatal(1,"Join cancelled waiting loan lost");hold_response=0;
                end
            join
            take_done(2,128);cases++;cancels++;
            // 接口反压让RAW公开RGB真实停住，再注入writer错误，必须明确discard旧RGB。
            if(L>2048)begin
                reset_joint();start_job(phase_value);hold_response=1;next_error=1;
                fork
                    feed_until_stop();
                    begin
                        while(!(pending && dut.raw_output_valid && !dut.raw_output_ready && !in_ready))@(negedge clk);
                        repeat(8)@(negedge clk);hold_response=0;
                    end
                join
                take_done(1,16,1);if(discarded_rgb==0)$fatal(1,"Join failed writer did not retire public RGB");discard_faults++;cases++;errors++;
            end
            // 一般安全memory error中途停止输入，无伪完整帧。
            reset_joint();start_job(phase_value);next_error=1;feed_until_stop();take_done(1,16,1);cases++;errors++;
            reset_joint();start_job(phase_value);next_drained=0;feed_until_stop();while(!quarantined)@(negedge clk);
            repeat(20)@(negedge clk);if(done_valid || job_ready || in_ready)$fatal(1,"Join unknown loan falsely released");cases++;
            reset_joint();start_job(phase_value);feed_until_stop();take_done(0,0,0);cases++;
            // job接纳同沿cancel：不启动任何子job，也可安全返回。
            reset_joint();@(negedge clk);job_valid=1;cancel_valid=1;cancel_id=job_handle;
            do @(posedge clk);while(!job_ready);@(negedge clk);job_valid=0;cancel_valid=0;take_done(2,128,0);cases++;cancels++;
        end
        protocol_file=$fopen("protocol-metrics.json","w");
        $fwrite(protocol_file,"{\"finished\":true,\"normal_frames\":%0d,\"cases\":%0d,\"cancel_cases\":%0d,\"error_cases\":%0d,\"discard_fault_cases\":%0d,\"raw_done_first\":%0d,\"writer_done_first\":%0d,\"cycles\":%0d}\n",normal_frames,cases,cancels,errors,discard_faults,raw_first,writer_first,cycles);
        $fclose(protocol_file);finished=1;$display("RAW source join PASS frames=%0d cases=%0d clocks=%0d",normal_frames,cases,cycles);$finish;
    end
endmodule
