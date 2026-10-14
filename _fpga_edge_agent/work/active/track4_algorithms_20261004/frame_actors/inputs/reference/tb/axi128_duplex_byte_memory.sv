`timescale 1ns/1ps
// DH-T01..4：一个读和一个写可以并行。返回数据只来自真实W写过的byte memory。
module axi128_duplex_byte_memory #(parameter integer BYTES=65536,CLASS_BASE=0,CLASS_BYTES=64)(
    input logic clk,rst,random_stalls,hold_aw,hold_w,hold_ar,hold_b,hold_r,input integer fault_kind,
    input logic m_axi_awvalid,output logic m_axi_awready,input logic [31:0] m_axi_awaddr,
    input logic [3:0] m_axi_awid,input logic [7:0] m_axi_awlen,input logic [2:0] m_axi_awsize,input logic [1:0] m_axi_awburst,
    input logic m_axi_wvalid,output logic m_axi_wready,input logic [127:0] m_axi_wdata,input logic [15:0] m_axi_wstrb,input logic m_axi_wlast,
    output logic m_axi_bvalid=0,input logic m_axi_bready,output logic [3:0] m_axi_bid=0,output logic [1:0] m_axi_bresp=0,
    input logic m_axi_arvalid,output logic m_axi_arready,input logic [31:0] m_axi_araddr,
    input logic [3:0] m_axi_arid,input logic [7:0] m_axi_arlen,input logic [2:0] m_axi_arsize,input logic [1:0] m_axi_arburst,
    output logic m_axi_rvalid=0,input logic m_axi_rready,output logic [127:0] m_axi_rdata=0,
    output logic [3:0] m_axi_rid=0,output logic [1:0] m_axi_rresp=0,output logic m_axi_rlast=0,
    output logic writing=0,b_pending=0,reading=0
);
    byte unsigned memory_bytes[0:BYTES-1],first_class_bytes[0:CLASS_BYTES-1];
    bit class_written[0:CLASS_BYTES/64-1];
    integer write_address=0,read_address=0,w_index=0,r_index=0,r_count=0,b_delay=0,r_delay=0,w_fault=0,r_fault=0;
    logic [3:0] read_identity=0;bit b_wrong_sent=0,reset_held=0;
    logic [31:0] rng=32'h9852cb7d;
    always @(negedge clk)begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        m_axi_awready=!rst&&!writing&&!b_pending&&!hold_aw&&(!random_stalls||rng[2:0]!=0);
        m_axi_wready=!rst&&writing&&!hold_w&&(!random_stalls||rng[5:3]!=0);
        m_axi_arready=!rst&&!reading&&!hold_ar&&(!random_stalls||rng[8:6]!=0);
    end
    always @(posedge clk)begin
        if(rst)begin
            writing=0;b_pending=0;reading=0;b_wrong_sent=0;w_index=0;r_index=0;b_delay=0;r_delay=0;
            m_axi_bvalid<=0;m_axi_rvalid<=0;m_axi_bid<=0;m_axi_bresp<=0;m_axi_rid<=0;m_axi_rresp<=0;m_axi_rlast<=0;m_axi_rdata<=0;
            if(!reset_held)begin
                for(integer i=0;i<BYTES;i++)memory_bytes[i]=8'((i*37)^(i>>3));
                for(integer i=0;i<CLASS_BYTES/64;i++)class_written[i]=0;
            end
            reset_held=1;
        end else begin
            reset_held=0;
            if(m_axi_awvalid&&m_axi_awready)begin
                if(m_axi_awid!=0||m_axi_awlen!=3||m_axi_awsize!=4||m_axi_awburst!=1||m_axi_awaddr[5:0]!=0||{1'b0,m_axi_awaddr}+64>33'(BYTES))$fatal(1,"Duplex AW grant/format");
                write_address=int'(m_axi_awaddr);w_index=0;writing=1;b_wrong_sent=0;w_fault=fault_kind;
            end
            if(m_axi_wvalid&&m_axi_wready)begin
                if(!writing||m_axi_wstrb!=16'hffff||m_axi_wlast!==(w_index==3))$fatal(1,"Duplex W ownership/strobe/LAST");
                for(integer i=0;i<16;i++)memory_bytes[write_address+w_index*16+i]=m_axi_wdata[i*8+:8];
                if(w_index==3)begin writing=0;b_pending=1;b_delay=7;end else w_index++;
            end
            // hold仅推迟首次公开；已公开的B正文和valid保持到实际fire。
            if(m_axi_bvalid&&m_axi_bready)begin
                m_axi_bvalid<=0;
                if(m_axi_bid==0)begin
                    b_pending=0;
                    if(write_address>=CLASS_BASE&&write_address<CLASS_BASE+CLASS_BYTES&&!class_written[(write_address-CLASS_BASE)/64])begin
                        class_written[(write_address-CLASS_BASE)/64]=1;
                        for(integer i=0;i<64;i++)first_class_bytes[write_address-CLASS_BASE+i]=memory_bytes[write_address+i];
                    end
                end else begin b_wrong_sent=1;b_delay=17;end
            end else if(b_pending&&!m_axi_bvalid)begin
                if(b_delay>0)b_delay--;
                else if(!hold_b)begin
                    m_axi_bvalid<=1;m_axi_bid<=w_fault==2&&!b_wrong_sent?4'd7:4'd0;m_axi_bresp<=w_fault==1?2'd2:2'd0;
                end
            end
            if(m_axi_arvalid&&m_axi_arready)begin
                if((m_axi_arid!=0&&m_axi_arid!=2)||m_axi_arsize!=4||m_axi_arburst!=1||m_axi_araddr[3:0]!=0||m_axi_arlen>63||
                    {1'b0,m_axi_araddr}+33'((int'(m_axi_arlen)+1)*16)>33'(BYTES)||int'(m_axi_araddr[11:0])+(int'(m_axi_arlen)+1)*16>4096)$fatal(1,"Duplex AR grant/format/4KiB");
                if(m_axi_arid==0&&(m_axi_arlen!=3||m_axi_araddr[5:0]!=0))$fatal(1,"Algorithm AR not 64B");
                read_address=int'(m_axi_araddr);r_index=0;r_count=int'(m_axi_arlen)+1;reading=1;r_delay=3;r_fault=fault_kind;read_identity=m_axi_arid;
            end
            if(m_axi_rvalid&&m_axi_rready)begin
                m_axi_rvalid<=0;
                if(m_axi_rlast&&m_axi_rid==read_identity)reading=0;
                else begin r_index++;r_delay=random_stalls?int'(rng[11:10]):1;end
            end else if(reading&&!m_axi_rvalid)begin
                if(r_delay>0)r_delay--;
                else if(!hold_r)begin
                    m_axi_rvalid<=1;m_axi_rid<=r_fault==4&&r_index==1?(read_identity^4'd1):read_identity;
                    m_axi_rresp<=r_fault==3&&r_index==2?2'd2:2'd0;
                    m_axi_rlast<=r_fault==5?r_index==1:r_fault==6?r_index>=r_count:r_index==r_count-1;
                    for(integer i=0;i<16;i++)begin
                        if(read_address+r_index*16+i<BYTES)m_axi_rdata[i*8+:8]<=memory_bytes[read_address+r_index*16+i];
                        else m_axi_rdata[i*8+:8]<=0;
                    end
                end
            end
        end
    end
endmodule

// T3：直接驱动hub的公开客户端。全部期望独立于DUT私有状态。
module tb_video_memory_hub_protocol;
    localparam integer CAPACITY=32768;
    logic clk=0,rst=1,axi_enable=1,producer_local_quarantined=0;
    always #5 clk=~clk;
    logic camera_req_valid=0,camera_rsp_ready=0;
    wire camera_req_ready,camera_rsp_valid,camera_error,camera_drained;
    logic [31:0] camera_addr=0;logic [511:0] camera_data=0;
    logic algorithm_req_valid=0,algorithm_write=0,algorithm_rsp_ready=0;
    wire algorithm_req_ready,algorithm_rsp_valid,algorithm_error,algorithm_drained;
    logic [31:0] algorithm_addr=0;logic [511:0] algorithm_wdata=0;wire [511:0] algorithm_rdata;
    logic display_enable=1,display_cancel=0,span_req_valid=0,display_done_ready=0,display_data_ready=1;
    wire span_req_ready,display_data_valid,display_done_valid,display_drained;
    logic [31:0] span_addr=0;logic [13:0] span_bytes=16;
    wire [127:0] display_data;wire [1:0] display_outcome;wire [7:0] display_reason;
    wire m_axi_awvalid,m_axi_awready,m_axi_wvalid,m_axi_wready,m_axi_wlast,m_axi_bvalid,m_axi_bready;
    wire m_axi_arvalid,m_axi_arready,m_axi_rvalid,m_axi_rready,m_axi_rlast;
    wire [31:0] m_axi_awaddr,m_axi_araddr;wire [3:0] m_axi_awid,m_axi_bid,m_axi_arid,m_axi_rid;
    wire [7:0] m_axi_awlen,m_axi_arlen;wire [2:0] m_axi_awsize,m_axi_arsize;
    wire [1:0] m_axi_awburst,m_axi_arburst,m_axi_bresp,m_axi_rresp;
    wire [127:0] m_axi_wdata,m_axi_rdata;wire [15:0] m_axi_wstrb;
    wire algorithm_live,read_occupied,read_physical_idle,write_busy,read_quarantined,write_quarantined,quarantined,direction_quarantined;
    wire [2:0] read_fault_reason,write_fault_reason;
    logic random_stalls=1,hold_aw=0,hold_w=0,hold_ar=0,hold_b=0,hold_r=0,hold_display=0;
    integer fault_kind=0;wire writing,b_pending,reading;
    video_memory_hub #(.ADDRESS_BYTES(33'(CAPACITY))) dut(.*);
    axi128_duplex_byte_memory #(.BYTES(CAPACITY)) slave(.*);
    integer case_id=0,cycle=0,case_start=0,trace_fd=0,result_fd=0,passed=0,metrics_fd;
    integer camera_count=0,algorithm_count=0,span_count=0,overlap_count=0,display_count=0;
    integer display_address=0,display_index=0;logic [31:0] random_word=32'h51648379;
    bit finished=0;string directory;

    function automatic logic [511:0] packet(input integer address,salt);
        for(integer i=0;i<64;i++)packet[i*8+:8]=8'(address+i*29+salt);
    endfunction
    function automatic logic [511:0] seeded_line(input integer address);
        for(integer i=0;i<64;i++)seeded_line[i*8+:8]=8'(((address+i)*37)^((address+i)>>3));
    endfunction
    function automatic logic [127:0] seeded_word(input integer address);
        for(integer i=0;i<16;i++)seeded_word[i*8+:8]=8'(((address+i)*37)^((address+i)>>3));
    endfunction
    always @(negedge clk)begin
        random_word={random_word[30:0],random_word[31]^random_word[21]^random_word[1]^random_word[0]};
        display_data_ready=!rst&&!hold_display&&random_word[2:0]!=0;
    end
    // 正沿前保存所有公开端口，不把数学slave或DUT内部状态写成期望。
    always @(posedge clk)if(trace_fd)begin
        cycle++;
        $fwrite(trace_fd,"%0d\t%0d\t%05b\t%0546b\t%04b\t%0547b\t%0516b\t%048b\t%0130b\t%013b\t%051b\t%0147b\t%08b\t%051b\t%0137b\t%08b\n",
            case_id,cycle,{rst,axi_enable,producer_local_quarantined,display_enable,display_cancel},
            {camera_req_valid,camera_req_ready,camera_addr,camera_data},{camera_rsp_valid,camera_rsp_ready,camera_error,camera_drained},
            {algorithm_req_valid,algorithm_req_ready,algorithm_write,algorithm_addr,algorithm_wdata},
            {algorithm_rsp_valid,algorithm_rsp_ready,algorithm_rdata,algorithm_error,algorithm_drained},
            {span_req_valid,span_req_ready,span_addr,span_bytes},{display_data_valid,display_data_ready,display_data},
            {display_done_valid,display_done_ready,display_outcome,display_reason,display_drained},
            {m_axi_awvalid,m_axi_awready,m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst},
            {m_axi_wvalid,m_axi_wready,m_axi_wdata,m_axi_wstrb,m_axi_wlast},
            {m_axi_bvalid,m_axi_bready,m_axi_bid,m_axi_bresp},
            {m_axi_arvalid,m_axi_arready,m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst},
            {m_axi_rvalid,m_axi_rready,m_axi_rdata,m_axi_rid,m_axi_rresp,m_axi_rlast},
            {quarantined,read_quarantined,write_quarantined,direction_quarantined,algorithm_live,write_busy,read_occupied,read_physical_idle});
        if(rst)begin display_address=0;display_index=0;end
        else begin
            if($isunknown({quarantined,read_quarantined,write_quarantined,direction_quarantined}))$fatal(1,"Hub Q contains X/Z");
            if(camera_req_valid&&camera_req_ready)camera_count++;
            if(algorithm_req_valid&&algorithm_req_ready)algorithm_count++;
            if(span_req_valid&&span_req_ready)begin span_count++;display_address=int'(span_addr);display_index=0;end
            if(display_data_valid&&display_data_ready)begin
                if(display_data!==seeded_word(display_address+16*display_index))$fatal(1,"Public display bytes differ from independent seed");
                display_index++;display_count++;
            end
            if(reading&&(writing||b_pending))overlap_count++;
        end
        if(cycle-case_start>60000)$fatal(1,"Independent hub watchdog case=%0d",case_id);
    end
    task automatic cold(input integer id);
        @(negedge clk);case_id=id;case_start=cycle;rst=1;axi_enable=1;producer_local_quarantined=0;
        camera_req_valid=0;camera_rsp_ready=0;algorithm_req_valid=0;algorithm_write=0;algorithm_rsp_ready=0;
        span_req_valid=0;display_enable=1;display_cancel=0;display_done_ready=0;
        hold_aw=0;hold_w=0;hold_ar=0;hold_b=0;hold_r=0;hold_display=0;fault_kind=0;
        repeat(3)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic camera(input integer address,salt=17);
        @(negedge clk);camera_addr=32'(address);camera_data=packet(address,salt);camera_req_valid=1;
        do @(posedge clk);while(camera_req_ready!==1'b1);@(negedge clk);camera_req_valid=0;
    endtask
    task automatic algorithm(input bit write_request,input integer address,salt=51);
        @(negedge clk);algorithm_write=write_request;algorithm_addr=32'(address);algorithm_wdata=packet(address,salt);algorithm_req_valid=1;
        do @(posedge clk);while(algorithm_req_ready!==1'b1);@(negedge clk);algorithm_req_valid=0;
    endtask
    task automatic span(input integer address,bytes);
        @(negedge clk);span_addr=32'(address);span_bytes=14'(bytes);span_req_valid=1;
        do @(posedge clk);while(span_req_ready!==1'b1);@(negedge clk);span_req_valid=0;
    endtask
    task automatic camera_reply(input bit error_expected=0,drain_expected=1);
        while(camera_rsp_valid!==1'b1)@(negedge clk);
        if(camera_error!==error_expected||camera_drained!==drain_expected)$fatal(1,"Camera reply expected error/drain");
        repeat(7)@(negedge clk);camera_rsp_ready=1;@(posedge clk);@(negedge clk);camera_rsp_ready=0;
    endtask
    task automatic algorithm_reply(input bit error_expected,drain_expected,input logic [511:0] expected_data,input bit check_data=1);
        while(algorithm_rsp_valid!==1'b1)@(negedge clk);
        if(algorithm_error!==error_expected||algorithm_drained!==drain_expected||(check_data&&algorithm_rdata!==expected_data))$fatal(1,"Algorithm reply direction/data/error/drain");
        repeat(7)@(negedge clk);algorithm_rsp_ready=1;@(posedge clk);@(negedge clk);algorithm_rsp_ready=0;
        if(!drain_expected&&!algorithm_live)$fatal(1,"UNKNOWN reply incorrectly released algorithm borrow");
    endtask
    task automatic display_reply(input integer outcome_expected);
        while(display_done_valid!==1'b1)@(negedge clk);
        if(display_outcome!==2'(outcome_expected)||!display_drained)$fatal(1,"Display terminal mismatch");
        repeat(7)@(negedge clk);display_done_ready=1;@(posedge clk);@(negedge clk);display_done_ready=0;
    endtask
    // Q后提出的新请求持续保持，直到下一次可信cold；不偷偷撤PUBLIC。
    task automatic block_new;
        @(negedge clk);
        if(!camera_req_valid)begin camera_addr=16384;camera_data=packet(16384,17);camera_req_valid=1;end
        if(!algorithm_req_valid)begin algorithm_addr=8192;algorithm_write=0;algorithm_wdata=0;algorithm_req_valid=1;end
        if(!span_req_valid)begin span_addr=24576;span_bytes=16;span_req_valid=1;end
        repeat(12)begin @(negedge clk);if(!quarantined||camera_req_ready||algorithm_req_ready||span_req_ready)$fatal(1,"Q accepted new client");end
    endtask
    task automatic mark_case;
        $fwrite(result_fd,"%0d\t%0d\n",case_id,cycle-case_start);passed++;
    endtask
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",directory))$fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected CAPTURE HUB fatal probe");
        trace_fd=$fopen({directory,"/hub-public.tsv"},"w");result_fd=$fopen({directory,"/hub-cases.tsv"},"w");
        if(!trace_fd||!result_fd)$fatal(1,"Hub trace open");
        $fwrite(trace_fd,"case\tcycle\tcontrols\tcamreq\tcamrsp\talgreq\talgrsp\tspanreq\tdisplayword\tdisplaydone\taw\tw\tb\tar\tr\tdiagnostics\n");
        cold(1);algorithm(0,8192);while(!algorithm_rsp_valid)@(negedge clk);algorithm_write=1;algorithm_addr=4096;algorithm_wdata='1;
        algorithm_reply(0,1,seeded_line(8192));mark_case();
        cold(2);algorithm(1,4096);while(!algorithm_rsp_valid)@(negedge clk);algorithm_write=0;algorithm_addr=8192;
        algorithm_reply(0,1,0);mark_case();
        cold(3);
        fork
            begin for(integer i=0;i<16;i++)begin camera(i*64);camera_reply();end end
            begin for(integer i=0;i<12;i++)begin algorithm(1,4096+i*64);algorithm_reply(0,1,0);end end
            begin span(12272,8192);display_reply(0);if(display_index!=512)$fatal(1,"8192 span incomplete");end
        join mark_case();
        cold(4);camera(0,99);camera_reply();algorithm(0,0);algorithm_reply(0,1,packet(0,99));mark_case();
        for(integer id=5;id<=8;id++)begin
            integer address;cold(id);case(id)5:address=1;6:address=32768;7:address=-64;8:address=32736;endcase
            algorithm(0,address);algorithm_reply(1,1,0,0);mark_case();
        end
        for(integer id=9;id<=13;id++)begin
            integer address,bytes;cold(id);address=24576;bytes=16;
            case(id)9:address=24577;10:bytes=0;11:bytes=15;12:bytes=8193;13:begin address=32752;bytes=32;end endcase
            span(address,bytes);display_reply(1);mark_case();
        end
        cold(14);span(32752,16);display_reply(0);mark_case();
        cold(15);hold_ar=1;span(12272,8192);while(!m_axi_arvalid)@(negedge clk);display_cancel=1;
        repeat(7)@(negedge clk);display_cancel=0;hold_ar=0;display_reply(2);mark_case();
        cold(16);hold_display=1;span(24576,64);while(!display_data_valid)@(negedge clk);display_cancel=1;
        repeat(7)@(negedge clk);display_cancel=0;hold_display=0;display_reply(2);mark_case();
        cold(17);fault_kind=1;algorithm(1,4096);algorithm_reply(1,1,0);mark_case();
        cold(18);fault_kind=3;algorithm(0,8192);algorithm_reply(1,1,0,0);mark_case();
        for(integer id=19;id<=22;id++)begin
            cold(id);fault_kind=id==19?2:id==20?4:id==21?5:6;
            algorithm(id==19,id==19?4096:8192);algorithm_reply(1,0,0,id==19);block_new();mark_case();
        end
        cold(23);hold_b=1;algorithm(1,4096);while(!b_pending)@(negedge clk);axi_enable=0;
        repeat(7)@(negedge clk);axi_enable=1;hold_b=0;algorithm_reply(1,0,0);block_new();mark_case();
        cold(24);hold_r=1;algorithm(0,8192);while(!reading)@(negedge clk);axi_enable=0;
        repeat(7)@(negedge clk);axi_enable=1;hold_r=0;algorithm_reply(1,0,0,0);block_new();mark_case();
        cold(25);hold_b=1;hold_r=1;camera(0);algorithm(0,8192);while(!b_pending||!reading)@(negedge clk);
        producer_local_quarantined=1;repeat(7)@(negedge clk);hold_b=0;hold_r=0;
        fork camera_reply();algorithm_reply(0,1,seeded_line(8192));join block_new();mark_case();
        cold(26);camera(0);while(!camera_rsp_valid)@(negedge clk);fault_kind=4;algorithm(0,8192);
        while(!read_quarantined)@(negedge clk);fork camera_reply();algorithm_reply(1,0,0,0);join block_new();mark_case();
        cold(27);algorithm(0,8192);while(!algorithm_rsp_valid)@(negedge clk);fault_kind=2;camera(0);
        while(!write_quarantined)@(negedge clk);fork camera_reply(1,0);algorithm_reply(0,1,seeded_line(8192));join block_new();mark_case();
        cold(28);hold_r=1;span(12272,8192);while(!reading)@(negedge clk);fault_kind=2;camera(0);
        while(!write_quarantined)@(negedge clk);hold_r=0;fault_kind=0;
        fork camera_reply(1,0);display_reply(0);join
        if(display_index!=512)$fatal(1,"Write Q abandoned old span grant");block_new();mark_case();
        cold(29);@(negedge clk);algorithm_req_valid=1;algorithm_write=1'bx;algorithm_addr=8192;algorithm_wdata=0;
        repeat(7)@(negedge clk);if(!direction_quarantined||algorithm_rsp_valid)$fatal(1,"Unknown direction accepted/replied");block_new();mark_case();
        cold(30);@(negedge clk);camera_req_valid=1;camera_addr=0;camera_data='x;
        repeat(7)@(negedge clk);if(!write_quarantined||camera_rsp_valid)$fatal(1,"Unknown camera packet accepted/replied");block_new();mark_case();
        cold(31);algorithm(0,8192);while(!algorithm_rsp_valid)@(negedge clk);axi_enable=0;
        repeat(7)@(negedge clk);algorithm_reply(0,1,seeded_line(8192));axi_enable=1;
        if(quarantined)$fatal(1,"Held safe reply treated as live backend transfer");mark_case();
        cold(32);hold_b=1;hold_r=1;camera(0);algorithm(0,8192);while(!b_pending||!reading)@(negedge clk);repeat(7)@(negedge clk);mark_case();
        cold(33);algorithm(0,8192);algorithm_reply(0,1,seeded_line(8192));if(quarantined||algorithm_live||write_busy)$fatal(1,"Common cold did not recover");mark_case();
        if(passed!=33||!overlap_count)$fatal(1,"Hub coverage incomplete");
        finished=1;$fclose(trace_fd);$fclose(result_fd);metrics_fd=$fopen({directory,"/hub-protocol-metrics.json"},"w");
        $fwrite(metrics_fd,"{\"finished\":true,\"cases\":%0d,\"cycles\":%0d,\"camera_requests\":%0d,\"algorithm_requests\":%0d,\"span_requests\":%0d,\"display_words\":%0d,\"overlap_cycles\":%0d}\n",passed,cycle,camera_count,algorithm_count,span_count,display_count,overlap_count);
        $fclose(metrics_fd);$finish;
    end
endmodule
