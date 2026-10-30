// Exact squared distance from P to the CLOSED segment AB. Numerator/denominator
// avoid division and rounding at the RDP threshold. One shared sequential
// multiplier handles all variable products. Coordinates are unsigned 11-bit.
// eps_numerator encodes epsilon squared * 10000 (22500 for epsilon=1.5).
// Results retain scope and stay stable until accepted. No external side effects.
module shape_segment_distance #(parameter integer EXTERNAL_MATH=0)(
    input wire clk,rst,cancel,
    input wire req_valid,output wire req_ready,
    input wire [21:0] req_a,req_b,req_p,
    input wire [23:0] req_epsilon,
    input wire [95:0] req_scope,
    output wire rsp_valid,input wire rsp_ready,
    output wire [63:0] rsp_numerator,
    output reg [23:0] rsp_denominator,
    output reg rsp_beyond,output reg [1:0] rsp_error,
    output reg [95:0] rsp_scope,
    output wire ext_valid,input wire ext_ready,
    output wire [127:0] ext_a,output wire [63:0] ext_b,
    output wire [95:0] ext_scope,output wire ext_cancel,
    input wire ext_result,output wire ext_consume,
    input wire [127:0] ext_value,input wire [95:0] ext_result_scope,
    input wire [1:0] ext_error
);
    localparam IDLE=0,LX=1,LY=2,PX=3,PY=4,CX=5,CY=6,SQUARE=7,
        EX=8,EY=9,NORMALIZE=10,EPS=11,RESULT=12,MREQ=13,MWAIT=14,SCALE=15;
    reg [3:0] state,resume;
    reg signed [11:0] dx,dy,tx,ty,ex,ey;
    reg signed [23:0] partial;
    reg [23:0] len,epsilon;
    reg [46:0] first_square;
    reg [45:0] numerator;
    assign rsp_numerator={18'd0,numerator};
    reg abort_pending;
    // Exact 46 x 24 unsigned serial product. Product's low bits hold the
    // unconsumed multiplier; the high part holds the running sum. This reuses
    // storage across the 24 steps instead of retaining input/result copies.
    // For 11-bit coordinates: distance numerator < 2^46, scaled by 10000
    // < 2^60; epsilon(24) * squared length(23) < 2^47.
    reg [45:0] multiplicand;
    reg [69:0] product;
    reg [23:0] operand_b;
    // External owner is retained through response consumption and cancellation.
    // The shared unit retains rsp_value until its next accepted request; the
    // continuation consumes that value before presenting the next operands.
    assign ext_valid=EXTERNAL_MATH&&!rst&&state==MREQ&&!cancel&&!abort_pending;
    assign ext_a={82'd0,multiplicand};assign ext_b={40'd0,operand_b};
    assign ext_scope=rsp_scope;assign ext_cancel=EXTERNAL_MATH&&(cancel||abort_pending);
    assign ext_consume=EXTERNAL_MATH&&!rst&&state==MWAIT;
    reg [4:0] mul_count;
    wire [46:0] upper_sum={1'b0,product[69:24]}+
        (product[0]?{1'b0,multiplicand}:47'd0);
    wire [69:0] mul_next={upper_sum,product[23:1]};
    wire [63:0] reply=EXTERNAL_MATH?ext_value[63:0]:{4'd0,product[59:0]};
    function automatic [63:0] magnitude(input signed [31:0] v);
        magnitude=v<0?64'(-v):64'(v);
    endfunction
    function automatic signed [23:0] signed_product(input [63:0] v,input sign_bit);
        signed_product=sign_bit?-$signed(v[23:0]):$signed(v[23:0]);
    endfunction
    wire signed [23:0] projection=partial+signed_product(reply,ty[11]^dy[11]);
    wire signed [23:0] cross_product=partial-signed_product(reply,ty[11]^dx[11]);
    assign req_ready=!rst&&!cancel&&state==IDLE;
    assign rsp_valid=!rst&&state==RESULT;
    task multiply(input [63:0] a,b,input [3:0] continuation);
        begin
            if(|a[63:24]|| |b[63:24])begin rsp_error<=1;numerator<=0;rsp_beyond<=0;state<=RESULT;end
            else begin multiplicand<={22'd0,a[23:0]};operand_b<=b[23:0];
                if(!EXTERNAL_MATH)product<={46'd0,b[23:0]};resume<=continuation;state<=MREQ;end
        end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;resume<=IDLE;dx<=0;dy<=0;tx<=0;ty<=0;ex<=0;ey<=0;
            partial<=0;len<=0;epsilon<=0;first_square<=0;multiplicand<=0;product<=0;
            mul_count<=0;operand_b<=0;
            numerator<=0;rsp_denominator<=1;rsp_beyond<=0;rsp_error<=0;rsp_scope<=0;abort_pending<=0;
        end else begin
            if(cancel&&state!=IDLE&&state!=RESULT)abort_pending<=1;
            if((cancel||abort_pending)&&state!=IDLE&&state!=RESULT&&state!=MREQ&&state!=MWAIT)begin
                numerator<=0;rsp_beyond<=0;rsp_error<=3;state<=RESULT;
            end else case(state)
                IDLE:if(req_valid&&req_ready)begin
                    dx<=$signed({1'b0,req_b[10:0]})-$signed({1'b0,req_a[10:0]});
                    dy<=$signed({1'b0,req_b[21:11]})-$signed({1'b0,req_a[21:11]});
                    tx<=$signed({1'b0,req_p[10:0]})-$signed({1'b0,req_a[10:0]});
                    ty<=$signed({1'b0,req_p[21:11]})-$signed({1'b0,req_a[21:11]});
                    ex<=$signed({1'b0,req_p[10:0]})-$signed({1'b0,req_b[10:0]});
                    ey<=$signed({1'b0,req_p[21:11]})-$signed({1'b0,req_b[21:11]});
                    epsilon<=req_epsilon;rsp_scope<=req_scope;rsp_error<=0;abort_pending<=0;
                    numerator<=0;rsp_beyond<=0;state<=LX;
                end
                LX:multiply(magnitude(dx),magnitude(dx),LY);
                LY:begin first_square<=reply[46:0];multiply(magnitude(dy),magnitude(dy),PX);end
                PX:begin len<=24'(first_square+reply);multiply(magnitude(tx),magnitude(dx),PY);end
                PY:begin partial<=signed_product(reply,tx[11]^dx[11]);multiply(magnitude(ty),magnitude(dy),CX);end
                CX:begin
                    rsp_denominator<=len==0?24'd1:len;
                    if(len==0||projection<=0)begin ex<=tx;ey<=ty;state<=EX;end
                    else if(projection>=$signed({1'b0,len[22:0]}))state<=EX;
                    else multiply(magnitude(tx),magnitude(dy),CY);
                end
                CY:begin partial<=signed_product(reply,tx[11]^dy[11]);multiply(magnitude(ty),magnitude(dx),SQUARE);end
                SQUARE:multiply(magnitude(cross_product),magnitude(cross_product),NORMALIZE);
                EX:multiply(magnitude(ex),magnitude(ex),EY);
                EY:begin first_square<=reply[46:0];multiply(magnitude(ey),magnitude(ey),EPS);end
                EPS:multiply(first_square+reply,{40'b0,rsp_denominator},NORMALIZE);
                NORMALIZE:begin numerator<=reply[45:0];multiply({40'b0,epsilon},{40'b0,rsp_denominator},SCALE);end
                SCALE:begin
                    // Reuse first_square after geometric distance is complete.
                    first_square<=reply[46:0];multiplicand<=numerator;operand_b<=24'd10000;
                    if(!EXTERNAL_MATH)product<={46'd0,24'd10000};
                    resume<=RESULT;state<=MREQ;
                end
                // MWAIT handles the final comparison before publishing RESULT.
                MREQ:if(cancel||abort_pending)begin rsp_error<=3;numerator<=0;rsp_beyond<=0;state<=RESULT;end
                    else if(!EXTERNAL_MATH||ext_ready)begin mul_count<=0;state<=MWAIT;end
                MWAIT:if(EXTERNAL_MATH)begin
                    // Never release the shared owner until the response drains,
                    // including a cancel response and a bad-scope response.
                    if(ext_result)begin
                        if(cancel||abort_pending||ext_error!=0||ext_result_scope!=rsp_scope)begin
                            rsp_error<=cancel||abort_pending?2'd3:ext_error!=0?ext_error:2'd1;
                            numerator<=0;rsp_beyond<=0;state<=RESULT;
                        end else begin
                            state<=resume;
                            if(resume==RESULT)rsp_beyond<=ext_value>{81'd0,first_square};
                        end
                    end
                end else if(cancel||abort_pending)begin rsp_error<=3;numerator<=0;rsp_beyond<=0;state<=RESULT;end
                    else begin
                        product<=mul_next;mul_count<=mul_count+1'b1;
                        if(mul_count==23)begin
                            state<=resume;
                            if(resume==RESULT)rsp_beyond<=mul_next>first_square;
                        end
                end
                RESULT:if(rsp_ready)state<=IDLE;
                default:begin rsp_error<=1;state<=RESULT;end
            endcase
        end
    end
endmodule
