// Component-local full eight-neighbor hysteresis. A strong seed starts one
// flood; scan resumes only after its FIFO drains. Neighbor claims accept both
// weak and strong pixels, each exactly once. Unconnected weak pixels stay weak.
// Seed scans may see claimed states; export still forbids remaining strong.
// This changes visitation order/locality, never limits connectivity or capacity.
module hysteresis_core_memory #(
    parameter integer unsigned WIDTH=1920, HEIGHT=1080, EXPORT_LANES=1
)(
    input logic clk,rst,
    input logic job_valid, input logic [63:0] job_id, output wire job_ready,
    input logic cancel_valid, input logic [63:0] cancel_id,
    output wire state_req_valid, input logic state_req_ready,
    output logic [1:0] state_req_op, output logic [20:0] state_req_index,
    input logic state_rsp_valid, output wire state_rsp_ready,
    input logic [15:0] state_rsp_word, // Eight consecutive 2-bit states, aligned to index[20:3].
    input logic [1:0] state_rsp_old, input logic state_rsp_claimed,state_rsp_error,state_rsp_aborted,
    output wire queue_req_valid, input logic queue_req_ready,
    output logic queue_req_push, output logic [20:0] queue_req_index,
    input logic queue_rsp_valid, output wire queue_rsp_ready,
    input logic [20:0] queue_rsp_index, input logic queue_rsp_error,queue_rsp_aborted,
    output wire pixel_valid, input logic pixel_ready,
    output logic [20:0] pixel_index, output logic pixel_edge, output logic [7:0] pixel_edges, output wire [63:0] pixel_job_id,
    output wire done_valid, input logic done_ready,
    output wire [63:0] done_job_id, output logic [1:0] outcome, output logic [7:0] reason,
    output logic [21:0] enqueue_count,pop_count,output_count
);
    localparam integer unsigned N=WIDTH*HEIGHT;
    // Export is linear, after COMPLETE eight-neighbor tracing. One handshake
    // carries EXPORT_LANES pixels, with pixel_index naming its first lane.
    // Counters stay in pixels; the final partial word ignores padded lanes.
    wire [21:0] export_step=({1'b0,export_index}+22'(EXPORT_LANES)>22'(N))
        ?22'(N)-{1'b0,export_index}:22'(EXPORT_LANES);
    initial if(EXPORT_LANES!=1 && EXPORT_LANES!=8)$fatal(1,"Export lanes must be 1 or 8");
    localparam logic [20:0] LAST_INDEX=21'(N-1);
    localparam logic [21:0] CAPACITY=22'(N);
    localparam logic [12:0] DIVISOR=13'(WIDTH);
    localparam logic signed [22:0] ROW_OFFSET=23'(WIDTH);
    typedef enum logic [3:0] {
        IDLE,SEED_NEXT,POP_NEXT,DIVIDE,COORD,NEXT_NEIGHBOR,
        STATE_REQUEST,STATE_WAIT,QUEUE_REQUEST,QUEUE_WAIT,EXPORT_NEXT,PIXEL_HELD,DONE_HELD,SEED_SELECT
    } state_t;
    state_t state;
    logic [63:0] held_job_id;
    logic cancel_sticky;
    logic [20:0] seed_index,current_index,export_index;
    logic [2:0] neighbor;
    logic [1:0] state_purpose,queue_purpose; // seed claim=0,neighbor=1,export/pop=2,seed word=3
    logic [7:0] seed_pending;
    logic [15:0] export_remaining;
    logic [7:0] word_strong_mask;
    logic word_has_claimed,word_has_strong;
    logic [2:0] seed_lane;
    // Linear scan bases are aligned globally to eight pixels, including row crossings.
    // Ignore padding in the final partial word for non-multiple-of-eight geometries.
    always_comb begin
        word_strong_mask=0;word_has_claimed=0;word_has_strong=0;
        for(integer lane=0;lane<8;lane=lane+1)begin
            if(({1'b0,state_req_index}+22'(lane))<22'(N))begin
                word_strong_mask[lane]=state_rsp_word[lane*2+:2]==2;
                word_has_claimed=word_has_claimed || state_rsp_word[lane*2+:2]==3;
                word_has_strong=word_has_strong || state_rsp_word[lane*2+:2]==2;
            end
        end
        seed_lane=0;
        for(integer lane=7;lane>=0;lane=lane-1)
            if(seed_pending[lane])seed_lane=3'(lane);
    end
    logic [20:0] division_bits,quotient;
    logic [11:0] remainder;
    logic [4:0] division_remaining;
    logic [10:0] current_x,current_y;
    logic signed [12:0] dx,dy,next_x,next_y;
    logic signed [22:0] neighbor_index;
    // Three exact restoring-division steps per clock: 21 bits / 3 = 7
    // clocks, with the same quotient/remainder and generic WIDTH semantics.
    // This is not an approximate reciprocal and does not limit edge tracing.
    wire [12:0] trial0={remainder,division_bits[20]};
    wire take0=trial0>=DIVISOR;
    wire [12:0] rem0=take0?trial0-DIVISOR:trial0;
    wire [12:0] trial1={rem0[11:0],division_bits[19]};
    wire take1=trial1>=DIVISOR;
    wire [12:0] rem1=take1?trial1-DIVISOR:trial1;
    wire [12:0] trial2={rem1[11:0],division_bits[18]};
    wire take2=trial2>=DIVISOR;
    wire [12:0] rem2=take2?trial2-DIVISOR:trial2;
    // 1920 = 128*15. For every legal 1080p index:
    // floor(index/1920) = (floor(index/128)*17477)>>18 exactly.
    // 17477=ceil(2^18/15); the bounded input makes the error <1/15.
    // One registered DSP product is captured on POP reply; DIVIDE consumes
    // it next clock. Other widths retain the exact generic divider.
    wire [47:0] coordinate_product;
    wire [10:0] fast_y=coordinate_product[28:18];
    wire [20:0] fast_row_base=({10'd0,fast_y}<<11)-({10'd0,fast_y}<<7);
    wire [21:0] fast_x={1'b0,current_index}-{1'b0,fast_row_base};
    generate if(WIDTH==1920)begin:coordinate_1920
        EFX_DSP48 #(.SIGNED(0),.O_REG(1),.RST_SYNC(1),.N_SEL("C")) multiply(
            .A({5'd0,queue_rsp_index[20:7]}),.B(18'd17477),.C(18'd0),.CASCIN(48'd0),
            .OP(2'b00),.SHIFT_ENA(1'b0),.CLK(clk),
            .CE(queue_rsp_valid && queue_rsp_ready && !queue_req_push),.RST(rst),
            .O(coordinate_product),.CASCOUT(),.OVFL());
    end else begin:coordinate_generic
        assign coordinate_product=48'd0;
    end endgenerate
    wire matching_cancel=cancel_valid && cancel_id==((state==IDLE)?job_id:held_job_id);
    wire cancellation=cancel_sticky || matching_cancel;

    initial if(WIDTH<6 || WIDTH>1920 || WIDTH%2!=0 || HEIGHT<5 || HEIGHT>1080)
        $fatal(1,"Unsupported hysteresis geometry");
    assign job_ready=!rst && state==IDLE;
    assign state_req_valid=!rst && state==STATE_REQUEST;
    assign state_rsp_ready=!rst && state==STATE_WAIT;
    assign queue_req_valid=!rst && state==QUEUE_REQUEST;
    assign queue_rsp_ready=!rst && state==QUEUE_WAIT;
    assign pixel_valid=!rst && state==PIXEL_HELD;
    assign done_valid=!rst && state==DONE_HELD;
    assign pixel_job_id=held_job_id;
    assign done_job_id=held_job_id;

    always_comb begin
        dx=0;dy=0;
        case(neighbor)
            0:begin dx=-13'sd1;dy=-13'sd1;end
            1:dy=-13'sd1;
            2:begin dx=13'sd1;dy=-13'sd1;end
            3:dx=-13'sd1;
            4:dx=13'sd1;
            5:begin dx=-13'sd1;dy=13'sd1;end
            6:dy=13'sd1;
            7:begin dx=13'sd1;dy=13'sd1;end
        endcase
        next_x=$signed({2'd0,current_x})+dx;
        next_y=$signed({2'd0,current_y})+dy;
        neighbor_index=$signed({2'd0,current_index})+$signed({{10{dx[12]}},dx});
        if(dy<0)neighbor_index=neighbor_index-ROW_OFFSET;
        else if(dy>0)neighbor_index=neighbor_index+ROW_OFFSET;
    end

    // Neighbor memo contains only immutable facts in ONE job: state0 never
    // becomes an edge; state3 has already completed its atomic claim. All
    // strong seeds are also claimable during a component flood. A weak state1
    // is NEVER skipped unless this successful response claimed that pixel.
    // Eight fully associative words cover three rows and word boundaries.
    // A stale weak bit merely causes an extra real request, never a lost edge.
    // The sole state writer is this serialized engine; next job clears validity.
    logic [7:0] memo_valid;
    logic [17:0] memo_word_index[0:7];
    logic [7:0] memo_skip_mask[0:7];
    logic [2:0] memo_replace,memo_update_way;
    logic memo_update_hit,memo_neighbor_skip;
    logic [7:0] response_skip_mask,memo_neighbor_mask;
    logic [7:0] memo_lanes_ahead;
    logic [3:0] memo_next_neighbor;
    always_comb begin
        memo_neighbor_skip=0;memo_neighbor_mask=0;memo_update_hit=0;memo_update_way=memo_replace;
        response_skip_mask=0;
        for(integer entry=0;entry<8;entry=entry+1)begin
            if(memo_valid[entry] && memo_word_index[entry]==neighbor_index[20:3])
                memo_neighbor_mask=memo_neighbor_mask | memo_skip_mask[entry];
            if(memo_valid[entry] && memo_word_index[entry]==state_req_index[20:3])begin
                memo_update_hit=1;memo_update_way=3'(entry);
            end
        end
        // Advance across a consecutive run only within this SAME memo word.
        // Shift inserts zeros across word boundaries; no hint from another row
        // or an unknown/weak lane can bypass its atomic claim and queue push.
        memo_lanes_ahead=memo_neighbor_mask >> neighbor_index[2:0];
        memo_neighbor_skip=memo_lanes_ahead[0];
        memo_next_neighbor={1'b0,neighbor}+4'd1;
        if(memo_neighbor_skip)case(neighbor)
            0,5:if(memo_lanes_ahead[1])begin
                memo_next_neighbor={1'b0,neighbor}+4'd2;
                if(current_x<11'(WIDTH-1) && memo_lanes_ahead[2])
                    memo_next_neighbor={1'b0,neighbor}+4'd3;
            end
            1,6:if(current_x<11'(WIDTH-1) && memo_lanes_ahead[1])
                memo_next_neighbor={1'b0,neighbor}+4'd2;
            3:if(current_x<11'(WIDTH-1) && memo_lanes_ahead[2])
                memo_next_neighbor=5;
            default:begin end
        endcase
        // Successful scalar replies carry the pre-claim word. Upgrade only
        // the claimed lane, and only after the reply has passed all checks.
        for(integer lane=0;lane<8;lane=lane+1)
            response_skip_mask[lane]=state_rsp_word[lane*2+:2]==0 || state_rsp_word[lane*2+:2]==3;
        if(state_rsp_claimed)response_skip_mask[state_req_index[2:0]]=1;
    end

    task automatic finish_task(input logic [1:0] result,input logic [7:0] error_code);
        begin outcome<=result;reason<=error_code;state<=DONE_HELD;end
    endtask
    task automatic class_operation(input logic [1:0] op,input logic [20:0] index,input logic [1:0] purpose);
        begin state_req_op<=op;state_req_index<=index;state_purpose<=purpose;state<=STATE_REQUEST;end
    endtask
    task automatic push_operation(input logic [20:0] index,input logic [1:0] purpose);
        begin
            if(enqueue_count>=CAPACITY)finish_task(1,2);
            else begin queue_req_push<=1;queue_req_index<=index;queue_purpose<=purpose;state<=QUEUE_REQUEST;end
        end
    endtask
    task automatic advance_seed;
        begin
            // Each selected seed still completes its atomic claim AND queue push.
            // Only then may the next bit from the saved word be consumed.
            state<=SEED_SELECT;
        end
    endtask
    task automatic advance_neighbor;
        begin
            if(neighbor==7)state<=POP_NEXT;
            else begin neighbor<=neighbor+3'd1;state<=NEXT_NEIGHBOR;end
        end
    endtask

    always_ff @(posedge clk) begin
        if(rst)begin
            state<=IDLE;held_job_id<=0;cancel_sticky<=0;outcome<=0;reason<=0;
            memo_valid<=0;memo_replace<=0;
            enqueue_count<=0;pop_count<=0;output_count<=0;
            state_req_op<=0;state_req_index<=0;queue_req_push<=0;queue_req_index<=0;
            pixel_index<=0;pixel_edge<=0;pixel_edges<=0;seed_index<=0;export_index<=0;seed_pending<=0;export_remaining<=0;
        end else begin
            if(state!=IDLE && state!=DONE_HELD && matching_cancel)cancel_sticky<=1;
            // 未公开新操作的计算状态可直接取消；已公开槽必须真实交付/终结。
            if(state!=IDLE && state!=DONE_HELD && state!=STATE_REQUEST && state!=STATE_WAIT &&
               state!=QUEUE_REQUEST && state!=QUEUE_WAIT && state!=PIXEL_HELD && cancellation)
                finish_task(2,0);
            else case(state)
                IDLE:if(job_valid && job_ready)begin
                    held_job_id<=job_id;cancel_sticky<=matching_cancel;outcome<=0;reason<=0;
                    memo_valid<=0;memo_replace<=0;
                    enqueue_count<=0;pop_count<=0;output_count<=0;seed_index<=0;export_index<=0;seed_pending<=0;export_remaining<=0;
                    if(matching_cancel)finish_task(2,0);else state<=SEED_NEXT;
                end
                SEED_NEXT:class_operation(0,seed_index,3);
                SEED_SELECT:if(|seed_pending)begin
                    seed_pending[seed_lane]<=0;
                    class_operation(1,seed_index+21'(seed_lane),0);
                end else if(({1'b0,seed_index}+22'd8)>=22'(N))begin export_index<=0;state<=EXPORT_NEXT;end
                else begin
                    seed_index<=seed_index+21'd8;
                    class_operation(0,seed_index+21'd8,3);
                end
                POP_NEXT:if(pop_count==enqueue_count)begin seed_pending<=0;state<=SEED_NEXT;end
                    else if(pop_count>enqueue_count)finish_task(1,2);
                    else begin queue_req_push<=0;queue_req_index<=0;queue_purpose<=2;state<=QUEUE_REQUEST;end
                STATE_REQUEST:if(state_req_ready)state<=STATE_WAIT;
                STATE_WAIT:if(state_rsp_valid && state_rsp_ready)begin
                    if(state_rsp_aborted)begin
                        if(cancellation)finish_task(2,0);else finish_task(1,1);
                    end else if(state_rsp_error)finish_task(1,3);
                    else if(state_rsp_claimed!=((state_purpose==0 && state_rsp_old==2) ||
                                               (state_purpose==1 && (state_rsp_old==1 || state_rsp_old==2))) ||
                            (state_purpose==0 && state_rsp_old==3) ||
                            (state_purpose==2 && state_rsp_old==2))finish_task(1,1);
                    else if(cancellation)finish_task(2,0);
                    else if(state_purpose==3)begin
                        // Re-read after each completed flood; prior strong lanes may now be 3.
                        if(state_req_index[2:0]!=0)finish_task(1,1);
                        else if(|word_strong_mask)begin seed_pending<=word_strong_mask;state<=SEED_SELECT;end
                        else if(({1'b0,seed_index}+22'd8)>=22'(N))begin export_index<=0;state<=EXPORT_NEXT;end
                        else begin
                            seed_index<=seed_index+21'd8;
                            class_operation(0,seed_index+21'd8,3);
                        end
                    end else if(state_purpose==2)begin
                        // BFS is complete. A remaining strong state is an invariant failure.
                        if(word_has_strong || state_req_index[2:0]!=0)finish_task(1,1);
                        else begin
                            pixel_index<=export_index;pixel_edge<=state_rsp_word[1:0]==3;
                            for(integer lane=0;lane<8;lane=lane+1)
                                pixel_edges[lane]<=({1'b0,export_index}+22'(lane)<22'(N)) &&
                                    state_rsp_word[2*lane+:2]==3;
                            export_remaining<={2'b0,state_rsp_word[15:2]};state<=PIXEL_HELD;
                        end
                    end else begin
                        // No entry is installed on error, cancellation, or a
                        // failed claim invariant. Replacement only loses hints.
                        if(state_purpose==1)begin
                            memo_valid[memo_update_way]<=1;
                            memo_word_index[memo_update_way]<=state_req_index[20:3];
                            memo_skip_mask[memo_update_way]<=response_skip_mask;
                            if(!memo_update_hit)memo_replace<=memo_replace+3'd1;
                        end
                        if(state_rsp_claimed)push_operation(state_req_index,state_purpose);
                        else if(state_purpose==0)advance_seed();else advance_neighbor();
                    end
                end
                QUEUE_REQUEST:if(queue_req_ready)state<=QUEUE_WAIT;
                QUEUE_WAIT:if(queue_rsp_valid && queue_rsp_ready)begin
                    if(queue_rsp_aborted)begin
                        if(cancellation)finish_task(2,0);else finish_task(1,1);
                    end else if(queue_rsp_error)finish_task(1,3);
                    else if(queue_rsp_index>=21'(N) || (queue_req_push && queue_rsp_index!=queue_req_index))finish_task(1,2);
                    else begin
                        if(queue_req_push)enqueue_count<=enqueue_count+22'd1;else pop_count<=pop_count+22'd1;
                        if(cancellation)finish_task(2,0);
                        else if(queue_purpose==0)begin seed_pending<=0;state<=POP_NEXT;end
                        else if(queue_purpose==1)advance_neighbor();
                        else begin
                            current_index<=queue_rsp_index;division_bits<=queue_rsp_index;
                            quotient<=0;remainder<=0;division_remaining<=7;state<=DIVIDE;
                        end
                    end
                end
                DIVIDE:if(WIDTH==1920)begin
                    if(fast_y>=11'(HEIGHT) || fast_x>=22'(WIDTH))finish_task(1,2);
                    else begin current_y<=fast_y;current_x<=fast_x[10:0];neighbor<=0;state<=NEXT_NEIGHBOR;end
                end else begin
                    division_bits<={division_bits[17:0],3'b0};
                    quotient<={quotient[17:0],take0,take1,take2};remainder<=rem2[11:0];
                    division_remaining<=division_remaining-5'd1;
                    if(division_remaining==1)state<=COORD;
                end
                COORD:if(quotient>=21'(HEIGHT) || remainder>=12'(WIDTH))finish_task(1,2);
                    else begin current_y<=quotient[10:0];current_x<=remainder[10:0];neighbor<=0;state<=NEXT_NEIGHBOR;end
                NEXT_NEIGHBOR:if(next_x<0 || next_x>=13'(WIDTH) || next_y<0 || next_y>=13'(HEIGHT))advance_neighbor();
                    else if(neighbor_index<0 || neighbor_index>=23'(N))finish_task(1,2);
                    else if(memo_neighbor_skip)begin
                        if(memo_next_neighbor>=8)state<=POP_NEXT;
                        else begin neighbor<=memo_next_neighbor[2:0];state<=NEXT_NEIGHBOR;end
                    end
                    else class_operation(2,neighbor_index[20:0],1);
                EXPORT_NEXT:class_operation(0,export_index,2);
                PIXEL_HELD:if(pixel_ready)begin
                    output_count<=output_count+export_step;
                    if(cancellation)finish_task(2,0);
                    else if(({1'b0,export_index}+export_step)>=22'(N))finish_task(0,0);
                    else if(EXPORT_LANES==8)begin
                        export_index<=export_index+21'd8;
                        class_operation(0,export_index+21'd8,2);
                    end
                    else begin
                        export_index<=export_index+21'd1;
                        // Each word was read after BFS completion, so it cannot change.
                        // Retain all pixels/metadata under backpressure; no speculative consumption.
                        if(export_index[2:0]==7)class_operation(0,export_index+21'd1,2);
                        else begin
                            pixel_index<=export_index+21'd1;
                            pixel_edge<=export_remaining[1:0]==3;
                            export_remaining<={2'b0,export_remaining[15:2]};
                        end
                    end
                end
                DONE_HELD:if(done_ready)state<=IDLE;
                default:finish_task(1,1);
            endcase
        end
    end
endmodule
