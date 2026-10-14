`timescale 1ns/1ps
module tb_sc431hai_config #(parameter integer FULL_CLOCK=0,RUN_PROTOCOL=1);
    localparam integer CLK_MAX=FULL_CLOCK ? 101000000 : 1000000;
    localparam real HALF_NS=FULL_CLOCK ? 5.0 : 500.0;
    logic clk=0,rst=1,platform_ok=1,finished=0;always #(HALF_NS) clk=~clk;
    logic job_valid=0,job_ready;logic [159:0] job_scope=0;logic [1:0] job_operation=0;logic [6:0] job_device_addr='h30;
    logic cancel_valid=0;logic [159:0] cancel_scope=0;
    logic done_valid,done_ready=0;logic [159:0] done_scope,verified_scope;
    logic [1:0] done_operation,outcome,chip_valid;logic [6:0] done_device_addr;
    logic [7:0] reason,readback_value,writes_committed,reads_completed;
    logic [15:0] failed_reg,chip_id;logic [3:0] failed_phase,ack_mask;logic [13:0] verify_mask;
    logic [111:0] readback_values;logic drained,registers_verified,live_verified,quarantined;
    logic scl_drive_low,sda_drive_low,sensor_scl_low,sensor_sda_low,force_scl=0,force_sda=0;
    tri1 scl_i,sda_i;
    assign scl_i=scl_drive_low ? 1'b0 : 1'bz;assign scl_i=(sensor_scl_low || force_scl) ? 1'b0 : 1'bz;
    assign sda_i=sda_drive_low ? 1'b0 : 1'bz;assign sda_i=(sensor_sda_low || force_sda) ? 1'b0 : 1'bz;
    integer case_id=0,nack_transaction=-1,nack_ordinal=-1,stretch_ns=0,corrupt_read_register=-1;
    logic [7:0] corrupt_read_xor=0;logic [6:0] device_address='h30;
    sc431hai_config #(.CLK_MAX_HZ(CLK_MAX),.TIMEOUT_US(FULL_CLOCK ? 10000 : 1000)) dut(.*);
    i2c_sensor_model sensor(.scl(scl_i),.sda(sda_i),.device_address(device_address),.case_id(case_id),
        .nack_transaction(nack_transaction),.nack_ordinal(nack_ordinal),.stretch_ns(stretch_ns),
        .corrupt_read_register(corrupt_read_register),.corrupt_read_xor(corrupt_read_xor),
        .sda_drive_low(sensor_sda_low),.scl_drive_low(sensor_scl_low));
    logic [23:0] table_words[0:163];logic [31:0] verify_words[0:13];
    logic [159:0] locked_scope;logic [1:0] locked_operation;logic [6:0] locked_device;
    logic held_done=0;logic [372:0] held_body;
    integer cycles=0,cases=0,errors=0,cancels=0,unknowns=0,normal_configs=0,result_handle;
    realtime power_time=0,first_start_time=0;
    wire [372:0] current_body={done_scope,done_operation,done_device_addr,outcome,reason,readback_value,failed_reg,chip_id,
        failed_phase,ack_mask,writes_committed,reads_completed,verify_mask,readback_values,chip_valid,drained,registers_verified};
    // 独立近耗尽实例：没有force内部next_tag，也不让拒绝请求触外部线。
    logic near_valid=0,near_ready,near_done,near_done_ready=0,near_drained,near_q,near_scl,near_sda;
    logic [1:0] near_outcome;logic [7:0] near_reason;
    sc431hai_config #(.CLK_MAX_HZ(CLK_MAX),.INITIAL_TAG(64'hfffffffffffffffe)) near_budget(
        .clk(clk),.rst(rst),.platform_ok(1'b1),.job_valid(near_valid),.job_ready(near_ready),.job_scope(job_scope),
        .job_operation(2'd0),.job_device_addr(7'h30),.cancel_valid(1'b0),.cancel_scope(160'd0),
        .done_valid(near_done),.done_ready(near_done_ready),.done_scope(),.done_operation(),.done_device_addr(),
        .outcome(near_outcome),.reason(near_reason),.readback_value(),.failed_reg(),.chip_id(),.failed_phase(),.ack_mask(),
        .writes_committed(),.reads_completed(),.verify_mask(),.readback_values(),.chip_valid(),
        .drained(near_drained),.registers_verified(),.live_verified(),.verified_scope(),.quarantined(near_q),
        .scl_i(1'b1),.sda_i(1'b1),.scl_drive_low(near_scl),.sda_drive_low(near_sda));
    always @(negedge sda_i)if(scl_i===1'b1 && first_start_time==0)first_start_time=$realtime;
    always @(posedge clk)begin
        cycles++;
        if(rst)held_done=0;
        else begin
            if(held_done && (!done_valid || current_body!==held_body))$fatal(1,"Held camera configuration snapshot changed");
            held_done=done_valid && !done_ready;held_body=current_body;
            if(dut.master_fire && platform_ok && dut.power_age<dut.T4)$fatal(1,"I2C started before physical T4 qualification");
        end
        if(cycles>(FULL_CLOCK ? 30000000 : 15000000))$fatal(1,"SC431 watchdog case=%0d state=%0d stage=%0d master=%0d",case_id,dut.state,dut.stage,dut.bus.state);
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;platform_ok=1;job_valid=0;cancel_valid=0;done_ready=0;force_scl=0;force_sda=0;
        nack_transaction=-1;nack_ordinal=-1;stretch_ns=0;corrupt_read_register=-1;corrupt_read_xor=0;device_address='h30;
        first_start_time=0;sensor.reset_model();repeat(3)@(posedge clk);@(negedge clk);rst=0;power_time=$realtime;
    endtask
    task automatic start_job(input logic [1:0] op=0,input logic [6:0] address='h30);
        @(negedge clk);job_scope={64'h99ab123400000000+64'(case_id),64'h7fa1000000000000+64'(case_id),32'hadef4310+32'(case_id)};
        locked_scope=job_scope;locked_operation=op;locked_device=address;job_operation=op;job_device_addr=address;job_valid=1;
        do @(posedge clk);while(job_ready!==1'b1);
        @(negedge clk);job_valid=0;job_scope='1;job_operation=3;job_device_addr=0;
    endtask
    task automatic take_done(input integer expected,input string kind="protocol");
        while(!done_valid)@(negedge clk);
        if(outcome!=expected || done_scope!=locked_scope || done_operation!=locked_operation || done_device_addr!=locked_device || drained!=(expected!=3))$fatal(1,"SC431 outcome/identity case=%0d out=%0d reason=%0d reg=%h phase=%0d",case_id,outcome,reason,failed_reg,failed_phase);
        if(expected!=3 && (dut.state==dut.ISSUE || dut.state==dut.WAIT_REPLY || sensor.active || scl_i!==1 || sda_i!==1))$fatal(1,"Camera safe result before real bus closure");
        if(expected==0 && locked_operation==0)begin
            if(!registers_verified || writes_committed!=164 || reads_completed!=16 || verify_mask!=16383 || chip_id!='hcd6b || chip_valid!=3)$fatal(1,"SC431 success prefix");
            for(integer i=0;i<14;i++)if((readback_values[i*8+:8]&verify_words[i][7:0])!=verify_words[i][15:8])$fatal(1,"Public readback snapshot mismatch");
        end
        if(cases)$fwrite(result_handle,",\n");
        $fwrite(result_handle,"{\"case\":%0d,\"kind\":\"%s\",\"device\":%0d,\"outcome\":%0d,\"reason\":%0d,\"writes\":%0d,\"reads\":%0d,\"mask\":%0d,\"id\":%0d,\"min_low_ns\":%0.0f,\"min_high_ns\":%0.0f,\"min_start_hold_ns\":%0.0f,\"min_stop_setup_ns\":%0.0f,\"min_bus_free_ns\":%0.0f,\"first_start_after_power_ns\":%0.0f}",
            case_id,kind,locked_device,outcome,reason,writes_committed,reads_completed,verify_mask,chip_id,
            sensor.min_low,sensor.min_high,sensor.min_start_hold,sensor.min_stop_setup,sensor.min_bus_free,first_start_time-power_time);
        repeat(15)@(negedge clk);done_ready=1;@(posedge clk);@(negedge clk);done_ready=0;
        if(expected==3)begin if(job_ready || !quarantined)$fatal(1,"Camera Q recycled after notification");unknowns++;end
        else if(!job_ready)$fatal(1,"Camera job not released");
        if(expected==1)errors++;if(expected==2)cancels++;if(expected==0 && locked_operation==0)normal_configs++;
        cases++;case_id++;
    endtask
    task automatic cancel_current;
        cancel_scope=locked_scope;cancel_valid=1;@(posedge clk);@(negedge clk);
    endtask
    initial begin
        integer metrics,old_starts;
        logic [7:0] flip_bit;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        $readmemh("profile.hex",table_words);$readmemh("verify.hex",verify_words);
        sensor.trace_handle=$fopen("config-wire.csv","w");result_handle=$fopen("config-results.json","w");$fwrite(result_handle,"[\n");
        $display("SC431 full profile clock=%0d",CLK_MAX);
        reset_joint();start_job();cancel_scope=locked_scope^(160'd1<<150);cancel_valid=1;take_done(0,"config_ok");cancel_valid=0;
        if(!live_verified || verified_scope!=locked_scope)$fatal(1,"Camera live register qualification identity");
        start_job(1);take_done(0,"stop_ok");if(writes_committed!=1 || reads_completed!=1 || live_verified || sensor.memory_bytes['h0100][0])$fatal(1,"SC431 STOP incomplete");
        if(RUN_PROTOCOL)begin
            reset_joint();device_address='h32;
            sensor.memory_bytes['h3018]='h7f;sensor.memory_bytes['h3031]='hfa;sensor.memory_bytes['h3037]='h3f;sensor.memory_bytes['h303f]='h7f;
            start_job(0,'h32);take_done(0,"config_ok");
            // held terminal平台失效不修改旧snapshot，但live立即撤销。
            reset_joint();start_job();while(!done_valid)@(negedge clk);platform_ok=0;repeat(3)@(negedge clk);
            if(live_verified || !registers_verified)$fatal(1,"Live revoke rewrote snapshot");take_done(0,"config_ok");
            reset_joint();sensor.memory_bytes['h3107]=0;start_job();take_done(1);if(reason!=5 || writes_committed || reads_completed!=2)$fatal(1,"Bad sensor ID wrote ROM");
            for(integer j=0;j<14;j++)begin
                $display("SC431 readback failure index=%0d",j);reset_joint();
                corrupt_read_register=integer'(verify_words[j][31:16]);flip_bit=verify_words[j][7:0]&(-verify_words[j][7:0]);corrupt_read_xor=flip_bit;
                start_job();take_done(1);if(reason!=6 || failed_reg!=verify_words[j][31:16] || writes_committed!=164 || reads_completed!=j+3 || verify_mask!=((1<<j)-1))$fatal(1,"SC431 public field failure prefix");
            end
            for(integer reading=0;reading<2;reading++)for(integer b=0;b<4;b++)begin
                reset_joint();nack_transaction=reading ? 0 : 91;nack_ordinal=b;start_job();take_done(1);
                if(reason!=2 || writes_committed!=(reading ? 0 : 89) || failed_phase!=(reading && b==3 ? 5 : b+1))$fatal(1,"Camera ACK failure not localized");
            end
            reset_joint();start_job(1);take_done(0,"stop_ok");
            reset_joint();corrupt_read_register='h0100;corrupt_read_xor=1;start_job(1);take_done(1);if(reason!=6 || writes_committed!=1 || reads_completed!=1)$fatal(1,"STOP readback not checked");
            for(integer target=0;target<3;target++)begin
                reset_joint();start_job();
                if(target==1)while(dut.state!=dut.ISSUE)@(negedge clk);
                else if(target==2)while(dut.stage!=dut.ROM_WRITE || dut.state!=dut.WAIT_REPLY || !dut.bus.owned)@(negedge clk);
                cancel_current();take_done(2);if(live_verified)$fatal(1,"Cancelled configuration became live");
            end
            reset_joint();
            @(negedge clk);job_scope={64'h99ab123400000000+64'(case_id),64'h7fa1000000000000+64'(case_id),32'hadef4310+32'(case_id)};
            locked_scope=job_scope;locked_operation=0;locked_device='h30;job_operation=0;job_device_addr='h30;cancel_scope=job_scope;cancel_valid=1;job_valid=1;
            do @(posedge clk);while(job_ready!==1'b1);@(negedge clk);job_valid=0;take_done(2);if(sensor.starts)$fatal(1,"Same-edge camera cancel started bus");
            reset_joint();platform_ok=0;start_job();take_done(1);if(reason!=4 || sensor.starts)$fatal(1,"Unqualified camera got through T4");
            reset_joint();start_job();repeat(300)@(negedge clk);platform_ok=0;repeat(3)@(negedge clk);platform_ok=1;power_time=$realtime;
            take_done(0,"config_ok");
            reset_joint();start_job();while(dut.state!=dut.PREPARE)@(negedge clk);platform_ok=0;take_done(1);if(reason!=7 || sensor.starts)$fatal(1,"Qualification loss before command started I2C");
            reset_joint();start_job();while(!dut.bus.owned)@(negedge clk);platform_ok=0;take_done(3);platform_ok=1;repeat(5)@(negedge clk);if(job_ready)$fatal(1,"Platform recovery cleared camera Q");
            reset_joint();force_sda=1;start_job();take_done(3);
            reset_joint();force_scl=1;start_job();take_done(3);
            for(integer bad=0;bad<2;bad++)begin
                reset_joint();start_job(bad==0 ? 2 : 0,bad==0 ? 7'h30 : 7'h31);take_done(1);if(reason!=1 || sensor.starts)$fatal(1,"Invalid camera profile touched bus");
            end
            reset_joint();@(negedge clk);near_valid=1;do @(posedge clk);while(!near_ready);@(negedge clk);near_valid=0;
            while(!near_done)@(negedge clk);
            if(near_outcome!=1 || near_reason!=8 || !near_drained || near_scl || near_sda || near_q)$fatal(1,"Camera tag budget wrapped");
            near_done_ready=1;@(posedge clk);@(negedge clk);near_done_ready=0;
            start_job();take_done(0,"config_ok");
            reset_joint();start_job();
            while(dut.stage!=dut.VERIFY || dut.verify_index!=13 || !dut.m_valid)@(negedge clk);
            cancel_current();take_done(2);if(writes_committed!=164 || reads_completed!=16 || live_verified || registers_verified)$fatal(1,"Last reply/cancel erased real prefix or enabled live");
        end
        $fwrite(result_handle,"\n]\n");$fclose(result_handle);$fclose(sensor.trace_handle);
        metrics=$fopen("protocol-metrics.json","w");
        $fwrite(metrics,"{\"finished\":true,\"cases\":%0d,\"normal_configs\":%0d,\"errors\":%0d,\"cancels\":%0d,\"unknowns\":%0d,\"cycles\":%0d,\"full_clock\":%s,\"clk_max_hz\":%0d}\n",cases,normal_configs,errors,cancels,unknowns,cycles,FULL_CLOCK ? "true" : "false",CLK_MAX);$fclose(metrics);
        finished=1;$display("SC431 configuration PASS cases=%0d cycles=%0d",cases,cycles);$finish;
    end
endmodule
