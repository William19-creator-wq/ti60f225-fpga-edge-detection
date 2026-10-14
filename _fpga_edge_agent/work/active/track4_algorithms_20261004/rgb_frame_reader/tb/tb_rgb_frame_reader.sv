`timescale 1ns/1ps
module tb_rgb_frame_reader #(parameter integer WIDTH=34,HEIGHT=19,RUN_PROTOCOL=1);
    localparam integer P=WIDTH*HEIGHT/2,L=WIDTH*HEIGHT*3,A=((L+63)/64)*64,LINES=A/64;
    logic clk=0,rst=1,finished=0;always #5 clk=~clk;
    logic job_valid=0,job_ready,job_rsp_valid,job_rsp_ready=0,job_rsp_error;
    logic [31:0] job_base=32'h100000;logic [63:0] job_handle=64'habcdef0112345678;
    logic out_valid,out_ready=0;logic [73:0] out_fp;logic [63:0] out_id;
    logic cancel_valid=0;logic [63:0] cancel_id=64'habcdef0112345678;
    logic done_valid,done_ready=0,source_stop,quarantined;logic [63:0] done_id;
    logic [1:0] outcome;logic [7:0] reason;logic [20:0] prepared_pairs,output_pairs;logic [21:0] read_lines,discarded_lines;
    logic line_req_valid,line_req_ready=0,line_write,line_rsp_valid=0,line_rsp_ready,line_error=0,line_drained=1;
    logic [31:0] line_addr;logic [511:0] line_wdata,line_rdata=0;
    rgb_frame_reader #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) dut(.*);
    logic [511:0] expected_lines[0:LINES-1];logic [73:0] expected_fp[0:P-1];
    logic pending=0,hold_request=0,hold_response=0,hold_output=0,hold_last=0,next_error=0,next_drained=1,record_frame=0,random_stalls=0;
    logic held_request=0,held_fp=0,held_done=0;logic [544:0] request_body;logic [137:0] fp_body;logic [159:0] done_body;
    logic [31:0] base_locked;logic [63:0] id_locked;logic [31:0] rng=32'h561278cb;
    integer cycles=0,request_count=0,actual_outputs=0,delay_count=0,normal_frames=0,cases=0,cancels=0,safe_errors=0,cross60=0,cross62=0,two_slot_cycles=0;
    integer output_file=0;
    always @(negedge clk)begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        line_req_ready=!rst && !pending && !hold_request && (!random_stalls || rng[2:0]!=0);
        line_rsp_valid=!rst && pending && delay_count==0 && !hold_response && (!random_stalls || rng[5:3]!=0);
        out_ready=!rst && !hold_output && !(hold_last && output_pairs==21'(P-1)) && (!random_stalls || rng[7:6]!=0);
    end
    always @(posedge clk)begin
        cycles++;
        if(rst)begin pending=0;held_request=0;held_fp=0;held_done=0;end
        else begin
            if(held_request && (!line_req_valid || request_body!=={line_write,line_addr,line_wdata}))$fatal(1,"Reader held request changed");
            if(held_fp && (!out_valid || fp_body!=={out_id,out_fp}))$fatal(1,"Reader held FP changed");
            if(held_done && (!done_valid || done_body!=={done_id,outcome,reason,prepared_pairs,output_pairs,read_lines,discarded_lines}))$fatal(1,"Reader held done changed");
            held_request=line_req_valid && !line_req_ready;request_body={line_write,line_addr,line_wdata};
            held_fp=out_valid && !out_ready;fp_body={out_id,out_fp};
            held_done=done_valid && !done_ready;done_body={done_id,outcome,reason,prepared_pairs,output_pairs,read_lines,discarded_lines};
            if(job_valid && job_ready)begin base_locked=job_base;id_locked=job_handle;request_count=0;actual_outputs=0;end
            if(line_req_valid && line_req_ready)begin
                integer offset;
                offset=integer'({1'b0,line_addr}-{1'b0,base_locked});
                if(pending || line_write || line_wdata!=0 || line_addr[5:0]!=0 || offset!=request_count*64 || offset<0 || offset+64>A)$fatal(1,"Reader request grant/order");
                pending=1;delay_count=3;line_rdata=expected_lines[offset/64];line_error=next_error;line_drained=next_drained;request_count++;
            end else if(pending && delay_count>0)delay_count--;
            if(line_rsp_valid && line_rsp_ready)pending=0;
            if(out_valid && out_ready)begin
                if(actual_outputs>=P || out_id!=id_locked || out_fp!==expected_fp[actual_outputs])$fatal(1,"Reader FP/identity mismatch ordinal=%0d actual=%h expected=%h",actual_outputs,out_fp,expected_fp[actual_outputs]);
                if(record_frame)$fwrite(output_file,"%019h\n",out_fp);
                actual_outputs++;
            end
            if(dut.build_fp && dut.cursor==60)cross60++;
            if(dut.build_fp && dut.cursor==62)cross62++;
            if(dut.slot_state[0]!=0 && dut.slot_state[1]!=0)two_slot_cycles++;
        end
        if(cycles>(RUN_PROTOCOL ? 2000000 : 100000000))$fatal(1,"Reader watchdog state=%0d cases=%0d",dut.state,cases);
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;job_valid=0;job_rsp_ready=0;cancel_valid=0;done_ready=0;
        hold_request=0;hold_response=0;hold_output=0;hold_last=0;next_error=0;next_drained=1;record_frame=0;random_stalls=0;
        job_base=32'h100000;job_handle=64'habcdef0112345678;cancel_id=job_handle;
        repeat(3)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic propose;
        @(negedge clk);job_valid=1;do @(posedge clk);while(!job_ready);
        @(negedge clk);job_valid=0;job_base=32'h500000;job_handle=64'h9988776655443322;
        while(!job_rsp_valid)@(negedge clk);
    endtask
    task automatic configure(input logic rejected=0);
        propose();if(job_rsp_error!==rejected)$fatal(1,"Reader config status");repeat(5)@(negedge clk);
        job_rsp_ready=1;@(posedge clk);@(negedge clk);job_rsp_ready=0;
    endtask
    task automatic cancel_matching;
        @(negedge clk);cancel_id=id_locked;cancel_valid=1;@(posedge clk);@(negedge clk);cancel_valid=0;
    endtask
    task automatic take_done(input integer expected_outcome,input integer expected_reason);
        while(!done_valid)@(negedge clk);
        if(outcome!=expected_outcome || reason!=expected_reason || done_id!=id_locked || output_pairs!=actual_outputs || pending || line_req_valid || line_rsp_ready || quarantined)$fatal(1,"Reader closure/count mismatch out=%0d reason=%0d expected=%0d/%0d",outcome,reason,expected_outcome,expected_reason);
        repeat(6)@(negedge clk);done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;if(!job_ready)$fatal(1,"Reader job not released");
    endtask
    initial begin
        integer listing,count,ignored,result_file,protocol_file,start_cycles;string stem;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        listing=$fopen("frame-list.txt","r");if(!listing)$fatal(1,"Missing reader list");ignored=$fscanf(listing,"%d\n",count);result_file=$fopen("actual-results.txt","w");
        for(integer frame=0;frame<count;frame++)begin
            ignored=$fscanf(listing,"%s\n",stem);$readmemh({stem,".lines"},expected_lines);$readmemh({stem,".fp"},expected_fp);
            reset_joint();if(frame==1)job_base=32'(33'h100000000-33'(A));
            configure();random_stalls=frame%2==0;record_frame=1;output_file=$fopen({stem,".actual.fp"},"w");start_cycles=cycles;
            cancel_valid=1;cancel_id=id_locked^64'd1;while(!done_valid)@(negedge clk);cancel_valid=0;record_frame=0;$fclose(output_file);
            if(prepared_pairs!=P || output_pairs!=P || read_lines!=LINES || discarded_lines!=0)$fatal(1,"Reader normal totals");
            $fwrite(result_file,"%s %0d %0d %0d %0d %0d %0d %0d\n",stem,prepared_pairs,output_pairs,read_lines,discarded_lines,outcome,reason,cycles-start_cycles);
            cancel_matching();take_done(0,0);normal_frames++;
        end
        $fclose(listing);$fclose(result_file);
        if(RUN_PROTOCOL)begin
            reset_joint();job_base++;configure(1);if(!job_ready)$fatal(1,"Reader rejected alignment retained ctx");cases++;
            if(A>64)begin reset_joint();job_base=32'hffffffc0;configure(1);if(!job_ready)$fatal(1,"Reader rejected overflow retained ctx");cases++;end
            reset_joint();propose();cancel_matching();job_rsp_ready=1;@(posedge clk);@(negedge clk);job_rsp_ready=0;take_done(2,128);cases++;cancels++;
            reset_joint();hold_request=1;configure();while(!line_req_valid)@(negedge clk);cancel_matching();repeat(12)@(negedge clk);
            if(!line_req_valid || done_valid)$fatal(1,"Reader request cancelled before drain");hold_request=0;take_done(2,128);cases++;cancels++;
            reset_joint();hold_response=1;configure();while(!pending)@(negedge clk);cancel_matching();repeat(12)@(negedge clk);
            if(done_valid || job_ready)$fatal(1,"Reader waiting response falsely closed");hold_response=0;take_done(2,128);if(discarded_lines!=1)$fatal(1,"Reader cancelled return not discarded once");cases++;cancels++;
            reset_joint();hold_output=1;configure();while(!out_valid)@(negedge clk);repeat(40)@(negedge clk);
            if(request_count!=(LINES<2 ? LINES : 2) || prepared_pairs!=1 || output_pairs!=0)$fatal(1,"Reader bounded prefetch/FP reservation");
            cancel_matching();repeat(12)@(negedge clk);if(!out_valid || done_valid)$fatal(1,"Reader cancelled public FP lost");hold_output=0;take_done(2,128);cases++;cancels++;
            reset_joint();hold_last=1;configure();while(!(out_valid && out_fp[72]))@(negedge clk);
            cancel_matching();repeat(12)@(negedge clk);if(!out_valid || done_valid)$fatal(1,"Reader last public FP lost");hold_last=0;take_done(2,128);cases++;cancels++;
            reset_joint();hold_response=1;next_error=1;configure();while(!pending)@(negedge clk);while(delay_count>0)@(negedge clk);
            cancel_valid=1;cancel_id=id_locked;hold_response=0;@(posedge clk);@(negedge clk);cancel_valid=0;take_done(1,16);safe_errors++;cases++;
            reset_joint();next_drained=0;configure();while(!quarantined)@(negedge clk);repeat(20)@(negedge clk);
            if(done_valid || job_ready || line_req_valid)$fatal(1,"Reader unknown released owner");cases++;
            reset_joint();configure();take_done(0,0);cases++;
        end
        protocol_file=$fopen("protocol-metrics.json","w");
        $fwrite(protocol_file,"{\"finished\":true,\"cases\":%0d,\"cancel_cases\":%0d,\"safe_errors\":%0d,\"unknown_quarantine\":%s,\"cross60\":%0d,\"cross62\":%0d,\"two_slot_cycles\":%0d,\"cycles\":%0d}\n",cases,cancels,safe_errors,RUN_PROTOCOL ? "true" : "false",cross60,cross62,two_slot_cycles,cycles);$fclose(protocol_file);
        finished=1;$display("RGB reader PASS frames=%0d cases=%0d cycles=%0d",normal_frames,cases,cycles);$finish;
    end
endmodule
