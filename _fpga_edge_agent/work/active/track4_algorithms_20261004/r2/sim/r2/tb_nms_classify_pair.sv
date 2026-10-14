// U-NC001…024：直接二维参考的fixture窗口，逐pair核125bit结果。
module tb_nms_classify_pair;
    logic clk=0; always #5 clk=~clk;
    logic rst=1,frame_start=0,data_flush=0,in_valid=0,out_ready=0;
    wire in_ready,out_valid,empty;
    logic [287:0] in_window_pair;
    logic [10:0] threshold_low,threshold_high,in_x_even,in_y;
    logic in_sof,in_eol,in_eof;
    wire [3:0] out_class_pair;
    wire [10:0] out_x_even,out_y;
    wire out_sof,out_eol,out_eof;
    logic [95:0] job_ids;
    logic [408:0] stimulus[0:23];logic [124:0] expected[0:23];
    wire [124:0] actual={out_eof,out_eol,out_sof,job_ids,out_y,out_x_even,out_class_pair};
    logic [124:0] held_output;logic [408:0] held_input;
    logic output_held=0,input_held=0,finished=0;
    integer delivered=0,accepted=0,hold_checks=0,strong_pixels=0,weak_pixels=0;
    integer cycles=0,eof_stall=0,input_stall=0,output_stall=0;
    logic [31:0] random_state=32'h431;
    string input_path,expected_path,result_path,case_id;
    integer tl,th;
    nms_classify_pair #(.W(8),.H(6)) dut(.*);
    always @(posedge clk) begin : observe
        cycles=cycles+1;if(cycles>20000) $fatal(1,"NMS timeout");
        if(rst || frame_start || data_flush) begin output_held=0;input_held=0;end
        else begin
            if(output_held) begin
                if(!out_valid || actual!==held_output) $fatal(1,"NMS stalled output changed");
                hold_checks=hold_checks+1;
            end
            if(input_held) begin
                if(!in_valid || {in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_window_pair}!==held_input)
                    $fatal(1,"held input changed");
                hold_checks=hold_checks+1;
            end
            output_held=out_valid&&!out_ready;held_output=actual;
            input_held=in_valid&&!in_ready;
            held_input={in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_window_pair};
            if(in_valid&&in_ready) accepted=accepted+1;
            if(out_valid&&out_ready) begin
                if(delivered>=24 || actual!==expected[delivered])
                    $fatal(1,"NMS class/metadata mismatch at %0d",delivered);
                for(integer lane=0;lane<2;lane=lane+1) begin
                    if(out_class_pair[lane*2 +: 2]==2'b10) strong_pixels=strong_pixels+1;
                    if(out_class_pair[lane*2 +: 2]==2'b01) weak_pixels=weak_pixels+1;
                    if(out_class_pair[lane*2 +: 2]==2'b11) $fatal(1,"illegal class11");
                end
                delivered=delivered+1;
            end
        end
    end
    initial begin : run_case
        integer p,f;logic pending,fired;
        if(!$value$plusargs("IN=%s",input_path) || !$value$plusargs("EXPECTED=%s",expected_path)
            || !$value$plusargs("RESULT=%s",result_path) || !$value$plusargs("CASE=%s",case_id)
            || !$value$plusargs("TL=%d",tl) || !$value$plusargs("TH=%d",th))
            $fatal(1,"missing NMS args");
        threshold_low=tl;threshold_high=th;
        $readmemh(input_path,stimulus);$readmemh(expected_path,expected);
        job_ids=stimulus[0][310 +: 96];
        repeat(4) @(negedge clk);rst=0;frame_start=1;
        @(negedge clk);frame_start=0;p=0;pending=0;
        while(delivered<24) begin
            @(negedge clk);
            random_state={random_state[30:0],random_state[31]^random_state[21]^random_state[1]^random_state[0]};
            if(out_valid&&out_eof&&eof_stall<8) begin
                out_ready=0;eof_stall=eof_stall+1;
            end else begin
                out_ready=random_state[1] || output_stall==8;
                if(out_ready) output_stall=0;else output_stall=output_stall+1;
            end
            if(!pending && p<24 && (random_state[0] || input_stall==8)) begin
                {in_eof,in_eol,in_sof,job_ids,in_y,in_x_even,in_window_pair}=stimulus[p];
                in_valid=1;pending=1;input_stall=0;
            end else if(!pending) begin in_valid=0;input_stall=input_stall+1;end
            @(posedge clk);fired=in_valid&&in_ready;
            #1;if(fired) begin p=p+1;pending=0;end
        end
        @(negedge clk);in_valid=0;
        if(!empty || accepted!=24 || eof_stall!=8) $fatal(1,"missing NMS completion/EOF hold");
        f=$fopen(result_path,"w");if(!f) $fatal(1,"result open failed");
        $fdisplay(f,"{\"schema\":1,\"case_id\":\"%s\",\"status\":\"PASS\",\"accepted_pairs\":%0d,\"compared_pairs\":%0d,\"strong_pixels\":%0d,\"weak_pixels\":%0d,\"numeric_errors\":0,\"protocol_errors\":0,\"hold_checks\":%0d,\"eof_hold_cycles\":%0d,\"cycles\":%0d,\"finished\":true}",case_id,accepted,delivered,strong_pixels,weak_pixels,hold_checks,eof_stall,cycles);
        $fclose(f);finished=1;$finish;
    end
endmodule
