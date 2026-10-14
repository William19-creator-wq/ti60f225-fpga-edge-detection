`timescale 1ns/1ps
module tb_pattern_pair_source;
    import r1_tb_text::*;
    parameter integer W=258,H=258;
    localparam integer N=W*H/2;
    reg clk=0,rst=1,start=0,stop=0,ready=0,finished=0;
    reg [1:0] pattern=0;reg [31:0] epoch=1,frame=11,config_id=17;
    reg median=1;reg [1:0] kind=1;reg [10:0] threshold=512;
    wire valid,sof,eol,eof,last;wire [47:0] rgb;wire [10:0] x,y;
    always #20 clk=~clk;
    pattern_pair_source #(.W(W),.H(H)) dut(.clk(clk),.rst(rst),.job_start(start),.job_stop(stop),
        .job_epoch(epoch),.job_frame_id(frame),.job_config_id(config_id),.job_median_enable(median),
        .job_output_kind(kind),.job_threshold(threshold),.job_pattern(pattern),.in_valid(valid),
        .in_ready(ready),.in_rgb(rgb),.in_x_even(x),.in_y(y),.in_sof(sof),.in_eol(eol),.in_eof(eof),.source_last_fire(last));
    integer fd,rf,p=0,cycles=0,count=0,held=0,boundaries=0;
    reg holding=0;reg [73:0] held_body;reg [111:0] snapshot;reg [47:0] golden;
    string path,result_path;
    initial begin
        if($test$plusargs("FAIL_PROBE")) $fatal(1,"Deliberate runner fatal-exit probe");
        if(!$value$plusargs("EXPECTED=%s",path) || !$value$plusargs("RESULT=%s",result_path) ||
           !$value$plusargs("PATTERN=%d",p)) $fatal(1,"Missing source fixture arguments");
        fd=$fopen(path,"r");if(!fd) $fatal(1,"Cannot open source golden");
        repeat(4) @(posedge clk);
        @(negedge clk) begin rst=0;start=1;pattern=p;end
        snapshot={pattern,threshold,kind,median,config_id,frame,epoch};
        @(negedge clk) start=0;
    end
    always @(negedge clk) if(!rst && !start) begin
        ready=(cycles%11)>1;
        // 活动时扰动外部配置，真实已锁快照和held事务必须不变。
        pattern=pattern+1;epoch=epoch+1;frame=frame+1;config_id=config_id+1;
        median=~median;kind=kind^1;threshold=threshold+1;
    end
    always @(posedge clk) begin
        cycles=cycles+1;if(cycles>N*3+100) $fatal(1,"Source bounded timeout");
        if(!rst && !start) begin
            if(dut.job_snapshot!==snapshot) $fatal(1,"Source job snapshot changed");
            if(holding && (!valid || {last,eof,eol,sof,y,x,rgb}!==held_body)) $fatal(1,"Source held payload changed");
            if(valid && !ready) begin holding=1;held_body={last,eof,eol,sof,y,x,rgb};held=held+1;end
            else holding=0;
            if(valid && ready) begin
                golden=read_hex(fd,12);
                if(rgb!==golden || x!==2*(count%(W/2)) || y!==count/(W/2) ||
                   sof!==(count==0) || eol!==((count%(W/2))==W/2-1) || eof!==(count==N-1) || last!==eof)
                    $fatal(1,"Pattern/coordinate/marker mismatch");
                if(x==30 || x==32 || x==128 || x==254 || x==256) boundaries=boundaries+1;
                count=count+1;
                if(count==N) begin
                    require_eof(fd);
                    #1;if(valid!==0) $fatal(1,"Source not empty after final real fire");
                    if(held==0 || boundaries!=5*H) $fatal(1,"Source boundary/held coverage incomplete");
                    rf=$fopen(result_path,"w");if(!rf) $fatal(1,"Cannot write source result");
                    $fdisplay(rf,"{\"finished\":true,\"pattern\":%0d,\"accepted_pairs\":%0d,\"compared_pairs\":%0d,\"boundary_pairs\":%0d,\"held_cycles\":%0d,\"numeric_errors\":0,\"protocol_errors\":0,\"cycles\":%0d}",p,count,count,boundaries,held,cycles);
                    $fclose(rf);finished=1;$finish;
                end
            end
        end
    end
endmodule
