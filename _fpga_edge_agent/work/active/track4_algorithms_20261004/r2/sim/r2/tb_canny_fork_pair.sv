// U-F001…006：分别计两个真实交付；flush旧fire计入，恢复换新身份。
module tb_canny_fork_pair;
    logic clk=0;always #5 clk=~clk;
    logic rst=1,frame_start=0,data_flush=0,retain_grad=1,in_valid=0,n_ready=0,grad_ready=0;
    wire in_ready,n_valid,grad_valid,empty;
    logic [69:0] in_pair;logic [10:0] in_x_even,in_y;logic in_sof,in_eol,in_eof;
    wire [31:0] n_pair;wire [63:0] grad_pair;
    wire [10:0] n_x_even,n_y,grad_x_even,grad_y;
    wire n_sof,n_eol,n_eof,grad_sof,grad_eol,grad_eof;
    logic [95:0] job_ids;
    logic [190:0] stimulus[0:19];logic [152:0] expected_n[0:19];
    logic [184:0] expected_grad[0:19];
    wire [152:0] actual_n={n_eof,n_eol,n_sof,job_ids,n_y,n_x_even,n_pair};
    wire [184:0] actual_grad={grad_eof,grad_eol,grad_sof,job_ids,grad_y,grad_x_even,grad_pair};
    logic [152:0] held_n;logic [184:0] held_grad;logic [190:0] held_input;
    logic n_held=0,grad_held=0,input_held=0,finished=0;
    integer ni=0,gi=0,total_n=0,total_grad=0,accepted=0,cycles=0,hold_checks=0;
    integer schedule,simultaneous_replace=0,flush_hits=0,recoveries=0;
    integer n_stall=0,grad_stall=0;
    string input_path,n_path,grad_path,result_path,case_id,restore_input,restore_n,restore_grad;
    canny_fork_pair dut(.*);
    always @(posedge clk) begin : observe
        cycles=cycles+1;if(cycles>20000) $fatal(1,"fork timeout");
        if(!rst) begin
            // flush这一沿之前成立的旧fire仍是实际交付。
            if(n_valid&&n_ready) begin
                if(ni>=20 || actual_n!==expected_n[ni]) $fatal(1,"N branch mismatch/duplicate %0d",ni);
                ni=ni+1;total_n=total_n+1;
            end
            if(grad_valid&&grad_ready) begin
                if(gi>=20 || actual_grad!==expected_grad[gi]) $fatal(1,"G branch mismatch/duplicate %0d",gi);
                gi=gi+1;total_grad=total_grad+1;
            end
            if(in_valid&&in_ready) begin
                accepted=accepted+1;
                if(n_valid&&n_ready&&(!retain_grad || grad_valid&&grad_ready))
                    simultaneous_replace=simultaneous_replace+1;
            end
            if(!retain_grad&&grad_valid) $fatal(1,"disabled grad branch active");
        end
        if(rst||frame_start||data_flush) begin n_held=0;grad_held=0;input_held=0;end
        else begin
            if(n_held) begin
                if(!n_valid || actual_n!==held_n) $fatal(1,"N held changed");
                hold_checks=hold_checks+1;
            end
            if(grad_held) begin
                if(!grad_valid || actual_grad!==held_grad) $fatal(1,"G held changed");
                hold_checks=hold_checks+1;
            end
            if(input_held) begin
                if(!in_valid || {in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair}!==held_input)
                    $fatal(1,"driver input changed");
                hold_checks=hold_checks+1;
            end
            n_held=n_valid&&!n_ready;held_n=actual_n;
            grad_held=grad_valid&&!grad_ready;held_grad=actual_grad;
            input_held=in_valid&&!in_ready;
            held_input={in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair};
        end
    end
    task automatic begin_frame;
        begin
            @(negedge clk);frame_start=1;in_valid=0;n_ready=0;grad_ready=0;
            @(negedge clk);frame_start=0;ni=0;gi=0;
        end
    endtask
    task automatic send_image(input integer mode);
        integer p;logic fired;
        begin
            p=0;
            while(p<20) begin
                @(negedge clk);
                {in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_pair}=stimulus[p];in_valid=1;
                case(mode)
                    2: begin n_ready=1;grad_ready=ni>gi;end
                    3: begin grad_ready=1;n_ready=gi>ni;end
                    4: begin
                        n_ready=n_stall==8;grad_ready=grad_stall==8;
                        if(n_valid&&!n_ready) n_stall=n_stall+1;else if(n_ready) n_stall=0;
                        if(grad_valid&&!grad_ready) grad_stall=grad_stall+1;else if(grad_ready) grad_stall=0;
                    end
                    6: begin n_ready=1;grad_ready=0;end
                    default: begin n_ready=1;grad_ready=1;end
                endcase
                @(posedge clk);fired=in_valid&&in_ready;#1;if(fired) p=p+1;
            end
            @(negedge clk);in_valid=0;
            if(mode==4) begin
                n_ready=1;grad_ready=0;data_flush=1;flush_hits=1;
                @(negedge clk);data_flush=0;
                if(!empty || ni!=20 || gi!=19) $fatal(1,"flush old-prefix accounting wrong");
            end else begin
                n_ready=1;grad_ready=retain_grad;
                wait(ni==20 && (retain_grad?gi==20:gi==0));@(negedge clk);
                if(!empty) $fatal(1,"fork not empty");
            end
        end
    endtask
    initial begin : run_case
        integer f;
        if(!$value$plusargs("IN=%s",input_path) || !$value$plusargs("NEXPECTED=%s",n_path)
            || !$value$plusargs("GEXPECTED=%s",grad_path) || !$value$plusargs("SCHEDULE=%d",schedule)
            || !$value$plusargs("RESULT=%s",result_path) || !$value$plusargs("CASE=%s",case_id))
            $fatal(1,"missing fork args");
        $readmemh(input_path,stimulus);$readmemh(n_path,expected_n);$readmemh(grad_path,expected_grad);
        job_ids=stimulus[0][92 +: 96];retain_grad=schedule!=6;
        repeat(4) @(negedge clk);rst=0;begin_frame();send_image(schedule);
        if(schedule==4) begin
            if(!$value$plusargs("RECOVERY_IN=%s",restore_input) || !$value$plusargs("RECOVERY_N=%s",restore_n)
                || !$value$plusargs("RECOVERY_G=%s",restore_grad)) $fatal(1,"missing fork recovery");
            $readmemh(restore_input,stimulus);$readmemh(restore_n,expected_n);$readmemh(restore_grad,expected_grad);
            job_ids=stimulus[0][92 +: 96];recoveries=1;begin_frame();send_image(1);
        end
        if(schedule==5 && simultaneous_replace<19) $fatal(1,"no same-edge replacement coverage");
        if(schedule==4 && hold_checks<16) $fatal(1,"no branch stall coverage");
        f=$fopen(result_path,"w");if(!f) $fatal(1,"result open failed");
        $fdisplay(f,"{\"schema\":1,\"case_id\":\"%s\",\"status\":\"PASS\",\"accepted_pairs\":%0d,\"compared_pairs\":%0d,\"grad_compared_pairs\":%0d,\"numeric_errors\":0,\"protocol_errors\":0,\"hold_checks\":%0d,\"simultaneous_replace\":%0d,\"flush_hits\":%0d,\"recoveries\":%0d,\"cycles\":%0d,\"finished\":true}",case_id,accepted,total_n,total_grad,hold_checks,simultaneous_replace,flush_hits,recoveries,cycles);
        $fclose(f);finished=1;$finish;
    end
endmodule
