// OBS-IF10：同core clock enable滚动CRC，每250000沿换一个bit，无派生clk。
module r2_led_status (
    input wire clk,rst,last_result_valid,last_complete_ok,input wire [31:0] last_crc,
    output wire led0,led1
);
    logic [17:0] enable_count;logic [4:0] crc_bit;
    assign led0=!rst&&last_result_valid&&last_complete_ok;
    assign led1=!rst&&last_result_valid&&last_crc[crc_bit];
    always_ff @(posedge clk) begin
        if(rst||!last_result_valid) begin enable_count<=0;crc_bit<=0;end
        else if(enable_count==18'd249999) begin enable_count<=0;crc_bit<=crc_bit+5'd1;end
        else enable_count<=enable_count+18'd1;
    end
endmodule
