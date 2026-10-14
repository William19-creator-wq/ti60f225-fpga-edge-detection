`timescale 1ns/1ps
module tb_stats_fit;
    tb_stats_core #(.CHECK_FIT(1)) bench();
    wire finished=bench.finished;
endmodule
