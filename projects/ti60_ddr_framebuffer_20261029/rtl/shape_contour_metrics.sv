// Ordered closed outer contour -> geometry statistics, no frame storage here.
// The contour producer supplies every boundary point exactly once, in order,
// without repeating the start point. Closing adjacency is checked explicitly.
// Bounding coordinates are inclusive. Radius is Q8 about the bounding-box
// center (which may lie on a half pixel). One shared sequential numeric unit
// calculates both coordinate squares, root, radius square and shoelace term.
// This module is a component of recognition, not a connected board recognizer.
module shape_contour_metrics #(
    parameter integer W=1920,H=1080,EXTERNAL_MATH=0
)(
    input wire clk,rst,cancel,
    input wire start_valid,output wire start_ready,
    input wire [95:0] start_scope,
    input wire [10:0] box_x0,box_y0,box_x1,box_y1,
    input wire [21:0] point_count,
    input wire point_valid,output wire point_ready,
    input wire [10:0] point_x,point_y,input wire point_last,
    output wire result_valid,input wire result_ready,
    output reg [95:0] result_scope,
    output reg [1:0] result_error,
    output reg result_clipped,
    output reg [47:0] area_twice,
    output wire [39:0] perimeter_q8,
    output wire [63:0] radius_sum_q8,radius_squared_sum_q16,
    output wire [31:0] radius_min_q8,radius_max_q8,
    output wire busy,
    output wire ext_valid,input wire ext_ready,output wire [1:0] ext_op,
    output wire [127:0] ext_a,output wire [63:0] ext_b,output wire [95:0] ext_scope,
    output wire ext_cancel,input wire ext_result,output wire ext_consume,
    input wire [127:0] ext_value,input wire [95:0] ext_result_scope,
    input wire [1:0] ext_error,input wire ext_busy
);
    // Valid contours contain at most 1920*1080 adjacent points. Using the
    // conservative full 11-bit coordinate domain: radius Q8 < 2^19,
    // radius square < 2^38, sum(radius) < 2^40, sum(square) < 2^59.
    // Perimeter <= N*362 < 2^30. Each signed area term has |dx|<=1
    // and y0+y1<=4094, so the absolute partial sum is <2^33.
    // Public ports remain wide; only unreachable high storage bits disappear.
    reg [29:0] perimeter_q8_bounded;
    reg [39:0] radius_sum_q8_bounded;
    reg [58:0] radius_squared_sum_q16_bounded;
    reg [18:0] radius_min_q8_bounded,radius_max_q8_bounded;
    assign perimeter_q8={10'd0,perimeter_q8_bounded};
    assign radius_sum_q8={24'd0,radius_sum_q8_bounded};
    assign radius_squared_sum_q16={5'd0,radius_squared_sum_q16_bounded};
    assign radius_min_q8={13'd0,radius_min_q8_bounded};
    assign radius_max_q8={13'd0,radius_max_q8_bounded};
    localparam IDLE=0,POINT=1,X_REQ=2,X_WAIT=3,Y_REQ=4,Y_WAIT=5,
        ROOT_REQ=6,ROOT_WAIT=7,R2_REQ=8,R2_WAIT=9,AREA_REQ=10,AREA_WAIT=11,
        ADVANCE=12,FINISH=13,DRAIN=14,RESULT=15;
    reg [3:0] state;
    reg [10:0] x0,y0,x1,y1,cx,cy,px,py,first_x,first_y;
    reg [10:0] observed_x0,observed_y0,observed_x1,observed_y1;
    reg [11:0] center_x2,center_y2;
    reg [21:0] count,index;
    reg last,closing;
    reg [10:0] distance_x,distance_y;
    reg [21:0] square_x;
    reg [18:0] radius_q8;
    reg [36:0] radius_squared_input;
    reg signed [33:0] signed_area;
    wire signed [13:0] delta_x=$signed({2'b0,point_x,1'b0})-$signed({2'b0,center_x2});
    wire signed [13:0] delta_y=$signed({2'b0,point_y,1'b0})-$signed({2'b0,center_y2});
    wire [10:0] step_x=px>cx?px-cx:cx-px;
    wire [10:0] step_y=py>cy?py-cy:cy-py;
    wire [10:0] input_step_x=px>point_x?px-point_x:point_x-px;
    wire [10:0] input_step_y=py>point_y?py-point_y:point_y-py;
    wire [10:0] closing_x=cx>first_x?cx-first_x:first_x-cx;
    wire [10:0] closing_y=cy>first_y?cy-first_y:first_y-cy;
    wire [11:0] area_y={1'b0,py}+{1'b0,cy};
    wire area_negative=px<cx;
    reg [1:0] math_op;
    reg [127:0] math_a;
    reg [63:0] math_b;
    wire math_valid=state==X_REQ||state==Y_REQ||state==ROOT_REQ||state==R2_REQ||state==AREA_REQ;
    wire math_ready,math_result,math_busy;
    wire [127:0] math_value;
    wire [95:0] math_scope;
    wire [1:0] math_error;
    wire math_consume=state==X_WAIT||state==Y_WAIT||state==ROOT_WAIT||state==R2_WAIT||state==AREA_WAIT||state==DRAIN;
    always @*begin
        math_op=0;math_a=0;math_b=0;
        case(state)
            X_REQ:begin math_a={117'd0,distance_x};math_b={53'd0,distance_x};end
            Y_REQ:begin math_a={117'd0,distance_y};math_b={53'd0,distance_y};end
            ROOT_REQ:begin math_op=1;math_a={91'd0,radius_squared_input};end
            R2_REQ:begin math_a={109'd0,radius_q8};math_b={45'd0,radius_q8};end
            AREA_REQ:begin math_a={117'd0,step_x};math_b={52'd0,area_y};end
            default:begin end
        endcase
    end
    // The frame sequencer selects only one client at a time and holds ownership
    // through response consumption and cancellation. Standalone tests use local math.
    assign ext_valid=(math_valid)&&!cancel;assign ext_op=math_op;
    assign ext_a=math_a;assign ext_b=math_b;assign ext_scope=result_scope;
    assign ext_cancel=cancel||state==DRAIN;assign ext_consume=math_consume;
    generate if(EXTERNAL_MATH)begin:external_numeric
        assign math_ready=ext_ready;assign math_result=ext_result;assign math_value=ext_value;
        assign math_scope=ext_result_scope;assign math_error=ext_error;assign math_busy=ext_busy;
    end else begin:local_numeric
    shape_math numeric(
        .clk(clk),.rst(rst),.cancel(cancel||state==DRAIN),
        .req_valid(math_valid&&!cancel),.req_ready(math_ready),.req_op(math_op),
        .req_a(math_a),.req_b(math_b),.req_scope(result_scope),
        .rsp_valid(math_result),.rsp_ready(math_consume),.rsp_value(math_value),
        .rsp_remainder(),.rsp_scope(math_scope),.rsp_error(math_error),.busy(math_busy));
    end endgenerate
    assign start_ready=!rst&&state==IDLE&&math_ready&&!cancel;
    assign point_ready=!rst&&state==POINT&&!cancel;
    assign result_valid=!rst&&state==RESULT;
    assign busy=state!=IDLE;
    task fail_format;
        begin result_error<=1;state<=DRAIN;end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;result_scope<=0;result_error<=0;result_clipped<=0;
            area_twice<=0;perimeter_q8_bounded<=0;radius_sum_q8_bounded<=0;radius_squared_sum_q16_bounded<=0;
            radius_min_q8_bounded<=0;radius_max_q8_bounded<=0;signed_area<=0;
            x0<=0;y0<=0;x1<=0;y1<=0;center_x2<=0;center_y2<=0;count<=0;index<=0;
            observed_x0<=0;observed_y0<=0;observed_x1<=0;observed_y1<=0;
            cx<=0;cy<=0;px<=0;py<=0;first_x<=0;first_y<=0;last<=0;closing<=0;
            distance_x<=0;distance_y<=0;square_x<=0;radius_squared_input<=0;radius_q8<=0;
        end else if(cancel&&state!=IDLE&&state!=RESULT&&state!=DRAIN)begin
            result_error<=3;state<=DRAIN;
        end else if(math_result&&math_consume&&state!=DRAIN&&(math_error!=0||math_scope!=result_scope))begin
            result_error<=2;state<=DRAIN;
        end else case(state)
            IDLE:if(start_valid&&start_ready)begin
                result_scope<=start_scope;result_error<=0;
                result_clipped<=box_x0==0||box_y0==0||box_x1==W-1||box_y1==H-1;
                x0<=box_x0;y0<=box_y0;x1<=box_x1;y1<=box_y1;
                center_x2<={1'b0,box_x0}+{1'b0,box_x1};
                center_y2<={1'b0,box_y0}+{1'b0,box_y1};
                count<=point_count;index<=0;closing<=0;
                observed_x0<=2047;observed_y0<=2047;observed_x1<=0;observed_y1<=0;
                area_twice<=0;signed_area<=0;perimeter_q8_bounded<=0;
                radius_sum_q8_bounded<=0;radius_squared_sum_q16_bounded<=0;radius_min_q8_bounded<=19'h7ffff;radius_max_q8_bounded<=0;
                if(box_x0>=box_x1||box_y0>=box_y1||box_x1>=W||box_y1>=H||point_count<3||point_count>W*H)
                    fail_format();
                else state<=POINT;
            end
            POINT:if(point_valid&&point_ready)begin
                if(point_x<x0||point_x>x1||point_y<y0||point_y>y1||
                   point_last!=(index==count-1)||
                   (index!=0&&(input_step_x>1||input_step_y>1||(input_step_x==0&&input_step_y==0))))fail_format();
                else begin
                    cx<=point_x;cy<=point_y;last<=point_last;
                    if(point_x<observed_x0)observed_x0<=point_x;
                    if(point_y<observed_y0)observed_y0<=point_y;
                    if(point_x>observed_x1)observed_x1<=point_x;
                    if(point_y>observed_y1)observed_y1<=point_y;
                    if(index==0)begin first_x<=point_x;first_y<=point_y;end
                    distance_x<=delta_x<0?11'(-delta_x):11'(delta_x);
                    distance_y<=delta_y<0?11'(-delta_y):11'(delta_y);
                    state<=X_REQ;
                end
            end
            X_REQ:if(math_ready)state<=X_WAIT;
            X_WAIT:if(math_result)begin square_x<=math_value[21:0];state<=Y_REQ;end
            Y_REQ:if(math_ready)state<=Y_WAIT;
            Y_WAIT:if(math_result)begin
                radius_squared_input<=({15'd0,square_x}+{15'd0,math_value[21:0]})<<14;state<=ROOT_REQ;
            end
            ROOT_REQ:if(math_ready)state<=ROOT_WAIT;
            ROOT_WAIT:if(math_result)begin radius_q8<=math_value[18:0];state<=R2_REQ;end
            R2_REQ:if(math_ready)state<=R2_WAIT;
            R2_WAIT:if(math_result)begin
                radius_sum_q8_bounded<=radius_sum_q8_bounded+{21'd0,radius_q8};
                radius_squared_sum_q16_bounded<=radius_squared_sum_q16_bounded+{21'd0,math_value[37:0]};
                if(radius_q8<radius_min_q8_bounded)radius_min_q8_bounded<=radius_q8;
                if(radius_q8>radius_max_q8_bounded)radius_max_q8_bounded<=radius_q8;
                state<=index==0?ADVANCE:AREA_REQ;
            end
            AREA_REQ:if(math_ready)state<=AREA_WAIT;
            AREA_WAIT:if(math_result)begin
                // Sum (previous_x-current_x)*(previous_y+current_y).
                // Absolute final sum equals twice the enclosed polygon area.
                signed_area<=area_negative?signed_area-$signed({21'd0,math_value[12:0]}):signed_area+$signed({21'd0,math_value[12:0]});
                perimeter_q8_bounded<=perimeter_q8_bounded+((step_x!=0&&step_y!=0)?30'd362:30'd256);
                state<=closing?FINISH:ADVANCE;
            end
            ADVANCE:begin
                px<=cx;py<=cy;
                if(last)begin
                    if(closing_x>1||closing_y>1||(closing_x==0&&closing_y==0))fail_format();
                    else begin cx<=first_x;cy<=first_y;closing<=1;state<=AREA_REQ;end
                end else begin index<=index+1'b1;state<=POINT;end
            end
            FINISH:if(observed_x0!=x0||observed_y0!=y0||observed_x1!=x1||observed_y1!=y1)fail_format();
                else begin area_twice<=signed_area<0?-signed_area:signed_area;state<=RESULT;end
            DRAIN:if(!math_busy)begin
                // Failed frames never publish partial statistics as valid data.
                area_twice<=0;perimeter_q8_bounded<=0;radius_sum_q8_bounded<=0;radius_squared_sum_q16_bounded<=0;
                radius_min_q8_bounded<=0;radius_max_q8_bounded<=0;state<=RESULT;
            end
            RESULT:if(result_ready)state<=IDLE;
            default:begin result_error<=2;state<=DRAIN;end
        endcase
    end
    // synthesis translate_off
    initial if(W>1920||H>1080||W<2||H<2) $fatal(1,"metrics supported image bounds");
    // synthesis translate_on
endmodule
