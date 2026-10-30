// Geometry decision after ordered contour metrics and bounded polygon RDP.
// Coordinates are inclusive. Four packed vertices follow contour order, vertex
// zero in the low 11 bits. polygon_four means exactly four RDP vertices, never
// the first four of a truncated polygon. Caller marks open/overflowed contours
// invalid; no partial contour may be classified. Scope is immutable per job.
// Circle: aspect >= .90, circularity >= .80 (pi=355/113), radius RMS <= .06,
// and maximum radial deviation <= .12. Radius inputs are Q8 from metrics.
// Rectangle: four convex corners, dot^2 <= .03*len1^2*len2^2, each side >=31
// pixels (one pixel tolerance for a rasterized physical 32 pixel target).
// Products use one iterative unit. 128-bit comparisons cover full 1080p
// contour worst cases; no division, floating point or general fitting array.
module shape_classifier #(
    parameter integer W=1920,H=1080,EXTERNAL_MATH=0
)(
    input wire clk,rst,cancel,
    input wire start_valid,output wire start_ready,
    input wire [95:0] start_scope,
    input wire [10:0] box_x0,box_y0,box_x1,box_y1,
    input wire [21:0] point_count,
    input wire contour_invalid,contour_clipped,polygon_four,
    input wire [43:0] polygon_x,polygon_y,
    input wire [47:0] area_twice,
    input wire [39:0] perimeter_q8,
    input wire [63:0] radius_sum_q8,radius_squared_sum_q16,
    input wire [31:0] radius_min_q8,radius_max_q8,
    output wire result_valid,input wire result_ready,
    output reg [95:0] result_scope,
    output reg [1:0] result_class, // 0 unknown, 1 circle, 2 rectangle
    output reg [2:0] result_reason, // 0 classified,1 clipped,2 small,3 format,
                                  // 4 geometry,5 upstream invalid,6 cancelled
    output reg [1:0] result_error, // 0 normal (unknown allowed),2 math,3 cancel
    output reg [43:0] result_box,
    output reg [23:0] result_center2, // {center_y*2,center_x*2}, exact half pixels
    output reg [47:0] result_area_twice,
    output wire busy,
    output wire ext_valid,input wire ext_ready,output wire [1:0] ext_op,
    output wire [127:0] ext_a,output wire [63:0] ext_b,output wire [95:0] ext_scope,
    output wire ext_cancel,input wire ext_result,output wire ext_consume,
    input wire [127:0] ext_value,input wire [95:0] ext_result_scope,
    input wire [1:0] ext_error,input wire ext_busy
);
    localparam IDLE=0,CHECK=1,REQUEST=2,WAIT_RESULT=3,DRAIN=4,RESULT=5,VERTICES=6;
    localparam LENGTHS=0,CORNERS=1,DOT_SQUARE=2,LENGTH_PRODUCT=3,
               CIRCLE_PERIMETER=4,CIRCLE_SUM_SQUARE=5,CIRCLE_N_SUM2=6,
               CIRCLE_MIN=7,CIRCLE_MAX=8,SCALE_LEFT=9,SCALE_RIGHT=10;
    reg [2:0] state;
    reg [3:0] phase;
    reg [1:0] edge_index,slot;
    reg [10:0] vx[0:3],vy[0:3];
    reg signed [11:0] dx[0:3],dy[0:3];
    // Each coordinate difference is at most 2047: square < 2^22, sum < 2^23.
    reg [22:0] length2[0:3];
    reg [21:0] partial_length;
    reg signed [24:0] product0;
    reg [25:0] dot_abs;
    reg [127:0] dot_squared,sum_squared;
    reg cross_sign;
    reg four,invalid,clipped;
    reg [11:0] width,height;
    reg [21:0] count;
    reg [47:0] area2;
    reg [39:0] perimeter;
    reg [63:0] sum_r,sum_r2;
    reg [31:0] min_r,max_r;
    wire [1:0] next_edge=edge_index+2'd1;
    reg signed [11:0] operand_a,operand_b;
    reg [127:0] math_a;
    reg [63:0] math_b;
    wire negative=operand_a[11]^operand_b[11];
    wire math_ready,math_result,math_busy;
    wire [127:0] math_value;
    wire [95:0] math_scope;
    wire [1:0] math_error;
    wire math_consume=state==WAIT_RESULT||state==DRAIN;
    wire signed [24:0] signed_product=negative?-$signed(math_value[24:0]):$signed(math_value[24:0]);
    wire signed [25:0] cross_value=$signed({product0[24],product0})-$signed({signed_product[24],signed_product});
    wire signed [25:0] dot_value=$signed({product0[24],product0})+$signed({signed_product[24],signed_product});
    // Explicit constant shifts prevent Efinity from allocating a bank of DSPs
    // for wide constant products in each independent decision expression.
    function automatic [127:0] scale(input [127:0] value,input integer factor);
        reg [127:0] total;
        integer bit_index;
        begin
            total=0;
            for(bit_index=0;bit_index<32;bit_index=bit_index+1)
                if((factor>>bit_index)&1)total=total+(value<<bit_index);
            scale=total;
        end
    endfunction
    // Constant comparisons reuse the shared ALU and two existing scratch
    // registers. Requests preserve scope/backpressure/cancel ownership.
    reg [3:0] compare_phase;
    reg [11:0] factor_left,factor_right;
    wire [1:0] math_op=(phase==SCALE_LEFT||phase==SCALE_RIGHT)?2'd3:2'd0;
    integer i;
    function automatic [63:0] magnitude(input signed [11:0] value);
        reg signed [12:0] extended;
        begin extended={value[11],value};magnitude=extended<0?64'(-extended):64'(extended);end
    endfunction
    always @*begin
        operand_a=0;operand_b=0;math_a=0;math_b=0;
        case(phase)
            LENGTHS:begin
                operand_a=slot==0?dx[0]:dy[0];operand_b=operand_a;
                math_a={64'd0,magnitude(operand_a)};math_b=magnitude(operand_b);
            end
            CORNERS:begin
                case(slot)
                    0:begin operand_a=dx[0];operand_b=dy[1];end
                    1:begin operand_a=dy[0];operand_b=dx[1];end
                    2:begin operand_a=dx[0];operand_b=dx[1];end
                    3:begin operand_a=dy[0];operand_b=dy[1];end
                endcase
                math_a={64'd0,magnitude(operand_a)};math_b=magnitude(operand_b);
            end
            DOT_SQUARE:begin math_a={102'd0,dot_abs};math_b={38'd0,dot_abs};end
            LENGTH_PRODUCT:begin math_a={105'd0,length2[0]};math_b={41'd0,length2[1]};end
            CIRCLE_PERIMETER:begin math_a={88'd0,perimeter};math_b={24'd0,perimeter};end
            CIRCLE_SUM_SQUARE:begin math_a={64'd0,sum_r};math_b=sum_r;end
            CIRCLE_N_SUM2:begin math_a={64'd0,sum_r2};math_b={42'd0,count};end
            CIRCLE_MIN:begin math_a={96'd0,min_r};math_b={42'd0,count};end
            CIRCLE_MAX:begin math_a={96'd0,max_r};math_b={42'd0,count};end
            SCALE_LEFT:begin math_a=dot_squared;math_b={52'd0,factor_left};end
            SCALE_RIGHT:begin math_a=sum_squared;math_b={52'd0,factor_right};end
            default:begin end
        endcase
    end
    // The frame sequencer selects only one client at a time and holds ownership
    // through response consumption and cancellation. Standalone tests use local math.
    assign ext_valid=(state==REQUEST)&&!cancel;assign ext_op=math_op;
    assign ext_a=math_a;assign ext_b=math_b;assign ext_scope=result_scope;
    assign ext_cancel=cancel||state==DRAIN;assign ext_consume=math_consume;
    generate if(EXTERNAL_MATH)begin:external_numeric
        assign math_ready=ext_ready;assign math_result=ext_result;assign math_value=ext_value;
        assign math_scope=ext_result_scope;assign math_error=ext_error;assign math_busy=ext_busy;
    end else begin:local_numeric
    shape_math numeric(.clk(clk),.rst(rst),.cancel(cancel||state==DRAIN),
        .req_valid(state==REQUEST&&!cancel),.req_ready(math_ready),.req_op(math_op),
        .req_a(math_a),.req_b(math_b),.req_scope(result_scope),
        .rsp_valid(math_result),.rsp_ready(math_consume),.rsp_value(math_value),
        .rsp_remainder(),.rsp_scope(math_scope),.rsp_error(math_error),.busy(math_busy));
    end endgenerate
    assign start_ready=!rst&&state==IDLE&&math_ready&&!cancel;
    assign result_valid=!rst&&state==RESULT;
    assign busy=state!=IDLE;
    task circle;
        begin phase<=CIRCLE_PERIMETER;state<=REQUEST;end
    endtask
    task unknown_shape(input [2:0] reason);
        begin result_class<=0;result_reason<=reason;state<=RESULT;end
    endtask
    task compare_scaled(input [127:0] left_value,right_value,input [11:0] left_factor,right_factor);
        begin
            dot_squared<=left_value;sum_squared<=right_value;
            factor_left<=left_factor;factor_right<=right_factor;
            compare_phase<=phase;phase<=SCALE_LEFT;state<=REQUEST;
        end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;phase<=LENGTHS;edge_index<=0;slot<=0;
            result_scope<=0;result_class<=0;result_reason<=0;result_error<=0;
            result_box<=0;result_center2<=0;result_area_twice<=0;
            partial_length<=0;product0<=0;dot_abs<=0;dot_squared<=0;sum_squared<=0;cross_sign<=0;
            four<=0;invalid<=0;clipped<=0;width<=0;height<=0;count<=0;
            area2<=0;perimeter<=0;sum_r<=0;sum_r2<=0;min_r<=0;max_r<=0;
            factor_left<=0;factor_right<=0;compare_phase<=0;
            for(i=0;i<4;i=i+1)begin vx[i]<=0;vy[i]<=0;dx[i]<=0;dy[i]<=0;length2[i]<=0;end
        end else if(cancel&&state!=IDLE&&state!=RESULT&&state!=DRAIN)begin
            result_class<=0;result_reason<=6;result_error<=3;state<=DRAIN;
        end else if(math_result&&state==WAIT_RESULT&&(math_error!=0||math_scope!=result_scope))begin
            result_class<=0;result_reason<=3;result_error<=2;state<=DRAIN;
        end else case(state)
            IDLE:if(start_valid&&start_ready)begin
                result_scope<=start_scope;result_class<=0;result_reason<=0;result_error<=0;
                result_box<={box_y1,box_x1,box_y0,box_x0};
                result_center2<={({1'b0,box_y0}+{1'b0,box_y1}),({1'b0,box_x0}+{1'b0,box_x1})};
                result_area_twice<=area_twice;
                width<={1'b0,box_x1}-{1'b0,box_x0}+12'd1;
                height<={1'b0,box_y1}-{1'b0,box_y0}+12'd1;
                count<=point_count;four<=polygon_four;invalid<=contour_invalid;
                clipped<=contour_clipped||box_x0==0||box_y0==0||box_x1==W-1||box_y1==H-1;
                area2<=area_twice;perimeter<=perimeter_q8;sum_r<=radius_sum_q8;
                sum_r2<=radius_squared_sum_q16;min_r<=radius_min_q8;max_r<=radius_max_q8;
                edge_index<=0;slot<=0;cross_sign<=0;
                for(i=0;i<4;i=i+1)begin
                    vx[i]<=polygon_x[i*11+:11];vy[i]<=polygon_y[i*11+:11];

                end
                if(box_x0>=box_x1||box_y0>=box_y1||box_x1>=W||box_y1>=H||point_count<4||point_count>W*H||
                   area_twice==0||area_twice>2*W*H||perimeter_q8==0||{88'd0,perimeter_q8}>scale({106'd0,point_count},362)||
                   radius_sum_q8==0||radius_min_q8>radius_max_q8||radius_max_q8>524288||
                   radius_sum_q8>({42'd0,point_count}<<19)||radius_squared_sum_q16>({42'd0,point_count}<<38))
                    unknown_shape(3);
                else state<=CHECK;
            end
            CHECK:begin
                if(invalid)unknown_shape(5);
                else if(clipped)unknown_shape(1);
                else if(width<32||height<32)unknown_shape(2);
                else begin
                    phase<=four?LENGTHS:CIRCLE_PERIMETER;
                    state<=four?VERTICES:REQUEST;
                end
            end
            // Four cycles validate vertices and form sides using two subtractors.
            // Rotating fixed heads avoids variable-index muxes; after four cycles
            // the original vertex/side order is restored. No data is discarded.
            VERTICES:begin
                if(vx[0]<result_box[10:0]||vx[0]>result_box[32:22]||vy[0]<result_box[21:11]||vy[0]>result_box[43:33])unknown_shape(3);
                else begin
                    for(i=0;i<3;i=i+1)begin
                        vx[i]<=vx[i+1];vy[i]<=vy[i+1];dx[i]<=dx[i+1];dy[i]<=dy[i+1];
                    end
                    vx[3]<=vx[0];vy[3]<=vy[0];
                    dx[3]<=$signed({1'b0,vx[1]})-$signed({1'b0,vx[0]});
                    dy[3]<=$signed({1'b0,vy[1]})-$signed({1'b0,vy[0]});
                    if(edge_index==3)begin edge_index<=0;state<=REQUEST;end
                    else edge_index<=edge_index+1'b1;
                end
            end
            REQUEST:if(math_ready)state<=WAIT_RESULT;
            WAIT_RESULT:if(math_result)begin
                state<=REQUEST;
                case(phase)
                    LENGTHS:if(slot==0)begin partial_length<=math_value[21:0];slot<=1;end
                        else begin
                            for(i=0;i<3;i=i+1)begin dx[i]<=dx[i+1];dy[i]<=dy[i+1];length2[i]<=length2[i+1];end
                            dx[3]<=dx[0];dy[3]<=dy[0];
                            length2[3]<={1'b0,partial_length}+math_value[22:0];slot<=0;
                            if({1'b0,partial_length}+math_value[22:0]<961)circle();
                            else if(edge_index==3)begin edge_index<=0;phase<=CORNERS;end
                            else edge_index<=edge_index+1'b1;
                        end
                    CORNERS:case(slot)
                        0,2:begin product0<=signed_product;slot<=slot+1'b1;end
                        1:begin
                            if(cross_value==0||(edge_index!=0&&cross_value[25]!=cross_sign))circle();
                            else begin cross_sign<=cross_value[25];slot<=2;end
                        end
                        3:begin dot_abs<=dot_value<0?-dot_value:dot_value;phase<=DOT_SQUARE;end
                    endcase
                    DOT_SQUARE:begin dot_squared<=math_value;phase<=LENGTH_PRODUCT;end
                    LENGTH_PRODUCT:compare_scaled(dot_squared,math_value,12'd100,12'd3);
                    CIRCLE_PERIMETER:begin
                        if(scale(width<height?{116'd0,width}:{116'd0,height},10)<scale(width<height?{116'd0,height}:{116'd0,width},9))unknown_shape(4);
                        else compare_scaled(math_value,{80'd0,area2}<<16,12'd452,12'd3550);
                    end
                    CIRCLE_SUM_SQUARE:begin sum_squared<=math_value;phase<=CIRCLE_N_SUM2;end
                    CIRCLE_N_SUM2:begin
                        if(math_value<sum_squared)unknown_shape(3);
                        else compare_scaled(math_value,sum_squared,12'd2500,12'd2509);
                    end
                    CIRCLE_MIN:compare_scaled(math_value,{64'd0,sum_r},12'd25,12'd22);
                    CIRCLE_MAX:compare_scaled(math_value,{64'd0,sum_r},12'd25,12'd28);
                    SCALE_LEFT:begin dot_squared<=math_value;phase<=SCALE_RIGHT;end
                    SCALE_RIGHT:begin
                    case(compare_phase)
                        LENGTH_PRODUCT:begin
                            if(dot_squared>math_value)circle();
                            else if(edge_index==3)begin result_class<=2;result_reason<=0;state<=RESULT;end
                            else begin
                                for(i=0;i<3;i=i+1)begin dx[i]<=dx[i+1];dy[i]<=dy[i+1];length2[i]<=length2[i+1];end
                                dx[3]<=dx[0];dy[3]<=dy[0];length2[3]<=length2[0];
                                edge_index<=edge_index+1'b1;slot<=0;phase<=CORNERS;
                            end
                        end
                        CIRCLE_PERIMETER:if(dot_squared>math_value)unknown_shape(4);
                            else phase<=CIRCLE_SUM_SQUARE;
                        CIRCLE_N_SUM2:if(dot_squared>math_value)unknown_shape(4);
                            else phase<=CIRCLE_MIN;
                        CIRCLE_MIN:if(dot_squared<math_value)unknown_shape(4);
                            else phase<=CIRCLE_MAX;
                        CIRCLE_MAX:if(dot_squared>math_value)unknown_shape(4);
                            else begin result_class<=1;result_reason<=0;state<=RESULT;end
                        default:unknown_shape(3);
                    endcase
                    end
                    default:unknown_shape(3);
                endcase
            end
            DRAIN:if(!math_busy)begin result_area_twice<=0;state<=RESULT;end
            RESULT:if(result_ready)state<=IDLE;
            default:begin result_error<=2;result_class<=0;result_reason<=3;state<=DRAIN;end
        endcase
    end
endmodule
