`timescale 1ns/1ps
module tb_i2c_register_master;
    logic clk=0,rst=1,enable=1,finished=0;always #500 clk=~clk;
    logic req_valid=0,req_ready,req_read=0;logic [6:0] req_device='h30;
    logic [15:0] req_register=0;logic [7:0] req_data=0;logic [63:0] req_tag=0;
    logic cancel_valid=0;logic [63:0] cancel_tag=0;
    logic rsp_valid,rsp_ready=0,rsp_drained,quarantined;logic [63:0] rsp_tag;
    logic [7:0] rsp_data,rsp_reason;logic [1:0] rsp_outcome;logic [3:0] rsp_phase,rsp_ack_mask;
    logic scl_drive_low,sda_drive_low,sensor_scl_low,sensor_sda_low,force_scl=0,force_sda=0;
    tri1 scl_i,sda_i;
    assign scl_i=scl_drive_low ? 1'b0 : 1'bz;assign scl_i=(sensor_scl_low || force_scl) ? 1'b0 : 1'bz;
    assign sda_i=sda_drive_low ? 1'b0 : 1'bz;assign sda_i=(sensor_sda_low || force_sda) ? 1'b0 : 1'bz;
    integer case_id=0,nack_transaction=-1,nack_ordinal=-1,stretch_ns=0,corrupt_read_register=-1;
    logic [7:0] corrupt_read_xor=0;logic [6:0] device_address='h30;
    i2c_register_master #(.CLK_MAX_HZ(1000000),.TIMEOUT_US(1000)) dut(.*);
    i2c_sensor_model sensor(.scl(scl_i),.sda(sda_i),.device_address(device_address),.case_id(case_id),
        .nack_transaction(nack_transaction),.nack_ordinal(nack_ordinal),.stretch_ns(stretch_ns),
        .corrupt_read_register(corrupt_read_register),.corrupt_read_xor(corrupt_read_xor),
        .sda_drive_low(sensor_sda_low),.scl_drive_low(sensor_scl_low));
    integer cycles=0,cases=0,errors=0,cancels=0,unknowns=0,result_handle;
    logic held=0;logic [90:0] held_body;
    logic [63:0] locked_tag;logic [31:0] random_value=32'h146ce572;
    always @(posedge clk)begin
        cycles++;
        if(rst)held=0;
        else begin
            if(held && (!rsp_valid || {rsp_tag,rsp_data,rsp_outcome,rsp_reason,rsp_phase,rsp_ack_mask,rsp_drained}!==held_body))$fatal(1,"Held I2C response changed");
            held=rsp_valid && !rsp_ready;held_body={rsp_tag,rsp_data,rsp_outcome,rsp_reason,rsp_phase,rsp_ack_mask,rsp_drained};
        end
        if(cycles>2000000)$fatal(1,"I2C master watchdog state=%0d case=%0d",dut.state,case_id);
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;enable=1;req_valid=0;cancel_valid=0;rsp_ready=0;force_scl=0;force_sda=0;
        nack_transaction=-1;nack_ordinal=-1;stretch_ns=0;corrupt_read_register=-1;device_address='h30;
        sensor.reset_model();repeat(3)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic issue(input logic reading,input logic [15:0] address,input logic [7:0] value);
        @(negedge clk);req_read=reading;req_register=address;req_data=value;req_device=device_address;
        req_tag=64'h8123000000000000+64'(case_id);locked_tag=req_tag;req_valid=1;
        do @(posedge clk);while(req_ready!==1'b1);
        @(negedge clk);req_valid=0;req_tag=0;req_register='1;req_data='1;req_device=0;req_read=!reading;
    endtask
    task automatic response(input integer expected,input logic [7:0] value=0,input logic check_value=0);
        while(!rsp_valid)@(negedge clk);
        if(rsp_outcome!=expected || rsp_tag!=locked_tag || rsp_drained!=(expected!=3))$fatal(1,"I2C outcome/identity case=%0d out=%0d reason=%0d phase=%0d drain=%b",case_id,rsp_outcome,rsp_reason,rsp_phase,rsp_drained);
        if(check_value && rsp_data!==value)$fatal(1,"I2C read byte mismatch got=%h want=%h",rsp_data,value);
        if(expected==0 && rsp_ack_mask!=15)$fatal(1,"Missing real slave ACK");
        if(expected!=3 && (scl_i!==1 || sda_i!==1 || sensor.active))$fatal(1,"I2C response before actual STOP/free");
        repeat(13)@(negedge clk);rsp_ready=1;@(posedge clk);@(negedge clk);rsp_ready=0;
        if(expected==3)begin if(req_ready || !quarantined)$fatal(1,"I2C unknown recycled after notice");unknowns++;end
        else if(!req_ready)$fatal(1,"I2C no fresh job after response");
        cases++;case_id++;
    endtask
    initial begin
        integer metrics,old_starts;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        sensor.trace_handle=$fopen("master-wire.csv","w");
        reset_joint();
        for(integer i=0;i<128;i++)begin
            random_value={random_value[30:0],random_value[31]^random_value[21]^random_value[1]^random_value[0]};
            issue(0,16'(i*517),random_value[7:0]);response(0);
            issue(1,16'(i*517),0);response(0,random_value[7:0],1);
        end
        for(integer reading=0;reading<2;reading++)for(integer byte_no=0;byte_no<4;byte_no++)begin
            reset_joint();nack_transaction=0;nack_ordinal=byte_no;issue(1'(reading),'h3107,'ha5);response(1);
            if(rsp_reason!=2 || rsp_phase!=(byte_no==3 && reading ? 5 : byte_no+1))$fatal(1,"NACK byte localization");errors++;
        end
        reset_joint();stretch_ns=20000;issue(1,'h3107,0);response(0,'hcd,1);
        reset_joint();old_starts=sensor.starts;cancel_tag=64'h8123000000000000+64'(case_id);cancel_valid=1;
        issue(0,'h1234,'h5a);response(2);if(sensor.starts!=old_starts)$fatal(1,"Same-edge cancelled I2C started");cancels++;
        reset_joint();issue(0,'h1234,'ha5);while(!dut.owned)@(negedge clk);
        cancel_tag=locked_tag^64'd1;cancel_valid=1;repeat(3)@(negedge clk);cancel_valid=0;response(0);
        reset_joint();issue(1,'h3107,0);while(!dut.owned)@(negedge clk);cancel_tag=locked_tag;cancel_valid=1;response(2);cancels++;
        reset_joint();issue(0,'h4321,'hcc);while(!dut.owned)@(negedge clk);enable=0;response(3);enable=1;repeat(10)@(negedge clk);if(req_ready)$fatal(1,"Enable recovery cleared Q");
        reset_joint();force_scl=1;issue(0,'h4321,'hcc);response(3);
        reset_joint();force_sda=1;issue(0,'h4321,'hcc);response(3);
        reset_joint();issue(0,'h1234,'hff);
        while(dut.state!=dut.BIT_HIGH || dut.bit_kind!=dut.TX || !dut.tx_byte[dut.bit_index])@(negedge clk);
        sensor.timing_enabled=0;force_sda=1;repeat(12)@(negedge clk);if(sda_drive_low || scl_drive_low)$fatal(1,"Arbitration loss inserted master STOP");force_sda=0;
        response(1);if(rsp_reason!=3)$fatal(1,"Arbitration cause missing");errors++;
        reset_joint();issue(1,'h3108,0);response(0,'h6b,1);
        if(sensor.min_low<4700 || sensor.min_high<4000 || sensor.min_start_hold<4000 || sensor.min_stop_setup<4000)$fatal(1,"Actual I2C standard-mode time");
        for(integer bad=0;bad<2;bad++)begin
            reset_joint();device_address=bad==0 ? 7'd0 : 7'h7f;issue(0,'h1234,'h55);response(1);
            if(rsp_reason!=1 || sensor.starts)$fatal(1,"Illegal I2C address started");errors++;
        end
        reset_joint();enable=0;issue(0,'h1234,'h55);response(1);
        if(rsp_reason!=7 || sensor.starts)$fatal(1,"Unqualified local request touched bus");errors++;
        metrics=$fopen("master-metrics.json","w");
        $fwrite(metrics,"{\"finished\":true,\"cases\":%0d,\"errors\":%0d,\"cancels\":%0d,\"unknowns\":%0d,\"cycles\":%0d}\n",cases,errors,cancels,unknowns,cycles);$fclose(metrics);$fclose(sensor.trace_handle);
        finished=1;$display("I2C register master PASS cases=%0d cycles=%0d",cases,cycles);$finish;
    end
endmodule
