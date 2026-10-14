`timescale 1ns/1ps
module tb_scalar_probe_top;
    reg clk_25m=0;always #20 clk_25m=~clk_25m;
    reg key1_n=0;
    wire led0,led1;
    reg finished=0;
    scalar_probe_top dut(.*);
    string run_dir;
    integer trace_file,result_file,cycles=0,accepted=0,consumed=0,completed=0;
    integer epoch_completed=0,phase=0,reset_cycles=0;
    reg live=0,response_owned=0,finishing_bit;
    reg [621:0] saved_request;
    reg [584:0] saved_response;

    always @(posedge clk_25m) begin
        cycles=cycles+1;finishing_bit=0;
        if(dut.core_rst) begin
            live=0;response_owned=0;reset_cycles=reset_cycles+1;
            if(dut.req_valid || dut.rsp_valid) $fatal(1,"probe reset qualification");
        end else begin
            if(dut.req_valid && dut.req_ready) begin
                if(live || response_owned) $fatal(1,"probe input ownership");
                saved_request=dut.request_slot;live=1;accepted=accepted+1;
            end
            if(dut.rsp_valid && dut.rsp_ready) begin
                if(!live || response_owned || dut.rsp_body[175:0]!==saved_request[175:0])
                    $fatal(1,"probe response ownership");
                saved_response=dut.rsp_body;live=0;response_owned=1;consumed=consumed+1;
            end
            finishing_bit=dut.source_state==3 && dut.bit_index==0;
            if(finishing_bit && !response_owned) $fatal(1,"CRC without reserved response");
        end
        #2;
        if(finishing_bit) begin
            $fwrite(trace_file,"%0156h %0147h %08h %0d\n",saved_request,saved_response,dut.rolling_crc,led0);
            completed=completed+1;epoch_completed=epoch_completed+1;response_owned=0;
            if(led1!==dut.rolling_crc[0]) $fatal(1,"LED1 alignment");
        end
        if(cycles>2000000) $fatal(1,"probe timeout");
    end
    task automatic release_key;
        begin
            @(negedge clk_25m);key1_n=1;
            @(posedge clk_25m);#3;
            if(!dut.core_rst) $fatal(1,"reset released before second stage");
            @(posedge clk_25m);#3;
            if(dut.core_rst) $fatal(1,"reset failed second stage release");
        end
    endtask
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir)) $fatal(1,"RUN_DIR missing");
        trace_file=$fopen({run_dir,"/probe-observed.txt"},"w");
        if(!trace_file) $fatal(1,"probe trace file missing");
        repeat(3) @(negedge clk_25m);
        release_key();
        while(epoch_completed<1024) @(negedge clk_25m);
        if(live || response_owned || accepted!=1024 || consumed!=1024)
            $fatal(1,"first probe epoch ledger");
        key1_n=0;phase=1;epoch_completed=0;
        $fwrite(trace_file,"RESET 1\n");
        repeat(3) @(negedge clk_25m);
        release_key();
        while(epoch_completed<32) @(negedge clk_25m);
        if(live || response_owned || accepted!=1056 || consumed!=1056 || completed!=1056)
            $fatal(1,"probe recovery ledger");
        $fclose(trace_file);
        result_file=$fopen({run_dir,"/probe-result.json"},"w");
        if(!result_file) $fatal(1,"probe result file missing");
        $fwrite(result_file,"{\"status\":\"PASS\",\"finished\":true,\"accepted\":%0d,\"consumed\":%0d,\"completed_crc\":%0d,\"reset_cycles\":%0d,\"epochs\":[1024,32],\"cycles\":%0d}\n",accepted,consumed,completed,reset_cycles,cycles);
        $fclose(result_file);$display("SCALAR_PROBE_PASS completed=%0d",completed);finished=1;$finish;
    end
endmodule
