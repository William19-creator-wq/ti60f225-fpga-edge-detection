// RS01..06：单银行视频borrow；native两credit，固定DE，无额外像素RAM。
module display_row_streamer #(
    parameter integer IMAGE_WIDTH=1920,IMAGE_HEIGHT=1080
)(
    input logic video_clk,safe_reset_n,
    input logic reserve_valid,output wire reserve_ready,
    input logic [542:0] reserve_ticket,input logic reserve_discard,
    input logic row_valid,output wire row_ready,input logic [542:0] row_ticket,input logic owned,
    output wire prepared,
    input logic display_start,display_de,input logic [10:0] display_x_even,
    input logic [478:0] display_demand,input logic discard,
    output wire rd_request_valid,input logic rd_request_ready,
    output wire [63:0] rd_generation,output wire [9:0] rd_address,
    input logic rd_response_valid,output wire rd_response_ready,
    input logic [53:0] rd_data,input logic [9:0] rd_response_address,input logic rd_error,
    output wire release_valid,input logic release_ready,output wire [63:0] release_generation,
    output logic [1:0] release_kind,input logic release_error,
    output wire [53:0] pixel_pair,output wire pixel_valid,identity_good,
    output wire quarantined,local_live,output wire [386:0] local_ref,
    output logic [1:0] line_error,output logic [10:0] shown,issued,popped
);
    import display_row_pkg::*;
    import display_fetch_pkg::*;
    localparam integer PAIRS=IMAGE_WIDTH/2;
    typedef enum logic [2:0] {IDLE,PRIME,RUN,DRAIN,RELEASE,VERIFY_RELEASE,Q} phase_t;
    phase_t phase;
    (* ASYNC_REG="TRUE" *) logic [1:0] reset_pipe;
    wire running=reset_pipe==0;
    logic pending_request,complete;
    logic [1:0] tail,display_error;
    row_ticket_t ticket;
    assign ticket=row_ticket;
    assign reserve_ready=running && phase==IDLE && row_valid && !owned;
    assign row_ready=reserve_valid && reserve_ready;
    wire reserve_fire=reserve_valid&&reserve_ready;
    assign prepared=running && phase==PRIME && !discard && owned && issued==2 &&
        rd_response_valid && rd_response_address==0 && !rd_error;
    assign rd_generation=ticket.generation;assign rd_address=issued[9:0];
    assign release_generation=ticket.generation;
    assign release_valid=running && phase==RELEASE;
    assign local_live=running && (phase!=IDLE || pending_request || tail!=0);
    assign local_ref=ticket_ref(ticket);assign quarantined=running && phase==Q;

    logic [1:0] start_error,current_error;
    logic attempt,pair_good,fail_line,drain_now,protocol_fault;
    // RS03：首DE读旧prepared；下一reserve不能改变上一失败行display_error。
    always_comb begin
        start_error=1;
        if(phase==PRIME && owned)begin
            if(display_x_even!=0 || row_ticket[478:0]!=display_demand ||
               (rd_response_valid && (rd_error || rd_response_address!=0)))start_error=3;
            else if(prepared && !discard)start_error=0;
        end else if(phase==RUN || phase==Q)start_error=3;
        current_error=display_start ? start_error : display_error;
        attempt=running && display_de && !discard && current_error==0 &&
            ((phase==PRIME && display_start && prepared) || phase==RUN);
        pair_good=attempt && owned && row_ticket[478:0]==display_demand &&
            !display_x_even[0] && display_x_even<IMAGE_WIDTH && display_x_even[10:1]==shown[9:0] &&
            rd_response_valid && !rd_error && rd_response_address==shown[9:0];
        fail_line=0;
        if(phase==PRIME)fail_line=discard || (display_start && start_error!=0) ||
            (rd_response_valid && (rd_error || rd_response_address!=0));
        if(phase==RUN)fail_line=discard || !display_de || !pair_good;
        if(fail_line && ((phase==PRIME && rd_response_valid && (rd_error || rd_response_address!=0)) ||
           (phase==RUN && display_de && !discard &&
            (row_ticket[478:0]!=display_demand || display_x_even[0] || display_x_even>=IMAGE_WIDTH ||
             display_x_even[10:1]!=shown[9:0] || (rd_response_valid && (rd_error || rd_response_address!=shown[9:0]))))))current_error=3;
        else if(fail_line && current_error==0)current_error=1;
        protocol_fault=(phase!=IDLE && phase!=VERIFY_RELEASE && phase!=Q && !owned) ||
            (phase!=IDLE && phase!=Q && rd_response_valid && issued==popped) || release_error;
        drain_now=running && !protocol_fault && (phase==DRAIN || fail_line);
    end
    assign rd_request_valid=running && pending_request;
    // 在DRAIN仍兑现先前promise；ready不授予尚未接受的第3信用。
    assign rd_response_ready=running && !protocol_fault && (pair_good || drain_now);
    wire request_fire=rd_request_valid&&rd_request_ready;
    wire response_fire=rd_response_valid&&rd_response_ready;
    assign pixel_valid=pair_good && response_fire && !protocol_fault;
    assign pixel_pair=rd_data;
    assign identity_good=running && phase!=Q && current_error!=3 && !protocol_fault;

    always_ff @(posedge video_clk or negedge safe_reset_n)
        if(!safe_reset_n)reset_pipe<=2'b11;else reset_pipe<={reset_pipe[0],1'b0};
    always_ff @(posedge video_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin
            phase<=IDLE;issued<=0;popped<=0;shown<=0;pending_request<=0;tail<=0;
            complete<=0;release_kind<=ROW_DISCARDED;line_error<=0;display_error<=0;
        end else if(running)begin
            tail<={tail[0],pixel_valid};
            if(display_start)display_error<=start_error;
            if(request_fire)begin
                issued<=issued+11'd1;
                // J1：PRIME保持RE2承诺，由真实pop释放信用；其后每个DE保持下一RE。
                pending_request<=!drain_now && !protocol_fault && !discard && issued+11'd1<PAIRS &&
                    ((phase==PRIME && issued+11'd1<3) || pixel_valid);
            end
            if(response_fire)popped<=popped+11'd1;
            if(pixel_valid)shown<=shown+11'd1;
            if(protocol_fault)begin phase<=Q;line_error<=3;display_error<=3;end
            else case(phase)
                IDLE:if(reserve_fire)begin
                    issued<=0;popped<=0;shown<=0;complete<=0;line_error<=0;
                    if(reserve_ticket!=row_ticket || ticket.generation==0)begin phase<=Q;line_error<=3;display_error<=3;end
                    else if(reserve_discard || discard)begin phase<=DRAIN;line_error<=1;end
                    else begin phase<=PRIME;pending_request<=1;end
                end
                PRIME,RUN:begin
                    if(fail_line)begin phase<=DRAIN;line_error<=current_error;display_error<=current_error;end
                    else if(pixel_valid)begin
                        if(shown==PAIRS-1)begin complete<=1;phase<=DRAIN;end
                        else phase<=RUN;
                    end
                end
                DRAIN:if(!pending_request && issued==popped && tail==0)begin
                    release_kind<=complete && shown==PAIRS && line_error==0 ? ROW_CONSUMED : ROW_DISCARDED;
                    phase<=RELEASE;
                end
                RELEASE:if(release_ready)phase<=VERIFY_RELEASE;
                VERIFY_RELEASE:begin
                    if(owned)begin phase<=Q;line_error<=3;display_error<=3;end
                    else phase<=IDLE;
                end
                Q:begin end
                default:phase<=Q;
            endcase
        end
    end
    // synthesis translate_off
    initial if(IMAGE_WIDTH<4 || IMAGE_WIDTH>1920 || IMAGE_WIDTH%2 || IMAGE_HEIGHT<2 || IMAGE_HEIGHT>1080 || IMAGE_HEIGHT%2)$fatal(1,"Row streamer geometry");
    always @(posedge video_clk)if(running)begin
        if(issued>PAIRS || popped>issued || shown>popped || issued-popped>2)$fatal(1,"Row stream actual credit ledger");
        if(release_valid && (pending_request || issued!=popped || tail!=0))$fatal(1,"Row stream early release");
        if(pixel_valid && (!rd_response_valid || !rd_response_ready || !display_de))$fatal(1,"Pixel without actual native pop");
    end
    // synthesis translate_on
endmodule
