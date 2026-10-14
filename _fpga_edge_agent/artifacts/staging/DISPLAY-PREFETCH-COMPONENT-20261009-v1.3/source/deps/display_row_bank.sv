// DR02..06：core填充/资格与video读借用，任何未知关闭不制造归还。
module display_row_bank #(
    parameter integer IMAGE_WIDTH=1920,IMAGE_HEIGHT=1080,BANK_ID=0,
    parameter logic [63:0] INIT_GENERATION=1
)(
    input logic core_clk,video_clk,safe_reset_n,
    input logic fill_valid,output wire fill_ready,input logic [542:0] fill_ticket,
    output wire fill_reply_valid,input logic fill_reply_ready,output wire [542:0] fill_reply_ticket,output logic [2:0] fill_reply_status,
    input logic wr_valid,output wire wr_ready,input logic [63:0] wr_generation,input logic [9:0] wr_address,input logic [53:0] wr_data,
    input logic publish_valid,output wire publish_ready,input logic [63:0] publish_generation,input logic io_closed,producer_closed,
    input logic abort_valid,output wire abort_ready,input logic [63:0] abort_generation,
    output wire return_valid,input logic return_ready,output wire [542:0] return_ticket,output wire [1:0] return_kind,
    output wire core_busy,output logic exhausted,output wire quarantined,output logic write_error,
    output wire row_valid,input logic row_ready,output wire [542:0] row_ticket,output logic owned,
    input logic rd_request_valid,output wire rd_request_ready,input logic [63:0] rd_generation,input logic [9:0] rd_address,
    output wire rd_response_valid,input logic rd_response_ready,output wire [53:0] rd_data,output wire [9:0] rd_response_address,output wire rd_error,
    input logic release_valid,output wire release_ready,input logic [63:0] release_generation,input logic [1:0] release_kind,output logic release_error
);
    import display_row_pkg::*;
    localparam integer PAIRS=IMAGE_WIDTH/2;
    typedef enum logic [2:0] {FREE,CHECK,REPLY,FILL,PUBLISH,WAIT_RETURN,RETURN_LOCAL,ROW_Q} core_state_t;
    core_state_t state;
    (* ASYNC_REG="TRUE" *) logic [1:0] core_reset,video_reset;
    wire core_running=core_reset==0,video_running=video_reset==0;
    row_ticket_t current,incoming,video_ticket;
    row_return_t return_view,release_record;
    logic [63:0] next_generation;
    logic [10:0] write_count,issued_count,served_count;
    wire publication_source_ready,publication_valid,publication_ready;
    wire [542:0] publication_data;
    wire return_source_ready,return_destination_valid,return_destination_ready;
    wire [544:0] return_destination_data;
    wire pub_src_run,pub_dst_run,ret_src_run,ret_dst_run;
    assign incoming=fill_ticket;assign video_ticket=publication_data;assign return_view=return_destination_data;
    assign fill_ready=core_running && state==FREE && !exhausted;
    assign fill_reply_valid=core_running && state==REPLY;assign fill_reply_ticket=current;
    assign wr_ready=core_running && state==FILL && write_count<PAIRS;
    wire write_fire=wr_valid&&wr_ready;
    wire write_matches=wr_generation==current.generation && wr_address==write_count[9:0];
    wire memory_write=write_fire&&write_matches;
    assign abort_ready=core_running && state==FILL && io_closed && producer_closed && !wr_valid;
    assign publish_ready=core_running && state==FILL && write_count==PAIRS && io_closed && producer_closed && !wr_valid && !abort_valid;
    wire return_matches=return_view.ticket==current && return_view.kind<2;
    assign return_valid=core_running && (state==RETURN_LOCAL || (state==WAIT_RETURN && return_destination_valid && return_matches));
    assign return_ticket=state==RETURN_LOCAL ? current : return_view.ticket;
    assign return_kind=state==RETURN_LOCAL ? ROW_DISCARDED : return_view.kind;
    assign return_destination_ready=state==WAIT_RETURN && return_ready && return_matches && core_running;
    assign core_busy=state!=FREE;assign quarantined=state==ROW_Q;

    atomic_mailbox #(.PAYLOAD_WIDTH(543)) publication(
        .src_clk(core_clk),.dst_clk(video_clk),.safe_reset_n,.src_valid(core_running && state==PUBLISH),.src_ready(publication_source_ready),.src_data(current),
        .dst_valid(publication_valid),.dst_ready(publication_ready),.dst_data(publication_data),.src_running(pub_src_run),.dst_running(pub_dst_run));
    assign row_valid=video_running && publication_valid && !owned && return_source_ready;
    assign row_ticket=publication_data;
    assign publication_ready=video_running && row_ready && !owned && return_source_ready;
    // 完整ticket由publication稳定源holding保存，直到视频读借用归还以后才会改变。
    assign release_record.ticket=video_ticket;assign release_record.kind=release_kind;

    logic head,tail,pending,pending_error;logic [1:0] count;
    logic [9:0] pending_address;
    read_record_t slot0,slot1,read_head;
    assign read_head=head ? slot1 : slot0;
    assign rd_response_valid=video_running && count!=0;
    assign rd_data=read_head.data;assign rd_response_address=read_head.address;assign rd_error=read_head.error;
    wire pop=rd_response_valid&&rd_response_ready;
    wire [2:0] after_capture={1'b0,count}+{2'b0,pending}-{2'b0,pop};
    assign rd_request_ready=video_running && owned && !release_valid && after_capture<3'd2;
    wire read_fire=rd_request_valid&&rd_request_ready;
    wire read_matches=rd_generation==video_ticket.generation && rd_address<PAIRS && rd_address==issued_count[9:0] && issued_count<PAIRS;
    wire memory_read=read_fire&&read_matches;
    wire [53:0] memory_data;
    row_ram54 storage(.core_clk,.video_clk,.write_enable(memory_write),.read_enable(memory_read),.write_address(wr_address),.read_address(rd_address),.write_data(wr_data),.read_data(memory_data));
    assign release_ready=video_running && owned && !pending && count==0 && return_source_ready;
    wire release_matches=release_generation==video_ticket.generation && release_kind<2 && (release_kind==ROW_DISCARDED || served_count==PAIRS);
    wire release_fire=release_valid&&release_ready&&release_matches;
    atomic_mailbox #(.PAYLOAD_WIDTH(545)) retirement(
        .src_clk(video_clk),.dst_clk(core_clk),.safe_reset_n,.src_valid(release_fire),.src_ready(return_source_ready),.src_data(release_record),
        .dst_valid(return_destination_valid),.dst_ready(return_destination_ready),.dst_data(return_destination_data),.src_running(ret_src_run),.dst_running(ret_dst_run));
    function automatic logic fields_valid(input row_ticket_t t);
        logic [2:0] mask;logic [10:0] sy;
        begin
            mask=0;sy=t.target_y;
            case(t.mode)
                0:begin mask=t.target_y<IMAGE_HEIGHT/2 ? 3'b001 : 3'b010;sy=11'(2*(t.target_y%(IMAGE_HEIGHT/2)));end
                1,2:mask=3'b001;
                3:mask=3'b010;
                4:mask=3'b011;
                5:mask=3'b111;
                default:mask=0;
            endcase
            return t.sequence_id!=0 && t.scan!=0 && t.result_handle!=0 && t.policy!=0 && t.origin[194:131]!=0 &&
                t.origin[194:131]==t.origin[66:3] && t.origin[2:0]<6 && t.target_y<IMAGE_HEIGHT && t.source_y<IMAGE_HEIGHT &&
                t.mode<6 && t.required_mask==mask && t.source_y==sy;
        end
    endfunction
    always_ff @(posedge core_clk or negedge safe_reset_n)
        if(!safe_reset_n)core_reset<=2'b11;else core_reset<={core_reset[0],1'b0};
    always_ff @(posedge video_clk or negedge safe_reset_n)
        if(!safe_reset_n)video_reset<=2'b11;else video_reset<={video_reset[0],1'b0};
    always_ff @(posedge core_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin state<=FREE;current<=0;next_generation<=INIT_GENERATION;write_count<=0;fill_reply_status<=0;exhausted<=0;write_error<=0;end
        else if(core_running)begin
            write_error<=0;
            case(state)
                FREE:if(fill_valid&&fill_ready)begin current<=incoming;write_count<=0;state<=CHECK;end
                CHECK:begin
                    fill_reply_status<=!fields_valid(current) ? ROW_FIELD : current.generation!=next_generation ? ROW_IDENTITY : ROW_OK;
                    state<=REPLY;
                end
                REPLY:if(fill_reply_valid&&fill_reply_ready)state<=fill_reply_status==ROW_OK ? FILL : FREE;
                FILL:begin
                    if(write_fire)begin
                        if(write_matches)write_count<=write_count+11'd1;
                        else begin state<=ROW_Q;write_error<=1;end
                    end else if(abort_valid&&abort_ready)begin
                        if(abort_generation==current.generation)state<=RETURN_LOCAL;
                        else begin state<=ROW_Q;write_error<=1;end
                    end else if(publish_valid&&publish_ready)begin
                        if(publish_generation==current.generation)state<=PUBLISH;
                        else begin state<=ROW_Q;write_error<=1;end
                    end
                end
                PUBLISH:if(publication_source_ready)state<=WAIT_RETURN;
                WAIT_RETURN:if(return_destination_valid && !return_matches)state<=ROW_Q;
                default:begin end
            endcase
            if(return_valid&&return_ready)begin
                state<=FREE;write_count<=0;
                if(next_generation==64'hffffffffffffffff)exhausted<=1;
                else next_generation<=next_generation+64'd1;
            end
        end
    end
    always_ff @(posedge video_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin owned<=0;issued_count<=0;served_count<=0;head<=0;tail<=0;pending<=0;count<=0;pending_error<=0;pending_address<=0;slot0<=0;slot1<=0;release_error<=0;end
        else if(video_running)begin
            release_error<=0;pending<=read_fire;count<=after_capture[1:0];
            if(row_valid&&row_ready)begin owned<=1;issued_count<=0;served_count<=0;end
            if(read_fire)begin
                pending_address<=rd_address;pending_error<=!read_matches;
                if(read_matches)issued_count<=issued_count+11'd1;
            end
            if(pending)begin
                if(tail)slot1<={pending_error ? 54'd0 : memory_data,pending_address,pending_error};
                else slot0<={pending_error ? 54'd0 : memory_data,pending_address,pending_error};
                tail<=!tail;
            end
            if(pop)begin head<=!head;if(!read_head.error)served_count<=served_count+11'd1;end
            if(release_valid&&release_ready)begin
                if(release_matches)owned<=0;else release_error<=1;
            end
        end
    end
    // synthesis translate_off
    initial if(IMAGE_WIDTH<4 || IMAGE_WIDTH>1920 || IMAGE_WIDTH%2!=0 || IMAGE_HEIGHT<2 || IMAGE_HEIGHT>1080 || IMAGE_HEIGHT%2!=0 || BANK_ID<0 || BANK_ID>2 || INIT_GENERATION==0)$fatal(1,"Row bank parameters");
    always @(posedge video_clk)if(video_running)begin
        if({1'b0,count}+{2'b0,pending}>3'd2 || after_capture>3'd2)$fatal(1,"Row read credit overflow");
        if(release_fire && (pending || count!=0))$fatal(1,"Released outstanding row reads");
    end
    // synthesis translate_on
endmodule
