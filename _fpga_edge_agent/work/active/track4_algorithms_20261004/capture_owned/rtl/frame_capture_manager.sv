// CO01..07：Source分配、真实RAW EOF、producer/RX双闭合。不是第二份帧账本。
module frame_capture_manager #(
    parameter integer WIDTH=1920, HEIGHT=1080
)(
    input logic clk,rst,halt,capture_quarantined,
    input logic frame_valid,output wire frame_ready,
    input logic [95:0] frame_scope,input logic [1:0] frame_bayer,
    output wire grant_valid,input logic grant_ready,output logic [3:0] grant_status,
    output wire [63:0] grant_handle,output wire [194:0] grant_origin,
    output wire [95:0] grant_scope,output wire [1:0] grant_bayer,

    output wire owner_cmd_valid,input logic owner_cmd_ready,output logic [940:0] owner_command,
    input logic owner_reply_valid,output wire owner_reply_ready,input logic [941:0] owner_reply,

    output wire cap_job_valid,input logic cap_job_ready,
    output wire [31:0] cap_base,output logic [63:0] cap_handle,
    output logic [95:0] cap_scope,output logic [1:0] cap_bayer,
    input logic cap_done_valid,output wire cap_done_ready,
    input logic [63:0] cap_done_handle,input logic [95:0] cap_done_scope,
    input logic [1:0] cap_outcome,input logic [7:0] cap_reason,
    input logic [21:0] cap_raw_pairs,cap_rgb_pairs,cap_lines,cap_discarded,
    input logic [31:0] cap_logical_bytes,cap_physical_bytes,
    output logic cap_cancel_valid,output wire [63:0] cap_cancel_handle,

    input logic raw_eof_valid,input logic [63:0] raw_eof_handle,input logic [95:0] raw_eof_scope,
    input logic rx_valid,output wire rx_ready,input logic [63:0] rx_handle,
    input logic [95:0] rx_scope,input logic [194:0] rx_origin,input logic rx_good,
    input logic cancel_valid,input logic [63:0] cancel_handle,
    output wire done_valid,input logic done_ready,output wire [63:0] done_handle,
    output wire [194:0] done_origin,output wire [95:0] done_scope,
    output logic [1:0] done_outcome,output logic [7:0] done_reason,
    output logic quarantined
);
    import frame_owner_pkg::*;
    localparam integer PAIRS=WIDTH*HEIGHT/2,LOGICAL_BYTES=WIDTH*HEIGHT*3;
    localparam integer PHYSICAL_BYTES=((LOGICAL_BYTES+63)/64)*64;
    typedef enum logic [3:0] {
        IDLE,ALLOC_REQUEST,ALLOC_REPLY,START_CAPTURE,WAIT_CLOSE,
        EOF_REQUEST,EOF_REPLY,END_REQUEST,END_REPLY,FINISHED,REJECTED,Q
    } state_t;
    state_t state;
    command_t request;
    reply_t answer;
    logic [194:0] source_origin;
    logic [2:0] source_slot;
    logic capture_started,grant_delivered,eof_seen,eof_registered;
    logic capture_seen,capture_good,capture_error,capture_count_error,capture_cancelled;
    logic rx_seen,rx_good_saved,cancel_seen,cancel_sent;
    logic [7:0] end_flags;
    logic grant_pending;
    assign grant_valid=!rst && grant_pending;
    assign answer=owner_reply;

    wire before_commit=state==START_CAPTURE || state==WAIT_CLOSE || state==EOF_REQUEST || state==EOF_REPLY;
    wire matching_cancel=cancel_valid && cap_handle!=0 && cancel_handle==cap_handle && before_commit;
    wire count_good=cap_raw_pairs==22'(PAIRS) && cap_rgb_pairs==22'(PAIRS) &&
        cap_lines==22'(PHYSICAL_BYTES/64) && cap_discarded==0 &&
        cap_logical_bytes==32'(LOGICAL_BYTES) && cap_physical_bytes==32'(PHYSICAL_BYTES);
    wire closing_error=capture_error || capture_count_error || (rx_seen && !rx_good_saved);
    wire closing_cancel=cancel_seen || matching_cancel || capture_cancelled;
    wire [7:0] closing_reason={4'd0,closing_cancel,(rx_seen && !rx_good_saved),capture_count_error,capture_error};

    assign frame_ready=!rst && state==IDLE && !grant_valid && !quarantined && !halt && !capture_quarantined;
    assign grant_handle=grant_status==OK ? cap_handle : 64'd0;
    assign grant_origin=grant_status==OK ? source_origin : 195'd0;
    assign grant_scope=cap_scope;
    assign grant_bayer=cap_bayer;
    assign cap_base=32'(source_slot)*32'h00800000;
    assign cap_job_valid=!rst && state==START_CAPTURE;
    assign cap_done_ready=!rst && capture_started && !capture_seen;
    assign cap_cancel_handle=cap_handle;
    assign rx_ready=!rst && capture_started && grant_delivered && !rx_seen;
    assign done_valid=!rst && state==FINISHED;
    assign done_handle=cap_handle;
    assign done_origin=source_origin;
    assign done_scope=cap_scope;
    assign owner_cmd_valid=!rst && (state==ALLOC_REQUEST || state==EOF_REQUEST || state==END_REQUEST);
    assign owner_reply_ready=!rst && (state==ALLOC_REPLY || state==EOF_REPLY || state==END_REPLY);

    // CO06：公开命令只取锁定字段；END flags在进入END_REQUEST前封存。
    always_comb begin
        request='0;
        if(state==ALLOC_REQUEST)begin
            request.op=ALLOC_SOURCE;
            request.origin[130:67]=cap_scope[63:0];
        end else begin
            request.op=state==EOF_REQUEST ? SOURCE_EOF : SOURCE_END;
            request.source_handle=cap_handle;
            request.origin=source_origin;
            if(state==END_REQUEST)request.flags=end_flags;
        end
        owner_command=request;
    end

    task automatic prepare_end(input logic [7:0] flags,input logic [1:0] outcome,input logic [7:0] reason);
        begin
            end_flags<=flags;
            done_outcome<=outcome;
            done_reason<=reason;
            state<=END_REQUEST;
        end
    endtask

    always_ff @(posedge clk) begin : capture_control
        if(rst)begin
            state<=IDLE;cap_handle<=0;source_origin<=0;source_slot<=0;
            cap_scope<=0;cap_bayer<=0;grant_pending<=0;grant_status<=OK;
            capture_started<=0;grant_delivered<=0;eof_seen<=0;eof_registered<=0;
            capture_seen<=0;capture_good<=0;capture_error<=0;capture_count_error<=0;capture_cancelled<=0;
            rx_seen<=0;rx_good_saved<=0;cancel_seen<=0;cancel_sent<=0;cap_cancel_valid<=0;
            end_flags<=0;done_outcome<=0;done_reason<=0;quarantined<=0;
        end else begin
            cap_cancel_valid<=0;
            if(halt || capture_quarantined)quarantined<=1;
            if(grant_valid && grant_ready)begin
                grant_pending<=0;
                if(grant_status==OK)grant_delivered<=1;
            end
            if(matching_cancel)cancel_seen<=1;

            // CO03：这三条事实通路独立于owner命令状态，往返期间仍接收真实事件。
            if(capture_started && raw_eof_valid && raw_eof_handle==cap_handle && raw_eof_scope==cap_scope)
                eof_seen<=1;
            if(cap_done_valid && cap_done_ready && cap_done_handle==cap_handle && cap_done_scope==cap_scope)begin
                capture_seen<=1;
                capture_good<=cap_outcome==0 && count_good;
                capture_error<=cap_outcome==1 || cap_outcome==3;
                capture_count_error<=cap_outcome==0 && !count_good;
                capture_cancelled<=cap_outcome==2;
            end
            if(rx_valid && rx_ready && rx_handle==cap_handle && rx_scope==cap_scope && rx_origin==source_origin)begin
                rx_seen<=1;
                rx_good_saved<=rx_good;
            end
            // CO05：旧parent的cancel是一次事件；持续level会反复覆盖其DRAIN状态。
            if(capture_started && !capture_seen && !cancel_sent &&
                (cancel_seen || matching_cancel || (rx_seen && !rx_good_saved) || halt || capture_quarantined))begin
                cap_cancel_valid<=1;
                cancel_sent<=1;
            end

            case(state)
                IDLE:if(frame_valid && frame_ready)begin
                    cap_scope<=frame_scope;cap_bayer<=frame_bayer;cap_handle<=0;source_origin<=0;source_slot<=0;
                    capture_started<=0;grant_delivered<=0;eof_seen<=0;eof_registered<=0;
                    capture_seen<=0;capture_good<=0;capture_error<=0;capture_count_error<=0;capture_cancelled<=0;
                    rx_seen<=0;rx_good_saved<=0;cancel_seen<=0;cancel_sent<=0;
                    end_flags<=0;done_outcome<=0;done_reason<=0;state<=ALLOC_REQUEST;
                end
                ALLOC_REQUEST:if(owner_cmd_ready)state<=ALLOC_REPLY;
                ALLOC_REPLY:if(owner_reply_valid)begin
                    if(answer.op!=ALLOC_SOURCE)begin quarantined<=1;state<=Q;end
                    else if(answer.status!=OK)begin
                        grant_status<=answer.status;grant_pending<=1;state<=REJECTED;
                    end else begin
                        cap_handle<=answer.source_handle;source_origin<=answer.origin;source_slot<=answer.source_slot;
                        if(halt || capture_quarantined || quarantined)begin
                            grant_status<=QUARANTINED;grant_pending<=1;prepare_end(0,1,8'h10);
                        end else begin grant_status<=OK;state<=START_CAPTURE;end
                    end
                end
                START_CAPTURE:if(cap_job_ready)begin
                    capture_started<=1;grant_pending<=1;grant_status<=OK;state<=WAIT_CLOSE;
                end
                WAIT_CLOSE:begin
                    if(halt || capture_quarantined || quarantined)prepare_end(0,1,8'h10);
                    else if(eof_seen && !eof_registered)state<=EOF_REQUEST;
                    else if(capture_seen && rx_seen && (eof_registered || closing_error || closing_cancel))begin
                        if(closing_error)prepare_end(6,1,closing_reason);
                        else if(closing_cancel)prepare_end(6,2,closing_reason);
                        else if(capture_good && rx_good_saved)prepare_end(7,0,0);
                        else prepare_end(6,1,8'h10);
                    end
                end
                EOF_REQUEST:if(owner_cmd_ready)state<=EOF_REPLY;
                EOF_REPLY:if(owner_reply_valid)begin
                    if(answer.op==SOURCE_EOF && answer.status==OK)begin eof_registered<=1;state<=WAIT_CLOSE;end
                    else begin quarantined<=1;state<=Q;end
                end
                END_REQUEST:if(owner_cmd_ready)state<=END_REPLY;
                END_REPLY:if(owner_reply_valid)begin
                    if(answer.op!=SOURCE_END)begin quarantined<=1;state<=Q;end
                    else if(end_flags==0)begin quarantined<=1;state<=Q;end
                    else if(answer.status==OK)state<=FINISHED;
                    else begin quarantined<=1;state<=Q;end
                end
                FINISHED:if(done_ready)state<=IDLE;
                REJECTED:if(grant_valid && grant_ready)state<=IDLE;
                Q:begin
                    // 未知Source借用保留到共同cold，既有grant仍由独立holding寄存器履约。
                end
                default:begin quarantined<=1;state<=Q;end
            endcase
        end
    end
    // synthesis translate_off
    initial if(WIDTH<4 || WIDTH>1920 || WIDTH%2!=0 || HEIGHT<2 || HEIGHT>1080 || HEIGHT%2!=0)
        $fatal(1,"Capture manager geometry");
    // synthesis translate_on
endmodule
