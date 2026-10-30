`timescale 1ns/1ps
module tb_full_canny;
    parameter integer WIDTH=34,HEIGHT=19,RUN_PROTOCOL=1;
    localparam integer N=WIDTH*HEIGHT,P=N/2,CWORDS=((N+255)/256)*16,QWORDS=((N+15)/16)*16,RWORDS=((N+63)/64)*16;
    localparam integer QFIRST=CWORDS+16,RFIRST=QFIRST+QWORDS+16,MWORDS=RFIRST+RWORDS;
    logic clk=0,rst=1,finished=0;always #5 clk=~clk;
    logic cj_valid=0,cj_ready;logic [141:0] cj=0;
    logic [31:0] class_base=32'h100000,queue_base=32'h100000+QFIRST*4,result_base=32'h100000+RFIRST*4;
    logic in_valid=0,in_ready;logic [73:0] in_fp=0;
    logic grad_valid,grad_ready=0;logic [184:0] grad_payload;
    logic cancel_valid=0;logic [95:0] cancel_scope=0;logic source_stop;
    logic done_valid,done_ready=0;logic [95:0] done_scope;logic [1:0] outcome;logic [31:0] reason;
    logic [20:0] input_pairs,class_pairs;logic [21:0] output_pixels,edge_pixels,discarded_pixels;
    logic [591:0] r2_status_snapshot;
    logic line_req_valid,line_req_ready=0,line_write;logic [31:0] line_addr;logic [511:0] line_wdata;
    logic line_rsp_valid=0,line_rsp_ready;logic [511:0] line_rdata=0;logic line_error=0,line_drained=1,quarantined;
    canny_full_top #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) dut(.*);
    logic [31:0] memory[0:MWORDS-1];logic [73:0] fp_values[0:P-1];logic [184:0] grad_values[0:P-1];
    logic pending=0,saved_write,saved_error=0,saved_drained=1,hold_request=0,hold_result_response=0;
    logic [511:0] saved_data,saved_read;integer saved_word,saved_region,delay_count,cycles=0,seed=32'h1801431;
    integer inject_error_region=-1,inject_unknown_region=-1,actual_inputs=0,actual_grads=0,requests=0;
    integer gradient_file=0,case_id=0,cancels=0,safe_errors=0;logic record_normal=0,snapshot_saved=0;
    logic error_waiting_pixel=0,error_held_pixel_seen=0;
    logic request_held=0,done_held=0,grad_held=0;logic [544:0] held_request;logic [255:0] held_done;logic [184:0] held_grad;
    function automatic integer random_bounded(input integer limit);
        seed=seed^(seed<<13);seed=seed^(seed>>17);seed=seed^(seed<<5);return (seed & 32'h7fffffff)%limit;
    endfunction
    task automatic dump_words(input string path,input integer first_word,input integer words);
        integer handle;
        handle=$fopen(path,"wb");if(!handle)$fatal(1,"Cannot create memory artifact %s",path);
        for(integer j=0;j<words;j++)$fwrite(handle,"%c%c%c%c",memory[first_word+j][7:0],memory[first_word+j][15:8],memory[first_word+j][23:16],memory[first_word+j][31:24]);
        $fclose(handle);
    endtask
    always @(negedge clk)begin
        line_req_ready=!rst && !pending && !hold_request && random_bounded(5)!=0;
        line_rsp_valid=!rst && pending && delay_count==0 && !(hold_result_response && saved_region==2) && !error_waiting_pixel;
        line_rdata=saved_read;line_error=saved_error;line_drained=saved_drained;
        grad_ready=!rst && random_bounded(4)!=0;
    end
    always @(posedge clk)begin
        cycles++;
        if(rst)begin pending=0;request_held=0;done_held=0;grad_held=0;error_waiting_pixel=0;error_held_pixel_seen=0;end
        else begin
            // Require the held-pixel corner explicitly. Pipeline latency changes
            // must not accidentally remove this regression through RNG phase.
            if(error_waiting_pixel&&dut.h_pixel_valid&&!dut.h_pixel_ready)begin error_waiting_pixel=0;error_held_pixel_seen=1;end
            if(request_held && (!line_req_valid || held_request!=={line_write,line_addr,line_wdata}))$fatal(1,"Public full-Canny RPC changed");
            if(done_held && (!done_valid || held_done!=={done_scope,outcome,reason,input_pairs,class_pairs,output_pixels,edge_pixels,discarded_pixels}))$fatal(1,"Held full-Canny done changed");
            if(grad_held && !dut.private_abort && (!grad_valid || held_grad!==grad_payload))$fatal(1,"Held gradient changed");
            request_held=line_req_valid && !line_req_ready;held_request={line_write,line_addr,line_wdata};
            done_held=done_valid && !done_ready;held_done={done_scope,outcome,reason,input_pairs,class_pairs,output_pixels,edge_pixels,discarded_pixels};
            grad_held=grad_valid && !grad_ready;held_grad=grad_payload;
            if(in_valid && in_ready)actual_inputs++;
            if(grad_valid && grad_ready)begin
                if(record_normal)begin
                    if(!cj[141] || actual_grads>=P || grad_payload!==grad_values[actual_grads])$fatal(1,"Gradient mismatch %0d",actual_grads);
                    $fwrite(gradient_file,"%h\n",grad_payload);
                end
                actual_grads++;
            end
            if(record_normal && !snapshot_saved && dut.state==5 && dut.active_cj==cj)begin
                dump_words($sformatf("actual-%0d.class.bin",case_id),0,CWORDS);snapshot_saved=1;
                if(pending || line_req_valid)$fatal(1,"HY phase switched with old writer RPC live");
            end
            if(line_req_valid && line_req_ready)begin
                if(pending || line_addr[5:0]!=0)$fatal(1,"Line live/alignment");
                if(line_addr>=class_base && 64'(line_addr)+64<=64'(class_base)+CWORDS*4)begin saved_word=(line_addr-class_base)/4;saved_region=0;end
                else if(line_addr>=queue_base && 64'(line_addr)+64<=64'(queue_base)+QWORDS*4)begin saved_word=QFIRST+(line_addr-queue_base)/4;saved_region=1;end
                else if(line_addr>=result_base && 64'(line_addr)+64<=64'(result_base)+RWORDS*4)begin saved_word=RFIRST+(line_addr-result_base)/4;saved_region=2;end
                else $fatal(1,"Memory outside grant %h",line_addr);
                saved_write=line_write;saved_data=line_wdata;saved_read=0;
                for(integer j=0;j<16;j++)saved_read[j*32+:32]=memory[saved_word+j];
                saved_error=(inject_error_region==0 && saved_region==0 && line_write) ||
                    (inject_error_region==1 && saved_region==0 && !line_write) || (inject_error_region==2 && saved_region==2 && line_write);
                if(saved_error)begin inject_error_region=-1;if(saved_region==2)error_waiting_pixel=1;end
                saved_drained=inject_unknown_region!=saved_region;if(!saved_drained)inject_unknown_region=-1;
                pending=1;delay_count=1+random_bounded(31);requests++;
            end else if(pending && delay_count>0)delay_count--;
            if(line_rsp_valid && line_rsp_ready)begin
                if(saved_write && !saved_error && saved_drained)for(integer j=0;j<16;j++)memory[saved_word+j]=saved_data[j*32+:32];
                pending=0;
            end
        end
        if(cycles>1000000000)$fatal(1,"Full-Canny watchdog");
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;cj_valid=0;in_valid=0;cancel_valid=0;done_ready=0;hold_request=0;hold_result_response=0;
        inject_error_region=-1;inject_unknown_region=-1;record_normal=0;
        repeat(4)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic prepare_memory;
        if(pending || line_req_valid || dut.state!=0)$fatal(1,"Memory replaced with live scope");
        for(integer j=0;j<MWORDS;j++)memory[j]=0;
        actual_inputs=0;actual_grads=0;snapshot_saved=0;
    endtask
    task automatic load_case(input integer ident);
        integer handle,scanned,expected_edges,retain,ordinal=0;logic [141:0] proposed;string filename;
        prepare_memory();handle=$fopen("cases.txt","r");if(!handle)$fatal(1,"Case config missing");
        do begin scanned=$fscanf(handle,"%h %d %d\n",proposed,expected_edges,retain);if(scanned!=3)$fatal(1,"Case config malformed");end while(ordinal++<ident);
        $fclose(handle);cj=proposed;filename=$sformatf("case-%0d.fp",ident);
        handle=$fopen(filename,"r");if(!handle)$fatal(1,"FP input missing");$fclose(handle);$readmemh(filename,fp_values);
        if(retain)begin filename=$sformatf("case-%0d.grad",ident);$readmemh(filename,grad_values);end
    endtask
    task automatic start_job;
        integer timeout;
        @(negedge clk);cj_valid=1;timeout=0;
        do begin @(posedge clk);if(timeout++>100000)$fatal(1,"CJ accept timeout");end while(!cj_ready);
        @(negedge clk);cj_valid=0;
    endtask
    task automatic feed_image(input logic bad_input=0);
        integer timeout;
        for(integer pair_number=0;pair_number<P;pair_number++)begin
            repeat(random_bounded(3))@(negedge clk);
            if(source_stop)break;
            in_fp=fp_values[pair_number];if(bad_input && pair_number==P/3)in_fp[73]=1;in_valid=1;timeout=0;
            do begin @(posedge clk);if(timeout++>1000000)$fatal(1,"Input request stuck");end while(!in_ready && !source_stop);
            @(negedge clk);in_valid=0;if(source_stop)break;
        end
    endtask
    task automatic take_done(input integer expected);
        integer timeout;
        timeout=0;while(!done_valid)begin
            @(negedge clk);if(timeout++>300000000)$fatal(1,"Full-Canny done stuck state=%0d r2=%0d class=%0d HY=%0d edge=%0d seen=%0b%0b%0b%0b",dut.state,dut.stream.controller.state,dut.classification_writer.sink.state,dut.memory_algorithm.control,dut.result_writer.sink.state,dut.r2_seen,dut.class_seen,dut.hy_seen,dut.edge_seen);
            if(quarantined)$fatal(1,"Unexpected quarantine");
        end
        if(outcome!=expected || done_scope!=cj[95:0])$fatal(1,"Full-Canny outcome %0d reason=%h expected %0d",outcome,reason,expected);
        if(pending || line_req_valid || dut.rpc_valid!=0 || dut.classification_writer.sink.state!=0 || dut.result_writer.sink.state!=0 || dut.memory_algorithm.control!=0)$fatal(1,"done before all child ownership released");
        repeat(15)@(negedge clk);done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;
    endtask
    task automatic cancel_point(input integer scenario);
        logic found;integer timeout;
        found=0;timeout=0;
        while(!found)begin
            @(negedge clk);
            case(scenario)
                0:found=dut.state==2;
                1:found=dut.state==3;
                2:found=dut.state==4 && actual_inputs>=5;
                3:found=line_req_valid && line_write && line_addr==class_base;
                4:found=dut.state==6;
                5:found=dut.state==7;
                6:found=dut.memory_algorithm.claim_valid && dut.memory_algorithm.claim_ready;
                7:begin if(dut.edge_count>=63)hold_request=1;found=line_req_valid && line_write && line_addr==result_base;end
                8:found=pending && saved_region==2;
                9:found=dut.state==9;
                default:$fatal(1,"Unknown cancel point");
            endcase
            if(timeout++>1000000 || done_valid)$fatal(1,"Cancel point unavailable %0d",scenario);
        end
        cancel_scope=cj[95:0];cancel_valid=1;@(posedge clk);@(negedge clk);cancel_valid=0;
        if(scenario==3 || scenario==7)begin repeat(12)@(negedge clk);if(!line_req_valid)$fatal(1,"Cancelled public writer request");end
        hold_request=0;hold_result_response=0;
    endtask
    initial begin:main
        integer header_file,result_file,status_file,metrics_file,scanned,expected_edges,retain,start_cycles,requests_before;
        logic [141:0] proposed;logic [31:0] original_base;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        reset_joint();header_file=$fopen("cases.txt","r");result_file=$fopen("actual-results.txt","w");
        if(!header_file || !result_file)$fatal(1,"Missing header/results");
        while(!$feof(header_file))begin
            scanned=$fscanf(header_file,"%h %d %d\n",proposed,expected_edges,retain);if(scanned!=3)$fatal(1,"Malformed header");
            load_case(case_id);if(cj!==proposed)$fatal(1,"CJ fixture drift");
            gradient_file=$fopen($sformatf("actual-%0d.grad",case_id),"w");record_normal=1;start_cycles=cycles;start_job();
            if(case_id==0)begin cancel_scope=cj[95:0]^(96'd1<<64);cancel_valid=1;@(posedge clk);@(negedge clk);cancel_valid=0;end
            feed_image();take_done(0);record_normal=0;$fclose(gradient_file);
            if(!snapshot_saved || actual_inputs!=P || input_pairs!=P || class_pairs!=P || output_pixels!=N || edge_pixels!=expected_edges || discarded_pixels || actual_grads!=(retain ? P : 0))$fatal(1,"Normal count/snapshot case %0d",case_id);
            dump_words($sformatf("actual-%0d.state.bin",case_id),0,CWORDS);
            dump_words($sformatf("actual-%0d.queue.bin",case_id),QFIRST,edge_pixels);
            dump_words($sformatf("actual-%0d.result.bin",case_id),RFIRST,RWORDS);
            status_file=$fopen($sformatf("actual-%0d.status",case_id),"w");$fwrite(status_file,"%h\n",r2_status_snapshot);$fclose(status_file);
            $fwrite(result_file,"%0d %0d %0d %0d %0d %0d %0d %0d %0d\n",case_id,outcome,reason,input_pairs,class_pairs,output_pixels,edge_pixels,discarded_pixels,cycles-start_cycles);case_id++;
        end
        $fclose(header_file);$fclose(result_file);
        if(RUN_PROTOCOL)begin
            for(integer kind=0;kind<4;kind++)begin
                load_case(4);requests_before=requests;
                if(kind==0)begin original_base=class_base;class_base=class_base+1;end
                else if(kind==1)begin original_base=result_base;result_base=queue_base;end
                else if(kind==2)begin original_base=result_base;result_base=32'hffffffc0;end
                else cj[128:118]=2047;
                start_job();take_done(1);if(requests!=requests_before)$fatal(1,"Illegal CJ/range accessed memory");
                if(kind==0)class_base=original_base;else if(kind<3)result_base=original_base;
            end
            load_case(4);start_job();feed_image(1);take_done(1);
            for(integer scenario=0;scenario<10;scenario++)begin
                reset_joint();load_case(4);hold_request=scenario==3;hold_result_response=scenario==8;start_job();
                fork feed_image();cancel_point(scenario);join
                take_done(2);cancels++;
            end
            for(integer region=0;region<3;region++)begin
                reset_joint();load_case(4);inject_error_region=region;start_job();feed_image();take_done(1);
                if(region==2 && (!error_held_pixel_seen||discarded_pixels==0))$fatal(1,"Failed writer did not close old held pixel");safe_errors++;
            end
            reset_joint();load_case(4);inject_unknown_region=2;start_job();feed_image();
            while(!quarantined)@(negedge clk);repeat(30)@(negedge clk);
            if(done_valid || cj_ready || line_req_valid)$fatal(1,"Unknown drain released complete Canny");
            reset_joint();load_case(4);start_job();feed_image();take_done(0);
        end
        metrics_file=$fopen("protocol-metrics.json","w");
        $fwrite(metrics_file,"{\"finished\":true,\"cancels\":%0d,\"safe_errors\":%0d,\"unknown_quarantine\":%s,\"cycles\":%0d,\"requests\":%0d}\n",cancels,safe_errors,RUN_PROTOCOL ? "true" : "false",cycles,requests);$fclose(metrics_file);
        finished=1;$display("Full Canny PASS images=%0d cancels=%0d errors=%0d cycles=%0d",case_id,cancels,safe_errors,cycles);$finish;
    end
endmodule
