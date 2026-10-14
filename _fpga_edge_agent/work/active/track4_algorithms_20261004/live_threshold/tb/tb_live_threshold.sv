`timescale 1ns/1ps
module tb_live_threshold;
    logic clk=0, rst=1, inc=1, dec=1, job=0;
    always #5 clk=~clk;
    wire [10:0] pending[0:2], active[0:2];
    wire ip[0:2],dp[0:2],il[0:2],dl[0:2];
    for(genvar i=0;i<3;i++)begin:g
        live_threshold_control #(.DEBOUNCE_CYCLES(i==0?7:2),
            .INITIAL_THRESHOLD(i==0?256:(i==1?0:2047)),.STEP(i==0?16:(i==1?1:2047))) dut(
            .clk(clk),.rst(rst),.raw_inc_n(inc),.raw_dec_n(dec),.job_fire(job),
            .pending_threshold(pending[i]),.active_threshold(active[i]),
            .inc_press(ip[i]),.dec_press(dp[i]),.inc_pressed(il[i]),.dec_pressed(dl[i]));
    end
    bit finished=0;
    integer input_file, output_file, fields, cycle=0, r,a,b,c;
    initial begin
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        input_file=$fopen("stimulus.txt","r");output_file=$fopen("actual.txt","w");
        if(!input_file || !output_file)$fatal(1,"file open failed");
        while(!$feof(input_file))begin
            @(negedge clk);
            fields=$fscanf(input_file,"%d %d %d %d\n",r,a,b,c);
            if(fields!=4)$fatal(1,"malformed stimulus");
            rst=r;inc=a;dec=b;job=c;
            @(posedge clk);#1;
            $fwrite(output_file,"%0d",cycle);
            for(integer i=0;i<3;i++)begin
                if($isunknown({pending[i],active[i],ip[i],dp[i],il[i],dl[i]}))$fatal(1,"unknown output");
                $fwrite(output_file," %0d %0d %0d %0d %0d %0d",pending[i],active[i],ip[i],dp[i],il[i],dl[i]);
            end
            $fwrite(output_file,"\n");cycle++;
        end
        $fclose(input_file);$fclose(output_file);
        finished=1;#1;$display("LT complete cycles=%0d",cycle);$finish;
    end
    initial begin #10000000;$fatal(1,"watchdog");end
endmodule
