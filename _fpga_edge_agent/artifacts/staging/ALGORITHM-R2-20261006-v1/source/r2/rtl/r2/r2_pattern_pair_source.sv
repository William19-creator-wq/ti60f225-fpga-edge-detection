// OBS-IF08 / OBS-OP01 / SRC：公式源，不保存图像，不另存accepted pair计数。
module r2_pattern_pair_source #(parameter integer W=1920,H=1080) (
    input wire clk,rst,job_start,input wire [141:0] cj,
    input wire [1:0] pattern,input wire fault,source_stop,
    output wire out_valid,input wire out_ready,output logic [73:0] out_fp,
    output wire source_last_fire
);
    logic active,source_terminated;
    logic [9:0] q;logic [10:0] row;
    logic [1:0] locked_pattern;logic locked_fault;
    wire [10:0] x_even={q,1'b0};
    wire pair_fire=out_valid&&out_ready;
    assign out_valid=!rst&&active&&!source_terminated;
    assign source_last_fire=pair_fire&&q==W/2-1&&row==H-1;
    function automatic [23:0] rgb_pixel(input logic [10:0] x,y,input logic [1:0] kind);
        logic [7:0] level;
        begin
            case(kind)
                0:rgb_pixel={x[7:0],y[7:0],x[7:0]^y[7:0]};
                1:begin level=x>=W/2 ? 8'd255 : 8'd0;rgb_pixel={level,level,level};end
                2:begin level=y>=H/2 ? 8'd255 : 8'd0;rgb_pixel={level,level,level};end
                3:begin level=x[5]^y[5] ? 8'd239 : 8'd16;rgb_pixel={level,level,level};end
            endcase
        end
    endfunction
    always_comb begin : make_candidate
        // lane0低24；每lane为R[23:16]/G[15:8]/B[7:0]，沿用R1。
        out_fp={locked_fault&&row==H/2&&q==1,
            q==W/2-1&&row==H-1,q==W/2-1,q==0&&row==0,row,x_even,
            rgb_pixel(x_even+11'd1,row,locked_pattern),rgb_pixel(x_even,row,locked_pattern)};
    end
    always_ff @(posedge clk) begin : source_owner
        if(rst) begin active<=0;source_terminated<=0;q<=0;row<=0;locked_pattern<=0;locked_fault<=0;end
        else if(job_start) begin
            active<=1;source_terminated<=0;q<=0;row<=0;locked_pattern<=pattern;locked_fault<=fault;
        end else begin
            // CS valid注册stop：明确允许作废尚未接受candidate，不把stop组合进ready。
            if(source_stop) begin source_terminated<=1;active<=0;end
            else if(pair_fire) begin
                if(q==W/2-1) begin
                    if(row==H-1) active<=0;
                    else begin q<=0;row<=row+11'd1;end
                end else q<=q+10'd1;
            end
        end
    end
    // synthesis translate_off
    initial if(W<6||W>1920||W%2!=0||H<5||H>1080) $fatal(1,"SRC dimensions");
    always @(posedge clk) if(!rst&&job_start&&(cj[106:96]!=W||cj[117:107]!=H))
        $fatal(1,"SRC job geometry must match static instance");
    // synthesis translate_on
endmodule
