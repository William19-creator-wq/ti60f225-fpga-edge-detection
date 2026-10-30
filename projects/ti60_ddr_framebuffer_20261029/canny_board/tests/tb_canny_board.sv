`timescale 1ns/1ps
module tb_canny_board;
    parameter integer W=32,H=16,CAPTURE_ONLY=0;
    // Several complete serial Canny jobs may be required: a configuration
    // update cannot replace the immutable job already in flight. Scale the
    // total budget with the frame, keeping all pixel/protocol assertions.
    localparam integer MAX_CYCLES=100000000+W*H*128;
    localparam integer N=W*H,S=((N*3+63)/64)*64,E=((N+63)/64)*64,C=((N+255)/256)*64,Q=((N+15)/16)*64;
    localparam integer TOTAL=2*S+3*E+C+3*Q+4096,HTOTAL=W==1920?1100:256;
    logic core_clk=0,video_clk=0,cold_reset_n=0,enable=1;
    always #5 core_clk=~core_clk;
    always #6.734 video_clk=~video_clk;
    logic video_vs=0,video_de=0,video_hs=0;logic [47:0] video_rgb=0;
    logic [2:0] mode=0,next_mode=0;
    logic [10:0] cfg_threshold=96;logic [1:0] cfg_filter=1;logic [31:0] cfg_config_id=1;
    wire out_vs,out_hs,out_de;wire [47:0] out_rgb;
    wire display_valid,quarantined;wire [10:0] display_threshold;wire [1:0] display_filter;
    wire [31:0] completed_jobs,failed_jobs,underflow_rows;
    logic b_awvalid=0,b_wvalid=0,b_wlast=0,b_arvalid=0;
    wire b_awready,b_wready,b_bvalid,b_arready,b_rvalid,b_rlast;
    wire [3:0] b_bid,b_rid;wire [1:0] b_bresp,b_rresp;
    wire [127:0] b_rdata;
    logic [127:0] b_wdata=128'h0123456789abcdef_0123456789abcdef;
    integer baseline_writes=0,baseline_reads=0;
    wire m_awvalid,m_awready,m_wvalid,m_wready,m_wlast,m_bvalid,m_bready,m_arvalid,m_arready,m_rvalid,m_rready,m_rlast;
    wire [31:0] m_awaddr,m_araddr;wire [3:0] m_awid,m_arid,m_bid,m_rid;
    wire [7:0] m_awlen,m_arlen;wire [2:0] m_awsize,m_arsize,m_awprot,m_arprot;
    wire [1:0] m_awburst,m_arburst,m_bresp,m_rresp;wire [3:0] m_awcache,m_arcache;
    wire m_awlock,m_arlock;wire [127:0] m_wdata,m_rdata;wire [15:0] m_wstrb;
    canny_board_system #(.W(W),.H(H)) dut(
        .core_clk,.video_clk,.cold_reset_n,.enable,.video_vs,.video_de,.video_rgb,
        .scan_vs(video_vs),.scan_hs(video_hs),.scan_de(video_de),.scan_rgb(video_rgb),.mode,
        .cfg_threshold,.cfg_filter,.cfg_config_id,.out_vs,.out_hs,.out_de,.out_rgb,
        .display_valid,.display_threshold,.display_filter,.quarantined,.completed_jobs,.failed_jobs,.underflow_rows,
        .b_awvalid,.b_awready,.b_awaddr(32'h1000),.b_awid(4'd2),.b_awlen(8'd127),.b_awsize(3'd4),.b_awburst(2'd1),.b_awcache(4'd3),.b_awprot(3'd0),.b_awlock(1'b0),
        .b_wvalid,.b_wready,.b_wdata,.b_wstrb(16'hffff),.b_wlast,.b_bvalid,.b_bready(1'b1),.b_bid,.b_bresp,
        .b_arvalid,.b_arready,.b_araddr(32'h1000),.b_arid(4'd2),.b_arlen(8'd127),.b_arsize(3'd4),.b_arburst(2'd1),.b_arcache(4'd3),.b_arprot(3'd0),.b_arlock(1'b0),.b_rvalid,.b_rdata,.b_rlast,.b_rready(1'b1),.b_rid,.b_rresp,
        .m_awvalid,.m_awready,.m_awaddr,.m_awid,.m_awlen,.m_awsize,.m_awburst,.m_awcache,.m_awprot,.m_awlock,
        .m_wvalid,.m_wready,.m_wdata,.m_wstrb,.m_wlast,.m_bvalid,.m_bready,.m_bid,.m_bresp,
        .m_arvalid,.m_arready,.m_araddr,.m_arid,.m_arlen,.m_arsize,.m_arburst,.m_arcache,.m_arprot,.m_arlock,
        .m_rvalid,.m_rready,.m_rdata,.m_rid,.m_rresp,.m_rlast);
    logic [7:0] memory[0:TOTAL-1];logic gold0[0:N-1],gold1[0:N-1];
    function automatic integer address_index(input logic [31:0] addr);
        if(addr>=32'h1000&&addr<32'h2000)return TOTAL-4096+addr-32'h1000;
        if(addr>=32'h04000000&&addr<32'h04000000+S)return addr-32'h04000000;
        if(addr>=32'h04800000&&addr<32'h04800000+S)return S+addr-32'h04800000;
        if(addr>=32'h06000000&&addr<32'h06000000+E)return 2*S+addr-32'h06000000;
        if(addr>=32'h06200000&&addr<32'h06200000+E)return 2*S+E+addr-32'h06200000;
        if(addr>=32'h06400000&&addr<32'h06400000+C)return 2*S+2*E+addr-32'h06400000;
        if(addr>=32'h06600000&&addr<32'h06600000+Q)return 2*S+2*E+C+addr-32'h06600000;
        if(addr>=32'h05000000&&addr<32'h05000000+Q)return 2*S+2*E+C+Q+addr-32'h05000000;
        if(addr>=32'h06e00000&&addr<32'h06e00000+E)return 2*S+2*E+C+2*Q+addr-32'h06e00000;
        if(addr>=32'h07000000&&addr<32'h07000000+Q)return 2*S+3*E+C+2*Q+addr-32'h07000000;
        $fatal(1,"Memory address outside grants %h",addr);return 0;
    endfunction
    function automatic [23:0] source_pixel(input integer x,input integer y);
        return x>=W/2?24'hdcdcdc:24'h101010;
    endfunction
    logic wr_live=0,rd_live=0,b_pending=0;
    logic [31:0] wr_addr,rd_addr;logic [3:0] wr_id,rd_id;
    integer wr_left,rd_left,cycle=0,aw_count=0,ar_count=0,w_count=0,r_count=0;
    logic awready_reg=0,wready_reg=0,arready_reg=0,bvalid_reg=0,rvalid_reg=0,rlast_reg=0;
    logic [127:0] rdata_reg=0;logic [3:0] bid_reg=0,rid_reg=0;logic [1:0] bresp_reg=0;
    logic injected_safe_error=0,inject_safe_enable=0,fail_this_write=0,r_consumed=0,b_consumed=0;
    assign m_awready=awready_reg;assign m_wready=wready_reg;assign m_arready=arready_reg;
    assign m_bvalid=bvalid_reg;assign m_bid=bid_reg;assign m_bresp=bresp_reg;
    assign m_rvalid=rvalid_reg;assign m_rdata=rdata_reg;assign m_rid=rid_reg;assign m_rresp=0;assign m_rlast=rlast_reg;
    always @(negedge core_clk)begin
        awready_reg=cold_reset_n&&!wr_live&&!b_pending&&cycle%5!=0;
        wready_reg=cold_reset_n&&wr_live&&cycle%7!=0;
        arready_reg=cold_reset_n&&!rd_live&&cycle%3!=0;
        if(!bvalid_reg||b_consumed)bvalid_reg=cold_reset_n&&b_pending&&cycle%4!=0;
        if(!rvalid_reg||r_consumed)begin
            rvalid_reg=cold_reset_n&&rd_live&&cycle%5!=0;
            if(rvalid_reg)begin
                for(integer lane=0;lane<16;lane++)rdata_reg[lane*8+:8]=memory[address_index(rd_addr+lane)];
                rid_reg=rd_id;rlast_reg=rd_left==1;
            end
        end
    end
    logic aw_held=0,ar_held=0,w_held=0;logic [56:0] saved_aw,saved_ar;logic [144:0] saved_w;
    always @(posedge core_clk)begin
        cycle++;r_consumed=m_rvalid&&m_rready;b_consumed=m_bvalid&&m_bready;
        if(cycle%10000000==0)$display("BOARD_PROGRESS cycle=%0d jobs=%0d failed=%0d worker=%0d handle=%0d threshold=%0d inputs=%0d classes=%0d outputs=%0d display_th=%0d edge96=%0d edge160=%0d overlay=%0d",
            cycle,completed_jobs,failed_jobs,dut.worker.state,dut.worker.handle,dut.worker.threshold,
            dut.worker.c_inputs,dut.worker.c_classes,dut.worker.c_outputs,display_threshold,threshold96_frames,threshold160_frames,overlay_frames);
        if(cycle>MAX_CYCLES)$fatal(1,"Board integration timeout completed=%0d failed=%0d q=%b worker=%0d inputs=%0d classes=%0d outputs=%0d edge96=%0d edge160=%0d overlay=%0d",
            completed_jobs,failed_jobs,quarantined,dut.worker.state,dut.worker.c_inputs,dut.worker.c_classes,dut.worker.c_outputs,threshold96_frames,threshold160_frames,overlay_frames);
        if(cold_reset_n)begin
            if(aw_held&&(!m_awvalid||saved_aw!=={m_awaddr,m_awid,m_awlen,m_awsize,m_awburst,m_awcache,m_awprot,m_awlock}))$fatal(1,"AW changed while held");
            if(ar_held&&(!m_arvalid||saved_ar!=={m_araddr,m_arid,m_arlen,m_arsize,m_arburst,m_arcache,m_arprot,m_arlock}))$fatal(1,"AR changed while held");
            if(w_held&&(!m_wvalid||saved_w!=={m_wdata,m_wstrb,m_wlast}))$fatal(1,"W changed while held");
            aw_held=m_awvalid&&!m_awready;ar_held=m_arvalid&&!m_arready;w_held=m_wvalid&&!m_wready;
            saved_aw={m_awaddr,m_awid,m_awlen,m_awsize,m_awburst,m_awcache,m_awprot,m_awlock};
            saved_ar={m_araddr,m_arid,m_arlen,m_arsize,m_arburst,m_arcache,m_arprot,m_arlock};saved_w={m_wdata,m_wstrb,m_wlast};
            if(quarantined)$fatal(1,"Unexpected quarantine worker=%b bridge=%b display=%b inner=%b/%0d outer=%b/%0d worker_state=%0d",dut.worker_q,dut.bridge_q,dut.display_q,dut.inner_q,dut.worker_share.fault_reason,dut.outer_q,dut.board_share.fault_reason,dut.worker.state);
            if(m_awvalid&&m_awready)begin
                if(wr_live||m_awsize!=4||m_awburst!=1||m_awaddr[3:0]||({1'b0,m_awaddr[11:0]}+((m_awlen+1)*16)>4096))$fatal(1,"Invalid AW grant");
                wr_live=1;wr_addr=m_awaddr;wr_left=m_awlen+1;wr_id=m_awid;aw_count++;
                fail_this_write=inject_safe_enable&&!injected_safe_error&&m_awaddr>=32'h06000000&&m_awaddr<32'h06400000;
                if(fail_this_write)injected_safe_error=1;
            end
            if(m_wvalid&&m_wready)begin
                if(!wr_live||m_wlast!=(wr_left==1))$fatal(1,"Invalid W ownership/LAST");
                for(integer lane=0;lane<16;lane++)if(m_wstrb[lane])memory[address_index(wr_addr+lane)]=m_wdata[lane*8+:8];
                wr_addr+=16;wr_left--;w_count++;
                if(wr_left==0)begin wr_live=0;b_pending=1;bid_reg=wr_id;bresp_reg=fail_this_write?2:0;end
            end
            if(m_bvalid&&m_bready)b_pending=0;
            if(m_arvalid&&m_arready)begin
                if(rd_live||m_arsize!=4||m_arburst!=1||m_araddr[3:0]||({1'b0,m_araddr[11:0]}+((m_arlen+1)*16)>4096))$fatal(1,"Invalid AR grant");
                rd_live=1;rd_addr=m_araddr;rd_left=m_arlen+1;rd_id=m_arid;ar_count++;
            end
            if(m_rvalid&&m_rready)begin
                if(!rd_live||m_rlast!=(rd_left==1))$fatal(1,"Invalid R ownership/LAST");
                rd_addr+=16;rd_left--;r_count++;if(rd_left==0)rd_live=0;
            end
        end
    end
    integer output_x=0,output_y=0,live_frames=0,edge_frames=0,overlay_frames=0,threshold96_frames=0,threshold160_frames=0;
    integer pixels_checked=0,mode_for_frame=0,threshold_for_frame=0,frame_pixels=0;
    logic output_vs_previous=0,check_frame=0;
    logic [23:0] expected;logic expected_edge;
    always @(negedge video_clk)begin
        if(cold_reset_n)begin
            if(out_vs&&!output_vs_previous)begin
                if(check_frame&&frame_pixels!=N)$fatal(1,"Wrong complete frame pixel count %0d",frame_pixels);
                output_x=0;output_y=0;frame_pixels=0;mode_for_frame=mode;threshold_for_frame=display_threshold;
                check_frame=mode<5||display_valid;
                if(check_frame&&mode<5)live_frames++;
                if(check_frame&&mode==5)begin edge_frames++;if(display_threshold==96)threshold96_frames++;if(display_threshold==160)threshold160_frames++;end
                if(check_frame&&mode==6)overlay_frames++;
            end
            output_vs_previous=out_vs;
            if(out_de)begin
                if(check_frame)begin
                    for(integer lane=0;lane<2;lane++)begin
                        expected_edge=threshold_for_frame==96?gold0[output_y*W+output_x+lane]:gold1[output_y*W+output_x+lane];
                        expected=source_pixel(output_x+lane,output_y);
                        if(mode_for_frame==5)expected={24{expected_edge}};
                        if(mode_for_frame==6&&expected_edge)expected=24'hff0000;
                        if(out_rgb[lane*24+:24]!==expected)$fatal(1,"Display mismatch mode=%0d th=%0d x=%0d y=%0d got=%h expected=%h completed=%0d underrun=%0d",mode_for_frame,threshold_for_frame,output_x+lane,output_y,out_rgb[lane*24+:24],expected,completed_jobs,underflow_rows);
                        pixels_checked++;
                    end
                    frame_pixels+=2;
                end
                if(output_x==W-2)begin output_x=0;output_y++;end else output_x+=2;
            end
        end
    end
    initial begin
        wait(cold_reset_n);
        forever begin
            repeat(500)@(negedge core_clk);b_awvalid=1;
            do @(posedge core_clk);while(!b_awready);
            @(negedge core_clk);b_awvalid=0;b_wvalid=1;
            for(integer beat=0;beat<128;beat++)begin
                b_wlast=beat==127;do @(posedge core_clk);while(!b_wready);
                @(negedge core_clk);
            end
            b_wvalid=0;b_wlast=0;wait(b_bvalid);
            if(b_bid!=2||b_bresp!=0)$fatal(1,"Original write response corrupted");
            @(negedge core_clk);baseline_writes++;
            b_arvalid=1;do @(posedge core_clk);while(!b_arready);
            @(negedge core_clk);b_arvalid=0;
            for(integer beat=0;beat<128;beat++)begin
                do @(posedge core_clk);while(!b_rvalid);
                if(b_rdata!==b_wdata||b_rlast!=(beat==127)||b_rid!=2||b_rresp!=0)$fatal(1,"Original-channel data corrupted");
                @(negedge core_clk);
            end
            baseline_reads++;
        end
    end
    initial begin
        for(integer i=0;i<TOTAL;i++)memory[i]=8'ha5;
        if(!CAPTURE_ONLY)begin $readmemh("gold-0.hex",gold0);$readmemh("gold-1.hex",gold1);end
        repeat(20)@(negedge core_clk);cold_reset_n=1;
        forever begin
            for(integer vy=0;vy<H+16;vy++)begin
                for(integer vx=0;vx<HTOTAL;vx++)begin
                    @(negedge video_clk);
                    if(vy==0&&vx==0)mode=next_mode;
                    video_vs=vy<2;video_hs=vx<5;video_de=vy>=8&&vy<H+8&&vx<W/2;
                    video_rgb={source_pixel(vx*2+1,vy-8),source_pixel(vx*2,vy-8)};
                end
            end
        end
    end
    initial begin
      if(CAPTURE_ONLY)begin
        wait(dut.worker.snapshot.done_valid);@(negedge core_clk);
        if(!dut.worker.snapshot.done_good||dut.worker.snapshot.captured_pairs!=N/2)$fatal(1,"Full snapshot failed, reason=%0d",dut.worker.snapshot.done_reason);
        for(integer pixel=0;pixel<N;pixel++)begin
            for(integer channel=0;channel<3;channel++)if(memory[pixel*3+channel]!=(pixel%W>=W/2?220:16))$fatal(1,"Full snapshot byte mismatch %0d",pixel);
        end
        if(baseline_reads==0||baseline_writes==0)$fatal(1,"No concurrent baseline traffic");
        $display("CANNY_CAPTURE_PASS W=%0d H=%0d pixels=%0d baseline_writes=%0d baseline_reads=%0d",W,H,N,baseline_writes,baseline_reads);$finish;
      end else begin
        wait(live_frames>=1);next_mode=5;
        wait(threshold96_frames>=2);
        @(negedge video_clk);cfg_threshold=160;cfg_filter=0;cfg_config_id=2;
        wait(threshold160_frames>=2);next_mode=6;
        wait(overlay_frames>=2);
        wait(dut.display_reader.current_recognition);
        if(dut.display_reader.current_target_mask!=0)$fatal(1,"Clipped step is not a complete shape");
        if(W!=1920)begin
            inject_safe_enable=1;wait(failed_jobs>=1);wait(completed_jobs>=4);
            if(!injected_safe_error)$fatal(1,"No safe-error recovery covered");
        end
        wait(out_vs&&!output_vs_previous);repeat(4)@(negedge video_clk);
        if(underflow_rows!=0)$fatal(1,"Display missed %0d rows",underflow_rows);
        if(baseline_reads==0||baseline_writes==0)$fatal(1,"No original-channel contention");
        $display("CANNY_BOARD_PASS W=%0d H=%0d jobs=%0d failed=%0d pixels=%0d AW=%0d W=%0d AR=%0d R=%0d baseline=%0d/%0d",W,H,completed_jobs,failed_jobs,pixels_checked,aw_count,w_count,ar_count,r_count,baseline_reads,baseline_writes);
        $finish;
      end
    end
endmodule
