/////////////////////////////////////////////////////////////////////////////
//           _____       
//          / _______    Copyright (C) 2013-2021 Efinix Inc. All rights reserved.
//         / /       \   
//        / /  ..    /   simple_dual_port_ram_fifo.v
//       / / .'     /    
//    __/ /.'      /     Description:
//   __   \       /      EFX FIFO
//  /_/ /\ \_____/ /     
// ____/  \_______/      
//
// *******************************
// Revisions:
//
// *******************************

module `IP_MODULE_NAME(efx_fifo_top) # (
    parameter FAMILY             = "TRION",       // New Param
    parameter SYNC_CLK           = 0,
    parameter BYPASS_RESET_SYNC  = 0,             // New Param
    parameter SYNC_STAGE         = 2,             // New Param
    parameter MODE               = "STANDARD",
    parameter DEPTH              = 512,           // Reverted (Equivalent to WDATA_DEPTH) 
    parameter DATA_WIDTH         = 32,            // Reverted (Equivalent to WDATA_WIDTH)
    parameter PIPELINE_REG       = 1,             // Reverted (By default is ON)
    parameter OPTIONAL_FLAGS     = 1,             // Reverted
    parameter OUTPUT_REG         = 0,
    parameter PROGRAMMABLE_FULL  = "STATIC_DUAL", // Set to "NONE" if not require this feature
    parameter PROG_FULL_ASSERT   = 27,
    parameter PROG_FULL_NEGATE   = 23,
    parameter PROGRAMMABLE_EMPTY = "STATIC_DUAL", // Set to "NONE" if not require this feature
    parameter PROG_EMPTY_ASSERT  = 5,
    parameter PROG_EMPTY_NEGATE  = 7,
    parameter ALMOST_FLAG        = OPTIONAL_FLAGS,
    parameter HANDSHAKE_FLAG     = OPTIONAL_FLAGS,
    parameter ASYM_WIDTH_RATIO   = 4,
    parameter WADDR_WIDTH        = depth2width(DEPTH),
    parameter RDATA_WIDTH        = rdwidthcompute(ASYM_WIDTH_RATIO,DATA_WIDTH),
    parameter RD_DEPTH           = rddepthcompute(DEPTH,DATA_WIDTH,RDATA_WIDTH),
    parameter RADDR_WIDTH        = depth2width(RD_DEPTH),
    parameter ENDIANESS		      = 0,
    parameter OVERFLOW_PROTECT   = 1,
    parameter UNDERFLOW_PROTECT  = 1,
    parameter RAM_STYLE          = "block_ram"

)(
    input  wire                   a_rst_i,
    input  wire                   a_wr_rst_i,
    input  wire                   a_rd_rst_i,
    input  wire                   clk_i,
    input  wire                   wr_clk_i,
    input  wire                   rd_clk_i,
    input  wire                   wr_en_i,
    input  wire                   rd_en_i,
    input  wire [DATA_WIDTH-1:0]  wdata,
    output wire                   almost_full_o,
    output wire                   prog_full_o,
    output wire                   full_o,
    output wire                   overflow_o,
    output wire                   wr_ack_o,
    output wire [WADDR_WIDTH :0]  datacount_o,
    output wire [WADDR_WIDTH :0]  wr_datacount_o,
    output wire                   empty_o,
    output wire                   almost_empty_o,
    output wire                   prog_empty_o,
    output wire                   underflow_o,
    output wire                   rd_valid_o,
    output wire [RDATA_WIDTH-1:0] rdata,
    output wire [RADDR_WIDTH :0]  rd_datacount_o,
    output wire                   rst_busy
); 

localparam WR_DEPTH      = DEPTH;
localparam WDATA_WIDTH   = DATA_WIDTH;
localparam RAM_MUX_RATIO = (RDATA_WIDTH <= WDATA_WIDTH/32) ? 32 :
                           (RDATA_WIDTH <= WDATA_WIDTH/16) ? 16 :
                           (RDATA_WIDTH <= WDATA_WIDTH/8)  ? 8  :
                           (RDATA_WIDTH <= WDATA_WIDTH/4)  ? 4  :
                           (RDATA_WIDTH <= WDATA_WIDTH/2)  ? 2  :
                           (RDATA_WIDTH <= WDATA_WIDTH)    ? 1  :
                           (RDATA_WIDTH <= WDATA_WIDTH*2)  ? 2  :
                           (RDATA_WIDTH <= WDATA_WIDTH*4)  ? 4  :
                           (RDATA_WIDTH <= WDATA_WIDTH*8)  ? 8  :
                           (RDATA_WIDTH <= WDATA_WIDTH*16) ? 16 : 32;           

wire                   wr_rst_int;
wire                   rd_rst_int;
wire                   wr_en_int;
wire                   rd_en_int;
wire [WADDR_WIDTH-1:0] waddr;
wire [RADDR_WIDTH-1:0] raddr;
wire                   wr_clk_int;
wire                   rd_clk_int;
wire [WADDR_WIDTH :0]  wr_datacount_int;
wire [RADDR_WIDTH :0]  rd_datacount_int;

generate
    if (ASYM_WIDTH_RATIO == 4) begin
        if (SYNC_CLK) begin
            assign wr_clk_int     = clk_i;    
            assign rd_clk_int     = clk_i;
            assign datacount_o    = wr_datacount_int;
            assign wr_datacount_o = {(WADDR_WIDTH+1){1'b0}};
            assign rd_datacount_o = {(RADDR_WIDTH+1){1'b0}};
        end
        else begin
            assign wr_clk_int     = wr_clk_i;    
            assign rd_clk_int     = rd_clk_i;
            assign datacount_o    = {(WADDR_WIDTH+1){1'b0}};
            assign wr_datacount_o = wr_datacount_int;
            assign rd_datacount_o = rd_datacount_int;
        end
    end
    else begin
        assign datacount_o    = {(WADDR_WIDTH+1){1'b0}};
        assign wr_datacount_o = wr_datacount_int;
        assign rd_datacount_o = rd_datacount_int;
        if (SYNC_CLK) begin
            assign wr_clk_int     = clk_i;    
            assign rd_clk_int     = clk_i;
        end
        else begin
            assign wr_clk_int     = wr_clk_i;    
            assign rd_clk_int     = rd_clk_i;
        end
    end    

    if (!SYNC_CLK) begin
        //(* async_reg = "true" *) reg [1:0] wr_rst;
        //(* async_reg = "true" *) reg [1:0] rd_rst;
        //
        //always @ (posedge wr_clk_int or posedge a_rst_i) begin
        //    if (a_rst_i) 
        //        wr_rst <= 2'b11;
        //    else 
        //        wr_rst <= {wr_rst[0],1'b0};            
        //end
        //
        //always @ (posedge rd_clk_int or posedge a_rst_i) begin
        //    if (a_rst_i) 
        //        rd_rst <= 2'b11;
        //    else 
        //        rd_rst <= {rd_rst[0],1'b0};            
        //end
        

        if (BYPASS_RESET_SYNC) begin
            assign wr_rst_int = a_wr_rst_i;
            assign rd_rst_int = a_rd_rst_i; 
            assign rst_busy   = 1'b0;
        end 
        else begin
            `IP_MODULE_NAME(efx_resetsync) #(
               .ACTIVE_LOW (0)
            ) efx_resetsync_wr_rst (
               .clk   (wr_clk_int),
               .reset (a_rst_i),
               .d_o   (wr_rst_int)
            );

            `IP_MODULE_NAME(efx_resetsync) #(
               .ACTIVE_LOW (0)
            ) efx_resetsync_rd_rst (
               .clk   (rd_clk_int),
               .reset (a_rst_i),
               .d_o   (rd_rst_int)
            );
            assign rst_busy   = wr_rst_int | rd_rst_int;
        end

    end
    else begin
        //(* async_reg = "true" *) reg [1:0] a_rst;
        //
        //always @ (posedge clk_i or posedge a_rst_i) begin
        //    if (a_rst_i) 
        //        a_rst <= 2'b11;
        //    else 
        //        a_rst <= {a_rst[0],1'b0};            
        //end
        wire   a_rst;

        `IP_MODULE_NAME(efx_resetsync) #(
           .ACTIVE_LOW (0)
        ) efx_resetsync_a_rst (
           .clk   (clk_i),
           .reset (a_rst_i),
           .d_o   (a_rst)
        );

        if (BYPASS_RESET_SYNC) begin
            assign wr_rst_int = a_rst_i;
            assign rd_rst_int = a_rst_i;
            assign rst_busy   = 1'b0;
        end
        else begin
            assign wr_rst_int = a_rst;
            assign rd_rst_int = a_rst;   
            assign rst_busy   = wr_rst_int | rd_rst_int;
        end
    end 
endgenerate

`IP_MODULE_NAME(efx_fifo_ram) # (
    .FAMILY        (FAMILY),
    .WR_DEPTH      (WR_DEPTH),
    .RD_DEPTH      (RD_DEPTH),
    .WDATA_WIDTH   (WDATA_WIDTH),
    .RDATA_WIDTH   (RDATA_WIDTH),
    .WADDR_WIDTH   (WADDR_WIDTH),
    .RADDR_WIDTH   (RADDR_WIDTH),
    .OUTPUT_REG    (OUTPUT_REG),
    .RAM_MUX_RATIO (RAM_MUX_RATIO),
    .ENDIANESS	    (ENDIANESS),
    .RAM_STYLE     (RAM_STYLE)
) xefx_fifo_ram (
    .wdata (wdata), 
    .waddr (waddr),
    .raddr (raddr), 
    .we    (wr_en_int), 
    .re    (rd_en_int),
    .wclk  (wr_clk_int),
    .rclk  (rd_clk_int),
    .rdata (rdata)
);

`IP_MODULE_NAME(efx_fifo_ctl) # (
    .SYNC_CLK           (SYNC_CLK),
    .SYNC_STAGE         (SYNC_STAGE),
    .MODE               (MODE),
    .WR_DEPTH           (WR_DEPTH),
    .WADDR_WIDTH        (WADDR_WIDTH),
    .RADDR_WIDTH        (RADDR_WIDTH),
    .ASYM_WIDTH_RATIO   (ASYM_WIDTH_RATIO),
    .RAM_MUX_RATIO      (RAM_MUX_RATIO),
    .PIPELINE_REG       (PIPELINE_REG),
    .ALMOST_FLAG        (ALMOST_FLAG),
    .PROGRAMMABLE_FULL  (PROGRAMMABLE_FULL),
    .PROG_FULL_ASSERT   (PROG_FULL_ASSERT),
    .PROG_FULL_NEGATE   (PROG_FULL_NEGATE),
    .PROGRAMMABLE_EMPTY (PROGRAMMABLE_EMPTY),
    .PROG_EMPTY_ASSERT  (PROG_EMPTY_ASSERT),
    .PROG_EMPTY_NEGATE  (PROG_EMPTY_NEGATE),
    .OUTPUT_REG         (OUTPUT_REG),
    .HANDSHAKE_FLAG     (HANDSHAKE_FLAG),
    .OVERFLOW_PROTECT   (OVERFLOW_PROTECT),
    .UNDERFLOW_PROTECT  (UNDERFLOW_PROTECT)
) xefx_fifo_ctl (
    .wr_rst          (wr_rst_int),
    .rd_rst          (rd_rst_int),
    .wclk            (wr_clk_int),
    .rclk            (rd_clk_int),
    .we              (wr_en_i),
    .re              (rd_en_i),
    .wr_full         (full_o),
    .wr_ack          (wr_ack_o),
    .rd_empty        (empty_o),
    .wr_almost_full  (almost_full_o),
    .rd_almost_empty (almost_empty_o),
    .wr_prog_full    (prog_full_o),
    .rd_prog_empty   (prog_empty_o),
    .wr_en_int       (wr_en_int),
    .rd_en_int       (rd_en_int),
    .waddr           (waddr),
    .raddr           (raddr),
    .wr_datacount    (wr_datacount_int),
    .rd_datacount    (rd_datacount_int),
    .rd_vld          (rd_valid_o),
    .wr_overflow     (overflow_o),
    .rd_underflow    (underflow_o)
);

function integer depth2width;
input [31:0] depth;
begin : fnDepth2Width
    if (depth > 1) begin
        depth = depth - 1;
        for (depth2width=0; depth>0; depth2width = depth2width + 1)
            depth = depth>>1;
        end
    else
       depth2width = 0;
end
endfunction 

function integer width2depth;
input [31:0] width;
begin : fnWidth2Depth
    width2depth = width**2;
end
endfunction

function integer rdwidthcompute;
input [31:0] asym_option;
input [31:0] wr_width;
begin : RdWidthCompute
    rdwidthcompute = (asym_option==0)? wr_width/16 :
                     (asym_option==1)? wr_width/8  :
                     (asym_option==2)? wr_width/4  :
                     (asym_option==3)? wr_width/2  :
                     (asym_option==4)? wr_width/1  :
                     (asym_option==5)? wr_width*2  :
                     (asym_option==6)? wr_width*4  :
                     (asym_option==7)? wr_width*8  :
                     (asym_option==8)? wr_width*16 : wr_width/1;
end
endfunction

function integer rddepthcompute;
input [31:0] wr_depth;
input [31:0] wr_width;
input [31:0] rd_width;
begin : RdDepthCompute
    rddepthcompute = (wr_depth * wr_width) / rd_width;
end
endfunction

endmodule
