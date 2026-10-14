`timescale 1ns/1ps
// SW-T01..04：独立连续字节内存、旧事件账本；所有故障从公开端口注入。
module tb_rgb_source_writer #(parameter integer WIDTH=34,HEIGHT=19,RUN_PROTOCOL=1);
    localparam integer PAIRS=WIDTH*HEIGHT/2,L=WIDTH*HEIGHT*3,A=((L+63)/64)*64,LINES=A/64;
    logic clk=0,rst=1,finished=0;always #5 clk=~clk;
    logic job_valid=0,job_ready,job_rsp_valid,job_rsp_ready=0,job_rsp_error;
    logic [31:0] job_base=32'h100000;
    logic [63:0] job_handle=64'habcdefff12345678;
    logic in_valid=0,in_ready,in_bad=0;
    logic [47:0] in_rgb=0;logic [10:0] in_x_even=0,in_y=0;logic [2:0] in_markers=0;
    logic [63:0] in_handle=64'habcdefff12345678;
    logic cancel_valid=0;logic [63:0] cancel_id=64'habcdefff12345678;
    logic done_valid,done_ready=0,source_stop,quarantined;
    logic [63:0] done_id;logic [1:0] outcome;logic [7:0] reason;
    logic [21:0] accepted_pairs,written_lines;logic [31:0] logical_bytes,physical_bytes;
    logic line_req_valid,line_req_ready=0,line_write,line_rsp_valid=0,line_rsp_ready,line_error=0,line_drained=1;
    logic [31:0] line_addr;logic [511:0] line_wdata;
`ifdef POSTMAP
    rgb_source_writer dut(.*,.line_rdata(512'd0));
`else
    rgb_source_writer #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) dut(.*,.line_rdata(512'd0));
`endif
    logic [47:0] input_values[0:PAIRS-1];logic [511:0] expected_lines[0:LINES-1];
    byte unsigned memory_bytes[0:A-1];
    logic pending=0,hold_request=0,hold_response=0,next_error=0,next_drained=1,random_stalls=0;
    logic held_request=0,held_done=0,held_cfg=0;
    logic [544:0] held_request_body;logic [181:0] held_done_body;
    logic held_cfg_error;
    logic [31:0] active_base;logic [63:0] active_id;
    integer cycles=0,delay_count=0,request_count=0,input_events=0,normal_frames=0,protocol_cases=0,cancel_cases=0,errors=0;
    integer re_events=0,discard_cases=0,two_packet_cycles=0,both_bank_cycles=0,backpressure_cycles=0;
    integer frame_cycles,file_results,check_protocol_payload=0;
    integer maximum_latency=3;
    logic [31:0] random_state=32'h87fa1265;
    function automatic [31:0] advance_random(input logic [31:0] value);
        return {value[30:0],value[31]^value[21]^value[1]^value[0]};
    endfunction
    always @(negedge clk)begin
        random_state=advance_random(random_state);
        line_req_ready=!rst && !pending && !hold_request && (!random_stalls || random_state[2:0]!=0);
        line_rsp_valid=!rst && pending && delay_count==0 && !hold_response && (!random_stalls || random_state[5:3]!=0);
    end
    always @(posedge clk)begin
        cycles++;
        if(rst)begin pending=0;held_request=0;held_done=0;held_cfg=0;request_count=0;input_events=0;end
        else begin
            if(held_request && (!line_req_valid || {line_write,line_addr,line_wdata}!==held_request_body))$fatal(1,"Source held request changed");
            if(held_done && (!done_valid || {done_id,outcome,reason,accepted_pairs,logical_bytes,physical_bytes,written_lines}!==held_done_body))$fatal(1,"Source held done changed");
            if(held_cfg && (!job_rsp_valid || job_rsp_error!==held_cfg_error))$fatal(1,"Source held config changed");
            held_request=line_req_valid && !line_req_ready;held_request_body={line_write,line_addr,line_wdata};
            held_done=done_valid && !done_ready;held_done_body={done_id,outcome,reason,accepted_pairs,logical_bytes,physical_bytes,written_lines};
            held_cfg=job_rsp_valid && !job_rsp_ready;held_cfg_error=job_rsp_error;
            if(job_valid && job_ready)begin active_base=job_base;active_id=job_handle;input_events=0;request_count=0;end
            if(in_valid && in_ready)input_events++;
`ifndef POSTMAP
            if(dut.ram_re)re_events++;
            if(dut.packet_state[0]!=0 && dut.packet_state[1]!=0)two_packet_cycles++;
            if(dut.bank_state[0]!=0 && dut.bank_state[1]!=0)both_bank_cycles++;
`endif
            if(in_valid && !in_ready && !source_stop)backpressure_cycles++;
            if(line_req_valid && line_req_ready)begin
                integer offset;
                offset=integer'({1'b0,line_addr}-{1'b0,active_base});
                if(pending || !line_write || line_addr[5:0]!=0 || offset<0 || offset+64>A || offset!=request_count*64)$fatal(1,"Source request grant/order/owner mismatch");
                if(line_wdata!==expected_lines[offset/64])$fatal(1,"Source payload mismatch offset=%0d actual=%h expected=%h",offset,line_wdata,expected_lines[offset/64]);
                for(integer b=0;b<64;b++)memory_bytes[offset+b]=line_wdata[b*8+:8];
                request_count++;pending=1;delay_count=maximum_latency;
                line_error=next_error;line_drained=next_drained;
            end else if(pending && delay_count>0)delay_count--;
            if(line_rsp_valid && line_rsp_ready)pending=0;
        end
        if(cycles>(RUN_PROTOCOL ? 1000000 : 120000000))$fatal(1,"Source writer watchdog cases=%0d",protocol_cases);
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;job_valid=0;job_rsp_ready=0;in_valid=0;cancel_valid=0;done_ready=0;
        hold_request=0;hold_response=0;next_error=0;next_drained=1;in_bad=0;random_stalls=0;maximum_latency=3;
        job_base=32'h100000;job_handle=64'habcdefff12345678;in_handle=job_handle;cancel_id=job_handle;
        for(integer b=0;b<A;b++)memory_bytes[b]=8'hca;
        repeat(3)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic configure(input logic reject=0);
        @(negedge clk);job_valid=1;do @(posedge clk);while(!job_ready);
        @(negedge clk);job_valid=0;
        while(!job_rsp_valid)@(negedge clk);
        if(job_rsp_error!==reject)$fatal(1,"Source config rejection mismatch");
        // held reply及job提案变化不改变已锁定grant/handle。
        repeat(3)@(negedge clk);job_base=32'h500000;job_handle=64'h123456789abcdef0;
        job_rsp_ready=1;@(posedge clk);@(negedge clk);job_rsp_ready=0;
    endtask
    task automatic prepare_input(input integer n,input integer corrupt=0);
        in_rgb=input_values[n];in_x_even=11'((n%(WIDTH/2))*2);in_y=11'(n/(WIDTH/2));
        in_markers={n==PAIRS-1,n%(WIDTH/2)==WIDTH/2-1,n==0};in_handle=active_id;in_bad=0;
        case(corrupt)
            1:in_bad=1;
            2:in_handle=active_id^64'd1;
            3:in_x_even=in_x_even^11'd2;
            4:in_markers=in_markers^3'd1;
            default:begin end
        endcase
    endtask
    task automatic send_item(input integer n,input integer corrupt=0);
        @(negedge clk);prepare_input(n,corrupt);in_valid=1;
        do @(posedge clk);while(!in_ready);
        @(negedge clk);in_valid=0;in_bad=0;
    endtask
    task automatic send_prefix(input integer items);
        for(integer n=0;n<items;n++)send_item(n);
    endtask
    task automatic send_all_fast;
        integer n;
        n=0;@(negedge clk);prepare_input(0);in_valid=1;
        while(n<PAIRS)begin
            @(posedge clk);if(in_valid && in_ready)n++;
            @(negedge clk);
            if(n==PAIRS)in_valid=0;
            else begin prepare_input(n);in_valid=!random_stalls || random_state[7:6]!=0;end
        end
    endtask
    task automatic cancel_matching;
        @(negedge clk);cancel_valid=1;cancel_id=active_id;
        @(posedge clk);@(negedge clk);cancel_valid=0;
    endtask
    task automatic take_done(input integer expected_outcome,input integer expected_reason);
        while(!done_valid)@(negedge clk);
        if(outcome!=expected_outcome || reason!=expected_reason || done_id!=active_id || accepted_pairs!=input_events || pending || line_req_valid || line_rsp_ready)$fatal(1,"Source completion closure/ledger mismatch out=%0d reason=%0d expected=%0d/%0d accepted=%0d/%0d",outcome,reason,expected_outcome,expected_reason,accepted_pairs,input_events);
        repeat(5)@(negedge clk);done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;
        if(!job_ready)$fatal(1,"Source safe completion did not release job");
    endtask
`ifndef POSTMAP
    task automatic run_cancel_case(input integer kind);
        integer prefix;
        reset_joint();configure();
        case(kind)
            0:begin send_prefix(1);cancel_matching();end // carry6尚无RAM word
            1:begin send_prefix(PAIRS<10 ? PAIRS-1 : 10);cancel_matching();end // FILL/word与carry
            2:begin // 对外公开但尚未fire，两个packet保持有界。
                hold_request=1;send_prefix(PAIRS<180 ? PAIRS : 180);
                while(!line_req_valid)@(negedge clk);
                repeat(20)@(negedge clk);cancel_matching();repeat(15)@(negedge clk);
                if(!line_req_valid || done_valid)$fatal(1,"Source cancel withdrew public loan");
                hold_request=0;
            end
            3:begin
                hold_response=1;send_prefix(PAIRS<180 ? PAIRS : 180);
                while(!pending)@(negedge clk);cancel_matching();repeat(15)@(negedge clk);
                if(done_valid || job_ready)$fatal(1,"Source released outstanding response");hold_response=0;
            end
            4:begin // READ_PENDING公开借用还未提出，旧RAM返回DISCARD。
                prefix=PAIRS<172 ? PAIRS : 172;send_prefix(prefix);
                while(!dut.read_pending)@(negedge clk);
                cancel_valid=1;cancel_id=active_id;@(posedge clk);@(negedge clk);cancel_valid=0;
                if(dut.read_discarded_count==0)$fatal(1,"Source pending RE not discarded");discard_cases++;
            end
            5:begin // 未完整组拍，不允许提出缺字节的RPC。
                send_prefix(PAIRS<172 ? PAIRS : 172);
                while(!dut.read_active)@(negedge clk);
                cancel_matching();
            end
            default:$fatal(1,"Unknown cancel scenario");
        endcase
        take_done(2,128);cancel_cases++;protocol_cases++;
    endtask
`endif
    initial begin
        integer listing,frame_count,ignored,file_output,protocol_file,start_cycles;
        string stem;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        listing=$fopen("frame-list.txt","r");if(!listing)$fatal(1,"Missing source frame list");
        ignored=$fscanf(listing,"%d\n",frame_count);file_results=$fopen("actual-results.txt","w");
        for(integer frame=0;frame<frame_count;frame++)begin
            ignored=$fscanf(listing,"%s\n",stem);
            $readmemh({stem,".input.hex"},input_values);$readmemh({stem,".lines.hex"},expected_lines);
            reset_joint();if(frame==1)job_base=32'((33'h100000000)-33'(A));
            configure();random_stalls=frame%2==0;maximum_latency=frame==3 ? 20 : 3;
            start_cycles=cycles;
            // wrong-ID cancel不影响有效帧。
            cancel_valid=1;cancel_id=active_id^64'd1;send_all_fast();cancel_valid=0;
            while(!done_valid)@(negedge clk);
            if(accepted_pairs!=PAIRS || logical_bytes!=L || physical_bytes!=A || written_lines!=LINES)$fatal(1,"Source normal frame count");
            $fwrite(file_results,"%s %0d %0d %0d %0d %0d %0d %0d\n",stem,accepted_pairs,logical_bytes,physical_bytes,written_lines,outcome,reason,cycles-start_cycles);
            file_output=$fopen({stem,".actual.rgb"},"wb");for(integer b=0;b<A;b++)$fwrite(file_output,"%c",memory_bytes[b]);$fclose(file_output);
            cancel_matching();take_done(0,0);normal_frames++;
        end
        $fclose(listing);$fclose(file_results);
`ifndef POSTMAP
        if(RUN_PROTOCOL)begin
            // 使用最后一幅独立参考，故障帧的完整已提出前缀仍须字节一致。
            reset_joint();job_base++;configure(1);if(!job_ready)$fatal(1,"Rejected grant retained context");protocol_cases++;
            if(A>64)begin reset_joint();job_base=32'hffffffc0;configure(1);if(!job_ready)$fatal(1,"Range-overflow grant retained context");protocol_cases++;end
            for(integer bad=1;bad<=4;bad++)begin
                reset_joint();configure();send_item(0,bad);take_done(1,bad);
                if(accepted_pairs!=1 || logical_bytes!=0 || physical_bytes!=0 || request_count!=0)$fatal(1,"Source bad tuple wrote bytes");errors++;protocol_cases++;
            end
            for(integer kind=0;kind<6;kind++)run_cancel_case(kind);
            // cancel与真实错误同沿：ERROR优先且仍须drain。
            reset_joint();configure();hold_response=1;next_error=1;
            send_prefix(PAIRS<180 ? PAIRS : 180);while(!pending)@(negedge clk);
            while(delay_count>0)@(negedge clk);
            hold_response=0;cancel_valid=1;cancel_id=active_id;
            @(posedge clk);@(negedge clk);cancel_valid=0;take_done(1,16);errors++;protocol_cases++;
            // 未知drain禁止公开安全done与job-ready，外部安全共同复位才可恢复。
            reset_joint();configure();next_drained=0;hold_response=1;
            send_prefix(PAIRS<180 ? PAIRS : 180);hold_response=0;while(!quarantined)@(negedge clk);
            repeat(20)@(negedge clk);
            if(done_valid || job_ready || in_ready || line_req_valid)$fatal(1,"Source unknown drain released owner");protocol_cases++;
            reset_joint();configure();send_all_fast();take_done(0,0);protocol_cases++;
            // 两bank满时不能提前回收；释放旧回执后继续帧并精确比对。
            if(L>2048)begin
                reset_joint();configure();hold_request=1;
                send_prefix(342);@(negedge clk);prepare_input(342);in_valid=1;
                repeat(25)@(negedge clk);
                if(in_ready || dut.bank_state[0]==0 || dut.bank_state[1]==0)$fatal(1,"Source full banks overwritten or early retired");
                hold_request=0;do @(posedge clk);while(!in_ready);@(negedge clk);in_valid=0;
                for(integer n=343;n<PAIRS;n++)send_item(n);take_done(0,0);protocol_cases++;
            end
            // 配置回执消费同沿cancel不能误入RUN。
            reset_joint();@(negedge clk);job_valid=1;do @(posedge clk);while(!job_ready);
            @(negedge clk);job_valid=0;job_rsp_ready=1;cancel_valid=1;cancel_id=active_id;
            @(posedge clk);@(negedge clk);job_rsp_ready=0;cancel_valid=0;take_done(2,128);protocol_cases++;cancel_cases++;
        end
`endif
        protocol_file=$fopen("protocol-metrics.json","w");
        $fwrite(protocol_file,"{\"finished\":true,\"normal_frames\":%0d,\"cases\":%0d,\"cancel_cases\":%0d,\"input_memory_errors\":%0d,\"pending_discard_cases\":%0d,\"two_packet_cycles\":%0d,\"both_bank_cycles\":%0d,\"backpressure_cycles\":%0d,\"re_events\":%0d,\"cycles\":%0d}\n",normal_frames,protocol_cases,cancel_cases,errors,discard_cases,two_packet_cycles,both_bank_cycles,backpressure_cycles,re_events,cycles);
        $fclose(protocol_file);finished=1;$display("RGB source writer PASS frames=%0d cases=%0d cycles=%0d",normal_frames,protocol_cases,cycles);$finish;
    end
endmodule
