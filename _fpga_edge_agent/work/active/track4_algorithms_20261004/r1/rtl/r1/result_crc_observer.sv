// R1-REQ03 / R1-OP02：一次只处理一份完整160bit记录；CRC不作数值oracle。
module result_crc_observer (
    input wire clk,rst,job_start,accept_records,
    input wire out_valid,output wire out_ready,
    input wire [15:0] out_y_filtered,input wire [1:0] out_edge,
    input wire [10:0] out_x_even,out_y,input wire out_sof,out_eol,out_eof,
    input wire [31:0] out_epoch,out_frame_id,out_config_id,
    input wire status_valid,output wire status_ready,input wire [2:0] status_code,
    input wire [31:0] status_epoch,status_frame_id,status_config_id,
    input wire [20:0] status_in_pairs,status_out_pairs,
    input wire terminal_accepted_good,
    output reg [20:0] data_pairs,
    output reg terminal_crc_done,terminal_good,
    output reg last_result_valid,output reg [31:0] last_crc,
    output reg [2:0] last_status,
    output reg [31:0] last_epoch,last_frame_id,last_config_id,
    output reg [20:0] last_in_pairs,last_out_pairs,last_data_pairs,
    output reg last_good
);
    reg busy,held_terminal,held_good;
    reg [159:0] record_hold;
    reg [7:0] record_bit_index;
    reg [31:0] crc_state;
    wire feedback=crc_state[31]^record_hold[record_bit_index];
    wire [31:0] shifted_crc={crc_state[30:0],1'b0} ^ (feedback ? 32'h04c11db7 : 32'b0);
    assign out_ready=!rst && accept_records && !busy;
    assign status_ready=!rst && accept_records && !busy;
    always @(posedge clk) begin
        if(rst) begin
            busy<=0;held_terminal<=0;held_good<=0;record_hold<=0;record_bit_index<=0;
            crc_state<=32'hffffffff;data_pairs<=0;
            terminal_crc_done<=0;terminal_good<=0;
            last_result_valid<=0;last_crc<=0;last_status<=0;last_good<=0;
            last_epoch<=0;last_frame_id<=0;last_config_id<=0;
            last_in_pairs<=0;last_out_pairs<=0;last_data_pairs<=0;
        end else begin
            terminal_crc_done<=0;
            if(job_start) begin
                crc_state<=32'hffffffff;data_pairs<=0;busy<=0;
                held_terminal<=0;held_good<=0;record_bit_index<=0;
            end else if(busy) begin
                crc_state<=shifted_crc;
                if(record_bit_index==0) begin
                    busy<=0;
                    if(held_terminal) begin
                        last_crc<=shifted_crc^32'hffffffff;
                        last_status<=record_hold[2:0];
                        last_in_pairs<=record_hold[23:3];last_out_pairs<=record_hold[44:24];
                        last_epoch<=record_hold[76:45];last_frame_id<=record_hold[108:77];
                        last_config_id<=record_hold[140:109];last_data_pairs<=data_pairs;
                        last_good<=held_good;last_result_valid<=1;
                        terminal_good<=held_good;terminal_crc_done<=1;
                    end
                end else record_bit_index<=record_bit_index-8'd1;
            end else if(out_valid && out_ready) begin
                record_hold<={21'b0,out_eof,out_eol,out_sof,out_config_id,out_frame_id,out_epoch,
                              out_y,out_x_even,out_edge,out_y_filtered};
                record_bit_index<=8'd159;busy<=1;held_terminal<=0;held_good<=0;
                data_pairs<=data_pairs+21'd1;
            end else if(status_valid && status_ready) begin
                record_hold<={19'b0,status_config_id,status_frame_id,status_epoch,
                              status_out_pairs,status_in_pairs,status_code};
                record_bit_index<=8'd159;busy<=1;held_terminal<=1;
                held_good<=terminal_accepted_good;
            end
        end
    end
    // synthesis translate_off
    always @(posedge clk) if(!rst) begin
        if(out_valid && status_valid) $fatal(1,"FE FO/FS simultaneously valid");
        if(job_start && busy) $fatal(1,"New job before old CRC completion");
    end
    // synthesis translate_on
endmodule
