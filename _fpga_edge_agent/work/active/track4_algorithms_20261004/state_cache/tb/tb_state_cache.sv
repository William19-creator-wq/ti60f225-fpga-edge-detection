`timescale 1ns/1ps
module tb_state_cache #(parameter integer WIDTH=1920,HEIGHT=1080);
    localparam integer N=WIDTH*HEIGHT,LINES=(N+255)/256;
    localparam logic [31:0] LAST_LEGAL_BASE=32'h00000000-32'(LINES*64);
    logic clk=0,rst=1;
    always #5 clk=~clk;
    logic cv=0,crr=0,rv=0,rr=0,claim_ready=0,lready=0,lrv=0;
    logic [31:0] cbase=32'h00100000;
    logic [63:0] cid=64'h4310602500000001;
    logic abort_valid=0;
    logic [63:0] abort_id=0;
    logic [1:0] op=0;
    logic [20:0] ri=0;
    wire cready,crv,cre,ready,valid,rc,re,raborted,claim_valid,lv,lwrite,lrready,quarantine;
    wire [1:0] ro;
    wire [20:0] claim_index;
    wire [31:0] laddr;
    wire [511:0] lwdata;
    logic [511:0] lrdata;
    logic lerror,ldrained;
    wire [63:0] active_id;
    canny_state_cache #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) dut(.clk(clk),.rst(rst),
        .cfg_valid(cv),.cfg_ready(cready),.cfg_base(cbase),.cfg_job_id(cid),
        .cfg_rsp_valid(crv),.cfg_rsp_ready(crr),.cfg_rsp_error(cre),
        .abort_private_valid(abort_valid),.abort_job_id(abort_id),
        .req_valid(rv),.req_ready(ready),.req_op(op),.req_index(ri),
        .rsp_valid(valid),.rsp_ready(rr),.rsp_old(ro),.rsp_claimed(rc),.rsp_error(re),.rsp_aborted(raborted),
        .claim_valid(claim_valid),.claim_ready(claim_ready),.claim_index(claim_index),
        .line_req_valid(lv),.line_req_ready(lready),.line_write(lwrite),.line_addr(laddr),.line_wdata(lwdata),
        .line_rsp_valid(lrv),.line_rsp_ready(lrready),.line_rdata(lrdata),.line_error(lerror),.line_drained(ldrained),
        .quarantined(quarantine),.active_job_id(active_id));
    logic [511:0] dram[0:LINES-1];
    bit seen[0:N-1];
    logic [31:0] rng=32'h43106025;
    logic [31:0] backend_base;
    integer delay_count=-1,fault_mode=0,reads=0,writes=0,atomic_claims=0,cycles=0;
    integer claim_override=-1,line_override=-1,abort_case,claims_before_abort,abort_checks=0,abort_extra_claims=0;
    bit held_line=0,held_claim=0,held_reply=0,finished=0;
    logic [544:0] line_body;
    logic [20:0] claim_body;
    logic [4:0] reply_body;
    integer operations_file,results_file,fields,opcode,index_value,expected_old,expected_claim,expected_error,item,frame,fault_file;
    bit checked_bad_cfg=0,checked_address_end=0,checked_read_error=0,checked_write_error=0,checked_quarantine=0,checked_install_reset=0;
    always @(negedge clk)begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        lready=delay_count<0 && !lrv && rng[1:0]!=0;
        claim_ready=rng[3:2]!=0;
        if(claim_override>=0)claim_ready=1'(claim_override);
        if(line_override==0)lready=0;
    end
    always @(posedge clk)begin
        cycles++;
        if(rst)begin lrv<=0;delay_count=-1;held_line=0;held_claim=0;held_reply=0;end
        else begin
            if(held_line && (!lv || {lwrite,laddr,lwdata}!==line_body))$fatal(1,"line RPC changed under stall");
            if(held_claim && (!claim_valid || claim_index!==claim_body))$fatal(1,"claim changed under stall");
            if(held_reply && (!valid || {ro,rc,re,raborted}!==reply_body))$fatal(1,"reply changed under stall");
            held_line=lv && !lready;line_body={lwrite,laddr,lwdata};
            held_claim=claim_valid && !claim_ready;claim_body=claim_index;
            if(abort_valid && abort_id==active_id && claim_valid && !claim_ready)held_claim=0;
            held_reply=valid && !rr;reply_body={ro,rc,re,raborted};
            if(lrv && lrready)lrv<=0;
            if(delay_count>0)delay_count--;
            else if(delay_count==0)begin lrv<=1;delay_count=-1;end
            if(lv && lready)begin
                if(delay_count>=0 || lrv || laddr[5:0]!=0 || laddr<backend_base ||
                    (laddr-backend_base)/64>=LINES)$fatal(1,"line ownership/alignment/range");
                lrdata<=dram[(laddr-backend_base)/64];lerror<=fault_mode!=0;ldrained<=fault_mode!=3;
                if(lwrite)begin
                    writes++;
                    if(fault_mode==0)dram[(laddr-backend_base)/64]=lwdata;
                end else reads++;
                fault_mode=0;delay_count=1+integer'(rng[8:5]);
            end
            if(claim_valid && claim_ready)begin
                if(claim_index>=N || seen[claim_index])$fatal(1,"duplicate/out of range atomic claim");
                if(!dut.ram_we[dut.selected_way][dut.selected_set[4]] || dut.ram_re[dut.selected_way][dut.selected_set[4]])
                    $fatal(1,"queue/cache commit not same edge");
                seen[claim_index]=1;atomic_claims++;
            end
            if(cycles>10000000)$fatal(1,"global watchdog");
        end
    end
    task automatic reset_service;
        begin
            @(negedge clk);rst=1;cv=0;rv=0;rr=0;crr=0;abort_valid=0;claim_override=-1;line_override=-1;
            repeat(3)@(negedge clk);rst=0;
            for(integer i=0;i<N;i++)seen[i]=0;
        end
    endtask
    task automatic configure(input logic [31:0] new_base,input logic [63:0] new_id,input bit error_expected);
        begin
            @(negedge clk);cbase=new_base;cid=new_id;cv=1;
            do begin @(posedge clk);end while(!cready);
            @(negedge clk);cv=0;
            wait(crv);repeat(3)@(negedge clk);
            if(cre!=error_expected || active_id!=new_id)$fatal(1,"config reply");
            crr=1;@(negedge clk);crr=0;
        end
    endtask
    task automatic expect_reply(input integer old_value,claim_value,error_value,input bit aborted_expected,input bit log_result);
        begin
            wait(valid);repeat(1+integer'(rng[11:9]))@(negedge clk);
            if({ro,rc,re,raborted}!=={2'(old_value),1'(claim_value),1'(error_value),aborted_expected})
                $fatal(1,"cache reply differs frame%0d item%0d got%0d/%0d/%0d/%0d",frame,item,ro,rc,re,raborted);
            if(log_result)$fwrite(results_file,"%0d %0d %0d %0d %0d %0d %0d\n",frame,item,op,ri,ro,rc,re);
            rr=1;@(negedge clk);rr=0;
        end
    endtask
    task automatic operation(input integer operation_code,operation_index,old_value,claim_value,error_value,input bit log_result,input bit aborted_expected=0);
        begin
            @(negedge clk);op=2'(operation_code);ri=21'(operation_index);rv=1;
            do begin @(posedge clk);end while(!ready);
            @(negedge clk);rv=0;
            expect_reply(old_value,claim_value,error_value,aborted_expected,log_result);
        end
    endtask
    initial begin
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        results_file=$fopen("actual-results.txt","w");
        repeat(4)@(negedge clk);rst=0;
        configure(32'h00100001,64'd1,1);checked_bad_cfg=1;
        if(LINES>1)configure(32'hffffffc0,64'd2,1);
        for(frame=0;frame<2;frame++)begin
            $readmemh("initial-lines.mem",dram);
            for(integer i=0;i<N;i++)seen[i]=0;
            backend_base=32'h00100000+32'(frame)*32'h00100000;
            configure(backend_base,64'd100+64'(frame),0);
            operations_file=$fopen("operations.txt","r");item=0;
            while(!$feof(operations_file))begin
                fields=$fscanf(operations_file,"%d %d %d %d %d\n",opcode,index_value,expected_old,expected_claim,expected_error);
                if(fields!=5)$fatal(1,"metadata malformed");
                operation(opcode,index_value,expected_old,expected_claim,expected_error,1);item++;
            end
            $fclose(operations_file);
            if(frame==0)$writememh("actual-frame0.mem",dram);else $writememh("actual-frame1.mem",dram);
        end
        $readmemh("initial-lines.mem",dram);backend_base=LAST_LEGAL_BASE;
        configure(backend_base,64'd190,0);
        operation(0,N-1,integer'(dram[LINES-1][((N-1)%256)*2+:2]),0,0,0);
        operation(3,0,0,0,0,0);checked_address_end=1;
        // 已排空读错误：后续操作失败，关闭作废图后允许新的配置。
        $readmemh("initial-lines.mem",dram);backend_base=32'h00300000;
        configure(backend_base,64'd200,0);fault_mode=1;
        operation(0,0,0,0,1,0);operation(0,1,0,0,1,0);operation(3,0,0,0,1,0);checked_read_error=1;
        // 合法claim先提交；flush的B等价安全错误不得报成功。
        $readmemh("initial-lines.mem",dram);for(integer i=0;i<N;i++)seen[i]=0;
        configure(backend_base,64'd201,0);operation(2,1,1,1,0,0);fault_mode=2;
        operation(3,0,0,0,1,0);operation(3,0,0,0,1,0);checked_write_error=1;
        // 后端报告未知排空，旧配置不能被下一job覆盖。
        configure(backend_base,64'd202,0);fault_mode=3;
        @(negedge clk);op=0;ri=0;rv=1;do begin @(posedge clk);end while(!ready);
        @(negedge clk);rv=0;wait(quarantine);repeat(20)@(negedge clk);
        if(valid || ready || cready || lv || claim_valid)$fatal(1,"quarantine released old ownership");checked_quarantine=1;
        reset_service(); // 行为后端共同reset；不代表真实DDR可自动暖复位。
        $readmemh("initial-lines.mem",dram);configure(backend_base,64'd203,0);
        @(negedge clk);op=0;ri=1;rv=1;do begin @(posedge clk);end while(!ready);
        @(negedge clk);rv=0;wait(dut.state==dut.FILL_INSTALL);repeat(3)@(negedge clk);
        reset_service();configure(backend_base,64'd204,0);operation(0,1,1,0,0,0);operation(3,0,0,0,0,0);checked_install_reset=1;
        claims_before_abort=atomic_claims;
        for(abort_case=0;abort_case<10;abort_case++)begin
            $readmemh("initial-lines.mem",dram);for(integer i=0;i<N;i++)seen[i]=0;
            configure(backend_base,64'd300+64'(abort_case),0);
            claim_override=-1;line_override=-1;
            if(abort_case<=2)claim_override=0;
            if(abort_case==3)line_override=0;
            if(abort_case==7)fault_mode=1;
            if(abort_case==9)operation(2,1,1,1,0,0);
            @(negedge clk);op=abort_case<=2 ? 2'd2 : (abort_case==9 ? 2'd3 : 2'd0);ri=abort_case==9 ? 21'd0 : 21'd1;rv=1;
            do begin @(posedge clk);end while(!ready);
            @(negedge clk);rv=0;
            case(abort_case)
                0,1,2:wait(claim_valid);
                3:wait(lv);
                4,7:wait(dut.state==dut.MEM_WAIT);
                5:begin wait(dut.state==dut.FILL_INSTALL);repeat(3)@(negedge clk);end
                6:wait(valid);
                8:wait(dut.state==dut.WORD_CAPTURE);
                9:wait(dut.state==dut.WB_CAPTURE);
            endcase
            @(negedge clk);#1;abort_id=abort_case==0 ? cid+64'd1 : cid;abort_valid=1;
            if(abort_case==2)begin claim_override=1;claim_ready=1;end
            @(negedge clk);#1;abort_valid=0;
            if(abort_case==0)begin claim_override=1;claim_ready=1;end
            if(abort_case==3)begin
                repeat(3)@(negedge clk);
                if(!lv)$fatal(1,"abort withdrew exposed line request");line_override=-1;
            end
            if(abort_case==0 || abort_case==2)expect_reply(1,1,0,0,0);
            else if(abort_case==6)expect_reply(1,0,0,0,0);
            else if(abort_case==7)expect_reply(0,0,1,0,0);
            else expect_reply(0,0,1,1,0);
            claim_override=-1;line_override=-1;
            if(abort_case==0)operation(3,0,0,0,0,0);
            else operation(3,0,0,0,1,0,1);
            abort_checks++;
        end
        abort_extra_claims=atomic_claims-claims_before_abort;
        if(abort_extra_claims!=3)$fatal(1,"abort/old claim fire accounting differs");
        fault_file=$fopen("fault-result.json","w");
        $fwrite(fault_file,"{\"bad_config\":%0d,\"address_end\":%0d,\"read_error\":%0d,\"write_error\":%0d,\"quarantine\":%0d,\"install_reset\":%0d,\"abort_checks\":%0d,\"abort_extra_claims\":%0d,\"atomic_claims\":%0d,\"line_reads\":%0d,\"line_writes\":%0d}\n",checked_bad_cfg,checked_address_end,checked_read_error,checked_write_error,checked_quarantine,checked_install_reset,abort_checks,abort_extra_claims,atomic_claims,reads,writes);
        $fclose(fault_file);$fclose(results_file);
        finished=1;#1;$display("SC complete claims=%0d reads=%0d writes=%0d",atomic_claims,reads,writes);$finish;
    end
endmodule
