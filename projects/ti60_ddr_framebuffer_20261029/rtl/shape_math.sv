// Sequential unsigned arithmetic shared by contour simplification and geometry.
// op 0: 64x64 -> 128 multiply (a[127:64] must be zero), at most 64 iterations.
// op 1: floor(sqrt(a)), 64 radix-four iterations; b is ignored.
// op 2: 128/64 divide -> 128 quotient, 128 iterations.
// op 3: low 128 bits of 128x12 multiply, at most 12 iterations; b[63:12] must be zero.
// A request latches operands and frame/config identity. Results remain stable
// under backpressure. Cancel terminates local arithmetic with error=3; it has
// no external memory transactions to drain. Reset discards the local request.
module shape_math (
    input wire clk, rst, cancel,
    input wire req_valid, output wire req_ready,
    input wire [1:0] req_op,
    input wire [127:0] req_a,
    input wire [63:0] req_b,
    input wire [95:0] req_scope,
    output wire rsp_valid, input wire rsp_ready,
    output wire [127:0] rsp_value,
    output wire [64:0] rsp_remainder,
    output reg [95:0] rsp_scope,
    output reg [1:0] rsp_error,
    output wire busy
);
    localparam IDLE=0, MUL=1, ROOT=2, DIVIDE=3, RESULT=4;
    reg [2:0] state;
    reg [7:0] count;
    reg short_multiply;
    reg [127:0] shift_operand, accumulator;
    // These three operands have disjoint lifetimes (multiply/root/divide).
    // The accumulator itself holds the published result, avoiding a second
    // 128-bit result register; RESULT never mutates arithmetic storage.
    reg [63:0] operand;
    assign rsp_value=accumulator;
    reg [65:0] remainder;
    assign rsp_remainder=remainder[64:0];
    wire [127:0] mul_next=accumulator+(operand[0]?shift_operand:128'd0);
    // Root and division execute in mutually exclusive states. A single
    // subtract supplies BOTH the residual and the unsigned comparison (borrow)
    // instead of separate subtractors and magnitude comparators.
    wire root_mode=state==ROOT;
    wire [65:0] trial_input=root_mode?
        {remainder[63:0],shift_operand[127:126]}:{1'b0,remainder[63:0],shift_operand[127]};
    wire [65:0] trial_divisor=root_mode?{operand,2'b01}:{2'b0,operand};
    wire [66:0] trial_difference={1'b0,trial_input}-{1'b0,trial_divisor};
    wire take=!trial_difference[66];
    wire [65:0] trial_remainder=take?trial_difference[65:0]:trial_input;
    wire [65:0] root_remainder=trial_remainder;
    wire [63:0] root_next={operand[62:0],take};
    wire div_take=take;
    wire [64:0] div_remainder=trial_remainder[64:0];
    assign req_ready=!rst&&state==IDLE&&!cancel;
    assign rsp_valid=!rst&&state==RESULT;
    assign busy=state!=IDLE;
    always @(posedge clk) begin
        if(rst)begin
            state<=IDLE; count<=0;short_multiply<=0;shift_operand<=0;accumulator<=0;
            operand<=0;remainder<=0;
            accumulator<=0;remainder<=0;rsp_scope<=0;rsp_error<=0;
        end else if(cancel&&state!=IDLE&&state!=RESULT)begin
            accumulator<=0;remainder<=0;rsp_error<=3;state<=RESULT;
        end else case(state)
            IDLE:if(req_valid&&req_ready)begin
                rsp_scope<=req_scope;rsp_error<=0;accumulator<=0;remainder<=0;
                count<=0;short_multiply<=req_op==3;accumulator<=0;operand<=0;remainder<=0;
                case(req_op)
                    0:if(|req_a[127:64])begin rsp_error<=1;state<=RESULT;end
                      else begin shift_operand<=req_a;operand<=req_b;state<=MUL;end
                    1:begin shift_operand<=req_a;state<=ROOT;end
                    2:if(req_b==0)begin rsp_error<=2;state<=RESULT;end
                      else begin shift_operand<=req_a;operand<=req_b;state<=DIVIDE;end
                    3:if(|req_b[63:12])begin rsp_error<=1;state<=RESULT;end
                      else begin shift_operand<=req_a;operand<=req_b;state<=MUL;end
                endcase
            end
            MUL:begin
                accumulator<=mul_next;shift_operand<=shift_operand<<1;operand<=operand>>1;
                // After consuming the current low bit, no higher multiplier
                // bits means all future partial products are exactly zero.
                // This preserves the full 128-bit product (op3 modulo 2^128).
                // Clients use ready/valid, never a fixed completion latency.
                if(count==(short_multiply?11:63)||operand[63:1]==0)begin state<=RESULT;end
                else count<=count+1'b1;
            end
            ROOT:begin
                operand<=root_next;remainder<=root_remainder;shift_operand<=shift_operand<<2;
                if(count==63)begin
                    accumulator<={64'd0,root_next};state<=RESULT;
                end else count<=count+1'b1;
            end
            DIVIDE:begin
                remainder<={1'b0,div_remainder};shift_operand<=shift_operand<<1;
                accumulator<={accumulator[126:0],div_take};
                if(count==127)begin
                    state<=RESULT;
                end else count<=count+1'b1;
            end
            RESULT:if(rsp_ready)state<=IDLE;
            default:begin rsp_error<=1;accumulator<=0;remainder<=0;state<=RESULT;end
        endcase
    end
endmodule
