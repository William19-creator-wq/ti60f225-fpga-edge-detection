// 板级串行统计：保留TOKEN262/STAT632及完整数值域；复用一份乘法器和57位加法器。
// ready在点运算期间拉低；旧四级流水线的仿真证明不适用于本版。
module stats_core #(parameter bit BORROW_CONTEXT=1'b0)(
    input logic clk,rst,
    input logic token_valid,input logic [261:0] token_body,output wire token_ready,
    output wire stat_valid,output wire [631:0] stat_body,input logic stat_ready,
    output wire fault_active,output wire [7:0] fault_reason,output wire quiet
);
    import stats_protocol_pkg::*;
    localparam IDLE=0,CHECK=1,RUN=2,AX_MUL=3,AX_STORE=4,BY_MUL=5,BY_STORE=6,
        MOMENT=7,MUL_STORE=8,ADD_MOMENT=9,COMMIT=10,PACK=11,HELD=12,PROTOCOL_STUCK=13;
    reg [3:0] state;
    wire [175:0] context_id;
    reg [83:0] header;
    reg [21:0] raw_seen;
    reg [20:0] included_count;
    reg signed [55:0] accumulator[0:4];
    reg [10:0] previous_x,previous_y;
    reg previous_valid,closing_abort;
    reg [7:0] first_reason;
    reg signed [11:0] a,b,x,y,x2,y2;
    reg signed [24:0] d;
    reg signed [36:0] product,contribution;
    reg signed [56:0] candidate;
    reg [2:0] moment;
    reg signed [11:0] mul_left;
    reg signed [24:0] mul_right;
    wire [10:0] width=header[10:0],height=header[21:11];
    wire tls=header[26:22]==12||header[26:22]==18;
    wire [83:0] data=token_body[261:178];
    wire [1:0] op=token_body[177:176];
    wire token_fire=token_valid&&token_ready;
    generate if(BORROW_CONTEXT)begin:borrow_context
        // 仅受控父模块启用：token身份从START接受到STAT消费/quiet始终不变。
        assign context_id=token_body[175:0];
    end else begin:copy_context
        reg [175:0] snapshot;
        assign context_id=snapshot;
        always @(posedge clk)begin
            if(rst)snapshot<=0;
            else if(state==IDLE&&token_fire)snapshot<=token_body[175:0];
        end
    end endgenerate
    wire same_id=token_body[175:0]==context_id;
    wire [10:0] point_x=data[32:22],point_y=data[43:33];
    wire signed [10:0] point_gx=data[54:44],point_gy=data[65:55];
    wire signed [12:0] centered_x=($signed({2'd0,point_x})<<<1)-($signed({2'd0,width})-13'sd1);
    wire signed [12:0] centered_y=($signed({2'd0,point_y})<<<1)-($signed({2'd0,height})-13'sd1);
    wire [22:0] next_raw={1'b0,raw_seen}+23'd1;
    wire [21:0] next_n={1'b0,included_count}+22'd1;
    wire [21:0] pixel_limit={11'd0,width}*{11'd0,height};
    wire signed [37:0] d_candidate=$signed({product[36],product})+$signed({{13{d[24]}},d});
    wire signed [56:0] sum_candidate=$signed({accumulator[moment][55],accumulator[moment]})+
        $signed({{20{contribution[36]}},contribution});
    reg [7:0] token_reason;
    reg candidate_fits;
    assign token_ready=!rst&&(state==IDLE||state==RUN);
    assign stat_valid=!rst&&state==HELD;
    assign quiet=!rst&&state==IDLE;
    assign fault_active=!rst&&first_reason!=0;
    assign fault_reason=first_reason;
    assign stat_body={first_reason,(first_reason!=0?fit_protocol_pkg::FRAME_FAIL:
        (closing_abort?fit_protocol_pkg::CANCEL_DROP:fit_protocol_pkg::VALUE)),
        pack_numeric(context_id,header,included_count,accumulator[0],accumulator[1],
            accumulator[2],accumulator[3],accumulator[4],first_reason==0&&!closing_abort)};
    always @*begin
        token_reason=0;
        if(state==RUN&&token_fire)begin
            if(!same_id)token_reason=fit_protocol_pkg::INTERNAL;
            else case(op)
                POINT:begin
                    if({1'b0,data[20:0]}!=raw_seen||raw_seen>={1'b0,header[71:51]})token_reason=fit_protocol_pkg::COUNT;
                    else if(point_x>=width||point_y>=height)token_reason=fit_protocol_pkg::COORD;
                    else if(point_gx < -11'sd1020||point_gx>11'sd1020||
                            point_gy < -11'sd1020||point_gy>11'sd1020)token_reason=fit_protocol_pkg::INTERNAL;
                    else if(data[83:66]!=0||(previous_valid&&
                        (point_y<previous_y||(point_y==previous_y&&point_x<=previous_x))))token_reason=fit_protocol_pkg::FORMAT;
                end
                END_SCAN:if(data[83:22]!=0)token_reason=fit_protocol_pkg::FORMAT;
                    else if(data[21:0]!=raw_seen||raw_seen!={1'b0,header[71:51]})token_reason=fit_protocol_pkg::COUNT;
                ABORT_SCAN:if(data!=0)token_reason=fit_protocol_pkg::FORMAT;
                default:token_reason=fit_protocol_pkg::FORMAT;
            endcase
        end
        mul_left=0;mul_right=0;
        if(state==AX_MUL)begin mul_left=a;mul_right={{13{x[11]}},x};end
        else if(state==BY_MUL)begin mul_left=b;mul_right={{13{y[11]}},y};end
        else if(tls)case(moment)
            2:begin mul_left=x2;mul_right={{13{x2[11]}},x2};end
            3:begin mul_left=y2;mul_right={{13{y2[11]}},y2};end
            4:begin mul_left=x2;mul_right={{13{y2[11]}},y2};end
            default:begin end
        endcase
        else case(moment)
            0:begin mul_left=a;mul_right={{13{a[11]}},a};end
            1:begin mul_left=a;mul_right={{13{b[11]}},b};end
            2:begin mul_left=b;mul_right={{13{b[11]}},b};end
            3:begin mul_left=a;mul_right=d;end
            4:begin mul_left=b;mul_right=d;end
            default:begin end
        endcase
        // 完整57位候选先通过高位扩展检查，再收回56位累计。
        candidate_fits=0;
        case(moment)
            0:candidate_fits=tls?(candidate[56:32]=={25{candidate[32]}}):candidate[56:43]==0;
            1:candidate_fits=tls?(candidate[56:32]=={25{candidate[32]}}):(candidate[56:43]=={14{candidate[43]}});
            2:candidate_fits=candidate[56:43]==0;
            3:candidate_fits=tls?(candidate[56:43]==0):(candidate[56]==candidate[55]);
            4:candidate_fits=tls?(candidate[56:43]=={14{candidate[43]}}):(candidate[56]==candidate[55]);
            default:candidate_fits=0;
        endcase
    end
    integer i;
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;header<=0;raw_seen<=0;included_count<=0;previous_valid<=0;
            closing_abort<=0;first_reason<=0;moment<=0;d<=0;
            for(i=0;i<5;i=i+1)accumulator[i]<=0;
        end else begin
            // 只有此处形成乘法算子；乘积在下一状态消费，不使用同沿的新值。
            if(state==AX_MUL||state==BY_MUL||(state==MOMENT&&(!tls||moment>=2)))
                product<=mul_left*mul_right;
            case(state)
                IDLE:if(token_fire)begin
                    header<=op==START?data:84'd0;
                    raw_seen<=0;included_count<=0;previous_valid<=0;closing_abort<=0;
                    for(i=0;i<5;i=i+1)accumulator[i]<=0;
                    if(op==START)begin first_reason<=0;state<=CHECK;end
                    else begin first_reason<=fit_protocol_pkg::FORMAT;state<=PACK;end
                end
                CHECK:begin first_reason<=check_start(context_id,header);state<=RUN;end
                RUN:if(token_fire)begin
                    if(first_reason==0&&token_reason!=0)first_reason<=token_reason;
                    if(op==POINT)begin
                        if(fits_raw_count(next_raw))raw_seen<=next_raw[21:0];
                        else begin state<=PROTOCOL_STUCK;if(first_reason==0)first_reason<=fit_protocol_pkg::COUNT;end
                        if(token_reason==0)begin previous_x<=point_x;previous_y<=point_y;previous_valid<=1;end
                        if(fits_raw_count(next_raw)&&token_reason==0&&data[21]&&first_reason==0)begin
                            if(next_n[21]||next_n>pixel_limit)first_reason<=fit_protocol_pkg::COUNT;
                            else begin
                                a<=$signed({point_gy[10],point_gy});b<=-$signed({point_gx[10],point_gx});
                                x<=$signed({1'b0,point_x});y<=$signed({1'b0,point_y});
                                x2<=centered_x[11:0];y2<=centered_y[11:0];moment<=0;d<=0;
                                state<=tls?MOMENT:AX_MUL;
                            end
                        end
                    end else if(same_id&&(op==END_SCAN||op==ABORT_SCAN))begin
                        closing_abort<=op==ABORT_SCAN&&data==0;state<=PACK;
                    end
                end
                AX_MUL:state<=AX_STORE;
                AX_STORE:begin
                    if(product[36:24]!={13{product[24]}})begin first_reason<=fit_protocol_pkg::INTERNAL;state<=RUN;end
                    else begin d<=product[24:0];state<=BY_MUL;end
                end
                BY_MUL:state<=BY_STORE;
                BY_STORE:begin
                    if(d_candidate[37:24]!={14{d_candidate[24]}})begin first_reason<=fit_protocol_pkg::INTERNAL;state<=RUN;end
                    else begin d<=d_candidate[24:0];state<=MOMENT;end
                end
                MOMENT:begin
                    if(tls&&moment<2)begin
                        contribution<=moment==0?{{25{x2[11]}},x2}:{{25{y2[11]}},y2};state<=ADD_MOMENT;
                    end else state<=MUL_STORE;
                end
                MUL_STORE:begin contribution<=product;state<=ADD_MOMENT;end
                ADD_MOMENT:begin candidate<=sum_candidate;state<=COMMIT;end
                COMMIT:begin
                    if(!candidate_fits)begin first_reason<=fit_protocol_pkg::OVERFLOW;state<=RUN;end
                    else begin
                        // 累计是私有的；任一项越界，整包数值正文为零，不公开部分累计。
                        accumulator[moment]<=candidate[55:0];
                        if(moment==4)begin included_count<=next_n[20:0];state<=RUN;end
                        else begin moment<=moment+3'd1;state<=MOMENT;end
                    end
                end
                PACK:state<=HELD;
                HELD:if(stat_ready)begin state<=IDLE;first_reason<=0;end
                PROTOCOL_STUCK:state<=PROTOCOL_STUCK;
                default:begin state<=PROTOCOL_STUCK;first_reason<=fit_protocol_pkg::INTERNAL;end
            endcase
        end
    end
endmodule
