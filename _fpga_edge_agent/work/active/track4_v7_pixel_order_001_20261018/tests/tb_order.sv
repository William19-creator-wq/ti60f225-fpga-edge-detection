`timescale 1ns/1ps
module order_case #(parameter FIX=0)(output reg done=0);
    reg clk=0;always #10 clk=~clk;
    reg rst_n=0,iv=0,sop=0,eop=0,period=0,stall=0;
    reg [31:0] source=0;
    wire [39:0] raw10={source[31:24],2'b10,source[23:16],2'b01,source[15:8],2'b11,source[7:0],2'b00};
    wire [31:0] din;
    // These wrappers are extracted from the actual baseline/new top-level .vin.
    generate if(FIX) vin_corrected actual_vin(raw10,din);
    else vin_original actual_vin(raw10,din); endgenerate
    wire ov,os,oe;wire [127:0] packed_data;
    ser2par_v1 #(.I_VID_WIDTH(32),.O_VID_WIDTH(128)) packer(
        .clk(clk),.rst_n(rst_n),.i_valid(iv),.i_frame_start(sop),.i_frame_end(eop),.frame_stable(1'b1),.frame_pix_num(24'd960),
        .i_data(din),.o_valid(ov),.o_data(packed_data),.o_frame_start(os),.o_frame_end(oe));
    reg [127:0] mem[0:511];integer nw=0,nr=0,received=0,case_id=0,cycles=0;
    reg [127:0] rddata=0;reg rdvalid=0;wire rden,tv;wire [15:0] td;
    wire empty=nr>=nw;
    vid_par2ser #(.I_VID_WIDTH(128),.O_VID_WIDTH(16)) unpacker(
        .clk(clk),.rst_n(rst_n),.frame_period(period),.rd_fifo_rdvalid(rdvalid),.rd_fifo_rddata(rddata),.rd_fifo_rdempty(empty),
        .rd_fifo_rden(rden),.tx_fifo_valid(tv),.wr_fifo_full(stall),.tx_fifo_wrdata(td));
    function automatic [7:0] pix(input integer n);pix=(n*37+19)%256;endfunction
    integer k,s,idx,expect_idx;
    always @(posedge clk)begin
        if(!rst_n)begin nw=0;nr=0;received=0;cycles=0;rdvalid<=0;end
        else begin
            cycles=cycles+1;
            if(ov)begin mem[nw]=packed_data;nw=nw+1;end
            rdvalid<=rden&&!empty;
            if(rden&&!empty)begin rddata<=mem[nr];nr=nr+1;end
            if(tv)begin
                for(s=0;s<2;s=s+1)begin
                    idx=received+s;expect_idx=FIX?idx:(idx^2);
                    if(td[s*8+:8]!==pix(expect_idx))$fatal(1,"ORDER mismatch FIX=%0d case=%0d pixel=%0d got=%h exp=%h",FIX,case_id,idx,td[s*8+:8],pix(expect_idx));
                    if(idx<16 && case_id==0)$display("TRACE FIX=%0d output_index=%0d input_index=%0d value=%0d",FIX,idx,expect_idx,td[s*8+:8]);
                end
                received=received+2;
                if(received>3840)$fatal(1,"Extra pixels");
            end
        end
    end
    initial begin
        for(case_id=0;case_id<3;case_id=case_id+1)begin
            @(negedge clk);rst_n=0;iv=0;sop=0;eop=0;period=0;stall=0;
            repeat(8)@(negedge clk);rst_n=1;
            repeat(5)@(negedge clk);period=1;
            for(k=0;k<960;k=k+1)begin
                if(case_id>0 && (k%7)==3)begin @(negedge clk);iv=0;sop=0;eop=0;repeat(k%3)@(negedge clk);end
                @(negedge clk);iv=1;sop=(k==0);eop=(k==959);
                source={pix(k*4+3),pix(k*4+2),pix(k*4+1),pix(k*4)};
            end
            @(negedge clk);iv=0;sop=0;eop=0;
            wait(received==3840);repeat(30)@(negedge clk);
            if(nw!=240 || nr!=240)$fatal(1,"Memory beat count %0d %0d",nw,nr);
            $display("ORDER_CASE_PASS FIX=%0d case=%0d pixels=%0d beats=%0d",FIX,case_id,received,nw);
        end
        @(negedge clk);rst_n=0;done=1;
    end
    // This models the actual almost-full headroom signal, not a hard-ready contract.
    always @(negedge clk)if(rst_n && case_id==2)stall=((cycles%53)>=17 && (cycles%53)<29);else stall=0;
endmodule
module tb_order;
    wire a,b;order_case #(.FIX(0)) original_path(a);order_case #(.FIX(1)) corrected_path(b);
    initial begin wait(a&&b);$display("PIXEL_ORDER_PASS original_xor2_reproduced corrected_identity pixels_per_variant=11520 scenarios=3");$finish;end
    initial begin #2000000;$fatal(1,"TIMEOUT");end
endmodule
