// WQ01…05：N容量FIFO，claim实际追加，push仅确认；外存64B RPC不撤销。
module canny_work_queue #(
    parameter integer unsigned WIDTH=1920,HEIGHT=1080,
    parameter bit RAM_CARRY=1'b0,DSP_WRITER=1'b0
)(
    input logic clk,rst,
    input logic cfg_valid,output wire cfg_ready,input logic [31:0] cfg_base,input logic [63:0] cfg_job_id,
    output logic cfg_rsp_valid,input logic cfg_rsp_ready,output logic cfg_rsp_error,
    input logic claim_valid,output wire claim_ready,input logic [20:0] claim_index,
    input logic queue_req_valid,output wire queue_req_ready,input logic queue_push,input logic [20:0] queue_index,
    output wire queue_rsp_valid,input logic queue_rsp_ready,output logic [20:0] queue_rsp_index,
    output logic queue_rsp_error,queue_rsp_aborted,
    input logic seal_valid,output wire seal_ready,input logic seal_end_job,input logic [63:0] seal_job_id,
    output logic seal_rsp_valid,input logic seal_rsp_ready,output logic seal_rsp_error,seal_rsp_drained,
    output logic [21:0] seal_rsp_head,seal_rsp_tail,seal_rsp_committed,
    input logic abort_private_valid,input logic [63:0] abort_job_id,
    output wire line_req_valid,input logic line_req_ready,output logic line_write,
    output logic [31:0] line_addr,output logic [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained,output wire quarantined,output wire [63:0] active_job_id
);
    localparam integer unsigned N=WIDTH*HEIGHT;
    localparam logic [32:0] ALLOCATION=33'(((N+15)/16)*64);
    typedef enum logic [2:0] {B_FREE,B_INIT,B_OPEN,B_SEALED,B_WRITING,B_RETIRE} bank_t;
    typedef enum logic [2:0] {W_IDLE,W_GATHER,W_REQUEST,W_WAIT,W_RETIRE} writer_t;
    typedef enum logic [2:0] {P_IDLE,P_REQUEST,P_WAIT,P_INSTALL} prefetch_t;
    typedef enum logic [2:0] {C_IDLE,C_FORWARD,C_FORWARD_CAPTURE,C_PREFETCH,C_READ,C_CAPTURE,C_REPLY} consumer_t;
    typedef enum logic [1:0] {M_IDLE,M_REQUEST,M_WAIT,M_QUARANTINE} memory_t;
    bank_t bank_state[0:1];
    writer_t writer;
    prefetch_t prefetch;
    consumer_t consumer;
    memory_t memory_state;
    logic configured,faulted,abort_sticky;
    logic [31:0] base;
    logic [63:0] job_id;
    logic [21:0] head,tail,committed;
    logic [21:0] bank_base[0:1],bank_start[0:1],bank_end[0:1];
    logic [3:0] init_lane[0:1];
    wire [20:0] carry_prefix;
    logic confirm_pending;
    logic [20:0] confirm_index;
    logic reply_is_pop,reply_confirms;
    logic seal_pending,seal_closes;
    logic [21:0] pop_position,pop_commit_snapshot;
    logic pop_bank;
    logic [7:0] pop_slot;
    logic writer_bank;
    logic [21:0] writer_block;
    logic [3:0] writer_lane;
    logic [335:0] writer_buffer;
    logic prefetch_valid;
    logic [21:0] prefetch_start,prefetch_end,prefetch_block;
    logic [3:0] install_lane;
    logic memory_owner,mem_turn,append_turn;
    logic ap_pending,ap_owner,ap_bank;
    logic [3:0] ap_lane;
    logic [31:0] append_q,prefetch_q;
    logic ap_re,ap_we,pf_re,pf_we;
    logic [8:0] ap_ra,ap_wa,pf_ra,pf_wa;
    logic [31:0] ap_data,pf_data;
    logic open_found,open_bank,init_found,init_bank,free_found,free_bank;
    logic owner_found,owner_bank;
    logic writer_eligible,forward_eligible,ap_grant,ap_grant_owner,ap_grant_bank;
    logic [8:0] ap_grant_address;
    logic earliest_found,earliest_bank;
    wire [4:0] carry_lane=5'd16-{1'b0,tail[3:0]}+{1'b0,init_lane[init_bank]};
    wire matching_abort=abort_private_valid && configured && abort_job_id==job_id;
    wire stopping=abort_sticky || matching_abort || faulted;
    wire memory_reply=memory_state==M_WAIT && line_rsp_valid && line_rsp_ready;
    wire real_memory_error=memory_reply && line_error;
    wire claim_fire=claim_valid && claim_ready;
    wire [32:0] cfg_end={1'b0,cfg_base}+ALLOCATION;
    wire cfg_legal=cfg_base[5:0]==0 && cfg_end<=33'h100000000;
    assign cfg_ready=!rst && !configured && !cfg_rsp_valid && !seal_rsp_valid && !seal_pending &&
                     consumer==C_IDLE && memory_state==M_IDLE && !ap_pending;
    // 同沿matching_abort不拆已经能够fire的cache/queue配对；下一拍sticky禁新claim。
    assign claim_ready=!rst && configured && !faulted && !abort_sticky && !cfg_rsp_valid &&
                       !seal_valid && !seal_pending && !seal_rsp_valid && open_found && !confirm_pending &&
                       consumer==C_IDLE && tail<22'(N) && claim_index<21'(N);
    assign queue_req_ready=!rst && configured && !cfg_rsp_valid && consumer==C_IDLE &&
                           !seal_rsp_valid && memory_state!=M_QUARANTINE;
    assign queue_rsp_valid=!rst && consumer==C_REPLY;
    assign seal_ready=!rst && configured && !cfg_rsp_valid && !seal_pending && !seal_rsp_valid &&
                      memory_state!=M_QUARANTINE;
    assign line_req_valid=!rst && memory_state==M_REQUEST;
    // 实际物理服务保持读回复；16个字全部安装后才消费，省掉第二份512位读快照。
    assign line_rsp_ready=!rst && memory_state==M_WAIT &&
        (memory_owner || stopping || line_error || !line_drained ||
         (prefetch==P_INSTALL && install_lane==15));
    for(genvar w=0;w<16;w++)begin:published_queue_word
        assign line_wdata[w*32+:32]=line_write?{11'd0,writer_buffer[w*21+:21]}:32'd0;
    end
    assign quarantined=memory_state==M_QUARANTINE;
    assign active_job_id=job_id;
    initial if(WIDTH<6 || WIDTH>1920 || WIDTH%2!=0 || HEIGHT<5 || HEIGHT>1080)
        $fatal(1,"Unsupported work queue geometry");

    queue_ram16_1r1w append_lo(.clk(clk),.re(ap_re),.we(ap_we),.read_address(ap_ra),.write_address(ap_wa),.data(ap_data[15:0]),.q(append_q[15:0]));
    queue_ram16_1r1w append_hi(.clk(clk),.re(ap_re),.we(ap_we),.read_address(ap_ra),.write_address(ap_wa),.data(ap_data[31:16]),.q(append_q[31:16]));
    queue_ram16_1r1w prefetch_lo(.clk(clk),.re(pf_re),.we(pf_we),.read_address(pf_ra),.write_address(pf_wa),.data(pf_data[15:0]),.q(prefetch_q[15:0]));
    queue_ram16_1r1w prefetch_hi(.clk(clk),.re(pf_re),.we(pf_we),.read_address(pf_ra),.write_address(pf_wa),.data(pf_data[31:16]),.q(prefetch_q[31:16]));

    if(RAM_CARRY)begin:carry_ring
        wire [31:0] history_q;
        wire [31:0] history_data={11'd0,claim_index};
        // 创建B_INIT的沿先读prefix[0]；下一沿直接安装，保持原每拍一字的节奏。
        wire first_read=!rst&&configured&&!cfg_rsp_valid&&!stopping&&!seal_pending&&!seal_rsp_valid&&
            !open_found&&!init_found&&free_found&&tail<22'(N)&&tail[3:0]!=0;
        wire prefix_write=!rst&&!claim_fire&&init_found&&!stopping&&!seal_pending&&!seal_rsp_valid;
        wire next_read=prefix_write&&(init_lane[init_bank]+4'd1!=tail[3:0]);
        wire history_re=first_read||next_read;
        wire [3:0] history_lane=first_read?4'd0:init_lane[init_bank]+4'd1;
        wire [8:0] history_ra={5'd0,history_lane};
        wire [8:0] history_wa={5'd0,tail[3:0]};
        // matching_abort同沿的已配对claim仍要存入历史；不额外用stopping禁写。
        wire history_we=!rst&&claim_fire;
        // 只用16个环地址；复用已推断为RAM的512x16模板，高11位恒0。
        queue_ram16_1r1w history_lo(.clk(clk),.re(history_re),.we(history_we),
            .read_address(history_ra),.write_address(history_wa),.data(history_data[15:0]),.q(history_q[15:0]));
        queue_ram16_1r1w history_hi(.clk(clk),.re(history_re),.we(history_we),
            .read_address(history_ra),.write_address(history_wa),.data(history_data[31:16]),.q(history_q[31:16]));
        // RE为0时q保持：seal回复暂停或stopping不能覆盖已预读的下一项。
        assign carry_prefix=history_q[20:0];
    end else begin:carry_shift
        logic [335:0] carry;
        always_ff @(posedge clk)if(!rst&&claim_fire)carry<={claim_index,carry[335:21]};
        assign carry_prefix=carry[carry_lane*21+:21];
    end

    generate if(DSP_WRITER)begin:dsp_writer
        // 原预约归还或尾块补零才推进21位；完整336位分成10个36位字，最上24位补零。
        wire return_capture=!rst&&ap_pending&&ap_owner&&!stopping;
        wire padding_capture=!rst&&writer==W_GATHER&&!stopping&&!ap_pending&&
            writer_block+{18'd0,writer_lane}>=bank_end[writer_bank];
        wire writer_capture=return_capture||padding_capture;
        wire [335:0] next_writer_buffer={padding_capture?21'd0:append_q[20:0],writer_buffer[335:21]};
        wire [359:0] padded_writer_buffer={24'd0,next_writer_buffer};
        for(genvar word=0;word<10;word++)begin:words
            wire [35:0] input_word=padded_writer_buffer[word*36+:36];
            wire [47:0] stored_word;
            // (高19位 << 17) + 低17位无重叠，只有O寄存器在原写沿捕获。
            EFX_DSP48 #(.MODE("NORMAL"),.SIGNED(1'b0),
                .A_REG(1'b0),.B_REG(1'b0),.C_REG(1'b0),.P_REG(1'b0),.OP_REG(1'b0),
                .W_REG(1'b0),.O_REG(1'b1),.SHIFTER(1'b0),.RST_SYNC(1'b1),
                .P_EXT("ALIGN_RIGHT"),.C_EXT("ALIGN_RIGHT"),
                .M_SEL("P"),.N_SEL("C"),.W_SEL("X"),
                .O_REG_USE_CE(1'b1),.O_REG_USE_RST(1'b0)) storage(
                .A(input_word[35:17]),.B(18'h20000),.C({1'b0,input_word[16:0]}),
                .CASCIN(48'd0),.OP(2'd0),.SHIFT_ENA(1'b0),
                .CLK(clk),.CE(writer_capture),.RST(1'b0),.O(stored_word),.CASCOUT(),.OVFL());
            if(word==9)begin:tail_word
                assign writer_buffer[335:324]=stored_word[11:0];
            end else begin:full_word
                assign writer_buffer[word*36+:36]=stored_word[35:0];
            end
        end
    end else begin:ff_writer
        // 默认仍为原336位FF：不复位正文，两个原写入条件和优先次序保留。
        always_ff @(posedge clk)if(!rst)begin
            if(ap_pending&&ap_owner&&!stopping)
                writer_buffer<={append_q[20:0],writer_buffer[335:21]};
            if(writer==W_GATHER&&!stopping&&!ap_pending&&
               writer_block+{18'd0,writer_lane}>=bank_end[writer_bank])
                writer_buffer<={21'd0,writer_buffer[335:21]};
        end
    end endgenerate

    always_comb begin
        open_found=0;open_bank=0;init_found=0;init_bank=0;free_found=0;free_bank=0;
        owner_found=0;owner_bank=0;earliest_found=0;earliest_bank=0;
        for(integer b=0;b<2;b++)begin
            if(bank_state[b]==B_OPEN)begin open_found=1;open_bank=1'(b);end
            if(bank_state[b]==B_INIT)begin init_found=1;init_bank=1'(b);end
            if(bank_state[b]==B_FREE && !free_found)begin free_found=1;free_bank=1'(b);end
            if(bank_state[b]!=B_FREE && bank_state[b]!=B_INIT && head>=bank_start[b] && head<bank_end[b])begin owner_found=1;owner_bank=1'(b);end
            if(bank_state[b]==B_SEALED && bank_start[b]==committed)begin earliest_found=1;earliest_bank=1'(b);end
        end
        writer_eligible=writer==W_GATHER && !ap_pending && !stopping &&
                        writer_block+{18'd0,writer_lane}<bank_end[writer_bank];
        forward_eligible=consumer==C_FORWARD && !ap_pending && !stopping;
        ap_grant=writer_eligible || forward_eligible;
        ap_grant_owner=writer_eligible && (!forward_eligible || !append_turn); // 1=assembler
        ap_grant_bank=ap_grant_owner ? writer_bank : pop_bank;
        ap_grant_address=ap_grant_owner ?
            {writer_bank,8'(writer_block+{18'd0,writer_lane}-bank_base[writer_bank])} : {pop_bank,pop_slot};
        ap_re=!rst && ap_grant;ap_ra=ap_grant_address;
        ap_we=0;ap_wa=0;ap_data=0;
        if(!rst && claim_fire)begin
            ap_we=1;ap_wa={open_bank,8'(tail-bank_base[open_bank])};ap_data={11'd0,claim_index};
        end else if(!rst && init_found && !stopping && !seal_pending && !seal_rsp_valid)begin
            ap_we=1;ap_wa={init_bank,4'd0,init_lane[init_bank]};ap_data={11'd0,carry_prefix};
        end
        pf_re=!rst && consumer==C_READ && !stopping;
        pf_ra=9'(pop_position-prefetch_start);
        pf_we=!rst && prefetch==P_INSTALL && !stopping && line_rsp_valid && line_drained && !line_error;
        pf_wa=9'(prefetch_block+{18'd0,install_lane}-prefetch_start);
        pf_data=line_rdata[install_lane*32+:32];
    end

    task automatic reply(input logic [20:0] value,input logic error_value,input logic aborted_value,
                         input logic is_pop,input logic confirms);
        begin
            queue_rsp_index<=value;queue_rsp_error<=error_value;queue_rsp_aborted<=aborted_value;
            reply_is_pop<=is_pop;reply_confirms<=confirms;consumer<=C_REPLY;
        end
    endtask
    task automatic seal_reply(input logic error_value,input logic closes,input logic drained_value=1);
        begin
            seal_rsp_valid<=1;seal_rsp_error<=error_value;seal_rsp_drained<=drained_value;
            seal_rsp_head<=head;seal_rsp_tail<=tail;seal_rsp_committed<=committed;
            seal_pending<=0;
            if(closes)begin
                configured<=0;prefetch_valid<=0;confirm_pending<=0;
                for(integer b=0;b<2;b++)bank_state[b]<=B_FREE;
            end
        end
    endtask
    always_ff @(posedge clk)begin
        if(rst)begin
            configured<=0;faulted<=0;abort_sticky<=0;base<=0;job_id<=0;head<=0;tail<=0;committed<=0;
            cfg_rsp_valid<=0;cfg_rsp_error<=0;seal_rsp_valid<=0;seal_rsp_error<=0;seal_rsp_drained<=0;
            seal_rsp_head<=0;seal_rsp_tail<=0;seal_rsp_committed<=0;seal_pending<=0;seal_closes<=0;
            confirm_pending<=0;confirm_index<=0;
            writer<=W_IDLE;prefetch<=P_IDLE;consumer<=C_IDLE;memory_state<=M_IDLE;
            prefetch_valid<=0;prefetch_start<=0;prefetch_end<=0;prefetch_block<=0;install_lane<=0;
            writer_bank<=0;writer_block<=0;writer_lane<=0;
            pop_position<=0;pop_commit_snapshot<=0;pop_bank<=0;pop_slot<=0;
            ap_pending<=0;ap_owner<=0;ap_bank<=0;ap_lane<=0;append_turn<=0;mem_turn<=0;memory_owner<=0;
            line_write<=0;line_addr<=0;
            queue_rsp_index<=0;queue_rsp_error<=0;queue_rsp_aborted<=0;reply_is_pop<=0;reply_confirms<=0;
            for(integer b=0;b<2;b++)begin bank_state[b]<=B_FREE;bank_base[b]<=0;bank_start[b]<=0;bank_end[b]<=0;init_lane[b]<=0;end
        end else begin
            if(cfg_rsp_valid && cfg_rsp_ready)cfg_rsp_valid<=0;
            if(seal_rsp_valid && seal_rsp_ready)seal_rsp_valid<=0;
            if(matching_abort)abort_sticky<=1;
            if(cfg_valid && cfg_ready)begin
                base<=cfg_base;job_id<=cfg_job_id;configured<=cfg_legal;cfg_rsp_valid<=1;cfg_rsp_error<=!cfg_legal;
                faulted<=0;abort_sticky<=0;head<=0;tail<=0;committed<=0;confirm_pending<=0;
                prefetch_valid<=0;writer<=W_IDLE;prefetch<=P_IDLE;
                for(integer b=0;b<2;b++)bank_state[b]<=B_FREE;
            end

            // WQ03：仅一个OPEN/INIT；prefix写不算新增entry，不能借初始化RAM内容。
            if(configured && !cfg_rsp_valid && !stopping && !seal_pending && !seal_rsp_valid)begin
                if(!open_found && !init_found && free_found && tail<22'(N))begin
                    bank_base[free_bank]<={tail[21:4],4'd0};bank_start[free_bank]<=tail;bank_end[free_bank]<=tail;
                    init_lane[free_bank]<=0;bank_state[free_bank]<=tail[3:0]==0 ? B_OPEN : B_INIT;
                end
                if(init_found)begin
                    if(init_lane[init_bank]+4'd1==tail[3:0])bank_state[init_bank]<=B_OPEN;
                    else init_lane[init_bank]<=init_lane[init_bank]+4'd1;
                end
            end
            if(claim_fire)begin
                tail<=tail+22'd1;bank_end[open_bank]<=tail+22'd1;confirm_pending<=1;confirm_index<=claim_index;
                // 历史保留最新16条；INIT仅读取当前prefix对应的最后tail%16条。
                if(8'(tail-bank_base[open_bank])==8'd255)bank_state[open_bank]<=B_SEALED;
            end
            if(seal_valid && seal_ready)begin
                if(seal_job_id!=job_id)seal_reply(1,0,0);
                else if(seal_end_job && !stopping && (head!=tail || confirm_pending || consumer!=C_IDLE || claim_fire))seal_reply(1,0,0);
                else begin
                    seal_pending<=1;seal_closes<=seal_end_job;
                    for(integer b=0;b<2;b++)begin
                        if(bank_state[b]==B_OPEN)bank_state[b]<=bank_end[b]>bank_start[b] ? B_SEALED : B_FREE;
                        if(bank_state[b]==B_INIT)bank_state[b]<=B_FREE;
                    end
                end
            end

            // 同步RAM返回：先完成旧预约，再处理本拍的新预约。
            if(ap_pending)begin
                ap_pending<=0;
                if(ap_owner)begin
                    if(!stopping)begin
                        if(ap_lane==15)writer<=W_REQUEST;else writer_lane<=ap_lane+4'd1;
                    end
                end else begin
                    if(real_memory_error || faulted)reply(0,1,0,0,0);
                    else if(stopping)reply(0,1,1,0,0);
                    else if(append_q[31:21]!=0 || append_q[20:0]>=21'(N))begin faulted<=1;reply(0,1,0,0,0);end
                    else reply(append_q[20:0],0,0,1,0);
                end
            end
            if(ap_grant)begin
                ap_pending<=1;ap_owner<=ap_grant_owner;ap_bank<=ap_grant_bank;ap_lane<=writer_lane;
                append_turn<=ap_grant_owner;
                if(!ap_grant_owner)consumer<=C_FORWARD_CAPTURE;
            end

            case(consumer)
                C_IDLE:if(queue_req_valid && queue_req_ready)begin
                    if(faulted || real_memory_error)reply(0,1,0,0,0);
                    else if(stopping)reply(0,1,1,0,0);
                    else if(queue_push)begin
                        if(confirm_pending && queue_index==confirm_index)reply(confirm_index,0,0,0,1);
                        else reply(0,1,0,0,0);
                    end else if(confirm_pending || head==tail)reply(0,1,0,0,0);
                    else begin
                        pop_position<=head;pop_commit_snapshot<=committed;
                        if(head>=committed)begin
                            if(!owner_found)begin faulted<=1;reply(0,1,0,0,0);end
                            else begin pop_bank<=owner_bank;pop_slot<=8'(head-bank_base[owner_bank]);consumer<=C_FORWARD;end
                        end else if(prefetch_valid && head>=prefetch_start && head<prefetch_end)consumer<=C_READ;
                        else begin
                            prefetch_valid<=0;prefetch_start<={head[21:4],4'd0};
                            prefetch_end<=committed<({head[21:4],4'd0}+22'd512) ? committed : ({head[21:4],4'd0}+22'd512);
                            prefetch_block<={head[21:4],4'd0};prefetch<=P_REQUEST;consumer<=C_PREFETCH;
                        end
                    end
                end
                C_READ:if(!stopping)consumer<=C_CAPTURE;
                C_CAPTURE:begin
                    if(faulted || real_memory_error)reply(0,1,0,0,0);
                    else if(stopping)reply(0,1,1,0,0);
                    else if(prefetch_q[31:21]!=0 || prefetch_q[20:0]>=21'(N))begin faulted<=1;reply(0,1,0,0,0);end
                    else reply(prefetch_q[20:0],0,0,1,0);
                end
                C_REPLY:if(queue_rsp_ready)begin
                    if(reply_is_pop && !queue_rsp_error)head<=head+22'd1;
                    if(reply_confirms && !queue_rsp_error)confirm_pending<=0;
                    consumer<=C_IDLE;
                end
                default:begin end
            endcase

            case(writer)
                W_IDLE:if(earliest_found && !stopping)begin
                    writer_bank<=earliest_bank;writer_block<=bank_base[earliest_bank];writer_lane<=0;
                    bank_state[earliest_bank]<=B_WRITING;writer<=W_GATHER;
                end
                W_GATHER:if(!stopping && !ap_pending && writer_block+{18'd0,writer_lane}>=bank_end[writer_bank])begin
                    if(writer_lane==15)writer<=W_REQUEST;else writer_lane<=writer_lane+4'd1;
                end
                W_RETIRE:if(!(ap_pending && ap_bank==writer_bank) &&
                              !(consumer==C_FORWARD && pop_bank==writer_bank) &&
                              !(ap_grant && ap_grant_bank==writer_bank))begin bank_state[writer_bank]<=B_FREE;writer<=W_IDLE;end
                default:begin end
            endcase
            if(memory_state==M_WAIT && !memory_owner && prefetch==P_WAIT &&
               line_rsp_valid && line_drained && !line_error && !stopping)begin
                install_lane<=0;prefetch<=P_INSTALL;
            end
            if(prefetch==P_INSTALL && !stopping && line_rsp_valid && line_drained && !line_error)begin
                if(install_lane==15)begin
                    if(prefetch_block+22'd16>=prefetch_end)begin prefetch<=P_IDLE;prefetch_valid<=1;consumer<=C_READ;end
                    else begin prefetch_block<=prefetch_block+22'd16;prefetch<=P_REQUEST;end
                end else install_lane<=install_lane+4'd1;
            end

            // 共享64B口：保存owner后才公开valid；data/addr直到回执都不变。
            case(memory_state)
                M_IDLE:if(!stopping && (writer==W_REQUEST || prefetch==P_REQUEST))begin
                    if(writer==W_REQUEST && (prefetch!=P_REQUEST || !mem_turn))begin
                        memory_owner<=1;line_write<=1;line_addr<=32'({1'b0,base}+({11'd0,writer_block}<<2));
                        writer<=W_WAIT;mem_turn<=1;
                    end else begin
                        memory_owner<=0;line_write<=0;line_addr<=32'({1'b0,base}+({11'd0,prefetch_block}<<2));
                        prefetch<=P_WAIT;mem_turn<=0;
                    end
                    memory_state<=M_REQUEST;
                end
                M_REQUEST:if(line_req_ready)memory_state<=M_WAIT;
                M_WAIT:if(memory_reply)begin
                    if(!line_drained)begin faulted<=1;memory_state<=M_QUARANTINE;end
                    else begin
                        memory_state<=M_IDLE;
                        if(line_error)begin
                            faulted<=1;writer<=W_IDLE;prefetch<=P_IDLE;prefetch_valid<=0;
                            if(consumer!=C_IDLE && consumer!=C_REPLY && consumer!=C_FORWARD_CAPTURE && consumer!=C_CAPTURE)reply(0,1,0,0,0);
                        end else if(!stopping && memory_owner)begin
                            if(writer_block+22'd16>=bank_end[writer_bank])begin
                                committed<=bank_end[writer_bank];bank_state[writer_bank]<=B_RETIRE;writer<=W_RETIRE;
                            end else begin writer_block<=writer_block+22'd16;writer_lane<=0;writer<=W_GATHER;end
                        end else if(stopping)begin writer<=W_IDLE;prefetch<=P_IDLE;end
                    end
                end
                default:begin end
            endcase

            // 私有取消只清内部预约；held回复/已提出RPC均等待真实交付。
            if(stopping)begin
                prefetch_valid<=0;confirm_pending<=0;
                if(writer!=W_WAIT || memory_state==M_IDLE)writer<=W_IDLE;
                if(prefetch!=P_WAIT || memory_state==M_IDLE)prefetch<=P_IDLE;
                if(consumer==C_FORWARD || consumer==C_PREFETCH || consumer==C_READ)
                    reply(0,1,!faulted && !real_memory_error,0,0);
            end
            if(seal_pending && memory_state==M_IDLE && !ap_pending && consumer==C_IDLE &&
               !confirm_pending && writer==W_IDLE && prefetch==P_IDLE)begin
                if(stopping)seal_reply(1,seal_closes);
                else if(committed==tail)seal_reply(0,seal_closes);
            end
        end
    end
endmodule
