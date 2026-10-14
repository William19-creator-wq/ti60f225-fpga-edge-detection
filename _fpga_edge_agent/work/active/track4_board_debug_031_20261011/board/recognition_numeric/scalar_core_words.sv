// 192位操作数、385位返回；内部以16位字串行处理，外部沿用完整请求/取消/held协议。
module scalar_core_words #(parameter bit BORROW_PAYLOAD=0)(
    input wire clk,rst,req_valid,output wire req_ready,input wire [621:0] req_body,
    output wire rsp_valid,input wire rsp_ready,output wire [584:0] rsp_body,
    input wire cancel_valid,input wire [175:0] cancel_id,output wire quiet
);
    import scalar_protocol_pkg::*;
    typedef enum logic [5:0] {
        QUIET,CHECK,INITIALIZE,ABS_A,ABS_B,DISPATCH,WORD_READ,WORD_USE,
        MUL_READ,MUL_PRODUCT,MUL_LOW,MUL_HIGH,MUL_ADD,MUL_NEXT,
        ADD_WORD,ADD_EXTEND,COMPARE_WORD,COMPARE_SAVE,
        DIV_GET,DIV_USE,DIV_COMPARE,DIV_DECIDE,DIV_QUOTIENT,DIV_NEXT,
        DIV_ROUND,DIV_ROUND_COMPARE,DIV_ROUND_READ,DIV_ROUND_USE,DIV_RESULT,
        ROOT_SHIFT,ROOT_TRIAL,ROOT_COMPARE,ROOT_DECIDE,ROOT_BIT,ROOT_NEXT,
        ROOT_ROUND,ROOT_ROUND_DECIDE,ROOT_RESULT,RESULT_SIGN,
        ASSEMBLE_READ,ASSEMBLE_USE,QUALIFY,QUALIFY_SCAN,PACK,HELD
    } state_t;
    typedef enum logic [2:0] {COPY_WORDS,ADD_WORDS,SUB_WORDS,NEG_WORDS,
        SHIFT_ONE,SHIFT_TWO,COMPARE_WORDS} operation_t;
    localparam logic [7:0] BA=0,BB=16,BR=32,BQ=48,BT=64,BROOT=80,BP=96,BPRODUCT=160,BZERO=224;
    state_t state,resume_state;
    operation_t operation;
    logic [221:0] held_header;
    wire [399:0] held_payload;
    generate if(BORROW_PAYLOAD)begin:borrowed_input
        assign held_payload=req_body[621:222];
    end else begin:copied_input
        logic [399:0] snapshot;
        assign held_payload=snapshot;
        always_ff @(posedge clk)if(!rst&&req_valid&&req_ready)snapshot<=req_body[621:222];
    end endgenerate
    wire [4:0] kind=held_header[KIND_LO+:5];
    wire [8:0] target=held_header[TARGET_LO+:9];
    wire [191:0] original_a=held_payload[191:0],original_b=held_payload[383:192];
    wire a_negative=held_header[AS_LO]&&original_a[191];
    wire b_negative=held_header[BS_LO]&&original_b[191];
    logic [384:0] full;
    logic [1:0] outcome,comparison,word_carry;
    logic [7:0] reason,initialize_index,left_base,right_base,destination_base;
    logic cancel_seen,negative_result,result_signed,accepted_bit;
    logic [4:0] word_index,word_count,assemble_index,add_index,qualify_word;
    logic [3:0] multiply_i,multiply_j;
    logic [31:0] product;
    logic [7:0] divide_remaining;
    logic [6:0] root_remaining;
    logic add_negative,add_carry,qualify_bad,qualify_word_bad;
    logic [7:0] check_reason;
    // 同步读副本在同一真实写沿更新。复位不清数据；每次请求完整初始化。
    logic [15:0] memory_left[0:255],memory_right[0:255];
    logic [15:0] read_left,read_right,write_data;
    logic [7:0] read_address_left,read_address_right,write_address;
    logic write_enable;
    always_ff @(posedge clk)begin
        read_left<=memory_left[read_address_left];
        read_right<=memory_right[read_address_right];
        if(write_enable)begin
            memory_left[write_address]<=write_data;
            memory_right[write_address]<=write_data;
        end
    end
    assign req_ready=!rst&&state==QUIET;
    assign quiet=req_ready;
    assign rsp_valid=!rst&&state==HELD;
    assign rsp_body={outcome==VALUE?full:385'd0,reason,outcome,target,kind,held_header[175:0]};
    wire current_cancel=cancel_valid&&cancel_id==held_header[175:0];
    wire [207:0] add_a_view={{16{a_negative}},original_a};
    wire [207:0] add_b_view={{16{b_negative}},original_b};
    logic [15:0] alu_left,alu_right;
    logic alu_carry;
    wire [16:0] alu_sum={1'b0,alu_left}+{1'b0,alu_right}+{16'd0,alu_carry};
    wire [1:0] alu_next_carry=operation==SUB_WORDS?{1'b0,!alu_sum[16]}:{1'b0,alu_sum[16]};
    wire [17:0] shift_two_value={read_left,2'b0}|{16'd0,word_carry};
    wire [16:0] shift_one_value={read_left,1'b0}|{16'd0,word_carry[0]};
    wire qualify_extension=result_signed&&full[384];
    wire [399:0] qualify_view={{15{qualify_extension}},full};
    wire [15:0] qualify_piece=qualify_view[qualify_word*16+:16];
    wire [8:0] qualify_cutoff=target-(result_signed?9'd1:9'd0);
    always_comb begin
        check_reason=NONE;
        if(held_header[W_LO+:11]<6||held_header[W_LO+:11]>1920||held_header[W_LO]||
           held_header[H_LO+:11]<5||held_header[H_LO+:11]>1080)check_reason=COORD;
        else if(held_header[VERSION_LO+:8]!=1||held_header[96+:8]!=0||kind>7)check_reason=UNSUPPORTED;
        else if(target==0||target>maximum_target(kind)||(kind==5&&target!=2)||
            ((kind==4||kind==6||kind==7)&&(held_header[AS_LO]||held_header[BS_LO])))check_reason=FORMAT;
        else if(((kind==4||kind==7)&&|held_payload[399:192])||
                (!(kind==4||kind==7)&&|held_payload[399:384]))check_reason=FORMAT;
        else if((kind==3||kind==6)&&original_b==0)check_reason=DIV_ZERO;
        else if(kind==3&&b_negative)check_reason=FORMAT;
        qualify_word_bad=0;
        for(integer lane=0;lane<16;lane=lane+1)
            if(({qualify_word,4'd0}+9'(lane))>=qualify_cutoff&&
                qualify_piece[lane]!=qualify_extension)qualify_word_bad=1;
        alu_left=read_left;alu_right=read_right;alu_carry=word_carry[0];
        if(operation==SUB_WORDS)begin alu_right=~read_right;alu_carry=!word_carry[0];end
        if(operation==NEG_WORDS)begin alu_left=~read_left;alu_right=0;end
        if(state==ADD_WORD)begin
            alu_left=add_a_view[add_index*16+:16];
            alu_right=kind==2?~add_b_view[add_index*16+:16]:add_b_view[add_index*16+:16];
            alu_carry=add_carry;
        end
    end
    always_comb begin
        read_address_left=left_base+{3'd0,word_index};
        read_address_right=right_base+{3'd0,word_index};
        case(state)
            MUL_READ,MUL_PRODUCT:begin
                read_address_left=BA+{4'd0,multiply_i};read_address_right=BB+{4'd0,multiply_j};
            end
            DIV_GET,DIV_USE:read_address_left=BA+8'((divide_remaining-8'd1)>>4);
            DIV_ROUND_READ,DIV_ROUND_USE:read_address_left=BQ;
            ASSEMBLE_READ,ASSEMBLE_USE:read_address_left=BP+{3'd0,assemble_index};
            default:begin end
        endcase
        write_enable=0;write_address=0;write_data=0;
        case(state)
            INITIALIZE:begin
                write_enable=1;write_address=initialize_index;
                if(initialize_index<12)write_data=original_a[initialize_index*16+:16];
                else if(initialize_index>=BB&&initialize_index<BB+12)
                    write_data=original_b[(initialize_index-BB)*16+:16];
            end
            WORD_USE:begin
                write_enable=operation!=COMPARE_WORDS;write_address=destination_base+{3'd0,word_index};
                case(operation)
                    COPY_WORDS:write_data=read_left;
                    SHIFT_ONE:write_data=shift_one_value[15:0];
                    SHIFT_TWO:write_data=shift_two_value[15:0];
                    default:write_data=alu_sum[15:0];
                endcase
            end
            MUL_LOW:begin write_enable=1;write_address=BPRODUCT;write_data=product[15:0];end
            MUL_HIGH:begin write_enable=1;write_address=BPRODUCT+1;write_data=product[31:16];end
            ADD_WORD:begin write_enable=1;write_address=BP+{3'd0,add_index};write_data=alu_sum[15:0];end
            ADD_EXTEND:begin write_enable=1;write_address=BP+{3'd0,add_index};write_data={16{add_negative}};end
            COMPARE_SAVE:begin write_enable=1;write_address=BP;write_data={14'd0,comparison};end
            default:begin end
        endcase
        if(rst||state==HELD||(state!=QUIET&&(cancel_seen||current_cancel)))write_enable=0;
    end
    task automatic fail_value(input logic [7:0] why);
        begin outcome<=FRAME_FAIL;reason<=why;state<=PACK;end
    endtask
    task automatic begin_words(input operation_t op,input logic [7:0] a,b,d,
        input logic [4:0] words,input logic [1:0] initial_carry,input state_t next_state);
        begin
            operation<=op;left_base<=a;right_base<=b;destination_base<=d;
            word_count<=words;word_index<=op==COMPARE_WORDS?words-5'd1:5'd0;
            word_carry<=initial_carry;comparison<=0;resume_state<=next_state;state<=WORD_READ;
        end
    endtask
    always_ff @(posedge clk)begin
        if(rst)begin state<=QUIET;outcome<=VALUE;reason<=NONE;cancel_seen<=0;end
        else if(state==HELD)begin if(rsp_ready)state<=QUIET;end
        else if(state!=QUIET&&(cancel_seen||current_cancel))begin
            outcome<=CANCEL_DROP;reason<=NONE;cancel_seen<=1;state<=HELD;
        end else case(state)
            QUIET:if(req_valid)begin
                held_header<=req_body[221:0];outcome<=VALUE;reason<=NONE;
                cancel_seen<=cancel_valid&&cancel_id==req_body[175:0];state<=CHECK;
            end
            CHECK:if(check_reason!=NONE)fail_value(check_reason);else begin
                initialize_index<=0;state<=INITIALIZE;
                result_signed<=kind==2||((kind==0||kind==1)&&(held_header[AS_LO]||held_header[BS_LO]))||
                    (kind==3&&held_header[AS_LO]);negative_result<=a_negative^b_negative;
            end
            INITIALIZE:if(initialize_index==255)state<=ABS_A;else initialize_index<=initialize_index+8'd1;
            ABS_A:if(a_negative)begin_words(NEG_WORDS,BA,BZERO,BA,12,1,ABS_B);else state<=ABS_B;
            ABS_B:if(b_negative)begin_words(NEG_WORDS,BB,BZERO,BB,12,1,DISPATCH);else state<=DISPATCH;
            DISPATCH:case(kind)
                0:begin multiply_i<=0;multiply_j<=0;state<=MUL_READ;end
                1,2:begin add_index<=0;add_carry<=kind==2;state<=ADD_WORD;end
                3,6:begin divide_remaining<=192;negative_result<=a_negative;state<=DIV_GET;end
                4,7:begin root_remaining<=96;negative_result<=0;state<=ROOT_SHIFT;end
                5:begin
                    word_index<=11;comparison<=0;
                    if(a_negative!=b_negative)begin comparison<=a_negative?1:2;state<=COMPARE_SAVE;end
                    else state<=COMPARE_WORD;
                end
                default:fail_value(UNSUPPORTED);
            endcase
            WORD_READ:state<=WORD_USE;
            WORD_USE:begin
                if(operation==COMPARE_WORDS)begin
                    if(comparison==0)begin
                        if(read_left<read_right)comparison<=1;else if(read_left>read_right)comparison<=2;
                    end
                    if(word_index==0)state<=resume_state;else begin word_index<=word_index-5'd1;state<=WORD_READ;end
                end else begin
                    if(operation==SHIFT_ONE)word_carry<={1'b0,shift_one_value[16]};
                    else if(operation==SHIFT_TWO)word_carry<=shift_two_value[17:16];else word_carry<=alu_next_carry;
                    if(word_index==word_count-5'd1)state<=resume_state;
                    else begin word_index<=word_index+5'd1;state<=WORD_READ;end
                end
            end
            MUL_READ:state<=MUL_PRODUCT;
            MUL_PRODUCT:begin product<=read_left*read_right;state<=MUL_LOW;end
            MUL_LOW:state<=MUL_HIGH;
            MUL_HIGH:state<=MUL_ADD;
            MUL_ADD:begin_words(ADD_WORDS,BP+8'(multiply_i)+8'(multiply_j),BPRODUCT,
                BP+8'(multiply_i)+8'(multiply_j),25-5'(multiply_i)-5'(multiply_j),0,MUL_NEXT);
            MUL_NEXT:if(multiply_j==11)begin
                multiply_j<=0;
                if(multiply_i==11)state<=RESULT_SIGN;else begin multiply_i<=multiply_i+4'd1;state<=MUL_READ;end
            end else begin multiply_j<=multiply_j+4'd1;state<=MUL_READ;end
            ADD_WORD:begin
                add_carry<=alu_sum[16];
                if(add_index==12)begin
                    if(alu_sum[15:2]!={14{alu_sum[1]}})fail_value(INTERNAL);
                    else begin add_negative<=alu_sum[1];add_index<=13;state<=ADD_EXTEND;end
                end else add_index<=add_index+5'd1;
            end
            ADD_EXTEND:if(add_index==24)begin assemble_index<=0;state<=ASSEMBLE_READ;end
                else add_index<=add_index+5'd1;
            COMPARE_WORD:begin
                if(comparison==0)begin
                    if(original_a[word_index*16+:16]<original_b[word_index*16+:16])comparison<=1;
                    else if(original_a[word_index*16+:16]>original_b[word_index*16+:16])comparison<=2;
                end
                if(word_index==0)state<=COMPARE_SAVE;else word_index<=word_index-5'd1;
            end
            COMPARE_SAVE:begin assemble_index<=0;state<=ASSEMBLE_READ;end
            DIV_GET:state<=DIV_USE;
            DIV_USE:begin_words(SHIFT_ONE,BR,BZERO,BR,13,
                {1'b0,read_left[(divide_remaining-8'd1)&8'd15]},DIV_COMPARE);
            DIV_COMPARE:begin_words(COMPARE_WORDS,BR,BB,BZERO,13,0,DIV_DECIDE);
            DIV_DECIDE:begin
                accepted_bit<=comparison!=1;
                if(comparison!=1)begin_words(SUB_WORDS,BR,BB,BR,13,0,DIV_QUOTIENT);else state<=DIV_QUOTIENT;
            end
            DIV_QUOTIENT:begin_words(SHIFT_ONE,BQ,BZERO,BQ,13,{1'b0,accepted_bit},DIV_NEXT);
            DIV_NEXT:if(divide_remaining==1)state<=kind==3?DIV_ROUND:DIV_RESULT;
                else begin divide_remaining<=divide_remaining-8'd1;state<=DIV_GET;end
            DIV_ROUND:begin_words(SHIFT_ONE,BR,BZERO,BT,13,0,DIV_ROUND_COMPARE);
            DIV_ROUND_COMPARE:begin_words(COMPARE_WORDS,BT,BB,BZERO,13,0,DIV_ROUND_READ);
            DIV_ROUND_READ:state<=DIV_ROUND_USE;
            DIV_ROUND_USE:if(comparison==2||(comparison==0&&read_left[0]))
                begin_words(ADD_WORDS,BQ,BZERO,BQ,13,1,DIV_RESULT);else state<=DIV_RESULT;
            DIV_RESULT:begin_words(COPY_WORDS,BQ,BZERO,BP,13,0,RESULT_SIGN);
            ROOT_SHIFT:begin_words(SHIFT_TWO,BR,BZERO,BR,13,
                original_a[(root_remaining-7'd1)*2+:2],ROOT_TRIAL);
            ROOT_TRIAL:begin_words(SHIFT_TWO,BROOT,BZERO,BT,13,1,ROOT_COMPARE);
            ROOT_COMPARE:begin_words(COMPARE_WORDS,BR,BT,BZERO,13,0,ROOT_DECIDE);
            ROOT_DECIDE:begin
                accepted_bit<=comparison!=1;
                if(comparison!=1)begin_words(SUB_WORDS,BR,BT,BR,13,0,ROOT_BIT);else state<=ROOT_BIT;
            end
            ROOT_BIT:begin_words(SHIFT_ONE,BROOT,BZERO,BROOT,13,{1'b0,accepted_bit},ROOT_NEXT);
            ROOT_NEXT:if(root_remaining==1)state<=kind==4?ROOT_ROUND:ROOT_RESULT;
                else begin root_remaining<=root_remaining-7'd1;state<=ROOT_SHIFT;end
            // A为整数，(r+1/2)^2=r^2+r+1/4，故最近整数根上舍入恰好为rem>r。
            ROOT_ROUND:begin_words(COMPARE_WORDS,BR,BROOT,BZERO,13,0,ROOT_ROUND_DECIDE);
            ROOT_ROUND_DECIDE:if(comparison==2)
                begin_words(ADD_WORDS,BROOT,BZERO,BROOT,13,1,ROOT_RESULT);else state<=ROOT_RESULT;
            ROOT_RESULT:begin_words(COPY_WORDS,BROOT,BZERO,BP,13,0,RESULT_SIGN);
            RESULT_SIGN:if(negative_result&&(kind==0||kind==3))begin
                begin_words(NEG_WORDS,BP,BZERO,BP,25,1,ASSEMBLE_READ);assemble_index<=0;
            end else begin assemble_index<=0;state<=ASSEMBLE_READ;end
            ASSEMBLE_READ:state<=ASSEMBLE_USE;
            ASSEMBLE_USE:if(assemble_index==24)begin full[384]<=read_left[0];state<=QUALIFY;end
                else begin full[assemble_index*16+:16]<=read_left;assemble_index<=assemble_index+5'd1;state<=ASSEMBLE_READ;end
            QUALIFY:begin qualify_word<=24;qualify_bad<=0;state<=QUALIFY_SCAN;end
            QUALIFY_SCAN:begin
                qualify_bad<=qualify_bad||qualify_word_bad;
                if(qualify_word==0)begin
                    if(qualify_bad||qualify_word_bad)fail_value(OVERFLOW);else begin outcome<=VALUE;reason<=NONE;state<=PACK;end
                end else qualify_word<=qualify_word-5'd1;
            end
            PACK:state<=HELD;
            default:fail_value(INTERNAL);
        endcase
    end
endmodule
