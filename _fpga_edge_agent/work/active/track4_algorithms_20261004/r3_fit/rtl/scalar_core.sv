// S01…S06 / IF-S01…03。逐沿草图见docs/module-code-reading.md和批准卡D。
module scalar_core(
    input wire clk,input wire rst,
    input wire req_valid,output wire req_ready,input wire [621:0] req_body,
    output wire rsp_valid,input wire rsp_ready,output wire [584:0] rsp_body,
    input wire cancel_valid,input wire [175:0] cancel_id,output wire quiet
);
    import scalar_protocol_pkg::*;
    typedef enum logic [4:0] {
        QUIET,CHECK,SETUP,MUL_INIT,MUL_PART,MUL_EMIT,MUL_LAST,MUL_DONE,
        ADD_DIGIT,ADD_DONE,COMPARE_VALUE,DIV_BIT,DIV_CHECK,DIV_ROUND,
        ROOT_PAIR,ROOT_START,QUALIFY,PACK,HELD
    } state_t;
    state_t state;
    logic [621:0] held_request;
    logic [384:0] response_value,full;
    logic [1:0] outcome;
    logic [7:0] reason;
    logic cancel_seen,negative_result,result_signed;
    logic [191:0] work_a,work_b,quotient;
    logic [192:0] remainder;
    logic [96:0] root;
    logic [36:0] column_sum;
    logic [19:0] carry;
    logic [4:0] column;
    logic [3:0] digit_i,add_digit;
    logic [7:0] divide_remaining;
    logic [6:0] root_remaining;
    // 0外部乘；1核k²；2核(k+1)²；3核(2k+1)²。
    logic [1:0] multiply_purpose;

    wire [4:0] kind=held_request[KIND_LO+:5];
    wire a_signed=held_request[AS_LO],b_signed=held_request[BS_LO];
    wire [8:0] target=held_request[TARGET_LO+:9];
    wire [191:0] original_a=held_request[PAYLOAD_LO+:192];
    wire [191:0] original_b=held_request[PAYLOAD_LO+192+:192];
    wire a_negative=a_signed && original_a[191];
    wire b_negative=b_signed && original_b[191];
    wire current_cancel=cancel_valid && cancel_id==held_request[175:0];
    assign req_ready=!rst && state==QUIET;
    assign rsp_valid=!rst && state==HELD;
    assign quiet=!rst && state==QUIET;
    assign rsp_body={response_value,reason,outcome,target,kind,held_request[175:0]};

    // 宽度在运算前确定；最负192bit的abs在193bit域取反后收无符号幅度。
    function automatic [191:0] magnitude192(input logic [191:0] bits,input logic neg);
        logic [192:0] expanded;
        begin
            expanded={neg,bits};
            if(neg) expanded=(~expanded)+193'd1;
            magnitude192=expanded[191:0];
        end
    endfunction
    logic [7:0] check_reason;
    logic [4:0] digit_j,last_i,first_digit;
    logic [31:0] partial_product;
    logic [36:0] next_column_sum;
    logic [207:0] add_a_view,add_b_view;
    logic [16:0] add_sum;
    logic signed [192:0] compare_a,compare_b;
    logic [192:0] shifted_remainder,trial_root,root_remainder;
    logic [192:0] doubled_remainder,rounded_quotient;
    logic [96:0] root_plus_one,root_mid,rounded_root;
    logic [384:0] original_a_full,root_round_boundary;
    logic fits_target;

    always_comb begin : check_and_private_values
        // 首错次序与原卡B一致，不让后来的算术错误覆盖格式错误。
        check_reason=NONE;
        if(held_request[W_LO+:11]<6 || held_request[W_LO+:11]>1920 ||
           held_request[W_LO] || held_request[H_LO+:11]<5 || held_request[H_LO+:11]>1080)
            check_reason=COORD;
        else if(held_request[VERSION_LO+:8]!=1 || held_request[96+:8]!=0 || kind>7)
            check_reason=UNSUPPORTED;
        else if(target==0 || target>maximum_target(kind) ||
                (kind==5 && target!=2) ||
                ((kind==4 || kind==6 || kind==7) && (a_signed || b_signed)))
            check_reason=FORMAT;
        else if(((kind==4 || kind==7) && |held_request[PAYLOAD_LO+192+:208]) ||
                (!(kind==4 || kind==7) && |held_request[PAYLOAD_LO+384+:16]))
            check_reason=FORMAT;
        else if((kind==3 || kind==6) && original_b==0) check_reason=DIV_ZERO;
        else if(kind==3 && b_negative) check_reason=FORMAT;

        digit_j=column-{1'b0,digit_i};
        last_i=(column>11)?5'd11:column;
        first_digit=(column>11)?column-5'd11:5'd0;
        partial_product=work_a[digit_i*16+:16]*work_b[digit_j*16+:16];
        next_column_sum=column_sum+{5'd0,partial_product};
        add_a_view={{16{a_negative}},original_a};
        add_b_view={{16{b_negative}},original_b};
        if(kind==2) add_b_view=~add_b_view;
        add_sum={1'b0,add_a_view[add_digit*16+:16]}+
                {1'b0,add_b_view[add_digit*16+:16]}+{16'd0,carry[0]};
        compare_a=$signed({a_negative,original_a});
        compare_b=$signed({b_negative,original_b});

        shifted_remainder='0;
        if(divide_remaining>=1 && divide_remaining<=192)
            shifted_remainder={remainder[191:0],work_a[divide_remaining-1]};
        doubled_remainder=remainder<<1;
        rounded_quotient={1'b0,quotient};
        if(kind==3 && (doubled_remainder>{1'b0,work_b} ||
           (doubled_remainder=={1'b0,work_b} && quotient[0])))
            rounded_quotient=rounded_quotient+193'd1;

        root_remainder=remainder<<2;
        if(root_remaining>=1 && root_remaining<=96)
            root_remainder=root_remainder|{{191{1'b0}},original_a[(root_remaining-1)*2+:2]};
        trial_root=({96'd0,root}<<2)|193'd1;
        root_plus_one=root+97'd1;
        root_mid=(root<<1)|97'd1;
        original_a_full={193'd0,original_a};
        root_round_boundary=original_a_full<<2;
        rounded_root=root;
        if(root_round_boundary>full || (root_round_boundary==full && root[0]))
            rounded_root=root_plus_one;

        // target是允许容器：完整值计算之后才判高位，不移位截断来判资格。
        fits_target=1'b1;
        for(integer bit_index=0;bit_index<385;bit_index=bit_index+1) begin
            if(result_signed) begin
                if(bit_index>=target-1 && full[bit_index]!=full[384]) fits_target=1'b0;
            end else if(bit_index>=target && full[bit_index]) fits_target=1'b0;
        end
    end

    task automatic fail_value(input logic [7:0] why);
        begin outcome<=FRAME_FAIL;reason<=why;response_value<='0;state<=PACK;end
    endtask
    task automatic begin_square(input logic [96:0] value,input logic [1:0] purpose);
        begin
            work_a<={95'd0,value};work_b<={95'd0,value};
            full<='0;carry<='0;column<=0;digit_i<=0;
            multiply_purpose<=purpose;state<=MUL_INIT;
        end
    endtask

    always_ff @(posedge clk) begin : scalar_transaction
        if(rst) begin
            state<=QUIET;cancel_seen<=0;outcome<=VALUE;reason<=NONE;
            // 私有数据可保留，所有读取资格由state隔离，SETUP完整初始化。
        end else if(state==HELD) begin
            // 已valid结果优先保持；同沿cancel不重写body。
            if(rsp_ready) state<=QUIET;
        end else if(state!=QUIET && (cancel_seen || current_cancel)) begin
            outcome<=CANCEL_DROP;reason<=NONE;response_value<='0;
            cancel_seen<=1;state<=HELD;
        end else begin
            case(state)
                QUIET:if(req_valid) begin
                    held_request<=req_body;
                    cancel_seen<=cancel_valid && cancel_id==req_body[175:0];
                    state<=CHECK;
                end
                CHECK:if(check_reason!=NONE) fail_value(check_reason);else state<=SETUP;
                SETUP:begin
                    full<='0;remainder<='0;quotient<='0;root<='0;
                    work_a<=magnitude192(original_a,a_negative);work_b<=magnitude192(original_b,b_negative);
                    negative_result<=a_negative^b_negative;
                    result_signed<=(kind==2)||((kind==0||kind==1)&&(a_signed||b_signed))||(kind==3&&a_signed);
                    column<=0;digit_i<=0;carry<=0;add_digit<=0;multiply_purpose<=0;
                    case(kind)
                        0:state<=MUL_INIT;
                        1,2:begin carry<=(kind==2)?20'd1:20'd0;state<=ADD_DIGIT;end
                        3,6:begin divide_remaining<=192;negative_result<=a_negative;state<=DIV_BIT;end
                        4,7:begin root_remaining<=96;state<=ROOT_PAIR;end
                        5:state<=COMPARE_VALUE;
                        default:fail_value(UNSUPPORTED);
                    endcase
                end
                MUL_INIT:begin
                    // 运算保留5位，资格检查后显式收4位，合法值0…11。
                    if(column>22 || first_digit>11) fail_value(INTERNAL);
                    else begin
                        column_sum<={17'd0,carry};
                        digit_i<=first_digit[3:0];state<=MUL_PART;
                    end
                end
                MUL_PART:begin
                    column_sum<=next_column_sum;
                    if({1'b0,digit_i}==last_i) state<=MUL_EMIT;
                    else digit_i<=digit_i+4'd1;
                end
                MUL_EMIT:begin
                    if(column_sum[36]) fail_value(INTERNAL);
                    else begin
                        full[column*16+:16]<=column_sum[15:0];carry<=column_sum[35:16];
                        if(column==22) state<=MUL_LAST;
                        else begin column<=column+5'd1;state<=MUL_INIT;end
                    end
                end
                MUL_LAST:begin
                    if(|carry[19:16]) fail_value(INTERNAL);
                    else begin full[383:368]<=carry[15:0];state<=MUL_DONE;end
                end
                MUL_DONE:case(multiply_purpose)
                    0:begin
                        if(negative_result) full<=(~full)+385'd1;
                        state<=QUALIFY;
                    end
                    1:if(full>original_a_full) fail_value(INTERNAL);else begin_square(root_plus_one,2);
                    2:if(full<=original_a_full) fail_value(INTERNAL);
                      else if(kind==7) begin full<={288'd0,root};state<=QUALIFY;end
                      else begin_square(root_mid,3);
                    3:begin full<={288'd0,rounded_root};state<=QUALIFY;end
                endcase
                ADD_DIGIT:begin
                    full[add_digit*16+:16]<=add_sum[15:0];carry<={19'd0,add_sum[16]};
                    if(add_digit==12) state<=ADD_DONE;else add_digit<=add_digit+4'd1;
                end
                ADD_DONE:if(full[207:194]!={14{full[193]}}) fail_value(INTERNAL);
                    else begin full<={{191{full[193]}},full[193:0]};state<=QUALIFY;end
                COMPARE_VALUE:begin
                    if(compare_a<compare_b) full<=385'd1;
                    else if(compare_a>compare_b) full<=385'd2;else full<='0;
                    state<=QUALIFY;
                end
                DIV_BIT:begin
                    if(shifted_remainder>={1'b0,work_b}) begin
                        remainder<=shifted_remainder-{1'b0,work_b};quotient[divide_remaining-1]<=1;
                    end else begin remainder<=shifted_remainder;quotient[divide_remaining-1]<=0;end
                    divide_remaining<=divide_remaining-8'd1;
                    if(divide_remaining==1) state<=DIV_CHECK;
                end
                DIV_CHECK:if(remainder>={1'b0,work_b}) fail_value(INTERNAL);else state<=DIV_ROUND;
                DIV_ROUND:begin
                    if(negative_result) full<=(~{192'd0,rounded_quotient})+385'd1;
                    else full<={192'd0,rounded_quotient};
                    state<=QUALIFY;
                end
                ROOT_PAIR:begin
                    if(root_remainder>=trial_root) begin
                        remainder<=root_remainder-trial_root;root<=(root<<1)|97'd1;
                    end else begin remainder<=root_remainder;root<=root<<1;end
                    root_remaining<=root_remaining-7'd1;
                    if(root_remaining==1) state<=ROOT_START;
                end
                ROOT_START:begin_square(root,1);
                QUALIFY:begin
                    if(!fits_target) fail_value(OVERFLOW);
                    else begin response_value<=full;outcome<=VALUE;reason<=NONE;state<=PACK;end
                end
                PACK:state<=HELD;
                default:fail_value(INTERNAL);
            endcase
        end
    end
endmodule
