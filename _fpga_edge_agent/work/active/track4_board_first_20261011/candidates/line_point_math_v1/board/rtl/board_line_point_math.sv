// LP01…04：粗线offset/细线残差、切向及gradient门；所有宽算术借唯一scalar。
// 借用正文从command接受到response消费且quiet保持，UNKNOWN保持至共同冷复位。
module board_line_point_math #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter bit SHARED_RETURN_WORDS=1'b0,BORROW_COMMAND=1'b0
)(
    input wire clk,rst,command_valid,output wire command_ready,
    input wire [175:0] command_id,input wire [1:0] command_mode,
    input wire [63:0] command_point,
    input wire signed [31:0] command_nx,command_ny,
    input wire signed [17:0] command_rho,input wire [15:0] command_tolerance,
    output wire response_valid,input wire response_ready,
    output wire [175:0] response_id,output wire [1:0] response_mode,
    output reg signed [20:0] offset,output reg offset_valid,output reg [5:0] offset_index,
    output reg signed [17:0] tangent,output reg [20:0] distance,
    output reg normal_ok,error,drained,output wire quiet,output reg fault,
    output wire num_req_valid,input wire num_req_ready,output wire [621:0] num_req_body,
    input wire num_rsp_valid,output wire num_rsp_ready,input wire [584:0] num_rsp_body,
    input wire num_quiet,output wire [4:0] num_rsp_word_index,input wire [15:0] num_rsp_word16
);
    import scalar_protocol_pkg::*;
    localparam IDLE=0,CHECK=1,PLAN=2,A_READ=3,A_CAPTURE=4,B_READ=5,B_CAPTURE=6,
        NUM_REQUEST=7,NUM_WAIT=8,NUM_SCAN=9,REG_WRITE=10,NUM_CONSUME=11,
        NUM_CLOSE=12,RESULT=13,UNKNOWN_RESULT=14,ISOLATED=15,LOCAL_CLOSE=16;
    localparam K1=0,K2=1,K3=2,K4=3,F1=4,F2=5,F3=6,F4=7,F5=8,F6=9,F7=10,
        C1=11,C2=12,C3=13,C4=14,C5=15,C6=16,C7=17,C8=18,C9=19,C10=20,
        T1=21,T2=22,T3=23,T4=24,TL1=25,TL2=26,TL3=27,TL4=28,TL5=29,
        TU1=30,TU2=31,TU3=32,TU4=33,TU5=34,T6=35,
        VL1=36,VL2=37,VL3=38,VL4=39,VL5=40,
        VU1=41,VU2=42,VU3=43,VU4=44,VU5=45,
        C_SIGN=46,C_LOW=47,C_HIGH=48,P1=49,P2=50,P3=51,P4=52,P5=53,
        N1=54,N2=55,N3=56,N4=57,N5=58,N6=59,N7=60,N8=61,N9=62,N10=63,N11=64,N12=65;
    localparam [5:0] NX=16,NY=17,X=18,Y=19,RHO=20,SCALE=21,ZERO=22,
        ONE=23,TWO=24,FOUR=25,SIXTEEN=26,SIXTYFOUR=27,X2_SRC=28,Y2_SRC=29,
        TOL=30,UNORM_SQUARE=31,K_MIN=32,F_SIGN=33,INCREMENT=34,LOW_OFFSET=35,HIGH_OFFSET=36,
        EIGHT=37,GX_SRC=38,GY_SRC=39;
    reg [4:0] state,scan_word;
    reg [6:0] pc;
    reg [2:0] word;
    reg [63:0] closed_sequence;
    reg exhausted,scan_bad,numeric_failed,f_negative,q_odd,q_zero,round_up,domain_lower_ok;
    reg signed [1:0] adjustment;
    reg [15:0] register_valid;
    reg [127:0] operand_a,operand_b;
    reg [20:0] q_value,completed_small;
    reg completed_sign;
    reg [1:0] completed_compare;

    wire command_fire=command_valid && command_ready;
    wire [339:0] held_command;
    generate if(BORROW_COMMAND)begin:borrow_command
        assign held_command={command_id,command_mode,command_point,command_nx,command_ny,command_rho,command_tolerance};
    end else begin:snapshot_command
        reg [339:0] snapshot;
        assign held_command=snapshot;
        always @(posedge clk)if(rst)snapshot<=0;else if(command_fire)
            snapshot<={command_id,command_mode,command_point,command_nx,command_ny,command_rho,command_tolerance};
    end endgenerate
    wire [175:0] held_id=held_command[339:164];
    wire [1:0] mode=held_command[163:162];
    wire [63:0] point=held_command[161:98];
    wire signed [31:0] nx=held_command[97:66],ny=held_command[65:34];
    wire signed [17:0] rho=held_command[33:16];
    wire [15:0] tolerance=held_command[15:0];
    wire coarse=mode==0;
    wire signed [10:0] gx=point[10:0],gy=point[21:11];
    wire [10:0] px=point[42:32],py=point[53:43];
    wire [10:0] ax=gx[10] ? -gx : gx,ay=gy[10] ? -gy : gy;
    wire signed [12:0] x2=$signed({1'b0,px,1'b0})-13'(WIDTH-1);
    wire signed [12:0] y2=$signed({1'b0,py,1'b0})-13'(HEIGHT-1);
    wire point_legal=point[63]==0 && point[31:24]==0 && px<WIDTH && py<HEIGHT &&
        gx>=-11'sd1020 && gx<=11'sd1020 && gy>=-11'sd1020 && gy<=11'sd1020 &&
        ({1'b0,ax}+{1'b0,ay})<=12'd1530 && point[21:0]!=0 &&
        x2[12]==x2[11] && y2[12]==y2[11];
    wire coarse_normal_legal=nx==$signed({{15{nx[16]}},nx[16:0]}) &&
        ny==$signed({{15{ny[16]}},ny[16:0]}) &&
        nx>=-32'sd32768 && nx<=32'sd32768 && ny>=-32'sd32768 && ny<=32'sd32768;
    wire tls_normal_legal=nx>=-32'sd1073741824 && nx<=32'sd1073741824 &&
        ny>=-32'sd1073741824 && ny<=32'sd1073741824;
    wire normal_legal=coarse ? coarse_normal_legal : tls_normal_legal;
    wire signed [21:0] biased_offset=$signed({offset[20],offset})+22'sd24;

    assign response_id=held_id;
    assign response_mode=mode;
    assign quiet=!rst && state==IDLE && num_quiet;
    assign command_ready=quiet && !exhausted;
    assign response_valid=!rst && (state==RESULT || state==UNKNOWN_RESULT);
    wire [175:0] numeric_id={8'hc4,closed_sequence,8'd0,held_id[95:0]};

    reg [2:0] opcode;
    reg [5:0] source_a,source_b;
    reg [3:0] destination;
    reg a_signed,b_signed,stored_signed,plan_valid;
    reg [7:0] stored_bits;
    task automatic call_plan(input [2:0] operation,input [5:0] a,b,input [3:0] dst,
        input [7:0] bits,input asigned,bsigned,ssigned);
        begin
            opcode=operation;source_a=a;source_b=b;destination=dst;stored_bits=bits;
            a_signed=asigned;b_signed=bsigned;stored_signed=ssigned;plan_valid=1;
        end
    endtask
    // 每个PC的源、目的和资格是固定的；同槽复用只能发生在旧值寿命结束后。
    always @*begin
        opcode=0;source_a=ZERO;source_b=ZERO;destination=0;stored_bits=1;
        a_signed=0;b_signed=0;stored_signed=0;plan_valid=0;
        case(pc)
            K1:call_plan(0,NX,NX,10,coarse ? 8'd34 : 8'd64,1,1,0);
            K2:call_plan(0,NY,NY,11,coarse ? 8'd34 : 8'd64,1,1,0);
            K3:call_plan(1,10,11,0,coarse ? 8'd33 : 8'd65,0,0,0);
            K4:call_plan(5,0,K_MIN,8,2,0,0,0);
            F1:call_plan(0,NX,X,10,coarse ? 8'd28 : 8'd43,1,0,1);
            F2:call_plan(0,NY,Y,11,coarse ? 8'd28 : 8'd43,1,0,1);
            F3:call_plan(1,10,11,12,coarse ? 8'd29 : 8'd44,1,1,1);
            F4:call_plan(0,12,SIXTEEN,13,coarse ? 8'd33 : 8'd48,1,0,1);
            F5:call_plan(0,RHO,SCALE,14,coarse ? 8'd33 : 8'd48,1,0,1);
            F6:call_plan(2,13,14,1,coarse ? 8'd34 : 8'd50,1,1,1);
            F7:call_plan(0,1,1,2,coarse ? 8'd68 : 8'd100,1,1,0);
            C1:call_plan(0,0,SIXTYFOUR,3,39,0,0,0);
            C2:call_plan(6,2,3,4,68,0,0,0);
            C3:call_plan(7,4,ZERO,4,21,0,0,0);
            C4:call_plan(0,2,FOUR,9,70,0,0,0);
            C5,TL1,TU1,VL1,VU1:call_plan(0,4,TWO,5,22,0,0,0);
            C6,TU2,VU2:call_plan(1,5,ONE,5,22,0,0,0);
            TL2,VL2:call_plan(2,5,ONE,5,22,0,0,0);
            C7,TL3,TU3,VL3,VU3:call_plan(0,5,5,6,44,0,0,0);
            C8:call_plan(0,6,3,7,83,0,0,0);
            TL4,TU4,VL4,VU4:call_plan(0,6,coarse ? 6'd3 : 6'd0,7,
                coarse ? 8'd83 : 8'd109,0,0,0);
            C9,TL5,TU5,VL5,VU5:call_plan(5,9,7,8,2,0,0,0);
            C10:call_plan(1,4,INCREMENT,4,21,0,0,0);
            T1:call_plan(4,0,ZERO,3,33,0,0,0);
            T2:call_plan(0,1,F_SIGN,10,50,1,1,0);
            T3:call_plan(3,10,3,4,21,0,0,0);
            T4:call_plan(0,2,FOUR,9,102,0,0,0);
            T6:if(adjustment<0)call_plan(2,4,ONE,4,21,0,0,0);
                else call_plan(1,4,INCREMENT,4,21,0,0,0);
            C_SIGN:call_plan(0,4,F_SIGN,4,21,0,1,1);
            C_LOW:call_plan(5,4,LOW_OFFSET,8,2,1,1,0);
            C_HIGH:call_plan(5,4,HIGH_OFFSET,8,2,1,1,0);
            P1:call_plan(0,NY,X2_SRC,10,coarse ? 8'd30 : 8'd45,1,1,1);
            P2:call_plan(0,NX,Y2_SRC,11,coarse ? 8'd30 : 8'd45,1,1,1);
            P3:call_plan(2,10,11,12,coarse ? 8'd31 : 8'd46,1,1,1);
            P4:call_plan(0,12,EIGHT,13,coarse ? 8'd34 : 8'd49,1,0,1);
            P5:call_plan(3,13,SCALE,4,18,1,0,1);
            N1:call_plan(0,NX,GY_SRC,10,coarse ? 8'd28 : 8'd43,1,1,1);
            N2:call_plan(0,NY,GX_SRC,11,coarse ? 8'd28 : 8'd43,1,1,1);
            N3:call_plan(2,10,11,12,coarse ? 8'd29 : 8'd44,1,1,1);
            N4:call_plan(0,12,12,2,coarse ? 8'd58 : 8'd88,1,1,0);
            N5:call_plan(0,2,UNORM_SQUARE,9,coarse ? 8'd90 : 8'd120,0,0,0);
            N6:call_plan(0,GX_SRC,GX_SRC,10,22,1,1,0);
            N7:call_plan(0,GY_SRC,GY_SRC,11,22,1,1,0);
            N8:call_plan(1,10,11,12,23,0,0,0);
            N9:call_plan(0,TOL,TOL,13,32,0,0,0);
            N10:call_plan(0,13,12,14,55,0,0,0);
            N11:call_plan(0,14,0,14,coarse ? 8'd88 : 8'd120,0,0,0);
            N12:call_plan(5,9,14,8,2,0,0,0);
            default:begin end
        endcase
    end
    function automatic [127:0] constant_source(input [5:0] source);
        begin
            constant_source=0;
            case(source)
                NX:constant_source={{96{nx[31]}},nx};
                NY:constant_source={{96{ny[31]}},ny};
                X:constant_source={117'd0,px};
                Y:constant_source={117'd0,py};
                RHO:constant_source={{110{rho[17]}},rho};
                SCALE:constant_source=coarse ? 128'd32768 : 128'd1073741824;
                ONE:constant_source=128'd1;
                TWO:constant_source=128'd2;
                FOUR:constant_source=128'd4;
                SIXTEEN:constant_source=128'd16;
                SIXTYFOUR:constant_source=128'd64;
                X2_SRC:constant_source={{115{x2[12]}},x2};
                Y2_SRC:constant_source={{115{y2[12]}},y2};
                TOL:constant_source={112'd0,tolerance};
                UNORM_SQUARE:constant_source=128'd4294836225;
                K_MIN:constant_source=coarse ? (128'd1<<28) : (128'd1<<58);
                F_SIGN:constant_source=f_negative ? {128{1'b1}} : 128'd1;
                INCREMENT:constant_source={127'd0,round_up};
                LOW_OFFSET:constant_source=-128'sd24;
                HIGH_OFFSET:constant_source=128'd24;
                EIGHT:constant_source=128'd8;
                GX_SRC:constant_source={{117{gx[10]}},gx};
                GY_SRC:constant_source={{117{gy[10]}},gy};
                default:begin end
            endcase
        end
    endfunction
    wire [5:0] operand_source=(state==B_READ || state==B_CAPTURE) ? source_b : source_a;
    wire [127:0] operand_constant=constant_source(operand_source);
    wire [8:0] requested_target=opcode==5 ? 9'd2 : opcode==4 ? 9'd97 : opcode==7 ? 9'd96 : 9'd192;
    assign num_req_body={16'd0,{{64{b_signed && operand_b[127]}},operand_b},
        {{64{a_signed && operand_a[127]}},operand_a},requested_target,b_signed,a_signed,
        2'd0,opcode,8'd1,11'(HEIGHT),11'(WIDTH),numeric_id};
    assign num_req_valid=!rst && state==NUM_REQUEST && !exhausted;
    wire response_owned=num_rsp_body[175:0]==numeric_id;
    assign num_rsp_ready=!rst && state==NUM_CONSUME && response_owned;
    wire response_header_ok=num_rsp_body[180:176]=={2'd0,opcode} && num_rsp_body[189:181]==requested_target;
    wire response_success=num_rsp_body[199:190]==0;
    wire response_error_matrix=num_rsp_body[191:190]==FRAME_FAIL && num_rsp_body[584:200]==0 &&
        (num_rsp_body[199:192]==FORMAT || num_rsp_body[199:192]==COORD ||
         num_rsp_body[199:192]==OVERFLOW || num_rsp_body[199:192]==DIV_ZERO ||
         num_rsp_body[199:192]==UNSUPPORTED || num_rsp_body[199:192]==INTERNAL);

    reg [15:0] work_memory[0:127],work_q;
    wire [6:0] work_read_address={operand_source[3:0],word};
    wire result_extension=stored_signed && num_rsp_body[584];
    wire [8:0] result_cutoff={1'b0,stored_bits}-(stored_signed ? 9'd1 : 9'd0);
    wire [15:0] result_piece,response_write_word;
    generate if(SHARED_RETURN_WORDS)begin:shared_return_word
        assign num_rsp_word_index=state==NUM_SCAN ? scan_word : state==REG_WRITE ? {2'd0,word} : 5'd0;
        assign result_piece=scan_word==24 ? {{15{result_extension}},num_rsp_word16[0]} : num_rsp_word16;
        assign response_write_word=num_rsp_word16;
    end else begin:local_return_word
        wire [399:0] result_view={{15{result_extension}},num_rsp_body[584:200]};
        assign num_rsp_word_index=5'd0;
        assign result_piece=result_view[scan_word*16+:16];
        assign response_write_word=num_rsp_body[200+word*16+:16];
    end endgenerate
    always @(posedge clk)begin
        work_q<=work_memory[work_read_address];
        if(!rst && state==REG_WRITE && num_rsp_valid && response_owned)
            work_memory[{destination,word}]<=response_write_word;
    end
    function automatic word_extension_bad(input [15:0] piece,input [4:0] index,
        input [8:0] cutoff,input extension);
        reg [15:0] mask;
        begin
            if(index<cutoff[8:4])mask=0;
            else if(index>cutoff[8:4])mask=16'hffff;
            else mask=16'hffff<<cutoff[3:0];
            word_extension_bad=|((piece^{16{extension}})&mask);
        end
    endfunction
    wire piece_bad=word_extension_bad(result_piece,scan_word,result_cutoff,result_extension);
    task automatic clear_values;
        begin offset<=0;offset_valid<=0;offset_index<=0;tangent<=0;distance<=0;normal_ok<=0;end
    endtask
    task automatic fail_local;
        begin error<=1;fault<=1;drained<=0;clear_values();state<=LOCAL_CLOSE;end
    endtask
    task automatic fail_known;
        begin error<=1;fault<=1;drained<=0;clear_values();numeric_failed<=1;state<=NUM_CONSUME;end
    endtask
    task automatic fail_unknown;
        begin error<=1;fault<=1;drained<=0;clear_values();state<=UNKNOWN_RESULT;end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;pc<=K1;word<=0;scan_word<=0;closed_sequence<=0;exhausted<=0;
            register_valid<=0;operand_a<=0;operand_b<=0;scan_bad<=0;numeric_failed<=0;
            f_negative<=0;q_odd<=0;q_zero<=1;q_value<=0;round_up<=0;adjustment<=0;domain_lower_ok<=0;
            completed_small<=0;completed_sign<=0;completed_compare<=0;
            offset<=0;offset_valid<=0;offset_index<=0;tangent<=0;distance<=0;normal_ok<=0;
            error<=0;drained<=0;fault<=0;
        end else case(state)
            IDLE:if(command_fire)begin
                pc<=K1;word<=0;scan_word<=0;register_valid<=0;scan_bad<=0;numeric_failed<=0;
                f_negative<=0;q_odd<=0;q_zero<=1;q_value<=0;round_up<=0;adjustment<=0;domain_lower_ok<=0;
                clear_values();error<=0;drained<=0;state<=CHECK;
            end
            CHECK:if(WIDTH<6 || WIDTH>1920 || WIDTH%2!=0 || HEIGHT<5 || HEIGHT>1080 ||
                held_id[103:96]!=0 || mode>1 || !point_legal || !normal_legal)fail_local();
                else state<=PLAN;
            PLAN:begin
                word<=0;numeric_failed<=0;
                if(exhausted || !plan_valid || (source_a<16 && !register_valid[source_a[3:0]]) ||
                    (source_b<16 && !register_valid[source_b[3:0]]))fail_local();
                else state<=A_READ;
            end
            A_READ:state<=A_CAPTURE;
            A_CAPTURE:if(source_a>=16)begin operand_a<=operand_constant;word<=0;state<=B_READ;end
                else begin
                    operand_a<={work_q,operand_a[127:16]};
                    if(word==7)begin word<=0;state<=B_READ;end
                    else begin word<=word+3'd1;state<=A_READ;end
                end
            B_READ:state<=B_CAPTURE;
            B_CAPTURE:if(source_b>=16)begin operand_b<=operand_constant;state<=NUM_REQUEST;end
                else begin
                    operand_b<={work_q,operand_b[127:16]};
                    if(word==7)state<=NUM_REQUEST;
                    else begin word<=word+3'd1;state<=B_READ;end
                end
            NUM_REQUEST:if(exhausted)fail_local();else if(num_req_valid && num_req_ready)state<=NUM_WAIT;
            NUM_WAIT:if(num_rsp_valid)begin
                if(!response_owned)fail_unknown();
                else if(!response_header_ok || !(response_success || response_error_matrix) || !response_success)fail_known();
                else begin scan_word<=0;scan_bad<=0;state<=NUM_SCAN;end
            end
            NUM_SCAN:if(num_rsp_valid)begin
                if(!response_owned)fail_unknown();
                else begin
                    scan_bad<=scan_bad || piece_bad;
                    if(scan_word==24)begin
                        if(scan_bad || piece_bad || (opcode==5 && num_rsp_body[201:200]==3))fail_known();
                        else begin
                            // 同槽回写先撤销旧资格；八字完整写好才重新发布私有valid。
                            register_valid[destination]<=0;word<=0;state<=REG_WRITE;
                        end
                    end else scan_word<=scan_word+5'd1;
                end
            end
            REG_WRITE:if(num_rsp_valid)begin
                if(!response_owned)fail_unknown();
                else if(word==7)begin
                    register_valid[destination]<=1;
                    // 仅保存已通过全385资格的小字段；分支仍等真实NUM_CLOSE才使用。
                    completed_small<=num_rsp_body[220:200];completed_sign<=num_rsp_body[584];
                    completed_compare<=num_rsp_body[201:200];state<=NUM_CONSUME;
                end else word<=word+3'd1;
            end
            NUM_CONSUME:if(num_rsp_valid)begin
                if(!response_owned)fail_unknown();else if(num_rsp_ready)state<=NUM_CLOSE;
            end
            NUM_CLOSE:if(num_quiet)begin
                if(&closed_sequence)begin exhausted<=1;fault<=1;end else closed_sequence<=closed_sequence+64'd1;
                if(numeric_failed)begin drained<=1;state<=RESULT;end
                else begin
                    if(destination==4 && stored_bits==21 && !stored_signed)begin
                        q_value<=completed_small;q_zero<=completed_small==0;q_odd<=completed_small[0];
                    end
                    state<=PLAN;
                    case(pc)
                        K4:if(completed_compare==1)fail_local();else pc<=F1;
                        F6:begin f_negative<=completed_sign;pc<=F7;end
                        F7:pc<=coarse ? C1 : T1;
                        C9:begin round_up<=completed_compare==2 || (completed_compare==0 && q_odd);pc<=C10;end
                        C10,T6:pc<=completed_small==0 ? VU1 : VL1;
                        T4:pc<=q_zero ? TU1 : TL1;
                        TL5:if(completed_compare==1 || (completed_compare==0 && q_odd))begin
                            adjustment<=-2'sd1;round_up<=0;pc<=T6;
                        end else begin adjustment<=0;round_up<=0;pc<=TU1;end
                        TU5:begin
                            adjustment<=completed_compare==2 || (completed_compare==0 && q_odd) ? 2'sd1 : 2'sd0;
                            round_up<=completed_compare==2 || (completed_compare==0 && q_odd);pc<=T6;
                        end
                        VL5:if(completed_compare==2 || (completed_compare==0 && !q_odd))pc<=VU1;
                            else fail_local();
                        VU5:if(completed_compare==1 || (completed_compare==0 && !q_odd))begin
                            if(coarse)pc<=C_SIGN;else begin distance<=q_value;pc<=P1;end
                        end else fail_local();
                        C_SIGN:begin offset<=completed_small;pc<=C_LOW;end
                        C_LOW:begin domain_lower_ok<=completed_compare!=1;pc<=C_HIGH;end
                        C_HIGH:begin
                            if(domain_lower_ok && completed_compare!=2)begin
                                if(biased_offset<0 || biased_offset>48)fail_local();
                                else begin offset_valid<=1;offset_index<=biased_offset[5:0];pc<=P1;end
                            end else begin offset_valid<=0;offset_index<=0;pc<=P1;end
                        end
                        P5:begin tangent<=completed_small[17:0];pc<=N1;end
                        N12:begin normal_ok<=completed_compare!=2;drained<=1;state<=RESULT;end
                        default:if(pc<N12)pc<=pc+7'd1;else fail_local();
                    endcase
                end
            end
            LOCAL_CLOSE:if(num_quiet)begin drained<=1;state<=RESULT;end
            RESULT:if(response_valid && response_ready)state<=IDLE;
            UNKNOWN_RESULT:if(response_valid && response_ready)state<=ISOLATED;
            ISOLATED:begin end
            default:begin error<=1;fault<=1;drained<=0;clear_values();state<=ISOLATED;end
        endcase
    end
endmodule
