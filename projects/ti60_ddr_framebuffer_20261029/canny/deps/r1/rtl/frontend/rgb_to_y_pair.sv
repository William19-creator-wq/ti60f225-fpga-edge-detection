// FE-02 / OP-02：两 lane RGB888，三级灰度，单 core 时钟。
// 接口与逐步中文读回见 docs/arithmetic-implementation.md。
module cny_rgb_to_y_pair (
    input  wire        clk,
    input  wire        rst,
    input  wire        frame_start,
    input  wire        flush,
    input  wire        in_valid,
    output wire        in_ready,
    input  wire [47:0] in_rgb,
    input  wire [10:0] in_x_even,
    input  wire [10:0] in_y,
    input  wire        in_sof,
    input  wire        in_eol,
    input  wire        in_eof,
    output wire        out_valid,
    input  wire        out_ready,
    output logic [15:0] out_y_pair,
    output wire [10:0] out_x_even,
    output wire [10:0] out_y,
    output wire        out_sof,
    output wire        out_eol,
    output wire        out_eof,
    output wire        empty
);
    // Exactly (77R + 150G + 29B + 128)>>8, three elastic stages.
    // Dedicated DSP registers share the same CE as metadata. Flushing only
    // invalidates the pipeline; uninitialized data can never become valid.
    logic [2:0] valid_pipe;
    logic [24:0] coordinate_pipe[0:2];
    wire advance=!valid_pipe[2]||out_ready;
    wire ce=advance&&!rst&&!flush&&!frame_start;
    assign in_ready=!rst&&advance;
    assign out_valid=!rst&&valid_pipe[2];
    assign empty=!(|valid_pipe);
    assign {out_eof,out_eol,out_sof,out_y,out_x_even}=coordinate_pipe[2];
    genvar lane;
    generate for(lane=0;lane<2;lane=lane+1)begin:pixel
        wire [47:0] red_s1,rg_s2,total_s3;
        wire [17:0] rounded_rg={2'b0,rg_s2[15:0]}+18'd128;
        EFX_DSP48 #(.SIGNED(0),.O_REG(1),.N_SEL("CONST0")) red(
            .A({11'd0,in_rgb[lane*24+16+:8]}),.B(18'd77),.C(18'd0),.CASCIN(48'd0),
            .OP(2'b00),.SHIFT_ENA(1'b0),.CLK(clk),.CE(ce),.RST(1'b0),.O(red_s1),.CASCOUT(),.OVFL());
        EFX_DSP48 #(.SIGNED(0),.A_REG(1),.O_REG(1),.N_SEL("C")) green(
            .A({11'd0,in_rgb[lane*24+8+:8]}),.B(18'd150),.C(red_s1[17:0]),.CASCIN(48'd0),
            .OP(2'b00),.SHIFT_ENA(1'b0),.CLK(clk),.CE(ce),.RST(1'b0),.O(rg_s2),.CASCOUT(),.OVFL());
        EFX_DSP48 #(.SIGNED(0),.A_REG(1),.P_REG(1),.O_REG(1),.N_SEL("C")) blue(
            .A({11'd0,in_rgb[lane*24+:8]}),.B(18'd29),.C(rounded_rg),.CASCIN(48'd0),
            .OP(2'b00),.SHIFT_ENA(1'b0),.CLK(clk),.CE(ce),.RST(1'b0),.O(total_s3),.CASCOUT(),.OVFL());
        assign out_y_pair[lane*8+:8]=total_s3[15:8];
    end endgenerate
    always_ff @(posedge clk)begin
        if(rst||flush||frame_start)valid_pipe<=0;
        else if(advance)begin
            valid_pipe<={valid_pipe[1:0],in_valid};
            coordinate_pipe[0]<={in_eof,in_eol,in_sof,in_y,in_x_even};
            coordinate_pipe[1]<=coordinate_pipe[0];coordinate_pipe[2]<=coordinate_pipe[1];
        end
    end
endmodule
