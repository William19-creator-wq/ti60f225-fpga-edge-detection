// R1-IF05 / OP03：两级异步置0、同域同步释放；核心只看到同步高reset。
module reset_sync(input wire clk,input wire key1_n,output wire core_rst);
    reg reset_release_stage1,reset_release_stage2;
    always @(posedge clk or negedge key1_n) begin
        if(!key1_n) begin reset_release_stage1<=0;reset_release_stage2<=0;end
        else begin reset_release_stage1<=1;reset_release_stage2<=reset_release_stage1;end
    end
    assign core_rst=!reset_release_stage2;
endmodule
