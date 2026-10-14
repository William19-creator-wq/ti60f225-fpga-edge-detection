// VP03：当前请求由上游当拍提供，模式帧头锁定，RGB与控制一起寄存一拍。
module video_compare_presenter(
    input logic clk,rst,input logic in_de,in_hs,in_vs,in_frame_start,
    input logic [10:0] in_x_even,in_y,input logic [1:0] cfg_mode,
    input logic [47:0] rgb_pair,input logic [15:0] gray_pair,input logic [1:0] edge_pair,
    output logic [10:0] source_x0,source_x1,source_y,
    output logic [47:0] out_rgb_pair,output logic out_de,out_hs,out_vs,out_frame_start
);
    logic [1:0] frame_mode,effective_mode;
    logic [47:0] rendered;
    function automatic [23:0] bar_color(input logic [10:0] x);
        if(x<240)bar_color=24'hffffff;else if(x<480)bar_color=24'hffff00;
        else if(x<720)bar_color=24'h00ffff;else if(x<960)bar_color=24'h00ff00;
        else if(x<1200)bar_color=24'hff00ff;else if(x<1440)bar_color=24'hff0000;
        else if(x<1680)bar_color=24'h0000ff;else bar_color=24'h000000;
    endfunction
    always_comb begin
        effective_mode=in_frame_start?cfg_mode:frame_mode;
        source_x0=0;source_x1=0;source_y=0;rendered=0;
        if(in_de)begin
            source_y=in_y;
            if(effective_mode==2)begin
                source_x0=(in_x_even<960?in_x_even:in_x_even-11'd960)<<1;
                source_x1=source_x0+11'd2;
            end else begin source_x0=in_x_even;source_x1=in_x_even+11'd1;end
            case(effective_mode)
                0:rendered={bar_color(in_x_even+11'd1),bar_color(in_x_even)};
                1:rendered={{3{gray_pair[15:8]}},{3{gray_pair[7:0]}}};
                2:if(in_x_even<960)rendered={{3{gray_pair[15:8]}},{3{gray_pair[7:0]}}};
                  else rendered={edge_pair[1]?24'hffffff:24'h000000,edge_pair[0]?24'hffffff:24'h000000};
                3:rendered={edge_pair[1]?24'hff0000:rgb_pair[47:24],edge_pair[0]?24'hff0000:rgb_pair[23:0]};
            endcase
        end
    end
    always_ff @(posedge clk)begin
        if(rst)begin frame_mode<=0;out_rgb_pair<=0;out_de<=0;out_hs<=0;out_vs<=0;out_frame_start<=0;end
        else begin
            if(in_frame_start)frame_mode<=cfg_mode;
            out_rgb_pair<=rendered;out_de<=in_de;out_hs<=in_hs;out_vs<=in_vs;out_frame_start<=in_frame_start;
        end
    end
endmodule
