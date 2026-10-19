`timescale 1ns/1ps
module tb_control;
    parameter N=4;
    reg clk=0;always #5 clk=~clk;
    reg rst=1,inc=0,dec=0,mode_key=0;
    wire [2:0] mode;wire [10:0] threshold;
    v7_algorithm_control #(.DEBOUNCE_CYCLES(N)) dut(
        .clk(clk),.rst(rst),.key_inc_n(inc),.key_dec_n(dec),.key_mode_n(mode_key),
        .mode(mode),.threshold(threshold));
    task tick(input integer n);repeat(n)@(negedge clk);endtask
    task check(input integer m,t);
        if(mode!==m||threshold!==t)$fatal(1,"control got mode=%0d threshold=%0d expected=%0d/%0d",mode,threshold,m,t);
    endtask
    task push(input integer key_id);
        begin
            case(key_id)0:inc=0;1:dec=0;2:mode_key=0;endcase
            tick(N+8);
            case(key_id)0:inc=1;1:dec=1;2:mode_key=1;endcase
            tick(N+8);
        end
    endtask
    integer i,expected,mode_order[0:6];
    initial begin
        mode_order[0]=2;mode_order[1]=6;mode_order[2]=3;mode_order[3]=4;
        mode_order[4]=5;mode_order[5]=0;mode_order[6]=1;
        tick(4);rst=0;tick(N*3+8);check(1,256); // startup-held keys cannot trigger
        inc=1;dec=1;mode_key=1;tick(N+8);
        // Every bounce is shorter than N stable samples, including minimum N=2.
        repeat(4)begin inc=0;tick(1);inc=1;tick(N+4);end
        check(1,256);
        inc=0;tick(N+8);check(1,288);tick(N*8);check(1,288);
        inc=1;tick(N+8);push(0);check(1,320);push(1);check(1,288);
        inc=0;dec=0;tick(N+8);check(1,288);inc=1;dec=1;tick(N+8);
        for(i=0;i<7;i=i+1)begin push(2);check(mode_order[i],288);end
        expected=288;
        for(i=0;i<70;i=i+1)begin push(0);expected=expected+32;if(expected>2047)expected=2047;check(1,expected);end
        for(i=0;i<70;i=i+1)begin push(1);expected=expected<32?0:expected-32;check(1,expected);end
        rst=1;mode_key=0;tick(4);rst=0;tick(N+8);check(1,256);
        mode_key=1;tick(N+8);push(2);check(2,256);
        $display("CONTROL_PASS debounce=%0d; startup-held,bounce,hold,release,mode_order,simultaneous,saturation,reset",N);
        $finish;
    end
endmodule

