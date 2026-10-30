// 256 direct-mapped 64-byte lines: 16 KiB / 65536 two-bit pixel states.
// Full-HD state backing and the full-frame queue remain in DDR unchanged.
// index[15:8] selects a line; index[20:16] is its tag. Dirty conflicts
// write back before replacement. RAM is 8192x16, still synchronous.
// Larger residency changes hit rate only; every 64-byte RPC must drain.
module canny_state_cache_reference #(
    parameter integer unsigned WIDTH=1920,HEIGHT=1080,CLAIM_STRONG_NEIGHBORS=0
)(
    input logic clk,rst,
    input logic cfg_valid,output wire cfg_ready,input logic [31:0] cfg_base,input logic [63:0] cfg_job_id,
    output wire cfg_rsp_valid,input logic cfg_rsp_ready,output logic cfg_rsp_error,
    input logic abort_private_valid,input logic [63:0] abort_job_id,
    input logic req_valid,output wire req_ready,input logic [1:0] req_op,input logic [20:0] req_index,
    output wire rsp_valid,input logic rsp_ready,output logic [1:0] rsp_old,output logic rsp_claimed,rsp_error,rsp_aborted,
    // Pre-claim word snapshot for successful op0/1/2 replies, held until
    // rsp_ready. old_word is loaded on both recent-hit and RAM-capture paths.
    // Claim writes RAM/recent_word but preserves old_word; rsp_claimed identifies
    // the only changed lane. Error/abort/flush replies do NOT promise word data.
    output wire [15:0] rsp_word,
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
    logic [4:0] tags[0:255];
    logic valid[0:255],dirty[0:255];
    logic [1:0] operation;
    logic [20:0] index;
    logic [7:0] selected_set;
    logic [4:0] transfer_word;
    logic [4:0] requested_tag;
    logic [15:0] old_word;
    // One-word forwarding buffer: eight 2-bit states. The sole requester
    // serializes every operation, so a resident word cannot change behind us.
    // Claims write both RAM and this copy on the SAME claim_ready handshake.
    // Invalidate before any miss eviction, flush, reconfiguration or abort.
    // Read-only linear scans predict the next 16-bit word IN THIS cache line.
    // The single-port RAM read is issued only when a successful op0 response
    // is consumed. Its registered q remains stable until the next RAM access.
    // Any accepted request invalidates the prediction; mutations never use it.
    // No DDR prefetch, new owner, speculative claim or additional RAM is added.
    logic lookahead_valid;
    logic [17:0] lookahead_index;
    wire lookahead_hit=lookahead_valid && req_op==0 && req_index[20:3]==lookahead_index;
    wire abort_requested;
    wire issue_lookahead=state==REPLY && rsp_ready && operation==0 &&
        !rsp_error && !rsp_aborted && !faulted && !abort_requested &&
        index[7:3]!=31 && ({1'b0,index[20:3],3'b000}+22'd8)<22'(N);
    logic recent_valid;
    logic [17:0] recent_index;
    logic [15:0] recent_word;
    wire [1:0] recent_state=recent_word[{req_index[2:0],1'b0}+:2];
    wire [511:0] line_buffer;
    logic flush_mode;
    logic [7:0] flush_position;
    logic [15:0] ram_q;
    logic ram_re,ram_we;
    logic [12:0] ram_address;
    logic [15:0] ram_data;
    wire [1:0] captured_state=ram_q[{index[2:0],1'b0}+:2];
    logic [15:0] claimed_word;
    wire [32:0] cfg_end={1'b0,cfg_base}+ALLOCATION;
    wire cfg_legal=cfg_base[5:0]==0 && cfg_end<=33'h100000000;
    wire matching_abort=abort_private_valid && configured && abort_job_id==job_id;
    assign abort_requested=abort_sticky || matching_abort;
    wire recent_hit=recent_valid && recent_index==req_index[20:3];
    wire resident_hit=valid[req_index[15:8]] && tags[req_index[15:8]]==req_index[20:16];
    // A successful resident request reserves its synchronous RAM read on
    // the acceptance edge. There is only one requester and no concurrent writer.
    wire accept_resident_read=state==IDLE && req_valid && req_ready && req_op!=3 &&
        req_index<21'(N) && !faulted && !abort_requested && !recent_hit && !lookahead_hit && resident_hit;
    assign cfg_ready=!rst && state==IDLE && !configured;
    assign cfg_rsp_valid=!rst && state==CFG_REPLY;
    assign req_ready=!rst && state==IDLE && configured;
    assign rsp_valid=!rst && state==REPLY;
    assign rsp_word=old_word;
    assign claim_valid=!rst && state==CLAIM;
    assign claim_index=index;
    assign line_req_valid=!rst && state==MEM_REQUEST;
    assign line_rsp_ready=!rst && state==MEM_WAIT;
    assign line_wdata=line_buffer;
    assign quarantined=state==QUARANTINE;
    assign active_job_id=job_id;
    initial if(WIDTH<6 || WIDTH>1920 || WIDTH%2!=0 || HEIGHT<5 || HEIGHT>1080)
        $fatal(1,"Unsupported state cache geometry");

    state_cache_ram16 #(.ADDR_WIDTH(13)) storage(.clk(clk),.re(ram_re),.we(ram_we),
        .address(ram_address),.data(ram_data),.q(ram_q));
    always_comb begin
        claimed_word=old_word;claimed_word[{index[2:0],1'b0}+:2]=2'b11;
        ram_re=0;ram_we=0;
        ram_address={selected_set,index[7:3]};ram_data=claimed_word;
        if(!rst)case(state)
            IDLE:if(accept_resident_read)begin ram_re=1;ram_address=req_index[15:3];end
            REPLY:if(issue_lookahead)begin
                ram_re=1;ram_address={selected_set,5'(index[7:3]+5'd1)};
            end
            WORD_READ:if(!abort_requested)ram_re=1;
            WB_READ:begin ram_address={selected_set,transfer_word};if(!abort_requested)ram_re=1;end
            // WB_READ primes word0. Each following capture consumes ram_q
            // from the preceding edge while issuing the next synchronous read.
            WB_CAPTURE:if(transfer_word!=31 && !abort_requested)begin
                ram_address={selected_set,5'(transfer_word+5'd1)};ram_re=1;
            end
            FILL_INSTALL:begin
                ram_address={selected_set,transfer_word};ram_data=line_buffer[15:0];
                if(!abort_requested)ram_we=1;
            end
            CLAIM:if(claim_ready)ram_we=1;
            default:begin end
        endcase
    end
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
            for(integer s=0;s<256;s++)begin valid[s]<=0;dirty[s]<=0;end
            configured<=0;reply(0,0,faulted);
        end
    endtask
    task automatic next_flush;
        begin
            if(flush_position==255)finish_flush();
            else begin flush_position<=flush_position+8'd1;state<=FLUSH_SCAN;end
        end
    endtask
    wire line_gather=state==WB_CAPTURE;
    wire line_install=state==FILL_INSTALL&&!abort_requested;
    wire line_load=state==MEM_WAIT&&line_rsp_valid&&line_rsp_ready&&line_drained&&!line_error&&!abort_requested&&!line_write;
    wire [511:0] line_next=line_load?line_rdata:
        line_gather?{ram_q,line_buffer[511:16]}:{16'd0,line_buffer[511:16]};
    // One-clock enabled native storage; public RPC ownership is unchanged.
    // A(19) * 2^17 + C(17) stores 36 unsigned bits exactly.
    wire [539:0] cache_line_holding_in={28'd0,line_next};wire [539:0] cache_line_holding_out;
    assign line_buffer=cache_line_holding_out[511:0];
    for(genvar word_number=0;word_number<15;word_number++)begin:cache_line_holding
        wire [35:0] data_word=cache_line_holding_in[word_number*36+:36];wire [47:0] held;
        EFX_DSP48 #(.SIGNED(0),.O_REG(1),.RST_SYNC(1),.N_SEL("C")) storage(
            .A(data_word[35:17]),.B(18'h20000),.C({1'b0,data_word[16:0]}),.CASCIN(48'd0),
            .OP(2'b00),.SHIFT_ENA(1'b0),.CLK(clk),.CE(line_gather||line_install||line_load),.RST(rst),
            .O(held),.CASCOUT(),.OVFL());
        assign cache_line_holding_out[word_number*36+:36]=held[35:0];
    end
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;configured<=0;faulted<=0;abort_sticky<=0;base<=0;job_id<=0;cfg_rsp_error<=0;
            rsp_old<=0;rsp_claimed<=0;rsp_error<=0;rsp_aborted<=0;line_write<=0;line_addr<=0;flush_mode<=0;
            index<=0;selected_set<=0;recent_valid<=0;recent_index<=0;recent_word<=0;lookahead_valid<=0;lookahead_index<=0;
            for(integer s=0;s<256;s++)begin tags[s]<=0;valid[s]<=0;dirty[s]<=0;end
        end else begin
            if(matching_abort)abort_sticky<=1;
            if(abort_requested)begin recent_valid<=0;lookahead_valid<=0;end
            // 公开RPC不撤销；RAM旧预约capture后才终结；held回复也不重写。
            if(abort_requested && state!=IDLE && state!=CFG_REPLY && state!=REPLY && state!=QUARANTINE &&
               state!=MEM_REQUEST && state!=MEM_WAIT && state!=WORD_CAPTURE && state!=WB_CAPTURE &&
               !(state==CLAIM && claim_ready))begin faulted<=1;reply(0,0,1);rsp_aborted<=1;end
            else case(state)
            IDLE:begin
                if(cfg_valid && cfg_ready)begin
                    recent_valid<=0;lookahead_valid<=0;
                    base<=cfg_base;job_id<=cfg_job_id;cfg_rsp_error<=!cfg_legal;
                    configured<=cfg_legal;faulted<=0;abort_sticky<=0;
                    for(integer s=0;s<256;s++)begin valid[s]<=0;dirty[s]<=0;end
                    state<=CFG_REPLY;
                end else if(req_valid && req_ready)begin
                    // Every accepted operation consumes or invalidates q's prediction
                    // before any RAM read/write or flush can change that q.
                    lookahead_valid<=0;
                    operation<=req_op;index<=req_index;flush_mode<=req_op==3;
                    if(req_op==3)begin
                        recent_valid<=0;
                        if(req_index!=0)reply(0,0,1);
                        else if(faulted || abort_requested)begin
                            configured<=0;
                            for(integer s=0;s<256;s++)begin valid[s]<=0;dirty[s]<=0;end
                            reply(0,0,1);rsp_aborted<=abort_requested;
                        end
                        else begin flush_position<=0;state<=FLUSH_SCAN;end
                    end else if(req_index>=21'(N) || faulted || abort_requested)begin reply(0,0,1);rsp_aborted<=abort_requested;end
                    else if(recent_hit)begin
                        selected_set<=req_index[15:8];old_word<=recent_word;
                        if((req_op==1 && recent_state==2) || (req_op==2 && (recent_state==1 || (CLAIM_STRONG_NEIGHBORS && recent_state==2))))state<=CLAIM;
                        else reply(recent_state,0,0);
                    end else if(lookahead_hit)begin
                        // q was loaded on the preceding reply handshake and has
                        // not been overwritten. Read-only request, no claim side effect.
                        selected_set<=req_index[15:8];old_word<=ram_q;
                        recent_word<=ram_q;recent_index<=req_index[20:3];recent_valid<=1;
                        reply(ram_q[{req_index[2:0],1'b0}+:2],0,0);
                    end else if(resident_hit)begin
                        selected_set<=req_index[15:8];state<=WORD_CAPTURE;
                    end else state<=LOOKUP;
                end
            end
            CFG_REPLY:if(cfg_rsp_ready)state<=IDLE;
            LOOKUP:begin
                selected_set<=index[15:8];requested_tag<=index[20:16];
                recent_valid<=0; // New word is not forwarded until RAM capture.
                if(valid[index[15:8]] && tags[index[15:8]]==index[20:16])state<=WORD_READ;
                else if(valid[index[15:8]] && dirty[index[15:8]])begin transfer_word<=0;state<=WB_READ;end
                else begin valid[index[15:8]]<=0;start_line(0,index[20:8]);end
            end
            WORD_READ:state<=WORD_CAPTURE;
            WORD_CAPTURE:begin
                // RAM output belongs to the accepted request from the previous
                // edge. Decode it here; old_word is registered for any later claim.
                old_word<=ram_q;
                recent_word<=ram_q;recent_index<=index[20:3];recent_valid<=!abort_requested;
                if(abort_requested)begin faulted<=1;reply(0,0,1);rsp_aborted<=1;end
                else if((operation==1 && captured_state==2) || (operation==2 && (captured_state==1 || (CLAIM_STRONG_NEIGHBORS && captured_state==2))))state<=CLAIM;
                else reply(captured_state,0,0);
            end
            CLAIM:if(claim_ready)begin
                dirty[selected_set]<=1;reply(old_word[{index[2:0],1'b0}+:2],1,0);
                recent_word<=claimed_word;recent_index<=index[20:3];recent_valid<=!abort_requested;
            end
            REPLY:if(rsp_ready)begin
                state<=IDLE;lookahead_valid<=issue_lookahead;
                if(issue_lookahead)lookahead_index<=index[20:3]+18'd1;
            end
            WB_READ:state<=WB_CAPTURE;
            WB_CAPTURE:begin
                
                if(abort_requested)begin faulted<=1;reply(0,0,1);rsp_aborted<=1;end
                else if(transfer_word==31)start_line(1,{tags[selected_set],selected_set});
                else begin transfer_word<=transfer_word+5'd1;state<=WB_CAPTURE;end
            end
            MEM_REQUEST:if(line_req_ready)state<=MEM_WAIT;
            MEM_WAIT:if(line_rsp_valid && line_rsp_ready)begin
                if(!line_drained)state<=QUARANTINE;
                else if(line_error)begin faulted<=1;reply(0,0,1);end
                else if(abort_requested)begin faulted<=1;reply(0,0,1);rsp_aborted<=1;end
                else if(line_write)begin
                    dirty[selected_set]<=0;
                    if(flush_mode)next_flush();
                    else begin valid[selected_set]<=0;start_line(0,{requested_tag,selected_set});end
                end else begin transfer_word<=0;state<=FILL_INSTALL;end
            end
            // Sequential shifts avoid a 512-bit variable lane selector.
            FILL_INSTALL:begin
                
                if(transfer_word==31)begin
                tags[selected_set]<=requested_tag;valid[selected_set]<=1;
                dirty[selected_set]<=0;state<=WORD_READ;
            end else transfer_word<=transfer_word+5'd1;
            end
            FLUSH_SCAN:begin
                selected_set<=flush_position;
                if(valid[flush_position] && dirty[flush_position])begin
                    transfer_word<=0;state<=WB_READ;
                end else next_flush();
            end
            QUARANTINE:begin end // 保留旧上下文；只有外部证明安全的共同rst允许恢复。
            default:begin faulted<=1;reply(0,0,1);end
            endcase
        end
    end
endmodule
