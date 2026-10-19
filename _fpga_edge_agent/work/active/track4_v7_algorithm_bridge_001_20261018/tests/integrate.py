from pathlib import Path
w=Path(__file__).resolve().parent.parent
p=w/'rtl/ti60f225_oob_top.v'
s=p.read_text(encoding='utf-8')
assert s.count('wire [47:0] rgb_datax2;')==1
s=s.replace('wire [47:0] rgb_datax2;', '''wire [47:0] rgb_datax2;
wire camera_rgb_vs, camera_rgb_hs, camera_rgb_de;
wire [47:0] camera_rgb_datax2;
wire algorithm_sticky_fault;
// 算法只改变像素，不参与相机/DDR/HDMI 的启动条件。
// 沿用已校色基线的实际 RGB 字节含义，低 24 位是前一个像素。
v7_algorithm_video_pair #(.W(1920),.H(1080),.HTOTAL(1100)) algorithm_bridge (
    .clk(vid_clk_dvi2),.rst(!vid_rst_n),
    .in_vs(camera_rgb_vs),.in_hs(camera_rgb_hs),.in_de(camera_rgb_de),
    .in_rgb(camera_rgb_datax2),
    .cfg_mode(3'd5),.cfg_threshold(11'd256),.cfg_median_enable(1'b1),
    .out_vs(rgb_vs),.out_hs(rgb_hs),.out_de(rgb_de),.out_rgb(rgb_datax2),
    .sticky_fault(algorithm_sticky_fault)
);''')
s=s.replace('// 相机RAW先扣黑电平并白平衡，随后注入已知BGGR色卡；同步及拍数保持。',
 '// 相机 RAW 先扣黑电平并白平衡；取消诊断图案，保留原始行奇偶标记。')
for old,new in [('(rgb_vs         )','(camera_rgb_vs  )'),('(rgb_hs         )','(camera_rgb_hs  )'),('(rgb_de         )','(camera_rgb_de  )'),('(rgb_datax2     )','(camera_rgb_datax2)')]:
    assert s.count(old)==1,(old,s.count(old))
    s=s.replace(old,new)
start=s.index('// 已知数字色卡直达编码器')
end=s.index('\ndvi_encoder dvi_encoder_m0',start)
s=s[:start]+'''// 旧信号 hdmi_tx_bdata 实际接编码器 R，维持已验证的 RGB 显示顺序。
wire [7:0] card_r = hdmi_tx_bdata;
wire [7:0] card_g = hdmi_tx_gdata;
wire [7:0] card_b = hdmi_tx_rdata;
'''+s[end:]
p.write_text(s,encoding='utf-8')
(w/'rtl/rawcard_overlay.v').write_text('''// 保留已验证的 RAW 行相位；算法桥版本取消所有合成图案覆盖。
module rawcard_overlay (
    input wire clk, rst_n, vs, de,
    input wire [15:0] camera_raw,
    output wire [15:0] out_raw,
    output wire raw_y_odd
);
    reg vs_q, de_q;
    reg [10:0] line_y;
    assign raw_y_odd=line_y[0];
    assign out_raw=camera_raw;
    always @(posedge clk) begin
        if(!rst_n)begin vs_q<=0;de_q<=0;line_y<=0;end
        else begin
            vs_q<=vs;de_q<=de;
            if(vs_q&&!vs)line_y<=0;
            else if(de_q&&!de&&line_y!=11'h7ff)line_y<=line_y+11'd1;
        end
    end
endmodule
''',encoding='utf-8')
p=w/'ti60f225_oob.xml';s=p.read_text(encoding='utf-8')
marker='        <efx:design_file name="rtl/colorcard_overlay.v"'
files=['rtl/v7_algorithm_video_pair.sv']+[f'algorithm/frontend/{n}.sv' for n in ['frontend_frame_pair','rgb_to_y_pair','window3x3_pair','line_store_pair','median9_pair','sobel_pair']]
assert marker in s
s=s.replace(marker,''.join(f'        <efx:design_file name="{n}" version="sv_09" library="default" />\n' for n in files)+marker)
p.write_text(s,encoding='utf-8')
print('Integrated bridge, retained video clocks and pin constraints.')
