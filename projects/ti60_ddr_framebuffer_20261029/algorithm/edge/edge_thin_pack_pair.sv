// THIN-M1：原v4.1字段原样携带，另附同中心幅值；不改变检出阈值。
module edge_thin_pack_pair #(parameter integer THRESHOLD_DROP=16) (
    input wire clk,rst,frame_start,data_flush,
    input wire in_valid,output wire in_ready,
    input wire [15:0] in_center_pair,input wire [1:0] in_seed_pair,
    input wire [21:0] in_gx_pair,in_gy_pair,in_l1_pair,
    input wire [10:0] threshold,in_x_even,in_y,input wire in_sof,in_eol,in_eof,
    output wire out_valid,input wire out_ready,output logic [47:0] out_pair,
    output wire [10:0] out_x_even,out_y,output wire out_sof,out_eol,out_eof,output wire empty
);
    logic present;
    logic [24:0] coordinate;
    localparam logic [10:0] DROP=THRESHOLD_DROP;
    wire [10:0] low_threshold=threshold>=DROP?threshold-DROP:11'd0;
    wire advance=!present||out_ready;
    function automatic [1:0] direction(input logic signed [10:0] gx,gy);
        logic [10:0] ax,ay;
        begin
            ax=gx<0?-gx:gx;ay=gy<0?-gy:gy;
            // 与v4.1完全相同的2:1量化；两倍<=2040，保留11位。
            if(gx==0&&gy==0)direction=0;
            else if((ay<<1)<ax)direction=0;
            else if((ax<<1)<ay)direction=2;
            else direction=(gx[10]==gy[10])?2'd1:2'd3;
        end
    endfunction
    assign in_ready=!rst&&advance;
    assign out_valid=!rst&&present;
    assign empty=!present;
    assign {out_eof,out_eol,out_sof,out_y,out_x_even}=coordinate;
    always_ff @(posedge clk)begin
        if(rst||frame_start||data_flush)present<=0;
        else if(advance)begin
            present<=in_valid;
            coordinate<={in_eof,in_eol,in_sof,in_y,in_x_even};
            for(integer lane=0;lane<2;lane=lane+1)
                out_pair[lane*24+:24]<={1'b0,in_l1_pair[lane*11+:11],in_seed_pair[lane],
                    (in_l1_pair[lane*11+:11]>low_threshold)&&
                        ((in_gx_pair[lane*11+:11]!=0)||(in_gy_pair[lane*11+:11]!=0)),
                    direction($signed(in_gx_pair[lane*11+:11]),$signed(in_gy_pair[lane*11+:11])),
                    in_center_pair[lane*8+:8]};
        end
    end
    // synthesis translate_off
    initial if(THRESHOLD_DROP!=16)$fatal(1,"THIN: only approved drop16");
    // synthesis translate_on
endmodule
