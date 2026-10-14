`timescale 1ns/1ps
// FT-T10：独立Python复核原请求/响应及585位CRC；计数不从LED推断。
module tb_fit_probe_top;
    logic clk_25m=0,key1_n=0;
    wire led0,led1;
    always #20 clk_25m=~clk_25m;
    bit finished=0;
    string run_dir;
    integer fd,result_fd,total=0,cycle=0;
    logic [621:0] accepted_request;
    logic [584:0] consumed_response;
    logic live=0,crc_pending=0;
    fit_probe_top dut(.*);
    always @(posedge clk_25m) begin
        cycle=cycle+1;
        if(dut.core_rst) begin live=0; crc_pending=0; end
        else begin
            if(dut.req_valid && dut.req_ready) begin
                if(live || crc_pending) $fatal(1,"probe overlapped source/CRC");
                accepted_request=dut.request_slot; live=1;
            end
            if(dut.rsp_valid && dut.rsp_ready) begin
                if(!live || dut.rsp_body[175:0]!==accepted_request[175:0]) $fatal(1,"probe identity");
                consumed_response=dut.rsp_body; live=0; crc_pending=1;
            end
            if(dut.source_state==4) begin
                if(!crc_pending) $fatal(1,"CRC without response");
                $fwrite(fd,"%0156h %0147h %08h\n",accepted_request,consumed_response,dut.rolling_crc);
                crc_pending=0; total=total+1;
            end
        end
        if(cycle>20000000) $fatal(1,"probe bounded suite timeout");
    end
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir)) $fatal(1,"RUN_DIR missing");
        fd=$fopen({run_dir,"/probe-observed.tsv"},"w"); if(!fd) $fatal(1,"probe output file");
        repeat(4) @(negedge clk_25m); key1_n=1;
        while(total<1024) @(negedge clk_25m);
        if(led0!==1) $fatal(1,"LED must use consumed old ID1023");
        key1_n=0; repeat(4) @(negedge clk_25m); key1_n=1;
        while(total<1056) @(negedge clk_25m);
        $fclose(fd); result_fd=$fopen({run_dir,"/probe-result.json"},"w");
        $fwrite(result_fd,"{\"finished\":true,\"errors\":0,\"count\":1056,\"cycles\":%0d}\n",cycle); $fclose(result_fd);
        finished=1; $display("PASS probe count=1056 cycles=%0d",cycle); $finish;
    end
endmodule
