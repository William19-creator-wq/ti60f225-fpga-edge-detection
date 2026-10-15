// DK01…04 / CAM-OP04：10bit保留到最后一次舍入；父端提供reflect101窗口。
module raw10_debayer_pair(
    input logic clk,rst,in_valid,output wire in_ready,
    input logic [179:0] in_window_pair,input logic [10:0] in_x_even,in_y,
    input logic [1:0] in_phase,input logic [2:0] in_markers,input logic [63:0] in_job_id,
    output wire out_valid,input logic out_ready,
    output logic [47:0] out_rgb_pair,output logic [10:0] out_x_even,out_y,
    output logic [2:0] out_markers,output logic [63:0] out_job_id
);
    logic valid_slot;
    logic [47:0] calculated_rgb;
    logic [9:0] samples[0:1][0:8];
    logic [12:0] channel_sum[0:1][0:2]; // 0R,1G,2B
    logic [1:0] divisor_log2[0:1][0:2];
    logic site_x[0:1],site_y[0:1];

    function automatic [7:0] quantize(input logic [12:0] sum,input logic [1:0] log2d);
        logic [12:0] rounded;
        logic [8:0] value;
        begin
            case(log2d)
                0:begin rounded=sum+13'd2;value=rounded[10:2];end
                1:begin rounded=sum+13'd4;value=rounded[11:3];end
                default:begin rounded=sum+13'd8;value=rounded[12:4];end
            endcase
            quantize = value > 9'd255 ? 8'd255 : value[7:0];
        end
    endfunction

    assign in_ready=!rst && (!valid_slot || out_ready);
    assign out_valid=!rst && valid_slot;
    always_comb begin
        calculated_rgb=0;
        for(integer lane=0;lane<2;lane++)begin
            for(integer sample=0;sample<9;sample++)samples[lane][sample]=in_window_pair[lane*90+sample*10+:10];
            site_x[lane]=in_x_even[0]^in_phase[0]^(lane==1);
            site_y[lane]=in_y[0]^in_phase[1];
            for(integer channel=0;channel<3;channel++)begin channel_sum[lane][channel]=0;divisor_log2[lane][channel]=0;end
            if(site_x[lane]==site_y[lane])begin
                channel_sum[lane][1]={3'd0,samples[lane][1]}+{3'd0,samples[lane][3]}+
                    {3'd0,samples[lane][5]}+{3'd0,samples[lane][7]};divisor_log2[lane][1]=2;
                channel_sum[lane][site_x[lane]?2:0]={3'd0,samples[lane][4]};
                channel_sum[lane][site_x[lane]?0:2]={3'd0,samples[lane][0]}+{3'd0,samples[lane][2]}+
                    {3'd0,samples[lane][6]}+{3'd0,samples[lane][8]};
                divisor_log2[lane][site_x[lane]?0:2]=2;
            end else begin
                channel_sum[lane][1]={3'd0,samples[lane][4]};
                channel_sum[lane][site_y[lane]?2:0]={3'd0,samples[lane][3]}+{3'd0,samples[lane][5]};
                channel_sum[lane][site_y[lane]?0:2]={3'd0,samples[lane][1]}+{3'd0,samples[lane][7]};
                divisor_log2[lane][0]=1;divisor_log2[lane][2]=1;
            end
            for(integer channel=0;channel<3;channel++)
                calculated_rgb[lane*24+(2-channel)*8+:8]=quantize(channel_sum[lane][channel],divisor_log2[lane][channel]);
        end
    end
    always_ff @(posedge clk)begin
        if(rst)valid_slot<=0;
        else if(in_ready)begin
            valid_slot<=in_valid;
            if(in_valid)begin
                out_rgb_pair<=calculated_rgb;out_x_even<=in_x_even;out_y<=in_y;
                out_markers<=in_markers;out_job_id<=in_job_id;
            end
        end
    end
endmodule
