// 上板面积版：4way/8set；扩大 tag 保留完整13位外存 line 身份，64B RPC仍须实际排空。
module canny_state_cache #(
    parameter integer unsigned WIDTH=1920,HEIGHT=1080,
    parameter bit RAM_TAGS=0,
    parameter bit PACK_DATA_WAYS=1'b0,
    parameter bit DSP_WB=1'b0
)(
    input logic clk,rst,
    input logic cfg_valid,output wire cfg_ready,input logic [31:0] cfg_base,input logic [63:0] cfg_job_id,
    output wire cfg_rsp_valid,input logic cfg_rsp_ready,output logic cfg_rsp_error,
    input logic abort_private_valid,input logic [63:0] abort_job_id,
    input logic req_valid,output wire req_ready,input logic [1:0] req_op,input logic [20:0] req_index,
    output wire rsp_valid,input logic rsp_ready,output logic [1:0] rsp_old,output logic rsp_claimed,rsp_error,rsp_aborted,
    output wire claim_valid,input logic claim_ready,output wire [20:0] claim_index,
    output wire line_req_valid,input logic line_req_ready,
    output logic line_write,output logic [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained,output wire quarantined,
    output wire [63:0] active_job_id
);
    localparam integer unsigned N=WIDTH*HEIGHT;
    localparam logic [32:0] ALLOCATION=33'(((N+255)/256)*64);
    typedef enum logic [3:0] {
        IDLE,CFG_REPLY,LOOKUP,WORD_READ,WORD_CAPTURE,CHECK,CLAIM,REPLY,
        WB_READ,WB_CAPTURE,MEM_REQUEST,MEM_WAIT,FILL_INSTALL,FLUSH_SCAN,QUARANTINE
    } state_t;
    state_t state;
    logic configured,faulted,abort_sticky;
    logic [31:0] base;
    logic [63:0] job_id;
    wire [9:0] lookup_tag[0:3];
    wire [9:0] selected_tag;
    logic valid[0:3][0:7],dirty[0:3][0:7];
    logic [2:0] plru[0:7];
    logic [1:0] operation,selected_way;
    logic [20:0] index;
    logic [4:0] selected_set,transfer_word;
    logic [9:0] requested_tag;
    logic [15:0] old_word;
    wire [511:0] line_buffer;
    logic flush_mode;
    logic [4:0] flush_position;
    wire [15:0] selected_data_q;
    logic ram_re[0:3][0:1],ram_we[0:3][0:1];
    logic [8:0] ram_address;
    logic [15:0] ram_data;
    logic [2:0] hit_count;
    logic [1:0] hit_way,victim_way;
    logic invalid_found;
    wire [1:0] old_state=old_word[{index[2:0],1'b0}+:2];
    logic [15:0] claimed_word;
    wire [32:0] cfg_end={1'b0,cfg_base}+ALLOCATION;
    wire cfg_legal=cfg_base[5:0]==0 && cfg_end<=33'h100000000;
    wire matching_abort=abort_private_valid && configured && abort_job_id==job_id;
    wire abort_requested=abort_sticky || matching_abort;
    // 仅最后一字真实安装成功才提交tag，与valid/dirty同沿；错误/取消不改身份。
    wire tag_install=!rst && state==FILL_INSTALL && line_rsp_valid && line_drained &&
                     !line_error && !abort_requested && transfer_word==31;
    assign cfg_ready=!rst && state==IDLE && !configured;
    assign cfg_rsp_valid=!rst && state==CFG_REPLY;
    assign req_ready=!rst && state==IDLE && configured;
    assign rsp_valid=!rst && state==REPLY;
    assign claim_valid=!rst && state==CLAIM;
    assign claim_index=index;
    assign line_req_valid=!rst && state==MEM_REQUEST;
    // 读回复保持在实际物理服务内；全部32个16位字安装后才消费，不再复制512位填充正文。
    assign line_rsp_ready=!rst&&
        ((state==MEM_WAIT&&(line_write||line_error||!line_drained||abort_requested))||
         (state==FILL_INSTALL&&(transfer_word==31||line_error||!line_drained||abort_requested)));
    assign line_wdata=line_buffer;
    assign quarantined=state==QUARANTINE;
    assign active_job_id=job_id;
    initial if(WIDTH<6 || WIDTH>1920 || WIDTH%2!=0 || HEIGHT<5 || HEIGHT>1080)
        $fatal(1,"Unsupported state cache geometry");

    // 每块按0..31完整组装，最后一字到达后LSB仍为字0；固定移位，不增加逐字写选择器。
    // 已预约的WB_CAPTURE即使同沿取消也保留原采样；正文不复位，公开请求只在组装完成后发出。
    wire wb_write=!rst && state==WB_CAPTURE;
    wire [511:0] wb_write_data={selected_data_q,line_buffer[511:16]};
    generate if(DSP_WB)begin:dsp_wb
        wire [539:0] padded_input={28'd0,wb_write_data};
        wire [539:0] padded_output;
        assign line_buffer=padded_output[511:0];
        for(genvar stripe=0;stripe<15;stripe++)begin:words
            wire [35:0] register_input=padded_input[stripe*36+:36];
            wire [47:0] registered_output;
            assign padded_output[stripe*36+:36]=registered_output[35:0];
            // 高19bit乘2^17与低17bit相加，无位重叠；硬O寄存器在原WB_CAPTURE沿采样。
            EFX_DSP48 #(.MODE("NORMAL"),.SIGNED(1'b0),.A_REG(1'b0),.B_REG(1'b0),
                .C_REG(1'b0),.P_REG(1'b0),.OP_REG(1'b0),.W_REG(1'b0),.O_REG(1'b1),
                .P_EXT("ALIGN_RIGHT"),.C_EXT("ALIGN_RIGHT"),
                .M_SEL("P"),.N_SEL("C"),.W_SEL("X"),.SHIFTER(1'b0),
                .RST_SYNC(1'b1),.O_REG_USE_CE(1'b1),.O_REG_USE_RST(1'b0)) storage(
                .A(register_input[35:17]),.B(18'h20000),
                .C({1'b0,register_input[16:0]}),.CASCIN(48'd0),.OP(2'b00),
                .SHIFT_ENA(1'b0),.CLK(clk),.CE(wb_write),.RST(1'b0),
                .O(registered_output),.CASCOUT(),.OVFL());
        end
    end else begin:ff_wb
        logic [511:0] held_line_buffer;
        assign line_buffer=held_line_buffer;
        always_ff @(posedge clk)if(wb_write)held_line_buffer<=wb_write_data;
    end endgenerate

    generate if(RAM_TAGS)begin:ram_tags
        wire [39:0] tag_row_q;
        logic [39:0] tag_row_write;
        logic [2:0] tag_read_set;
        always_comb begin
            // 接受沿必须用当前req_index，下一LOOKUP沿就能比较锁定请求的四路tag。
            // flush预读扫描行，其余时间只取已锁定set；反压时忽略活动输入。
            tag_read_set=selected_set[2:0];
            if(req_valid && req_ready)tag_read_set=req_index[10:8];
            else if(state==LOOKUP)tag_read_set=index[10:8];
            else if(state==FLUSH_SCAN)tag_read_set=flush_position[4:2];
            // 整行读改写保留其它way，不使用RAM动态部分写或清数据阵列。
            tag_row_write=tag_row_q;
            case(selected_way)
                0:tag_row_write[9:0]=requested_tag;
                1:tag_row_write[19:10]=requested_tag;
                2:tag_row_write[29:20]=requested_tag;
                3:tag_row_write[39:30]=requested_tag;
            endcase
        end
        for(genvar stripe=0;stripe<2;stripe++)begin:tag_words
            EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_FIRST")) storage(
                .WCLK(clk),.WE({2{tag_install}}),.WCLKE(1'b1),.WADDREN(1'b1),
                .WDATA(tag_row_write[stripe*20+:20]),.WADDR({6'd0,selected_set[2:0]}),
                .RCLK(clk),.RE(!rst),.RST(1'b0),.RADDREN(1'b1),
                .RDATA(tag_row_q[stripe*20+:20]),.RADDR({6'd0,tag_read_set}));
        end
        for(genvar way_number=0;way_number<4;way_number++)begin:lookup_words
            assign lookup_tag[way_number]=tag_row_q[way_number*10+:10];
        end
        assign selected_tag=tag_row_q[selected_way*10+:10];
        // RAM不复位：现有valid在rst/cfg清零，未初始化的其它way始终被valid屏蔽。
        // 同址安装沿读旧行无害；下一WORD_READ不消费tag，后续请求重新预读。
    end else begin:ff_tags
        logic [9:0] tags[0:3][0:7];
        for(genvar way_number=0;way_number<4;way_number++)begin:lookup_words
            assign lookup_tag[way_number]=tags[way_number][index[10:8]];
        end
        assign selected_tag=tags[selected_way][selected_set];
        always_ff @(posedge clk)begin
            if(rst)begin
                for(integer w=0;w<4;w++)for(integer s=0;s<8;s++)tags[w][s]<=0;
            end else if(tag_install)tags[selected_way][selected_set]<=requested_tag;
        end
    end endgenerate

    generate if(PACK_DATA_WAYS)begin:packed_data_ways
        wire [15:0] packed_q[0:1];
        // 每way只用8set x 32word；两个way按地址高位分开，共用一个512x16 RAM。
        // 同沿始终只访问selected_way，故保持原读/写预约及下一沿capture。
        wire [8:0] packed_address={selected_way[0],selected_set[2:0],ram_address[4:0]};
        for(genvar physical_bank=0;physical_bank<2;physical_bank++)begin:bank
            wire packed_re=ram_re[physical_bank*2][0]||ram_re[physical_bank*2+1][0];
            wire packed_we=ram_we[physical_bank*2][0]||ram_we[physical_bank*2+1][0];
            state_cache_ram16 storage(.clk(clk),.re(packed_re),.we(packed_we),
                .address(packed_address),.data(ram_data),.q(packed_q[physical_bank]));
        end
        assign selected_data_q=packed_q[selected_way[1]];
    end else begin:separate_data_ways
        logic [15:0] ram_q[0:3][0:1];
        for(genvar w=0;w<4;w++)begin:way
            for(genvar b=0;b<2;b++)begin:bank
                state_cache_ram16 storage(.clk(clk),.re(ram_re[w][b]),.we(ram_we[w][b]),
                    .address(ram_address),.data(ram_data),.q(ram_q[w][b]));
            end
        end
        assign selected_data_q=ram_q[selected_way][selected_set[4]];
    end endgenerate
    always_comb begin
        hit_count=0;hit_way=0;invalid_found=0;
        victim_way=plru[index[10:8]][0] ? {1'b1,plru[index[10:8]][2]} : {1'b0,plru[index[10:8]][1]};
        for(integer w=0;w<4;w++)begin
            if(valid[w][index[10:8]] && lookup_tag[w]==index[20:11])begin
                hit_count=hit_count+3'd1;hit_way=2'(w);
            end
            if(!valid[w][index[10:8]] && !invalid_found)begin victim_way=2'(w);invalid_found=1;end
        end
        claimed_word=old_word;claimed_word[{index[2:0],1'b0}+:2]=2'b11;
        for(integer w=0;w<4;w++)for(integer b=0;b<2;b++)begin ram_re[w][b]=0;ram_we[w][b]=0;end
        ram_address={selected_set[3:0],index[7:3]};ram_data=claimed_word;
        if(!rst)case(state)
            WORD_READ:if(!abort_requested)ram_re[selected_way][selected_set[4]]=1;
            WB_READ:begin ram_address={selected_set[3:0],transfer_word};if(!abort_requested)ram_re[selected_way][selected_set[4]]=1;end
            FILL_INSTALL:begin
                ram_address={selected_set[3:0],transfer_word};ram_data=line_rdata[transfer_word*16+:16];
                if(line_rsp_valid&&line_drained&&!line_error&&!abort_requested)ram_we[selected_way][selected_set[4]]=1;
            end
            CLAIM:if(claim_ready)ram_we[selected_way][selected_set[4]]=1;
            default:begin end
        endcase
    end
    task automatic touch(input logic [4:0] set_number,input logic [1:0] way_number);
        begin
            plru[set_number][0]<=!way_number[1];
            if(way_number[1])plru[set_number][2]<=!way_number[0];else plru[set_number][1]<=!way_number[0];
        end
    endtask
    task automatic reply(input logic [1:0] old_value,input logic did_claim,input logic error_value);
        begin rsp_old<=old_value;rsp_claimed<=did_claim;rsp_error<=error_value;rsp_aborted<=0;state<=REPLY;end
    endtask
    task automatic start_line(input logic writing,input logic [12:0] line_number);
        logic [32:0] address;
        begin
            address={1'b0,base}+({20'd0,line_number}<<6);
            if(address+33'd64>{1'b0,base}+ALLOCATION || address[32])begin faulted<=1;reply(0,0,1);end
            else begin line_write<=writing;line_addr<=address[31:0];state<=MEM_REQUEST;end
        end
    endtask
    task automatic finish_flush;
        begin
            for(integer w=0;w<4;w++)for(integer s=0;s<8;s++)begin valid[w][s]<=0;dirty[w][s]<=0;end
            configured<=0;reply(0,0,faulted);
        end
    endtask
    task automatic next_flush;
        begin
            if(flush_position==31)finish_flush();
            else begin flush_position<=flush_position+5'd1;state<=FLUSH_SCAN;end
        end
    endtask
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;configured<=0;faulted<=0;abort_sticky<=0;base<=0;job_id<=0;cfg_rsp_error<=0;
            rsp_old<=0;rsp_claimed<=0;rsp_error<=0;rsp_aborted<=0;line_write<=0;line_addr<=0;flush_mode<=0;
            index<=0;selected_way<=0;selected_set<=0;
            for(integer w=0;w<4;w++)for(integer s=0;s<8;s++)begin valid[w][s]<=0;dirty[w][s]<=0;end
            for(integer s=0;s<8;s++)plru[s]<=0;
        end else begin
            if(matching_abort)abort_sticky<=1;
            // 公开RPC不撤销；RAM旧预约capture后才终结；held回复也不重写。
            if(abort_requested && state!=IDLE && state!=CFG_REPLY && state!=REPLY && state!=QUARANTINE &&
               state!=MEM_REQUEST && state!=MEM_WAIT && state!=FILL_INSTALL && state!=WORD_CAPTURE && state!=WB_CAPTURE &&
               !(state==CLAIM && claim_ready))begin faulted<=1;reply(0,0,1);rsp_aborted<=1;end
            else case(state)
            IDLE:begin
                if(cfg_valid && cfg_ready)begin
                    base<=cfg_base;job_id<=cfg_job_id;cfg_rsp_error<=!cfg_legal;
                    configured<=cfg_legal;faulted<=0;abort_sticky<=0;
                    for(integer w=0;w<4;w++)for(integer s=0;s<8;s++)begin valid[w][s]<=0;dirty[w][s]<=0;end
                    for(integer s=0;s<8;s++)plru[s]<=0;
                    state<=CFG_REPLY;
                end else if(req_valid && req_ready)begin
                    operation<=req_op;index<=req_index;flush_mode<=req_op==3;
                    if(req_op==3)begin
                        if(req_index!=0)reply(0,0,1);
                        else if(faulted || abort_requested)begin
                            configured<=0;
                            for(integer w=0;w<4;w++)for(integer s=0;s<8;s++)begin valid[w][s]<=0;dirty[w][s]<=0;end
                            reply(0,0,1);rsp_aborted<=abort_requested;
                        end
                        else begin flush_position<=0;state<=FLUSH_SCAN;end
                    end else if(req_index>=21'(N) || faulted || abort_requested)begin reply(0,0,1);rsp_aborted<=abort_requested;end
                    else state<=LOOKUP;
                end
            end
            CFG_REPLY:if(cfg_rsp_ready)state<=IDLE;
            LOOKUP:begin
                selected_set<=index[10:8];requested_tag<=index[20:11];
                if(hit_count>1)begin faulted<=1;reply(0,0,1);end
                else if(hit_count==1)begin selected_way<=hit_way;touch(index[10:8],hit_way);state<=WORD_READ;end
                else begin
                    selected_way<=victim_way;
                    if(valid[victim_way][index[10:8]] && dirty[victim_way][index[10:8]])begin transfer_word<=0;state<=WB_READ;end
                    else begin valid[victim_way][index[10:8]]<=0;start_line(0,index[20:8]);end
                end
            end
            WORD_READ:state<=WORD_CAPTURE;
            WORD_CAPTURE:begin old_word<=selected_data_q;state<=CHECK;end
            CHECK:if((operation==1 && old_state==2) || (operation==2 && old_state==1))state<=CLAIM;
                else reply(old_state,0,0);
            CLAIM:if(claim_ready)begin dirty[selected_way][selected_set]<=1;reply(old_state,1,0);end
            REPLY:if(rsp_ready)state<=IDLE;
            WB_READ:state<=WB_CAPTURE;
            WB_CAPTURE:begin
                if(abort_requested)begin faulted<=1;reply(0,0,1);rsp_aborted<=1;end
                else if(transfer_word==31)start_line(1,{selected_tag,selected_set[2:0]});
                else begin transfer_word<=transfer_word+5'd1;state<=WB_READ;end
            end
            MEM_REQUEST:if(line_req_ready)state<=MEM_WAIT;
            MEM_WAIT:if(line_rsp_valid)begin
                if(!line_drained)state<=QUARANTINE;
                else if(line_error)begin faulted<=1;reply(0,0,1);end
                else if(abort_requested)begin faulted<=1;reply(0,0,1);rsp_aborted<=1;end
                else if(line_write)begin
                    dirty[selected_way][selected_set]<=0;
                    if(flush_mode)next_flush();
                    else begin valid[selected_way][selected_set]<=0;start_line(0,{requested_tag,selected_set[2:0]});end
                end else begin transfer_word<=0;state<=FILL_INSTALL;end
            end
            FILL_INSTALL:if(line_rsp_valid)begin
                if(!line_drained)state<=QUARANTINE;
                else if(line_error)begin faulted<=1;reply(0,0,1);end
                else if(abort_requested)begin faulted<=1;reply(0,0,1);rsp_aborted<=1;end
                else if(transfer_word==31)begin
                    valid[selected_way][selected_set]<=1;
                    dirty[selected_way][selected_set]<=0;touch(selected_set,selected_way);state<=WORD_READ;
                end else transfer_word<=transfer_word+5'd1;
            end
            FLUSH_SCAN:begin
                selected_set<=flush_position[4:2];selected_way<=flush_position[1:0];
                if(valid[flush_position[1:0]][flush_position[4:2]] && dirty[flush_position[1:0]][flush_position[4:2]])begin
                    transfer_word<=0;state<=WB_READ;
                end else next_flush();
            end
            QUARANTINE:begin end // 保留旧上下文；只有外部证明安全的共同rst允许恢复。
            default:begin faulted<=1;reply(0,0,1);end
            endcase
        end
    end
endmodule
