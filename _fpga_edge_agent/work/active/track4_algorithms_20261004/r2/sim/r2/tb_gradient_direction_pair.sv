// U-D001…049：黄金由Python生成；TB只观察真实fire，不由DUT算期望。
module tb_gradient_direction_pair;
    logic clk=0; always #5 clk=~clk;
    logic rst=1, frame_start=0, data_flush=0, in_valid=0, out_ready=0, err_ready=0;
    wire in_ready,out_valid,err_valid,empty;
    logic [65:0] in_pair;
    logic [10:0] in_x_even,in_y;
    logic in_sof,in_eol,in_eof;
    logic [95:0] job_ids;
    wire [69:0] out_pair;
    wire [10:0] out_x_even,out_y;
    wire out_sof,out_eol,out_eof;
    wire [119:0] err_payload;
    logic [186:0] stimulus [0:19];
    logic [190:0] expected [0:19];
    logic [119:0] expected_error [0:0];
    wire [190:0] actual={out_eof,out_eol,out_sof,job_ids,out_y,out_x_even,out_pair};
    logic [190:0] held_output;
    logic [186:0] held_input;
    logic [119:0] held_error;
    logic output_held=0,input_held=0,error_held=0;
    logic finished=0;
    integer output_index=0,accepted=0,compared=0,cycles=0,hold_checks=0;
    integer err_checks=0,recoveries=0,flush_hits=0,error_hold_cycles=0;
    integer bad=0,flush_error=0,limit_pairs=20;
    logic [31:0] random_state=32'h431;
    integer input_stall=0,output_stall=0;
    string input_path,expected_path,error_path,recovery_input,recovery_expected;
    string result_path,case_id;
    logic [95:0] recovery_ids;
    gradient_direction_pair dut(.*);

    always @(posedge clk) begin : observe
        cycles=cycles+1;
        if(cycles>20000) $fatal(1,"direction timeout");
        if(rst || frame_start || data_flush) begin
            output_held=0;input_held=0;
        end else begin
            if(output_held) begin
                if(!out_valid || actual!==held_output) $fatal(1,"output changed while stalled");
                hold_checks=hold_checks+1;
            end
            if(input_held) begin
                if(!in_valid || {in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair}!==held_input)
                    $fatal(1,"driver changed held input");
                hold_checks=hold_checks+1;
            end
            output_held=out_valid&&!out_ready;
            held_output=actual;
            input_held=in_valid&&!in_ready;
            held_input={in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair};
        end
        // 错误的保持检查不受data_flush/frame_start影响。
        if(rst) error_held=0;
        else begin
            if(error_held) begin
                if(!err_valid || err_payload!==held_error) $fatal(1,"held DERR lost");
                hold_checks=hold_checks+1;
            end
            error_held=err_valid&&!err_ready;
            held_error=err_payload;
            if(err_valid) begin
                if(err_payload!==expected_error[0]) $fatal(1,"DERR bits/IDs/location differ");
                if(in_ready) $fatal(1,"new D1 allowed while error slot occupied");
                if(!err_ready) error_hold_cycles=error_hold_cycles+1;
            end
            if(err_valid&&err_ready) err_checks=err_checks+1;
            if(out_valid&&out_ready) begin
                if(output_index>=limit_pairs || actual!==expected[output_index])
                    $fatal(1,"direction numeric/metadata mismatch at %0d",output_index);
                output_index=output_index+1;compared=compared+1;
            end
            if(in_valid&&in_ready) accepted=accepted+1;
        end
    end

    task automatic begin_frame;
        begin
            @(negedge clk);frame_start=1;in_valid=0;out_ready=1;err_ready=0;
            @(negedge clk);frame_start=0;output_index=0;input_stall=0;output_stall=0;
        end
    endtask

    task automatic send_image(input integer count);
        integer p;logic pending;logic fired;
        begin
            p=0;pending=0;
            while(p<count) begin
                @(negedge clk);
                random_state={random_state[30:0],random_state[31]^random_state[21]^random_state[1]^random_state[0]};
                out_ready=(random_state[1] || output_stall==8);
                if(out_ready) output_stall=0;else output_stall=output_stall+1;
                if(!pending && (random_state[0] || input_stall==8)) begin
                    {in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair}=stimulus[p];
                    in_valid=1;pending=1;input_stall=0;
                end else if(!pending) begin in_valid=0;input_stall=input_stall+1;end
                @(posedge clk);fired=in_valid&&in_ready;
                #1;if(fired) begin p=p+1;pending=0;end
            end
            @(negedge clk);in_valid=0;out_ready=1;
        end
    endtask

    initial begin : run_case
        integer f;
        if(!$value$plusargs("IN=%s",input_path) || !$value$plusargs("EXPECTED=%s",expected_path)
            || !$value$plusargs("RESULT=%s",result_path) || !$value$plusargs("CASE=%s",case_id))
            $fatal(1,"missing vector/result args");
        if($value$plusargs("BAD=%d",bad)) begin end
        if($value$plusargs("FLUSH_ERROR=%d",flush_error)) begin end
        $readmemh(input_path,stimulus);$readmemh(expected_path,expected);
        if(bad) begin
            if(!$value$plusargs("ERROR=%s",error_path) || !$value$plusargs("RECOVERY_IN=%s",recovery_input)
                || !$value$plusargs("RECOVERY_EXPECTED=%s",recovery_expected)
                || !$value$plusargs("RECOVERY_IDS=%h",recovery_ids)) $fatal(1,"missing recovery args");
            $readmemh(error_path,expected_error);
        end
        job_ids=stimulus[0][88 +: 96];
        repeat(4) @(negedge clk);rst=0;
        begin_frame();
        limit_pairs=bad?4:20;
        send_image(bad?5:20);
        if(bad) begin
            if(!err_valid) $fatal(1,"bad D1 did not create DERR");
            // 先排空旧合法前缀，再在错误槽持有期间flush，避免假设未交付后缀存在。
            wait(output_index==4);
            repeat(8) @(negedge clk);
            if(flush_error) begin
                data_flush=1;flush_hits=flush_hits+1;
                @(negedge clk);data_flush=0;
                if(!err_valid) $fatal(1,"flush erased error slot");
            end
            err_ready=1;@(negedge clk);err_ready=0;
            if(err_valid || !empty) $fatal(1,"error drain did not empty");
            $readmemh(recovery_input,stimulus);$readmemh(recovery_expected,expected);
            job_ids=recovery_ids;limit_pairs=20;recoveries=1;
            begin_frame();send_image(20);
        end
        wait(output_index==20);@(negedge clk);
        if(!empty || err_valid || err_checks!=bad || (bad && error_hold_cycles<8))
            $fatal(1,"wrong completion/error coverage");
        f=$fopen(result_path,"w");if(!f) $fatal(1,"result open failed");
        $fdisplay(f,"{\"schema\":1,\"case_id\":\"%s\",\"status\":\"PASS\",\"accepted_pairs\":%0d,\"compared_pairs\":%0d,\"numeric_errors\":0,\"protocol_errors\":0,\"error_checks\":%0d,\"error_hold_cycles\":%0d,\"hold_checks\":%0d,\"recoveries\":%0d,\"flush_hits\":%0d,\"cycles\":%0d,\"finished\":true}",case_id,accepted,compared,err_checks,error_hold_cycles,hold_checks,recoveries,flush_hits,cycles);
        $fclose(f);finished=1;$finish;
    end
endmodule
