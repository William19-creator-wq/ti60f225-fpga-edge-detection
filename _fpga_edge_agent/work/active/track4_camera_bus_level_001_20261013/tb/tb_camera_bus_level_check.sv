`timescale 1ns/1ps
// T2-T4：用可断开的输出路径和外部拉低模型检查可观察行为。
module tb_camera_bus_level_check;
    localparam integer M = 64, S = 8, G = 8;
    logic clk = 0;
    always #5 clk = !clk;
    logic arst_n = 0;
    logic break_scl = 0, break_sda = 0;
    logic sda_input_high = 0;
    logic external_scl_low = 0, external_sda_low = 0;
    wire scl_low, sda_low, cam_rst, done, sda_error, scl_error;
    wire [3:0] phase;
    tri1 scl_pad, sda_pad;
    assign scl_pad = (scl_low && !break_scl) ? 1'b0 : 1'bz;
    assign sda_pad = (sda_low && !break_sda) ? 1'b0 : 1'bz;
    assign scl_pad = external_scl_low ? 1'b0 : 1'bz;
    assign sda_pad = external_sda_low ? 1'b0 : 1'bz;

    camera_bus_level_check #(
        .MEASURE_CYCLES(M), .SETTLE_CYCLES(S), .GUARD_CYCLES(G)
    ) dut (
        .clk(clk), .arst_n(arst_n), .scl_i(scl_pad),
        .sda_i(sda_input_high ? 1'b1 : sda_pad),
        .cam_rst_p(cam_rst), .scl_drive_low(scl_low), .sda_drive_low(sda_low),
        .phase_leds(phase), .finished(done), .sda_error(sda_error), .scl_error(scl_error)
    );

    integer phase_ticks[0:3];
    integer sda_active_ticks, scl_active_ticks;
    integer test_count = 0;
    bit finished = 0;
    // 只观察端口，不靠状态机内部路径来判正常结果。
    always @(posedge clk) begin
        #1;
        if (!arst_n) begin
            for (int p=0; p<4; p++) phase_ticks[p] = 0;
            sda_active_ticks = 0;
            scl_active_ticks = 0;
        end else begin
            if (phase !== 0 && phase !== 1 && phase !== 2 && phase !== 4 && phase !== 8)
                $fatal(1,"Phase is not one-hot: %b",phase);
            for (int p=0; p<4; p++)
                if (phase == (4'b0001 << p)) phase_ticks[p]++;
            if (sda_low) sda_active_ticks++;
            if (scl_low) scl_active_ticks++;
            if (sda_low && !scl_low) $fatal(1,"SDA asserted without SCL low qualification");
            if (done && (scl_low || sda_low || phase != 0))
                $fatal(1,"Finished while driving or displaying a measurement phase");
        end
    end

    task automatic reset_case(input integer mode);
        @(negedge clk);
        arst_n=0;
        break_scl=(mode==2); break_sda=(mode==1);
        sda_input_high=(mode==3);
        external_scl_low=0; external_sda_low=(mode==4);
        #1;
        if (scl_low !== 0 || sda_low !== 0 || cam_rst !== 1)
            $fatal(1,"Asynchronous reset did not revoke drives");
        repeat(4) @(negedge clk);
        arst_n=1;
    endtask

    task automatic wait_phase(input logic [3:0] expected);
        bit found;
        found=0;
        for(int n=0;n<600;n++) begin
            @(posedge clk); #2;
            if(phase==expected) begin found=1; break; end
            if(done) $fatal(1,"Ended before requested phase %b",expected);
        end
        if(!found) $fatal(1,"Timeout waiting for phase %b",expected);
    endtask

    task automatic expect_done(input bit expected_sda,input bit expected_scl,input string label);
        bit found;
        found=0;
        for(int n=0;n<600;n++) begin
            @(posedge clk); #2;
            if(done) begin found=1; break; end
        end
        if(!found) $fatal(1,"%s: finite completion timeout",label);
        if(sda_error !== expected_sda || scl_error !== expected_scl)
            $fatal(1,"%s: errors SDA=%b SCL=%b expected %b/%b",label,sda_error,scl_error,expected_sda,expected_scl);
        repeat(2*M) begin
            @(posedge clk); #2;
            if(!done || phase!=0 || scl_low || sda_low ||
               sda_error!==expected_sda || scl_error!==expected_scl)
                $fatal(1,"%s: absorbing result changed",label);
        end
        test_count++;
        $display("CASE PASS %s",label);
    endtask

    initial begin
        if($test$plusargs("EXPECT_FATAL")) $fatal(1,"bus level expected fatal probe");
        reset_case(0);
        expect_done(0,0,"normal electrical bus");
        // 同步释放让第一阶段多一个初始可见沿；其余三个窗口应恰为M拍。
        if(phase_ticks[0]<M || phase_ticks[0]>M+1) $fatal(1,"Idle duration %0d",phase_ticks[0]);
        for(int p=1;p<4;p++) if(phase_ticks[p]!=M) $fatal(1,"Phase duration %0d=%0d",p,phase_ticks[p]);

        reset_case(1);
        expect_done(1,0,"SDA output physically disconnected");
        if(phase_ticks[2]!=M) $fatal(1,"SDA fault lost measurement window");

        reset_case(3);
        expect_done(1,0,"SDA input stuck high while pad drives low");

        reset_case(2);
        expect_done(0,1,"SCL output physically disconnected");
        if(sda_active_ticks!=0) $fatal(1,"Pulled SDA before confirming SCL");

        reset_case(4);
        expect_done(1,0,"SDA already held low before start");
        if(scl_active_ticks!=0 || sda_active_ticks!=0) $fatal(1,"Drove initially busy bus");

        reset_case(0);
        wait_phase(4'b1000);
        @(negedge clk); external_sda_low=1;
        expect_done(1,0,"External SDA holds low during release");
        if(sda_pad!==0) $fatal(1,"Confused own release with external release");

        for(int p=0;p<4;p++) begin
            reset_case(0);
            wait_phase(4'b0001 << p);
            repeat(3) @(negedge clk);
            arst_n=0;
            #1;
            if(scl_low!==0 || sda_low!==0 || phase!==0 || cam_rst!==1)
                $fatal(1,"Reset in phase %0d failed",p);
            repeat(4) @(negedge clk);
            arst_n=1;
            expect_done(0,0,$sformatf("Async reset and restart from phase %0d",p));
        end

        reset_case(0);
        wait_phase(4'b0100);
        @(negedge clk); force dut.state[2:0] = 3'b111;
        @(posedge clk); #2; release dut.state[2:0];
        expect_done(1,1,"Illegal state releases and terminates");

        reset_case(0);
        wait_phase(4'b0100);
        @(negedge clk); break_scl=1;
        expect_done(0,1,"SCL path lost after entering both low");

        if(test_count!=12) $fatal(1,"Unexpected case count %0d",test_count);
        $display("BUS_LEVEL_SUITE_PASS cases=%0d",test_count);
        finished=1;
        $finish;
    end
    initial begin
        #200000;
        $fatal(1,"Global timeout");
    end
endmodule
