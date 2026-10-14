// PF03/05/06：一个16B对齐byte span；实际AR/R与输出holding分别结账。
module display_span_axi #(
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000,
    parameter logic [3:0] READ_ID=2
)(
    input logic clk,rst,enable,cancel,
    input logic req_valid,output wire req_ready,input logic [31:0] req_addr,input logic [13:0] req_bytes,
    output wire data_valid,input logic data_ready,output logic [127:0] data,
    output wire done_valid,input logic done_ready,output logic [1:0] outcome,output logic [7:0] reason,
    output logic drained,output wire quarantined,
    output wire m_axi_arvalid,input logic m_axi_arready,output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid,output wire [7:0] m_axi_arlen,output wire [2:0] m_axi_arsize,output wire [1:0] m_axi_arburst,
    input logic m_axi_rvalid,output wire m_axi_rready,input logic [127:0] m_axi_rdata,
    input logic [3:0] m_axi_rid,input logic [1:0] m_axi_rresp,input logic m_axi_rlast
);
    typedef enum logic [2:0] {IDLE,PLAN,AR,R,AFTER_BURST,DONE,Q} state_t;
    state_t state;
    logic [31:0] address;logic [9:0] remaining_beats;
    logic [6:0] burst_beats,beat_index;
    logic hold_valid,stop_latched,uncertain,notice_valid,drain_tail;
    wire [32:0] req_end={1'b0,req_addr}+{19'd0,req_bytes};
    wire pop=data_valid&&data_ready;
    wire stop_new=stop_latched||cancel||uncertain||!enable;
    wire [8:0] page_beats=9'd256-{1'b0,address[11:4]};
    logic [6:0] planned_beats;
    always_comb begin
        planned_beats=remaining_beats>10'd64 ? 7'd64 : remaining_beats[6:0];
        if({2'd0,planned_beats}>page_beats)planned_beats=page_beats[6:0];
    end
    assign req_ready=!rst && enable && state==IDLE;
    assign data_valid=!rst && hold_valid;
    assign done_valid=!rst && (state==DONE || (state==Q && notice_valid && !hold_valid));
    assign quarantined=state==Q;
    assign m_axi_arvalid=!rst && state==AR;assign m_axi_araddr=address;assign m_axi_arid=READ_ID;
    assign m_axi_arlen=8'(burst_beats-7'd1);assign m_axi_arsize=4;assign m_axi_arburst=1;
    assign m_axi_rready=!rst && ((state==R && (!hold_valid||data_ready)) || (state==Q && drain_tail && (!hold_valid||data_ready)));
    wire r_fire=m_axi_rvalid&&m_axi_rready;
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;address<=0;remaining_beats<=0;burst_beats<=0;beat_index<=0;data<=0;hold_valid<=0;
            stop_latched<=0;uncertain<=0;notice_valid<=0;drain_tail<=0;outcome<=0;reason<=0;drained<=1;
        end else begin
            if(pop)hold_valid<=0;
            if(state!=IDLE && state!=DONE && state!=Q)begin
                if(cancel)begin stop_latched<=1;if(outcome==0)begin outcome<=2;reason<=128;end end
                if(!enable)begin uncertain<=1;stop_latched<=1;end
            end
            case(state)
                IDLE:if(req_valid&&req_ready)begin
                    address<=req_addr;remaining_beats<=10'(req_bytes>>4);beat_index<=0;hold_valid<=0;
                    stop_latched<=cancel;uncertain<=0;notice_valid<=0;drain_tail<=0;drained<=1;
                    outcome<=cancel ? 2 : 0;reason<=cancel ? 128 : 0;
                    if(req_addr[3:0]!=0 || req_bytes<16 || req_bytes>8192 || req_bytes[3:0]!=0 || req_end>ADDRESS_BYTES)begin
                        outcome<=1;reason<=1;state<=DONE;
                    end else state<=PLAN;
                end
                PLAN:begin
                    if(uncertain || !enable)begin state<=Q;notice_valid<=1;outcome<=3;reason<=4;drained<=0;end
                    else if(stop_new || remaining_beats==0)state<=DONE;
                    else begin burst_beats<=planned_beats;beat_index<=0;state<=AR;end
                end
                // AR一旦提出就保持；取消/失效只阻止下一个burst。
                AR:if(m_axi_arready)state<=R;
                R:if(r_fire)begin
                    if(m_axi_rid!=READ_ID || m_axi_rlast!=(beat_index==burst_beats-1))begin
                        state<=Q;notice_valid<=1;outcome<=3;reason<=3;drained<=0;
                        drain_tail<=!(m_axi_rid==READ_ID && m_axi_rlast);
                    end else begin
                        if(m_axi_rresp!=0)begin outcome<=1;reason<=2;stop_latched<=1;end
                        if(m_axi_rresp==0 && !stop_new && outcome==0)begin data<=m_axi_rdata;hold_valid<=1;end
                        if(beat_index==burst_beats-1)begin
                            address<=address+({25'd0,burst_beats}<<4);remaining_beats<=remaining_beats-{3'd0,burst_beats};state<=AFTER_BURST;
                        end else beat_index<=beat_index+7'd1;
                    end
                end
                AFTER_BURST:if(!hold_valid)begin
                    if(uncertain || !enable)begin state<=Q;notice_valid<=1;outcome<=3;reason<=4;drained<=0;end
                    else if(stop_new || remaining_beats==0)state<=DONE;
                    else state<=PLAN;
                end
                DONE:if(done_valid&&done_ready)state<=IDLE;
                Q:begin
                    if(done_valid&&done_ready)notice_valid<=0;
                    if(r_fire && m_axi_rid==READ_ID && m_axi_rlast)drain_tail<=0;
                end
                default:state<=Q;
            endcase
        end
    end
    // synthesis translate_off
    initial if(ADDRESS_BYTES<16 || ADDRESS_BYTES>33'h100000000 || ADDRESS_BYTES[3:0]!=0)$fatal(1,"Span capacity");
    always @(posedge clk)if(!rst)begin
        if(m_axi_arvalid && (burst_beats==0 || burst_beats>64 || {1'b0,address[11:0]}+({6'd0,burst_beats}<<4)>4096))$fatal(1,"AXI span burst boundary");
        if(done_valid && outcome!=3 && (!drained || hold_valid))$fatal(1,"Span done before local holding closed");
        if(quarantined && (req_ready || m_axi_arvalid))$fatal(1,"Unknown span reused");
    end
    // synthesis translate_on
endmodule
