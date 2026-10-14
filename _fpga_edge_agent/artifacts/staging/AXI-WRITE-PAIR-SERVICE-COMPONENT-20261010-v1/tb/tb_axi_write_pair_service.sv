`timescale 1ns/1ps
// WT1..7：数学producer遵从实际64B接口；只有实际AW/W/B接受才推进slave。
module tb_axi_write_pair_service;
    logic clk=0,rst=1,enable=1;always #5 clk=~clk;
    logic [1:0] c_req_valid=0,c_rsp_ready=0;
    wire [1:0] c_req_ready,c_rsp_valid,c_error,c_drained;
    logic [31:0] c_addr[0:1];logic [511:0] c_data[0:1];
    wire m_axi_awvalid,m_axi_wvalid,m_axi_wlast,m_axi_bready;
    logic m_axi_awready=0,m_axi_wready=0,m_axi_bvalid=0;
    wire [31:0] m_axi_awaddr;wire [3:0] m_axi_awid;wire [7:0] m_axi_awlen;
    wire [2:0] m_axi_awsize;wire [1:0] m_axi_awburst;
    wire [127:0] m_axi_wdata;wire [15:0] m_axi_wstrb;
    logic [3:0] m_axi_bid=0;logic [1:0] m_axi_bresp=0;
    wire busy,quarantined,local_quarantined,bridge_quarantined;wire [2:0] fault_reason;
    axi_write_pair_service dut(.*);
    bit finished=0,af,wf,bf;logic [1:0] cf,rf;
    integer fd=0,memory_fd=0,result_fd,case_id=0,cycle=0,completed_cases=0,requests=0,replies=0,aws=0,words=0,bs=0;
    byte unsigned slave_memory[logic [31:0]];
    logic [31:0] memory_address;integer memory_index;bit memory_owner;
    logic [511:0] memory_snapshot;
    string run_dir;
    function automatic logic [511:0] payload(input integer port,sequence_index);
        logic [63:0] seed;seed=64'h4310_60f2_25a5_c39d;
        case(sequence_index%8)
            0:payload=0;1:payload='1;2:payload=512'd1;3:payload=512'd1<<511;
            default:for(integer i=0;i<64;i++)
                payload[i*8+:8]=8'((i*37+sequence_index*73+port*101)^(sequence_index>>(i%5))^(seed>>((i%8)*8)));
        endcase
    endfunction
    always @(posedge clk)if(fd!=0)begin
        $fwrite(fd,"%0d\t%0d\t%b\t%b\t%02b\t%02b\t%0544b\t%0544b\t%02b\t%02b\t%02b\t%02b\t%b\t%b\t%049b\t%b\t%b\t%0145b\t%b\t%b\t%06b\t%b\t%b\t%b\t%0d\t%b\n",
            case_id,cycle,rst,enable,c_req_valid,c_req_ready,{c_addr[0],c_data[0]},{c_addr[1],c_data[1]},
            c_rsp_valid,c_rsp_ready,c_error,c_drained,m_axi_awvalid,m_axi_awready,
            {m_axi_awaddr,m_axi_awid,m_axi_awlen,m_axi_awsize,m_axi_awburst},m_axi_wvalid,m_axi_wready,
            {m_axi_wdata,m_axi_wstrb,m_axi_wlast},m_axi_bvalid,m_axi_bready,{m_axi_bid,m_axi_bresp},
            quarantined,local_quarantined,bridge_quarantined,fault_reason,busy);
        if(rst)begin slave_memory.delete();memory_owner=0;memory_index=0;end
        else begin
            if(m_axi_awvalid&&m_axi_awready)begin
                if(memory_owner)$fatal(1,"Memory slave overlapping AW");
                memory_owner=1;memory_address=m_axi_awaddr;memory_index=0;
            end
            if(m_axi_wvalid&&m_axi_wready)begin
                if(!memory_owner||memory_index>=4)$fatal(1,"Memory slave W outside ownership");
                for(integer i=0;i<16;i++)if(m_axi_wstrb[i])slave_memory[memory_address+32'(memory_index*16+i)]=m_axi_wdata[i*8+:8];
                memory_index++;
            end
            if(m_axi_bvalid&&m_axi_bready&&m_axi_bid==0)begin
                if(!memory_owner||memory_index!=4)$fatal(1,"Memory slave response before full write");
                for(integer i=0;i<64;i++)begin
                    if(!slave_memory.exists(memory_address+32'(i)))$fatal(1,"Memory slave missing byte");
                    memory_snapshot[i*8+:8]=slave_memory[memory_address+32'(i)];
                end
                $fwrite(memory_fd,"%0d\t%0d\t%032b\t%0512b\n",case_id,cycle,memory_address,memory_snapshot);
                memory_owner=0;
            end
        end
        cycle++;
    end
    task automatic step;
        @(posedge clk);cf=c_req_valid&c_req_ready;rf=c_rsp_valid&c_rsp_ready;
        af=m_axi_awvalid&&m_axi_awready;wf=m_axi_wvalid&&m_axi_wready;bf=m_axi_bvalid&&m_axi_bready;
        if(cf[0])requests++;if(cf[1])requests++;if(rf[0])replies++;if(rf[1])replies++;
        if(af)aws++;if(wf)words++;if(bf)bs++;#1;@(negedge clk);
    endtask
    task automatic cold(input integer id);
        case_id=id;rst=1;enable=1;c_req_valid=0;c_rsp_ready=0;c_addr[0]=0;c_addr[1]=0;c_data[0]=0;c_data[1]=0;
        m_axi_awready=0;m_axi_wready=0;m_axi_bvalid=0;m_axi_bid=0;m_axi_bresp=0;
        repeat(3)step();rst=0;step();if(quarantined||busy)$fatal(1,"Cold did not establish empty write service");
    endtask
    task automatic request(input integer port,input logic [31:0] address,input integer sequence_index);
        integer ticks;ticks=0;c_req_valid=2'(1<<port);c_addr[port]=address;c_data[port]=payload(port,sequence_index);
        do begin step();if(ticks++>200)$fatal(1,"Write request timeout");end while(!cf[port]);
        c_req_valid=0;c_addr[port]=32'hdead_beef;c_data[port]=~payload(port,sequence_index);
    endtask
    task automatic wait_aw;
        integer ticks;ticks=0;m_axi_awready=0;
        while(!m_axi_awvalid)begin step();if(ticks++>200)$fatal(1,"Write AW timeout");end
    endtask
    task automatic accept_aw;
        m_axi_awready=1;step();if(!af)$fatal(1,"AW not accepted");m_axi_awready=0;
    endtask
    task automatic write_word(input integer index);
        integer ticks;ticks=0;m_axi_wready=1;
        do begin step();if(ticks++>200)$fatal(1,"Write W timeout");end while(!wf);
        m_axi_wready=0;
    endtask
    task automatic response(input logic [3:0] id,input logic [1:0] resp);
        integer ticks;ticks=0;m_axi_bvalid=1;m_axi_bid=id;m_axi_bresp=resp;
        do begin step();if(ticks++>200)$fatal(1,"B was unexpectedly blocked");end while(!bf);
        m_axi_bvalid=0;
    endtask
    task automatic finish_reply(input integer port);
        integer ticks;ticks=0;c_rsp_ready=2'(1<<port);
        do begin step();if(ticks++>200)$fatal(1,"Write reply missing");end while(!rf[port]);
        c_rsp_ready=0;repeat(3)step();
    endtask
    task automatic wait_reply(input integer port);
        integer ticks;ticks=0;
        while(!c_rsp_valid[port])begin step();if(ticks++>200)$fatal(1,"Write notice missing");end
    endtask
    task automatic gate_check;
        c_req_valid=3;c_addr[0]=32'h01008000;c_addr[1]=32'h02008000;c_data[0]=payload(0,5);c_data[1]=payload(1,5);
        repeat(12)begin step();if(!quarantined||!busy||c_req_ready!=0||af)$fatal(1,"Q reused unknown write owner");end
        c_req_valid=0;
    endtask
    task automatic normal(input integer id,count0,count1,input bit stalls,input logic [1:0] resp=0,
                          input logic [31:0] base0=32'h01000000,base1=32'h02000000,input integer initial_stop=0);
        integer issued[0:1],consumed[0:1],limits[0:1],ticks,beat_index,due;bit live;
        cold(id);issued[0]=0;issued[1]=0;consumed[0]=0;consumed[1]=0;limits[0]=count0;limits[1]=count1;ticks=0;beat_index=0;due=0;live=0;
        while(consumed[0]<count0||consumed[1]<count1||live||busy)begin
            if(ticks>100000)$fatal(1,"Normal write timeout case=%0d",id);
            enable=ticks>=initial_stop;
            for(integer p=0;p<2;p++)begin
                c_req_valid[p]=issued[p]<limits[p];c_addr[p]=(p==0?base0:base1)+32'(issued[p]*64);
                c_data[p]=payload(p,issued[p]);c_rsp_ready[p]=!stalls||ticks%(31+p*6)>=11;
            end
            m_axi_awready=!stalls||ticks%23>=9;m_axi_wready=!stalls||ticks%29>=12;
            if(!m_axi_bvalid&&live&&beat_index==4&&ticks>=due)begin m_axi_bvalid=1;m_axi_bid=0;m_axi_bresp=resp;end
            step();ticks++;
            for(integer p=0;p<2;p++)begin if(cf[p])issued[p]++;if(rf[p])consumed[p]++;end
            if(af)begin if(live)$fatal(1,"Overlapping AW");live=1;beat_index=0;end
            if(wf)begin beat_index++;if(beat_index==4)due=ticks+(stalls?19:2);end
            if(bf)begin m_axi_bvalid=0;live=0;end
            if(quarantined)$fatal(1,"Normal write Q");
        end
        c_req_valid=0;c_rsp_ready=0;repeat(3)step();completed_cases++;
    endtask
    task automatic disabled_live(input integer id,phase);
        cold(id);request(id%2,32'h03000000+32'(id*64),5);wait_aw();
        if(phase==0)begin enable=0;repeat(9)step();enable=1;end
        accept_aw();
        for(integer i=0;i<4;i++)begin
            if(phase==i+1)begin enable=0;repeat(7)step();enable=1;end
            write_word(i);
        end
        if(phase==5)begin enable=0;repeat(9)step();enable=1;end
        response(0,0);finish_reply(id%2);
        if(!quarantined||!bridge_quarantined||fault_reason!=4)$fatal(1,"Unsafe enable restored old write");
        gate_check();completed_cases++;
    endtask
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir))$fatal(1,"RUN_DIR missing");
        if($test$plusargs("FATAL_PROBE"))$fatal(1,"expected WRITE fatal probe");
        fd=$fopen({run_dir,"/write-events.tsv"},"w");if(fd==0)$fatal(1,"Cannot write trace");
        memory_fd=$fopen({run_dir,"/write-memory.tsv"},"w");if(memory_fd==0)$fatal(1,"Cannot write memory snapshots");
        $fwrite(memory_fd,"case\tcycle\taddr\tdata\n");
        $fwrite(fd,"case\tcycle\trst\tenable\tcv\tcr\tca0\tca1\trv\trr\ter\tdr\tav\tar\ta\twv\twr\tw\tbv\tbr\tb\tq\tlq\tbq\tfault\tbusy\n");
        normal(1,48,16,0);normal(2,48,16,1);normal(3,24,0,1);normal(4,0,24,1);normal(5,16,16,1);
        normal(6,1,0,0,0,32'h0fffffc0);normal(7,1,0,0,0,32'h01000001);normal(8,0,1,0,0,32'h01000000,32'h10000000);
        normal(9,3,0,1,1);normal(10,0,3,1,2);normal(11,3,3,1,3);normal(12,3,1,0,0,32'h01000000,32'h02000000,16);
        for(integer i=0;i<6;i++)disabled_live(13+i,i);
        cold(19);request(0,32'h03000000,5);wait_aw();accept_aw();for(integer i=0;i<4;i++)write_word(i);response(0,0);
        wait_reply(0);enable=0;repeat(17)step();enable=1;finish_reply(0);if(quarantined||busy)$fatal(1,"Held safe reply poisoned by late disable");completed_cases++;
        cold(20);request(0,32'h03000001,5);wait_reply(0);m_axi_bvalid=1;m_axi_bid=6;m_axi_bresp=0;
        repeat(9)step();if(quarantined)$fatal(1,"Existing public invalid reply rewritten");finish_reply(0);
        if(!local_quarantined||fault_reason!=2)$fatal(1,"Unowned B after held reply not isolated");gate_check();completed_cases++;
        for(integer id=21;id<=22;id++)begin
            cold(id);request(1,32'h03000000,5);wait_aw();accept_aw();for(integer i=0;i<4;i++)write_word(i);
            response(7,0);finish_reply(1);if(id==22)response(6,3);response(0,0);
            if(!quarantined||!busy||fault_reason!=4)$fatal(1,"Late correct B released unknown owner");gate_check();completed_cases++;
        end
        cold(23);m_axi_bvalid=1;m_axi_bid=3;c_req_valid=3;c_addr[0]=32'h01000000;c_addr[1]=32'h02000000;
        repeat(8)begin step();if(cf!=0||af||bf)$fatal(1,"Unowned B allowed new/false acceptance");end
        if(fault_reason!=2||c_rsp_valid!=0)$fatal(1,"Unowned B fabricated reply");gate_check();completed_cases++;
        cold(24);request(0,32'h03000000,5);wait_aw();m_axi_bvalid=1;m_axi_bid=0;m_axi_bresp=0;repeat(8)step();
        accept_aw();for(integer i=0;i<4;i++)write_word(i);
        do begin step();end while(!bf);m_axi_bvalid=0;finish_reply(0);
        if(!local_quarantined||bridge_quarantined||fault_reason!=3)$fatal(1,"Early B not isolated");gate_check();completed_cases++;
        cold(25);request(0,32'h03000000,5);wait_aw();accept_aw();for(integer i=0;i<3;i++)write_word(i);
        m_axi_bvalid=1;m_axi_bid=0;m_axi_bresp=0;write_word(3);do begin step();end while(!bf);m_axi_bvalid=0;
        finish_reply(0);if(quarantined||busy)$fatal(1,"Same lastW early valid B falsely Q");completed_cases++;
        for(integer id=26;id<=29;id++)begin
            cold(id);request(0,32'h03000000,5);wait_aw();
            if(id>=27)begin accept_aw();for(integer i=0;i<(id==27?2:4);i++)write_word(i);end
            if(id==29)begin response(0,0);wait_reply(0);repeat(9)step();end
            normal(id,1,1,0,0,32'h01008000,32'h02008000);
        end
        for(integer id=30;id<=33;id++)begin
            cold(id);c_req_valid=1;c_addr[0]=32'h03000000;c_data[0]=payload(0,5);
            case(id)
                30:c_data[0][317]=1'bx;
                31:c_addr[0][21]=1'bz;
                32:c_req_valid[1]=1'bx;
                33:c_req_valid[0]=1'bz;
            endcase
            repeat(8)begin step();if(c_req_ready!=0||m_axi_awvalid||c_rsp_valid!=0)$fatal(1,"Unknown request fabricated transaction");end
            if(!local_quarantined||fault_reason!=1)$fatal(1,"Four-state request not isolated");gate_check();completed_cases++;
        end
        cold(34);c_data[1]='x;request(0,32'h03000000,5);wait_aw();accept_aw();for(integer i=0;i<4;i++)write_word(i);response(0,0);finish_reply(0);
        if(quarantined||busy)$fatal(1,"Unused payload poisoned selected request");completed_cases++;
        cold(35);enable=0;c_req_valid=1;c_addr[0]=32'h03000000;c_data[0]='x;
        repeat(8)begin step();if(quarantined||c_req_ready!=0||m_axi_awvalid)$fatal(1,"Disabled request selected");end
        enable=1;repeat(8)step();if(!local_quarantined||fault_reason!=1)$fatal(1,"Enabled unknown request not isolated");gate_check();completed_cases++;
        if(completed_cases!=35)$fatal(1,"Missing write scenario");
        finished=1;$fclose(fd);$fclose(memory_fd);fd=0;result_fd=$fopen({run_dir,"/write-result.json"},"w");
        $fwrite(result_fd,"{\"finished\":true,\"cases\":%0d,\"cycles\":%0d,\"requests\":%0d,\"replies\":%0d,\"physical_aw\":%0d,\"physical_w\":%0d,\"physical_b\":%0d}\n",completed_cases,cycle,requests,replies,aws,words,bs);
        $fclose(result_fd);$finish;
    end
endmodule
