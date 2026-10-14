// SW01..03：连续RGB字节/双bank/双packet；所有计数只按真实旧状态事件推进。
module rgb_source_writer #(parameter integer WIDTH=1920,HEIGHT=1080,parameter bit DSP_PACKETS=0)(
    input logic clk,rst,
    input logic job_valid,output wire job_ready,input logic [31:0] job_base,input logic [63:0] job_handle,
    output wire job_rsp_valid,input logic job_rsp_ready,output logic job_rsp_error,
    input logic in_valid,output wire in_ready,input logic [47:0] in_rgb,
    input logic [10:0] in_x_even,in_y,input logic [2:0] in_markers,input logic in_bad,input logic [63:0] in_handle,
    input logic cancel_valid,input logic [63:0] cancel_id,
    output wire done_valid,input logic done_ready,output wire [63:0] done_id,
    output logic [1:0] outcome,output logic [7:0] reason,
    output logic [21:0] accepted_pairs,written_lines,
    output logic [31:0] logical_bytes,physical_bytes,
    output wire source_stop,quarantined,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained
);
    localparam integer PAIRS=WIDTH*HEIGHT/2,LOGICAL=WIDTH*HEIGHT*3,ALLOCATION=((LOGICAL+63)/64)*64;
    typedef enum logic [3:0] {IDLE,CFG_REPLY,RUN,TAIL_PAD,DRAIN,ABORT,DONE,QUARANTINE} state_t;
    typedef enum logic [1:0] {B_FREE,B_FILL,B_SEALED,B_DRAIN} bank_state_t;
    typedef enum logic [1:0] {P_EMPTY,P_BUILD,P_READY,P_PUBLIC} packet_state_t;
    typedef enum logic [1:0] {RPC_IDLE,RPC_REQUEST,RPC_WAIT} rpc_state_t;
    state_t state;
    bank_state_t bank_state[0:1];
    packet_state_t packet_state[0:1];
    rpc_state_t rpc_state;
    logic [31:0] base,bank_offset[0:1];
    logic [63:0] active_handle;
    logic [7:0] bank_words[0:1];
    logic [4:0] bank_issued[0:1],bank_completed[0:1];
    logic fill_valid,fill_bank;
    logic [55:0] carry;
    logic [2:0] carry_count;
    logic [10:0] expected_x,expected_y;
    logic [511:0] packet0,packet1;
    logic [31:0] packet_addr[0:1];
    logic packet_bank[0:1],packet_head,packet_tail;
    logic read_active,read_slot,read_bank;
    logic [3:0] read_line;
    logic [3:0] read_issue_count;
    logic read_pending,pending_slot,pending_bank;
    logic [2:0] pending_lane;
    logic [31:0] read_issued_count,read_retired_count,read_discarded_count;
    wire active=state==RUN || state==TAIL_PAD || state==DRAIN;
    wire matching_cancel=cancel_valid && cancel_id==active_handle &&
        (active || (state==CFG_REPLY && !job_rsp_error));
    wire [2:0] expected_markers={accepted_pairs==22'(PAIRS-1),expected_x==11'(WIDTH-2),accepted_pairs==0};
    wire input_fire=in_valid && in_ready;
    wire tuple_bad=in_bad || in_handle!=active_handle || in_x_even!=expected_x || in_y!=expected_y || in_markers!=expected_markers;
    wire bad_fire=input_fire && tuple_bad;
    wire response_fire=line_rsp_valid && line_rsp_ready;
    wire response_failure=response_fire && (line_error || !line_drained);
    wire stop_new=matching_cancel || bad_fire || response_failure || state==ABORT || state==QUARANTINE;
    wire [32:0] grant_end={1'b0,job_base}+33'(ALLOCATION);
    assign job_ready=!rst && state==IDLE;
    assign job_rsp_valid=!rst && state==CFG_REPLY;
    assign in_ready=!rst && state==RUN && fill_valid && !matching_cancel;
    assign done_valid=!rst && state==DONE;
    assign done_id=active_handle;
    assign source_stop=state==TAIL_PAD || state==DRAIN || state==ABORT || state==DONE || state==QUARANTINE || matching_cancel;
    assign quarantined=state==QUARANTINE;
    assign line_req_valid=!rst && rpc_state==RPC_REQUEST;
    assign line_rsp_ready=!rst && rpc_state==RPC_WAIT && state!=QUARANTINE;
    assign line_write=1'b1;
    assign line_addr=packet_addr[packet_head];
    assign line_wdata=packet_head ? packet1 : packet0;

    // canonical48低24为R0/G0/B0；stream低byte必须先R0，然后G0/B0/R1/G1/B1。
    wire [47:0] stream_bytes={in_rgb[31:24],in_rgb[39:32],in_rgb[47:40],in_rgb[7:0],in_rgb[15:8],in_rgb[23:16]};
    wire [111:0] append_temp={56'd0,carry} | ({64'd0,stream_bytes} << {carry_count,3'b000});
    wire [3:0] append_count={1'b0,carry_count}+4'd6;
    wire append_fire=input_fire && !tuple_bad;
    wire append_word=append_fire && append_count>=8;
    wire padding_word=state==TAIL_PAD && fill_valid && physical_bytes<32'(ALLOCATION) && !stop_new;
    wire ram_we=!rst && (append_word || padding_word);
    wire [8:0] ram_waddr={1'b0,fill_bank,bank_words[fill_bank][6:0]};
    wire [63:0] ram_wdata=append_word ? append_temp[63:0] : {8'd0,carry};
    wire ram_re=!rst && read_active && read_issue_count<8 && !stop_new;
    wire [8:0] ram_raddr={1'b0,read_bank,read_line,read_issue_count[2:0]};
    wire [63:0] ram_rdata;
    rgb_source_ram_word payload(.clk(clk),.rd_en(ram_re),.rd_addr(ram_raddr),.rd_word(ram_rdata),
        .wr_en(ram_we),.wr_addr(ram_waddr),.wr_word(ram_wdata));

    logic reader_bank_valid,reader_bank_choice;
    always_comb begin
        reader_bank_valid=0;reader_bank_choice=0;
        for(integer b=0;b<2;b++)begin
            if((bank_state[b]==B_SEALED || bank_state[b]==B_DRAIN) && bank_issued[b]<({1'b0,bank_words[b]}>>3))begin
                if(!reader_bank_valid || bank_offset[b]<bank_offset[reader_bank_choice])begin
                    reader_bank_valid=1;reader_bank_choice=1'(b);
                end
            end
        end
    end
    wire private_empty=packet_state[0]==P_EMPTY && packet_state[1]==P_EMPTY;
    wire banks_empty=bank_state[0]==B_FREE && bank_state[1]==B_FREE;

    generate if(DSP_PACKETS)begin:dsp_packets
        // 每个64位lane补零为72位，拆成两个36位字；两包仍各自持有，捕获沿与原FF相同。
        // 高19位乘2^17后加低17位，精确恢复36位。只有O寄存器启用，不增加读回周期。
        for(genvar slot=0;slot<2;slot++)begin:packet
            for(genvar lane=0;lane<8;lane++)begin:word
                wire capture=!rst&&read_pending&&!stop_new&&
                    pending_slot==1'(slot)&&pending_lane==3'(lane);
                // 同步RST优先于CE；复位时仍打开时钟使能，所有lane在同一沿清零。
                wire register_enable=rst||capture;
                wire [47:0] low_word,high_word;
                wire [35:0] low_input=ram_rdata[35:0];
                wire [35:0] high_input={8'd0,ram_rdata[63:36]};
                EFX_DSP48 #(.MODE("NORMAL"),.SIGNED(1'b0),
                    .A_REG(1'b0),.B_REG(1'b0),.C_REG(1'b0),.P_REG(1'b0),.OP_REG(1'b0),
                    .W_REG(1'b0),.O_REG(1'b1),.SHIFTER(1'b0),.RST_SYNC(1'b1),
                    .P_EXT("ALIGN_RIGHT"),.C_EXT("ALIGN_RIGHT"),
                    .M_SEL("P"),.N_SEL("C"),.W_SEL("X"),
                    .O_REG_USE_CE(1'b1),.O_REG_USE_RST(1'b1)) low_storage(
                    .A(low_input[35:17]),.B(18'h20000),
                    .C({1'b0,low_input[16:0]}),.CASCIN(48'd0),.OP(2'd0),
                    .SHIFT_ENA(1'b0),.CLK(clk),.CE(register_enable),.RST(rst),
                    .O(low_word),.CASCOUT(),.OVFL());
                EFX_DSP48 #(.MODE("NORMAL"),.SIGNED(1'b0),
                    .A_REG(1'b0),.B_REG(1'b0),.C_REG(1'b0),.P_REG(1'b0),.OP_REG(1'b0),
                    .W_REG(1'b0),.O_REG(1'b1),.SHIFTER(1'b0),.RST_SYNC(1'b1),
                    .P_EXT("ALIGN_RIGHT"),.C_EXT("ALIGN_RIGHT"),
                    .M_SEL("P"),.N_SEL("C"),.W_SEL("X"),
                    .O_REG_USE_CE(1'b1),.O_REG_USE_RST(1'b1)) high_storage(
                    .A(high_input[35:17]),.B(18'h20000),.C({1'b0,high_input[16:0]}),
                    .CASCIN(48'd0),.OP(2'd0),.SHIFT_ENA(1'b0),
                    .CLK(clk),.CE(register_enable),.RST(rst),
                    .O(high_word),.CASCOUT(),.OVFL());
                if(slot==0)begin:first_packet
                    assign packet0[lane*64+:64]={high_word[27:0],low_word[35:0]};
                end else begin:second_packet
                    assign packet1[lane*64+:64]={high_word[27:0],low_word[35:0]};
                end
            end
        end
    end else begin:ff_packets
        // SW02 v1.1：两个完整holding显式FF；8项固定切片，避免动态数组部分写的综合歧义。
        always_ff @(posedge clk)begin
            if(rst)begin packet0<=0;packet1<=0;end
            else if(read_pending && !stop_new)begin
                if(pending_slot)begin
                    case(pending_lane)
                        0:packet1[63:0]<=ram_rdata;
                        1:packet1[127:64]<=ram_rdata;
                        2:packet1[191:128]<=ram_rdata;
                        3:packet1[255:192]<=ram_rdata;
                        4:packet1[319:256]<=ram_rdata;
                        5:packet1[383:320]<=ram_rdata;
                        6:packet1[447:384]<=ram_rdata;
                        7:packet1[511:448]<=ram_rdata;
                    endcase
                end else begin
                    case(pending_lane)
                        0:packet0[63:0]<=ram_rdata;
                        1:packet0[127:64]<=ram_rdata;
                        2:packet0[191:128]<=ram_rdata;
                        3:packet0[255:192]<=ram_rdata;
                        4:packet0[319:256]<=ram_rdata;
                        5:packet0[383:320]<=ram_rdata;
                        6:packet0[447:384]<=ram_rdata;
                        7:packet0[511:448]<=ram_rdata;
                    endcase
                end
            end
        end
    end endgenerate

    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;rpc_state<=RPC_IDLE;base<=0;active_handle<=0;job_rsp_error<=0;
            outcome<=0;reason<=0;accepted_pairs<=0;written_lines<=0;logical_bytes<=0;physical_bytes<=0;
            fill_valid<=0;fill_bank<=0;carry<=0;carry_count<=0;expected_x<=0;expected_y<=0;
            packet_head<=0;packet_tail<=0;read_active<=0;read_slot<=0;read_bank<=0;read_line<=0;read_issue_count<=0;
            read_pending<=0;pending_slot<=0;pending_bank<=0;pending_lane<=0;
            read_issued_count<=0;read_retired_count<=0;read_discarded_count<=0;
            for(integer b=0;b<2;b++)begin
                bank_state[b]<=B_FREE;bank_offset[b]<=0;bank_words[b]<=0;bank_issued[b]<=0;bank_completed[b]<=0;
                packet_state[b]<=P_EMPTY;packet_addr[b]<=0;packet_bank[b]<=0;
            end
        end else begin
            // 同步RAM的旧Q在本沿归还，新RE可同时借下一个Q。先预约整个packet，再开始RE。
            read_pending<=ram_re;
            if(ram_re)begin
                pending_slot<=read_slot;pending_bank<=read_bank;pending_lane<=read_issue_count[2:0];
                read_issue_count<=read_issue_count+4'd1;read_issued_count<=read_issued_count+32'd1;
            end
            if(read_pending)begin
                if(stop_new)read_discarded_count<=read_discarded_count+32'd1;
                else begin
                    read_retired_count<=read_retired_count+32'd1;
                    if(pending_lane==7)begin packet_state[pending_slot]<=P_READY;read_active<=0;end
                end
            end
            if(active && !stop_new)begin
                if(!read_active && packet_state[packet_tail]==P_EMPTY && reader_bank_valid)begin
                    read_active<=1;read_slot<=packet_tail;read_bank<=reader_bank_choice;
                    read_line<=bank_issued[reader_bank_choice][3:0];read_issue_count<=0;
                    packet_state[packet_tail]<=P_BUILD;packet_bank[packet_tail]<=reader_bank_choice;
                    packet_addr[packet_tail]<=base+bank_offset[reader_bank_choice]+({27'd0,bank_issued[reader_bank_choice]}<<6);
                    bank_issued[reader_bank_choice]<=bank_issued[reader_bank_choice]+5'd1;
                    bank_state[reader_bank_choice]<=B_DRAIN;packet_tail<=!packet_tail;
                end
                if(rpc_state==RPC_IDLE && packet_state[packet_head]==P_READY)begin
                    packet_state[packet_head]<=P_PUBLIC;rpc_state<=RPC_REQUEST;
                end
            end
            // 公共REQUEST不因stop撤销；回执才归还该packet，bank不在最后RE处退休。
            if(rpc_state==RPC_REQUEST && line_req_ready)rpc_state<=RPC_WAIT;
            if(response_fire)begin
                if(!line_drained)begin state<=QUARANTINE;outcome<=1;reason<=8'd16;end
                else begin
                    rpc_state<=RPC_IDLE;packet_state[packet_head]<=P_EMPTY;packet_head<=!packet_head;
                    if(!line_error)begin
                        written_lines<=written_lines+22'd1;
                        bank_completed[packet_bank[packet_head]]<=bank_completed[packet_bank[packet_head]]+5'd1;
                    end else begin state<=ABORT;outcome<=1;reason<=8'd16;end
                end
            end
            for(integer b=0;b<2;b++)begin
                if((bank_state[b]==B_SEALED || bank_state[b]==B_DRAIN) &&
                    bank_completed[b]==({1'b0,bank_words[b]}>>3) && bank_issued[b]==bank_completed[b] &&
                    !(read_pending && pending_bank==1'(b)) &&
                    !(packet_state[0]!=P_EMPTY && packet_bank[0]==1'(b)) &&
                    !(packet_state[1]!=P_EMPTY && packet_bank[1]==1'(b)))bank_state[b]<=B_FREE;
            end
            if((state==RUN || state==TAIL_PAD) && !fill_valid && !stop_new &&
                (state==RUN || physical_bytes<32'(ALLOCATION)))begin
                if(bank_state[0]==B_FREE || bank_state[1]==B_FREE)begin
                    fill_bank<=bank_state[0]==B_FREE ? 1'b0 : 1'b1;fill_valid<=1;
                    bank_state[bank_state[0]==B_FREE ? 0 : 1]<=B_FILL;
                    bank_offset[bank_state[0]==B_FREE ? 0 : 1]<=physical_bytes;
                    bank_words[bank_state[0]==B_FREE ? 0 : 1]<=0;
                    bank_issued[bank_state[0]==B_FREE ? 0 : 1]<=0;
                    bank_completed[bank_state[0]==B_FREE ? 0 : 1]<=0;
                end
            end
            if(ram_we)begin
                physical_bytes<=physical_bytes+32'd8;bank_words[fill_bank]<=bank_words[fill_bank]+8'd1;
                if(bank_words[fill_bank]==127)begin bank_state[fill_bank]<=B_SEALED;fill_valid<=0;end
            end
            case(state)
                IDLE:if(job_valid && job_ready)begin
                    base<=job_base;active_handle<=job_handle;
                    job_rsp_error<=job_base[5:0]!=0 || grant_end>33'h100000000;state<=CFG_REPLY;
                    outcome<=0;reason<=0;accepted_pairs<=0;written_lines<=0;logical_bytes<=0;physical_bytes<=0;
                    carry<=0;carry_count<=0;expected_x<=0;expected_y<=0;packet_head<=0;packet_tail<=0;
                    read_issued_count<=0;read_retired_count<=0;read_discarded_count<=0;
                end
                CFG_REPLY:if(job_rsp_ready)state<=job_rsp_error ? IDLE : (outcome==2 || matching_cancel ? ABORT : RUN);
                RUN:if(input_fire)begin
                    accepted_pairs<=accepted_pairs+22'd1;
                    if(tuple_bad)begin
                        state<=ABORT;outcome<=1;
                        reason<=in_bad ? 8'd1 : in_handle!=active_handle ? 8'd2 :
                            in_x_even!=expected_x || in_y!=expected_y ? 8'd3 : 8'd4;
                    end else begin
                        logical_bytes<=logical_bytes+32'd6;
                        if(append_count>=8)begin carry<=56'(append_temp>>64);carry_count<=3'(append_count-8);end
                        else begin carry<=append_temp[55:0];carry_count<=append_count[2:0];end
                        if(expected_x==11'(WIDTH-2))begin expected_x<=0;expected_y<=expected_y+11'd1;end
                        else expected_x<=expected_x+11'd2;
                        if(accepted_pairs==22'(PAIRS-1))state<=TAIL_PAD;
                    end
                end
                TAIL_PAD:begin
                    if(padding_word)begin carry<=0;carry_count<=0;end
                    if(physical_bytes==32'(ALLOCATION) && !stop_new)begin
                        if(fill_valid)begin bank_state[fill_bank]<=bank_words[fill_bank]==0 ? B_FREE : B_SEALED;fill_valid<=0;end
                        state<=DRAIN;
                    end
                end
                DRAIN:if(banks_empty && private_empty && !read_active && !read_pending && rpc_state==RPC_IDLE && !stop_new)begin
                    state<=DONE;
                    if(accepted_pairs!=22'(PAIRS) || logical_bytes!=32'(LOGICAL) || physical_bytes!=32'(ALLOCATION) || written_lines!=22'(ALLOCATION/64))begin outcome<=1;reason<=8'd17;end
                end
                ABORT:if(rpc_state==RPC_IDLE && !read_pending)begin
                    state<=DONE;fill_valid<=0;carry<=0;carry_count<=0;read_active<=0;
                    for(integer b=0;b<2;b++)begin bank_state[b]<=B_FREE;packet_state[b]<=P_EMPTY;end
                end
                DONE:if(done_ready)state<=IDLE;
                default:begin end
            endcase
            // 此处置于case之后：同沿真内存错误必须覆盖cancel和普通输入错误。
            if(matching_cancel)begin
                if(state!=CFG_REPLY)state<=ABORT;
                if(outcome==0)begin outcome<=2;reason<=8'd128;end
            end
            if(response_failure)begin state<=line_drained ? ABORT : QUARANTINE;outcome<=1;reason<=8'd16;end
            if(stop_new)begin
                read_active<=0;fill_valid<=0;
                for(integer p=0;p<2;p++)if(packet_state[p]!=P_PUBLIC)packet_state[p]<=P_EMPTY;
            end
        end
    end
    // synthesis translate_off
    initial if(WIDTH<4 || WIDTH>1920 || WIDTH%2 || HEIGHT<2 || HEIGHT>1080)$fatal(1,"Source writer geometry");
    always @(posedge clk)if(!rst)begin
        if(ram_we && bank_state[fill_bank]!=B_FILL)$fatal(1,"Source WE lacks FILL owner");
        if(ram_re && bank_state[read_bank]!=B_DRAIN && bank_state[read_bank]!=B_SEALED)$fatal(1,"Source RE lacks frozen descriptor");
        if(line_req_valid && packet_state[packet_head]!=P_PUBLIC)$fatal(1,"Source public packet lost");
        if(read_pending && packet_state[pending_slot]!=P_BUILD && !stop_new)$fatal(1,"Source return lacks reservation");
        if(done_valid && (rpc_state!=RPC_IDLE || read_pending || read_active || !private_empty || !banks_empty))$fatal(1,"Source done with borrowed storage");
        if(physical_bytes>32'(ALLOCATION) || logical_bytes>32'(LOGICAL))$fatal(1,"Source grant overrun");
        if(read_issued_count!=read_retired_count+read_discarded_count+32'(read_pending))$fatal(1,"Source RE retirement ledger");
    end
    // synthesis translate_on
endmodule
