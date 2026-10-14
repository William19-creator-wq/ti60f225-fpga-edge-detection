// R1-IF04 / OP03：clock enable显示CRC，不产生新分频时钟。
module r1_led_status #(parameter integer W=1920,parameter integer H=1080) (
    input wire clk,rst,last_result_valid,last_good,input wire [2:0] last_status,
    input wire [31:0] last_crc,input wire [20:0] last_in_pairs,last_out_pairs,last_data_pairs,
    output wire led0,led1
);
    localparam [20:0] N=(W/2)*H;
    reg [17:0] display_enable_count;
    reg [4:0] crc_display_index;
    assign led0=!rst && last_result_valid && last_good && last_status==0 &&
                 last_in_pairs==N && last_out_pairs==N && last_data_pairs==N;
    assign led1=!rst && last_result_valid && last_crc[crc_display_index];
    always @(posedge clk) begin
        if(rst) begin display_enable_count<=0;crc_display_index<=0;end
        else if(display_enable_count==18'd249999) begin
            display_enable_count<=0;crc_display_index<=crc_display_index+5'd1;
        end else display_enable_count<=display_enable_count+18'd1;
    end
endmodule
