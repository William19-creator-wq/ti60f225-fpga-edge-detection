`timescale 1ns/1ps
module tb_stats_helpers;
    import stats_protocol_pkg::*;
    logic finished=0;
    integer checks=0,bits;
    logic signed [56:0] minimum,maximum;
    task automatic require(input logic actual,input logic expected);
        begin if(actual!==expected) $fatal(1,"qualification boundary check %0d",checks); checks++; end
    endtask
    initial begin
        for(integer tls=0;tls<2;tls++) for(integer s=0;s<5;s++) begin
            if(tls) bits=(s<2)?33:((s<4)?43:44);
            else bits=(s==1)?44:((s>=3)?56:43);
            minimum=((!tls && (s==0 || s==2)) || (tls && (s==2 || s==3)))?0:-(57'sd1<<<(bits-1));
            maximum=minimum==0?((57'sd1<<<bits)-1):((57'sd1<<<(bits-1))-1);
            require(fits_accumulator(minimum,tls,s),1); require(fits_accumulator(maximum,tls,s),1);
            require(fits_accumulator(minimum-1,tls,s),0); require(fits_accumulator(maximum+1,tls,s),0);
            require(fits_accumulator(0,tls,s),1);
        end
        require(fits_raw_count(23'd4194302),1); require(fits_raw_count(23'd4194303),1);
        require(fits_raw_count(23'd4194304),0);
        require(qualify_commit(22'd2073600,22'd2073600,0,0,0,0,0,0)==0,1);
        require(qualify_commit(22'd2073601,22'd2073600,0,0,0,0,0,0)==7,1);
        require(qualify_commit(22'd2097152,22'd4194303,0,0,0,0,0,0)==7,1);
        require(qualify_commit(22'd2073601,22'd2073600,0,-57'sd1,0,0,0,0)==7,1);
        require(qualify_commit(22'd1,22'd2073600,0,-57'sd1,0,0,0,0)==8,1);
        require(qualify_commit(22'd1,22'd2073600,1,0,0,0,-57'sd1,0)==8,1);
        $display("PASS STATS helper checks=%0d",checks); finished=1; $finish;
    end
endmodule
