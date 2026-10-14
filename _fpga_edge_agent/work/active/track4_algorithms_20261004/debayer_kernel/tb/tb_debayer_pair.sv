`timescale 1ns/1ps
module tb_debayer_pair;
    logic clk=0,rst=1,iv=0,ready=0;
    always #5 clk=~clk;
    logic [179:0] window_pair;
    logic [10:0] x,y;
    logic [1:0] phase;
    logic [2:0] markers;
    logic [63:0] job;
    wire ir,ov;
    wire [47:0] rgb;
    wire [10:0] ox,oy;
    wire [2:0] om;
    wire [63:0] oj;
    raw10_debayer_pair dut(.clk(clk),.rst(rst),.in_valid(iv),.in_ready(ir),.in_window_pair(window_pair),
        .in_x_even(x),.in_y(y),.in_phase(phase),.in_markers(markers),.in_job_id(job),
        .out_valid(ov),.out_ready(ready),.out_rgb_pair(rgb),.out_x_even(ox),.out_y(oy),.out_markers(om),.out_job_id(oj));
    localparam logic [63:0] BASE_ID=64'h0100000000000000;
    logic [31:0] rng=32'h43106025;
    logic [136:0] held_body;
    bit held=0,accepted_cycle=0,force_stall=0,finished=0;
    integer input_file,event_file,fields,xi,yi,ph,mark,index=0;
    always @(negedge clk)begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        ready=!force_stall && rng[1:0]!=0;
    end
    always @(posedge clk)begin
        accepted_cycle=0;
        if(rst)begin held=0;if(event_file)$fwrite(event_file,"R\n");end
        else begin
            if(held && (!ov || {rgb,ox,oy,om,oj}!==held_body))$fatal(1,"RGB/metadata changed under stall");
            held=ov && !ready;held_body={rgb,ox,oy,om,oj};
            // 同沿先消费旧槽，再接受替代，账的顺序与握手语义一致。
            if(ov && ready)begin
                if($isunknown({rgb,ox,oy,om,oj}))$fatal(1,"unknown output");
                $fwrite(event_file,"O %0d %h %0d %0d %0d %h\n",integer'(oj-BASE_ID),rgb,ox,oy,om,oj);
            end
            if(iv && ir)begin $fwrite(event_file,"A %0d\n",integer'(job-BASE_ID));accepted_cycle=1;end
        end
    end
    initial begin
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        input_file=$fopen("stimulus.txt","r");event_file=$fopen("events.txt","w");
        if(!input_file || !event_file)$fatal(1,"fixture unavailable");
        repeat(4)@(negedge clk);rst=0;
        while(!$feof(input_file))begin
            @(negedge clk);iv=0;
            fields=$fscanf(input_file,"%h %d %d %d %h %d\n",window_pair,xi,yi,ph,job,mark);
            if(fields!=6)$fatal(1,"bad fixture");x=11'(xi);y=11'(yi);phase=2'(ph);markers=3'(mark);
            repeat(integer'(rng[4:3]))@(negedge clk);
            iv=1;
            do begin @(posedge clk);#2;end while(!accepted_cycle);
            @(negedge clk);iv=0;
            if(index%511==0)begin
                force_stall=1;ready=0;repeat(4)@(negedge clk);
                rst=1;@(negedge clk);rst=0;force_stall=0;
            end
            index++;
        end
        while(ov)@(negedge clk);
        repeat(3)@(negedge clk);
        $fclose(input_file);$fclose(event_file);
        finished=1;#1;$display("DK complete items=%0d",index);$finish;
    end
    initial begin #20000000;$fatal(1,"watchdog");end
endmodule
