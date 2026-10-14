`timescale 1ns/1ps
module tb_work_queue;
    parameter integer WIDTH=1920,HEIGHT=1080;
    localparam integer N=WIDTH*HEIGHT,ALLOC_WORDS=((N+15)/16)*16;
    logic clk=0,rst=1,finished=0;
    always #5 clk=~clk;
    logic cfg_valid=0,cfg_ready,cfg_rsp_valid,cfg_rsp_ready=0,cfg_rsp_error;
    logic [31:0] cfg_base=32'h100000;
    logic [63:0] cfg_job_id=64'h7123456789abcdef;
    logic claim_valid=0,claim_ready;logic [20:0] claim_index=0;
    logic queue_req_valid=0,queue_req_ready,queue_push=0;logic [20:0] queue_index=0;
    logic queue_rsp_valid,queue_rsp_ready=0;logic [20:0] queue_rsp_index;logic queue_rsp_error,queue_rsp_aborted;
    logic seal_valid=0,seal_ready,seal_end_job=0;logic [63:0] seal_job_id=64'h7123456789abcdef;
    logic seal_rsp_valid,seal_rsp_ready=0,seal_rsp_error,seal_rsp_drained;
    logic [21:0] seal_rsp_head,seal_rsp_tail,seal_rsp_committed;
    logic abort_private_valid=0;logic [63:0] abort_job_id=64'h7123456789abcdef;
    logic line_req_valid,line_req_ready=0,line_write;logic [31:0] line_addr;logic [511:0] line_wdata;
    logic line_rsp_valid=0,line_rsp_ready;logic [511:0] line_rdata=0;logic line_error=0,line_drained=1;
    logic quarantined;logic [63:0] active_job_id;
    canny_work_queue #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) dut(.*);
    logic [31:0] memory[0:ALLOC_WORDS-1];
    logic [31:0] claimed[0:N-1];
    integer claims=0,pops=0,forward_count=0,prefetch_count=0,prefix_seals=0;
    integer abort_scenarios=0,cycles=0,seed=32'h17234;
    logic safe_error=0,unknown_quarantine=0;
    logic pending=0,mem_write,saved_error,saved_drained;
    logic hold_request=0,hold_response=0,next_error=0,next_drained=1;
    integer mem_word,delay_count;
    logic [511:0] mem_data,mem_read;
    logic req_held=0,rsp_held=0,seal_held=0;
    logic [544:0] held_request;logic [22:0] held_response;logic [67:0] held_seal;
    function automatic integer random_bounded(input integer limit);
        seed=seed^(seed<<13);seed=seed^(seed>>17);seed=seed^(seed<<5);
        return (seed & 32'h7fffffff)%limit;
    endfunction
    always @(negedge clk)begin
        line_req_ready=!rst && !pending && !hold_request && random_bounded(4)!=0;
        line_rsp_valid=!rst && pending && delay_count==0 && !hold_response;
        line_rdata=mem_read;line_error=saved_error;line_drained=saved_drained;
    end
    // 行为外存只证明64B原子服务合同；不替代真实DDR器件动态模型。
    always @(posedge clk)begin
        cycles=cycles+1;
        if(rst)begin pending=0;req_held=0;rsp_held=0;seal_held=0;end
        else begin
            if(req_held && (!line_req_valid || {line_write,line_addr,line_wdata}!==held_request))$fatal(1,"Public line request withdrawn/changed");
            if(rsp_held && (!queue_rsp_valid || {queue_rsp_error,queue_rsp_aborted,queue_rsp_index}!==held_response))$fatal(1,"Queue held response changed");
            if(seal_held && (!seal_rsp_valid || {seal_rsp_error,seal_rsp_drained,seal_rsp_head,seal_rsp_tail,seal_rsp_committed}!==held_seal))$fatal(1,"Seal held response changed");
            req_held=line_req_valid && !line_req_ready;held_request={line_write,line_addr,line_wdata};
            rsp_held=queue_rsp_valid && !queue_rsp_ready;held_response={queue_rsp_error,queue_rsp_aborted,queue_rsp_index};
            seal_held=seal_rsp_valid && !seal_rsp_ready;held_seal={seal_rsp_error,seal_rsp_drained,seal_rsp_head,seal_rsp_tail,seal_rsp_committed};
            if(dut.head>dut.tail || dut.tail>N || dut.committed>dut.tail)$fatal(1,"Pointer invariant");
            if(dut.ap_re && dut.ap_we && dut.ap_ra==dut.ap_wa)$fatal(1,"Append RAM read/write collision");
            if(dut.pf_re && dut.pf_we && dut.pf_ra==dut.pf_wa)$fatal(1,"Prefetch RAM read/write collision");
            if(line_req_valid && line_req_ready)begin
                if(pending || line_addr[5:0]!=0 || line_addr<cfg_base || (64'(line_addr)+64>64'(cfg_base)+ALLOC_WORDS*4))$fatal(1,"Line grant range/alignment/live");
                mem_word=(line_addr-cfg_base)/4;mem_write=line_write;mem_data=line_wdata;mem_read=0;
                for(integer j=0;j<16;j++)mem_read[j*32+:32]=memory[mem_word+j];
                saved_error=next_error;saved_drained=next_drained;next_error=0;next_drained=1;
                delay_count=10+random_bounded(97);pending=1;
                if(!line_write)prefetch_count=prefetch_count+1;
            end else if(pending && delay_count>0)delay_count=delay_count-1;
            if(line_rsp_valid && line_rsp_ready)begin
                if(mem_write && !saved_error && saved_drained)for(integer j=0;j<16;j++)memory[mem_word+j]=mem_data[j*32+:32];
                pending=0;
            end
            if(queue_req_valid && queue_req_ready && !queue_push && !dut.confirm_pending && dut.head<dut.tail && dut.head>=dut.committed && !dut.stopping)forward_count=forward_count+1;
        end
        if(cycles>10000000)$fatal(1,"Global queue watchdog");
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;cfg_valid=0;claim_valid=0;queue_req_valid=0;seal_valid=0;abort_private_valid=0;
        cfg_rsp_ready=0;queue_rsp_ready=0;seal_rsp_ready=0;hold_request=0;hold_response=0;next_error=0;next_drained=1;
        repeat(4)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic configure(input logic expect_error=0);
        integer timeout;
        @(negedge clk);cfg_valid=1;
        timeout=0;do begin @(posedge clk);if(timeout++>100000)$fatal(1,"cfg timeout");end while(!cfg_ready);
        @(negedge clk);cfg_valid=0;
        timeout=0;while(!cfg_rsp_valid)begin @(negedge clk);if(timeout++>100000)$fatal(1,"cfg reply timeout");end
        if(cfg_rsp_error!==expect_error)$fatal(1,"cfg legal check");
        repeat(3)@(negedge clk);cfg_rsp_ready=1;@(posedge clk);@(negedge clk);cfg_rsp_ready=0;
    endtask
    task automatic append(input integer index_value,input logic record_value=1);
        integer timeout;
        @(negedge clk);claim_index=21'(index_value);claim_valid=1;
        timeout=0;do begin @(posedge clk);if(timeout++>300000)$fatal(1,"claim timeout tail=%0d c=%0d writer=%0d banks=%0d/%0d",dut.tail,dut.committed,dut.writer,dut.bank_state[0],dut.bank_state[1]);end while(!claim_ready);
        if(record_value)begin claimed[claims]=32'(index_value);claims++;end
        @(negedge clk);claim_valid=0;
    endtask
    task automatic queue_request(input logic push_value,input integer index_value);
        integer timeout;
        @(negedge clk);queue_push=push_value;queue_index=21'(index_value);queue_req_valid=1;
        timeout=0;do begin @(posedge clk);if(timeout++>300000)$fatal(1,"queue request timeout");end while(!queue_req_ready);
        @(negedge clk);queue_req_valid=0;
    endtask
    task automatic take_queue(output integer value,output integer error_value,output integer aborted_value);
        integer timeout;
        timeout=0;while(!queue_rsp_valid)begin @(negedge clk);if(timeout++>300000)$fatal(1,"queue reply timeout cons=%0d writer=%0d mem=%0d pf=%0d head=%0d c=%0d",dut.consumer,dut.writer,dut.memory_state,dut.prefetch,dut.head,dut.committed);end
        repeat(1+random_bounded(7))@(negedge clk);
        value=queue_rsp_index;error_value=queue_rsp_error;aborted_value=queue_rsp_aborted;
        queue_rsp_ready=1;@(posedge clk);@(negedge clk);queue_rsp_ready=0;
    endtask
    task automatic request_seal(input logic closing,input logic wrong_id=0);
        integer timeout;
        @(negedge clk);seal_end_job=closing;seal_job_id=wrong_id ? cfg_job_id^64'd1 : cfg_job_id;seal_valid=1;
        timeout=0;do begin @(posedge clk);if(timeout++>100000)$fatal(1,"seal request timeout");end while(!seal_ready);
        @(negedge clk);seal_valid=0;
    endtask
    task automatic take_seal(output integer error_value);
        integer timeout;
        timeout=0;while(!seal_rsp_valid)begin @(negedge clk);if(timeout++>300000)$fatal(1,"seal reply timeout c=%0d tail=%0d writer=%0d banks=%0d/%0d cons=%0d conf=%0d",dut.committed,dut.tail,dut.writer,dut.bank_state[0],dut.bank_state[1],dut.consumer,dut.confirm_pending);end
        if(!seal_rsp_error && !seal_rsp_drained)$fatal(1,"Successful seal without drain");
        if(seal_rsp_drained && (pending || line_req_valid || dut.ap_pending))$fatal(1,"False seal drain");
        repeat(5)@(negedge clk);error_value=seal_rsp_error;seal_rsp_ready=1;@(posedge clk);@(negedge clk);seal_rsp_ready=0;
    endtask
    task automatic abort_job(input logic wrong_id=0);
        @(negedge clk);abort_job_id=wrong_id ? cfg_job_id^64'd1 : cfg_job_id;abort_private_valid=1;
        @(posedge clk);@(negedge clk);abort_private_valid=0;
    endtask
    task automatic seed_one;
        integer value,error_value,aborted_value;
        append(7,0);queue_request(1,7);take_queue(value,error_value,aborted_value);
        if(value!=7 || error_value || aborted_value)$fatal(1,"seed confirm");
    endtask
    initial begin:main
        integer commands,output_file,memory_file,metrics_file,count,index_value,value,error_value,aborted_value;
        string operation;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        for(integer j=0;j<ALLOC_WORDS;j++)memory[j]=0;
        reset_joint();cfg_base=32'h100001;configure(1);cfg_base=32'hffffffc0;configure(1);cfg_base=32'h100000;configure();
        claim_index=21'(N);#1;if(claim_ready)$fatal(1,"Invalid entry accepted");claim_index=0;
        commands=$fopen("commands.txt","r");output_file=$fopen("actual-results.txt","w");
        if(!commands || !output_file)$fatal(1,"Missing command/output file");
        while(!$feof(commands))begin
            count=$fscanf(commands,"%s %d\n",operation,index_value);if(count!=2)$fatal(1,"Malformed command");
            case(operation)
                "C":begin append(index_value);value=index_value;error_value=0;end
                "P","O":begin
                    queue_request(operation=="P",index_value);take_queue(value,error_value,aborted_value);
                    if(aborted_value)$fatal(1,"Unexpected normal abort");if(operation=="O" && !error_value)pops++;
                end
                "S","E":begin
                    request_seal(operation=="E");take_seal(error_value);value=0;
                    if(operation=="S")begin
                        prefix_seals++;
                        if(dut.committed!=dut.tail || error_value)$fatal(1,"Seal prefix/c mismatch");
                        for(integer j=0;j<dut.tail;j++)if(memory[j]!==claimed[j])$fatal(1,"Prefix lost at word %0d after seal %0d",j,prefix_seals);
                    end
                end
                default:$fatal(1,"Unknown command");
            endcase
            $fwrite(output_file,"%s %0d %0d %0d %0d\n",operation,value,error_value,dut.head,dut.tail);
        end
        $fclose(commands);$fclose(output_file);
        memory_file=$fopen("final-memory.bin","wb");if(!memory_file)$fatal(1,"Memory output");
        for(integer j=0;j<ALLOC_WORDS;j++)$fwrite(memory_file,"%c%c%c%c",memory[j][7:0],memory[j][15:8],memory[j][23:16],memory[j][31:24]);
        $fclose(memory_file);

        // T03：两bank同时占满，已公开writer请求反压；第513条不可覆盖旧bank。
        reset_joint();configure();hold_request=1;
        for(integer j=0;j<512;j++)begin
            append(j%N,0);queue_request(1,j%N);take_queue(value,error_value,aborted_value);
            if(error_value || aborted_value)$fatal(1,"Two-bank fill confirm");
        end
        repeat(12)@(negedge clk);
        if(claim_ready || dut.tail!=512 || !line_req_valid)$fatal(1,"Full banks did not apply backpressure");
        hold_request=0;append(512%N,0);queue_request(1,512%N);take_queue(value,error_value,aborted_value);
        for(integer j=0;j<513;j++)begin
            queue_request(0,0);take_queue(value,error_value,aborted_value);
            if(error_value || aborted_value || value!=j%N)$fatal(1,"Two-bank FIFO lost at %0d",j);
        end
        request_seal(1);take_seal(error_value);if(error_value)$fatal(1,"Two-bank close");

        // T04：真实读错误和非法外存entry必须作失败，不能发布为像素索引。
        for(integer kind=0;kind<2;kind++)begin
            reset_joint();configure();seed_one();request_seal(0);take_seal(error_value);
            if(kind==0)next_error=1;else memory[0]=32'h80000007;
            queue_request(0,0);take_queue(value,error_value,aborted_value);
            if(!error_value || aborted_value || !dut.faulted || dut.head!=0)$fatal(1,"Bad prefetch entry/read error accepted");
            request_seal(1);take_seal(error_value);
        end

        // T06-1：错误ID不取消；held正常确认在后来abort下不可改写。
        reset_joint();configure();abort_job(1);seed_one();append(9,0);queue_request(1,9);
        while(!queue_rsp_valid)@(negedge clk);abort_job();
        take_queue(value,error_value,aborted_value);if(value!=9 || error_value || aborted_value)$fatal(1,"Held confirmation mutated");
        request_seal(1);take_seal(error_value);if(!error_value)$fatal(1,"Cancelled end incorrectly succeeds");abort_scenarios++;

        // T06-2：旧claim与共同cancel同沿仍实际配对追加；随后私有confirm作废。
        reset_joint();configure();while(!claim_ready)@(negedge clk);
        claim_index=3;claim_valid=1;abort_private_valid=1;abort_job_id=cfg_job_id;
        @(posedge clk);@(negedge clk);claim_valid=0;abort_private_valid=0;
        if(dut.tail!=1)$fatal(1,"Same-edge old claim was split");
        request_seal(1);take_seal(error_value);abort_scenarios++;

        // T06-3/4：已经公开的写请求及等待回复不能被撤销。
        for(integer phase=0;phase<2;phase++)begin
            reset_joint();configure();seed_one();hold_request=phase==0;hold_response=phase==1;request_seal(0);
            if(phase==0)begin while(!line_req_valid)@(negedge clk);end
            else begin while(!pending)@(negedge clk);end
            abort_job();repeat(12)@(negedge clk);
            if(phase==0 && !line_req_valid)$fatal(1,"Cancelled RPC vanished");
            hold_request=0;hold_response=0;take_seal(error_value);if(!error_value)$fatal(1,"Cancel seal result");
            request_seal(1);take_seal(error_value);abort_scenarios++;
        end

        // T06-5：forward已有RE预约，下一沿仍归还但不能作成功pop。
        reset_joint();configure();seed_one();queue_request(0,0);
        while(!dut.ap_pending)@(negedge clk);abort_private_valid=1;abort_job_id=cfg_job_id;
        @(posedge clk);@(negedge clk);abort_private_valid=0;
        take_queue(value,error_value,aborted_value);if(!error_value || !aborted_value || dut.head!=0)$fatal(1,"Forward cancel/capture");
        request_seal(1);take_seal(error_value);abort_scenarios++;

        // T06-6：已提交前缀的prefetch安装中取消，禁止半填数据发布。
        reset_joint();configure();seed_one();request_seal(0);take_seal(error_value);queue_request(0,0);
        while(dut.prefetch!=3)@(negedge clk);abort_job();take_queue(value,error_value,aborted_value);
        if(!error_value || !aborted_value || dut.prefetch_valid)$fatal(1,"Partial prefetch published");
        request_seal(1);take_seal(error_value);abort_scenarios++;

        // 安全外存错误优先于cancel；没有错误drain伪证。
        reset_joint();configure();seed_one();next_error=1;request_seal(0);take_seal(error_value);
        if(!error_value || !dut.faulted)$fatal(1,"Safe error not recorded");
        abort_job();queue_request(0,0);take_queue(value,error_value,aborted_value);
        if(!error_value || aborted_value)$fatal(1,"Real memory error disguised as cancel");
        request_seal(1);take_seal(error_value);safe_error=1;

        reset_joint();configure();seed_one();next_drained=0;request_seal(0);
        while(!quarantined)@(negedge clk);repeat(25)@(negedge clk);
        if(cfg_ready || seal_rsp_valid || queue_req_ready || line_req_valid)$fatal(1,"Unknown drain released old context");unknown_quarantine=1;
        reset_joint();configure();request_seal(1,1);take_seal(error_value);
        if(!error_value || !dut.configured)$fatal(1,"Wrong-ID end affected current job");
        request_seal(1);take_seal(error_value);if(error_value)$fatal(1,"Empty normal end");
        metrics_file=$fopen("tb-metrics.json","w");
        $fwrite(metrics_file,"{\"finished\":true,\"claims\":%0d,\"pops\":%0d,\"forward\":%0d,\"prefetch\":%0d,\"prefix_seals\":%0d,\"abort_scenarios\":%0d,\"safe_error\":true,\"unknown_quarantine\":true,\"cycles\":%0d}\n",claims,pops,forward_count,prefetch_count,prefix_seals,abort_scenarios,cycles);
        $fclose(metrics_file);finished=1;
        $display("Work queue PASS claims=%0d pops=%0d forward=%0d read-lines=%0d cancel=%0d cycles=%0d",claims,pops,forward_count,prefetch_count,abort_scenarios,cycles);$finish;
    end
endmodule
