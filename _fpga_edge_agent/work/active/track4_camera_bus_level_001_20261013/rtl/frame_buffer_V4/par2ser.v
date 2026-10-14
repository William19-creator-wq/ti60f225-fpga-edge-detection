

module par2ser #(
    parameter I_DATA_WIDTH = 512,
    parameter O_DATA_WIDTH = 24

)(
    input clk,
    input rst_n,

    input                       frame_period,
    input                       rd_fifo_rdvalid,
    input [I_DATA_WIDTH-1:0]    rd_fifo_rddata ,
    input                       rd_fifo_rdempty,
    output reg                  rd_fifo_rden = 'd0,

    output reg                  tx_fifo_valid = 'd0,
    input                       wr_fifo_full,
    output [O_DATA_WIDTH-1:0] tx_fifo_wrdata
);

reg frame_period_r0 = 1'b0;
reg frame_period_r1 = 1'b0;
reg [4:0] pre_state = 'd0;
reg [128-1:0] rx_data = 'd0;
always @( posedge clk or negedge rst_n )
begin
    if( !rst_n ) begin
        frame_period_r0 <= 1'b0;
        frame_period_r1 <= 1'b0;
    end else begin
        frame_period_r0 <= frame_period;
        frame_period_r1 <= frame_period_r0;
    end
end
wire frame_start_w = {frame_period_r0,frame_period} == 2'b01;
wire frame_start = {frame_period_r1,frame_period_r0} == 2'b01;
    
assign tx_fifo_wrdata = rx_data[I_DATA_WIDTH:I_DATA_WIDTH-O_DATA_WIDTH];
always @( posedge clk or negedge rst_n )
begin
    if( !rst_n ) begin
        
        pre_state <= 0;
        rd_fifo_rden <= 1'b0;
        tx_fifo_valid <= 1'b0;
    end else if(frame_start_w) begin
        pre_state <= 0;
        rd_fifo_rden <= 1'b0;
        tx_fifo_valid <= 1'b0;
    end else begin
        rd_fifo_rden <= 1'b0;
        tx_fifo_valid <= 1'b0;
        case( pre_state )
        5'd0 : begin
           if( frame_start) 
            pre_state <= pre_state + 1'b1;
        end
        5'd1 : if( ~rd_fifo_rdempty ) begin
                pre_state <= pre_state + 1'b1;
                rd_fifo_rden <= 1'b1;
        end
        5'd2 : begin
            pre_state <= 5'd3;
        end
        5'd3 : begin
            if( ~wr_fifo_full ) begin
                rx_data <= rd_fifo_rddata;//data 1
                tx_fifo_valid <= 1'b1;
                pre_state <= pre_state + 1'b1;
            end
        end
        5'd4 : begin
            if( ~wr_fifo_full ) begin
                tx_fifo_valid <= 1'b1;
                rx_data <= rx_data << O_DATA_WIDTH  ; //data2 
                pre_state <= pre_state + 1'b1 ;
            end 
        end
        5'd5 :
           begin
            if( ~wr_fifo_full && ~rd_fifo_rdempty ) begin
                rx_data <= rx_data << O_DATA_WIDTH  ;
                tx_fifo_valid <= 1'b1;
                pre_state <= pre_state + 1'b1 ;
                rd_fifo_rden <= 1'b1;
            end
           end
           
        5'd6 :
           begin
            if( ~wr_fifo_full ) begin
                rx_data <= rx_data << O_DATA_WIDTH  ;
                tx_fifo_valid <= 1'b1;
                pre_state <= 3 ;
            end 
           end
        default:;
        endcase

    end          

end





endmodule
