`timescale 1ns/1ps
module tb_raw_color_stream;
    parameter integer WIDTH=34,HEIGHT=19,RUN_PROTOCOL=1;
    localparam integer P=WIDTH*HEIGHT/2;
    logic clk=0,rst=1,finished=0;always #5 clk=~clk;
    logic job_valid=0,job_ready;logic [63:0] job_id=0;logic [1:0] phase=0;
    logic in_valid=0,in_ready;logic [19:0] raw_pair=0;logic [10:0] in_x_even=0,in_y=0;
    logic [2:0] in_markers=0;logic in_bad=0;logic [63:0] in_id=0;
    logic out_valid,out_ready=0;logic [47:0] rgb_pair;logic [10:0] out_x_even,out_y;logic [2:0] out_markers;logic [63:0] out_id;
    logic cancel_valid=0;logic [63:0] cancel_id=0;logic source_stop;
    logic done_valid,done_ready=0;logic [63:0] done_id;logic [1:0] outcome;logic [7:0] reason;
    logic [21:0] accepted_pairs,window_pairs,output_pairs,discarded_reads;
    raw10_color_stream #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) dut(.*);
    logic [19:0] raw_values[0:P-1];logic [179:0] expected_windows[0:P-1];
    byte unsigned expected_rgb[0:P*6-1];
    logic [63:0] expected_id;
    logic [1:0] expected_phase;
    integer case_id=0,cycles=0,seed=32'h171431,inputs=0,windows=0,outputs=0,reads_issued=0,reads_retired=0;
    integer cancel_cases=0,input_errors=0,pending_discard_cases=0,output_file=0;
    logic record_normal=0,force_stall=0,change_proposal=0,held_rgb=0,held_window=0,held_done=0;
    logic [136:0] saved_rgb;logic [204:0] saved_window;logic [161:0] saved_done;
    function automatic integer random_bounded(input integer limit);
        seed=seed^(seed<<13);seed=seed^(seed>>17);seed=seed^(seed<<5);return (seed & 32'h7fffffff)%limit;
    endfunction
    function automatic [2:0] markers_for(input integer pair_index);
        return {pair_index==P-1,pair_index%(WIDTH/2)==WIDTH/2-1,pair_index==0};
    endfunction
    function automatic [47:0] rgb_for(input integer pair_index);
        logic [47:0] result;
        for(integer j=0;j<6;j++)result[j*8+:8]=expected_rgb[pair_index*6+j];return result;
    endfunction
    always @(negedge clk)begin
        out_ready=!rst && !force_stall && random_bounded(5)!=0;
        if(change_proposal && dut.state!=0 && dut.state!=5)begin phase=phase+2'd1;job_id=job_id^64'h0000100000000000;end
    end
    always @(posedge clk)begin
        cycles++;
        if(rst)begin held_rgb=0;held_window=0;held_done=0;end
        else begin
            if(held_rgb && (!out_valid || {out_id,out_markers,out_y,out_x_even,rgb_pair}!==saved_rgb))$fatal(1,"Public RGB changed/withdrawn");
            if(held_window && dut.state!=4 && (!dut.window_valid || {dut.window_eof,dut.window_eol,dut.window_sof,dut.window_y,dut.window_x,dut.window_payload}!==saved_window))$fatal(1,"Private window changed without common abort");
            if(held_done && (!done_valid || {done_id,outcome,reason,accepted_pairs,window_pairs,output_pairs,discarded_reads}!==saved_done))$fatal(1,"Held RAW color done changed");
            held_rgb=out_valid && !out_ready;saved_rgb={out_id,out_markers,out_y,out_x_even,rgb_pair};
            held_window=dut.window_valid && !dut.kernel_ready;saved_window={dut.window_eof,dut.window_eol,dut.window_sof,dut.window_y,dut.window_x,dut.window_payload};
            held_done=done_valid && !done_ready;saved_done={done_id,outcome,reason,accepted_pairs,window_pairs,output_pairs,discarded_reads};
            if(in_valid && in_ready)inputs++;
            if(dut.window.rd_en)reads_issued++;
            if(dut.window.advance && !dut.window.flush && !dut.window.frame_start &&
               ((dut.window.read_pending==1 && dut.window.pending_row!=0) || dut.window.read_pending==2))reads_retired++;
            if(dut.window_fire)begin
                if(windows>=P || dut.window_payload!==expected_windows[windows] || dut.window_x!=2*(windows%(WIDTH/2)) || dut.window_y!=windows/(WIDTH/2) ||
                   {dut.window_eof,dut.window_eol,dut.window_sof}!==markers_for(windows))$fatal(1,"Actual RAW RAM/window mismatch pair=%0d case=%0d",windows,case_id);
                windows++;
            end
            if(out_valid && out_ready)begin
                if(outputs>=P || rgb_pair!==rgb_for(outputs) || out_x_even!=2*(outputs%(WIDTH/2)) || out_y!=outputs/(WIDTH/2) || out_markers!==markers_for(outputs) || out_id!=expected_id)$fatal(1,"RAW RGB/identity mismatch pair=%0d",outputs);
                if(record_normal)$fwrite(output_file,"%c%c%c%c%c%c",rgb_pair[7:0],rgb_pair[15:8],rgb_pair[23:16],rgb_pair[31:24],rgb_pair[39:32],rgb_pair[47:40]);
                outputs++;
            end
        end
        if(cycles>100000000)$fatal(1,"RAW color global watchdog");
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;job_valid=0;in_valid=0;in_bad=0;cancel_valid=0;done_ready=0;force_stall=0;change_proposal=0;record_normal=0;
        repeat(4)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic load_case(input integer index_value);
        integer handle,scanned,phase_value,pattern_value,ordinal=0,bytes_read;string filename;
        if(dut.state!=0 || out_valid || !dut.window_empty)$fatal(1,"Replacing RAW scope with live old ownership");
        handle=$fopen("cases.txt","r");if(!handle)$fatal(1,"RAW config missing");
        do begin scanned=$fscanf(handle,"%d %d\n",phase_value,pattern_value);if(scanned!=2)$fatal(1,"RAW config malformed");end while(ordinal++<index_value);$fclose(handle);
        phase=2'(phase_value);expected_phase=phase;job_id=64'h5000000000000000+64'(index_value);expected_id=job_id;
        filename=$sformatf("case-%0d.raw",index_value);handle=$fopen(filename,"r");if(!handle)$fatal(1,"RAW vector missing");$fclose(handle);$readmemh(filename,raw_values);
        filename=$sformatf("case-%0d.window",index_value);$readmemh(filename,expected_windows);
        filename=$sformatf("case-%0d.rgb",index_value);handle=$fopen(filename,"rb");if(!handle)$fatal(1,"RAW RGB reference missing");
        bytes_read=$fread(expected_rgb,handle);$fclose(handle);if(bytes_read!=P*6)$fatal(1,"RAW RGB reference incomplete");
        inputs=0;windows=0;outputs=0;reads_issued=0;reads_retired=0;
    endtask
    task automatic start_job;
        integer timeout;
        @(negedge clk);job_valid=1;timeout=0;
        do begin @(posedge clk);if(timeout++>100000)$fatal(1,"RAW job request stuck");end while(!job_ready);
        @(negedge clk);job_valid=0;
    endtask
    task automatic feed(input integer error_kind=0);
        integer timeout;
        for(integer pair_index=0;pair_index<P;pair_index++)begin
            repeat(random_bounded(3))@(negedge clk);if(source_stop || rst)break;
            raw_pair=raw_values[pair_index];in_id=expected_id;in_bad=0;
            in_x_even=11'(2*(pair_index%(WIDTH/2)));in_y=11'(pair_index/(WIDTH/2));in_markers=markers_for(pair_index);
            if(pair_index==P/2)case(error_kind)
                1:in_bad=1;
                2:in_id=expected_id^64'h8000000000000000;
                3:in_x_even=in_x_even^11'd1;
                4:in_markers=in_markers^3'd2;
                default:begin end
            endcase
            in_valid=1;timeout=0;do begin @(posedge clk);if(timeout++>1000000)$fatal(1,"RAW source request stuck");end while(!in_ready && !source_stop && !rst);
            @(negedge clk);in_valid=0;if(source_stop || rst)break;
        end
    endtask
    task automatic take_done(input integer expected_outcome,input integer expected_reason=0);
        integer timeout;
        timeout=0;while(!done_valid)begin @(negedge clk);if(timeout++>20000000)$fatal(1,"RAW drain stuck state=%0d phase=%0d pending=%0d",dut.state,dut.window.replay_phase,dut.window.read_pending);end
        if(outcome!=expected_outcome || reason!=expected_reason || done_id!=expected_id || !dut.window_empty || out_valid)$fatal(1,"RAW outcome/drain %0d/%0d expected %0d/%0d",outcome,reason,expected_outcome,expected_reason);
        if(accepted_pairs!=inputs || window_pairs!=windows || output_pairs!=outputs || reads_issued!=reads_retired+discarded_reads)$fatal(1,"RAW actual event ledger input=%0d/%0d window=%0d/%0d out=%0d/%0d read=%0d/%0d/%0d",inputs,accepted_pairs,windows,window_pairs,outputs,output_pairs,reads_issued,reads_retired,discarded_reads);
        if(discarded_reads>0)pending_discard_cases++;
        repeat(10)@(negedge clk);
        // 已公开done不得因后来匹配cancel重写。
        cancel_id=expected_id;cancel_valid=1;@(posedge clk);@(negedge clk);cancel_valid=0;
        done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;
    endtask
    task automatic cancel_point(input integer scenario);
        integer timeout;logic found;
        found=0;timeout=0;
        while(!found)begin
            case(scenario)
                0:found=dut.state==1;
                1:found=dut.window.read_pending==1 && dut.window.pending_row!=0;
                2:found=dut.window.replay_phase==2;
                3:found=dut.window.replay_phase==3;
                4:found=dut.window_valid && !dut.kernel_ready;
                5:found=out_valid && !out_ready;
                6:found=dut.window_fire;
                7:found=in_valid && !in_ready && dut.state==2;
                default:$fatal(1,"RAW cancel point unknown");
            endcase
            if(timeout++>1000000 || done_valid)$fatal(1,"RAW cancel point %0d unavailable",scenario);
            if(!found)@(negedge clk);
        end
        cancel_id=expected_id;cancel_valid=1;@(posedge clk);@(negedge clk);cancel_valid=0;force_stall=0;
    endtask
    initial begin:main
        integer handle,result_handle,metrics_handle,scanned,phase_value,pattern_value,start_cycles;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        reset_joint();handle=$fopen("cases.txt","r");result_handle=$fopen("actual-results.txt","w");if(!handle || !result_handle)$fatal(1,"RAW cases/output missing");
        while(!$feof(handle))begin
            scanned=$fscanf(handle,"%d %d\n",phase_value,pattern_value);if(scanned!=2)$fatal(1,"RAW header malformed");
            load_case(case_id);output_file=$fopen($sformatf("actual-%0d.rgb",case_id),"wb");if(!output_file)$fatal(1,"RAW RGB output missing");
            record_normal=1;start_cycles=cycles;start_job();change_proposal=1;
            if(case_id==0)begin cancel_id=expected_id^64'd1;cancel_valid=1;@(posedge clk);@(negedge clk);cancel_valid=0;end
            feed();take_done(0);change_proposal=0;record_normal=0;$fclose(output_file);
            if(inputs!=P || windows!=P || outputs!=P || reads_issued!=P || discarded_reads!=0)$fatal(1,"RAW normal frame incomplete");
            $fwrite(result_handle,"%0d %0d %0d %0d %0d %0d %0d %0d\n",case_id,outcome,reason,accepted_pairs,window_pairs,output_pairs,discarded_reads,cycles-start_cycles);case_id++;
        end
        $fclose(handle);$fclose(result_handle);
        if(RUN_PROTOCOL)begin
            for(integer error_kind=1;error_kind<=4;error_kind++)begin load_case(8);start_job();feed(error_kind);take_done(1,error_kind);input_errors++;end
            for(integer scenario=0;scenario<8;scenario++)begin
                // P4的全部RAW在首RGB/反压形成前已接纳，没有RUN输入held状态。
                if(scenario==7 && P<8)continue;
                reset_joint();load_case(8);force_stall=scenario==4 || scenario==5 || scenario==7;start_job();
                fork feed();cancel_point(scenario);join
                take_done(2);cancel_cases++;
            end
            // 共同rst实际作废held RGB；下一纯红帧不能混入旧随机图。
            reset_joint();load_case(8);force_stall=1;start_job();
            fork
                feed();
                begin while(!out_valid)@(negedge clk);reset_joint();end
            join
            load_case(3);start_job();feed();take_done(0);
        end
        metrics_handle=$fopen("protocol-metrics.json","w");$fwrite(metrics_handle,"{\"finished\":true,\"input_errors\":%0d,\"cancel_cases\":%0d,\"pending_discard_cases\":%0d,\"cycles\":%0d}\n",input_errors,cancel_cases,pending_discard_cases,cycles);$fclose(metrics_handle);
        finished=1;$display("RAW10 real rows/reflect101/RGB PASS frames=%0d errors=%0d cancel=%0d cycles=%0d",case_id,input_errors,cancel_cases,cycles);$finish;
    end
endmodule
