`timescale 1ns/1ps
module tb_r1_observer_supervisor;
    import r1_tb_text::*;
    localparam integer W=4,H=3,N=6;
    reg clk=0,rst=1,jready=0,source_last=0,ov=0,sv=0,finished=0;
    reg [15:0] m=0;reg [1:0] edge_bits=0;reg [10:0] x=0,y=0;reg sof=0,eol=0,eof=0;
    reg [31:0] oe=0,ofr=0,oc=0,se=0,sfr=0,sc=0;reg [2:0] code=0;
    reg [20:0] sin=0,sout=0;
    wire jvalid,jstart,accept_records,org,srg,good,done,tgood,median,lastvalid,lastgood;
    wire [31:0] je,jf,jc,lastcrc,le,lf,lc;wire [1:0] kind,pattern;
    wire [10:0] threshold;wire [20:0] data_pairs,lin,lout,ldata;wire [2:0] laststatus;
    wire led0,led1;
    always #20 clk=~clk;
    r1_job_supervisor #(.W(W),.H(H)) supervisor(.clk(clk),.rst(rst),.job_valid(jvalid),.job_ready(jready),
        .job_epoch(je),.job_frame_id(jf),.job_config_id(jc),.job_median_enable(median),
        .job_output_kind(kind),.job_pattern(pattern),.job_threshold(threshold),.job_start(jstart),
        .source_last_fire(source_last),.accept_records(accept_records),.status_valid(sv),.status_ready(srg),
        .status_code(code),.status_epoch(se),.status_frame_id(sfr),.status_config_id(sc),
        .status_in_pairs(sin),.status_out_pairs(sout),.data_pairs(data_pairs),.terminal_accepted_good(good),
        .terminal_crc_done(done),.terminal_good(tgood));
    result_crc_observer observer(.clk(clk),.rst(rst),.job_start(jstart),.accept_records(accept_records),
        .out_valid(ov),.out_ready(org),.out_y_filtered(m),.out_edge(edge_bits),.out_x_even(x),.out_y(y),
        .out_sof(sof),.out_eol(eol),.out_eof(eof),.out_epoch(oe),.out_frame_id(ofr),.out_config_id(oc),
        .status_valid(sv),.status_ready(srg),.status_code(code),.status_epoch(se),.status_frame_id(sfr),
        .status_config_id(sc),.status_in_pairs(sin),.status_out_pairs(sout),.terminal_accepted_good(good),
        .data_pairs(data_pairs),.terminal_crc_done(done),.terminal_good(tgood),.last_result_valid(lastvalid),
        .last_crc(lastcrc),.last_status(laststatus),.last_epoch(le),.last_frame_id(lf),.last_config_id(lc),
        .last_in_pairs(lin),.last_out_pairs(lout),.last_data_pairs(ldata),.last_good(lastgood));
    r1_led_status #(.W(W),.H(H)) leds(.clk(clk),.rst(rst),.last_result_valid(lastvalid),.last_good(lastgood),
        .last_status(laststatus),.last_crc(lastcrc),.last_in_pairs(lin),.last_out_pairs(lout),.last_data_pairs(ldata),.led0(led0),.led1(led1));
    integer sf,ef,cf,mf,rf,cycles=0,records=0,crc_checks=0,cases=0,shift_count=0,fo_stalls=0,fs_stalls=0;
    integer ci,j,n,drain,expected_good,reset_before,rc;
    reg [31:0] sequence_value,expected_crc,capture_crc;
    reg pending=0,held_terminal=0,old_busy;
    reg [159:0] incoming,golden,held_record;
    string stim_path,crc_path,meta_path,result_path,cid;
    task automatic reset_domain;
        begin
            @(negedge clk) begin rst=1;jready=0;ov=0;sv=0;source_last=0;end
            repeat(4) @(posedge clk);
            @(negedge clk) begin rst=0;end
        end
    endtask
    task automatic start_job;
        begin
            @(negedge clk) jready=1;
            do @(posedge clk); while(!jstart);
            @(negedge clk) jready=0;
        end
    endtask
    task automatic offer_record(input reg [159:0] record_value,input bit terminal);
        begin
            @(negedge clk);
            if(terminal) begin
                {sc,sfr,se,sout,sin,code}=record_value[140:0];sv=1;
            end else begin
                {eof,eol,sof,oc,ofr,oe,y,x,edge_bits,m}=record_value[138:0];ov=1;
            end
            do @(posedge clk); while(!(terminal ? srg : org));
            @(negedge clk) begin ov=0;sv=0;end
        end
    endtask
    initial begin
        if($test$plusargs("FAIL_PROBE")) $fatal(1,"Deliberate runner fatal-exit probe");
        if(!$value$plusargs("RECORDS=%s",stim_path) || !$value$plusargs("CRC=%s",crc_path) ||
           !$value$plusargs("META=%s",meta_path) || !$value$plusargs("RESULT=%s",result_path)) $fatal(1,"Missing component fixture");
        sf=$fopen(stim_path,"r");ef=$fopen(stim_path,"r");cf=$fopen(crc_path,"r");mf=$fopen(meta_path,"r");
        if(!sf || !ef || !cf || !mf) $fatal(1,"Component fixture open failed");
        reset_domain();start_job();incoming=read_hex(sf,40);offer_record(incoming,0);
        repeat(8) @(posedge clk);
        if(!observer.busy) $fatal(1,"Reset busy test missed real record");
        reset_domain();
        if(lastvalid!==0 || led0!==0 || observer.busy!==0) $fatal(1,"Busy reset did not isolate old record");
        if($fseek(sf,0,0)!=0 || $fseek(ef,0,0)!=0 || $fseek(cf,0,0)!=0) $fatal(1,"Rewind failed");
        for(ci=0;ci<8;ci=ci+1) begin
            rc=$fscanf(mf,"%s %d %h %d %d %d\n",cid,n,sequence_value,drain,expected_good,reset_before);
            if(rc!=6) $fatal(1,"Missing typed scenario metadata");
            if(reset_before) reset_domain();
            // 批准的计数边界初始化；不改真实done/status/state。
            if(sequence_value==32'hfffffffe) begin @(negedge clk);supervisor.job_sequence=sequence_value;end
            start_job();
            if(jf!==sequence_value) $fatal(1,"Unexpected actual supervisor sequence");
            for(j=0;j<n;j=j+1) begin incoming=read_hex(sf,40);offer_record(incoming,0);end
            if(drain) begin @(negedge clk) source_last=1;@(negedge clk) source_last=0;end
            incoming=read_hex(sf,40);offer_record(incoming,1);
            wait(done);#2;
            if(lastgood!==expected_good || tgood!==expected_good || led0!==expected_good ||
               laststatus!==incoming[2:0] || lin!==incoming[23:3] || lout!==incoming[44:24] ||
               le!==incoming[76:45] || lf!==incoming[108:77] || lc!==incoming[140:109] || ldata!==n)
                $fatal(1,"Typed terminal/good/LED snapshot mismatch");
            repeat(2) @(negedge clk);
            if(!expected_good && (jvalid!==0 || supervisor.supervision_state!==4)) $fatal(1,"Invalid OK did not enter ERROR");
            if(sequence_value==32'hffffffff && (jvalid!==0 || supervisor.job_sequence!==32'hffffffff ||
               supervisor.supervision_state!==5)) $fatal(1,"EXHAUSTED wrapped/restarted");
            cases=cases+1;
        end
        require_eof(sf);require_eof(ef);require_eof(cf);require_eof(mf);
        if(records!=47 || crc_checks!=46 || fo_stalls==0 || fs_stalls==0) $fatal(1,"Component coverage/count incomplete");
        rf=$fopen(result_path,"w");if(!rf) $fatal(1,"Result create failed");
        $fdisplay(rf,"{\"finished\":true,\"cases_completed\":%0d,\"records_compared\":%0d,\"record_crc_checks\":%0d,\"fo_stall_cycles\":%0d,\"fs_stall_cycles\":%0d,\"busy_reset_checks\":1,\"exhausted_jobs\":2,\"numeric_errors\":0,\"protocol_errors\":0,\"cycles\":%0d}",cases,records,crc_checks,fo_stalls,fs_stalls,cycles);
        $fclose(rf);finished=1;$finish;
    end
    always @(posedge clk) begin
        cycles=cycles+1;if(cycles>50000) $fatal(1,"Typed component timeout");
        old_busy=observer.busy;
        if(rst) begin pending=0;shift_count=0;end
        else begin
            if(ov && !org) fo_stalls=fo_stalls+1;
            if(sv && !srg) fs_stalls=fs_stalls+1;
            if((ov && org) || (sv && srg)) begin
                if(pending) $fatal(1,"Component record overwritten");
                held_terminal=sv;
                golden=read_hex(ef,40);expected_crc=read_hex(cf,8);
                held_record=sv ? {19'b0,sc,sfr,se,sout,sin,code} : {21'b0,eof,eol,sof,oc,ofr,oe,y,x,edge_bits,m};
                if(held_record!==golden) $fatal(1,"Typed record packing mismatch");
                if(sv && good!==expected_good) $fatal(1,"Supervisor original status qualification mismatch");
                pending=1;shift_count=0;records=records+1;capture_crc=observer.crc_state;
                #1;if(observer.record_hold!==golden || observer.crc_state!==capture_crc || observer.record_bit_index!==159)
                    $fatal(1,"Component first bit/capture boundary wrong");
            end else if(old_busy) begin
                if(!pending || observer.record_hold!==held_record) $fatal(1,"Held component identity changed");
                shift_count=shift_count+1;
                if(observer.record_bit_index==0) begin
                    #1;if(shift_count!=160 || observer.crc_state!==expected_crc) $fatal(1,"Component independent CRC mismatch");
                    if(held_terminal && lastcrc!==(expected_crc^32'hffffffff)) $fatal(1,"Last-bit CRC snapshot mismatch");
                    pending=0;crc_checks=crc_checks+1;
                end
            end
        end
    end
endmodule
