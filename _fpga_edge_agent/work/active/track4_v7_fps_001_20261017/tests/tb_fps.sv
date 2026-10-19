`timescale 1ns/1ps
module tb_fps;
    reg clk=0, rst_n=0, vs=0, hs=0, de=0;
    always #10 clk=~clk;
    wire [15:0] word_out;
    wire start,ready;
    camera_fps_monitor #(.STALE_CYCLES(32'd2000000)) dut(
        .clk(clk),.rst_n(rst_n),.vs(vs),.hs(hs),.de(de),
        .telemetry_word(word_out),.packet_start(start),.measurement_ready(ready));
    integer packets=0, pos=-1, i;
    reg [15:0] words[0:15], sum;
    // 每个报文都验证帧边界更新期间的原子性及校验；不读取VCD时间换算FPS。
    always @(negedge clk) begin
        if (!rst_n) pos=-1;
        else begin
            if(start) pos=0;
            if(pos>=0) begin
                words[pos]=word_out;
                if(pos==15) begin
                    if(words[0]==16'ha55a) begin
                        sum=0;
                        for(i=0;i<14;i=i+1) sum=sum^words[i];
                        if(words[14]!==sum || words[15]!==16'h5aa5 || words[1]!==1)
                            $fatal(1,"packet checksum/version/trailer failure");
                        packets=packets+1;
                    end
                    pos=-1;
                end else pos=pos+1;
            end
        end
    end
    task tick(input bit v,h,d);
        @(negedge clk); #1;vs=v;hs=h;de=d;
    endtask
    task frame(input integer period, width, height, input bit bubbles);
        integer n,l,x;
        begin
            tick(1,0,0);n=1;
            tick(0,0,0);n=n+1;
            for(l=0;l<height;l=l+1) begin
                for(x=0;x<width;x=x+1) begin
                    tick(0,1,1);n=n+1;
                    if(bubbles && x%8==0) begin tick(0,1,0);n=n+1;end
                end
                tick(0,0,0);n=n+1;
            end
            if(n>period) $fatal(1,"invalid stimulus period");
            repeat(period-n) tick(0,0,0);
        end
    endtask
    task check(input integer period,width,height,seq);
        #12;
        if(dut.last_period!==period || dut.last_words!==width*height ||
           dut.last_lines!==height || dut.last_min!==width || dut.last_max!==width ||
           dut.sequence_count!==seq || dut.last_overflow || dut.last_boundary_error)
            $fatal(1,"measurement mismatch period=%0d words=%0d lines=%0d min=%0d max=%0d seq=%0d",
                dut.last_period,dut.last_words,dut.last_lines,dut.last_min,dut.last_max,dut.sequence_count);
    endtask
    task dump_capture;
        integer fd,n;
        reg [15:0] previous;
        reg ps,pr;
        begin
            fd=$fopen("synthetic_capture.vcd","w");
            $fwrite(fd,"$timescale 1 ns $end\n$scope module top $end\n$var wire 8 0 ch0_g $end\n$var wire 8 1 ch0_b $end\n$var wire 1 2 ch0_de $end\n$var wire 1 3 cal_done $end\n$upscope $end\n$enddefinitions $end\n");
            previous=0;ps=0;pr=0;
            for(n=0;n<1024;n=n+1) begin
                @(negedge clk);#2;
                // 模仿Debugger：时间单位为样点索引，未变化的信号省略。
                $fwrite(fd,"#%0d\n",n);
                if(n==0 || word_out[7:0]!=previous[7:0]) $fwrite(fd,"b%b 0\n",word_out[7:0]);
                if(n==0 || word_out[15:8]!=previous[15:8]) $fwrite(fd,"b%b 1\n",word_out[15:8]);
                if(n==0 || start!=ps) $fwrite(fd,"%b2\n",start);
                if(n==0 || ready!=pr) $fwrite(fd,"%b3\n",ready);
                previous=word_out;ps=start;pr=ready;
            end
            $fclose(fd);
        end
    endtask
    initial begin
        repeat(3) tick(0,0,0);rst_n=1;
        if(dut.ready) $fatal(1,"ready before first full interval");
        frame(833333,480,1080,1);
        if(dut.ready) $fatal(1,"first edge is not a measured interval");
        frame(833333,480,1080,0);
        check(833333,480,1080,1);
        frame(1666667,480,1080,1);
        check(833333,480,1080,2);
        frame(1666667,480,1080,0);
        check(1666667,480,1080,3);
        tick(1,0,0);check(1666667,480,1080,4);
        tick(0,0,0);
        dump_capture();
        repeat(2000050) tick(0,0,0);
        if(!dut.flags[1]) $fatal(1,"stale flag did not assert");
        // 复位取消旧的完整周期，下一帧必须重新起算。
        rst_n=0;repeat(3) tick(0,0,0);rst_n=1;
        frame(60,4,3,1);
        tick(1,0,0);check(60,4,3,1);
        if(!dut.flags[3]) $fatal(1,"malformed geometry not flagged");
        // 一个VS边界切断有效行，前后区间必须都报告异常。
        tick(0,1,1);tick(0,1,1);tick(1,1,1);#12;
        if(!dut.last_boundary_error) $fatal(1,"cross-boundary line not flagged");
        tick(0,1,1);tick(0,0,0);tick(1,0,0);#12;
        if(!dut.last_boundary_error) $fatal(1,"new half line not flagged");
        // 溢出保护故障注入，检查饱和而不是静默回卷。
        @(negedge clk);#1;vs=0;hs=0;de=0;
        dut.period_count=32'hffffffff;
        @(negedge clk);#1;vs=1;
        #12;
        if(dut.last_period!==32'hffffffff || !dut.last_overflow)
            $fatal(1,"period saturation failed");
        if(packets<1000) $fatal(1,"insufficient telemetry checks");
        $display("FPS_MONITOR_PASS packets=%0d simulated_1080p_60_and_30_with_bubbles reset_stale_geometry_boundary_overflow",packets);
        $finish;
    end
endmodule
