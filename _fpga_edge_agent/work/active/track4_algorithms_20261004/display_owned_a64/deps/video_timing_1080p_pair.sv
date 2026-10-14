// VP02：当前计数译码；一拍双像素，生产74.25MHz对应1920×1080@60Hz。
module video_timing_1080p_pair(
    input logic clk,rst,output logic de,hs,vs,frame_start,output logic [10:0] x_even,y
);
    logic [10:0] h_count,v_count;
    always_comb begin
        de=h_count<960 && v_count<1080;
        hs=h_count>=1004 && h_count<1026;vs=v_count>=1084 && v_count<1089;
        frame_start=h_count==0 && v_count==0;
        x_even=de?{h_count[9:0],1'b0}:11'd0;y=de?v_count:11'd0;
    end
    always_ff @(posedge clk) begin
        if(rst)begin h_count<=0;v_count<=0;end
        else if(h_count==1099)begin h_count<=0;v_count<=v_count==1124?11'd0:v_count+11'd1;end
        else h_count<=h_count+11'd1;
    end
endmodule
