module vin_original(input wire [39:0] w_mipi_rx_data,output wire [31:0] din);
assign din={w_mipi_rx_data[39:32],w_mipi_rx_data[29:22],w_mipi_rx_data[19:12],w_mipi_rx_data[9:2]};
endmodule
module vin_corrected(input wire [39:0] w_mipi_rx_data,output wire [31:0] din);
assign din={w_mipi_rx_data[19:12],w_mipi_rx_data[9:2],w_mipi_rx_data[39:32],w_mipi_rx_data[29:22]};
endmodule
