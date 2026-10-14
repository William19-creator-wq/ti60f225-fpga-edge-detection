`timescale 1ns/1ps
module tb_video_async_fifo #(
    parameter integer WIDTH=128,DEPTH=1024,RECORDS=20480,RUN_PROTOCOL=1,
    parameter realtime WR_HALF=7.143,RD_HALF=5.0
);
    logic wr_clk=0,rd_clk=0,cold_reset_n=0,wr_clock_enable=1,rd_clock_enable=1,finished=0;
    always #(WR_HALF)if(wr_clock_enable)wr_clk=~wr_clk;
    always #(RD_HALF)if(rd_clock_enable)rd_clk=~rd_clk;
    logic wr_valid=0,rd_ready=0;logic [WIDTH-1:0] wr_data=0;
    wire wr_ready,wr_accept,wr_running,wr_overflow,rd_valid,rd_running,rd_fault;
    wire [31:0] wr_loss_count;wire [WIDTH-1:0] rd_data;
    video_async_fifo #(.WIDTH(WIDTH),.DEPTH(DEPTH)) dut(.*);
    logic [WIDTH-1:0] expected[$],sample,held_body;
    logic held=0,auto_reader=0;
    integer trace_handle,metrics_handle,rows_handle,case_id=-1,cases=0;
    integer attempted=0,accepted=0,delivered=0,lost=0,tx_index=0,read_ticks=0,streak=0,max_streak=0;
    integer total_accepted=0,total_delivered=0,total_lost=0,total_attempted=0;
    function automatic logic [WIDTH-1:0] record_value(input integer n,input integer epoch);
        logic [319:0] value;
        begin
            for(integer j=0;j<5;j++)value[j*64+:64]=((64'(n)+64'h146ce572)*64'h9e3779b97f4a7c15)^
                (64'(epoch)<<32)^(64'hfedcba9876543210>>(j+1))^64'(j);
            if(n==0)value='0;else if(n==1)value='1;else if(n==2)begin value='0;value[epoch%WIDTH]=1;end
            return value[WIDTH-1:0];
        end
    endfunction
    always @(posedge wr_clk)if(cold_reset_n && wr_running && wr_valid)begin
        attempted++;total_attempted++;
        if(wr_accept)begin expected.push_back(wr_data);accepted++;total_accepted++;end
        else begin lost++;total_lost++;end
        $fwrite(trace_handle,"W,%0d,%0d,%0d,%h\n",case_id,tx_index,wr_accept,wr_data);
    end
    always @(negedge rd_clk)if(auto_reader && rd_running)rd_ready=(read_ticks%11!=3 && read_ticks%11!=4);
    always @(posedge rd_clk)begin
        read_ticks++;
        if(read_ticks>12000000)$fatal(1,"Video FIFO TB watchdog case=%0d",case_id);
        if(!cold_reset_n || !rd_running)begin held=0;streak=0;end
        else begin
            if(held && (!rd_valid || rd_data!==held_body))$fatal(1,"Video FIFO held record changed case=%0d",case_id);
            held=rd_valid && !rd_ready;held_body=rd_data;
            if(rd_valid && rd_ready)begin
                if(expected.size()==0)$fatal(1,"Video FIFO produced unaccepted record case=%0d",case_id);
                sample=expected.pop_front();if(rd_data!==sample)$fatal(1,"Video FIFO record mismatch case=%0d index=%0d got=%h want=%h",case_id,delivered,rd_data,sample);
                delivered++;total_delivered++;streak++;if(streak>max_streak)max_streak=streak;
                $fwrite(trace_handle,"R,%0d,%h\n",case_id,rd_data);
            end else streak=0;
        end
    end
    task automatic reset_case(input logic stop_reader=0);
        wr_clock_enable=1;rd_clock_enable=1;auto_reader=0;
        @(negedge rd_clk);rd_ready=0;if(stop_reader)rd_clock_enable=0;
        @(negedge wr_clk);wr_valid=0;cold_reset_n=0;
        repeat(5)@(negedge wr_clk);
        if(expected.size()!=0)$fatal(1,"Test cold reset before old accepted prefix drained");
        case_id++;attempted=0;accepted=0;delivered=0;lost=0;max_streak=0;held=0;
        #3;cold_reset_n=1;
        while(!wr_running)@(negedge wr_clk);
        if(!stop_reader)while(!rd_running)@(negedge wr_clk);
        if(wr_overflow || wr_loss_count || rd_valid || (!stop_reader && rd_fault))$fatal(1,"Cold reset old data/fault revived");
    endtask
    task automatic send(input integer number,input logic gaps=0,input logic require_all=0);
        @(negedge wr_clk);
        for(integer i=0;i<number;i++)begin
            tx_index=attempted;wr_data=record_value(tx_index,case_id);wr_valid=1;
            @(posedge wr_clk);if(require_all && !wr_accept)$fatal(1,"Video continuous stream overflow case=%0d index=%0d",case_id,i);
            @(negedge wr_clk);
            if(gaps)begin wr_valid=0;repeat(3+(i%5))@(negedge wr_clk);end
        end
        wr_valid=0;
    endtask
    task automatic drain(input logic expect_fault=0);
        auto_reader=0;@(negedge rd_clk);rd_ready=1;
        while(delivered!=accepted)@(negedge rd_clk);
        repeat(14)@(negedge rd_clk);
        if(rd_valid || expected.size()!=0 || wr_loss_count!=lost || rd_fault!=expect_fault || wr_overflow!=expect_fault)$fatal(1,"Video FIFO closure/count/fault mismatch case=%0d accepted=%0d delivered=%0d loss=%0d actual_loss=%0d",case_id,accepted,delivered,lost,wr_loss_count);
        if(expect_fault && wr_ready)$fatal(1,"Video overflow unlocked after drain");
    endtask
    task automatic save_row(input string kind);
        if(cases)$fwrite(rows_handle,",\n");
        $fwrite(rows_handle,"{\"case\":%0d,\"kind\":\"%s\",\"attempted\":%0d,\"accepted\":%0d,\"delivered\":%0d,\"lost\":%0d,\"max_consecutive_read_clocks\":%0d}",case_id,kind,attempted,accepted,delivered,lost,max_streak);
        cases++;
    endtask
    initial begin
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        trace_handle=$fopen("fifo-wire.csv","w");rows_handle=$fopen("fifo-results.json","w");$fwrite(rows_handle,"[\n");
        reset_case();@(negedge rd_clk);rd_ready=1;send(RECORDS,0,1);drain();
        if(accepted!=RECORDS || max_streak<2)$fatal(1,"FIFO continuous throughput not observed");save_row("continuous");
        if(RUN_PROTOCOL)begin
            reset_case();auto_reader=1;send(DEPTH*5+37,1,1);drain();save_row("gaps_and_stalls");
            reset_case();send(2,0,1);repeat(32)@(negedge wr_clk);
            if(!rd_valid)$fatal(1,"FIFO prefetch did not expose held record");
            send(DEPTH+6,0,0);repeat(12)@(negedge wr_clk);
            if(accepted!=DEPTH+2 || lost!=6 || !rd_fault)$fatal(1,"FIFO finite capacity/fault channel case=%0d accepted=%0d lost=%0d",case_id,accepted,lost);
            drain(1);save_row("overflow_held");
            reset_case(1);if(rd_running)$fatal(1,"Stopped reader reset release fabricated");
            send(DEPTH+7,0,0);if(accepted!=DEPTH || !wr_overflow)$fatal(1,"Stopped reader capacity");
            rd_clock_enable=1;while(!rd_running || !rd_fault)@(negedge rd_clk);drain(1);save_row("stopped_reader");
            reset_case();@(negedge wr_clk);wr_clock_enable=0;@(negedge rd_clk);rd_ready=1;
            repeat(100)@(negedge rd_clk);if(rd_valid || rd_fault)$fatal(1,"Stopped writer created data");
            wr_clock_enable=1;send(DEPTH+31,1,1);drain();save_row("stopped_writer_resume");
            reset_case();@(negedge rd_clk);rd_ready=1;send(DEPTH*3+19,1,1);drain();save_row("cold_new_epoch");
        end
        $fwrite(rows_handle,"\n]\n");$fclose(rows_handle);$fclose(trace_handle);
        metrics_handle=$fopen("protocol-metrics.json","w");
        $fwrite(metrics_handle,"{\"finished\":true,\"cases\":%0d,\"width\":%0d,\"depth\":%0d,\"records\":%0d,\"attempted\":%0d,\"accepted\":%0d,\"delivered\":%0d,\"lost\":%0d,\"read_clocks\":%0d,\"write_half_ns\":%0.3f,\"read_half_ns\":%0.3f}\n",cases,WIDTH,DEPTH,RECORDS,total_attempted,total_accepted,total_delivered,total_lost,read_ticks,WR_HALF,RD_HALF);$fclose(metrics_handle);
        finished=1;$display("Video async FIFO PASS width=%0d depth=%0d cases=%0d accepted=%0d lost=%0d",WIDTH,DEPTH,cases,total_accepted,total_lost);$finish;
    end
endmodule
