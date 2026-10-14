// PF01/02/05/07：同域行解析；完整身份锁定，metadata缓存及RGB carry先留容量。
module display_row_reader #(
    parameter integer IMAGE_WIDTH=1920,IMAGE_HEIGHT=1080,FRAME_ALIGNMENT=16,
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000,parameter logic [3:0] READ_ID=2
)(
    input logic clk,rst,enable,
    input logic job_valid,output wire job_ready,input logic [1:0] job_bank,
    input logic [542:0] job_ticket,input logic [941:0] job_bundle,input logic job_permitted,
    output wire job_reply_valid,input logic job_reply_ready,output logic [2:0] job_reply_status,
    output logic [1:0] saved_bank,output wire [542:0] saved_ticket,
    output wire out_valid,input logic out_ready,output logic [53:0] out_data,output logic [9:0] out_address,output wire [63:0] out_generation,
    input logic cancel_valid,input logic [1:0] cancel_bank,input logic [542:0] cancel_ticket,
    output wire done_valid,input logic done_ready,output logic [1:0] outcome,output logic [7:0] reason,
    output wire drained,output logic [10:0] prepared_pairs,delivered_pairs,output logic [31:0] read_beats,output wire quarantined,
    output wire m_axi_arvalid,input logic m_axi_arready,output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid,output wire [7:0] m_axi_arlen,output wire [2:0] m_axi_arsize,output wire [1:0] m_axi_arburst,
    input logic m_axi_rvalid,output wire m_axi_rready,input logic [127:0] m_axi_rdata,
    input logic [3:0] m_axi_rid,input logic [1:0] m_axi_rresp,input logic m_axi_rlast
);
    import display_row_pkg::*;
    localparam integer PAIRS=IMAGE_WIDTH/2;
    localparam logic [31:0] N=32'(IMAGE_WIDTH*IMAGE_HEIGHT),RGB_L=3*N,EDGE_L=(N+7)/8,ANN_L=4224+(N+3)/4;
    typedef enum logic [3:0] {IDLE,CHECK,CFG_REPLY,META_BEGIN,META_WAIT,RGB_BEGIN,RGB_RUN,STOPPING,DONE,Q} state_t;
    typedef enum logic [1:0] {EMPTY,RESERVED,VALID} cache_state_t;
    state_t state;row_ticket_t ticket;frame_owner_pkg::reply_t bundle;
    logic permitted,stop_latched,fp_valid,span_active,span_cmd_valid,rgb_io_done,notice_valid;
    logic serial_valid,meta_pending;
    wire span_q;
    logic [1:0] phase; // 0 EDGE、1 ANN、2 RGB；元数据各自以raw字节存储。
    logic [31:0] span_cmd_addr;logic [13:0] span_cmd_bytes;
    wire matching_cancel=cancel_valid && cancel_bank==saved_bank && cancel_ticket==ticket && state!=IDLE && state!=DONE && state!=Q;
    wire reading_phase=state==META_BEGIN || state==META_WAIT || state==RGB_BEGIN || state==RGB_RUN || state==STOPPING;
    wire stopping=stop_latched || matching_cancel || span_q || (reading_phase && !enable) || state==STOPPING || state==Q;
    wire span_req_ready,span_data_valid,span_done_valid,span_drained;
    wire [127:0] span_data;wire [1:0] span_outcome;wire [7:0] span_reason;
    wire span_data_ready,span_done_ready;
    wire span_fire=span_data_valid&&span_data_ready,span_done_fire=span_done_valid&&span_done_ready;
    assign job_ready=!rst && enable && state==IDLE && !span_q;
    assign job_reply_valid=!rst && state==CFG_REPLY;
    assign saved_ticket=ticket;assign out_generation=ticket.generation;assign out_valid=!rst && fp_valid;
    assign quarantined=state==Q;assign drained=state!=Q;
    assign done_valid=!rst && (state==DONE || (state==Q && notice_valid && !fp_valid && !meta_pending && !serial_valid));
    wire out_fire=out_valid&&out_ready;

    display_span_axi #(.ADDRESS_BYTES(ADDRESS_BYTES),.READ_ID(READ_ID)) spans(
        .clk,.rst,.enable,.cancel(stopping),.req_valid(span_cmd_valid),.req_ready(span_req_ready),.req_addr(span_cmd_addr),.req_bytes(span_cmd_bytes),
        .data_valid(span_data_valid),.data_ready(span_data_ready),.data(span_data),.done_valid(span_done_valid),.done_ready(span_done_ready),
        .outcome(span_outcome),.reason(span_reason),.drained(span_drained),.quarantined(span_q),
        .m_axi_arvalid,.m_axi_arready,.m_axi_araddr,.m_axi_arid,.m_axi_arlen,.m_axi_arsize,.m_axi_arburst,
        .m_axi_rvalid,.m_axi_rready,.m_axi_rdata,.m_axi_rid,.m_axi_rresp,.m_axi_rlast);
    function automatic logic [31:0] align16(input logic [31:0] n);return (n+15)&32'hfffffff0;endfunction
    // PB04/05：描述物理容量与行span对齐分别计算，不能把16B读取改成64B。
    function automatic logic [31:0] frame_allocation(input logic [31:0] n);
        return FRAME_ALIGNMENT==64 ? ((n+32'd63)&32'hffffffc0) : ((n+32'd15)&32'hfffffff0);
    endfunction
    function automatic logic header_valid(input row_ticket_t t,input frame_owner_pkg::reply_t b,input logic [1:0] bank);
        logic [95:0] sd,ed,ad;logic [31:0] rb;logic [2:0] mask;logic [10:0] sy;logic valid_ranges;
        begin
            sd={32'(b.source_slot)*32'h00800000,RGB_L,frame_allocation(RGB_L)};ed=0;ad=0;rb=32'h03000000+32'(b.result_slot)*32'h00800000;
            if(t.mode!=1 && t.mode!=2)ed={rb,EDGE_L,frame_allocation(EDGE_L)};
            if(t.mode==5)ad={rb+32'h00100000,ANN_L,frame_allocation(ANN_L)};
            mask=0;sy=t.target_y;
            case(t.mode)
                0:begin mask=t.target_y<IMAGE_HEIGHT/2 ? 1 : 2;sy=t.target_y<IMAGE_HEIGHT/2 ? 11'(t.target_y<<1) : 11'((t.target_y-IMAGE_HEIGHT/2)<<1);end
                1,2:mask=1;3:mask=2;4:mask=3;5:mask=7;
                default:mask=0;
            endcase
            valid_ranges={1'b0,sd[95:64]}+{1'b0,sd[31:0]}<=ADDRESS_BYTES;
            if(ed!=0)valid_ranges=valid_ranges && {1'b0,ed[95:64]}+{1'b0,ed[31:0]}<=ADDRESS_BYTES;
            if(ad!=0)valid_ranges=valid_ranges && {1'b0,ad[95:64]}+{1'b0,ad[31:0]}<=ADDRESS_BYTES;
            return bank<3 && b.op==5 && b.status==0 && b.source_handle!=0 && b.result_handle!=0 && b.source_slot<6 && b.result_slot<3 &&
                b.origin[194:131]==b.source_handle && b.origin[66:3]==b.source_handle && b.origin[2:0]==b.source_slot && b.cj[63:0]==b.origin[130:67] &&
                b.cj[106:96]==IMAGE_WIDTH && b.cj[117:107]==IMAGE_HEIGHT && b.cj[128:118]<=b.cj[139:129] && b.body[111:109]==t.mode && b.body[108:98]==IMAGE_HEIGHT/2 &&
                b.body[399:112]=={sd,ed,ad} && b.policy!=0 && valid_ranges && t.generation!=0 && t.sequence_id!=0 && t.scan!=0 &&
                t.result_handle==b.result_handle && t.origin==b.origin && t.policy==b.policy && t.target_y<IMAGE_HEIGHT && t.source_y==sy && t.mode<6 && t.required_mask==mask;
        end
    endfunction
    wire [31:0] edge_bit_start=32'(ticket.source_y)*32'(IMAGE_WIDTH),ann_bit_start=edge_bit_start<<1;
    wire [31:0] rgb_byte_start=edge_bit_start*32'd3;
    wire [31:0] edge_byte_start=edge_bit_start>>3,ann_byte_start=ann_bit_start>>3;
    wire [31:0] edge_byte_end=(edge_bit_start+32'(IMAGE_WIDTH)+7)>>3;
    wire [31:0] ann_byte_end=(ann_bit_start+32'(IMAGE_WIDTH*2)+7)>>3;
    wire [31:0] rgb_byte_end=rgb_byte_start+32'(IMAGE_WIDTH*3);
    wire [6:0] edge_prefix=edge_bit_start[6:0],ann_prefix=ann_bit_start[6:0];
    wire [31:0] src_base=bundle.body[399:368],edge_base=bundle.body[303:272],ann_base=bundle.body[207:176];
    logic [31:0] phase_addr;logic [13:0] phase_bytes;
    always_comb begin
        phase_addr=0;phase_bytes=0;
        case(phase)
            0:begin phase_addr=edge_base+(edge_byte_start&32'hfffffff0);phase_bytes=14'(align16(edge_byte_end)-(edge_byte_start&32'hfffffff0));end
            1:begin phase_addr=ann_base+32'd4224+(ann_byte_start&32'hfffffff0);phase_bytes=14'(align16(ann_byte_end)-(ann_byte_start&32'hfffffff0));end
            2:begin phase_addr=src_base+(rgb_byte_start&32'hfffffff0);phase_bytes=14'(align16(rgb_byte_end)-(rgb_byte_start&32'hfffffff0));end
        endcase
    end
    logic [127:0] serial_data;logic [2:0] serial_index;logic [8:0] meta_words;
    wire meta_write=serial_valid && !stopping && state==META_WAIT;
    wire [8:0] meta_write_address=(phase==1 ? 9'd128 : 9'd0)+meta_words;
    cache_state_t cache_state[0:3];logic [8:0] cache_tag[0:3];logic [15:0] cache_data[0:3];
    logic [1:0] pending_slot;
    logic meta_issue;logic [1:0] issue_slot;logic [8:0] issue_address;
    wire [15:0] meta_read_data;
    display_meta_ram meta_storage(.clk,.write_enable(meta_write),.read_enable(meta_issue),.write_address(meta_write_address),.read_address(issue_address),.write_data(serial_data[15:0]),.read_data(meta_read_data));
    wire [17:0] e_cursor={11'd0,edge_prefix}+({7'd0,prepared_pairs}<<1),a_cursor={11'd0,ann_prefix}+({7'd0,prepared_pairs}<<2);
    wire [8:0] e_word=9'(e_cursor>>4),a_word=9'd128+9'(a_cursor>>4);
    localparam integer LAST_PAIR=PAIRS-1;
    wire [8:0] e_last=9'(({11'd0,edge_prefix}+18'(LAST_PAIR*2))>>4),a_last=9'd128+9'(({11'd0,ann_prefix}+18'(LAST_PAIR*4))>>4);
    logic e_found,a_found,e_next_found,a_next_found,e_valid,a_valid;logic [15:0] e_value,a_value;logic [2:0] e_empty,a_empty;
    always_comb begin
        e_found=0;a_found=0;e_next_found=0;a_next_found=0;e_valid=!ticket.required_mask[1];a_valid=!ticket.required_mask[2];e_value=0;a_value=0;e_empty=4;a_empty=4;
        for(integer i=0;i<4;i++)begin
            if(i<2)begin
                if(cache_state[i]==EMPTY && e_empty==4)e_empty=3'(i);
                if(cache_state[i]!=EMPTY && cache_tag[i]==e_word)e_found=1;
                if(cache_state[i]!=EMPTY && cache_tag[i]==e_word+1)e_next_found=1;
                if(cache_state[i]==VALID && cache_tag[i]==e_word)begin e_valid=1;e_value=cache_data[i];end
            end else begin
                if(cache_state[i]==EMPTY && a_empty==4)a_empty=3'(i);
                if(cache_state[i]!=EMPTY && cache_tag[i]==a_word)a_found=1;
                if(cache_state[i]!=EMPTY && cache_tag[i]==a_word+1)a_next_found=1;
                if(cache_state[i]==VALID && cache_tag[i]==a_word)begin a_valid=1;a_value=cache_data[i];end
            end
        end
        meta_issue=0;issue_slot=0;issue_address=0;
        if(state==RGB_RUN && prepared_pairs<PAIRS && !stopping)begin
            if(ticket.required_mask[1] && !e_found && e_empty<4)begin meta_issue=1;issue_slot=e_empty[1:0];issue_address=e_word;end
            else if(ticket.required_mask[2] && !a_found && a_empty<4)begin meta_issue=1;issue_slot=a_empty[1:0];issue_address=a_word;end
            else if(ticket.required_mask[2] && a_word<a_last && !a_next_found && a_empty<4)begin meta_issue=1;issue_slot=a_empty[1:0];issue_address=a_word+9'd1;end
            else if(ticket.required_mask[1] && e_word<e_last && !e_next_found && e_empty<4)begin meta_issue=1;issue_slot=e_empty[1:0];issue_address=e_word+9'd1;end
        end
    end
    logic [255:0] rgb_buffer;logic [5:0] rgb_count;logic [3:0] rgb_skip;
    wire [5:0] bytes_for_pair={2'd0,rgb_skip}+6'd6;
    wire build_pair=state==RGB_RUN && !stopping && (!fp_valid||out_ready) && prepared_pairs<PAIRS && e_valid && a_valid && (!ticket.required_mask[0] || rgb_count>=bytes_for_pair);
    wire [5:0] consumed=build_pair && ticket.required_mask[0] ? bytes_for_pair : 6'd0;
    wire [5:0] count_after=rgb_count-consumed;
    wire [255:0] buffer_after=rgb_buffer>>{consumed,3'd0};
    wire [47:0] byte_pair=48'(rgb_buffer>>{rgb_skip,3'd0});
    wire [47:0] rgb_pair=ticket.required_mask[0] ? {byte_pair[31:24],byte_pair[39:32],byte_pair[47:40],byte_pair[7:0],byte_pair[15:8],byte_pair[23:16]} : 48'd0;
    wire [1:0] edge_pair=ticket.required_mask[1] ? 2'(e_value>>e_cursor[3:0]) : 2'd0;
    wire [3:0] ann_pair=ticket.required_mask[2] ? 4'(a_value>>a_cursor[3:0]) : 4'd0;
    assign span_data_ready=stopping ? 1'b1 : state==META_WAIT ? (!serial_valid || serial_index==7) : state==RGB_RUN && ticket.required_mask[0] && count_after<=16;
    assign span_done_ready=span_active && (stopping ? 1'b1 : state==META_WAIT ? !serial_valid : state==RGB_RUN);

    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;ticket<=0;bundle<=0;saved_bank<=0;permitted<=0;job_reply_status<=0;
            stop_latched<=0;fp_valid<=0;span_active<=0;span_cmd_valid<=0;span_cmd_addr<=0;span_cmd_bytes<=0;
            phase<=0;serial_valid<=0;serial_data<=0;serial_index<=0;meta_words<=0;meta_pending<=0;pending_slot<=0;
            rgb_buffer<=0;rgb_count<=0;rgb_skip<=0;rgb_io_done<=0;notice_valid<=0;
            out_data<=0;out_address<=0;prepared_pairs<=0;delivered_pairs<=0;read_beats<=0;outcome<=0;reason<=0;
            for(integer i=0;i<4;i++)begin cache_state[i]<=EMPTY;cache_tag[i]<=0;cache_data[i]<=0;end
        end else begin
            if(out_fire)begin fp_valid<=0;delivered_pairs<=delivered_pairs+11'd1;end
            if(span_cmd_valid && span_req_ready)begin span_cmd_valid<=0;span_active<=1;end
            if(m_axi_rvalid && m_axi_rready && state!=Q && state!=DONE && read_beats!=32'hffffffff)read_beats<=read_beats+32'd1;
            meta_pending<=meta_issue;
            if(meta_pending)begin cache_data[pending_slot]<=meta_read_data;cache_state[pending_slot]<=VALID;end
            if(meta_issue)begin pending_slot<=issue_slot;cache_tag[issue_slot]<=issue_address;cache_state[issue_slot]<=RESERVED;end
            if(meta_write)begin
                meta_words<=meta_words+9'd1;serial_data<=serial_data>>16;serial_index<=serial_index+3'd1;
                if(serial_index==7)serial_valid<=0;
            end
            if(span_fire && state==META_WAIT && !stopping)begin serial_data<=span_data;serial_index<=0;serial_valid<=1;end
            if(state==RGB_RUN && !stopping)begin
                rgb_buffer<=buffer_after;rgb_count<=count_after;
                if(span_fire)begin rgb_buffer<=buffer_after | ({128'd0,span_data}<<{count_after,3'd0});rgb_count<=count_after+6'd16;end
            end
            if(build_pair)begin
                out_data<={ann_pair,edge_pair,rgb_pair};out_address<=prepared_pairs[9:0];fp_valid<=1;prepared_pairs<=prepared_pairs+11'd1;rgb_skip<=0;
                for(integer i=0;i<4;i++)if(cache_state[i]==VALID)begin
                    if(i<2 && cache_tag[i]<9'(({11'd0,edge_prefix}+((18'(prepared_pairs)+1)<<1))>>4))cache_state[i]<=EMPTY;
                    if(i>=2 && cache_tag[i]<9'd128+9'(({11'd0,ann_prefix}+((18'(prepared_pairs)+1)<<2))>>4))cache_state[i]<=EMPTY;
                end
            end
            if(span_done_fire)begin
                span_active<=0;
                if(state!=Q)begin
                    if(span_outcome==3 || !span_drained)begin state<=Q;notice_valid<=1;outcome<=3;reason<=span_reason;end
                    else if(span_outcome==1)begin state<=STOPPING;stop_latched<=1;outcome<=1;reason<=span_reason;end
                    else if(span_outcome==2)begin state<=STOPPING;stop_latched<=1;if(outcome==0)begin outcome<=2;reason<=128;end end
                end
            end
            case(state)
                IDLE:if(job_valid&&job_ready)begin
                    ticket<=job_ticket;bundle<=job_bundle;saved_bank<=job_bank;permitted<=job_permitted;state<=CHECK;
                    stop_latched<=cancel_valid && cancel_bank==job_bank && cancel_ticket==job_ticket;fp_valid<=0;
                    outcome<=cancel_valid && cancel_bank==job_bank && cancel_ticket==job_ticket ? 2 : 0;reason<=cancel_valid && cancel_bank==job_bank && cancel_ticket==job_ticket ? 128 : 0;
                    prepared_pairs<=0;delivered_pairs<=0;read_beats<=0;span_cmd_valid<=0;span_active<=0;serial_valid<=0;meta_pending<=0;rgb_count<=0;notice_valid<=0;
                    for(integer i=0;i<4;i++)cache_state[i]<=EMPTY;
                end
                CHECK:begin job_reply_status<=!permitted ? 3'd2 : !header_valid(ticket,bundle,saved_bank) ? 3'd1 : 3'd0;state<=CFG_REPLY;end
                CFG_REPLY:if(job_reply_ready)begin
                    if(job_reply_status!=0)state<=IDLE;
                    else if(stop_latched||matching_cancel)state<=STOPPING;
                    else begin phase<=0;state<=META_BEGIN;end
                end
                META_BEGIN:begin
                    if(stopping)state<=STOPPING;
                    else if((phase==0 && !ticket.required_mask[1]) || (phase==1 && !ticket.required_mask[2]))begin
                        if(phase==0)phase<=1;else state<=RGB_BEGIN;
                    end else begin span_cmd_valid<=1;span_cmd_addr<=phase_addr;span_cmd_bytes<=phase_bytes;meta_words<=0;serial_valid<=0;state<=META_WAIT;end
                end
                META_WAIT:if(span_done_fire && span_outcome==0 && !stopping)begin
                    if(phase==0)begin phase<=1;state<=META_BEGIN;end else state<=RGB_BEGIN;
                end
                RGB_BEGIN:begin
                    phase<=2;rgb_buffer<=0;rgb_count<=0;rgb_skip<=rgb_byte_start[3:0];rgb_io_done<=!ticket.required_mask[0];
                    for(integer i=0;i<4;i++)cache_state[i]<=EMPTY;
                    if(stopping)state<=STOPPING;
                    else begin
                        if(ticket.required_mask[0])begin
                            // phase刚更新为RGB，地址/长度直接由不可变RGB范围形成。
                            span_cmd_addr<=src_base+(rgb_byte_start&32'hfffffff0);span_cmd_bytes<=14'(align16(rgb_byte_end)-(rgb_byte_start&32'hfffffff0));span_cmd_valid<=1;
                        end
                        state<=RGB_RUN;
                    end
                end
                RGB_RUN:begin
                    if(span_done_fire && span_outcome==0)rgb_io_done<=1;
                    if(stopping && !span_done_fire)state<=STOPPING;
                    else if(!stopping && prepared_pairs==PAIRS && delivered_pairs==PAIRS && !fp_valid && rgb_io_done && !span_active && !span_cmd_valid && !meta_pending)begin
                        state<=DONE;rgb_count<=0;for(integer i=0;i<4;i++)cache_state[i]<=EMPTY;
                    end
                end
                STOPPING:if(!span_active && !span_cmd_valid && !fp_valid && !meta_pending && !serial_valid)begin state<=DONE;rgb_count<=0;for(integer i=0;i<4;i++)cache_state[i]<=EMPTY;end
                DONE:if(done_valid&&done_ready)state<=IDLE;
                Q:if(done_valid&&done_ready)notice_valid<=0;
                default:state<=Q;
            endcase
            if(stopping)begin serial_valid<=0;rgb_count<=0;for(integer i=0;i<4;i++)cache_state[i]<=EMPTY;end
            if(matching_cancel)begin stop_latched<=1;if(outcome==0 && !(span_done_fire && span_outcome!=0))begin outcome<=2;reason<=128;end end
            if(state!=Q && ((reading_phase && !enable) || span_q))begin state<=Q;notice_valid<=1;outcome<=3;reason<=span_q ? span_reason : 8'd4;end
        end
    end
    // synthesis translate_off
    initial if(IMAGE_WIDTH<4 || IMAGE_WIDTH>1920 || IMAGE_WIDTH%2 || IMAGE_HEIGHT<2 || IMAGE_HEIGHT>1080 || IMAGE_HEIGHT%2)$fatal(1,"Prefetch reader geometry");
    always @(posedge clk)if(!rst)begin
        if(prepared_pairs<delivered_pairs || prepared_pairs-delivered_pairs>1 || prepared_pairs>PAIRS)$fatal(1,"Prefetch pair reservation");
        if(rgb_count>32)$fatal(1,"Prefetch RGB reservoir overflow");
        if(meta_write && (phase==0 ? meta_words>=128 : meta_words>=256))$fatal(1,"Metadata span overrun");
        if(meta_issue && meta_write)$fatal(1,"Metadata read before fill closed");
        if(done_valid && state!=Q && (fp_valid || span_active || span_cmd_valid || meta_pending || serial_valid))$fatal(1,"Prefetch premature done");
    end
    // synthesis translate_on
    // synthesis translate_off
    initial if(FRAME_ALIGNMENT!=16 && FRAME_ALIGNMENT!=64) $fatal(1,"PB reader frame alignment");
    // synthesis translate_on
endmodule
