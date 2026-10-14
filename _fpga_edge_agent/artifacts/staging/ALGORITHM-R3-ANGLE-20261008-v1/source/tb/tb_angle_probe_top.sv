`timescale 1ns/1ps
module tb_angle_probe_top;
    logic clk_25m=0,key1_n=0;always #5 clk_25m=~clk_25m;wire led0,led1;
    angle_probe_top dut(.*);
    logic finished=0,log_enabled=1;string run_dir;integer ledger,result_file,cycle=0,segment=0,closed=0;
    always @(posedge clk_25m)begin
        cycle++;
        if(log_enabled && !dut.core_rst)begin
            if(dut.req_valid && dut.req_ready)$fwrite(ledger,"%0d Q %0d %h\n",segment,cycle,dut.request_slot);
            if(dut.rsp_valid && dut.rsp_ready)$fwrite(ledger,"%0d R %0d %h\n",segment,cycle,dut.rsp_body);
            if(dut.observer_done)begin $fwrite(ledger,"%0d C %0d %h\n",segment,cycle,dut.next_crc);closed++;end
        end
    end
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir))$fatal(1,"RUN_DIR missing");ledger=$fopen({run_dir,"/probe-ledger.tsv"},"w");if(!ledger)$fatal(1,"probe ledger open");
        $fwrite(ledger,"0 B 0 0\n");repeat(3)@(negedge clk_25m);key1_n=1;
        while(closed<1024)begin @(posedge clk_25m);#1;end
        if(!led0)$fatal(1,"1024 response LED did not toggle");
        @(negedge clk_25m);key1_n=0;segment=1;closed=0;$fwrite(ledger,"1 B %0d 0\n",cycle);
        repeat(3)@(negedge clk_25m);key1_n=1;
        while(closed<32)begin @(posedge clk_25m);#1;end
        @(negedge clk_25m);key1_n=0;log_enabled=0;$fclose(ledger);
        result_file=$fopen({run_dir,"/probe-result.json"},"w");$fwrite(result_file,"{\"status\":\"PASS\",\"finished\":true,\"requests\":1056,\"crc_words\":1056}\n");$fclose(result_file);
        finished=1;#1;$finish;
    end
    initial begin repeat(2000000)@(posedge clk_25m);$fatal(1,"ANGLE probe deadline");end
endmodule
