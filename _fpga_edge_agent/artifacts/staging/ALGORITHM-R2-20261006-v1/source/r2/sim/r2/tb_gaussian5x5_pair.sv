// U-G：25项独立黄金；实际原厂RAM使能、同址和阶段停顿均观察。
module tb_gaussian5x5_pair #(parameter integer W=6,H=5);
    localparam integer P=W*H/2;
    logic clk=0;always #5 clk=~clk;
    logic rst=1,frame_start=0,data_flush=0,in_valid=0,out_ready=0;
    wire in_ready,out_valid,empty;
    logic [15:0] in_pair;logic [10:0] in_x_even,in_y;logic in_sof,in_eol,in_eof;
    wire [15:0] out_pair;wire [10:0] out_x_even,out_y;wire out_sof,out_eol,out_eof;
    logic [95:0] job_ids;logic [136:0] stimulus[0:P-1],expected[0:P-1];
    wire [136:0] actual={out_eof,out_eol,out_sof,job_ids,out_y,out_x_even,out_pair};
    logic [136:0] held_output,held_input;logic output_held=0,input_held=0,finished=0;
    logic [15:0] held_ram[0:3];logic ram_held=0;
    integer delivered=0,accepted=0,cycles=0,hold_checks=0,ram_reads=0,ram_writes=0;
    integer first_input=-1,first_output=-1,last_output=-1,phase_hold=0,target_phase=0;
    integer random_stalls=0,input_stall=0,output_stall=0;
    logic [31:0] random_state=32'h431;
    string input_path,expected_path,result_path,case_id;
    gaussian5x5_pair #(.W(W),.H(H)) dut(.*);
    always @(posedge clk) begin : observe
        cycles=cycles+1;if(cycles>8192+128*(W/2)+128*P) $fatal(1,"Gaussian timeout");
        if(rst||frame_start||data_flush) begin output_held=0;input_held=0;ram_held=0;end
        else begin
            if(output_held) begin
                if(!out_valid||actual!==held_output) $fatal(1,"Gaussian output held changed");
                hold_checks=hold_checks+1;
            end
            if(input_held) begin
                if(!in_valid||{in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair}!==held_input)
                    $fatal(1,"Gaussian driver held changed");
                hold_checks=hold_checks+1;
            end
            for(integer b=0;b<4;b=b+1) begin
                if(ram_held&&dut.bank_read[b]!==held_ram[b]) $fatal(1,"RAM read output changed in stall");
                if(dut.rd_en[b]) ram_reads=ram_reads+1;
                if(dut.wr_en[b]) ram_writes=ram_writes+1;
                held_ram[b]=dut.bank_read[b];
            end
            if(!dut.advance&&(dut.rd_en!=0||dut.wr_en!=0)) $fatal(1,"RAM enabled while stalled");
            ram_held=!dut.advance;
            output_held=out_valid&&!out_ready;held_output=actual;
            input_held=in_valid&&!in_ready;held_input={in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair};
            if(in_valid&&in_ready) begin
                if(first_input<0) first_input=cycles;
                accepted=accepted+1;
            end
            if(out_valid&&out_ready) begin
                if(delivered>=P||actual!==expected[delivered])
                    $fatal(1,"Gaussian numeric/metadata mismatch %0d got=%h expected=%h",delivered,actual,expected[delivered]);
                if(first_output<0) first_output=cycles;
                last_output=cycles;delivered=delivered+1;
            end
        end
    end
    initial begin : run_case
        integer p,f;logic pending_input,fired,target_now;
        if($test$plusargs("FATAL_PROBE")) $fatal(1,"P-FATAL Gaussian intentional failure");
        if(!$value$plusargs("IN=%s",input_path)||!$value$plusargs("EXPECTED=%s",expected_path)
            ||!$value$plusargs("RESULT=%s",result_path)||!$value$plusargs("CASE=%s",case_id)) $fatal(1,"missing Gaussian args");
        if($value$plusargs("PHASE=%d",target_phase)) begin end
        if($value$plusargs("RANDOM=%d",random_stalls)) begin end
        $readmemh(input_path,stimulus);$readmemh(expected_path,expected);job_ids=stimulus[0][38 +: 96];
        repeat(4) @(negedge clk);rst=0;frame_start=1;
        @(negedge clk);frame_start=0;p=0;pending_input=0;
        while(delivered<P) begin
            @(negedge clk);
            random_state={random_state[30:0],random_state[31]^random_state[21]^random_state[1]^random_state[0]};
            target_now=(target_phase==1&&dut.phase==2&&dut.pending==1&&dut.pending_q==W/2-1)
                ||(target_phase==2&&dut.phase==2&&dut.replay_q==0)
                ||(target_phase==3&&dut.phase==3&&dut.replay_q==0)
                ||(target_phase==4&&dut.phase==4);
            if(target_phase!=0&&target_now&&phase_hold<8) begin
                if(!out_valid) $fatal(1,"target stall did not reach occupied output");
                out_ready=0;phase_hold=phase_hold+1;
            end else begin
                out_ready=!random_stalls||random_state[1]||output_stall==8;
                if(out_ready) output_stall=0;else output_stall=output_stall+1;
            end
            if(!pending_input&&p<P&&(!random_stalls||random_state[0]||input_stall==8)) begin
                {in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair}=stimulus[p];in_valid=1;
                pending_input=1;input_stall=0;
            end else if(!pending_input) begin in_valid=0;input_stall=input_stall+1;end
            @(posedge clk);fired=in_valid&&in_ready;#1;if(fired) begin p=p+1;pending_input=0;end
        end
        @(negedge clk);in_valid=0;
        if(!empty||accepted!=P||ram_writes!=P||(target_phase!=0&&phase_hold!=8)) $fatal(1,"Gaussian count/empty/phase missing");
        if(target_phase==0&&!random_stalls&&(first_output-first_input!=W+7||last_output-first_input!=P+W+6))
            $fatal(1,"Gaussian local latency differs first=%0d last=%0d",first_output-first_input,last_output-first_input);
        f=$fopen(result_path,"w");if(!f) $fatal(1,"result open failed");
        $fdisplay(f,"{\"schema\":1,\"case_id\":\"%s\",\"status\":\"PASS\",\"accepted_pairs\":%0d,\"compared_pairs\":%0d,\"numeric_errors\":0,\"protocol_errors\":0,\"hold_checks\":%0d,\"ram_reads\":%0d,\"ram_writes\":%0d,\"ram_range_errors\":0,\"ram_collisions\":0,\"phase_hold_cycles\":%0d,\"first_output_cycle\":%0d,\"last_output_cycle\":%0d,\"cycles\":%0d,\"finished\":true}",case_id,accepted,delivered,hold_checks,ram_reads,ram_writes,phase_hold,first_output-first_input,last_output-first_input,cycles);
        $fclose(f);finished=1;$finish;
    end
endmodule
