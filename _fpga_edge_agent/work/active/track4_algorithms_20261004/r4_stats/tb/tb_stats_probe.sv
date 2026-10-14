`timescale 1ns/1ps
module tb_stats_probe;
    logic clk_25m=0,key1_n=0,tail_key=0;always #5 clk_25m=~clk_25m;
    wire led0,led1,tail_led0,tail_led1;
    stats_probe_top main(.clk_25m(clk_25m),.key1_n(key1_n),.led0(led0),.led1(led1));
    stats_probe_top #(.FIRST_SEQUENCE(64'hfffffffffffffffe)) tail(.clk_25m(clk_25m),.key1_n(tail_key),.led0(tail_led0),.led1(tail_led1));
    logic finished=0,log_main=1,log_tail=0;
    string run_dir;integer ledger,result_file,cycle=0,segment=0,closed_main=0,closed_tail=0;
    logic [584:0] held_word;
    task automatic record(input string who,input integer seg,
        input logic tv,tr,input logic [261:0] tb,
        input logic sv,sr,input logic [631:0] sb,
        input logic nv,nr,input logic [621:0] nb,
        input logic rv,rr,input logic [584:0] rb,
        input logic ov,ready,input logic [584:0] ob,
        input logic done,input logic [31:0] crc,inout integer closed);
        begin
            if(tv && tr) $fwrite(ledger,"%s %0d T %0d %h\n",who,seg,cycle,tb);
            if(sv && sr) $fwrite(ledger,"%s %0d S %0d %h\n",who,seg,cycle,sb);
            if(nv && nr) $fwrite(ledger,"%s %0d N %0d %h\n",who,seg,cycle,nb);
            if(rv && rr) $fwrite(ledger,"%s %0d R %0d %h\n",who,seg,cycle,rb);
            if(ov && ready) $fwrite(ledger,"%s %0d O %0d %h\n",who,seg,cycle,ob);
            if(done) begin $fwrite(ledger,"%s %0d C %0d %h\n",who,seg,cycle,crc);closed++;end
        end
    endtask
    always @(posedge clk_25m) begin
        cycle++;
        if(log_main && !main.core_rst) begin
            record("M",segment,main.token_valid,main.token_ready,main.token_slot,main.stat_valid,main.stat_ready,main.stat_body,
                main.fit_req_valid,main.fit_req_ready,main.request_slot,main.fit_rsp_valid,main.fit_rsp_ready,main.fit_rsp_body,
                main.observer_valid,main.observer_ready,main.response_word,main.observer_done,main.next_crc,closed_main);
            if(main.protocol_fault) $fatal(1,"main protocol fault");
        end
        if(log_tail && !tail.core_rst) begin
            record("T",0,tail.token_valid,tail.token_ready,tail.token_slot,tail.stat_valid,tail.stat_ready,tail.stat_body,
                tail.fit_req_valid,tail.fit_req_ready,tail.request_slot,tail.fit_rsp_valid,tail.fit_rsp_ready,tail.fit_rsp_body,
                tail.observer_valid,tail.observer_ready,tail.response_word,tail.observer_done,tail.next_crc,closed_tail);
            if(tail.protocol_fault) $fatal(1,"tail protocol fault");
        end
    end
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir)) $fatal(1,"RUN_DIR missing");
        ledger=$fopen({run_dir,"/probe-ledger.tsv"},"w");if(!ledger) $fatal(1,"ledger open");
        $fwrite(ledger,"M 0 B 0 0000000000000000\n");
        repeat(3) @(negedge clk_25m);key1_n=1;
        // 暂停观察者，只动ready，不修改身份、数值或真实返回。
        while(!main.observer_valid) @(negedge clk_25m);
        force main.observer_ready=1'b0;held_word=main.response_word;
        repeat(8) begin @(posedge clk_25m);#1;
            if(!main.observer_valid || main.response_word!==held_word || main.token_valid) $fatal(1,"observer held changed");
        end
        @(negedge clk_25m);release main.observer_ready;
        while(closed_main<64) begin @(posedge clk_25m);#1;end
        @(negedge clk_25m);key1_n=0;segment=1;closed_main=0;
        $fwrite(ledger,"M 1 B %0d 0000000000000000\n",cycle);
        repeat(3) @(negedge clk_25m);key1_n=1;
        while(closed_main<4) begin @(posedge clk_25m);#1;end
        @(negedge clk_25m);key1_n=0;log_main=0;log_tail=1;
        $fwrite(ledger,"T 0 B %0d fffffffffffffffe\n",cycle);tail_key=1;
        while(closed_tail<2) begin @(posedge clk_25m);#1;end
        repeat(257) begin @(posedge clk_25m);#1;if(tail.token_valid || tail.observer_valid) $fatal(1,"sequence exhaustion wrapped");end
        if(tail.source_phase!==tail.HALT) $fatal(1,"tail not halted");
        $fclose(ledger);result_file=$fopen({run_dir,"/probe-result.json"},"w");
        $fwrite(result_file,"{\"status\":\"PASS\",\"finished\":true,\"first_segment_jobs\":64,\"reset_segment_jobs\":4,\"tail_jobs\":2,\"cycles\":%0d}\n",cycle);
        $fclose(result_file);$display("PASS STATS probe64+4+2");finished=1;$finish;
    end
    initial begin repeat(2000000) @(posedge clk_25m);$fatal(1,"probe finite deadline");end
endmodule
