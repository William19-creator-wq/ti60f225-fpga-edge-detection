`timescale 1ns/1ps
// 先负沿给稳定输入，正沿记旧fire；#1以后才检查提交后的寄存器。
module tb_stats_core #(parameter bit CHECK_FIT=0);
    logic clk=0,rst=1; always #5 clk=~clk;
    logic token_valid=0,token_ready,stat_valid,stat_ready=0;
    logic [261:0] token_body=0; logic [631:0] stat_body;
    wire fault_active,quiet; wire [7:0] fault_reason;
    stats_core dut(.*);
    logic fit_req_valid=0,fit_rsp_ready=0,cancel_valid=0;
    logic [621:0] fit_req_body=0; logic [175:0] cancel_id=0;
    wire fit_req_ready,fit_rsp_valid,fit_quiet; wire [584:0] fit_rsp_body;
    generate if(CHECK_FIT) begin: joined
        fit_core fit(.clk(clk),.rst(rst),.req_valid(fit_req_valid),.req_ready(fit_req_ready),.req_body(fit_req_body),
            .rsp_valid(fit_rsp_valid),.rsp_ready(fit_rsp_ready),.rsp_body(fit_rsp_body),
            .cancel_valid(cancel_valid),.cancel_id(cancel_id),.quiet(fit_quiet));
    end else begin
        assign fit_req_ready=0; assign fit_rsp_valid=0; assign fit_rsp_body=0; assign fit_quiet=!rst;
    end endgenerate
    logic finished=0,record_inputs=0;
    string run_dir,label;
    integer case_file,input_file,actual_file,stat_file,result_file,ncases,ntokens,continuous,rc;
    integer accepted_points=0,fit_calls=0,case_index=0,cycle=0,formed_max=0;
    integer eligible=0,committed=0,discarded=0,reset_aborted=0;
    integer contexts_accepted=0,stats_consumed=0,contexts_reset=0,live_context=0;
    logic [263:0] input_word;
    logic [631:0] expected_stat,observed_stat;
    logic [584:0] expected_rsp;
    logic [621:0] readable_request;
    logic [584:0] readable_response;

    always @(posedge clk) begin
        cycle=cycle+1;
        if(!rst) begin
            if(token_valid && token_ready && dut.state==dut.IDLE)begin contexts_accepted++;live_context++;end
            if(stat_valid && stat_ready)begin stats_consumed++;live_context--;end
            if(live_context<0 || live_context>1)$fatal(1,"context accounting");
            if(record_inputs && token_valid && token_ready) begin
                // 固定33字节网络序：与输入文件逐字节比较，保留真正fire流。
                for(integer b=32;b>=0;b--) $fwrite(actual_file,"%c",input_word[b*8+:8]);
                if(token_body[177:176]==1) accepted_points=accepted_points+1;
            end
            if(dut.dispatch_point) eligible=eligible+1;
            if(dut.pipeline_valid[3]) begin
                if(dut.can_commit && dut.commit_reason==0) committed=committed+1;
                else discarded=discarded+1;
            end
        end else begin
            if(live_context)begin contexts_reset++;live_context=0;end
            for(integer stage=0;stage<4;stage++) if(dut.pipeline_valid[stage]===1'b1) reset_aborted++;
        end
    end

    task automatic cold_reset;
        begin
            @(negedge clk); token_valid=0; stat_ready=0; fit_req_valid=0; fit_rsp_ready=0; cancel_valid=0; rst=1;
            repeat(2) @(posedge clk);
            @(negedge clk); rst=0;
        end
    endtask

    task automatic reset_closing_phase(input integer position);
        logic [175:0] id;logic [83:0] h,p;logic [631:0] golden;integer waits;
        begin
            cold_reset();id=176'd99;h=0;h[0+:11]=6;h[11+:11]=5;h[22+:5]=11;h[27+:8]=1;h[51+:21]=1;
            offer(stats_protocol_pkg::token(id,0,h));p=0;p[21]=1;p[22+:11]=1;p[33+:11]=1;p[44+:11]=1;p[55+:11]=1;
            offer(stats_protocol_pkg::token(id,1,p));offer(stats_protocol_pkg::token(id,2,84'd1));
            @(negedge clk);token_valid=0;waits=0;
            while(dut.state!=(position==0?dut.DRAIN:(position==1?dut.PACK:dut.HELD)))begin
                @(posedge clk);#1;waits++;if(waits>16)$fatal(1,"reset closing stage not reached");
            end
            cold_reset();repeat(3)begin @(posedge clk);#1;if(stat_valid || !quiet)$fatal(1,"closing reset retained old result");end
            // 每次作废后换尺寸、kind和ID，检查新配置确实生效。
            id=176'd199+position;h=0;h[0+:11]=8;h[11+:11]=7;h[22+:5]=18;h[27+:8]=1;
            golden={8'd0,2'd0,stats_protocol_pkg::pack_numeric(id,h,21'd0,56'sd0,56'sd0,56'sd0,56'sd0,56'sd0,1'b1)};
            offer(stats_protocol_pkg::token(id,0,h));offer(stats_protocol_pkg::token(id,2,84'd0));
            @(negedge clk);token_valid=0;waits=0;
            while(!stat_valid)begin @(posedge clk);#1;waits++;if(waits>6)$fatal(1,"reset recovery bound");end
            if(stat_body!==golden)$fatal(1,"new header after closing reset");
            @(negedge clk);stat_ready=1;@(posedge clk);#1;@(negedge clk);stat_ready=0;
        end
    endtask
    task automatic offer(input logic [261:0] body);
        integer wait_count;
        begin
            @(negedge clk); token_body=body; token_valid=1; wait_count=0;
            do begin @(posedge clk); wait_count++; if(wait_count>20) $fatal(1,"token did not progress"); end while(!token_ready);
            #1;
        end
    endtask
    task automatic check_fit(input logic [621:0] request,input logic [584:0] golden);
        integer waits;
        begin
            @(negedge clk); fit_req_body=request; fit_req_valid=1;
            do @(posedge clk); while(!fit_req_ready);
            #1; @(negedge clk); fit_req_valid=0; waits=0;
            while(!fit_rsp_valid) begin @(posedge clk); #1; waits++; if(waits>16384) $fatal(1,"FIT formation timeout case%0d",case_index); end
            if(fit_rsp_body!==golden) $fatal(1,"FIT mismatch case%0d actual=%h golden=%h",case_index,fit_rsp_body,golden);
            repeat(7) begin @(posedge clk); #1; if(fit_rsp_body!==golden || !fit_rsp_valid) $fatal(1,"FIT held changed"); end
            @(negedge clk); fit_rsp_ready=1; @(posedge clk); #1; @(negedge clk); fit_rsp_ready=0;
            if(!fit_quiet) $fatal(1,"FIT did not release"); fit_calls++;
        end
    endtask
    task automatic reset_stage(input integer position);
        logic [175:0] id; logic [83:0] h,p;
        begin
            cold_reset(); id=176'd1; h=0; h[0+:11]=6;h[11+:11]=5;h[22+:5]=11;h[27+:8]=1;h[51+:21]=3;
            offer(stats_protocol_pkg::token(id,0,h));
            if(position>0) begin
                p=0;p[21]=1;p[22+:11]=1;p[33+:11]=1;p[44+:11]=1;p[55+:11]=1;
                offer(stats_protocol_pkg::token(id,1,p));
                @(negedge clk); token_valid=0;
                repeat(position-1) @(posedge clk);
            end
            cold_reset(); repeat(3) begin @(posedge clk); #1; if(stat_valid || !quiet) $fatal(1,"reset stage left old obligation"); end
        end
    endtask

    task automatic fit_cancel_trial(input integer mode);
        integer waits;
        logic [584:0] golden;
        begin
            cold_reset();golden=(mode<2)?fit_protocol_pkg::pack_response(readable_request,fit_protocol_pkg::CANCEL_DROP,8'd0,385'd0):readable_response;
            @(negedge clk);fit_req_body=readable_request;fit_req_valid=1;
            cancel_id=readable_request[175:0] ^ (mode==3?176'd1:176'd0);cancel_valid=mode==0 || mode==3;
            do @(posedge clk);while(!fit_req_ready);
            #1;@(negedge clk);fit_req_valid=0;cancel_valid=0;
            if(mode==1) begin repeat(10) @(negedge clk);cancel_valid=1;@(posedge clk);#1;@(negedge clk);cancel_valid=0;end
            waits=0;
            while(!fit_rsp_valid) begin @(posedge clk);#1;waits++;if(waits>16384)$fatal(1,"FIT cancel did not drain");end
            if(fit_rsp_body!==golden)$fatal(1,"FIT cancel mode%0d",mode);
            if(mode==2) begin
                @(negedge clk);cancel_valid=1;repeat(3)begin @(posedge clk);#1;if(!fit_rsp_valid || fit_rsp_body!==golden)$fatal(1,"cancel rewrote held FIT");end
            end
            @(negedge clk);fit_rsp_ready=1;cancel_valid=mode==4;cancel_id=readable_request[175:0];
            @(posedge clk);#1;@(negedge clk);fit_rsp_ready=0;cancel_valid=0;
            if(!fit_quiet)$fatal(1,"FIT cancel quiet failed");
        end
    endtask

    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir)) $fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE")) $fatal(1,"expected STATS fatal probe");
        label=CHECK_FIT?"fit":"core";
        case_file=$fopen({run_dir,"/vectors/cases.txt"},"r"); input_file=$fopen({run_dir,"/vectors/tokens.bin"},"rb");
        actual_file=$fopen({run_dir,"/",label,"-tokens.bin"},"wb"); stat_file=$fopen({run_dir,"/",label,"-stat.tsv"},"w");
        if(!case_file || !input_file || !actual_file || !stat_file) $fatal(1,"file open");
        rc=$fscanf(case_file,"%d\n",ncases); if(rc!=1) $fatal(1,"case count");
        for(case_index=0;case_index<ncases;case_index++) begin: cases
            integer formation,hold_cycles;
            rc=$fscanf(case_file,"%d %h %h %d\n",ntokens,expected_stat,expected_rsp,continuous);
            if(rc!=4) $fatal(1,"case descriptor %0d",case_index);
            cold_reset(); record_inputs=1;
            for(integer t=0;t<ntokens;t++) begin
                rc=$fread(input_word,input_file); if(rc!=33 || input_word[263:262]!=0) $fatal(1,"token binary %0d/%0d",case_index,t);
                offer(input_word[261:0]);
                if(!continuous) begin
                    @(negedge clk); token_valid=0;
                    repeat((t+case_index)%4) @(posedge clk);
                end
            end
            @(negedge clk); token_valid=0; formation=0;
            while(!stat_valid) begin @(posedge clk); #1; formation++; if(formation>6) $fatal(1,"STAT closing bound case%0d",case_index); end
            if(formation>formed_max) formed_max=formation;
            observed_stat=stat_body;
            if(case_index==1024)begin readable_request=observed_stat[621:0];readable_response=expected_rsp;end
            if(observed_stat!==expected_stat) $fatal(1,"STAT case%0d actual=%h expected=%h",case_index,observed_stat,expected_stat);
            $fwrite(stat_file,"%0d %h\n",case_index,observed_stat);
            case(case_index%4) 0:hold_cycles=1;1:hold_cycles=7;2:hold_cycles=31;default:hold_cycles=257;endcase
            repeat(hold_cycles) begin @(posedge clk); #1;
                if(!stat_valid || stat_body!==observed_stat || token_ready) $fatal(1,"held STAT changed");
            end
            @(negedge clk); stat_ready=1; @(posedge clk); #1; @(negedge clk); stat_ready=0; record_inputs=0;
            if(!quiet) $fatal(1,"stats did not release");
            if(CHECK_FIT && observed_stat[623:622]==0) check_fit(observed_stat[621:0],expected_rsp);
            else if(CHECK_FIT && fit_protocol_pkg::pack_response(observed_stat[621:0],observed_stat[623:622],observed_stat[631:624],385'd0)!==expected_rsp)
                $fatal(1,"failure bypass mismatch");
            if(case_index%128==0 || ntokens>2000000) $display("STATS %s case%0d points%0d",label,case_index,accepted_points);
        end
        if($fread(input_word,input_file)!=0) $fatal(1,"extra binary token");
        if(CHECK_FIT)for(integer mode=0;mode<5;mode++)fit_cancel_trial(mode);
        for(integer position=0;position<3;position++)reset_closing_phase(position);
        for(integer position=0;position<6;position++) reset_stage(position);
        if(eligible!=committed+discarded+reset_aborted) $fatal(1,"pipeline accounting %0d != %0d+%0d+%0d",eligible,committed,discarded,reset_aborted);
        if(live_context!=0 || contexts_accepted!=stats_consumed+contexts_reset)$fatal(1,"terminal context accounting");
        $fclose(case_file);$fclose(input_file);$fclose(actual_file);$fclose(stat_file);
        result_file=$fopen({run_dir,"/",label,"-result.json"},"w");
        $fwrite(result_file,"{\"status\":\"PASS\",\"finished\":true,\"cases\":%0d,\"points\":%0d,\"fit_calls\":%0d,\"closing_formation_max\":%0d,\"eligible\":%0d,\"committed\":%0d,\"discarded\":%0d,\"reset_aborted\":%0d}\n",ncases,accepted_points,fit_calls,formed_max,eligible,committed,discarded,reset_aborted);
        // 给包装层连续赋值一次传播机会，再由运行脚本读取finished。
        $fclose(result_file); $display("PASS STATS %s cases%0d points%0d",label,ncases,accepted_points); finished=1;#1;$finish;
    end
    initial begin repeat(200000000) @(posedge clk); $fatal(1,"suite cycle watchdog"); end
endmodule
