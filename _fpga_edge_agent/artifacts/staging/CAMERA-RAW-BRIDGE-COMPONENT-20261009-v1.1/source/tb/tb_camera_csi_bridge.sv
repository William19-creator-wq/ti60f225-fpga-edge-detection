`define IP_MODULE_NAME(name) name
`timescale 1ns/1ps
// CPREQ01..05：真实官方TX/RX数字模型与外部端口观察；不读保护主体。
module tb_camera_csi_bridge #(parameter integer PROBE_WIDTH=20,PROBE_HEIGHT=8,PROBE_FRAMES=1);
    localparam integer GROUPS=PROBE_WIDTH*PROBE_HEIGHT/4,TARGET=GROUPS*PROBE_FRAMES;
    logic control_clk=0,byte_clk=0,pixel_clk=0,reset_n=0,video_reset_n=0,finished=0;
    always #5 control_clk=~control_clk;
    always #7.143 byte_clk=~byte_clk;
    always #10 pixel_clk=~pixel_clk;
    wire [13:0] generator_x;wire [11:0] generator_y;
    wire generator_valid,generator_hs,generator_vs,generator_de;
    logic source_done=0,old_generator_vs=0;
    integer input_records=0,output_records=0,pixel_cycles=0;
    wire tx_valid=video_reset_n && generator_valid && input_records<TARGET;
    wire tx_hs=video_reset_n && !source_done && generator_hs;
    wire tx_vs=video_reset_n && !source_done && generator_vs;
    wire [63:0] tx_data;
    wire [3:0] lp_dp,lp_dn,hs_enabled;
    wire lp_cp,lp_cn;wire [7:0] lane0,lane1,lane2,lane3;
    wire rx_hs,rx_vs,rx_valid,rx_irq,tx_irq;
    wire [63:0] rx_data;wire [3:0] rx_ppc;wire [5:0] rx_dt;
    wire [1:0] rx_vc,rx_vcx;wire [15:0] rx_wc,rx_short;
    wire [31:0] rx_debug,tx_debug;
    integer source_file,result_file,unknown_file,edge_file,lane_file,metrics_file;
    logic [39:0] expected[$],front;
    logic [80:0] last_pixel_meta='1,last_byte_meta='1;
    logic [33:0] last_control_meta='1;
    realtime first_rx=-1,last_rx=-1,source_end=-1;
    function automatic logic [39:0] raw_group(input integer gx,input integer gy,input integer frame);
        logic [39:0] value;integer px;
        begin
            for(integer j=0;j<4;j++)begin px=gx*4+j;value[j*10+:10]=10'(px*37+gy*53+(px^gy)*7+frame*101);end
            return value;
        end
    endfunction
    assign tx_data={24'ha5c300^24'(generator_y*17+input_records/GROUPS),raw_group(int'(generator_x),int'(generator_y),input_records/GROUPS)};
    vga_gen #(.H_SyncPulse(5),.H_BackPorch(5),.H_ActivePix(PROBE_WIDTH),.H_FrontPorch(1024),
        .V_SyncPulse(1),.V_BackPorch(1),.V_ActivePix(PROBE_HEIGHT),.V_FrontPorch(2),.P_Cnt(1),.PixelPerClock(4),.PW(14)) video(
        .in_pclk(pixel_clk),.in_rstn(video_reset_n),.out_x(generator_x),.out_y(generator_y),
        .out_valid(generator_valid),.out_de(generator_de),.out_hs(generator_hs),.out_vs(generator_vs));
    efx_csi2_tx #(.HS_BYTECLK_MHZ(70),.CLOCK_FREQ_MHZ(100),.NUM_DATA_LANE(4),
        .DPHY_CLOCK_MODE("Discontinuous"),.FRAME_MODE("GENERIC"),.PACK_TYPE(15),.PIXEL_FIFO_DEPTH(2048)) tx(
        .clk(control_clk),.reset_n(reset_n),.clk_byte_HS(byte_clk),.reset_byte_HS_n(reset_n),.clk_pixel(pixel_clk),.reset_pixel_n(reset_n),
        .Tx_LP_CLK_P(lp_cp),.Tx_LP_CLK_N(lp_cn),.Tx_HS_C(),.Tx_HS_enable_C(),.Tx_LP_CLK_P_OE(),.Tx_LP_CLK_N_OE(),
        .Tx_LP_D_P(lp_dp),.Tx_LP_D_N(lp_dn),.Tx_LP_D_P_OE(),.Tx_LP_D_N_OE(),.Tx_HS_enable_D(hs_enabled),
        .Tx_HS_D_0(lane0),.Tx_HS_D_1(lane1),.Tx_HS_D_2(lane2),.Tx_HS_D_3(lane3),.Tx_HS_D_4(),.Tx_HS_D_5(),.Tx_HS_D_6(),.Tx_HS_D_7(),
        .axi_clk(control_clk),.axi_reset_n(reset_n),.axi_awaddr(6'd0),.axi_awvalid(1'b0),.axi_awready(),.axi_wdata(32'd0),.axi_wvalid(1'b0),.axi_wready(),
        .axi_bvalid(),.axi_bready(1'b1),.axi_araddr(6'd0),.axi_arvalid(1'b0),.axi_arready(),.axi_rdata(),.axi_rvalid(),.axi_rready(1'b1),
        .hsync_vc0(tx_hs),.hsync_vc1(1'b0),.hsync_vc2(1'b0),.hsync_vc3(1'b0),.hsync_vc4(1'b0),.hsync_vc5(1'b0),.hsync_vc6(1'b0),.hsync_vc7(1'b0),
        .hsync_vc8(1'b0),.hsync_vc9(1'b0),.hsync_vc10(1'b0),.hsync_vc11(1'b0),.hsync_vc12(1'b0),.hsync_vc13(1'b0),.hsync_vc14(1'b0),.hsync_vc15(1'b0),
        .vsync_vc0(tx_vs),.vsync_vc1(1'b0),.vsync_vc2(1'b0),.vsync_vc3(1'b0),.vsync_vc4(1'b0),.vsync_vc5(1'b0),.vsync_vc6(1'b0),.vsync_vc7(1'b0),
        .vsync_vc8(1'b0),.vsync_vc9(1'b0),.vsync_vc10(1'b0),.vsync_vc11(1'b0),.vsync_vc12(1'b0),.vsync_vc13(1'b0),.vsync_vc14(1'b0),.vsync_vc15(1'b0),
        .datatype(6'h2b),.pixel_data(tx_data),.pixel_data_valid(tx_valid),.haddr(16'(PROBE_WIDTH)),.line_num(16'd0),.frame_num(16'h1337),
        .mipi_debug_in(32'd0),.mipi_debug_out(tx_debug),.irq(tx_irq));
    efx_csi2_rx #(.HS_BYTECLK_MHZ(70),.CLOCK_FREQ_MHZ(100),.NUM_DATA_LANE(4),.tD_TERM_EN_NS(25),
        .DPHY_CLOCK_MODE("Discontinuous"),.FRAME_MODE("GENERIC"),.PACK_TYPE(15),.PIXEL_FIFO_DEPTH(1024),.AREGISTER(8),.ASYNC_STAGE(2)) rx(
        .clk(control_clk),.reset_n(reset_n),.clk_byte_HS(byte_clk),.reset_byte_HS_n(reset_n),.clk_pixel(pixel_clk),.reset_pixel_n(reset_n),
        .Rx_LP_CLK_P(lp_cp),.Rx_LP_CLK_N(lp_cn),.Rx_HS_enable_C(),.LVDS_termen_C(),.Rx_LP_D_P(lp_dp),.Rx_LP_D_N(lp_dn),
        .Rx_HS_D_0(lane0),.Rx_HS_D_1(lane1),.Rx_HS_D_2(lane2),.Rx_HS_D_3(lane3),.Rx_HS_D_4(8'd0),.Rx_HS_D_5(8'd0),.Rx_HS_D_6(8'd0),.Rx_HS_D_7(8'd0),
        .Rx_HS_enable_D(),.LVDS_termen_D(),.fifo_rd_enable(),.fifo_rd_empty(4'b0000),.DLY_enable_D(),.DLY_inc_D(),.u_dly_enable_D(4'd0),.u_dly_inc_D(4'd0),
        .axi_clk(control_clk),.axi_reset_n(reset_n),.axi_awaddr(6'd0),.axi_awvalid(1'b0),.axi_awready(),.axi_wdata(32'd0),.axi_wvalid(1'b0),.axi_wready(),
        .axi_bvalid(),.axi_bready(1'b1),.axi_araddr(6'd0),.axi_arvalid(1'b0),.axi_arready(),.axi_rdata(),.axi_rvalid(),.axi_rready(1'b1),
        .hsync_vc0(rx_hs),.hsync_vc1(),.hsync_vc2(),.hsync_vc3(),.hsync_vc4(),.hsync_vc5(),.hsync_vc6(),.hsync_vc7(),
        .hsync_vc8(),.hsync_vc9(),.hsync_vc10(),.hsync_vc11(),.hsync_vc12(),.hsync_vc13(),.hsync_vc14(),.hsync_vc15(),
        .vsync_vc0(rx_vs),.vsync_vc1(),.vsync_vc2(),.vsync_vc3(),.vsync_vc4(),.vsync_vc5(),.vsync_vc6(),.vsync_vc7(),
        .vsync_vc8(),.vsync_vc9(),.vsync_vc10(),.vsync_vc11(),.vsync_vc12(),.vsync_vc13(),.vsync_vc14(),.vsync_vc15(),
        .vc(rx_vc),.vcx(rx_vcx),.word_count(rx_wc),.shortpkt_data_field(rx_short),.datatype(rx_dt),.pixel_per_clk(rx_ppc),.pixel_data(rx_data),.pixel_data_valid(rx_valid),
        .mipi_debug_in(32'd0),.mipi_debug_out(rx_debug),.irq(rx_irq));


    logic job_valid=0;wire job_ready;logic [63:0] job_handle=64'h6000000000000001;
    logic [194:0] job_origin={64'd1,32'd1,32'h17,64'h100003,3'd0};
    wire out_valid;logic out_ready=1;wire [19:0] raw_pair;wire [10:0] out_x_even,out_y;
    wire [2:0] out_markers;wire out_bad;wire [63:0] out_handle;
    wire done_valid;logic done_ready=0;wire [63:0] done_handle;wire [194:0] done_origin;
    wire [1:0] done_outcome;wire [7:0] done_reason;
    wire [21:0] done_accepted_groups,done_delivered_pairs,done_discarded_pairs;
    wire done_shape_complete,done_drained,done_groups_known,reception_verified,quarantined;wire [2:0] phase;
    integer pair_index=0,core_cycles=0,pair_file,cases_file;
    logic [31:0] ready_random=32'h68c4a319;
    logic held=0;logic [109:0] held_body;
    wire [109:0] pair_body={out_handle,out_bad,out_markers,out_y,out_x_even,raw_pair};
    camera_raw_bridge #(.IMAGE_WIDTH(PROBE_WIDTH),.IMAGE_HEIGHT(PROBE_HEIGHT)) bridge(
        .core_clk(control_clk),.pixel_clk,.cold_reset_n(reset_n),.job_valid,.job_ready,.job_handle,.job_origin,
        .cancel_valid(1'b0),.cancel_handle(64'd0),.discard_valid(1'b0),.discard_handle(64'd0),
        .pixel_data(rx_data),.pixel_valid(rx_valid),.hs(rx_hs),.vs(rx_vs),.rx_fault(1'b0),
        .pixel_per_clock(rx_ppc),.datatype(rx_dt),.virtual_channel(rx_vc),.word_count(rx_wc),
        .out_valid,.out_ready,.raw_pair,.out_x_even,.out_y,.out_markers,.out_bad,.out_handle,
        .done_valid,.done_ready,.done_handle,.done_origin,.done_outcome,.done_reason,
        .done_accepted_groups,.done_delivered_pairs,.done_discarded_pairs,.done_shape_complete,.done_drained,.done_groups_known,
        .reception_verified,.quarantined,.phase);
    always @(negedge control_clk)begin
        ready_random={ready_random[30:0],ready_random[31]^ready_random[21]^ready_random[1]^ready_random[0]};
        out_ready=ready_random[3:0]!=0;
    end
    always @(posedge pixel_clk)if(reset_n)begin
        if(tx_valid)input_records<=input_records+1;
        if(video_reset_n && !source_done && input_records==TARGET && old_generator_vs && !generator_vs)begin source_done<=1;source_end=$realtime;end
        old_generator_vs<=generator_vs;
        if(rx_valid)begin
            if(rx_ppc!=4 || rx_dt!=6'h2b || rx_vc!=0 || rx_wc!=PROBE_WIDTH*5/4 || !rx_hs || !rx_vs || $isunknown(rx_data[39:0]))$fatal(1,"Actual CSI metadata incompatible");
            if(output_records==0)first_rx=$realtime;last_rx=$realtime;output_records++;
        end
    end
    always @(posedge control_clk)begin
        integer x,y;logic [19:0] expected_pair;logic [2:0] markers;logic [127:0] record;
        core_cycles++;
        if(!reset_n)held=0;
        else begin
            if(held && (!out_valid || pair_body!==held_body))$fatal(1,"Coupled held pair changed");
            held=out_valid&&!out_ready;held_body=pair_body;
            if(out_valid&&out_ready)begin
                x=(pair_index%(PROBE_WIDTH/2))*2;y=pair_index/(PROBE_WIDTH/2);
                expected_pair={10'(37*(x+1)+53*y+7*((x+1)^y)),10'(37*x+53*y+7*(x^y))};
                markers={y==PROBE_HEIGHT-1 && x==PROBE_WIDTH-2,x==PROBE_WIDTH-2,pair_index==0};
                if(raw_pair!==expected_pair || out_x_even!=x || out_y!=y || out_markers!==markers || out_handle!=job_handle || out_bad)
                    $fatal(1,"Coupled CSI pair mismatch index=%0d",pair_index);
                record={out_handle,5'd0,out_x_even,5'd0,out_y,4'd0,out_bad,out_markers,4'd0,raw_pair};
                for(integer b=0;b<16;b++)$fwrite(pair_file,"%c",record[b*8+:8]);pair_index++;
            end
            if(reception_verified || quarantined)$fatal(1,"Coupled receiver unexpected promotion/failure");
        end
    end
    initial begin
        integer metrics;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        pair_file=$fopen("pairs.bin","wb");cases_file=$fopen("cases.csv","w");
        $fwrite(cases_file,"case,handle,seed,groups,delivered,discarded,outcome,reason,shape,drained,known\n");
        repeat(20)@(negedge control_clk);reset_n=1;
        #300000;@(negedge control_clk);wait(job_ready);job_valid=1;
        @(negedge control_clk);job_valid=0;repeat(15)@(negedge pixel_clk);video_reset_n=1;
        wait(done_valid);@(negedge control_clk);
        if(done_outcome!=0 || done_reason!=0 || !done_shape_complete || !done_drained || !done_groups_known ||
            done_handle!=job_handle || done_origin!==job_origin || done_accepted_groups!=GROUPS ||
            done_delivered_pairs!=GROUPS*2 || done_discarded_pairs!=0 || pair_index!=GROUPS*2 || output_records!=GROUPS)
            $fatal(1,"Coupled local terminal mismatch outcome=%0d reason=%0d groups=%0d",done_outcome,done_reason,done_accepted_groups);
        repeat(15)@(negedge control_clk);if(!done_valid)$fatal(1,"Coupled terminal not held");
        $fwrite(cases_file,"1,%h,0,%0d,%0d,0,0,0,1,1,1\n",job_handle,done_accepted_groups,done_delivered_pairs);
        done_ready=1;@(negedge control_clk);done_ready=0;wait(job_ready);
        $fclose(pair_file);$fclose(cases_file);
        metrics=$fopen("protocol-metrics.json","w");
        $fwrite(metrics,"{\"finished\":true,\"width\":%0d,\"height\":%0d,\"cases\":1,\"pairs\":%0d,\"core_cycles\":%0d,\"input_records\":%0d,\"output_records\":%0d,\"first_rx_ns\":%0.3f,\"last_rx_ns\":%0.3f,\"reception_closure_proven\":false}\n",PROBE_WIDTH,PROBE_HEIGHT,pair_index,core_cycles,input_records,output_records,first_rx,last_rx);$fclose(metrics);
        finished=1;$display("Actual CSI to RAW bridge PASS %0dx%0d pairs=%0d",PROBE_WIDTH,PROBE_HEIGHT,pair_index);$finish;
    end
    initial begin
        #((PROBE_WIDTH/4+1034)*(PROBE_HEIGHT+4)*40+2000000);
        if(!finished)$fatal(1,"Coupled CSI watchdog phase=%0d rx=%0d pairs=%0d",phase,output_records,pair_index);
    end
endmodule
