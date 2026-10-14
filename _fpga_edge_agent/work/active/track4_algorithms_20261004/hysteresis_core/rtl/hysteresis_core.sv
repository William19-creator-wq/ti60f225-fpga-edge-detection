// HY01…04：精确八邻域；图/queue由同job独占服务拥有，TB服务不等于DDR硬件。
module hysteresis_core #(
    parameter integer unsigned WIDTH=1920, HEIGHT=1080
)(
    input logic clk,rst,
    input logic job_valid, input logic [63:0] job_id, output wire job_ready,
    input logic cancel_valid, input logic [63:0] cancel_id,
    output wire state_req_valid, input logic state_req_ready,
    output logic [1:0] state_req_op, output logic [20:0] state_req_index,
    input logic state_rsp_valid, output wire state_rsp_ready,
    input logic [1:0] state_rsp_old, input logic state_rsp_claimed,state_rsp_error,
    output wire queue_req_valid, input logic queue_req_ready,
    output logic queue_req_push, output logic [20:0] queue_req_index,
    input logic queue_rsp_valid, output wire queue_rsp_ready,
    input logic [20:0] queue_rsp_index, input logic queue_rsp_error,
    output wire pixel_valid, input logic pixel_ready,
    output logic [20:0] pixel_index, output logic pixel_edge, output wire [63:0] pixel_job_id,
    output wire done_valid, input logic done_ready,
    output wire [63:0] done_job_id, output logic [1:0] outcome, output logic [7:0] reason,
    output logic [21:0] enqueue_count,pop_count,output_count
);
    localparam integer unsigned N=WIDTH*HEIGHT;
    localparam logic [20:0] LAST_INDEX=21'(N-1);
    localparam logic [21:0] CAPACITY=22'(N);
    localparam logic [12:0] DIVISOR=13'(WIDTH);
    localparam logic signed [22:0] ROW_OFFSET=23'(WIDTH);
    typedef enum logic [3:0] {
        IDLE,SEED_NEXT,POP_NEXT,DIVIDE,COORD,NEXT_NEIGHBOR,
        STATE_REQUEST,STATE_WAIT,QUEUE_REQUEST,QUEUE_WAIT,EXPORT_NEXT,PIXEL_HELD,DONE_HELD
    } state_t;
    state_t state;
    logic [63:0] held_job_id;
    logic cancel_sticky;
    logic [20:0] seed_index,current_index,export_index;
    logic [2:0] neighbor;
    logic [1:0] state_purpose,queue_purpose; // seed=0,neighbor=1,export/pop=2
    logic [20:0] division_bits,quotient;
    logic [11:0] remainder;
    logic [4:0] division_remaining;
    logic [10:0] current_x,current_y;
    logic signed [12:0] dx,dy,next_x,next_y;
    logic signed [22:0] neighbor_index;
    wire [12:0] division_trial={remainder,division_bits[20]};
    wire division_one=division_trial>=DIVISOR;
    wire [12:0] reduced_trial=division_one?division_trial-DIVISOR:division_trial;
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
            if(seed_index==LAST_INDEX)state<=POP_NEXT;
            else begin seed_index<=seed_index+21'd1;state<=SEED_NEXT;end
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
            enqueue_count<=0;pop_count<=0;output_count<=0;
            state_req_op<=0;state_req_index<=0;queue_req_push<=0;queue_req_index<=0;
            pixel_index<=0;pixel_edge<=0;seed_index<=0;export_index<=0;
        end else begin
            if(state!=IDLE && state!=DONE_HELD && matching_cancel)cancel_sticky<=1;
            // 未公开新操作的计算状态可直接取消；已公开槽必须真实交付/终结。
            if(state!=IDLE && state!=DONE_HELD && state!=STATE_REQUEST && state!=STATE_WAIT &&
               state!=QUEUE_REQUEST && state!=QUEUE_WAIT && state!=PIXEL_HELD && cancellation)
                finish_task(2,0);
            else case(state)
                IDLE:if(job_valid && job_ready)begin
                    held_job_id<=job_id;cancel_sticky<=matching_cancel;outcome<=0;reason<=0;
                    enqueue_count<=0;pop_count<=0;output_count<=0;seed_index<=0;export_index<=0;
                    if(matching_cancel)finish_task(2,0);else state<=SEED_NEXT;
                end
                SEED_NEXT:class_operation(1,seed_index,0);
                POP_NEXT:if(pop_count==enqueue_count)begin export_index<=0;state<=EXPORT_NEXT;end
                    else if(pop_count>enqueue_count)finish_task(1,2);
                    else begin queue_req_push<=0;queue_req_index<=0;queue_purpose<=2;state<=QUEUE_REQUEST;end
                STATE_REQUEST:if(state_req_ready)state<=STATE_WAIT;
                STATE_WAIT:if(state_rsp_valid && state_rsp_ready)begin
                    if(state_rsp_error)finish_task(1,3);
                    else if(state_rsp_claimed!=((state_purpose==0 && state_rsp_old==2) ||
                                               (state_purpose==1 && state_rsp_old==1)) ||
                            (state_purpose==0 && state_rsp_old==3) ||
                            (state_purpose!=0 && state_rsp_old==2))finish_task(1,1);
                    else if(cancellation)finish_task(2,0);
                    else if(state_purpose==2)begin
                        pixel_index<=export_index;pixel_edge<=state_rsp_old==3;state<=PIXEL_HELD;
                    end else if(state_rsp_claimed)push_operation(state_req_index,state_purpose);
                    else if(state_purpose==0)advance_seed();else advance_neighbor();
                end
                QUEUE_REQUEST:if(queue_req_ready)state<=QUEUE_WAIT;
                QUEUE_WAIT:if(queue_rsp_valid && queue_rsp_ready)begin
                    if(queue_rsp_error)finish_task(1,3);
                    else if(queue_rsp_index>=21'(N) || (queue_req_push && queue_rsp_index!=queue_req_index))finish_task(1,2);
                    else begin
                        if(queue_req_push)enqueue_count<=enqueue_count+22'd1;else pop_count<=pop_count+22'd1;
                        if(cancellation)finish_task(2,0);
                        else if(queue_purpose==0)advance_seed();
                        else if(queue_purpose==1)advance_neighbor();
                        else begin
                            current_index<=queue_rsp_index;division_bits<=queue_rsp_index;
                            quotient<=0;remainder<=0;division_remaining<=21;state<=DIVIDE;
                        end
                    end
                end
                DIVIDE:begin
                    division_bits<={division_bits[19:0],1'b0};
                    quotient<={quotient[19:0],division_one};remainder<=reduced_trial[11:0];
                    division_remaining<=division_remaining-5'd1;
                    if(division_remaining==1)state<=COORD;
                end
                COORD:if(quotient>=21'(HEIGHT) || remainder>=12'(WIDTH))finish_task(1,2);
                    else begin current_y<=quotient[10:0];current_x<=remainder[10:0];neighbor<=0;state<=NEXT_NEIGHBOR;end
                NEXT_NEIGHBOR:if(next_x<0 || next_x>=13'(WIDTH) || next_y<0 || next_y>=13'(HEIGHT))advance_neighbor();
                    else if(neighbor_index<0 || neighbor_index>=23'(N))finish_task(1,2);
                    else class_operation(2,neighbor_index[20:0],1);
                EXPORT_NEXT:class_operation(0,export_index,2);
                PIXEL_HELD:if(pixel_ready)begin
                    output_count<=output_count+22'd1;
                    if(cancellation)finish_task(2,0);
                    else if(export_index==LAST_INDEX)finish_task(0,0);
                    else begin export_index<=export_index+21'd1;state<=EXPORT_NEXT;end
                end
                DONE_HELD:if(done_ready)state<=IDLE;
                default:finish_task(1,1);
            endcase
        end
    end
endmodule
