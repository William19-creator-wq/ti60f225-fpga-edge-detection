// PF04/05/06：reader IO/producer关闭后才真实publish/abort；内部abort归还不等待外部父。
module display_prefetch_rows #(
    parameter integer IMAGE_WIDTH=1920,IMAGE_HEIGHT=1080,
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000,parameter logic [3:0] READ_ID=2
)(
    input logic core_clk,video_clk,safe_reset_n,enable,
    input logic job_valid,output wire job_ready,input logic [1:0] job_bank,
    input logic [542:0] job_ticket,input logic [941:0] job_bundle,input logic job_permitted,
    output wire job_reply_valid,input logic job_reply_ready,output logic [2:0] job_reply_status,
    output wire [1:0] saved_bank,output wire [542:0] saved_ticket,
    input logic cancel_valid,input logic [1:0] cancel_bank,input logic [542:0] cancel_ticket,
    output wire done_valid,input logic done_ready,output logic [1:0] outcome,output logic [7:0] reason,
    output logic drained,row_returned,output logic [10:0] prepared_pairs,delivered_pairs,output logic [31:0] read_beats,
    output wire quarantined,
    output wire [2:0] return_valid,
    input logic [2:0] return_ready,
    output wire [2:0][542:0] return_ticket,
    output wire [2:0][1:0] return_kind,
    output wire [2:0] row_valid,
    input logic [2:0] row_ready,
    output wire [2:0][542:0] row_ticket,
    output wire [2:0] owned,
    input logic [2:0] rd_request_valid,
    output wire [2:0] rd_request_ready,
    input logic [2:0][63:0] rd_generation,
    input logic [2:0][9:0] rd_address,
    output wire [2:0] rd_response_valid,
    input logic [2:0] rd_response_ready,
    output wire [2:0][53:0] rd_data,
    output wire [2:0][9:0] rd_response_address,
    output wire [2:0] rd_error,
    input logic [2:0] release_valid,
    output wire [2:0] release_ready,
    input logic [2:0][63:0] release_generation,
    input logic [2:0][1:0] release_kind,
    output wire [2:0] release_error,
    output wire m_axi_arvalid,input logic m_axi_arready,output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid,output wire [7:0] m_axi_arlen,output wire [2:0] m_axi_arsize,output wire [1:0] m_axi_arburst,
    input logic m_axi_rvalid,output wire m_axi_rready,input logic [127:0] m_axi_rdata,
    input logic [3:0] m_axi_rid,input logic [1:0] m_axi_rresp,input logic m_axi_rlast
);
    typedef enum logic [3:0] {IDLE,HEADER,ROW_FILL,ROW_ACK,USER_ACK,REJECT_DRAIN,RUN,ABORT_REQUEST,ABORT_RETURN,USER_DONE,Q} state_t;
    state_t state;
    (* ASYNC_REG="TRUE" *) logic [1:0] reset_pipe;
    wire rst=reset_pipe!=0;
    logic cancel_latched,force_cancel;
    wire reader_job_ready,reader_reply_valid,reader_out_valid,reader_out_ready,reader_done_valid,reader_done_ready,reader_q,reader_drained;
    wire [2:0] reader_reply_status;wire [53:0] reader_data;wire [9:0] reader_address;wire [63:0] reader_generation;
    wire [1:0] reader_outcome;wire [7:0] reader_reason;wire [10:0] reader_prepared,reader_delivered;wire [31:0] reader_beats;
    wire active_cancel=cancel_valid && cancel_bank==saved_bank && cancel_ticket==saved_ticket && state!=IDLE && state!=USER_DONE && state!=Q;
    wire send_cancel=force_cancel||cancel_latched||active_cancel;
    wire reader_reply_ready;
    assign job_ready=!rst && state==IDLE && enable && reader_job_ready && !reader_q;
    assign job_reply_valid=!rst && state==USER_ACK;
    assign done_valid=!rst && state==USER_DONE;
    assign quarantined=state==Q || (state==USER_DONE && outcome==3);
    display_row_reader #(.IMAGE_WIDTH(IMAGE_WIDTH),.IMAGE_HEIGHT(IMAGE_HEIGHT),.ADDRESS_BYTES(ADDRESS_BYTES),.READ_ID(READ_ID)) reader(
        .clk(core_clk),.rst,.enable,.job_valid(job_valid && state==IDLE),.job_ready(reader_job_ready),.job_bank,.job_ticket,.job_bundle,.job_permitted,
        .job_reply_valid(reader_reply_valid),.job_reply_ready(reader_reply_ready),.job_reply_status(reader_reply_status),.saved_bank,.saved_ticket,
        .out_valid(reader_out_valid),.out_ready(reader_out_ready),.out_data(reader_data),.out_address(reader_address),.out_generation(reader_generation),
        .cancel_valid(send_cancel),.cancel_bank(saved_bank),.cancel_ticket(saved_ticket),
        .done_valid(reader_done_valid),.done_ready(reader_done_ready),.outcome(reader_outcome),.reason(reader_reason),.drained(reader_drained),
        .prepared_pairs(reader_prepared),.delivered_pairs(reader_delivered),.read_beats(reader_beats),.quarantined(reader_q),
        .m_axi_arvalid,.m_axi_arready,.m_axi_araddr,.m_axi_arid,.m_axi_arlen,.m_axi_arsize,.m_axi_arburst,
        .m_axi_rvalid,.m_axi_rready,.m_axi_rdata,.m_axi_rid,.m_axi_rresp,.m_axi_rlast);
    logic [2:0] fill_valid,fill_reply_ready,wr_valid,publish_valid,abort_valid,bank_return_ready,io_closed,producer_closed;
    logic [2:0][542:0] fill_ticket;
    logic [2:0][63:0] wr_generation,publish_generation,abort_generation;
    logic [2:0][9:0] wr_address;logic [2:0][53:0] wr_data;
    wire [2:0] fill_ready,fill_reply_valid,wr_ready,publish_ready,abort_ready,bank_return_valid,core_busy,exhausted,bank_q,write_error;
    wire [2:0][542:0] fill_reply_ticket,bank_return_ticket;wire [2:0][2:0] fill_reply_status;wire [2:0][1:0] bank_return_kind;
    display_rows3 #(.IMAGE_WIDTH(IMAGE_WIDTH),.IMAGE_HEIGHT(IMAGE_HEIGHT)) rows(
        .core_clk,.video_clk,.safe_reset_n,.fill_valid,.fill_ready,.fill_ticket,.fill_reply_valid,.fill_reply_ready,.fill_reply_ticket,.fill_reply_status,
        .wr_valid,.wr_ready,.wr_generation,.wr_address,.wr_data,.publish_valid,.publish_ready,.publish_generation,.io_closed,.producer_closed,.abort_valid,.abort_ready,.abort_generation,
        .return_valid(bank_return_valid),.return_ready(bank_return_ready),.return_ticket(bank_return_ticket),.return_kind(bank_return_kind),.core_busy,.exhausted,.quarantined(bank_q),.write_error,
        .row_valid,.row_ready,.row_ticket,.owned,.rd_request_valid,.rd_request_ready,.rd_generation,.rd_address,.rd_response_valid,.rd_response_ready,.rd_data,.rd_response_address,.rd_error,
        .release_valid,.release_ready,.release_generation,.release_kind,.release_error);
    wire chosen=saved_bank<3;
    wire internal_return=chosen && state==ABORT_RETURN;
    assign return_ticket=bank_return_ticket;assign return_kind=bank_return_kind;
    for(genvar b=0;b<3;b++)begin: public_return
        assign return_valid[b]=!rst && bank_return_valid[b] && !(internal_return && saved_bank==b);
    end
    wire publish_fire=chosen && publish_valid[saved_bank] && publish_ready[saved_bank];
    wire abort_fire=chosen && abort_valid[saved_bank] && abort_ready[saved_bank];
    wire abort_return_fire=internal_return && bank_return_valid[saved_bank] && bank_return_ready[saved_bank];
    assign reader_out_ready=!rst && state==RUN && chosen && wr_ready[saved_bank];
    assign reader_reply_ready=!rst && ((state==REJECT_DRAIN && reader_reply_valid) || (state==USER_ACK && job_reply_ready && job_reply_status<3));
    assign reader_done_ready=!rst && ((state==REJECT_DRAIN && reader_done_valid) || publish_fire || abort_return_fire || (state==RUN && reader_done_valid && (reader_outcome==3 || !reader_drained)));
    always_comb begin
        fill_valid=0;fill_reply_ready=0;fill_ticket=0;wr_valid=0;wr_generation=0;wr_address=0;wr_data=0;
        publish_valid=0;publish_generation=0;abort_valid=0;abort_generation=0;io_closed=0;producer_closed=0;
        bank_return_ready=return_ready;
        if(chosen)begin
            fill_ticket[saved_bank]=saved_ticket;fill_valid[saved_bank]=state==ROW_FILL;
            fill_reply_ready[saved_bank]=state==ROW_ACK;
            wr_valid[saved_bank]=state==RUN && reader_out_valid;
            wr_generation[saved_bank]=reader_generation;wr_address[saved_bank]=reader_address;wr_data[saved_bank]=reader_data;
            io_closed[saved_bank]=reader_done_valid && reader_drained && reader_outcome!=3;
            producer_closed[saved_bank]=reader_done_valid && reader_drained && !reader_out_valid && reader_outcome!=3;
            publish_valid[saved_bank]=state==RUN && reader_done_valid && reader_outcome==0 && reader_drained;
            publish_generation[saved_bank]=reader_generation;
            abort_valid[saved_bank]=state==ABORT_REQUEST;abort_generation[saved_bank]=reader_generation;
            if(internal_return)bank_return_ready[saved_bank]=1;
        end
    end
    always_ff @(posedge core_clk or negedge safe_reset_n)
        if(!safe_reset_n)reset_pipe<=2'b11;else reset_pipe<={reset_pipe[0],1'b0};
    always_ff @(posedge core_clk)begin
        if(rst)begin state<=IDLE;cancel_latched<=0;force_cancel<=0;job_reply_status<=0;outcome<=0;reason<=0;drained<=1;row_returned<=0;prepared_pairs<=0;delivered_pairs<=0;read_beats<=0;end
        else begin
            if(active_cancel)cancel_latched<=1;
            case(state)
                IDLE:if(job_valid&&job_ready)begin
                    state<=HEADER;force_cancel<=0;cancel_latched<=cancel_valid && cancel_bank==job_bank && cancel_ticket==job_ticket;
                    outcome<=0;reason<=0;drained<=1;row_returned<=0;prepared_pairs<=0;delivered_pairs<=0;read_beats<=0;
                end
                HEADER:if(reader_reply_valid)begin
                    if(reader_reply_status!=0)begin job_reply_status<=reader_reply_status;state<=USER_ACK;end
                    else if(!chosen || !fill_ready[saved_bank])begin job_reply_status<=3;force_cancel<=1;state<=REJECT_DRAIN;end
                    else state<=ROW_FILL;
                end
                ROW_FILL:if(chosen && fill_ready[saved_bank])state<=ROW_ACK;
                ROW_ACK:if(chosen && fill_reply_valid[saved_bank])begin
                    if(fill_reply_status[saved_bank]!=0)begin job_reply_status<=4;force_cancel<=1;state<=REJECT_DRAIN;end
                    else begin job_reply_status<=0;state<=USER_ACK;end
                end
                REJECT_DRAIN:if(reader_done_valid)state<=USER_ACK;
                USER_ACK:if(job_reply_ready)state<=job_reply_status==0 ? RUN : IDLE;
                RUN:if(reader_done_valid)begin
                    if(reader_outcome==3 || !reader_drained || publish_fire)begin
                        outcome<=reader_outcome;reason<=reader_reason;drained<=reader_drained;row_returned<=0;
                        prepared_pairs<=reader_prepared;delivered_pairs<=reader_delivered;read_beats<=reader_beats;state<=USER_DONE;
                    end else if(reader_outcome!=0)state<=ABORT_REQUEST;
                end
                ABORT_REQUEST:if(abort_fire)state<=ABORT_RETURN;
                ABORT_RETURN:if(abort_return_fire)begin
                    if(bank_return_ticket[saved_bank]!=saved_ticket || bank_return_kind[saved_bank]!=1)begin outcome<=3;reason<=3;drained<=0;row_returned<=0;end
                    else begin outcome<=reader_outcome;reason<=reader_reason;drained<=reader_drained;row_returned<=1;end
                    prepared_pairs<=reader_prepared;delivered_pairs<=reader_delivered;read_beats<=reader_beats;state<=USER_DONE;
                end
                USER_DONE:if(done_ready)state<=outcome==3 ? Q : IDLE;
                Q:begin end
                default:state<=Q;
            endcase
        end
    end
    // synthesis translate_off
    always @(posedge core_clk)if(!rst)begin
        if(publish_fire && (reader_outcome!=0 || !reader_drained || reader_delivered!=IMAGE_WIDTH/2))$fatal(1,"Prefetch row published before actual IO/data close");
        if(abort_fire && (!reader_drained || reader_outcome==3))$fatal(1,"Unknown prefetch row reclaimed");
        if(done_valid && outcome==0 && (prepared_pairs!=IMAGE_WIDTH/2 || delivered_pairs!=IMAGE_WIDTH/2 || !drained || row_returned))$fatal(1,"Prefetch success contract");
    end
    // synthesis translate_on
endmodule
