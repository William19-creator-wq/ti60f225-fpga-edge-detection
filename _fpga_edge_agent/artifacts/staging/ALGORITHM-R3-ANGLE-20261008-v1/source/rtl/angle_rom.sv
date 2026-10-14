// AN04：两块20×512同步只读ROM；复位只清core的预约，不写/清ROM。
module angle_rom #(
    parameter string BOUNDARY_FILE="C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/r3_angle/rtl/angle_boundary.mem",
    parameter string COEFFICIENT_FILE="C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/r3_angle/rtl/projection_coeff.mem"
)(input logic clk,re,bank,input logic [8:0] address,output logic [19:0] data);
    logic [19:0] boundary[0:511],coefficient[0:511];
    logic [19:0] boundary_output,coefficient_output;
    initial begin $readmemh(BOUNDARY_FILE,boundary);$readmemh(COEFFICIENT_FILE,coefficient);end
    always_ff @(posedge clk)if(re && !bank)boundary_output<=boundary[address];
    always_ff @(posedge clk)if(re && bank)coefficient_output<=coefficient[address];
    always_comb data=bank?coefficient_output:boundary_output;
endmodule
