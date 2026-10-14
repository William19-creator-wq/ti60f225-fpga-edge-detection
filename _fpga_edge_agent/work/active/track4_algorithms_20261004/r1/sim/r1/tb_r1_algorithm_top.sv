`timescale 1ns/1ps
// Python黄金文件是唯一CRC/图像oracle；本包只严格解码文件，不计算CRC。
package r1_tb_text;
    function automatic [159:0] read_hex(input integer fd,input integer digits);
        string line; integer got,i,c,d,n; reg [159:0] value;
        begin
            got=$fgets(line,fd); n=line.len();
            if(got==0) $fatal(1,"Missing required golden vector");
            if(n>0 && line.getc(n-1)==10) n=n-1;
            if(n>0 && line.getc(n-1)==13) n=n-1;
            if(n!=digits) $fatal(1,"Golden vector wrong length");
            value=0;
            for(i=0;i<n;i=i+1) begin
                c=line.getc(i);
                if(c>=48 && c<=57) d=c-48;
                else if(c>=97 && c<=102) d=c-87;
                else begin $fatal(1,"Noncanonical/X/Z golden hex");d=0;end
                value=(value<<4)|d;
            end
            read_hex=value;
        end
    endfunction
    task automatic require_eof(input integer fd);
        string line; integer got;
        begin got=$fgets(line,fd); if(got!=0) $fatal(1,"Extra golden vector"); end
    endtask
endpackage

module tb_r1_algorithm_top;
    import r1_tb_text::*;
    parameter integer W=4,H=3;
    localparam integer N=W*H/2;
    reg clk=0,key1_n=0,finished=0; wire led0,led1;
    always #20 clk=~clk;
    r1_algorithm_top #(.W(W),.H(H)) dut(.clk_25m(clk),.key1_n(key1_n),.led0(led0),.led1(led1));
    integer rf,cf,result_fd,cycles=0,records=0,crc_checks=0,jobs=0,pairs=0;
    integer shift_count=0,job_records=0,reset_count=0,max_cycles=1000000;
    reg pending=0,is_terminal=0,old_busy,old_rst;
    reg [31:0] expected_crc,capture_crc;
    reg [159:0] expected_record,actual_record,old_record;
    reg [63:0] completed_ids=0;
    string rp,cp,result_path;
    initial begin
        if($test$plusargs("FAIL_PROBE")) $fatal(1,"Deliberate runner fatal-exit probe");
        if(!$value$plusargs("RECORDS=%s",rp) || !$value$plusargs("CRC=%s",cp) ||
           !$value$plusargs("RESULT=%s",result_path)) $fatal(1,"Missing fixture arguments");
        rf=$fopen(rp,"r");cf=$fopen(cp,"r");
        if(!rf || !cf) $fatal(1,"Cannot open complete golden files");
        repeat(4) @(posedge clk); @(negedge clk) key1_n=1;
        // 先完成pattern1的k4，再在k5真实CRC忙时reset；旧RAM与新k0图不同。
        wait(jobs==5 && dut.observer.busy && dut.observer.record_bit_index==150);
        @(negedge clk) begin key1_n=0;reset_count=reset_count+1;end
        repeat(4) @(posedge clk);
        @(negedge clk) begin
            if(dut.last_result_valid!==0 || led0!==0 || led1!==0) $fatal(1,"Reset did not clear old result");
            key1_n=1;
        end
    end
    always @(posedge clk) begin
        cycles=cycles+1;
        if(cycles>max_cycles) $fatal(1,"Bounded R1 top timeout");
        old_busy=dut.observer.busy;old_rst=dut.rst;
        if(old_rst) begin pending=0;shift_count=0;job_records=0;end
        else begin
            if(dut.job_start) begin
                if(dut.job_frame_id==0) begin
                    if($fseek(rf,0,0)!=0 || $fseek(cf,0,0)!=0) $fatal(1,"Fixture rewind failed");
                end
                if(pending) $fatal(1,"New job while old record pending");
                job_records=0;
            end
            if(dut.out_valid && dut.status_valid) $fatal(1,"FO/FS overlap");
            if((dut.out_valid && dut.out_ready) || (dut.status_valid && dut.status_ready)) begin
                if(pending) $fatal(1,"Overwrote held CRC record");
                is_terminal=dut.status_valid;
                if(is_terminal) begin
                    actual_record={19'b0,dut.status_config_id,dut.status_frame_id,dut.status_epoch,
                                   dut.status_out_pairs,dut.status_in_pairs,dut.status_code};
                    if(dut.status_error_x!==0 || dut.status_error_y!==0) $fatal(1,"Normal diagnostic coordinate nonzero");
                end else begin
                    actual_record={21'b0,dut.out_eof,dut.out_eol,dut.out_sof,dut.out_config_id,dut.out_frame_id,
                                   dut.out_epoch,dut.out_y,dut.out_x_even,dut.out_edge,dut.out_y_filtered};
                    pairs=pairs+1;
                end
                expected_record=read_hex(rf,40);expected_crc=read_hex(cf,8);
                if(actual_record!==expected_record) $fatal(1,"Independent 160bit record mismatch");
                capture_crc=dut.observer.crc_state;old_record=expected_record;
                pending=1;shift_count=0;records=records+1;job_records=job_records+1;
                #1;
                if(dut.observer.record_hold!==expected_record || dut.observer.record_bit_index!==159 ||
                   dut.observer.crc_state!==capture_crc) $fatal(1,"Record capture/first-bit boundary wrong");
            end else if(old_busy) begin
                if(!pending || dut.observer.record_hold!==old_record) $fatal(1,"Lost record identity");
                shift_count=shift_count+1;
                if(dut.observer.record_bit_index==0) begin
                    #1;
                    if(shift_count!=160 || dut.observer.crc_state!==expected_crc) $fatal(1,"Independent record CRC mismatch");
                    pending=0;crc_checks=crc_checks+1;
                    if(is_terminal) begin
                        if(job_records!=N+1 || dut.last_crc!==(expected_crc^32'hffffffff) ||
                           dut.last_good!==1 || dut.last_status!==0 || dut.last_in_pairs!==N ||
                           dut.last_out_pairs!==N || dut.last_data_pairs!==N || led0!==1)
                            $fatal(1,"Terminal/LED snapshot mismatch");
                        completed_ids[dut.last_frame_id]=1;jobs=jobs+1;
                        if(jobs==69) begin
                            if(completed_ids!==64'hffffffffffffffff || reset_count!=1 ||
                               records!=69*(N+1)+1 || crc_checks!=69*(N+1) || pairs!=69*N+1)
                                $fatal(1,"Incomplete job/reset/record coverage");
                            require_eof(rf);require_eof(cf);
                            result_fd=$fopen(result_path,"w");if(!result_fd) $fatal(1,"Result write failed");
                            $fdisplay(result_fd,"{\"finished\":true,\"jobs_completed\":%0d,\"unique_jobs\":64,\"data_pairs_compared\":%0d,\"records_compared\":%0d,\"record_crc_checks\":%0d,\"reset_count\":%0d,\"numeric_errors\":0,\"protocol_errors\":0,\"cycles\":%0d}",jobs,pairs,records,crc_checks,reset_count,cycles);
                            $fclose(result_fd);finished=1;$finish;
                        end
                    end
                end
            end
        end
    end
endmodule
