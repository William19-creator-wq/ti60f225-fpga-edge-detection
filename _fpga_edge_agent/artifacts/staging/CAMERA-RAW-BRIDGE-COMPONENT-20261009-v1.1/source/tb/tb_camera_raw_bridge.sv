`timescale 1ns/1ps
module tb_camera_raw_bridge #(
    parameter integer TEST_WIDTH=20,TEST_HEIGHT=8,TEST_FULL=0,TEST_DEPTH=16,
    parameter integer TEST_WATCHDOG=4000,
    parameter integer TEST_PIXEL_HALF_PS=10000,TEST_CORE_HALF_PS=5000
);
    logic core_clk=0,pixel_clk=0,pixel_clock_enable=1,cold_reset_n=0,finished=0;
    always #(TEST_CORE_HALF_PS/1000.0) core_clk=~core_clk;
    always #(TEST_PIXEL_HALF_PS/1000.0) if(pixel_clock_enable)pixel_clk=~pixel_clk;
    logic job_valid=0;wire job_ready;logic [63:0] job_handle=0;logic [194:0] job_origin=0;
    logic cancel_valid=0,discard_valid=0;logic [63:0] cancel_handle=0,discard_handle=0;
    logic [63:0] pixel_data=0;logic pixel_valid=0,hs=0,vs=0,rx_fault=0;
    logic [3:0] pixel_per_clock=4;logic [5:0] datatype=6'h2b;
    logic [1:0] virtual_channel=0;logic [15:0] word_count=16'(TEST_WIDTH*5/4);
    wire out_valid;logic out_ready=1;wire [19:0] raw_pair;wire [10:0] out_x_even,out_y;
    wire [2:0] out_markers;wire out_bad;wire [63:0] out_handle;
    wire done_valid;logic done_ready=0;wire [63:0] done_handle;wire [194:0] done_origin;
    wire [1:0] done_outcome;wire [7:0] done_reason;
    wire [21:0] done_accepted_groups,done_delivered_pairs,done_discarded_pairs;
    wire done_shape_complete,done_drained,done_groups_known,reception_verified,quarantined;wire [2:0] phase;
    integer pair_file,cases_file,case_count=0,completed_cases=0,reset_aborted_jobs=0,pair_index=0,total_pairs=0,frame_seed=0,core_cycles=0;
    logic random_ready=0;logic [31:0] random_state=32'h68c4a319;
    logic held=0,done_held=0;logic [109:0] held_body;logic [337:0] held_done;
    wire [109:0] pair_body={out_handle,out_bad,out_markers,out_y,out_x_even,raw_pair};
    wire [337:0] done_body={done_handle,done_origin,done_outcome,done_reason,done_accepted_groups,
        done_delivered_pairs,done_discarded_pairs,done_shape_complete,done_drained,done_groups_known};
    camera_raw_bridge #(.IMAGE_WIDTH(TEST_WIDTH),.IMAGE_HEIGHT(TEST_HEIGHT),.BUFFER_DEPTH(TEST_DEPTH),.WATCHDOG_CYCLES(TEST_WATCHDOG)) dut(.*);

    function automatic logic [9:0] sample(input integer x,y,seed);
        return 10'(37*x+53*y+7*(x^y)+101*seed);
    endfunction
    function automatic logic [39:0] group(input integer x,y,seed);
        logic [39:0] a;for(integer k=0;k<4;k++)a[k*10+:10]=sample(x+k,y,seed);return a;
    endfunction
    always @(negedge core_clk)if(random_ready)begin
        random_state={random_state[30:0],random_state[31]^random_state[21]^random_state[1]^random_state[0]};
        out_ready=(random_state[3:0]!=0);
    end
    always @(posedge core_clk)begin
        integer x,y;logic [19:0] want;logic [2:0] flags;logic [127:0] record;
        core_cycles++;
        if(!cold_reset_n)begin held=0;done_held=0;end
        else begin
            if(held && !(discard_valid && discard_handle==job_handle) && !dut.discard_mode && (!out_valid || pair_body!==held_body))$fatal(1,"Held RAW changed");
            if(done_held && (!done_valid || done_body!==held_done))$fatal(1,"Held done changed");
            held=out_valid&&!out_ready;held_body=pair_body;done_held=done_valid&&!done_ready;held_done=done_body;
            if(reception_verified)$fatal(1,"Local shape promoted to reception verification");
            if(out_valid&&out_ready)begin
                x=(pair_index%(TEST_WIDTH/2))*2;y=pair_index/(TEST_WIDTH/2);
                want={sample(x+1,y,frame_seed),sample(x,y,frame_seed)};
                flags={y==TEST_HEIGHT-1 && x==TEST_WIDTH-2,x==TEST_WIDTH-2,pair_index==0};
                if(raw_pair!==want || out_x_even!=x || out_y!=y || out_markers!==flags || out_bad || out_handle!=job_handle)
                    $fatal(1,"RAW pair identity/value mismatch case=%0d pair=%0d got=%h want=%h xy=%0d,%0d",case_count,pair_index,raw_pair,want,out_x_even,out_y);
                record={out_handle,5'd0,out_x_even,5'd0,out_y,4'd0,out_bad,out_markers,4'd0,raw_pair};
                for(integer b=0;b<16;b++)$fwrite(pair_file,"%c",record[b*8+:8]);
                pair_index++;total_pairs++;
            end
        end
    end
    task automatic reset_all;
        random_ready=0;out_ready=1;done_ready=0;job_valid=0;cancel_valid=0;discard_valid=0;
        cold_reset_n=0;pixel_clock_enable=1;hs=0;vs=0;pixel_valid=0;rx_fault=0;
        pixel_per_clock=4;datatype=6'h2b;virtual_channel=0;word_count=16'(TEST_WIDTH*5/4);
        repeat(8)@(negedge core_clk);cold_reset_n=1;repeat(8)@(negedge pixel_clk);
    endtask
    task automatic start_job(input bit old_frame=0);
        case_count++;frame_seed=case_count;pair_index=0;
        if(old_frame)begin @(negedge pixel_clk);vs=1;hs=1;end
        @(negedge core_clk);wait(job_ready);job_handle=64'h6000000000000000+64'(case_count);
        job_origin={64'(case_count),32'(case_count),32'h17,64'h100003,3'd0};job_valid=1;
        @(negedge core_clk);job_valid=0;repeat(12)@(negedge pixel_clk);
        if(old_frame)begin
            pixel_valid=1;pixel_data='1;repeat(3)@(negedge pixel_clk);pixel_valid=0;hs=0;vs=0;
            repeat(5)@(negedge pixel_clk);
        end
    endtask
    task automatic pulse_cancel(input bit correct=1);
        @(negedge core_clk);cancel_handle=correct ? job_handle : job_handle^64'h100;cancel_valid=1;
        @(negedge core_clk);cancel_valid=0;
    endtask
    task automatic pulse_discard(input bit correct=1);
        @(negedge core_clk);discard_handle=correct ? job_handle : job_handle^64'h100;discard_valid=1;
        @(negedge core_clk);discard_valid=0;
    endtask
    // mode：1..4元数据，5短行，6长行，7早VS，8额外行，9rx_fault，10中途取消，11溢出。
    task automatic send_frame(input integer mode=0);
        integer groups_to_send;
        @(negedge pixel_clk);vs=1;
        if(mode==12)begin hs=1;pixel_valid=1;pixel_data={24'd0,group(0,0,frame_seed)};@(negedge pixel_clk);pixel_valid=0;end
        repeat(2)@(negedge pixel_clk);
        for(integer y=0;y<TEST_HEIGHT;y++)begin
            hs=1;repeat(2)@(negedge pixel_clk);
            groups_to_send=TEST_WIDTH/4;
            if(mode==5 && y==0)groups_to_send=2;
            if(mode==6 && y==0)groups_to_send++;
            for(integer g=((mode==12 && y==0)?1:0);g<groups_to_send;g++)begin
                pixel_data={24'hc6a931,group(g*4,y,frame_seed)};pixel_valid=1;
                if(y==0 && g==2)begin
                    case(mode)
                        1:pixel_per_clock=2;2:datatype=6'h2a;3:virtual_channel=1;4:word_count=0;9:rx_fault=1;
                    endcase
                end
                @(negedge pixel_clk);pixel_valid=0;
                if(mode!=11)repeat(2)@(negedge pixel_clk);
                if(mode==10 && y==0 && g==1)begin pulse_cancel();repeat(8)@(negedge pixel_clk);end
            end
            hs=0;if(mode==13 && y==TEST_HEIGHT-1)vs=0;repeat(4)@(negedge pixel_clk);
            if(mode==7 && y==0)begin vs=0;repeat(3)@(negedge pixel_clk);vs=1;end
        end
        if(mode==8)begin hs=1;repeat(3)@(negedge pixel_clk);hs=0;end
        if(mode==14)begin pulse_cancel();repeat(8)@(negedge pixel_clk);end
        repeat(5)@(negedge pixel_clk);
        if(done_valid && mode==0)$fatal(1,"Success before VS end");
        vs=0;repeat(3)@(negedge pixel_clk);
    endtask
    task automatic finish_case(input integer outcome,reason,input bit shape,input bit drain=1,input bit known=1,input integer exact_groups=-1);
        integer waited;logic [337:0] snapshot;
        waited=0;while(!done_valid && waited<TEST_WATCHDOG+200)begin @(negedge core_clk);waited++;end
        if(!done_valid)$fatal(1,"Missing terminal case=%0d",case_count);
        if(done_handle!=job_handle || done_origin!==job_origin || done_outcome!=outcome || done_reason!=reason ||
            done_shape_complete!=shape || done_drained!=drain || done_groups_known!=known)
            $fatal(1,"Terminal mismatch case=%0d got=%0d/%0d shape=%b drained=%b known=%b groups=%0d",case_count,done_outcome,done_reason,done_shape_complete,done_drained,done_groups_known,done_accepted_groups);
        if(exact_groups>=0 && done_accepted_groups!=exact_groups)$fatal(1,"Accepted prefix count mismatch");
        if(drain && done_delivered_pairs+done_discarded_pairs!=done_accepted_groups*2)$fatal(1,"Drained count mismatch");
        if(done_delivered_pairs!=pair_index)$fatal(1,"Reported delivery differs from actual boundary");
        snapshot=done_body;repeat(11)@(negedge core_clk);if(done_body!==snapshot || !done_valid)$fatal(1,"Done not held");
        $fwrite(cases_file,"%0d,%h,%0d,%0d,%0d,%0d,%0d,%0d,%b,%b,%b\n",case_count,job_handle,frame_seed,
            done_accepted_groups,done_delivered_pairs,done_discarded_pairs,done_outcome,done_reason,done_shape_complete,done_drained,done_groups_known);
        done_ready=1;@(negedge core_clk);done_ready=0;
        if(outcome!=3)begin waited=0;while(!job_ready && waited<100)begin @(negedge core_clk);waited++;end
            if(!job_ready)$fatal(1,"No safe rearm after terminal ack");end
        else begin repeat(10)@(negedge core_clk);if(job_ready || !quarantined)$fatal(1,"Quarantine permitted rearm");end
        completed_cases++;
        $display("Bridge case %0d PASS outcome=%0d reason=%0d pairs=%0d",case_count,outcome,reason,pair_index);
    endtask
    initial begin
        integer metrics;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        pair_file=$fopen("pairs.bin","wb");cases_file=$fopen("cases.csv","w");
        $fwrite(cases_file,"case,handle,seed,groups,delivered,discarded,outcome,reason,shape,drained,known\n");
        reset_all();random_ready=1;start_job();send_frame();finish_case(0,0,1,1,1,TEST_WIDTH*TEST_HEIGHT/4);
        random_ready=1;start_job(1);send_frame();finish_case(0,0,1,1,1,TEST_WIDTH*TEST_HEIGHT/4);
        if(!TEST_FULL)begin
            for(integer m=1;m<=9;m++)begin
                reset_all();start_job();send_frame(m);
                finish_case(1,(m<=4 ? 3 : (m==9 ? 5 : 4)),0,1,1,((m<=5 || m==9) ? 2 : -1));
            end
            reset_all();start_job();pulse_cancel(0);send_frame();finish_case(0,0,1,1,1,TEST_WIDTH*TEST_HEIGHT/4);
            reset_all();start_job();pulse_cancel();repeat(8)@(negedge pixel_clk);finish_case(2,1,0,1,1,0);
            reset_all();start_job();send_frame(10);finish_case(2,1,0,1,1,2);
            reset_all();out_ready=0;start_job();
            @(negedge pixel_clk);vs=1;hs=1;repeat(3)@(negedge pixel_clk);
            for(integer g=0;g<2;g++)begin pixel_valid=1;pixel_data={24'd0,group(g*4,0,frame_seed)};@(negedge pixel_clk);pixel_valid=0;repeat(3)@(negedge pixel_clk);end
            wait(out_valid);pulse_cancel();repeat(15)@(negedge core_clk);
            if(!out_valid || done_valid)$fatal(1,"Cancel discarded held prefix without permission");
            pulse_discard(0);repeat(8)@(negedge core_clk);if(!out_valid)$fatal(1,"Wrong handle discarded prefix");
            pulse_discard();finish_case(2,1,0,1,1,2);
            reset_all();out_ready=0;start_job();send_frame(11);out_ready=1;finish_case(3,2,0);
            reset_all();start_job();@(negedge pixel_clk);pixel_clock_enable=0;
            finish_case(3,6,0,0,0);pixel_clock_enable=1;
            reset_all();start_job();send_frame(12);finish_case(0,0,1,1,1,TEST_WIDTH*TEST_HEIGHT/4);
            reset_all();start_job();send_frame(13);finish_case(0,0,1,1,1,TEST_WIDTH*TEST_HEIGHT/4);
            reset_all();start_job();send_frame(14);finish_case(2,1,0,1,1,TEST_WIDTH*TEST_HEIGHT/4);
            reset_all();out_ready=0;start_job();
            @(negedge pixel_clk);vs=1;hs=1;repeat(3)@(negedge pixel_clk);
            pixel_valid=1;pixel_data={24'd0,group(0,0,frame_seed)};@(negedge pixel_clk);pixel_valid=0;
            wait(out_valid);repeat(7)@(negedge core_clk);if(pair_index!=0)$fatal(1,"Reset held setup delivered data");reset_aborted_jobs++;
            reset_all();start_job();send_frame();finish_case(0,0,1,1,1,TEST_WIDTH*TEST_HEIGHT/4);
        end
        $fclose(pair_file);$fclose(cases_file);metrics=$fopen("protocol-metrics.json","w");
        $fwrite(metrics,"{\"finished\":true,\"width\":%0d,\"height\":%0d,\"cases\":%0d,\"pairs\":%0d,\"core_cycles\":%0d,\"reset_aborted_jobs\":%0d,\"reception_closure_proven\":false}\n",TEST_WIDTH,TEST_HEIGHT,completed_cases,total_pairs,core_cycles,reset_aborted_jobs);$fclose(metrics);
        finished=1;$display("Camera RAW bridge PASS cases=%0d pairs=%0d",case_count,total_pairs);$finish;
    end
    initial begin #((TEST_WIDTH*TEST_HEIGHT*100)+(TEST_WATCHDOG*100)+1000000);if(!finished)$fatal(1,"Bridge suite watchdog");end
endmodule
