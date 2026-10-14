// RA01..05：一个实际物理读在途；错误归属保留占用，不猜closed。
module axi_read_arbiter2 #(
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000
)(
    input logic clk,rst,enable,
    input logic [1:0] c_arvalid,output logic [1:0] c_arready,
    input logic [1:0][31:0] c_araddr,input logic [1:0][3:0] c_arid,
    input logic [1:0][7:0] c_arlen,input logic [1:0][2:0] c_arsize,
    input logic [1:0][1:0] c_arburst,
    output logic [1:0] c_rvalid,input logic [1:0] c_rready,
    output wire [1:0][127:0] c_rdata,output wire [1:0][3:0] c_rid,
    output wire [1:0][1:0] c_rresp,output wire [1:0] c_rlast,
    output wire m_axi_arvalid,input logic m_axi_arready,output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid,output wire [7:0] m_axi_arlen,
    output wire [2:0] m_axi_arsize,output wire [1:0] m_axi_arburst,
    input logic m_axi_rvalid,output wire m_axi_rready,input logic [127:0] m_axi_rdata,
    input logic [3:0] m_axi_rid,input logic [1:0] m_axi_rresp,input logic m_axi_rlast,
    output wire idle,occupied,output logic quarantined,output logic [2:0] fault_reason
);
    // E1：保存完整AR，身份仍由父FrameRef授权；这些ID只用于总线选路。
    logic pending,selected,active,owner;
    logic [48:0] ar_hold;
    logic [3:0] expected_id;
    logic [8:0] remaining;
    logic [1:0] display_credit;
    logic choose,can_choose,chosen_legal;
    logic [1:0][48:0] client_ar;
    logic [48:0] chosen_ar;
    logic [8:0] chosen_beats;
    logic [12:0] chosen_bytes,page_end;
    logic [32:0] address_end;
    logic [2:0] detected_fault;
    wire ar_fire=m_axi_arvalid && m_axi_arready;
    wire r_fire=m_axi_rvalid && m_axi_rready;

    assign m_axi_arvalid=!rst && pending;
    assign {m_axi_araddr,m_axi_arid,m_axi_arlen,m_axi_arsize,m_axi_arburst}=ar_hold;
    assign m_axi_rready=!rst && active && c_rready[owner];
    assign c_rdata={2{m_axi_rdata}};
    assign c_rid={2{m_axi_rid}};
    assign c_rresp={2{m_axi_rresp}};
    assign c_rlast={2{m_axi_rlast}};
    assign idle=!rst && !pending && !active && !quarantined;
    assign occupied=pending || active || quarantined;

    always_comb begin
        for(integer client=0;client<2;client++)
            client_ar[client]={c_araddr[client],c_arid[client],c_arlen[client],c_arsize[client],c_arburst[client]};
        can_choose=!rst && enable && !pending && !active && !quarantined && (|c_arvalid);
        // E2：端0显示；只有双方持续请求时，额度决定3:1机会。
        choose=c_arvalid[0] ? (c_arvalid[1] && display_credit==0) : 1'b1;
        chosen_ar=client_ar[choose];
        chosen_beats={1'b0,c_arlen[choose]}+9'd1;
        chosen_bytes={4'd0,chosen_beats}<<4;
        address_end={1'b0,c_araddr[choose]}+{20'd0,chosen_bytes};
        page_end={1'b0,c_araddr[choose][11:0]}+chosen_bytes;
        chosen_legal=c_arid[choose]==(choose ? 4'd0 : 4'd2) &&
            c_arsize[choose]==3'd4 && c_arburst[choose]==2'd1 && c_araddr[choose][3:0]==0 &&
            (choose ? c_arlen[choose]==8'd3 : c_arlen[choose]<=8'd63) &&
            address_end<=ADDRESS_BYTES && page_end<=13'd4096;
        c_arready=0;c_rvalid=0;
        if(!rst && pending)c_arready[selected]=m_axi_arready;
        if(!rst && active)c_rvalid[owner]=m_axi_rvalid;

        // E3..5：全事件优先记录首因；RRESP原样给叶，不能在这里改写成功。
        detected_fault=0;
        if(can_choose && !chosen_legal)detected_fault=1;
        else if(pending && (!c_arvalid[selected] || client_ar[selected]!==ar_hold))detected_fault=2;
        else if(r_fire && m_axi_rid!==expected_id)detected_fault=3;
        else if(r_fire && m_axi_rlast!==(remaining==9'd1))detected_fault=4;
        else if(!active && m_axi_rvalid && !ar_fire)detected_fault=5;
    end

    always_ff @(posedge clk)begin
        if(rst)begin
            pending<=0;selected<=0;active<=0;owner<=0;ar_hold<=0;
            expected_id<=0;remaining<=0;display_credit<=3;quarantined<=0;fault_reason<=0;
        end else begin
            if(!quarantined && detected_fault!=0)begin quarantined<=1;fault_reason<=detected_fault;end
            if(can_choose && chosen_legal)begin pending<=1;selected<=choose;ar_hold<=chosen_ar;end
            // 已锁定的AR即使disable/Q也兑现，绝不改写已公开的49位正文。
            if(ar_fire)begin
                pending<=0;active<=1;owner<=selected;
                expected_id<=ar_hold[16:13];remaining<={1'b0,ar_hold[12:5]}+9'd1;
                if(selected)display_credit<=3;
                else if(display_credit!=0)display_credit<=display_credit-2'd1;
            end
            if(r_fire && !quarantined && detected_fault==0)begin
                if(remaining==9'd1)active<=0;
                else remaining<=remaining-9'd1;
            end
            // 错误或Q时不清active/remaining；旧尾可流动，但身份不复用。
        end
    end
    // synthesis translate_off
    initial if(ADDRESS_BYTES==0 || ADDRESS_BYTES>33'h100000000)$fatal(1,"Read arbiter address geometry");
    // synthesis translate_on
endmodule
