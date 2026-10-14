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

module `IP_MODULE_NAME(efx_fifo_ctl) # (
    parameter SYNC_CLK           = 1,
    parameter SYNC_STAGE         = 2,
    parameter MODE               = "STANDARD",
    parameter WR_DEPTH           = 512,
    parameter WADDR_WIDTH        = 9,
    parameter RADDR_WIDTH        = 9,
    parameter ASYM_WIDTH_RATIO   = 4,
    parameter RAM_MUX_RATIO      = 1,
    parameter PIPELINE_REG       = 1,
    parameter ALMOST_FLAG        = 1,
    parameter PROGRAMMABLE_FULL  = "NONE",
    parameter PROG_FULL_ASSERT   = 0,
    parameter PROG_FULL_NEGATE   = 0,
    parameter PROGRAMMABLE_EMPTY = "NONE",
    parameter PROG_EMPTY_ASSERT  = 0,
    parameter PROG_EMPTY_NEGATE  = 0,
    parameter OUTPUT_REG         = 0,
    parameter HANDSHAKE_FLAG     = 1, 
    parameter OVERFLOW_PROTECT   = 0,
    parameter UNDERFLOW_PROTECT  = 0
)(
    input   wire                   wr_rst,
    input   wire                   rd_rst,
    input   wire                   wclk,
    input   wire                   rclk,
    input   wire                   we,
    input   wire                   re,
    output  wire                   wr_full,
    output  reg                    wr_ack,
    output  wire                   wr_almost_full,
    output  wire                   rd_empty,
    output  wire                   rd_almost_empty,
    output  wire                   wr_prog_full,
    output  wire                   rd_prog_empty,
    output  wire                   wr_en_int,
    output  wire                   rd_en_int,
    output  wire [WADDR_WIDTH-1:0] waddr,
    output  wire [RADDR_WIDTH-1:0] raddr,
    output  wire [WADDR_WIDTH:0]   wr_datacount,
    output  wire [RADDR_WIDTH:0]   rd_datacount,
    output  wire                   rd_vld,
    output  reg                    wr_overflow,
    output  reg                    rd_underflow
);

reg  [WADDR_WIDTH:0] waddr_cntr;
reg  [WADDR_WIDTH:0] waddr_cntr_r;
reg  [RADDR_WIDTH:0] raddr_cntr;
reg                  rd_valid;

wire [WADDR_WIDTH:0] waddr_int;
wire [RADDR_WIDTH:0] raddr_int;
wire                 rd_empty_int;
wire [WADDR_WIDTH:0] wr_datacount_int;
wire [RADDR_WIDTH:0] rd_datacount_int;

assign waddr     = waddr_cntr[WADDR_WIDTH-1:0];
// NIC
wire [RADDR_WIDTH:0] ram_raddr;
assign raddr     = (MODE == "FWFT") ? ram_raddr[RADDR_WIDTH-1:0] : raddr_cntr[RADDR_WIDTH-1:0];
//assign raddr     = raddr_cntr[RADDR_WIDTH-1:0];
//assign wr_en_int = we & ~wr_full;
assign wr_en_int = OVERFLOW_PROTECT ? we & ~wr_full : we;

assign wr_datacount  = wr_datacount_int;
assign rd_datacount  = ASYM_WIDTH_RATIO == 4 && SYNC_CLK ? wr_datacount_int : rd_datacount_int;


generate
    if (MODE == "FWFT") begin    
        // NIC
        //assign rd_en_int     = (~rd_empty_int & rd_empty) | (re & ~rd_empty_int);
        //assign rd_empty      = rd_empty_fwft;

        assign rd_en_int     = 1'b1;
        //assign rd_empty      = rd_empty_int;
        
        //always @ (posedge rclk or posedge rd_rst) begin
        //    if (rd_rst) begin
        //        init_set <= 1'b1;
        //    end
        //    else if (~init_set & rd_empty) begin
        //        init_set <= 1'b1;            
        //    end
        //    else if (~rd_empty_int) begin
        //        init_set <= 1'b0;            
        //    end
        //    else if (rd_empty) begin
        //        init_set <= 1'b1;            
        //    end
        //end
        // NIC 
        //always @ (posedge rclk or posedge rd_rst) begin
        //    if (rd_rst) begin
        //        rd_empty_fwft <= 1'b1;
        //    end
        //    else if (rd_en_int) begin
        //        rd_empty_fwft <= 1'b0;            
        //    end
        //    else if (re) begin
        //        rd_empty_fwft <= 1'b1;            
        //    end
        //end          
        
        //if (FAMILY == "TRION") begin
        if (OUTPUT_REG) begin
            always @ (posedge rclk or posedge rd_rst) begin
                if (rd_rst) begin
                    rd_valid <= 1'b0;
                end
                else begin
                    rd_valid <= ~rd_empty;
                end
            end
            assign rd_vld = rd_valid;                
        end    
        else begin
            assign rd_vld = ~rd_empty;                
        end
        
        assign rd_empty = rd_empty_int;
    end
    else begin
        assign rd_en_int     = UNDERFLOW_PROTECT ? re & ~rd_empty_int : re;
        assign rd_empty      = rd_empty_int;
        
        if (OUTPUT_REG) begin
            reg rd_valid_r;
            always @ (posedge rclk or posedge rd_rst) begin
                if (rd_rst) begin
                    rd_valid_r <= 'h0;
                    rd_valid   <= 'h0;
                end
                else begin
                    {rd_valid,rd_valid_r} <= {rd_valid_r,rd_en_int};
                end
            end
            assign rd_vld = rd_valid;            
        end
        else begin
            always @ (posedge rclk or posedge rd_rst) begin
                if (rd_rst) begin
                    rd_valid  <= 'h0;
                end
                else begin
                    rd_valid <= rd_en_int;
                end
            end
            assign rd_vld = rd_valid;
        end
    end
    
    if (ALMOST_FLAG) begin
        assign wr_almost_full   = wr_datacount >= WR_DEPTH-1;
        assign rd_almost_empty  = rd_datacount <= 'd1;
    end
    else begin
        assign wr_almost_full   = 1'b0;
        assign rd_almost_empty  = 1'b0;        
    end
    
    if (PROGRAMMABLE_FULL == "STATIC_SINGLE") begin
        reg    wr_prog_full_int;
        assign wr_prog_full  = wr_datacount >= PROG_FULL_ASSERT;
        
        always @ (posedge wclk or posedge wr_rst) begin
            if (wr_rst) begin
                wr_prog_full_int  <= 1'b0;
            end
            else begin
                wr_prog_full_int  <= wr_prog_full;
            end
        end  
    end
    else if (PROGRAMMABLE_FULL == "STATIC_DUAL") begin
        reg    wr_prog_full_int;
        assign wr_prog_full  = wr_prog_full_int ? wr_datacount >= PROG_FULL_NEGATE : wr_datacount >= PROG_FULL_ASSERT;   

        always @ (posedge wclk or posedge wr_rst) begin
            if (wr_rst) begin
                wr_prog_full_int  <= 1'b0;
            end
            else begin
                wr_prog_full_int  <= wr_prog_full;
            end
        end              
    end
    else begin
        assign wr_prog_full  = 1'b0; 
    end
        
    if (PROGRAMMABLE_EMPTY == "STATIC_SINGLE") begin
        reg    rd_prog_empty_int;
        assign rd_prog_empty  = rd_datacount <= PROG_EMPTY_ASSERT;
            
        always @ (posedge rclk or posedge rd_rst) begin
            if (rd_rst) begin
                rd_prog_empty_int <= 1'b1;
            end
            else begin
                rd_prog_empty_int <= rd_prog_empty;
            end
        end
    end
    else if (PROGRAMMABLE_EMPTY == "STATIC_DUAL") begin
        reg    rd_prog_empty_int;
        assign rd_prog_empty = rd_prog_empty_int ? (rd_datacount <= PROG_EMPTY_NEGATE) : (rd_datacount <= PROG_EMPTY_ASSERT);
            
        always @ (posedge rclk or posedge rd_rst) begin
            if (rd_rst) begin
                rd_prog_empty_int <= 1'b1;
            end
            else begin
                rd_prog_empty_int <= rd_prog_empty;
            end
        end  
    end
    else begin
        assign rd_prog_empty  = 1'b0; 
    end
    
    if (HANDSHAKE_FLAG) begin
        always @ (posedge wclk or posedge wr_rst) begin
            if (wr_rst) begin
                wr_ack <= 1'b0;
            end
            else begin
                // NIC
                //wr_ack <= wr_en_int & ~wr_overflow;
                wr_ack <= OVERFLOW_PROTECT ? wr_en_int & ~wr_overflow : wr_en_int;
            end
        end
    end

    if (OVERFLOW_PROTECT) begin
        always @ (posedge wclk or posedge wr_rst) begin
            if (wr_rst) begin
                wr_overflow <= 1'b0;
            end
            else if (we && wr_full) begin
                wr_overflow <= 1'b1;
            end
            else begin
                wr_overflow <= 1'b0;            
            end
        end
    end
    else if (HANDSHAKE_FLAG) begin
        always @ (posedge wclk or posedge wr_rst) begin
            if (wr_rst) begin
                wr_overflow <= 1'b0;
            end
            else begin
                wr_overflow <= we && wr_full ? 1'b1 : wr_overflow;
            end
        end
    end

    if (UNDERFLOW_PROTECT) begin     
        always @ (posedge rclk or posedge rd_rst) begin
            if (rd_rst) begin
                rd_underflow <= 1'b0;
            end
            else if (re && rd_empty) begin
                rd_underflow <= 1'b1;
            end
            else begin
                rd_underflow <= 1'b0;            
            end
        end
    end
    else if (HANDSHAKE_FLAG) begin
        always @ (posedge rclk or posedge rd_rst) begin
            if (rd_rst) begin
                rd_underflow <= 1'b0;
            end
            else begin
                rd_underflow <= re && rd_empty ? 1'b1 : rd_underflow;
            end
        end
    end
    
    localparam RATIO_WIDTH = (RADDR_WIDTH >= WADDR_WIDTH)? RADDR_WIDTH - WADDR_WIDTH : WADDR_WIDTH - RADDR_WIDTH;
    
    if (ASYM_WIDTH_RATIO < 4) begin
        assign wr_full          = (waddr_cntr[WADDR_WIDTH]^raddr_int[RADDR_WIDTH]) & (waddr_cntr[WADDR_WIDTH-1:0] == raddr_int[RADDR_WIDTH-1:RATIO_WIDTH]);
        assign rd_empty_int     = waddr_int[WADDR_WIDTH:0] == raddr_cntr[RADDR_WIDTH:RATIO_WIDTH];
        assign wr_datacount_int = waddr_cntr - (raddr_int/RAM_MUX_RATIO);
        assign rd_datacount_int = (waddr_int*RAM_MUX_RATIO)-raddr_cntr;
    end
    // NIC
    else if (ASYM_WIDTH_RATIO == 4) begin
        assign wr_full          = (waddr_cntr[WADDR_WIDTH]^raddr_int[RADDR_WIDTH]) & (waddr_cntr[WADDR_WIDTH-1:0] == raddr_int[RADDR_WIDTH-1:0]);
        assign rd_empty_int     = waddr_int[WADDR_WIDTH:0] == raddr_cntr[RADDR_WIDTH:0];
        assign wr_datacount_int = waddr_cntr - raddr_int;
        assign rd_datacount_int = waddr_int - raddr_cntr;
    end
    else begin
        assign wr_full          = (waddr_cntr[WADDR_WIDTH]^raddr_int[RADDR_WIDTH]) & (waddr_cntr[WADDR_WIDTH-1:RATIO_WIDTH] == raddr_int[RADDR_WIDTH-1:0]);
        // NIC
        //assign rd_empty_int     = (waddr_int- raddr_cntr*RAM_MUX_RATIO) < RAM_MUX_RATIO;
        assign rd_empty_int     = waddr_int[WADDR_WIDTH:RATIO_WIDTH] == raddr_cntr[RADDR_WIDTH:0];
        assign wr_datacount_int = waddr_cntr - (raddr_int*RAM_MUX_RATIO);
        assign rd_datacount_int = (waddr_int/RAM_MUX_RATIO)-raddr_cntr;
    end
endgenerate

always @ (posedge wclk or posedge wr_rst) begin
    if (wr_rst) begin
        waddr_cntr   <= 'h0;
    end
    else if (wr_en_int) begin
        waddr_cntr   <= waddr_cntr + 1'b1;
    end
end

always @ (posedge wclk or posedge wr_rst) begin
    if (wr_rst) begin
        waddr_cntr_r  <= 'h0;
    end
    else begin
        waddr_cntr_r  <= waddr_cntr;
    end
end

always @ (posedge rclk or posedge rd_rst) begin
    if (rd_rst) begin
        raddr_cntr   <= 'h0;
    end
    // NIC
    //else if (rd_en_int) begin
    else begin
        //raddr_cntr   <= raddr_cntr + 1'b1;
        //raddr_cntr   <= raddr_cntr + (re & ~rd_empty_int);
        raddr_cntr   <= ram_raddr;
    end
end
// NIC
assign ram_raddr = raddr_cntr + (UNDERFLOW_PROTECT ? re & ~rd_empty_int : re);


generate
    if (SYNC_CLK) begin : sync_clk
       if (MODE == "FWFT") begin
          assign waddr_int = waddr_cntr_r;
          assign raddr_int        = raddr_cntr;
       end
       else begin
          assign waddr_int        = waddr_cntr;
          assign raddr_int        = raddr_cntr;
       end
    end
    else begin : async_clk
        reg  [RADDR_WIDTH:0] raddr_cntr_gry_r;
        reg  [WADDR_WIDTH:0] waddr_cntr_gry_r;
        
        wire [RADDR_WIDTH:0] raddr_cntr_gry;
        wire [RADDR_WIDTH:0] raddr_cntr_gry_sync;
        wire [RADDR_WIDTH:0] raddr_cntr_sync_g2b;
        wire [WADDR_WIDTH:0] waddr_cntr_gry;
        wire [WADDR_WIDTH:0] waddr_cntr_gry_sync;
        wire [WADDR_WIDTH:0] waddr_cntr_sync_g2b;

        if (PIPELINE_REG) begin
            reg  [RADDR_WIDTH:0] raddr_cntr_sync_g2b_r;    
            reg  [WADDR_WIDTH:0] waddr_cntr_sync_g2b_r;        
        
            assign waddr_int        = waddr_cntr_sync_g2b_r;
            assign raddr_int        = raddr_cntr_sync_g2b_r;
            
            always @ (posedge wclk or posedge wr_rst) begin
                if (wr_rst) begin
                    raddr_cntr_sync_g2b_r <= 'h0;
                end
                else begin
                    raddr_cntr_sync_g2b_r <= raddr_cntr_sync_g2b;
                end
            end
            
            always @ (posedge rclk or posedge rd_rst) begin
                if (rd_rst) begin
                    waddr_cntr_sync_g2b_r <= 'h0;
                end
                else begin
                    waddr_cntr_sync_g2b_r <= waddr_cntr_sync_g2b;
                end
            end
        end
        else begin
            assign waddr_int        = waddr_cntr_sync_g2b;
            assign raddr_int        = raddr_cntr_sync_g2b;        
        end
      
        always @ (posedge rclk or posedge rd_rst) begin
            if (rd_rst) begin
                raddr_cntr_gry_r <= 'h0;
            end
            else begin
                raddr_cntr_gry_r <= raddr_cntr_gry;
            end
        end
        `IP_MODULE_NAME(efx_fifo_bin2gray) # (.WIDTH(RADDR_WIDTH+1)                                                               ) xrd2wr_bin2gray    (.bin_i(raddr_cntr), .gray_o(raddr_cntr_gry));
        `IP_MODULE_NAME(efx_asyncreg)      # (.ASYNC_STAGE(SYNC_STAGE), .WIDTH (RADDR_WIDTH+1), .ACTIVE_LOW(0), .OFF_ASSERTION (1)) xrd2wr_addr_sync   (.clk(wclk), .reset_n(wr_rst), .d_i(raddr_cntr_gry_r), .d_o(raddr_cntr_gry_sync));
        `IP_MODULE_NAME(efx_fifo_gray2bin) # (.WIDTH(RADDR_WIDTH+1)                                                               ) xrd2wr_gray2bin    (.gray_i(raddr_cntr_gry_sync), .bin_o(raddr_cntr_sync_g2b));
        
        always @ (posedge wclk or posedge wr_rst) begin
            if (wr_rst) begin
                waddr_cntr_gry_r <= 'h0;
            end
            else begin
                waddr_cntr_gry_r <= waddr_cntr_gry;
            end
        end        
        `IP_MODULE_NAME(efx_fifo_bin2gray) # (.WIDTH(WADDR_WIDTH+1)                                                               ) wr2rd_bin2gray  (.bin_i(waddr_cntr), .gray_o(waddr_cntr_gry));
        `IP_MODULE_NAME(efx_asyncreg)      # (.ASYNC_STAGE(SYNC_STAGE), .WIDTH (WADDR_WIDTH+1), .ACTIVE_LOW(0), .OFF_ASSERTION (1)) wr2rd_addr_sync (.clk(rclk), .reset_n(rd_rst), .d_i(waddr_cntr_gry_r), .d_o(waddr_cntr_gry_sync));
        `IP_MODULE_NAME(efx_fifo_gray2bin) # (.WIDTH(WADDR_WIDTH+1)                                                               ) wr2rd_gray2bin  (.gray_i(waddr_cntr_gry_sync), .bin_o(waddr_cntr_sync_g2b));        

    end
endgenerate
endmodule
