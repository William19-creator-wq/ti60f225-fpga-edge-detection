// U-NW：九坐标clamp黄金，不借用RAM状态计算窗口期望。
module tb_nms_window_pair;
    localparam integer W=8,H=6,P=24;
    logic clk=0;always #5 clk=~clk;
    logic rst=1,frame_start=0,data_flush=0,in_valid=0,out_ready=0;
    wire in_ready,out_valid,empty;
    logic [31:0] in_pair;logic [10:0] in_x_even,in_y;logic in_sof,in_eol,in_eof;
    wire [287:0] out_window_pair;wire [10:0] out_x_even,out_y;wire out_sof,out_eol,out_eof;
    logic [95:0] job_ids;logic [152:0] stimulus[0:P-1];logic [408:0] expected[0:P-1];
    wire [408:0] actual={out_eof,out_eol,out_sof,job_ids,out_y,out_x_even,out_window_pair};
    logic [408:0] held_output;logic [152:0] held_input;
    logic output_held=0,input_held=0,ram_held=0,finished=0;
    logic [31:0] held_recent,held_older;
    integer delivered=0,total_compared=0,accepted=0,cycles=0,hold_checks=0,phase_hold=0;
    integer ram_reads=0,ram_writes=0,flush_hits=0,recoveries=0,eof_count=0;
    integer schedule,input_stall=0,output_stall=0;
    logic [31:0] random_state=32'h431;
    string input_path,expected_path,result_path,case_id,restore_input,restore_expected;
    nms_window_pair #(.W(W),.H(H)) dut(.*);
    always @(posedge clk) begin : observe
        cycles=cycles+1;if(cycles>20000) $fatal(1,"NMS window timeout");
        if(!rst) begin
            if(in_valid&&in_ready) accepted=accepted+1;
            if(out_valid&&out_ready) begin
                if(delivered>=P||actual!==expected[delivered]) $fatal(1,"NMS window payload/metadata %0d",delivered);
                delivered=delivered+1;total_compared=total_compared+1;
                if(out_eof) eof_count=eof_count+1;
            end
        end
        if(rst||frame_start||data_flush) begin output_held=0;input_held=0;ram_held=0;end
        else begin
            if(output_held) begin
                if(!out_valid||actual!==held_output) $fatal(1,"NMS window held changed");
                hold_checks=hold_checks+1;
            end
            if(input_held) begin
                if(!in_valid||{in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair}!==held_input)
                    $fatal(1,"NMS source held changed");
                hold_checks=hold_checks+1;
            end
            if(ram_held&&(dut.recent_read!==held_recent||dut.older_read!==held_older))
                $fatal(1,"NMS byte readback changed in stall");
            if(!dut.advance&&(dut.rd_en||dut.recent_wr_en||dut.older_wr_en)) $fatal(1,"NMS RAM enabled while stalled");
            ram_held=!dut.advance;held_recent=dut.recent_read;held_older=dut.older_read;
            if(dut.rd_en) ram_reads=ram_reads+2;
            if(dut.recent_wr_en) ram_writes=ram_writes+1;
            if(dut.older_wr_en) ram_writes=ram_writes+1;
            output_held=out_valid&&!out_ready;held_output=actual;
            input_held=in_valid&&!in_ready;held_input={in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair};
        end
    end
    task automatic run_job(input integer mode);
        integer p;logic pending_input,fired,aborted,target_now;
        begin
            @(negedge clk);frame_start=1;in_valid=0;out_ready=0;
            @(negedge clk);frame_start=0;delivered=0;p=0;pending_input=0;aborted=0;
            while(delivered<P&&!aborted) begin
                @(negedge clk);
                random_state={random_state[30:0],random_state[31]^random_state[21]^random_state[1]^random_state[0]};
                target_now=(mode==2&&dut.phase==2&&dut.pending==1&&dut.pending_q==W/2-1)
                    ||(mode==3&&dut.phase==3&&dut.pending==2&&dut.pending_q==W/2-1)
                    ||(mode==4&&out_valid&&out_eof);
                if(target_now&&phase_hold<8) begin
                    if(!out_valid) $fatal(1,"NMS phase no occupied output");
                    out_ready=0;phase_hold=phase_hold+1;
                end else begin
                    out_ready=mode!=1||random_state[1]||output_stall==8;
                    if(out_ready) output_stall=0;else output_stall=output_stall+1;
                end
                if(!pending_input&&p<P&&(mode!=1||random_state[0]||input_stall==8)) begin
                    {in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair}=stimulus[p];
                    in_valid=1;pending_input=1;input_stall=0;
                end else if(!pending_input) begin in_valid=0;input_stall=input_stall+1;end
                if(mode==5&&delivered>=5&&out_valid) begin
                    data_flush=1;in_valid=0;pending_input=0;out_ready=1;flush_hits=flush_hits+1;
                end
                @(posedge clk);fired=in_valid&&in_ready;#1;
                if(fired) begin p=p+1;pending_input=0;end
                if(data_flush) aborted=1;
            end
            @(negedge clk);in_valid=0;data_flush=0;
            if(!empty) $fatal(1,"NMS local empty missing");
            if(mode>=2&&mode<=4&&phase_hold!=8) $fatal(1,"NMS target phase not covered");
        end
    endtask
    initial begin : run_case
        integer f;
        if(!$value$plusargs("IN=%s",input_path)||!$value$plusargs("EXPECTED=%s",expected_path)
            ||!$value$plusargs("RESULT=%s",result_path)||!$value$plusargs("CASE=%s",case_id)
            ||!$value$plusargs("SCHEDULE=%d",schedule)) $fatal(1,"missing NMS window args");
        $readmemh(input_path,stimulus);$readmemh(expected_path,expected);job_ids=stimulus[0][54 +: 96];
        repeat(4) @(negedge clk);rst=0;run_job(schedule);
        if(schedule==5) begin
            if(!$value$plusargs("RECOVERY_IN=%s",restore_input)||!$value$plusargs("RECOVERY_EXPECTED=%s",restore_expected))
                $fatal(1,"missing window recovery");
            $readmemh(restore_input,stimulus);$readmemh(restore_expected,expected);job_ids=stimulus[0][54 +: 96];
            recoveries=1;run_job(0);
        end
        if(eof_count!=1||delivered!=P||total_compared<(schedule==5?30:24)) $fatal(1,"NMS incomplete comparison");
        f=$fopen(result_path,"w");if(!f) $fatal(1,"result open failed");
        $fdisplay(f,"{\"schema\":1,\"case_id\":\"%s\",\"status\":\"PASS\",\"accepted_pairs\":%0d,\"compared_pairs\":%0d,\"numeric_errors\":0,\"protocol_errors\":0,\"hold_checks\":%0d,\"phase_hold_cycles\":%0d,\"ram_reads\":%0d,\"ram_writes\":%0d,\"ram_collisions\":0,\"ram_range_errors\":0,\"eof_count\":%0d,\"flush_hits\":%0d,\"recoveries\":%0d,\"cycles\":%0d,\"finished\":true}",case_id,accepted,total_compared,hold_checks,phase_hold,ram_reads,ram_writes,eof_count,flush_hits,recoveries,cycles);
        $fclose(f);finished=1;$finish;
    end
endmodule
