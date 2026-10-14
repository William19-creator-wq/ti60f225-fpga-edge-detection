`timescale 1ns/1ps
// RPT1..7：实际三叶；正沿前全端口账、负沿驱动；slave只依物理AR建立身份。
module tb_axi_read_pair_service;
    logic clk=0,rst=1,arbiter_enable=1,algorithm_enable=1,display_enable=1,display_cancel=0;
    always #5 clk=~clk;
    logic line_req_valid=0,line_rsp_ready=0,span_req_valid=0,display_data_ready=1,display_done_ready=0;
    logic [31:0] line_addr=0,span_addr=0;
    logic [13:0] span_bytes=16;
    wire line_req_ready,line_rsp_valid,line_error,line_drained,span_req_ready,display_data_valid,display_done_valid,display_drained;
    wire [511:0] line_rdata;
    wire [127:0] display_data;
    wire [1:0] display_outcome;
    wire [7:0] display_reason;
    wire m_axi_arvalid,m_axi_rready;
    logic m_axi_arready=0,m_axi_rvalid=0,m_axi_rlast=0;
    wire [31:0] m_axi_araddr;
    wire [3:0] m_axi_arid;
    wire [7:0] m_axi_arlen;
    wire [2:0] m_axi_arsize;
    wire [1:0] m_axi_arburst;
    logic [127:0] m_axi_rdata=0;
    logic [3:0] m_axi_rid=0;
    logic [1:0] m_axi_rresp=0;
    wire line_quarantined,span_quarantined,bus_quarantined,quarantined,physical_idle,physical_occupied;
    wire [2:0] bus_fault_reason;
    axi_read_pair_service dut(.*);
    bit finished=0,af,rf,lf,sf,lr,dd,done;
    logic [48:0] fired_ar;
    integer case_id=0,cycle=0,fd=0,exposure_fd=0,result_fd,completed_cases=0,ars=0,rs=0,line_requests=0,span_requests=0,line_replies=0,span_dones=0;
    string run_dir;
    function automatic logic [127:0] word_at(input logic [31:0] address);
        for(integer i=0;i<16;i++)word_at[i*8+:8]=8'((address+32'(i))*32'd37+32'd11);
    endfunction
    always @(posedge clk)if(fd!=0)begin
        $fwrite(fd,"%0d\t%0d\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%032b\t%b\t%b\t%0514b\t%b\t%b\t%032b\t%0d\t%b\t%b\t%0128b\t%b\t%b\t%011b\t%b\t%b\t%049b\t%b\t%b\t%0135b\t%b\t%b\t%b\t%b\t%0d\t%b\t%b\n",
            case_id,cycle,rst,arbiter_enable,algorithm_enable,display_enable,display_cancel,
            line_req_valid,line_req_ready,line_addr,line_rsp_valid,line_rsp_ready,{line_rdata,line_error,line_drained},
            span_req_valid,span_req_ready,span_addr,span_bytes,display_data_valid,display_data_ready,display_data,
            display_done_valid,display_done_ready,{display_outcome,display_reason,display_drained},
            m_axi_arvalid,m_axi_arready,{m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst},
            m_axi_rvalid,m_axi_rready,{m_axi_rdata,m_axi_rid,m_axi_rresp,m_axi_rlast},
            line_quarantined,span_quarantined,bus_quarantined,quarantined,bus_fault_reason,physical_idle,physical_occupied);
        cycle++;
        // J2：记录公开AR沿后曝光；取消在下一个负沿才改变。
        #1;$fwrite(exposure_fd,"%0d\t%b\t%b\t%049b\n",cycle-1,rst,m_axi_arvalid,
                  {m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst});
    end
    task automatic step;
        @(posedge clk);
        af=m_axi_arvalid&&m_axi_arready;rf=m_axi_rvalid&&m_axi_rready;
        lf=line_req_valid&&line_req_ready;sf=span_req_valid&&span_req_ready;
        lr=line_rsp_valid&&line_rsp_ready;dd=display_data_valid&&display_data_ready;done=display_done_valid&&display_done_ready;
        fired_ar={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst};
        if(af)ars++;if(rf)rs++;if(lf)line_requests++;if(sf)span_requests++;if(lr)line_replies++;if(done)span_dones++;
        #1;@(negedge clk);
    endtask
    task automatic cold(input integer id);
        case_id=id;rst=1;arbiter_enable=1;algorithm_enable=1;display_enable=1;display_cancel=0;
        line_req_valid=0;span_req_valid=0;line_rsp_ready=0;display_done_ready=0;display_data_ready=1;
        m_axi_arready=0;m_axi_rvalid=0;m_axi_rdata=0;m_axi_rid=0;m_axi_rresp=0;m_axi_rlast=0;
        repeat(3)step();rst=0;step();
        if(quarantined||!physical_idle||physical_occupied)$fatal(1,"Cold state not empty");
    endtask
    task automatic issue(input bit want_l,want_s,input logic [31:0] la,sa,input integer bytes);
        integer ticks;bit al,as;
        line_addr=la;span_addr=sa;span_bytes=14'(bytes);line_req_valid=want_l;span_req_valid=want_s;
        al=!want_l;as=!want_s;ticks=0;
        while(!al||!as)begin
            step();if(lf)begin al=1;line_req_valid=0;end if(sf)begin as=1;span_req_valid=0;end
            if(ticks++>200)$fatal(1,"Application issue timeout");
        end
    endtask
    task automatic wait_ar;
        integer ticks;ticks=0;m_axi_arready=0;
        while(!m_axi_arvalid)begin step();if(ticks++>200)$fatal(1,"No physical AR");end
    endtask
    logic [31:0] server_addr;
    logic [3:0] server_id;
    integer server_beats;
    task automatic accept_ar;
        m_axi_arready=1;step();if(!af)$fatal(1,"AR not accepted");
        server_addr=fired_ar[48:17];server_id=fired_ar[16:13];server_beats=int'(fired_ar[12:5])+1;m_axi_arready=0;
    endtask
    task automatic beat(input integer index,input logic [3:0] rid,input bit last,input logic [1:0] resp=0);
        integer ticks;ticks=0;m_axi_rvalid=1;m_axi_rdata=word_at(server_addr+32'(16*index));
        m_axi_rid=rid;m_axi_rlast=last;m_axi_rresp=resp;
        do begin step();if(ticks++>500)$fatal(1,"Unexpected R blocking");end while(!rf);
        m_axi_rvalid=0;
    endtask
    task automatic finish_outputs(input bit want_l,want_s);
        integer ticks;bit got_l,got_s;got_l=!want_l;got_s=!want_s;ticks=0;
        line_rsp_ready=1;display_done_ready=1;display_data_ready=1;
        while(!got_l||!got_s)begin
            step();if(lr)got_l=1;if(done)got_s=1;
            if(ticks++>500)$fatal(1,"Missing terminal notification");
        end
        line_rsp_ready=0;display_done_ready=0;repeat(4)step();
    endtask
    task automatic gate_check;
        line_req_valid=1;span_req_valid=1;line_addr=32'h05000000;span_addr=32'h06000000;span_bytes=16;
        repeat(12)begin
            step();if(!quarantined||line_req_ready||span_req_ready||af)$fatal(1,"Global Q allowed new work");
        end
        line_req_valid=0;span_req_valid=0;
    endtask
    // 连续实际应用与地址slave；压力并非模拟DDR带宽/最坏服务期限。
    task automatic normal(input integer id,lc,sc,input logic [31:0] la,sa,input integer bytes,input bit stalls,
                          input integer error_id=-1,error_index=-1,input integer initial_stop=0,input bit zero_delay=0);
        integer li,si,lo,so,ticks,index,total;bit live;logic [31:0] addr;logic [3:0] rid;
        cold(id);li=0;si=0;lo=0;so=0;ticks=0;index=0;total=0;live=0;
        while(lo<lc||so<sc||live||!physical_idle)begin
            if(ticks>100000)$fatal(1,"Normal case timeout id=%0d",id);
            arbiter_enable=ticks>=initial_stop;
            line_req_valid=li<lc;line_addr=la+32'(li*8192);
            span_req_valid=si<sc;span_addr=sa+32'(si*16384);span_bytes=14'(bytes);
            line_rsp_ready=!stalls||ticks%29>=9;display_done_ready=!stalls||ticks%31>=11;
            display_data_ready=!stalls||ticks%47>=19;m_axi_arready=!stalls||ticks%37>=13;
            if(!m_axi_rvalid && live && (!stalls||ticks%7!=0))begin
                m_axi_rvalid=1;m_axi_rdata=word_at(addr+32'(index*16));m_axi_rid=rid;
                m_axi_rresp=(int'(rid)==error_id&&index==error_index)?2:0;m_axi_rlast=index==total-1;
            end else if(!m_axi_rvalid&&!live&&zero_delay&&m_axi_arvalid&&m_axi_arready)begin
                m_axi_rvalid=1;m_axi_rdata=word_at(m_axi_araddr);m_axi_rid=m_axi_arid;m_axi_rresp=0;m_axi_rlast=m_axi_arlen==0;
            end
            step();ticks++;
            if(lf)li++;if(sf)si++;if(lr)lo++;if(done)so++;
            if(af)begin
                if(live)$fatal(1,"Two physical owners");live=1;addr=fired_ar[48:17];rid=fired_ar[16:13];total=int'(fired_ar[12:5])+1;index=0;
            end
            if(rf)begin index++;m_axi_rvalid=0;if(index==total)live=0;end
            if(quarantined)$fatal(1,"Unexpected normal Q case=%0d",id);
        end
        line_req_valid=0;span_req_valid=0;line_rsp_ready=0;display_done_ready=0;repeat(3)step();completed_cases++;
    endtask
    task automatic cancel_case(input integer id,phase);
        cold(id);issue(0,1,0,32'h01000000,(phase>=3)?16:8192);
        if(phase==0)begin display_cancel=1;repeat(4)step();end
        else begin
            wait_ar();
            if(phase==1)begin display_cancel=1;repeat(9)step();end
            accept_ar();
            if(phase==2)begin
                for(integer i=0;i<5;i++)beat(i,2,0);
                display_cancel=1;repeat(4)step();
                for(integer i=5;i<server_beats;i++)beat(i,2,i==server_beats-1);
            end else if(phase>=3)begin
                display_data_ready=phase==4;beat(0,2,1);
                repeat(5)step();display_cancel=1;repeat(9)step();display_data_ready=1;
            end else for(integer i=0;i<server_beats;i++)beat(i,2,i==server_beats-1);
        end
        finish_outputs(0,1);if(quarantined||!physical_idle)$fatal(1,"Cancel falsely Q");completed_cases++;
    endtask
    task automatic disable_case(input integer id,phase);
        cold(id);issue(phase==0,phase!=0,32'h02000000,32'h01000000,1024);
        if(phase==1)begin display_enable=0;repeat(6)step();end
        else begin
            wait_ar();
            if(phase==0)algorithm_enable=0;
            if(phase==2)display_enable=0;
            repeat(8)step();accept_ar();
            for(integer i=0;i<server_beats;i++)begin
                if(phase==3&&i==3)display_enable=0;
                beat(i,server_id,i==server_beats-1);
            end
        end
        finish_outputs(phase==0,phase!=0);
        if(!quarantined||bus_quarantined||!physical_idle)$fatal(1,"Leaf unknown was confused with physical occupied");
        gate_check();completed_cases++;
    endtask
    task automatic fault_case(input integer id,input bit span_fault,input integer kind);
        integer count;
        cold(id);
        // 先留下一个完整算法reply；显示Q出现后它仍须能消费。
        if(span_fault)begin
            issue(1,0,32'h02000000,0,16);wait_ar();accept_ar();
            for(integer i=0;i<4;i++)beat(i,0,i==3);repeat(3)step();
        end
        issue(!span_fault,span_fault,32'h02004000,32'h01000000,64);wait_ar();accept_ar();count=server_beats;
        if(kind==0)begin
            beat(0,7,0);finish_outputs(1,span_fault);
            for(integer i=1;i<count;i++)beat(i,server_id,i==count-1);
        end else if(kind==1)begin
            beat(0,server_id,1);
            m_axi_rvalid=1;m_axi_rdata=word_at(server_addr+16);m_axi_rid=server_id;m_axi_rlast=0;m_axi_rresp=0;
            repeat(8)begin step();if(rf)$fatal(1,"Early correct LAST leaf should retain unknown tail");end
        end else begin
            for(integer i=0;i<count;i++)beat(i,server_id,0);
            finish_outputs(1,span_fault);
            beat(count,server_id,1);
        end
        if(!bus_quarantined||!quarantined||!physical_occupied||physical_idle)$fatal(1,"Fault released physical owner");
        if(kind==1)finish_outputs(1,span_fault);
        gate_check();completed_cases++;
    endtask
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir))$fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected PAIR fatal probe");
        fd=$fopen({run_dir,"/pair-events.tsv"},"w");if(fd==0)$fatal(1,"Trace not writable");
        exposure_fd=$fopen({run_dir,"/pair-ar-exposure.tsv"},"w");if(exposure_fd==0)$fatal(1,"Exposure trace not writable");
        $fwrite(exposure_fd,"cycle\trst\tmav\tma\n");
        $fwrite(fd,"case\tcycle\trst\tben\taen\tden\tcancel\tlqv\tlqr\tladdr\tlrv\tlrr\tlbody\tsqv\tsqr\tsaddr\tsbytes\tdv\tdr\tddata\tnev\tner\tnbody\tmav\tmar\tma\tmrv\tmrr\tmr\tlq\tsq\tbq\tq\tfault\tidle\toccupied\n");
        normal(1,16,4,32'h04000000,32'h01000ff0,8192,0);
        normal(2,8,3,32'h04000000,32'h01000ff0,8192,1);
        normal(3,0,1,0,32'h01000000,16,0);normal(4,0,1,0,32'h01000000,1024,0);
        normal(5,0,1,0,32'h01000ff0,8192,1);
        normal(6,1,0,32'h0fffffc0,0,16,0);normal(7,0,1,0,32'h0ffffc00,1024,0);
        normal(8,1,0,32'h02000011,0,16,0);normal(9,1,0,32'h10000000,0,16,0);
        normal(10,0,1,0,32'h01000001,16,0);normal(11,0,1,0,32'h01000000,0,0);
        normal(12,0,1,0,32'h01000000,15,0);normal(13,0,1,0,32'h01000000,17,0);
        normal(14,0,1,0,32'h01000000,8193,0);normal(15,0,1,0,32'h0ffffff0,32,0);
        normal(16,1,0,32'h02000000,0,16,1,0,1);normal(17,0,1,0,32'h01000000,8192,1,2,2);
        for(integer i=0;i<5;i++)cancel_case(18+i,i);
        for(integer i=0;i<4;i++)disable_case(23+i,i);
        for(integer i=0;i<3;i++)fault_case(27+i,0,i);
        for(integer i=0;i<3;i++)fault_case(30+i,1,i);
        cold(33);issue(1,1,32'h02000000,32'h01000000,1024);wait_ar();repeat(8)step();
        normal(33,1,1,32'h02008000,32'h01008000,16,0);
        cold(34);issue(1,1,32'h02000000,32'h01000000,1024);wait_ar();accept_ar();display_data_ready=0;beat(0,server_id,0);repeat(8)step();
        normal(34,1,1,32'h02008000,32'h01008000,16,0);
        cold(35);issue(1,0,32'h02000000,0,16);wait_ar();accept_ar();for(integer i=0;i<4;i++)beat(i,0,i==3);
        issue(0,1,0,32'h01000000,16);wait_ar();accept_ar();display_data_ready=0;beat(0,2,1);repeat(8)step();
        normal(35,1,1,32'h02008000,32'h01008000,16,0);
        normal(36,3,2,32'h02000000,32'h01000000,1024,0,-1,-1,16);
        cold(37);issue(1,0,32'h02000000,0,16);wait_ar();arbiter_enable=0;repeat(11)step();accept_ar();
        for(integer i=0;i<4;i++)beat(i,0,i==3);finish_outputs(1,0);
        issue(1,0,32'h02004000,0,16);repeat(12)begin step();if(m_axi_arvalid)$fatal(1,"Disabled new arbiter selection");end
        arbiter_enable=1;wait_ar();accept_ar();for(integer i=0;i<4;i++)beat(i,0,i==3);finish_outputs(1,0);completed_cases++;
        normal(38,3,3,32'h02000000,32'h01000000,16,0,-1,-1,0,1);
        if(completed_cases!=38)$fatal(1,"Missing scenario");
        finished=1;$fclose(fd);$fclose(exposure_fd);fd=0;result_fd=$fopen({run_dir,"/pair-result.json"},"w");
        $fwrite(result_fd,"{\"finished\":true,\"cases\":%0d,\"cycles\":%0d,\"physical_ar\":%0d,\"physical_r\":%0d,\"line_requests\":%0d,\"span_requests\":%0d,\"line_replies\":%0d,\"span_dones\":%0d}\n",completed_cases,cycle,ars,rs,line_requests,span_requests,line_replies,span_dones);
        $fclose(result_fd);$finish;
    end
endmodule
