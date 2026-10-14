`define IP_MODULE_NAME(name) name
`timescale 1ns/1ps
// CPREQ01..05：真实官方TX/RX数字模型与外部端口观察；不读保护主体。
module tb_csi_model_probe #(parameter integer PROBE_WIDTH=20,PROBE_HEIGHT=8,PROBE_FRAMES=2);
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

    always @(posedge pixel_clk)begin
        logic [127:0] observed;logic [7:0] unknown_mask;
        pixel_cycles++;
        if(reset_n)begin
            if(tx_valid)begin
                if($isunknown(tx_data) || generator_x>=PROBE_WIDTH/4 || generator_y>=PROBE_HEIGHT)$fatal(1,"CSI source coordinate/value");
                expected.push_back(tx_data[39:0]);
                for(integer b=0;b<8;b++)$fwrite(source_file,"%c",tx_data[b*8+:8]);
                input_records<=input_records+1;
            end
            if(video_reset_n && !source_done && input_records==TARGET && old_generator_vs && !generator_vs)begin source_done<=1;source_end=$realtime;end
            old_generator_vs<=generator_vs;
            if(rx_valid)begin
                if($isunknown(rx_data[39:0]) || expected.size()==0)$fatal(1,"CSI unaccepted/unknown pixel output records=%0d",output_records);
                front=expected.pop_front();if(rx_data[39:0]!==front)$fatal(1,"CSI RAW10 loopback mismatch group=%0d got=%h want=%h",output_records,rx_data[39:0],front);
                if(output_records==0)begin first_rx=$realtime;$display("CSI first valid data=%h PPC=%h DT=%h WC=%h HS=%b VS=%b",rx_data,rx_ppc,rx_dt,rx_wc,rx_hs,rx_vs);end
                unknown_mask={$isunknown(rx_vs),$isunknown(rx_hs),$isunknown(rx_short),$isunknown(rx_wc),$isunknown(rx_vc),$isunknown(rx_dt),$isunknown(rx_ppc),$isunknown(rx_data[63:40])};
                observed={($isunknown(rx_short)?16'd0:rx_short),($isunknown(rx_wc)?16'd0:rx_wc),
                    6'd0,($isunknown(rx_vs)?1'b0:rx_vs),($isunknown(rx_hs)?1'b0:rx_hs),
                    ($isunknown(rx_vc)?8'd0:{6'd0,rx_vc}),($isunknown(rx_dt)?8'd0:{2'd0,rx_dt}),
                    ($isunknown(rx_ppc)?8'd0:{4'd0,rx_ppc}),($isunknown(rx_data[63:40])?24'd0:rx_data[63:40]),rx_data[39:0]};
                for(integer b=0;b<16;b++)$fwrite(result_file,"%c",observed[b*8+:8]);$fwrite(unknown_file,"%c",unknown_mask);
                output_records++;last_rx=$realtime;
            end
            if({rx_debug,rx_short,rx_wc,rx_dt,rx_vcx,rx_vc,rx_hs,rx_vs,rx_valid,rx_ppc}!==last_pixel_meta)begin
                $fwrite(edge_file,"P,%0.3f,%b,%b,%b,%h,%h,%h,%h,%h,%h\n",$realtime,rx_hs,rx_vs,rx_valid,rx_ppc,rx_dt,rx_vc,rx_wc,rx_short,rx_debug);
                last_pixel_meta={rx_debug,rx_short,rx_wc,rx_dt,rx_vcx,rx_vc,rx_hs,rx_vs,rx_valid,rx_ppc};
            end
        end
    end
    always @(posedge byte_clk)if(reset_n)begin
        if({rx_debug,rx_short,rx_wc,rx_dt,rx_vcx,rx_vc,rx_hs,rx_vs,rx_valid,rx_ppc}!==last_byte_meta)begin
            $fwrite(edge_file,"B,%0.3f,%b,%b,%b,%h,%h,%h,%h,%h,%h\n",$realtime,rx_hs,rx_vs,rx_valid,rx_ppc,rx_dt,rx_vc,rx_wc,rx_short,rx_debug);
            last_byte_meta={rx_debug,rx_short,rx_wc,rx_dt,rx_vcx,rx_vc,rx_hs,rx_vs,rx_valid,rx_ppc};
        end
        if(hs_enabled!=0)begin
            $fwrite(lane_file,"%c%c%c%c%c%c%c%c%c",lane0,lane1,lane2,lane3,{4'd0,hs_enabled},{4'd0,lp_dp},{4'd0,lp_dn},{7'd0,lp_cp},{7'd0,lp_cn});
        end
    end
    always @(posedge control_clk)if(reset_n && {rx_debug,rx_irq,tx_irq}!==last_control_meta)begin
        $fwrite(edge_file,"C,%0.3f,%h,%b,%b\n",$realtime,rx_debug,rx_irq,tx_irq);last_control_meta={rx_debug,rx_irq,tx_irq};
    end
    initial begin
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        if(PROBE_WIDTH<4 || PROBE_WIDTH%4!=0 || PROBE_WIDTH>1920 || PROBE_HEIGHT<2 || PROBE_HEIGHT>1080 || PROBE_FRAMES<1 || PROBE_FRAMES>4)$fatal(1,"CSI probe geometry");
        source_file=$fopen("tx-source.bin","wb");result_file=$fopen("rx-observed.bin","wb");unknown_file=$fopen("rx-unknown.bin","wb");
        edge_file=$fopen("port-edges.csv","w");lane_file=$fopen("tx-lanes.bin","wb");
        repeat(20)@(negedge control_clk);reset_n=1;
        #300000;@(negedge pixel_clk);video_reset_n=1;
        wait(source_done);repeat(50000)@(negedge pixel_clk);
        if(input_records!=TARGET || output_records!=TARGET || expected.size()!=0)$fatal(1,"CSI frame incomplete tx=%0d rx=%0d target=%0d",input_records,output_records,TARGET);
        $fclose(source_file);$fclose(result_file);$fclose(unknown_file);$fclose(edge_file);$fclose(lane_file);
        metrics_file=$fopen("protocol-metrics.json","w");
        $fwrite(metrics_file,"{\"finished\":true,\"width\":%0d,\"height\":%0d,\"frames\":%0d,\"input_records\":%0d,\"output_records\":%0d,\"pixel_cycles\":%0d,\"first_rx_ns\":%0.3f,\"last_rx_ns\":%0.3f,\"source_end_ns\":%0.3f,\"reception_closure_proven\":false}\n",PROBE_WIDTH,PROBE_HEIGHT,PROBE_FRAMES,input_records,output_records,pixel_cycles,first_rx,last_rx,source_end);$fclose(metrics_file);
        finished=1;$display("CSI vendor RAW10 probe PASS %0dx%0d frames=%0d groups=%0d",PROBE_WIDTH,PROBE_HEIGHT,PROBE_FRAMES,output_records);$finish;
    end
    initial begin
        #((PROBE_WIDTH/4+1034)*(PROBE_HEIGHT+4)*(PROBE_FRAMES+1)*20+2000000);
        if(!finished)$fatal(1,"CSI watchdog tx=%0d rx=%0d source_done=%b",input_records,output_records,source_done);
    end
endmodule
