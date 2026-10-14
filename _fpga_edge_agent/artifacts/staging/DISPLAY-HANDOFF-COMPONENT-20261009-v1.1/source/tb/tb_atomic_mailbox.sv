`timescale 1ns/1ps
module tb_atomic_mailbox #(parameter integer TEST_MAIL_WIDTH=1137,TEST_SRC_HALF_PS=5000,TEST_DST_HALF_PS=6734);
    logic src_clk=0,dst_clk=0,safe_reset_n=0,src_clock_enable=1,dst_clock_enable=1,finished=0;
    always #(TEST_SRC_HALF_PS/1000.0)if(src_clock_enable)src_clk=~src_clk;
    always #(TEST_DST_HALF_PS/1000.0)if(dst_clock_enable)dst_clk=~dst_clk;
    logic src_valid=0,dst_ready=0;wire src_ready,dst_valid,src_running,dst_running;
    logic [TEST_MAIL_WIDTH-1:0] src_data=0;wire [TEST_MAIL_WIDTH-1:0] dst_data;
    logic [TEST_MAIL_WIDTH-1:0] expected[$],front,last_held;
    logic held=0,random_ready=1;logic [31:0] random_state=32'h827539a6;
    integer log_file,accepted=0,delivered=0,reset_count=0,seed_counter=0,held_cycles=0;
    atomic_mailbox #(.PAYLOAD_WIDTH(TEST_MAIL_WIDTH)) dut(.*);
    function automatic logic [TEST_MAIL_WIDTH-1:0] pattern(input integer seed);
        logic [TEST_MAIL_WIDTH-1:0] value;
        for(integer bit_index=0;bit_index<TEST_MAIL_WIDTH;bit_index++)value[bit_index]=((seed*37+bit_index*11+7)%17)<8;
        return value;
    endfunction
    always @(negedge dst_clk)if(random_ready)begin
        random_state={random_state[30:0],random_state[31]^random_state[21]^random_state[1]^random_state[0]};
        dst_ready=random_state[3:0]!=0;
    end
    always @(posedge src_clk)if(safe_reset_n && src_valid && src_ready)begin
        expected.push_back(src_data);accepted++;$fwrite(log_file,"S,%0d,%h\n",seed_counter,src_data);
    end
    always @(posedge dst_clk)begin
        if(!safe_reset_n)held=0;
        else begin
            if(held && (!dst_valid || dst_data!==last_held))$fatal(1,"Mailbox held message changed");
            held=dst_valid&&!dst_ready;last_held=dst_data;if(held)held_cycles++;
            if(dst_valid&&dst_ready)begin
                if(expected.size()==0)$fatal(1,"Mailbox duplicate/unaccepted data");
                front=expected.pop_front();if(dst_data!==front)$fatal(1,"Mailbox torn payload");
                delivered++;$fwrite(log_file,"D,%h\n",dst_data);
            end
        end
    end
    task automatic reset_both;
        src_clock_enable=1;dst_clock_enable=1;safe_reset_n=0;src_valid=0;dst_ready=0;held=0;expected.delete();
        $fwrite(log_file,"RESET\n");reset_count++;
        repeat(6)@(negedge src_clk);safe_reset_n=1;repeat(6)@(negedge src_clk);
    endtask
    task automatic send_message;
        integer before_count;
        @(negedge src_clk);seed_counter++;before_count=accepted;src_data=pattern(seed_counter);src_valid=1;
        while(accepted==before_count)@(negedge src_clk);
        src_valid=0;
    endtask
    task automatic drain;
        integer waited=0;
        while((expected.size()!=0 || !src_ready) && waited<1000)begin @(negedge src_clk);waited++;end
        if(waited==1000)$fatal(1,"Mailbox failed drain/ack");
    endtask
    initial begin
        integer metrics;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        log_file=$fopen("mailbox-events.csv","w");reset_both();
        for(integer i=0;i<128;i++)begin send_message();repeat(i%3)@(negedge src_clk);end
        drain();random_ready=0;dst_ready=0;send_message();wait(dst_valid);
        repeat(31)@(negedge dst_clk);src_clock_enable=0;dst_ready=1;
        repeat(13)@(negedge dst_clk);if(src_ready)$fatal(1,"Source forgot pending while clock stopped");
        src_clock_enable=1;drain();
        dst_ready=0;send_message();wait(dst_valid);dst_clock_enable=0;
        repeat(31)@(negedge src_clk);if(src_ready)$fatal(1,"Unconsumed stopped destination released source");
        dst_clock_enable=1;dst_ready=1;drain();
        dst_ready=0;send_message();wait(dst_valid);repeat(9)@(negedge dst_clk);
        reset_both();random_ready=1;for(integer i=0;i<64;i++)send_message();drain();
        $fclose(log_file);metrics=$fopen("protocol-metrics.json","w");
        $fwrite(metrics,"{\"finished\":true,\"kind\":\"mailbox\",\"width\":%0d,\"accepted\":%0d,\"delivered\":%0d,\"resets\":%0d,\"held_cycles\":%0d}\n",TEST_MAIL_WIDTH,accepted,delivered,reset_count,held_cycles);$fclose(metrics);
        finished=1;$display("Atomic mailbox PASS width=%0d accepted=%0d delivered=%0d",TEST_MAIL_WIDTH,accepted,delivered);$finish;
    end
    initial begin #1000000;if(!finished)$fatal(1,"Mailbox suite watchdog");end
endmodule
