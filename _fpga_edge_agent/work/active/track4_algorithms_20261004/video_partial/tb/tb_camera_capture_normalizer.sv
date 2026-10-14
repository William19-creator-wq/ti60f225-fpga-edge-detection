`timescale 1ns/1ps
module tb_camera_capture_normalizer;
    logic clk=0,rst=1;always #5 clk=~clk;
    logic in_valid=0,in_sof=0,in_eol=0,in_bad=0;logic [19:0] raw_pair=0;
    wire pixel_valid,sof,eol,eof,frame_end_valid,frame_end_good,error_valid;
    wire [19:0] raw_pair_out;wire [15:0] gray_pair;wire [10:0] x_even,y;wire [31:0] frame_id,frame_end_id;
    wire [2:0] frame_end_reason,error_reason;
    camera_capture_normalizer dut(.*);
    logic small_valid=0,small_sof=0,small_eol=0,small_bad=0;logic [19:0] small_raw=20'h54321;
    wire sp,ss,se,sf,send,sgood,serr;wire [19:0] sraw;wire [15:0] sgray;wire [10:0] sx,sy;
    wire [31:0] sid,sendid;wire [2:0] sreason,serreason;
    camera_capture_normalizer #(.WIDTH(4),.HEIGHT(2),.FIRST_FRAME_ID(32'hfffffffe)) boundary_capture(
        .clk(clk),.rst(rst),.in_valid(small_valid),.raw_pair(small_raw),.in_sof(small_sof),.in_eol(small_eol),.in_bad(small_bad),
        .pixel_valid(sp),.raw_pair_out(sraw),.gray_pair(sgray),.x_even(sx),.y(sy),.frame_id(sid),.sof(ss),.eol(se),.eof(sf),
        .frame_end_valid(send),.frame_end_id(sendid),.frame_end_good(sgood),.frame_end_reason(sreason),.error_valid(serr),.error_reason(serreason));
    logic finished=0;string run_dir;integer output_file,result_file,checks=0;
    function automatic [9:0] raw_pixel(input integer px,py);
        raw_pixel=(3*px+5*py+256*((px/120+py/90)%2))%1024;
    endfunction
    task automatic small_step(input logic valid,fs,le,bad,input logic expect_pixel,expect_error,expect_end,expect_good,input logic [2:0] reason);
        begin
            @(negedge clk);small_valid=valid;small_sof=fs;small_eol=le;small_bad=bad;
            @(posedge clk);#1;checks++;
            if(sp!==expect_pixel || serr!==expect_error || send!==expect_end)$fatal(1,"small capture pulse check%0d",checks);
            if(expect_error && serreason!==reason)$fatal(1,"small capture error priority check%0d",checks);
            if(expect_end && (sgood!==expect_good || sreason!==reason))$fatal(1,"small capture end check%0d",checks);
        end
    endtask
    task automatic reset_both;
        begin @(negedge clk);rst=1;in_valid=0;small_valid=0;repeat(2)@(posedge clk);@(negedge clk);rst=0;end
    endtask
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir))$fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected VIDEO fatal probe");
        output_file=$fopen({run_dir,"/capture-gray.bin"},"wb");if(!output_file)$fatal(1,"camera output open");
        reset_both();
        for(integer row=0;row<1080;row++)for(integer x=0;x<1920;x+=2)begin
            logic [9:0] a,b;
            a=raw_pixel(x,row);b=raw_pixel(x+1,row);
            @(negedge clk);in_valid=1;raw_pair={b,a};in_sof=x==0 && row==0;in_eol=x==1918;in_bad=0;
            @(posedge clk);#1;
            if(!pixel_valid || raw_pair_out!=={b,a} || gray_pair!=={b[9:2],a[9:2]} || x_even!=x || y!=row || frame_id!=0 ||
                sof!==(x==0 && row==0) || eol!==(x==1918) || eof!==(x==1918 && row==1079) || error_valid)$fatal(1,"1080p capture x%0d y%0d",x,row);
            if(frame_end_valid!==(x==1918 && row==1079))$fatal(1,"capture terminal position");
            if(frame_end_valid && (!frame_end_good || frame_end_id!=0 || frame_end_reason!=0))$fatal(1,"capture good end");
            $fwrite(output_file,"%c%c",gray_pair[7:0],gray_pair[15:8]);
        end
        @(negedge clk);in_valid=0;$fclose(output_file);
        small_step(1,0,0,0,0,1,0,0,1);small_step(1,0,0,0,0,0,0,0,0);
        small_step(1,1,1,1,0,1,0,0,4);small_step(1,1,1,0,0,1,0,0,3);
        small_step(0,1,1,1,0,0,0,0,0);small_step(1,1,0,0,1,0,0,0,0);
        if(sid!=32'hfffffffe || sx!=0 || sy!=0)$fatal(1,"first allocated ID");
        small_step(0,0,0,0,0,0,0,0,0);if(sid!=32'hfffffffe || sx!=0 || sy!=0)$fatal(1,"bubble changed payload");
        small_step(1,0,0,0,0,1,1,0,3);if(sendid!=32'hfffffffe)$fatal(1,"failed frame ID");
        small_step(1,1,0,0,1,0,0,0,0);if(sid!=32'hffffffff)$fatal(1,"last allocated ID");
        small_step(1,0,1,0,1,0,0,0,0);if(sx!=2 || sy!=0)$fatal(1,"small line end");
        small_step(1,0,0,0,1,0,0,0,0);if(sx!=0 || sy!=1)$fatal(1,"small next row");
        small_step(1,0,1,0,1,0,1,1,0);if(sendid!=32'hffffffff || !sf)$fatal(1,"last ID frame did not finish");
        small_step(1,1,1,0,0,1,0,0,5);small_step(1,1,0,1,0,1,0,0,5);
        reset_both();small_step(1,1,0,0,1,0,0,0,0);small_step(1,1,0,0,0,1,1,0,2);
        small_step(1,1,0,0,1,0,0,0,0);small_step(1,1,0,1,0,1,1,0,4);
        reset_both();small_step(1,1,0,0,1,0,0,0,0);small_step(1,0,1,0,1,0,0,0,0);
        small_step(1,0,1,0,0,1,1,0,3); // 新行首组EOL太早。
        reset_both();small_step(1,1,0,0,1,0,0,0,0);reset_both();
        @(posedge clk);#1;if(sp || send || serr)$fatal(1,"active frame reset retained obligation");
        small_step(1,1,0,0,1,0,0,0,0);if(sid!=32'hfffffffe)$fatal(1,"reset did not restore initial ID");
        small_step(1,0,1,0,1,0,0,0,0);small_step(1,0,0,0,1,0,0,0,0);small_step(1,0,1,0,1,0,1,1,0);
        result_file=$fopen({run_dir,"/camera-result.json"},"w");
        $fwrite(result_file,"{\"status\":\"PASS\",\"finished\":true,\"pairs\":1036800,\"small_checks\":%0d}\n",checks);
        $fclose(result_file);$display("PASS camera complete1080p and small checks%0d",checks);finished=1;$finish;
    end
endmodule
