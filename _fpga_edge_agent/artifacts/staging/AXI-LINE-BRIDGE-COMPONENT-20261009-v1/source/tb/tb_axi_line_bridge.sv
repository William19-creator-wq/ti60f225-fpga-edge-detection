`timescale 1ns/1ps
module tb_axi_line_bridge;
    localparam integer BYTES=16384;
    logic clk=0,rst=1,finished=0,enable=1;always #5 clk=~clk;
    logic line_req_valid=0,line_req_ready,line_write=0,line_rsp_valid,line_rsp_ready=0,line_error,line_drained,quarantined;
    logic [31:0] line_addr=0;logic [511:0] line_wdata=0,line_rdata;
    logic m_axi_awvalid,m_axi_awready,m_axi_wvalid,m_axi_wready,m_axi_wlast,m_axi_bvalid,m_axi_bready,m_axi_arvalid,m_axi_arready,m_axi_rvalid,m_axi_rready,m_axi_rlast;
    logic [31:0] m_axi_awaddr,m_axi_araddr;logic [3:0] m_axi_awid,m_axi_arid,m_axi_bid,m_axi_rid;
    logic [7:0] m_axi_awlen,m_axi_arlen;logic [2:0] m_axi_awsize,m_axi_arsize;
    logic [1:0] m_axi_awburst,m_axi_arburst,m_axi_bresp,m_axi_rresp;
    logic [127:0] m_axi_wdata,m_axi_rdata;logic [15:0] m_axi_wstrb;
    logic random_stalls=1,hold_aw=0,hold_w=0,hold_ar=0,hold_b=0,hold_r=0;integer fault_kind=0;
    axi_line_bridge #(.ADDRESS_BYTES(33'(BYTES))) dut(.*);
    axi128_byte_memory #(.BYTES(BYTES)) slave(.*);
    byte unsigned gold[0:BYTES-1];
    logic held_aw=0,held_ar=0,held_w=0,held_reply=0;
    logic [48:0] aw_body,ar_body;logic [144:0] w_body;logic [513:0] reply_body;
    integer cycles=0,cases=0,normal_writes=0,normal_reads=0,fault_cases=0,accepted=0,aw_count=0,ar_count=0,w_count=0,r_count=0,b_count=0;
    integer trace_file;
    function automatic [511:0] pattern(input integer ordinal);
        logic [511:0] value;value=0;
        for(integer b=0;b<64;b++)value[b*8+:8]=8'((ordinal*71+b*13)^(b>>1));
        if(ordinal%17==0)value=0;
        if(ordinal%17==1)value='1;
        if(ordinal%17==2)begin value=0;value[ordinal%512]=1;end
        return value;
    endfunction
    always @(posedge clk)begin
        cycles++;
        if(rst)begin held_aw=0;held_ar=0;held_w=0;held_reply=0;end
        else begin
            if(held_aw && (!m_axi_awvalid || aw_body!=={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst}))$fatal(1,"AXI AW held changed");
            if(held_ar && (!m_axi_arvalid || ar_body!=={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst}))$fatal(1,"AXI AR held changed");
            if(held_w && (!m_axi_wvalid || w_body!=={m_axi_wdata,m_axi_wstrb,m_axi_wlast}))$fatal(1,"AXI W held changed");
            if(held_reply && (!line_rsp_valid || reply_body!=={line_rdata,line_error,line_drained}))$fatal(1,"AXI reply held changed");
            held_aw=m_axi_awvalid && !m_axi_awready;aw_body={m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst};
            held_ar=m_axi_arvalid && !m_axi_arready;ar_body={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst};
            held_w=m_axi_wvalid && !m_axi_wready;w_body={m_axi_wdata,m_axi_wstrb,m_axi_wlast};
            held_reply=line_rsp_valid && !line_rsp_ready;reply_body={line_rdata,line_error,line_drained};
            if(line_req_valid && line_req_ready)begin
                accepted++;
                if(line_write && line_addr[5:0]==0 && {1'b0,line_addr}+33'd64<=BYTES)begin
                    for(integer b=0;b<64;b++)gold[line_addr+b]=line_wdata[b*8+:8];
                    $fwrite(trace_file,"W %0d %0128h\n",line_addr,line_wdata);
                end
            end
            if(m_axi_awvalid && m_axi_awready)aw_count++;
            if(m_axi_arvalid && m_axi_arready)ar_count++;
            if(m_axi_wvalid && m_axi_wready)w_count++;
            if(m_axi_rvalid && m_axi_rready)r_count++;
            if(m_axi_bvalid && m_axi_bready)b_count++;
        end
        if(cycles>300000)$fatal(1,"AXI unit watchdog cases=%0d state=%0d",cases,dut.state);
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;enable=1;line_req_valid=0;line_rsp_ready=0;fault_kind=0;
        hold_aw=0;hold_ar=0;hold_w=0;hold_b=0;hold_r=0;random_stalls=1;
        for(integer b=0;b<BYTES;b++)gold[b]=8'((b*37)^(b>>3));
        $fwrite(trace_file,"X\n");repeat(3)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic transaction(input logic write_value,input logic [31:0] address_value,input logic [511:0] data_value,
        input logic expect_error=0,input logic expect_drained=1);
        logic [511:0] expected_data;
        integer aw_before,ar_before,w_before,b_before;
        expected_data=0;aw_before=aw_count;ar_before=ar_count;w_before=w_count;b_before=b_count;
        if(!write_value && !expect_error)for(integer b=0;b<64;b++)expected_data[b*8+:8]=gold[address_value+b];
        @(negedge clk);line_req_valid=1;line_write=write_value;line_addr=address_value;line_wdata=data_value;
        do @(posedge clk);while(!line_req_ready);
        @(negedge clk);line_req_valid=0;line_addr=32'hffffffff;line_wdata=~data_value;line_write=!write_value;
        while(!line_rsp_valid)@(negedge clk);
        if(line_error!==expect_error || line_drained!==expect_drained || line_rdata!==expected_data)$fatal(1,"AXI reply math/status mismatch addr=%h write=%0d err=%0d drain=%0d expected=%0d/%0d",address_value,write_value,line_error,line_drained,expect_error,expect_drained);
        if(address_value[5:0]!=0 || {1'b0,address_value}+33'd64>BYTES)begin
            if(aw_count!=aw_before || ar_count!=ar_before || w_count!=w_before || b_count!=b_before)$fatal(1,"Rejected line touched AXI");
        end else if(write_value && b_count==b_before)$fatal(1,"AXI write replied before B");
        repeat(7)@(negedge clk);line_rsp_ready=1;@(posedge clk);@(negedge clk);line_rsp_ready=0;cases++;
        if(expect_drained)begin if(!line_req_ready)$fatal(1,"AXI safe line not released");end
        else begin
            repeat(15)@(negedge clk);
            if(!quarantined || line_req_ready || line_rsp_valid || m_axi_awvalid || m_axi_arvalid)$fatal(1,"AXI unknown line reused after notice");fault_cases++;
        end
    endtask
    initial begin
        integer file_output,metrics_file;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        trace_file=$fopen("transactions.txt","w");reset_joint();
        for(integer n=0;n<512;n++)begin
            transaction(1,32'((n%256)*64),pattern(n));normal_writes++;
            transaction(0,32'((n%256)*64),0);normal_reads++;
        end
        for(integer n=0;n<256;n++)begin transaction(0,32'(n*64),0);normal_reads++;end
        transaction(1,32'd1,pattern(5),1,1);transaction(0,32'(BYTES),0,1,1);
        // 公共AW/AR/W保持和末W后真实B延迟。
        hold_aw=1;
        fork transaction(1,32'hfc0,pattern(700));begin while(!m_axi_awvalid)@(negedge clk);repeat(20)@(negedge clk);hold_aw=0;end join
        hold_ar=1;
        fork transaction(0,32'hfc0,0);begin while(!m_axi_arvalid)@(negedge clk);repeat(20)@(negedge clk);hold_ar=0;end join
        hold_w=1;
        fork transaction(1,32'h1000,pattern(701));begin while(!m_axi_wvalid)@(negedge clk);repeat(20)@(negedge clk);hold_w=0;end join
        hold_b=1;
        fork transaction(1,32'hffc0 & 32'(BYTES-64),pattern(702));begin while(!slave.b_pending)@(negedge clk);repeat(20)@(negedge clk);if(line_rsp_valid)$fatal(1,"AXI last W falsely committed");hold_b=0;end join
        fault_kind=1;transaction(1,128,pattern(703),1,1);fault_kind=0;
        fault_kind=3;transaction(0,128,0,1,1);fault_kind=0;
        for(integer f=2;f<=7;f++)if(f!=3)begin
            reset_joint();fault_kind=f;transaction(f==2,128,pattern(704+f),1,0);
            if(slave.reading || slave.b_pending)$fatal(1,"AXI quarantine did not absorb real tail");
        end
        // enable低仍保持已经公开AW，恢复后仍不可把本请求改成安全success。
        reset_joint();hold_aw=1;
        fork
            transaction(1,128,pattern(800),1,0);
            begin while(!m_axi_awvalid)@(negedge clk);enable=0;repeat(20)@(negedge clk);if(!m_axi_awvalid)$fatal(1,"AXI enable loss withdrew AW");enable=1;hold_aw=0;end
        join
        reset_joint();hold_ar=1;
        fork
            transaction(0,128,0,1,0);
            begin while(!m_axi_arvalid)@(negedge clk);enable=0;repeat(20)@(negedge clk);if(!m_axi_arvalid)$fatal(1,"AXI enable loss withdrew AR");enable=1;hold_ar=0;end
        join
        reset_joint();transaction(1,32'(BYTES-64),pattern(900));transaction(0,32'(BYTES-64),0);
        file_output=$fopen("actual-memory.bin","wb");for(integer b=0;b<BYTES;b++)$fwrite(file_output,"%c",slave.memory_bytes[b]);$fclose(file_output);$fclose(trace_file);
        metrics_file=$fopen("protocol-metrics.json","w");
        $fwrite(metrics_file,"{\"finished\":true,\"cases\":%0d,\"normal_writes\":%0d,\"normal_reads\":%0d,\"unknown_fault_cases\":%0d,\"accepted\":%0d,\"aw\":%0d,\"ar\":%0d,\"w_beats\":%0d,\"r_beats\":%0d,\"b\":%0d,\"cycles\":%0d}\n",cases,normal_writes,normal_reads,fault_cases,accepted,aw_count,ar_count,w_count,r_count,b_count,cycles);
        $fclose(metrics_file);finished=1;$display("AXI line bridge PASS cases=%0d cycles=%0d",cases,cycles);$finish;
    end
endmodule
