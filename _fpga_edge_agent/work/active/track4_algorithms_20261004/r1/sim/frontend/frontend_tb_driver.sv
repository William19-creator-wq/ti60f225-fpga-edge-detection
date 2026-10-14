`timescale 1ns/1ps
// FE F1/G：黄金文件只提供数值；真实fire、身份、保持、故障与恢复另行检查。
module frontend_tb_driver #(parameter integer K=1, W=4, H=3);
    localparam integer D=W/2, N=D*H;
    reg clk=0; always #5 clk=~clk;
    reg rst=1, frame_start=0, flush=0, in_valid=0, out_ready=0, cancel=0;
    reg job_valid=0, status_ready=0;
    wire in_ready, out_valid, empty, job_ready, status_valid;
    reg [47:0] in_rgb=0;
    reg [143:0] in_window_pair=0;
    reg [15:0] in_y_pair=0;
    reg [10:0] in_x_even=0,in_y=0;
    reg in_sof=0,in_eol=0,in_eof=0,in_bad=0;
    reg [31:0] job_epoch=0,job_frame_id=0,job_config_id=0;
    reg median_enable=0; reg [1:0] output_kind=0; reg [10:0] threshold=0;
    wire [15:0] out_y_pair; wire [143:0] out_window_pair;
    wire [1:0] out_edge; wire [21:0] out_gx_pair,out_gy_pair,out_l1_pair;
    wire [10:0] out_x_even,out_y,status_error_x,status_error_y;
    wire out_sof,out_eol,out_eof;
    wire [31:0] out_epoch,out_frame_id,out_config_id,status_epoch,status_frame_id,status_config_id;
    wire [2:0] status_code; wire [20:0] status_in_pairs,status_out_pairs;
    wire [143:0] actual_value;
    generate
    if(K==1) begin:g_gray
        rgb_to_y_pair dut(.clk(clk),.rst(rst),.frame_start(frame_start),.flush(flush),
          .in_valid(in_valid),.in_ready(in_ready),.in_rgb(in_rgb),.in_x_even(in_x_even),.in_y(in_y),
          .in_sof(in_sof),.in_eol(in_eol),.in_eof(in_eof),.out_valid(out_valid),.out_ready(out_ready),
          .out_y_pair(out_y_pair),.out_x_even(out_x_even),.out_y(out_y),
          .out_sof(out_sof),.out_eol(out_eol),.out_eof(out_eof),.empty(empty));
        assign actual_value={128'b0,out_y_pair};
    end else if(K==2) begin:g_median
        median9_pair dut(.clk(clk),.rst(rst),.frame_start(frame_start),.flush(flush),
          .median_enable(median_enable),.in_valid(in_valid),.in_ready(in_ready),.in_window_pair(in_window_pair),
          .in_x_even(in_x_even),.in_y(in_y),.in_sof(in_sof),.in_eol(in_eol),.in_eof(in_eof),
          .out_valid(out_valid),.out_ready(out_ready),.out_y_pair(out_y_pair),
          .out_x_even(out_x_even),.out_y(out_y),.out_sof(out_sof),.out_eol(out_eol),.out_eof(out_eof),.empty(empty));
        assign actual_value={128'b0,out_y_pair};
    end else if(K==3) begin:g_sobel
        sobel_pair dut(.clk(clk),.rst(rst),.frame_start(frame_start),.flush(flush),
          .output_kind(output_kind),.threshold(threshold),.in_valid(in_valid),.in_ready(in_ready),
          .in_window_pair(in_window_pair),.in_x_even(in_x_even),.in_y(in_y),
          .in_sof(in_sof),.in_eol(in_eol),.in_eof(in_eof),.out_valid(out_valid),.out_ready(out_ready),
          .out_y_pair(out_y_pair),.out_edge(out_edge),.out_gx_pair(out_gx_pair),.out_gy_pair(out_gy_pair),
          .out_l1_pair(out_l1_pair),.out_x_even(out_x_even),.out_y(out_y),
          .out_sof(out_sof),.out_eol(out_eol),.out_eof(out_eof),.empty(empty));
        assign actual_value={60'b0,out_l1_pair,out_gy_pair,out_gx_pair,out_edge,out_y_pair};
    end else if(K==4) begin:g_window
        window3x3_pair #(.W(W),.H(H)) dut(.clk(clk),.rst(rst),.frame_start(frame_start),.flush(flush),
          .in_valid(in_valid),.in_ready(in_ready),.in_y_pair(in_y_pair),.in_x_even(in_x_even),.in_y(in_y),
          .in_sof(in_sof),.in_eol(in_eol),.in_eof(in_eof),.out_valid(out_valid),.out_ready(out_ready),
          .out_window_pair(out_window_pair),.out_x_even(out_x_even),.out_y(out_y),
          .out_sof(out_sof),.out_eol(out_eol),.out_eof(out_eof),.empty(empty));
        assign actual_value=out_window_pair;
    end else begin:g_frontend
        frontend_frame_pair #(.W(W),.H(H)) dut(.clk(clk),.rst(rst),.job_valid(job_valid),.job_ready(job_ready),
          .job_epoch(job_epoch),.job_frame_id(job_frame_id),.job_config_id(job_config_id),
          .job_median_enable(median_enable),.job_output_kind(output_kind),.job_threshold(threshold),
          .in_valid(in_valid),.in_ready(in_ready),.in_rgb(in_rgb),.in_x_even(in_x_even),.in_y(in_y),
          .in_sof(in_sof),.in_eol(in_eol),.in_eof(in_eof),.in_bad(in_bad),.out_valid(out_valid),.out_ready(out_ready),
          .out_y_filtered(out_y_pair),.out_edge(out_edge),.out_x_even(out_x_even),.out_y(out_y),
          .out_sof(out_sof),.out_eol(out_eol),.out_eof(out_eof),.out_epoch(out_epoch),
          .out_frame_id(out_frame_id),.out_config_id(out_config_id),.cancel(cancel),
          .status_valid(status_valid),.status_ready(status_ready),.status_code(status_code),
          .status_epoch(status_epoch),.status_frame_id(status_frame_id),.status_config_id(status_config_id),
          .status_in_pairs(status_in_pairs),.status_out_pairs(status_out_pairs),
          .status_error_x(status_error_x),.status_error_y(status_error_y));
        assign actual_value={126'b0,out_edge,out_y_pair}; assign empty=1'b0;
    end
    if(K!=5) begin:g_unit_identity
        assign out_epoch=job_epoch; assign out_frame_id=job_frame_id; assign out_config_id=job_config_id;
        assign job_ready=0; assign status_valid=0; assign status_code=0;
        assign status_epoch=0; assign status_frame_id=0; assign status_config_id=0;
        assign status_in_pairs=0; assign status_out_pairs=0; assign status_error_x=0; assign status_error_y=0;
    end
    endgenerate

    string case_id,input_path,expected_path,result_path,event_path,scenario_name,follow_input,follow_expected;
    integer input_fd,expected_fd,event_fd,result_fd;
    integer stimulus_pairs,expected_pairs,expected_status,max_cycles,event_count=0,cycles=0,observed_status=-1;
    integer input_digits,expected_digits,input_index=0,output_index=0;
    integer accepted_pairs=0,delivered_pairs=0,compared_pairs=0,numeric_errors=0,protocol_errors=0;
    integer current_accepted=0,current_delivered=0,recovery_compared=0,jobs_completed=0;
    integer bubble_left=0,stall_left=0,status_stall_left=0,reset_left=0;
    integer bubbles=0,stalls=0,status_stalls=0,ram_reads=0,ram_writes=0,injections=0,phase_hits=0;
    integer first_input_cycle=-1,first_output_cycle=-1,last_output_cycle=-1;
    integer random_stalls=0,bubble_age=0,stall_age=0,timing_check=0,follow_up=0;
    integer ev_code[0:255],ev_trigger[0:255],ev_index[0:255],ev_cycles[0:255],ev_field[0:255],ev_value[0:255],ev_when[0:255];
    reg [31:0] ev_epoch[0:255],ev_frame[0:255],ev_config[0:255];
    integer ev_median[0:255],ev_kind[0:255],ev_threshold[0:255];
    reg ev_done[0:255]; reg [31:0] lfsr=32'h431;
    reg [31:0] locked_epoch,locked_frame,locked_config;
    reg original_median; reg [1:0] original_kind; reg [10:0] original_threshold;
    reg [31:0] next_epoch,next_frame,next_config;
    reg next_median; reg [1:0] next_kind; reg [10:0] next_threshold;
    reg active=0,job_accepted=0,stop_input=0,reset_restarted=0,reset_pending=0,done=0;
    reg held_output=0,held_status=0; reg [264:0] output_snapshot;
    reg [162:0] status_snapshot; reg [10:0] expected_error_x=0,expected_error_y=0;
    reg input_fired=0,status_fired=0,job_fired=0,start_fired=0,cancel_fire=0; integer finish_wait=0;
    wire [264:0] output_body={actual_value,out_x_even,out_y,out_sof,out_eol,out_eof,out_epoch,out_frame_id,out_config_id};
    wire [162:0] status_body={status_code,status_epoch,status_frame_id,status_config_id,
      status_in_pairs,status_out_pairs,status_error_x,status_error_y};
    wire [9:1] phase_present;
    wire frontend_all_empty;
    generate if(K==5) begin:g_phase_observers
        assign frontend_all_empty=g_frontend.dut.all_empty;
        assign phase_present[1]=|g_frontend.dut.gray.valid_pipe;
        assign phase_present[2]=g_frontend.dut.window_before_median.read_pending==1 && g_frontend.dut.window_before_median.pending_row==0;
        assign phase_present[3]=|g_frontend.dut.median.valid_pipe;
        assign phase_present[4]=g_frontend.dut.window_before_sobel.read_pending==1 && g_frontend.dut.window_before_sobel.pending_row==0;
        assign phase_present[5]=|g_frontend.dut.sobel.valid_pipe;
        assign phase_present[6]=g_frontend.dut.window_before_median.replay_phase==2;
        assign phase_present[7]=g_frontend.dut.window_before_median.replay_phase==3;
        assign phase_present[8]=g_frontend.dut.window_before_sobel.replay_phase==2;
        assign phase_present[9]=g_frontend.dut.window_before_sobel.replay_phase==3;
    end else begin assign phase_present=0;assign frontend_all_empty=1'b1;end endgenerate

    task write_result(input bit finished,input string reason);
        begin
            result_fd=$fopen(result_path,"w");
            if(result_fd) begin
                $fdisplay(result_fd,"{\"schema_version\":1,\"case_id\":\"%s\",\"status\":%0d,\"accepted_pairs\":%0d,\"delivered_pairs\":%0d,\"compared_pairs\":%0d,\"numeric_errors\":%0d,\"protocol_errors\":%0d,\"finished\":%s,\"cycles\":%0d,\"injections\":%0d,\"phase_hits\":%0d,\"jobs_completed\":%0d,\"recovery_compared_pairs\":%0d,\"bubble_cycles\":%0d,\"stall_cycles\":%0d,\"status_stall_cycles\":%0d,\"ram_reads\":%0d,\"ram_writes\":%0d,\"first_input_cycle\":%0d,\"first_output_cycle\":%0d,\"last_output_cycle\":%0d,\"reason\":\"%s\"}",
                  case_id,observed_status,accepted_pairs,delivered_pairs,compared_pairs,numeric_errors,protocol_errors,
                  finished?"true":"false",cycles,injections,phase_hits,jobs_completed,recovery_compared,bubbles,stalls,status_stalls,
                  ram_reads,ram_writes,first_input_cycle,first_output_cycle,last_output_cycle,reason);
                $fclose(result_fd);
            end
        end
    endtask
    task fail(input string reason,input bit numeric);
        begin
            if(numeric) numeric_errors=numeric_errors+1; else protocol_errors=protocol_errors+1;
            write_result(0,reason); $error("%s index=%0d cycle=%0d: %s",case_id,output_index,cycles,reason);
            $fatal(1,"frontend case failed");
        end
    endtask
    // 不使用readmemh的短文件补值；每行字符/长度和额外EOF都独立检查。
    task read_hex(input integer fd,input integer digits,output reg [143:0] value);
        string line; integer count,j,c,scan;
        begin
            count=$fgets(line,fd); if(count==0) fail("vector ended early",0);
            if(line.len()>0 && line.getc(line.len()-1)==10) line=line.substr(0,line.len()-2);
            if(line.len()>0 && line.getc(line.len()-1)==13) line=line.substr(0,line.len()-2);
            if(line.len()!=digits) fail("wrong hexadecimal line width",0);
            for(j=0;j<line.len();j=j+1) begin
                c=line.getc(j);
                if(!((c>=48 && c<=57)||(c>=97 && c<=102))) fail("noncanonical hexadecimal character",0);
            end
            value=0; scan=$sscanf(line,"%h",value);
            if(scan!=1 || (^value===1'bx)) fail("invalid hexadecimal vector",0);
            if(digits==5 && value[143:18]!=0) fail("frontend high padding nonzero",0);
        end
    endtask
    task require_eof(input integer fd);
        string line; integer count;
        begin count=$fgets(line,fd); if(count!=0) fail("extra vector lines",0); end
    endtask
    task open_vectors(input string stimulus,input string golden);
        begin
            input_fd=$fopen(stimulus,"r"); expected_fd=$fopen(golden,"r");
            if(!input_fd || !expected_fd) fail("cannot open vector file",0);
        end
    endtask
    task begin_job;
        begin
            locked_epoch=job_epoch; locked_frame=job_frame_id; locked_config=job_config_id;
            input_index=0;output_index=0;current_accepted=0;current_delivered=0;stop_input=0;
            in_valid=0;held_output=0;held_status=0;finish_wait=0;job_accepted=0;
            expected_error_x=0;expected_error_y=0;
            job_fired=0;start_fired=0;
            if(K==5) job_valid=1; else frame_start=1;
            active=1;
        end
    endtask
    task prepare_input;
        reg [143:0] value; integer j;
        begin
            read_hex(input_fd,input_digits,value);
            in_rgb=value[47:0];in_y_pair=value[15:0];in_window_pair=value;
            in_x_even=2*(input_index%D);in_y=(input_index/D)%H;
            in_sof=input_index%N==0;in_eol=input_index%D==D-1;in_eof=input_index%N==N-1;in_bad=0;
            for(j=0;j<event_count;j=j+1) if(!ev_done[j] && ev_trigger[j]==0 && ev_index[j]==input_index && ev_code[j]>=3 && ev_code[j]<=5) begin
                if(ev_code[j]==3) begin if(ev_field[j]==0) in_x_even=ev_value[j];else in_y=ev_value[j];end
                if(ev_code[j]==4) case(ev_field[j]) 0:in_sof=ev_value[j];1:in_eol=ev_value[j];2:in_eof=ev_value[j];default:fail("invalid marker field",0);endcase
                if(ev_code[j]==5) in_bad=ev_value[j];
                ev_done[j]=1;injections=injections+1;
            end
            in_valid=1;
        end
    endtask
    task ram_check(input bit rd,input integer ra,input bit wr0,input bit wr1,input integer wa);
        begin
            if(rd) begin ram_reads=ram_reads+2;if(ra<0 || ra>=D) fail("RAM read address outside line",0);end
            if(wr0 || wr1) begin ram_writes=ram_writes+wr0+wr1;if(wa<0 || wa>=D) fail("RAM write address outside line",0);end
            if(rd && (wr0||wr1) && ra==wa) fail("RAM same-address collision",0);
            if((rst || flush || frame_start) && (rd || wr0 || wr1)) fail("RAM operation during clear event",0);
        end
    endtask
    generate
      if(K==4) always @(posedge clk) if(active) ram_check(g_window.dut.rd_en,g_window.dut.rd_addr,
        g_window.dut.recent_wr_en,g_window.dut.older_wr_en,g_window.dut.pending_q);
      if(K==5) always @(posedge clk) if(active) begin
        ram_check(g_frontend.dut.window_before_median.rd_en,g_frontend.dut.window_before_median.rd_addr,
          g_frontend.dut.window_before_median.recent_wr_en,g_frontend.dut.window_before_median.older_wr_en,g_frontend.dut.window_before_median.pending_q);
        ram_check(g_frontend.dut.window_before_sobel.rd_en,g_frontend.dut.window_before_sobel.rd_addr,
          g_frontend.dut.window_before_sobel.recent_wr_en,g_frontend.dut.window_before_sobel.older_wr_en,g_frontend.dut.window_before_sobel.pending_q);
      end
    endgenerate

    // 只在下降沿驱动；pos沿检查的是沿前真实交接，不读取刚更新的NBA结果。
    always @(posedge clk) if(active && !done) begin:check_edge
        reg [143:0] golden; integer expected_x,expected_y;
        cycles=cycles+1; input_fired=0; status_fired=0;job_fired=0;start_fired=frame_start;
        if(cycles>max_cycles) fail("finite cycle timeout",0);
        if(rst) begin
            if(in_ready!==0 || out_valid!==0 || (K==5 && (job_ready!==0 || status_valid!==0))) fail("reset interface not masked",0);
            held_output=0;held_status=0;
        end else begin
            if((^({in_ready,out_valid,out_ready,in_valid})===1'bx)) fail("unknown handshake control",0);
            if(held_output && !cancel && !flush && output_body!==output_snapshot) fail("stalled output changed",0);
            if(held_output && !cancel && !flush && out_valid!==1) fail("stalled output withdrawn",0);
            if(K==5 && held_status && (status_valid!==1 || status_body!==status_snapshot)) fail("stalled status changed",0);
            if(K==5 && job_valid && job_ready) begin
                if(in_ready!==0) fail("first input accepted on job edge",0);
                job_accepted=1;job_fired=1;
            end
            if(in_valid && in_ready) begin
                if((^({in_rgb,in_window_pair,in_y_pair,in_x_even,in_y,in_sof,in_eol,in_eof,in_bad})===1'bx)) fail("unknown accepted input",0);
                accepted_pairs=accepted_pairs+1;current_accepted=current_accepted+1;input_fired=1;
                if(first_input_cycle<0) first_input_cycle=cycles;
                if(K==5 && (in_bad || in_x_even!=2*(input_index%D) || in_y!=input_index/D ||
                  in_sof!=(input_index==0) || in_eol!=(input_index%D==D-1) || in_eof!=(input_index==N-1))) begin
                    expected_error_x=in_x_even;expected_error_y=in_y;stop_input=1;
                end
                input_index=input_index+1;
            end
            if(out_valid && out_ready) begin
                if(first_output_cycle<0) first_output_cycle=cycles;
                last_output_cycle=cycles;current_delivered=current_delivered+1;delivered_pairs=delivered_pairs+1;
                if((^output_body===1'bx)) fail("unknown delivered output",0);
                if(output_index>=expected_pairs) fail("extra delivered output",0);
                read_hex(expected_fd,expected_digits,golden);
                compared_pairs=compared_pairs+1;
                if(reset_restarted || jobs_completed>0) recovery_compared=recovery_compared+1;
                if(actual_value!==golden) fail("numeric mismatch",1);
                expected_x=2*(output_index%D);expected_y=(output_index/D)%H;
                if(out_x_even!=expected_x || out_y!=expected_y || out_sof!=(output_index%N==0) ||
                  out_eol!=(output_index%D==D-1) || out_eof!=(output_index%N==N-1)) fail("output coordinates or markers differ",0);
                if(K==5 && {out_epoch,out_frame_id,out_config_id}!={locked_epoch,locked_frame,locked_config}) fail("output job identity changed",0);
                output_index=output_index+1;
            end
            if(K==5 && status_valid) begin
                stop_input=1;
                if(frontend_all_empty!==1'b1) fail("STATUS before all internal valid/pending/history cleared",0);
                if(out_valid!==0 || in_ready!==0 || job_ready!==0) fail("STATUS overlaps data or job readiness",0);
                if((^status_body===1'bx)) fail("unknown status payload",0);
                if(status_ready) begin
                    if(status_code!=expected_status) fail("unexpected terminal status",0);
                    if({status_epoch,status_frame_id,status_config_id}!={locked_epoch,locked_frame,locked_config}) fail("terminal identity changed",0);
                    if(status_in_pairs!=current_accepted || status_out_pairs!=current_delivered) fail("terminal counts differ from real fires",0);
                    if(expected_status>=2 && expected_status<=4) begin
                        if({status_error_x,status_error_y}!={expected_error_x,expected_error_y}) fail("terminal error location differs",0);
                    end else if({status_error_x,status_error_y}!=0) fail("unexpected terminal location",0);
                    if(expected_status==0 && (current_accepted!=stimulus_pairs || output_index!=expected_pairs)) fail("OK before complete frame",0);
                    if(observed_status<0) observed_status=status_code;
                    status_fired=1;jobs_completed=jobs_completed+1;
                end
            end
            held_output=out_valid && !out_ready;output_snapshot=output_body;
            held_status=K==5 && status_valid && !status_ready;status_snapshot=status_body;
            if(cancel || flush || (K==5 && input_fired && stop_input)) held_output=0;
        end
    end

    always @(negedge clk) if(active && !done) begin:drive_edge
        integer j; reg trigger_event;
        lfsr={lfsr[30:0],lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
        cancel=0;cancel_fire=0;flush=0;
        if(start_fired) frame_start=0;
        if(job_fired) job_valid=0;
        if(reset_left>0) begin rst=1;reset_left=reset_left-1;in_valid=0;out_ready=0;status_ready=0;end
        else if(reset_pending) begin
            rst=0;reset_pending=0;reset_restarted=1;
            $fclose(input_fd);$fclose(expected_fd);open_vectors(input_path,expected_path);
            job_epoch=locked_epoch;job_frame_id=locked_frame;job_config_id=locked_config;
            median_enable=original_median;output_kind=original_kind;threshold=original_threshold;
            expected_status=0;begin_job;
        end else begin
            rst=0;
            if(input_fired) in_valid=0;
            if(status_fired) begin
                in_valid=0;status_ready=0;
                if(follow_up && jobs_completed==1) begin
                    if(expected_status==0) begin require_eof(input_fd);require_eof(expected_fd);end
                    $fclose(input_fd);$fclose(expected_fd);
                    open_vectors(follow_input,follow_expected);
                    job_epoch=next_epoch;job_frame_id=next_frame;job_config_id=next_config;
                    median_enable=next_median;output_kind=next_kind;threshold=next_threshold;
                    expected_status=0;begin_job;
                end else finish_wait=1;
            end
            for(j=0;j<event_count;j=j+1) if(!ev_done[j] && !(ev_code[j]>=3 && ev_code[j]<=5)) begin
                trigger_event=(ev_trigger[j]==0 && input_index==ev_index[j] && (K!=5 || job_accepted)) ||
                  (ev_trigger[j]==1 && output_index==ev_index[j] && out_valid) ||
                  (ev_trigger[j]==2 && K==5 && status_valid) ||
                  (ev_trigger[j]==3 && K==5 && ev_field[j]>=1 && ev_field[j]<=9 && phase_present[ev_field[j]]);
                if(trigger_event) begin
                    ev_done[j]=1;injections=injections+1;
                    if(ev_trigger[j]==3) phase_hits=phase_hits | (1 << (ev_field[j]-1));
                    case(ev_code[j])
                      1:bubble_left=ev_cycles[j];
                      2:stall_left=ev_cycles[j];
                      6:begin cancel=1;stop_input=1;in_valid=0;cancel_fire=ev_when[j]==1;if(cancel_fire) stall_left=0;end
                      7:begin rst=1;reset_left=ev_cycles[j]-1;reset_pending=1;in_valid=0;job_valid=0;end
                      8:begin job_epoch=ev_epoch[j];job_frame_id=ev_frame[j];job_config_id=ev_config[j];
                         median_enable=ev_median[j];output_kind=ev_kind[j];threshold=ev_threshold[j];end
                      9:status_stall_left=ev_cycles[j];
                      default:fail("unsupported declared event",0);
                    endcase
                end
            end
            out_ready=1;status_ready=1;
            if(stall_left>0) begin out_ready=0;stall_left=stall_left-1;stalls=stalls+1;end
            else if(random_stalls && lfsr[1] && stall_age<8) begin out_ready=0;stall_age=stall_age+1;stalls=stalls+1;end
            else stall_age=0;
            if(cancel_fire) out_ready=1; // fire指定场景仍发生真实旧交付；before保留原背压。
            if(status_stall_left>0) begin status_ready=0;status_stall_left=status_stall_left-1;status_stalls=status_stalls+1;end
            if(rst) begin out_ready=0;status_ready=0;end
            if(!rst && !frame_start && !stop_input && !in_valid && input_index<stimulus_pairs && (K!=5 || job_accepted)) begin
                if(bubble_left>0) begin bubble_left=bubble_left-1;bubbles=bubbles+1;end
                else if(random_stalls && lfsr[0] && bubble_age<8) begin bubble_age=bubble_age+1;bubbles=bubbles+1;end
                else begin bubble_age=0;prepare_input;end
            end
            if(K!=5 && input_index==stimulus_pairs && output_index==expected_pairs && empty) finish_wait=1;
            if(finish_wait>0) begin
                for(j=0;j<event_count;j=j+1) if(!ev_done[j]) fail("declared event never executed",0);
                if(expected_status==0 || K!=5) begin require_eof(input_fd);require_eof(expected_fd);end
                if(compared_pairs!=delivered_pairs) fail("uncompared delivered prefix",0);
                if(timing_check && !random_stalls && event_count==0) begin
                    if(K==4 && (first_output_cycle-first_input_cycle!=D+3 || last_output_cycle-first_input_cycle!=N+D+2)) fail("window no-stall latency differs",0);
                    if(K==5 && (first_output_cycle-first_input_cycle!=2*D+24 || last_output_cycle-first_input_cycle!=N+2*D+23)) fail("frontend no-stall latency differs",0);
                    if(K<4 && first_output_cycle-first_input_cycle!=(K==1?3:K==2?9:6)) fail("arithmetic stage latency differs",0);
                end
                done=1;write_result(1,"complete");$display("CASE_FINISHED %s compared=%0d",case_id,compared_pairs);$finish;
            end
        end
    end

    initial begin:setup
        integer got,unused,j; string line,extra;
        if(!$value$plusargs("CASE=%s",case_id) || !$value$plusargs("IN=%s",input_path) ||
          !$value$plusargs("EXPECTED=%s",expected_path) || !$value$plusargs("RESULT=%s",result_path)) $fatal(1,"missing case paths");
        if(!$value$plusargs("PAIRS=%d",stimulus_pairs) || !$value$plusargs("EXPECTED_PAIRS=%d",expected_pairs) ||
          !$value$plusargs("STATUS=%d",expected_status) || !$value$plusargs("MAX_CYCLES=%d",max_cycles)) fail("missing case counts",0);
        unused=$value$plusargs("EPOCH=%d",job_epoch);unused=$value$plusargs("FRAME=%d",job_frame_id);unused=$value$plusargs("CONFIG=%d",job_config_id);
        unused=$value$plusargs("MEDIAN=%d",median_enable);unused=$value$plusargs("KIND=%d",output_kind);unused=$value$plusargs("THRESHOLD=%d",threshold);
        unused=$value$plusargs("SEED=%h",lfsr);unused=$value$plusargs("RANDOM_STALLS=%d",random_stalls);unused=$value$plusargs("TIMING=%d",timing_check);
        original_median=median_enable;original_kind=output_kind;original_threshold=threshold;
        if(lfsr==0 || stimulus_pairs<1 || expected_pairs<1 || max_cycles<10 || W<4 || W%2 || H<3) fail("invalid test parameters",0);
        input_digits=K==1||K==5?12:K==4?4:36;expected_digits=K==1||K==2?4:K==3?21:K==4?36:5;
        open_vectors(input_path,expected_path);
        if($value$plusargs("EVENTS=%s",event_path)) begin
            event_fd=$fopen(event_path,"r");if(!event_fd) fail("cannot open event file",0);
            while($fgets(line,event_fd)) begin
                if(event_count>=256) fail("too many events",0); extra="";
                got=$sscanf(line,"%d %d %d %d %d %d %d %d %d %d %d %d %d %s",
                  ev_code[event_count],ev_trigger[event_count],ev_index[event_count],ev_cycles[event_count],
                  ev_field[event_count],ev_value[event_count],ev_when[event_count],ev_epoch[event_count],
                  ev_frame[event_count],ev_config[event_count],ev_median[event_count],ev_kind[event_count],ev_threshold[event_count],extra);
                if(got!=13) fail("invalid event fields",0);
                ev_done[event_count]=0;event_count=event_count+1;
            end
            $fclose(event_fd);
        end
        unused=$value$plusargs("FOLLOW_UP=%d",follow_up);
        if(follow_up) begin
            if(!$value$plusargs("FOLLOW_IN=%s",follow_input) || !$value$plusargs("FOLLOW_EXPECTED=%s",follow_expected)) fail("missing follow-up vectors",0);
            unused=$value$plusargs("NEXT_EPOCH=%d",next_epoch);unused=$value$plusargs("NEXT_FRAME=%d",next_frame);unused=$value$plusargs("NEXT_CONFIG=%d",next_config);
            unused=$value$plusargs("NEXT_MEDIAN=%d",next_median);unused=$value$plusargs("NEXT_KIND=%d",next_kind);unused=$value$plusargs("NEXT_THRESHOLD=%d",next_threshold);
        end
        repeat(4) @(negedge clk);
        rst=0;begin_job;
    end
endmodule
