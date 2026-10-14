// SRC001…004：258×258完整公式比对、奇数半幅与mod256边界，held cfg隔离。
module tb_r2_pattern_pair_source;
    localparam integer W=258,H=258,P=W*H/2;
    logic clk=0;always #5 clk=~clk;
    logic rst=1,job_start=0,fault=0,source_stop=0,out_ready=0;
    logic [141:0] cj=0;logic [1:0] pattern=0;
    wire out_valid,source_last_fire;wire [73:0] out_fp;
    r2_pattern_pair_source #(.W(W),.H(H)) dut (.*);
    logic [141:0] job[0:0];logic [31:0] lfsr=32'h431;logic old_hold=0;
    logic [73:0] held;logic finished=0;
    integer expected_fd,result_fd,compared=0,cycles=0,hold_checks=0,stall_run=0,last_fires=0;
    string case_id,input_path,expected_path,result_path;
    always @(posedge clk) begin
        logic [73:0] expected;
        cycles=cycles+1;
        if(cycles>32768+128*(W/2)+16*P) $fatal(1,"SRC finite timeout");
        if(rst) begin
            if(out_valid||source_last_fire) $fatal(1,"SRC reset fire");old_hold=0;
        end else begin
            if(old_hold&&(!out_valid||out_fp!==held)) $fatal(1,"SRC held cfg/data changed");
            if(old_hold) hold_checks=hold_checks+1;
            old_hold=out_valid&&!out_ready;held=out_fp;
            if(out_valid&&out_ready) begin
                if(compared>=P||$fscanf(expected_fd,"%h\n",expected)!=1) $fatal(1,"SRC golden count");
                if(out_fp!==expected) $fatal(1,"SRC full FP74 mismatch pair=%0d",compared);
                compared=compared+1;
            end
            if(source_last_fire) last_fires=last_fires+1;
        end
    end
    initial begin
        if(!$value$plusargs("CASE=%s",case_id)||!$value$plusargs("IN=%s",input_path)
            ||!$value$plusargs("EXPECTED=%s",expected_path)||!$value$plusargs("RESULT=%s",result_path)) $fatal(1,"SRC args");
        $readmemh(input_path,job);expected_fd=$fopen(expected_path,"r");if(expected_fd==0) $fatal(1,"SRC expected open");
        repeat(3) @(negedge clk);rst=0;cj=job[0];pattern=job[0][67:66];job_start=1;
        @(negedge clk);job_start=0;
        // 外部配置变化不得改变已锁job。pattern来自k[3:2]，输入file config=k。
        while(compared<P) begin
            lfsr={lfsr[30:0],lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
            out_ready=lfsr[1]||stall_run==8;stall_run=out_ready?0:stall_run+1;
            cj=~cj;pattern=pattern+2'd1;fault=~fault;
            @(negedge clk);
        end
        out_ready=1;repeat(3) @(negedge clk);
        if(out_valid||source_last_fire||last_fires!=1||hold_checks==0) $fatal(1,"SRC completion/coverage");
        $fclose(expected_fd);result_fd=$fopen(result_path,"w");if(result_fd==0) $fatal(1,"SRC result open");
        $fwrite(result_fd,"{\"schema_version\":1,\"case_id\":\"%s\",\"suite\":\"r2-observer-v1\",\"width\":258,\"height\":258,\"status\":\"PASS\",\"finished\":true,\"numeric_errors\":0,\"protocol_errors\":0,\"compared_pairs\":%0d,\"last_fires\":%0d,\"hold_checks\":%0d,\"cycles\":%0d}\n",case_id,compared,last_fires,hold_checks,cycles);
        $fclose(result_fd);finished=1;$finish;
    end
endmodule
