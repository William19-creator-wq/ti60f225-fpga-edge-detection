`timescale 1ns/1ps
module tb_memory_join;
    parameter integer WIDTH=32,HEIGHT=24,RUN_PROTOCOL=1;
    localparam integer N=WIDTH*HEIGHT,STATE_WORDS=((N+255)/256)*16,QUEUE_WORDS=((N+15)/16)*16;
    localparam integer QUEUE_FIRST=STATE_WORDS+16,MEM_WORDS=QUEUE_FIRST+QUEUE_WORDS;
    logic clk=0,rst=1,finished=0;always #5 clk=~clk;
    logic job_valid=0,job_ready;logic [63:0] job_id=64'hafed012345670000;
    logic [31:0] state_base=32'h100000,queue_base=32'h100000+QUEUE_FIRST*4;
    logic cancel_valid=0;logic [63:0] cancel_id=0;
    logic pixel_valid,pixel_ready=1;logic [20:0] pixel_index;logic pixel_edge;logic [63:0] pixel_job_id;
    logic done_valid,done_ready=0;logic [63:0] done_job_id;logic [1:0] outcome;logic [7:0] reason;
    logic [21:0] enqueue_count,pop_count,output_count;
    logic line_req_valid,line_req_ready=0,line_write;logic [31:0] line_addr;logic [511:0] line_wdata;
    logic line_rsp_valid=0,line_rsp_ready;logic [511:0] line_rdata=0;logic line_error=0,line_drained=1,quarantined;
    canny_memory_top #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) dut(.*);
    logic [31:0] memory[0:MEM_WORDS-1];
    logic [1:0] classes[0:N-1];
    logic pending=0,saved_write,saved_error=0,saved_drained=1,hold_request=0,hold_response=0,next_error=0,next_drained=1;
    logic [511:0] saved_data,saved_read;
    integer saved_word,delay_count,cycles=0,seed=32'h73810;
    integer pixel_file=0,actual_pixels=0,actual_edges=0,atomic_pairs=0,cancel_cases=0;
    integer reads=0,writes=0,queue_reads=0,queue_writes=0,accepted_requests=0;
    logic record_normal=0,force_pixel_stall=0;
    logic req_held=0,pixel_held=0,done_held=0;
    logic [544:0] held_req;logic [85:0] held_pixel;logic [139:0] held_done;
    function automatic integer random_bounded(input integer limit);
        seed=seed^(seed<<13);seed=seed^(seed>>17);seed=seed^(seed<<5);return (seed & 32'h7fffffff)%limit;
    endfunction
    always @(negedge clk)begin
        line_req_ready=!rst && !pending && !hold_request && random_bounded(4)!=0;
        line_rsp_valid=!rst && pending && delay_count==0 && !hold_response;
        line_rdata=saved_read;line_error=saved_error;line_drained=saved_drained;
        pixel_ready=!force_pixel_stall && random_bounded(5)!=0;
    end
    always @(posedge clk)begin
        cycles++;
        if(rst)begin pending=0;req_held=0;pixel_held=0;done_held=0;end
        else begin
            if(req_held && (!line_req_valid || held_req!=={line_write,line_addr,line_wdata}))$fatal(1,"Global held RPC changed");
            if(pixel_held && (!pixel_valid || held_pixel!=={pixel_job_id,pixel_index,pixel_edge}))$fatal(1,"Held pixel withdrawn/changed");
            if(done_held && (!done_valid || held_done!=={done_job_id,outcome,reason,enqueue_count,pop_count,output_count}))$fatal(1,"Held done changed");
            req_held=line_req_valid && !line_req_ready;held_req={line_write,line_addr,line_wdata};
            pixel_held=pixel_valid && !pixel_ready;held_pixel={pixel_job_id,pixel_index,pixel_edge};
            done_held=done_valid && !done_ready;held_done={done_job_id,outcome,reason,enqueue_count,pop_count,output_count};
            if((dut.rpc_req_valid & dut.rpc_req_ready)==2'b11)$fatal(1,"Two simultaneous RPC owners");
            if(dut.claim_valid && dut.claim_ready)begin
                if(!dut.work_queue.ap_we || !dut.class_cache.ram_we[dut.class_cache.selected_way][dut.class_cache.selected_set[4]])$fatal(1,"Atomic claim/RAM pair split");
                if(record_normal)atomic_pairs++;
            end
            if(line_req_valid && line_req_ready)begin
                if(pending || line_addr[5:0]!=0)$fatal(1,"Global live/alignment");
                if(line_addr>=state_base && 64'(line_addr)+64<=64'(state_base)+STATE_WORDS*4)saved_word=(line_addr-state_base)/4;
                else if(line_addr>=queue_base && 64'(line_addr)+64<=64'(queue_base)+QUEUE_WORDS*4)saved_word=QUEUE_FIRST+(line_addr-queue_base)/4;
                else $fatal(1,"Request escaped authorized ranges %h",line_addr);
                saved_write=line_write;saved_data=line_wdata;saved_read=0;
                for(integer j=0;j<16;j++)saved_read[j*32+:32]=memory[saved_word+j];
                saved_error=next_error;saved_drained=next_drained;next_error=0;next_drained=1;
                delay_count=1+random_bounded(20);pending=1;accepted_requests++;
                if(line_write)writes++;else reads++;
                if(dut.line_arbiter.owner)begin if(line_write)queue_writes++;else queue_reads++;end
            end else if(pending && delay_count>0)delay_count--;
            if(line_rsp_valid && line_rsp_ready)begin
                if(saved_write && !saved_error && saved_drained)for(integer j=0;j<16;j++)memory[saved_word+j]=saved_data[j*32+:32];
                pending=0;
            end
            if(pixel_valid && pixel_ready)begin
                if(pixel_job_id!=job_id || pixel_index!=actual_pixels || pixel_index>=N)$fatal(1,"Pixel identity/order %0d vs %0d",pixel_index,actual_pixels);
                actual_pixels++;actual_edges+=pixel_edge;
                if(record_normal)$fwrite(pixel_file,"%c",8'(pixel_edge));
            end
        end
        if(cycles>1500000000)$fatal(1,"Join global watchdog");
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;job_valid=0;cancel_valid=0;done_ready=0;hold_request=0;hold_response=0;
        force_pixel_stall=0;next_error=0;next_drained=1;record_normal=0;
        repeat(4)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic empty_memory;
        if(pending || line_req_valid || dut.control!=0)$fatal(1,"Replacing memory with live ownership");
        for(integer j=0;j<MEM_WORDS;j++)memory[j]=0;
        actual_pixels=0;actual_edges=0;
    endtask
    task automatic load_pattern(input integer kind);
        empty_memory();
        for(integer j=0;j<N;j++)begin
            classes[j]=kind==1 ? 2 : (kind==2 ? (j==0 ? 2 : 1) : (j==0 ? 2 : 0));
            memory[j/16][(j%16)*2+:2]=classes[j];
        end
    endtask
    task automatic start_job;
        integer timeout;
        @(negedge clk);job_id++;job_valid=1;
        timeout=0;do begin @(posedge clk);if(timeout++>100000)$fatal(1,"job accept timeout");end while(!job_ready);
        @(negedge clk);job_valid=0;
    endtask
    task automatic take_done(input integer expected_outcome);
        integer timeout;
        timeout=0;while(!done_valid)begin
            @(negedge clk);
            if(timeout++>600000000)$fatal(1,"Join completion timeout control=%0d HY=%0d cache=%0d queue=%0d",dut.control,dut.hysteresis.state,dut.class_cache.state,dut.work_queue.consumer);
            if(quarantined)$fatal(1,"Unexpected quarantine");
        end
        if(outcome!=expected_outcome || done_job_id!=job_id)$fatal(1,"Outcome %0d/%0d expected %0d",outcome,reason,expected_outcome);
        if(pending || line_req_valid || dut.class_cache.configured || dut.work_queue.configured)$fatal(1,"done before both clients drained/closed");
        repeat(15)@(negedge clk);done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;
    endtask
    task automatic pulse_cancel(input logic wrong_id=0);
        @(negedge clk);cancel_id=wrong_id ? job_id^64'd1 : job_id;cancel_valid=1;
        @(posedge clk);@(negedge clk);cancel_valid=0;
    endtask
    task automatic wait_cancel_point(input integer scenario);
        integer timeout;logic found;
        timeout=0;found=0;
        while(!found)begin
            @(negedge clk);
            case(scenario)
                0:found=dut.control==2;
                1:found=dut.control==4;
                2:found=dut.control==5;
                3:found=dut.claim_valid && dut.claim_ready;
                4:found=dut.h_queue_req_valid;
                5:found=dut.work_queue.ap_pending && !dut.work_queue.ap_owner;
                6:found=dut.work_queue.prefetch==3;
                7:found=pixel_valid;
                8:begin if(dut.control==7)hold_response=1;found=dut.control==8 && pending && saved_write;end
                9:begin if(dut.control==9)hold_response=1;found=dut.control==10 && pending && saved_write;end
                10:found=line_req_valid;
                default:$fatal(1,"Bad cancel scenario");
            endcase
            if(timeout++>2000000 || done_valid)$fatal(1,"Cancel point %0d unavailable",scenario);
        end
        // 当前negedge就在预约fire之前；不再多等一拍错失目标窗口。
        cancel_valid=1;cancel_id=job_id;
        @(posedge clk);@(negedge clk);cancel_valid=0;
        if(scenario==10)begin repeat(12)@(negedge clk);if(!line_req_valid)$fatal(1,"Public request cancelled");end
        hold_request=0;hold_response=0;force_pixel_stall=0;
    endtask
    initial begin:main
        integer cases_file,result_file,class_file,state_file,queue_file,metrics_file,expected_edges,case_id=0,start_cycles,scanned,value;
        string filename;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        reset_joint();empty_memory();
        cases_file=$fopen("cases.txt","r");result_file=$fopen("actual-results.txt","w");
        if(!cases_file || !result_file)$fatal(1,"Missing cases/output");
        while(!$feof(cases_file))begin
            scanned=$fscanf(cases_file,"%d\n",expected_edges);if(scanned!=1)$fatal(1,"Malformed case metadata");
            empty_memory();filename=$sformatf("case-%0d.class",case_id);class_file=$fopen(filename,"r");
            if(!class_file)$fatal(1,"Class input missing");
            for(integer j=0;j<N;j++)begin
                scanned=$fscanf(class_file,"%d\n",value);if(scanned!=1 || value<0 || value>2)$fatal(1,"Class input malformed");
                classes[j]=2'(value);memory[j/16][(j%16)*2+:2]=classes[j];
            end
            $fclose(class_file);filename=$sformatf("actual-%0d.edge",case_id);pixel_file=$fopen(filename,"wb");
            if(!pixel_file)$fatal(1,"Pixel output missing");record_normal=1;start_cycles=cycles;start_job();
            if(case_id==0)pulse_cancel(1); // 错误ID不能影响正常运行。
            take_done(0);record_normal=0;$fclose(pixel_file);
            if(reason || actual_pixels!=N || actual_edges!=expected_edges || enqueue_count!=expected_edges || pop_count!=expected_edges || output_count!=N)$fatal(1,"Normal counters mismatch case %0d",case_id);
            $fwrite(result_file,"%0d %0d %0d %0d %0d %0d %0d %0d\n",case_id,outcome,reason,enqueue_count,pop_count,output_count,actual_edges,cycles-start_cycles);
            filename=$sformatf("actual-%0d.state.bin",case_id);state_file=$fopen(filename,"wb");
            for(integer j=0;j<STATE_WORDS;j++)$fwrite(state_file,"%c%c%c%c",memory[j][7:0],memory[j][15:8],memory[j][23:16],memory[j][31:24]);$fclose(state_file);
            filename=$sformatf("actual-%0d.queue.bin",case_id);queue_file=$fopen(filename,"wb");
            for(integer j=0;j<enqueue_count;j++)$fwrite(queue_file,"%c%c%c%c",memory[QUEUE_FIRST+j][7:0],memory[QUEUE_FIRST+j][15:8],memory[QUEUE_FIRST+j][23:16],memory[QUEUE_FIRST+j][31:24]);$fclose(queue_file);
            case_id++;
        end
        $fclose(cases_file);$fclose(result_file);

        if(RUN_PROTOCOL)begin
        // 不合法授权区必须在配置前拒绝，不能产生任何RPC。
        for(integer kind=0;kind<3;kind++)begin
            empty_memory();value=accepted_requests;
            if(kind==0)state_base=32'h100001;
            else if(kind==1)queue_base=state_base;
            else state_base=32'hffffffc0;
            start_job();
            while(!done_valid)@(negedge clk);
            if(outcome!=1 || reason!=8'h10 || accepted_requests!=value)$fatal(1,"Invalid grant accessed memory");
            repeat(10)@(negedge clk);done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;
            state_base=32'h100000;queue_base=32'h100000+QUEUE_FIRST*4;
        end
        for(integer scenario=0;scenario<11;scenario++)begin
            reset_joint();load_pattern(scenario==5 || scenario==9 || scenario==10 ? 3 : 1);
            force_pixel_stall=scenario==7;hold_request=scenario==10;
            start_job();wait_cancel_point(scenario);take_done(2);cancel_cases++;
        end
        // 真错误与取消同时存在时优先ERROR。
        reset_joint();load_pattern(3);next_error=1;hold_response=1;start_job();
        while(!pending)@(negedge clk);pulse_cancel();hold_response=0;take_done(1);
        // drained未知：不返回成功/不允许下一任务；只在安全joint reset后恢复。
        reset_joint();load_pattern(3);next_drained=0;start_job();
        while(!quarantined)@(negedge clk);repeat(30)@(negedge clk);
        if(done_valid || job_ready || line_req_valid)$fatal(1,"Quarantine released old ownership");
        reset_joint();load_pattern(3);start_job();take_done(0);
        end
        metrics_file=$fopen("protocol-metrics.json","w");
        $fwrite(metrics_file,"{\"finished\":true,\"atomic_pairs\":%0d,\"cancel_cases\":%0d,\"safe_error\":%s,\"unknown_quarantine\":%s,\"reads\":%0d,\"writes\":%0d,\"queue_reads\":%0d,\"queue_writes\":%0d,\"cycles\":%0d}\n",atomic_pairs,cancel_cases,RUN_PROTOCOL ? "true" : "false",RUN_PROTOCOL ? "true" : "false",reads,writes,queue_reads,queue_writes,cycles);$fclose(metrics_file);
        finished=1;$display("Actual cache/queue/HY JOIN PASS normal_cases=%0d atomic_pairs=%0d cancels=%0d cycles=%0d",case_id,atomic_pairs,cancel_cases,cycles);$finish;
    end
endmodule
