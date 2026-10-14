`timescale 1ns/1ps
// RA-T1..7：负沿驱动，正沿前记全总线；共同冷reset与业务enable严格分开。
module tb_axi_read_arbiter2;
    logic clk=0,rst=1,enable=1;
    always #5 clk=~clk;
    logic [1:0] c_arvalid=0,c_arready,c_rvalid,c_rready=3;
    logic [1:0][31:0] c_araddr=0;
    logic [1:0][3:0] c_arid=0,c_rid;
    logic [1:0][7:0] c_arlen=0;
    logic [1:0][2:0] c_arsize=0;
    logic [1:0][1:0] c_arburst=0,c_rresp;
    wire [1:0][127:0] c_rdata;
    wire [1:0] c_rlast;
    wire m_axi_arvalid,m_axi_rready,idle,occupied;
    logic m_axi_arready=0,m_axi_rvalid=0,m_axi_rlast=0;
    wire [31:0] m_axi_araddr;
    wire [3:0] m_axi_arid;
    wire [7:0] m_axi_arlen;
    wire [2:0] m_axi_arsize;
    wire [1:0] m_axi_arburst;
    logic [127:0] m_axi_rdata=0;
    logic [3:0] m_axi_rid=0;
    logic [1:0] m_axi_rresp=0;
    wire quarantined;
    wire [2:0] fault_reason;
    axi_read_arbiter2 dut(.*);
    bit finished=0,ar_event,r_event;
    logic [1:0] client_ar_event;
    logic [48:0] fired_ar;
    integer case_id=0,cycle=0,log_fd=0,result_fd;
    integer physical_ar=0,physical_r=0,completed_cases=0;
    string run_dir;
    function automatic logic [48:0] client_body(input integer port);
        client_body={c_araddr[port],c_arid[port],c_arlen[port],c_arsize[port],c_arburst[port]};
    endfunction
    function automatic logic [127:0] memory_word(input logic [31:0] address);
        for(integer byte_index=0;byte_index<16;byte_index++)
            memory_word[byte_index*8+:8]=8'((address+32'(byte_index))*32'd37+32'd11);
    endfunction
    always @(posedge clk)if(log_fd!=0)begin
        $fwrite(log_fd,"%0d\t%0d\t%b\t%b\t%02b\t%049b\t%049b\t%02b\t%b\t%b\t%049b\t%b\t%b\t%0135b\t%02b\t%02b\t%0135b\t%0135b\t%b\t%0d\t%b\t%b\n",
            case_id,cycle,rst,enable,c_arvalid,client_body(0),client_body(1),c_arready,
            m_axi_arvalid,m_axi_arready,{m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst},
            m_axi_rvalid,m_axi_rready,{m_axi_rdata,m_axi_rid,m_axi_rresp,m_axi_rlast},
            c_rvalid,c_rready,{c_rdata[0],c_rid[0],c_rresp[0],c_rlast[0]},
            {c_rdata[1],c_rid[1],c_rresp[1],c_rlast[1]},quarantined,fault_reason,occupied,idle);
        cycle++;
    end
    task automatic step;
        @(posedge clk);
        ar_event=m_axi_arvalid && m_axi_arready;
        r_event=m_axi_rvalid && m_axi_rready;
        client_ar_event=c_arvalid & c_arready;
        fired_ar={m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst};
        if(ar_event)physical_ar++;
        if(r_event)physical_r++;
        #1;@(negedge clk);
    endtask
    // 这里明确模拟DDR、两个客户端与核心一起冷复位；不伪造业务closed。
    task automatic cold(input integer id);
        case_id=id;rst=1;enable=1;c_arvalid=0;m_axi_arready=0;m_axi_rvalid=0;
        m_axi_rdata=0;m_axi_rid=0;m_axi_rresp=0;m_axi_rlast=0;c_rready=3;
        c_araddr=0;c_arid[0]=2;c_arid[1]=0;c_arlen[0]=0;c_arlen[1]=3;c_arsize='{default:3'd4};c_arburst='{default:2'd1};
        repeat(3)step();rst=0;step();
        if(!idle || occupied || quarantined)$fatal(1,"Cold reset did not establish empty state");
    endtask
    task automatic arm(input integer port,input logic [31:0] address,input logic [7:0] length);
        c_araddr[port]=address;c_arlen[port]=length;c_arvalid=2'(1<<port);m_axi_arready=0;
        step();if(!m_axi_arvalid || !occupied)$fatal(1,"AR not captured");
    endtask
    task automatic accept_ar;
        m_axi_arready=1;step();if(!ar_event)$fatal(1,"AR not physically accepted");c_arvalid=0;
    endtask
    task automatic beat(input logic [31:0] address,input logic [3:0] rid,input logic last,input logic [1:0] resp=0);
        m_axi_rdata=memory_word(address);m_axi_rid=rid;m_axi_rlast=last;m_axi_rresp=resp;
        m_axi_rvalid=1;c_rready=3;step();if(!r_event)$fatal(1,"R not forwarded to actual owner");m_axi_rvalid=0;
    endtask
    task automatic expect_q(input logic [2:0] reason);
        repeat(4)step();
        if(!quarantined || fault_reason!=reason || !occupied || idle)$fatal(1,"Unknown owner incorrectly released reason=%0d",reason);
        completed_cases++;
    endtask
    task automatic normal(input integer id,input integer display_count,algorithm_count,input bit stalls,input logic [1:0] response_code=0);
        integer issued[0:1],limits[0:1],ticks,index,total;bit server_live;
        logic [31:0] server_address;logic [3:0] server_id;
        cold(id);issued[0]=0;issued[1]=0;limits[0]=display_count;limits[1]=algorithm_count;
        ticks=0;index=0;total=0;server_live=0;
        c_arvalid={algorithm_count!=0,display_count!=0};c_araddr[0]=32'h01000000;c_araddr[1]=32'h02000000;
        while(issued[0]<limits[0] || issued[1]<limits[1] || server_live || !idle)begin
            if(ticks>50000)$fatal(1,"Normal read timeout");
            m_axi_arready=!stalls || ticks%37>=11;
            c_rready[0]=!stalls || ticks%41>=13;c_rready[1]=!stalls || ticks%31>=7;
            if(!m_axi_rvalid && server_live && (!stalls || ticks%5!=0))begin
                m_axi_rvalid=1;m_axi_rdata=memory_word(server_address+32'(index*16));
                m_axi_rid=server_id;m_axi_rresp=response_code;m_axi_rlast=index==total-1;
            end
            step();ticks++;
            if(ar_event)begin
                if(server_live)$fatal(1,"Two physical reads in flight");
                server_live=1;server_address=fired_ar[48:17];server_id=fired_ar[16:13];
                total=int'(fired_ar[12:5])+1;index=0;
                for(integer port=0;port<2;port++)if(client_ar_event[port])begin
                    issued[port]++;c_arvalid[port]=issued[port]<limits[port];
                    c_araddr[port]=(port==0?32'h01000000:32'h02000000)+32'(issued[port]*4096);
                    c_arlen[port]=port==0?8'(issued[port]%64):8'd3;
                end
            end
            if(r_event)begin index++;m_axi_rvalid=0;if(index==total)server_live=0;end
            if(quarantined)$fatal(1,"Normal traffic quarantined");
        end
        completed_cases++;
    endtask
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir))$fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected READ fatal probe");
        log_fd=$fopen({run_dir,"/read-events.tsv"},"w");if(log_fd==0)$fatal(1,"Cannot open events");
        $fwrite(log_fd,"case\tcycle\trst\tenable\tcav\tca0\tca1\tcar\tmav\tmar\tma\tmrv\tmrr\tmr\tcrv\tcrr\tcr0\tcr1\tq\treason\toccupied\tidle\n");
        normal(1,24,8,0);normal(2,64,0,1);normal(3,0,32,0);normal(4,24,8,1);normal(9,4,4,1,2);
        cold(5);enable=0;c_arvalid=3;repeat(8)step();if(m_axi_arvalid || !idle)$fatal(1,"Disabled selection");
        enable=1;step();accept_ar();beat(0,2,1);step();if(!idle)$fatal(1,"Enable restart");completed_cases++;
        cold(6);arm(0,32'h1000,3);enable=0;repeat(8)step();accept_ar();
        for(integer b=0;b<4;b++)beat(32'h1000+32'(b*16),2,b==3);
        step();if(!idle)$fatal(1,"Disable withdrew pending AR");completed_cases++;
        cold(7);arm(1,32'h2000,3);accept_ar();beat(32'h2000,0,0);enable=0;
        for(integer b=1;b<4;b++)beat(32'h2000+32'(b*16),0,b==3);
        step();if(!idle)$fatal(1,"Disable withdrew R tail");completed_cases++;
        cold(8);arm(0,32'h3000,0);m_axi_arready=1;m_axi_rvalid=1;m_axi_rdata=memory_word(32'h3000);m_axi_rid=2;m_axi_rlast=1;
        step();if(!ar_event || r_event || quarantined)$fatal(1,"Zero-delay R acceptance");c_arvalid=0;
        step();if(!r_event)$fatal(1,"Zero-delay held R not consumed");m_axi_rvalid=0;step();if(!idle)$fatal(1,"Zero-delay tail");completed_cases++;
        for(integer bad=10;bad<=16;bad++)begin
            cold(bad);c_arvalid=1;c_araddr[0]=32'h4000;
            case(bad)
                10:c_araddr[0]=32'h4001;
                11:begin c_araddr[0]=32'h4ff0;c_arlen[0]=1;end
                12:begin c_araddr[0]=32'h0ffffff0;c_arlen[0]=1;end
                13:c_arsize[0]=3;
                14:c_arburst[0]=0;
                15:c_arid[0]=3;
                16:begin c_arvalid=2;c_arlen[1]=4;end
            endcase
            step();if(ar_event || m_axi_arvalid)$fatal(1,"Invalid AR published");expect_q(1);
        end
        cold(17);arm(1,32'h5000,3);accept_ar();beat(32'h5000,7,0);
        for(integer b=1;b<4;b++)beat(32'h5000+32'(b*16),0,b==3);expect_q(3);
        cold(18);arm(1,32'h6000,3);accept_ar();beat(32'h6000,0,0);beat(32'h6010,0,1);beat(32'h6020,0,0);beat(32'h6030,0,1);expect_q(4);
        cold(19);arm(1,32'h7000,3);accept_ar();for(integer b=0;b<4;b++)beat(32'h7000+32'(b*16),0,0);beat(32'h7040,0,1);expect_q(4);
        cold(20);m_axi_rvalid=1;m_axi_rid=2;m_axi_rlast=1;m_axi_rdata=memory_word(32'h8000);step();
        if(r_event || c_rvalid!=0)$fatal(1,"Unknown R routed");expect_q(5);
        cold(21);arm(0,32'h9000,0);c_araddr[0]=32'h9010;step();if(!m_axi_arvalid || m_axi_araddr!=32'h9000)$fatal(1,"Changed locked AR");accept_ar();beat(32'h9000,2,1);expect_q(2);
        cold(22);arm(0,32'ha000,0);c_arvalid[0]=1'bx;step();accept_ar();beat(32'ha000,2,1);expect_q(2);
        cold(23);arm(1,32'h0fffffc0,3);accept_ar();for(integer b=0;b<4;b++)beat(32'h0fffffc0+32'(b*16),0,b==3);step();if(!idle)$fatal(1,"Top geometry edge");completed_cases++;
        cold(24);arm(0,32'hbfc0,3);accept_ar();for(integer b=0;b<4;b++)beat(32'hbfc0+32'(b*16),2,b==3);step();if(!idle)$fatal(1,"Page edge");completed_cases++;
        cold(25);arm(1,32'hc000,3);cold(25);arm(1,32'hc000,3);accept_ar();beat(32'hc000,0,0);cold(25);arm(0,32'hd000,0);accept_ar();beat(32'hd000,2,1);step();if(!idle)$fatal(1,"Common reset recovery");completed_cases++;
        cold(26);c_arvalid=1;c_arid[0]=4'bxxxx;step();expect_q(1);
        // 收尾只是日志结束，不解除最后Q对象，不写任何closed。
        repeat(2)step();$fclose(log_fd);log_fd=0;
        result_fd=$fopen({run_dir,"/read-result.json"},"w");
        $fwrite(result_fd,"{\"finished\":true,\"physical_ar\":%0d,\"physical_r\":%0d,\"cases\":%0d,\"cycles\":%0d,\"final_quarantine_retained\":true}\n",physical_ar,physical_r,completed_cases,cycle);$fclose(result_fd);
        finished=1;$display("PASS read arbitration cases=%0d AR=%0d R=%0d",completed_cases,physical_ar,physical_r);$finish;
    end
endmodule
