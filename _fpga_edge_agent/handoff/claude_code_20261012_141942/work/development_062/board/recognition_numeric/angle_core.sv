// AN01…06：一份请求、一次预约；字捕获后下一状态才读，取消必须收旧返回。
module angle_core #(parameter bit BORROW_REQUEST=0)(input logic clk,rst,
    input logic req_valid,input logic [621:0] req_body,output logic req_ready,
    output logic rsp_valid,output logic [584:0] rsp_body,input logic rsp_ready,
    input logic cancel_valid,input logic [175:0] cancel_id,output logic quiet);
    import angle_protocol_pkg::*;
    typedef enum logic [4:0] {IDLE,CHECK,PREP,SELECT,READ0,READ1,READ2,READ_DRAIN,MUL0,MUL1,
        PRODUCT_DRAIN,DECIDE,RECOVER,RESTORE,COORD,SIGN,SUM,ROUND,QUALIFY,PACK,HELD,DROP_WAIT} state_t;
    state_t state;
    wire [621:0] held_request;
    logic [384:0] result_value;
    logic [1:0] result_outcome;logic [7:0] result_reason;
    logic cancel_sticky,rom_pending,rom_pending_bank,product_pending,product_destination;
    logic [1:0] rom_word_index,coefficient_phase;
    logic [8:0] rom_base,coefficient_index;
    logic [59:0] constant_words;
    logic signed [18:0] canonical_x,canonical_y;
    logic [17:0] minor_magnitude,major_magnitude;
    logic half;logic [7:0] lo,hi,mid;logic [3:0] compare_count;
    logic signed [16:0] coefficient_c,coefficient_s;
    logic signed [11:0] centered_x,centered_y;
    logic [47:0] first_product,second_product;
    logic signed [28:0] signed_product_x,signed_product_y;
    logic signed [29:0] projection_sum;
    logic signed [12:0] rounded_q;
    wire [4:0] kind=held_request[KIND_LO+:5];
    wire vector_operation=kind==8 || kind==9;
    wire req_fire=req_valid && req_ready;
    generate if(BORROW_REQUEST)begin:borrowed_request
        // 调用者从请求接受沿到HELD真实消费沿保持整份正文；默认路径仍自行快照。
        assign held_request=req_body;
    end else begin:copied_request
        logic [621:0] snapshot;
        assign held_request=snapshot;
        always_ff @(posedge clk)begin
            if(rst)snapshot<=0;
            else if(req_fire)snapshot<=req_body;
        end
    end endgenerate
    wire matching_cancel=cancel_valid && ((state==IDLE && req_fire && cancel_id==req_body[175:0]) ||
        (state!=IDLE && cancel_id==held_request[175:0]));
    wire cancel_requested=matching_cancel || cancel_sticky;
    wire [9:0] input_check=check_request(held_request);
    logic rom_re,rom_bank,product_start,private_failure;
    logic [8:0] rom_address;wire [19:0] rom_data;
    logic [17:0] product_a;logic [29:0] product_b;wire [47:0] product_data;wire product_valid;
    wire signed [48:0] cross_value;wire cross_positive;
    wire signed [12:0] round_result;
    logic signed [19:0] raw_x,raw_y,normalized_x,normalized_y;
    logic [19:0] absolute_x;
    logic half_input;logic [8:0] target_theta,mid_sum;logic [7:0] selected_mid;
    logic [9:0] restored_theta;logic [10:0] full_theta;
    logic [59:0] complete_boundary;
    logic signed [12:0] wide_x,wide_y,shifted_q;
    logic signed [48:0] restored_product_x,restored_product_y;

    function automatic [17:0] abs_coord(input logic signed [11:0] x);
        logic signed [12:0] wide;begin wide=$signed({x[11],x});abs_coord=wide[12]?-$signed(wide):wide;end
    endfunction
    function automatic [29:0] abs_coefficient(input logic signed [16:0] x);
        logic signed [17:0] wide;begin wide=$signed({x[16],x});abs_coefficient=wide[17]?-$signed(wide):wide;end
    endfunction
    function automatic logic fits_s29(input logic signed [48:0] x);
        fits_s29=x==$signed({{20{x[28]}},x[28:0]});
    endfunction

    angle_rom constants(.clk(clk),.re(rom_re),.bank(rom_bank),.address(rom_address),.data(rom_data));
    angle_product multiply(.clk(clk),.rst(rst),.start(product_start),.a(product_a),.b(product_b),.product(product_data),.valid(product_valid));
    angle_cross compare(.m_c(first_product),.m_s(second_product),.cross_value(cross_value),.positive(cross_positive));
    project_round rounding(.p(projection_sum),.q(round_result));
    assign req_ready=!rst && state==IDLE && !rom_pending && !product_pending;
    assign rsp_valid=!rst && state==HELD;
    // PACK把终态及取消决定存入结果字段；HELD正文不再读取实时cancel。
    assign rsp_body=pack_response(held_request,result_outcome,result_reason,
        result_outcome==VALUE?result_value:385'd0);
    assign quiet=!rst && state==IDLE && !rom_pending && !product_pending;

    always_comb begin
        raw_x=kind==8?$signed({{9{held_request[232]}},held_request[222+:11]}):$signed({held_request[240],held_request[222+:19]});
        raw_y=kind==8?$signed({{9{held_request[243]}},held_request[233+:11]}):$signed({held_request[259],held_request[241+:19]});
        half_input=raw_y<0 || (raw_y==0 && raw_x<0);
        normalized_x=half_input?-raw_x:raw_x;normalized_y=half_input?-raw_y:raw_y;
        absolute_x=normalized_x<0?-normalized_x:normalized_x;
        target_theta=kind==16?held_request[222+:9]:held_request[244+:9];
        mid_sum={1'b0,lo}+{1'b0,hi};selected_mid=mid_sum[8:1];
        if(canonical_x>=0)restored_theta=($unsigned(canonical_x)>=$unsigned(canonical_y))?{2'd0,lo}:10'd256-{2'd0,lo};
        else restored_theta=($unsigned(-canonical_x)<$unsigned(canonical_y))?10'd256+{2'd0,lo}:10'd512-{2'd0,lo};
        full_theta={1'b0,restored_theta}+(half?11'd512:11'd0);
        complete_boundary={rom_data,constant_words[39:0]};
        wide_x=($signed({2'd0,held_request[222+:11]})<<<1)-($signed({2'd0,held_request[W_LO+:11]})-13'sd1);
        wide_y=($signed({2'd0,held_request[233+:11]})<<<1)-($signed({2'd0,held_request[H_LO+:11]})-13'sd1);
        restored_product_x=(centered_x[11]^coefficient_c[16])?-$signed({1'b0,first_product}):$signed({1'b0,first_product});
        restored_product_y=(centered_y[11]^coefficient_s[16])?-$signed({1'b0,second_product}):$signed({1'b0,second_product});
        shifted_q=rounded_q+13'sd138;
        private_failure=(product_pending && !product_valid) || (rom_pending && (rom_word_index>2 || rom_pending_bank!=!vector_operation));
        case(state)
            READ1:private_failure=private_failure || !rom_pending || rom_word_index!=0;
            READ2:private_failure=private_failure || !rom_pending || rom_word_index!=1 || !vector_operation;
            READ_DRAIN:private_failure=private_failure || !rom_pending || rom_word_index!=(vector_operation?2:1);
            MUL1:private_failure=private_failure || !product_pending || product_destination;
            PRODUCT_DRAIN:private_failure=private_failure || !product_pending || !product_destination;
            default:begin end
        endcase
        rom_bank=!vector_operation;rom_re=0;rom_address=rom_base;product_start=0;product_a=0;product_b=0;
        if(!rst && !cancel_requested && !private_failure)begin
            case(state)
                READ0:begin rom_re=1;rom_address=rom_base;end
                READ1:begin rom_re=1;rom_address=rom_base+9'd1;end
                READ2:begin rom_re=1;rom_address=rom_base+9'd2;end
                MUL0:begin
                    product_start=1;product_a=vector_operation?minor_magnitude:abs_coord(centered_x);
                    product_b=vector_operation?constant_words[29:0]:abs_coefficient(coefficient_c);
                end
                MUL1:begin
                    product_start=1;product_a=vector_operation?major_magnitude:abs_coord(centered_y);
                    product_b=vector_operation?constant_words[59:30]:abs_coefficient(coefficient_s);
                end
                default:begin end
            endcase
        end
    end

    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;result_value<=0;result_outcome<=VALUE;result_reason<=NONE;
            cancel_sticky<=0;rom_pending<=0;product_pending<=0;compare_count<=0;
        end else begin
            rom_pending<=rom_re;product_pending<=product_start;
            if(rom_re)begin rom_pending_bank<=rom_bank;rom_word_index<=state==READ0?2'd0:(state==READ1?2'd1:2'd2);end
            if(product_start)product_destination<=state==MUL1;
            // 即使本沿取消，旧预约仍capture，再由DROP_WAIT丢弃，不等消费者ready。
            if(rom_pending)case(rom_word_index)
                0:constant_words[19:0]<=rom_data;1:constant_words[39:20]<=rom_data;2:constant_words[59:40]<=rom_data;default:begin end
            endcase
            if(product_pending && product_valid)begin
                if(product_destination)second_product<=product_data;else first_product<=product_data;
            end
            if(matching_cancel && state!=HELD)cancel_sticky<=1;
            if(state!=IDLE && state!=HELD && state!=PACK && state!=DROP_WAIT && cancel_requested)begin
                result_outcome<=CANCEL_DROP;result_reason<=NONE;result_value<=0;state<=(rom_pending || product_pending)?DROP_WAIT:PACK;
            end else if(state!=IDLE && state!=HELD && state!=PACK && state!=DROP_WAIT && private_failure)begin
                result_outcome<=FRAME_FAIL;result_reason<=INTERNAL;result_value<=0;state<=PACK;
            end else case(state)
                IDLE:if(req_fire)begin
                    result_value<=0;result_outcome<=VALUE;result_reason<=NONE;
                    cancel_sticky<=matching_cancel;compare_count<=0;state<=CHECK;
                end
                CHECK:if(input_check!=0)begin result_outcome<=input_check[1:0];result_reason<=input_check[9:2];state<=PACK;end
                    else state<=PREP;
                PREP:begin
                    if(vector_operation)begin
                        canonical_x<=normalized_x[18:0];canonical_y<=normalized_y[18:0];half<=half_input;
                        minor_magnitude<=absolute_x<$unsigned(normalized_y)?absolute_x[17:0]:normalized_y[17:0];
                        major_magnitude<=absolute_x<$unsigned(normalized_y)?normalized_y[17:0]:absolute_x[17:0];lo<=0;hi<=128;
                    end else if(target_theta<=128)begin coefficient_index<=target_theta;coefficient_phase<=0;end
                    else if(target_theta<=256)begin coefficient_index<=9'd256-target_theta;coefficient_phase<=1;end
                    else if(target_theta<=384)begin coefficient_index<=target_theta-9'd256;coefficient_phase<=2;end
                    else begin coefficient_index<=10'd512-{1'b0,target_theta};coefficient_phase<=3;end
                    state<=SELECT;
                end
                SELECT:if(vector_operation)begin
                    if(lo==hi)state<=RECOVER;
                    else begin mid<=selected_mid;rom_base<={1'b0,selected_mid}+({1'b0,selected_mid}<<1);state<=READ0;end
                end else begin rom_base<=coefficient_index<<1;state<=READ0;end
                READ0:state<=READ1;
                READ1:state<=vector_operation?READ2:READ_DRAIN;
                READ2:state<=READ_DRAIN;
                READ_DRAIN:if(vector_operation)begin
                    if(complete_boundary[59:30]==0 || complete_boundary[59:30]>=complete_boundary[29:0])begin
                        result_outcome<=FRAME_FAIL;result_reason<=INTERNAL;state<=PACK;
                    end else state<=MUL0;
                end else state<=RESTORE;
                MUL0:state<=MUL1;
                MUL1:state<=PRODUCT_DRAIN;
                PRODUCT_DRAIN:state<=vector_operation?DECIDE:SIGN;
                DECIDE:if(compare_count>=8 || lo>=hi)begin result_outcome<=FRAME_FAIL;result_reason<=INTERNAL;state<=PACK;end
                    else begin if(cross_positive)lo<=mid+8'd1;else hi<=mid;compare_count<=compare_count+4'd1;state<=SELECT;end
                RECOVER:begin
                    if(kind==8)result_value[8:0]<=restored_theta[8:0];
                    else begin result_value[9:0]<=restored_theta;result_value[10]<=half;result_value[20:11]<=full_theta[9:0];result_value[26:21]<=full_theta[9:4];end
                    state<=PACK;
                end
                RESTORE:if(constant_words[19:16]!=0 || constant_words[39:36]!=0 || constant_words[15:0]>32768 ||
                    constant_words[35:20]>constant_words[15:0] ||
                    (coefficient_index==0 && (constant_words[15:0]!=32768 || constant_words[35:20]!=0)) ||
                    (coefficient_index==128 && constant_words[15:0]!=constant_words[35:20]))begin
                        result_outcome<=FRAME_FAIL;result_reason<=INTERNAL;state<=PACK;
                    end else begin
                        case(coefficient_phase)
                            0:begin coefficient_c<=$signed({1'b0,constant_words[15:0]});coefficient_s<=$signed({1'b0,constant_words[35:20]});end
                            1:begin coefficient_c<=$signed({1'b0,constant_words[35:20]});coefficient_s<=$signed({1'b0,constant_words[15:0]});end
                            2:begin coefficient_c<=-$signed({1'b0,constant_words[35:20]});coefficient_s<=$signed({1'b0,constant_words[15:0]});end
                            3:begin coefficient_c<=-$signed({1'b0,constant_words[15:0]});coefficient_s<=$signed({1'b0,constant_words[35:20]});end
                        endcase
                        state<=kind==16?QUALIFY:COORD;
                    end
                COORD:if(wide_x < -13'sd2048 || wide_x>13'sd2047 || wide_y < -13'sd2048 || wide_y>13'sd2047)begin
                    result_outcome<=FRAME_FAIL;result_reason<=OVERFLOW;state<=PACK;
                end else begin centered_x<=wide_x[11:0];centered_y<=wide_y[11:0];state<=MUL0;end
                SIGN:if(!fits_s29(restored_product_x) || !fits_s29(restored_product_y))begin
                    result_outcome<=FRAME_FAIL;result_reason<=OVERFLOW;state<=PACK;
                end else begin signed_product_x<=restored_product_x[28:0];signed_product_y<=restored_product_y[28:0];state<=SUM;end
                SUM:begin projection_sum<=$signed({signed_product_x[28],signed_product_x})+$signed({signed_product_y[28],signed_product_y});state<=ROUND;end
                ROUND:begin rounded_q<=round_result;state<=QUALIFY;end
                QUALIFY:begin
                    if(kind==16)begin result_value[0+:17]<=coefficient_c;result_value[17+:17]<=coefficient_s;end
                    else if(rounded_q < -13'sd138 || rounded_q>13'sd138 || shifted_q<0 || shifted_q>276)begin
                        result_outcome<=FRAME_FAIL;result_reason<=OVERFLOW;
                    end else begin result_value[8:0]<=rounded_q[8:0];result_value[17:9]<=shifted_q[8:0];end
                    state<=PACK;
                end
                DROP_WAIT:if(!rom_pending && !product_pending)state<=PACK;
                PACK:begin
                    if(cancel_requested)begin
                        result_outcome<=CANCEL_DROP;result_reason<=NONE;result_value<=0;
                    end
                    state<=HELD;
                end
                HELD:if(rsp_ready)begin state<=IDLE;cancel_sticky<=0;end
                default:begin result_outcome<=FRAME_FAIL;result_reason<=INTERNAL;result_value<=0;state<=PACK;end
            endcase
        end
    end
endmodule
