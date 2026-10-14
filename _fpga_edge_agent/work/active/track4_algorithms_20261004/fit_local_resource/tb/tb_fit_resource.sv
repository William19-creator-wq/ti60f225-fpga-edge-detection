`timescale 1ns/1ps
// FT-T01…09：独立文件期望；真实fire账；非法/取消/reset与普通数值分账。
module tb_fit_resource;
    import fit_protocol_pkg::*;
    logic clk=0,rst=1;
    always #20 clk=~clk;
    logic req_valid=0,req_ready,rsp_valid,rsp_ready=0,cancel_valid=0,quiet;
    logic [621:0] req_body=0;
    logic [584:0] rsp_body;
    logic [175:0] cancel_id=0;
    bit finished=0;
    string run_dir;
    integer vector_fd,observed_fd,private_fd,event_fd,result_fd;
    integer cycle=0,numeric_count=0,accepted=0,consumed=0,reset_aborted=0;
    integer child_calls=0,protocol_checks=0,cancel_checks=0,reset_checks=0;
    integer cache_checks=0;
    integer local_equivalence_checks=0;
    logic live=0;
    logic [175:0] live_id;
    logic [10:0] parent_states=0;
    logic [5:0] bridge_states=0;
    logic [18:0] child_states=0;
    logic [621:0] last_child_offer;
    logic last_child_stall=0;
    logic [584:0] last_response;
    logic last_response_stall=0;
    logic [63:0] protocol_sequence=64'd1000000;
    fit_core dut(.*);

    // RT02：旧参考只存在于TB，生产MAP仍只有一份私有scalar。
    wire old_req_ready,old_rsp_valid,old_quiet;
    wire [584:0] old_rsp_body;
    integer equivalent_cycles=0,equivalent_local_writes=0,helper_checks=0;
    fit_core_original original(.clk,.rst,.req_valid,.req_ready(old_req_ready),.req_body,
        .rsp_valid(old_rsp_valid),.rsp_ready,.rsp_body(old_rsp_body),.cancel_valid,.cancel_id,.quiet(old_quiet));
    always @(posedge clk)if(!rst)begin
        equivalent_cycles++;
        if({req_ready,rsp_valid,quiet}!=={old_req_ready,old_rsp_valid,old_quiet})$fatal(1,"FIT public timing changed");
        if(rsp_valid && rsp_body!==old_rsp_body)$fatal(1,"FIT full585 changed");
        if({dut.child_req_valid,dut.child_req_ready,dut.child_rsp_valid,dut.child_rsp_ready,dut.result_fire}!==
           {original.child_req_valid,original.child_req_ready,original.child_rsp_valid,original.child_rsp_ready,original.result_fire})$fatal(1,"FIT child timing changed");
        if(dut.child_req_valid && dut.child_req_body!==original.child_req_body)$fatal(1,"FIT child full622 changed");
        if(dut.child_rsp_valid && dut.child_rsp_body!==original.child_rsp_body)$fatal(1,"FIT child full585 changed");
        if(dut.result_fire && dut.bridge_result!==original.bridge_result)$fatal(1,"FIT bridge full403 changed");
        if(dut.state==dut.LOCAL_COMMIT && !dut.matching_cancel && dut.plan_class==1)begin
            if(dut.plan_local!==original.plan_local || dut.plan_destination!==original.plan_destination ||
               dut.plan_width!==original.plan_width || dut.plan_signed!==original.plan_signed)$fatal(1,"FIT local full192 changed");
            equivalent_local_writes++;
        end
    end
    initial begin : directed_full_width_helpers
        logic [191:0] value,raw;
        logic [31:0] rng;
        integer n;
        if(!$test$plusargs("FATAL_PROBE"))begin
            #1;rng=32'h43106025;
            for(integer slot=0;slot<16;slot++)if(slot==0 || slot==1 || slot==2 || slot==8 || slot==10 || slot==11)begin
                n=original.slot_maximum_bits(4'(slot));
                for(integer bit_index=0;bit_index<=n;bit_index++)begin
                    raw=192'd1<<bit_index;
                    for(integer sign=0;sign<2;sign++)begin
                        value=original.canonical_slot(sign ? -raw : raw,4'(slot));
                        if(dut.local_negate(4'(slot),value)!==-value)$fatal(1,"Local negation corner slot=%0d bit=%0d",slot,bit_index);
                        helper_checks++;
                    end
                end
                for(integer sample=0;sample<256;sample++)begin
                    for(integer word=0;word<6;word++)begin
                        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};raw[word*32+:32]=rng;
                    end
                    value=original.canonical_slot(raw,4'(slot));
                    if(dut.local_negate(4'(slot),value)!==-value)$fatal(1,"Local negation random slot=%0d",slot);
                    helper_checks++;
                end
            end
            for(integer v=0;v<2048;v++)begin
                value={181'd0,11'(v)}-192'd1;
                if(dut.coordinate_last(11'(v))!==value)$fatal(1,"Coordinate last full192 mismatch");helper_checks++;
            end
        end
    end


    always @(posedge clk) begin : actual_event_monitor
        logic [191:0] original_local;
        bit check_local;
        cycle=cycle+1;
        if(rst) begin
            if(live) begin reset_aborted=reset_aborted+1; $fwrite(event_fd,"Z %0d %044h\n",cycle,live_id); end
            else $fwrite(event_fd,"J %0d 0\n",cycle);
            live=0; last_child_stall=0; last_response_stall=0;
        end else begin
            parent_states[dut.state]=1; bridge_states[dut.private_bridge.state]=1; child_states[dut.private_arithmetic.state]=1;
            if(req_valid && req_ready) begin
                if(live) $fatal(1,"two outer obligations");
                accepted=accepted+1; live=1; live_id=req_body[175:0];
                $fwrite(event_fd,"A %0d %0156h\n",cycle,req_body);
            end
            if(rsp_valid && rsp_ready) begin
                if(!live || live_id!==rsp_body[175:0]) $fatal(1,"outer identity");
                consumed=consumed+1; live=0; $fwrite(event_fd,"R %0d %0147h\n",cycle,rsp_body);
            end
            if(last_response_stall && (!rsp_valid || rsp_body!==last_response)) $fatal(1,"outer held body changed");
            last_response_stall=rsp_valid && !rsp_ready; last_response=rsp_body;
            if(last_child_stall && (!dut.child_req_valid || dut.child_req_body!==last_child_offer)) $fatal(1,"published child withdrew");
            last_child_stall=dut.child_req_valid && !dut.child_req_ready; last_child_offer=dut.child_req_body;
            if(dut.child_req_valid && dut.child_req_ready) begin
                child_calls=child_calls+1;
                $fwrite(private_fd,"Q %0d outer_fit %044h private_scalar %0156h\n",cycle,dut.held_request[175:0],dut.child_req_body);
            end
            if(dut.child_rsp_valid && dut.child_rsp_ready)
                $fwrite(private_fd,"R %0d outer_fit %044h private_scalar %0147h\n",cycle,dut.held_request[175:0],dut.child_rsp_body);
            if(dut.result_fire)
                $fwrite(private_fd,"B %0d %044h step%0d phase%0d %0101h\n",cycle,dut.held_request[175:0],dut.step,dut.subphase,dut.bridge_result);
            if(dut.state==dut.QUALIFY_RETURN && dut.result_fire && !dut.matching_cancel && dut.bridge_result[8+:2]==VALUE) begin
                if(dut.reserved_width>dut.slot_maximum_bits(dut.reserved_destination)) $fatal(1,"slot typed maximum excludes declared target");
                if(dut.canonical_slot(dut.bridge_result[18+:192],dut.reserved_destination)!==dut.bridge_result[18+:192]) $fatal(1,"slot canonical commit changes full192 value");
            end
            if((dut.state==2 || dut.state==7) &&
               (dut.slot_valid & dut.required_slots)!=dut.required_slots && dut.plan_class!=3) $fatal(1,"unguarded slot read");
            if(dut.state==7 && !dut.matching_cancel && dut.plan_class==1)
                $fwrite(private_fd,"L %0d %044h step%0d phase%0d slot%0d %048h\n",cycle,dut.held_request[175:0],dut.step,dut.subphase,dut.plan_destination,dut.plan_local);
            if(dut.state==dut.LOCAL_COMMIT && !dut.matching_cancel && dut.plan_class==1) begin
                if(dut.plan_width>dut.slot_maximum_bits(dut.plan_destination) ||
                   dut.canonical_slot(dut.plan_local,dut.plan_destination)!==dut.plan_local) $fatal(1,"local typed/canonical slot mismatch");
                // 用优化前的完整192位表达式核每次真实提交，进位仍必须可见。
                original_local=0; check_local=1;
                if(dut.kind==14) begin
                    case(dut.step)
                        15:original_local=dut.work_slot[3]==0?192'd0:(dut.work_slot[3]<<1)-192'd1;
                        18:begin
                            if(dut.subphase!=1) check_local=0;
                            original_local=dut.work_slot[3]-((dut.work_slot[15]==1 || (dut.work_slot[15]==0 && dut.work_slot[3][0]))?192'd1:192'd0);
                        end
                        19:original_local=(dut.work_slot[3]<<1)+192'd1;
                        23:original_local=dut.work_slot[3]+((dut.work_slot[15]==2 || (dut.work_slot[15]==0 && dut.work_slot[3][0]))?192'd1:192'd0);
                        default:check_local=0;
                    endcase
                end else if(dut.kind==15) begin
                    case(dut.step)
                        15:original_local=(dut.work_slot[11]<<1)+192'd1;
                        20,21:begin
                            if(dut.subphase!=0) check_local=0;
                            original_local=(dut.step==21 && dut.work_slot[12]==0)?192'd0:
                                (dut.work_slot[12]<<1)+(dut.step==20?192'd1:-192'd1);
                        end
                        default:check_local=0;
                    endcase
                end else check_local=0;
                if(check_local) begin
                    if(dut.plan_local!==original_local) $fatal(1,"local full192 equivalence kind=%0d step=%0d",dut.kind,dut.step);
                    local_equivalence_checks=local_equivalence_checks+1;
                end
            end
            if(quiet && (dut.cmd_pending || dut.command_published || !dut.bridge_quiet)) $fatal(1,"false quiet");
        end
    end

    task automatic accept_request(input logic [621:0] request,output integer start_cycle,output integer initial_calls);
        begin
            @(negedge clk); req_body=request; req_valid=1;
            do @(posedge clk); while(!req_ready);
            start_cycle=cycle; initial_calls=child_calls;
            @(negedge clk); req_valid=0;
        end
    endtask
    task automatic collect(input logic [584:0] expected,input integer start_cycle,input integer hold,
                           output integer forming);
        logic [584:0] held;
        begin
            while(!rsp_valid) begin
                @(negedge clk); if(cycle-start_cycle>16384) $fatal(1,"formation exceeded16384 state=%0d kind=%0d step=%0d phase=%0d",dut.state,dut.kind,dut.step,dut.subphase);
            end
            forming=cycle-start_cycle; held=rsp_body;
            if(held!==expected) $fatal(1,"response mismatch request=%h expected=%h observed=%h step=%0d",req_body,expected,held,dut.step);
            if(hold>=7) begin
                cancel_id=held[175:0]; cancel_valid=1;
                @(negedge clk); cancel_valid=0;
                if(!rsp_valid || rsp_body!==held) $fatal(1,"HELD cancel changed old body");
            end
            repeat(hold) begin @(negedge clk); if(!rsp_valid || rsp_body!==held) $fatal(1,"held response"); end
            rsp_ready=1; @(posedge clk); @(negedge clk); rsp_ready=0;
        end
    endtask
    function automatic [621:0] protocol_request(input logic bad_count);
        logic [399:0] p;
        logic [175:0] id;
        begin
            p=0; p[0+:21]=bad_count?1:2; p[87+:43]=18; p[130+:43]=50; p[173+:44]=30;
            id={8'd12,protocol_sequence,8'd0,32'd1,32'd0,32'd1};
            protocol_request={p,9'd0,2'd0,5'd12,8'd1,11'd1080,11'd1920,id};
        end
    endfunction
    task automatic wait_state(input integer domain,input integer wanted,input integer started);
        begin
            while((domain==0 && dut.state!=wanted) || (domain==1 && dut.private_bridge.state!=wanted) ||
                  (domain==2 && dut.private_arithmetic.state!=wanted)) begin
                @(negedge clk);
                if(cycle-started>16384) $fatal(1,"unreached state domain=%0d state=%0d",domain,wanted);
            end
        end
    endtask
    task automatic cancellation(input integer domain,input integer wanted);
        logic [621:0] request;
        logic [584:0] expected;
        integer started,calls,formed,cancelled;
        begin
            request=protocol_request(domain==0 && wanted==8); protocol_sequence=protocol_sequence+1;
            accept_request(request,started,calls); wait_state(domain,wanted,started);
            if(rsp_valid) expected=rsp_body;
            else expected=pack_response(request,CANCEL_DROP,NONE,0);
            cancelled=cycle; cancel_id=request[175:0]; cancel_valid=1;
            $fwrite(event_fd,"C %0d %044h %0d\n",cycle,request[175:0],!rsp_valid);
            @(negedge clk); cancel_valid=0;
            collect(expected,started,7,formed);
            if(expected[OUTCOME_LO+:2]==CANCEL_DROP && formed+started-cancelled>8) $fatal(1,"cancel close exceeded8");
            cancel_checks=cancel_checks+1;
        end
    endtask
    task automatic reset_at(input integer domain,input integer wanted);
        logic [621:0] request;
        integer started,calls;
        begin
            request=protocol_request(domain==0 && wanted==8); protocol_sequence=protocol_sequence+1;
            accept_request(request,started,calls); wait_state(domain,wanted,started);
            rst=1; repeat(2) @(negedge clk); rst=0; #1;
            if(rsp_valid || !quiet || dut.cache_valid!=0) $fatal(1,"joint reset did not abort/cache clear");
            reset_checks=reset_checks+1;
        end
    endtask

    initial begin : suite
        logic [621:0] request;
        logic [584:0] expected;
        integer read_count,started,calls,formed,hold,cache_fd,cancelled;
        if(!$value$plusargs("RUN_DIR=%s",run_dir)) $fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE")) $fatal(1,"expected FIT fatal probe");
        // 真实u21/u19最大值与额外进位；下边界零由调度负责，函数不借截断蒙混。
        if(dut.line_odd_boundary(21'h1fffff,1)!==192'd4194303 ||
           dut.line_odd_boundary(21'd1,0)!==192'd1 || dut.line_odd_boundary(21'd0,1)!==192'd1 ||
           dut.line_neighbor(21'h1fffff,1)!==192'd2097152 ||
           fits_slot(dut.line_neighbor(21'h1fffff,1),21,0) ||
           dut.line_neighbor(21'd1,0)!==192'd0 ||
           dut.finite_odd_boundary(19'h7ffff,1)!==192'd1048575 ||
           dut.finite_odd_boundary(19'd1,0)!==192'd1 || dut.finite_odd_boundary(19'd0,1)!==192'd1)
            $fatal(1,"local boundary width/carry");
        event_fd=$fopen({run_dir,"/outer-events.tsv"},"w"); private_fd=$fopen({run_dir,"/private-events.tsv"},"w");
        observed_fd=$fopen({run_dir,"/numeric-observed.tsv"},"w");
        vector_fd=$fopen({run_dir,"/vectors/numeric.tsv"},"r");
        if(!vector_fd || !event_fd || !private_fd || !observed_fd) $fatal(1,"file open");
        repeat(3) @(negedge clk); rst=0;
        if(!$test$plusargs("CACHE_ONLY")) begin
        read_count=$fscanf(vector_fd,"%h %h\n",request,expected);
        while(read_count==2) begin
            accept_request(request,started,calls);
            hold=(numeric_count%257==0)?257:(numeric_count%31==0)?31:(numeric_count%7==0)?7:1;
            collect(expected,started,hold,formed);
            $fwrite(observed_fd,"%0156h %0147h %0d %0d\n",request,expected,formed,child_calls-calls);
            numeric_count=numeric_count+1;
            read_count=$fscanf(vector_fd,"%h %h\n",request,expected);
        end
        if(read_count!=-1 && !$feof(vector_fd)) $fatal(1,"malformed vector file");
        // IDLE同接受取消；已经HELD的三类响应在数值suite后单独验证。
        request=protocol_request(0); protocol_sequence=protocol_sequence+1;
        @(negedge clk); cancel_valid=1; cancel_id=request[175:0];
        accept_request(request,started,calls); cancel_valid=0;
        $fwrite(event_fd,"C %0d %044h 1\n",cycle,request[175:0]);
        collect(pack_response(request,CANCEL_DROP,NONE,0),started,31,formed); cancel_checks=cancel_checks+1;
        for(integer wanted=1;wanted<11;wanted=wanted+1) cancellation(0,wanted);
        for(integer wanted=0;wanted<6;wanted=wanted+1) cancellation(1,wanted);
        for(integer wanted=0;wanted<19;wanted=wanted+1) cancellation(2,wanted);
        for(integer wanted=1;wanted<11;wanted=wanted+1) reset_at(0,wanted);
        for(integer wanted=0;wanted<6;wanted=wanted+1) reset_at(1,wanted);
        for(integer wanted=0;wanted<19;wanted=wanted+1) reset_at(2,wanted);
        // 复位后新事务，与错误身份cancel：这里只借旧同一统计的既有numeric期望。
        request=protocol_request(0); protocol_sequence=protocol_sequence+1;
        // 此正常rank-one TLS的输出由独立文件的同统计向量提供，因此下面只测不受错cancel影响。
        accept_request(request,started,calls); cancel_id=request[175:0]^176'b1; cancel_valid=1;
        repeat(7) @(negedge clk); cancel_valid=0;
        while(!rsp_valid) begin @(negedge clk); if(cycle-started>16384) $fatal(1,"wrong cancel lost transaction"); end
        if(rsp_body[OUTCOME_LO+:2]!=VALUE || rsp_body[175:0]!==request[175:0]) $fatal(1,"wrong cancel changed result");
        expected=rsp_body; collect(expected,started,257,formed); protocol_checks=protocol_checks+1;
        end
        // FT-T05/09：取消同安装、cold miss、跨job hit、TLS规范安装后hit。
        rst=1; repeat(2) @(negedge clk); rst=0; #1;
        if(dut.cache_valid!=0) $fatal(1,"quiet reset retained cache");
        cache_fd=$fopen({run_dir,"/vectors/cache-directed.tsv"},"r"); if(!cache_fd) $fatal(1,"cache vector file");
        for(integer index=0;index<5;index=index+1) begin
            if($fscanf(cache_fd,"%h %h\n",request,expected)!=2) $fatal(1,"cache vector count");
            accept_request(request,started,calls);
            if(index==0) begin
                while(!(dut.state==dut.QUALIFY_RETURN && dut.kind==14 && dut.step==4)) begin
                    @(negedge clk); if(cycle-started>16384) $fatal(1,"cache installation state not reached");
                end
                cancelled=cycle; cancel_id=request[175:0]; cancel_valid=1;
                $fwrite(event_fd,"C %0d %044h 1\n",cycle,request[175:0]);
                @(negedge clk); cancel_valid=0;
                collect(pack_response(request,CANCEL_DROP,NONE,0),started,7,formed);
                if(dut.cache_valid!=0 || formed+started-cancelled>8) $fatal(1,"cancel installed cache or did not close cache=%h close=%0d started=%0d forming=%0d cancelled=%0d",dut.cache_valid,formed+started-cancelled,started,formed,cancelled);
                cancel_checks=cancel_checks+1;
            end else begin
                collect(expected,started,31,formed);
                if(index==1 && child_calls-calls!=22) $fatal(1,"cold miss must22 calls");
                if((index==2 || index==4) && child_calls-calls!=18) $fatal(1,"cache hit must18 calls");
            end
            cache_checks=cache_checks+1;
        end
        $fclose(cache_fd);
        if(accepted!=consumed+reset_aborted || live) $fatal(1,"outer ledger not closed");
        if(!$test$plusargs("CACHE_ONLY") && (parent_states!==11'h7ff || bridge_states!==6'h3f || child_states!==19'h7ffff)) $fatal(1,"reachable state coverage incomplete");
        $fclose(vector_fd); $fclose(observed_fd); $fclose(event_fd); $fclose(private_fd);
        result_fd=$fopen({run_dir,"/core-result.json"},"w");
        $fwrite(result_fd,"{\"finished\":true,\"errors\":0,\"numeric\":%0d,\"accepted\":%0d,\"consumed\":%0d,\"reset_aborted\":%0d,\"cancel_checks\":%0d,\"reset_checks\":%0d,\"cache_checks\":%0d,\"parent_states\":%0d,\"bridge_states\":%0d,\"child_states\":%0d}\n",numeric_count,accepted,consumed,reset_aborted,cancel_checks,reset_checks,cache_checks,parent_states,bridge_states,child_states);
        $fclose(result_fd);
        if(helper_checks<4000 || equivalent_cycles==0 || equivalent_local_writes==0)$fatal(1,"Missing resource comparison coverage");
        result_fd=$fopen({run_dir,"/resource-compare.json"},"w");
        $fwrite(result_fd,"{\"finished\":true,\"cycles_equal\":%0d,\"local_writes_equal\":%0d,\"helper_checks\":%0d,\"full_values_and_timing_equal\":true,\"helper_seed\":\"43106025\"}\n",equivalent_cycles,equivalent_local_writes,helper_checks);
        $fclose(result_fd);finished=1;
        $display("PASS full192 local equivalence checks=%0d",local_equivalence_checks);
        $display("PASS FIT numeric=%0d accepted=%0d consumed=%0d reset_aborted=%0d cancel=%0d reset=%0d",numeric_count,accepted,consumed,reset_aborted,cancel_checks,reset_checks); $finish;
    end
endmodule
