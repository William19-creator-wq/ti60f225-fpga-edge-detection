// PM1/PM2：逐点评估半径与法线；全部乘法/开方/比较复用父级唯一 scalar。
// EVAL 正文从接受到回复消费且 quiet 保持；UNKNOWN 保持借用及物理所有权到共同复位。
module board_geometry_point_math #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter bit SHARED_RETURN_WORDS=1'b0,ENABLE_RADIUS_ONLY=1'b0
)(
    input wire clk,rst,
    input wire eval_req_valid,output wire eval_req_ready,
    input wire [95:0] eval_scope,input wire [7:0] eval_seed,
    input wire [2:0] eval_pass,input wire [20:0] eval_ordinal,
    input wire [63:0] eval_point,input wire signed [17:0] eval_cx,eval_cy,
    input wire [15:0] eval_tolerance,
    output wire eval_rsp_valid,input wire eval_rsp_ready,
    output wire [95:0] eval_rsp_scope,output wire [7:0] eval_rsp_seed,
    output wire [2:0] eval_rsp_pass,output wire [20:0] eval_rsp_ordinal,
    output reg [17:0] radius,output reg normal_ok,error,drained,
    output wire quiet,output reg fault,
    output wire num_req_valid,input wire num_req_ready,output wire [621:0] num_req_body,
    input wire num_rsp_valid,output wire num_rsp_ready,input wire [584:0] num_rsp_body,
    input wire num_quiet,
    output wire [4:0] num_rsp_word_index,input wire [15:0] num_rsp_word16,
    input wire eval_radius_only
);
    import scalar_protocol_pkg::*;
    localparam IDLE=0,CHECK=1,PLAN=2,A_READ=3,A_CAPTURE=4,B_READ=5,B_CAPTURE=6,
        NUM_REQUEST=7,NUM_WAIT=8,NUM_SCAN=9,REG_WRITE=10,NUM_CONSUME=11,
        NUM_CLOSE=12,RESULT=13,UNKNOWN_RESULT=14,ISOLATED=15,LOCAL_CLOSE=16;
    reg [4:0] state,pc,scan_word;
    reg [2:0] word;
    reg [63:0] closed_sequence;
    reg exhausted,scan_bad,numeric_failed;
    reg [15:0] register_valid;
    reg [127:0] operand_a,operand_b;
    // 新位同EVAL正文借用到回复消费及quiet；默认关闭时未连接输入不进旧路径。
    wire radius_only_effective=ENABLE_RADIUS_ONLY&&eval_radius_only;

    // 除已关闭序号外不锁第二份身份；父保持整个 EVAL，禁止按点或 job 重置序号。
    wire [175:0] numeric_id={8'hc1,closed_sequence,8'd0,eval_scope};
    assign eval_rsp_scope=eval_scope;
    assign eval_rsp_seed=eval_seed;
    assign eval_rsp_pass=eval_pass;
    assign eval_rsp_ordinal=eval_ordinal;
    assign quiet=!rst && state==IDLE && num_quiet;
    assign eval_req_ready=quiet && !exhausted;
    assign eval_rsp_valid=!rst && (state==RESULT || state==UNKNOWN_RESULT);

    wire signed [10:0] gx=eval_point[10:0],gy=eval_point[21:11];
    wire [10:0] ax=gx[10] ? -gx : gx;
    wire [10:0] ay=gy[10] ? -gy : gy;
    wire point_legal=eval_point[63]==0 && eval_point[31:24]==0 &&
        eval_point[42:32]<WIDTH && eval_point[53:43]<HEIGHT &&
        gx>=-11'sd1020 && gx<=11'sd1020 && gy>=-11'sd1020 && gy<=11'sd1020 &&
        ({1'b0,ax}+{1'b0,ay})<=12'd1530 && eval_point[21:0]!=0 &&
        eval_ordinal<WIDTH*HEIGHT;

    reg [2:0] opcode;
    reg [5:0] source_a,source_b;
    reg [3:0] destination;
    reg a_signed,b_signed,stored_signed;
    reg [7:0] stored_bits;
    // 16 个 slot；最后右式复用临时 slot15，比较复用已经不用的 slot6。
    // 位宽是资格边界，绝不能据低128位有值就跳过完整385位检查。
    always @*begin
        opcode=0;source_a=16;source_b=16;destination=0;
        a_signed=0;b_signed=0;stored_signed=0;stored_bits=1;
        case(pc)
            0:begin opcode=2;source_a=17;source_b=19;destination=0;
                b_signed=1;stored_signed=1;stored_bits=19;end
            1:begin opcode=2;source_a=18;source_b=20;destination=1;
                b_signed=1;stored_signed=1;stored_bits=19;end
            2:begin source_a=0;source_b=0;destination=2;a_signed=1;b_signed=1;stored_bits=38;end
            3:begin source_a=1;source_b=1;destination=3;a_signed=1;b_signed=1;stored_bits=38;end
            4:begin opcode=1;source_a=2;source_b=3;destination=4;stored_bits=39;end
            5:begin opcode=4;source_a=4;source_b=16;destination=5;stored_bits=18;end
            6:begin source_a=22;source_b=0;destination=6;
                a_signed=1;b_signed=1;stored_signed=1;stored_bits=30;end
            7:begin source_a=21;source_b=1;destination=7;
                a_signed=1;b_signed=1;stored_signed=1;stored_bits=30;end
            8:begin opcode=2;source_a=7;source_b=6;destination=8;
                a_signed=1;b_signed=1;stored_signed=1;stored_bits=30;end
            9:begin source_a=8;source_b=8;destination=9;a_signed=1;b_signed=1;stored_bits=60;end
            10:begin source_a=9;source_b=24;destination=10;stored_bits=92;end
            11:begin source_a=21;source_b=21;destination=11;a_signed=1;b_signed=1;stored_bits=22;end
            12:begin source_a=22;source_b=22;destination=12;a_signed=1;b_signed=1;stored_bits=22;end
            13:begin opcode=1;source_a=11;source_b=12;destination=13;stored_bits=23;end
            14:begin source_a=23;source_b=23;destination=14;stored_bits=32;end
            15:begin source_a=14;source_b=13;destination=15;stored_bits=55;end
            16:begin source_a=15;source_b=4;destination=15;stored_bits=94;end
            17:begin opcode=5;source_a=10;source_b=15;destination=6;stored_bits=2;end
            default:begin end
        endcase
    end
    wire [8:0] requested_target=opcode==5 ? 9'd2 : opcode==4 ? 9'd97 : 9'd192;
    assign num_req_body={16'd0,{{64{b_signed && operand_b[127]}},operand_b},
        {{64{a_signed && operand_a[127]}},operand_a},requested_target,b_signed,a_signed,
        2'd0,opcode,8'd1,11'(HEIGHT),11'(WIDTH),numeric_id};
    assign num_req_valid=!rst && state==NUM_REQUEST && !exhausted;
    wire response_owned=num_rsp_body[175:0]==numeric_id;
    assign num_rsp_ready=!rst && state==NUM_CONSUME && response_owned;

    function automatic [127:0] constant_source(input reg [5:0] source);
        begin
            constant_source=0;
            case(source)
                17:constant_source={113'd0,eval_point[42:32],4'd0};
                18:constant_source={113'd0,eval_point[53:43],4'd0};
                19:constant_source={{110{eval_cx[17]}},eval_cx};
                20:constant_source={{110{eval_cy[17]}},eval_cy};
                21:constant_source={{117{gx[10]}},gx};
                22:constant_source={{117{gy[10]}},gy};
                23:constant_source={112'd0,eval_tolerance};
                24:constant_source=128'd4294836225;
                default:begin end
            endcase
        end
    endfunction
    wire [5:0] operand_source=(state==B_READ || state==B_CAPTURE) ? source_b : source_a;
    wire [127:0] operand_constant=constant_source(operand_source);
    reg [15:0] work_memory[0:127],work_q;
    wire [6:0] work_read_address={operand_source[3:0],word};
    wire result_extension=stored_signed && num_rsp_body[584];
    wire [8:0] result_cutoff={1'b0,stored_bits}-(stored_signed ? 9'd1 : 9'd0);
    wire [15:0] result_piece,response_write_word;
    generate if(SHARED_RETURN_WORDS)begin:shared_return_word
        // 父级按游标选择；不能依 valid/quiet 把 held 返回字置零。
        assign num_rsp_word_index=state==NUM_SCAN ? scan_word :
            state==REG_WRITE ? {2'd0,word} : 5'd0;
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
    function automatic word_extension_bad(input logic [15:0] piece,input logic [4:0] index,
        input logic [8:0] cutoff,input logic extension);
        logic [15:0] mask;
        begin
            if(index<cutoff[8:4])mask=0;
            else if(index>cutoff[8:4])mask=16'hffff;
            else mask=16'hffff << cutoff[3:0];
            word_extension_bad=|((piece^{16{extension}})&mask);
        end
    endfunction
    wire piece_bad=word_extension_bad(result_piece,scan_word,result_cutoff,result_extension);
    wire response_header_ok=num_rsp_body[180:176]=={2'd0,opcode} &&
        num_rsp_body[189:181]==requested_target;
    wire response_success=num_rsp_body[191:190]==VALUE && num_rsp_body[199:192]==NONE;
    wire response_error_matrix=num_rsp_body[191:190]==FRAME_FAIL && num_rsp_body[584:200]==0 &&
        (num_rsp_body[199:192]==FORMAT || num_rsp_body[199:192]==COORD ||
         num_rsp_body[199:192]==OVERFLOW || num_rsp_body[199:192]==DIV_ZERO ||
         num_rsp_body[199:192]==UNSUPPORTED || num_rsp_body[199:192]==INTERNAL);

    // 所有错误先归还已确认的 child 再等 quiet。异 ID 则不消费、不取消、不伪关闭。
    task automatic fail_known;
        begin error<=1;fault<=1;radius<=0;normal_ok<=0;numeric_failed<=1;state<=NUM_CONSUME;end
    endtask
    task automatic fail_unknown;
        begin error<=1;fault<=1;radius<=0;normal_ok<=0;drained<=0;state<=UNKNOWN_RESULT;end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;pc<=0;scan_word<=0;word<=0;closed_sequence<=0;
            exhausted<=0;scan_bad<=0;numeric_failed<=0;register_valid<=0;
            radius<=0;normal_ok<=0;error<=0;drained<=0;fault<=0;
        end else case(state)
            IDLE:if(eval_req_valid && eval_req_ready)begin
                pc<=0;word<=0;scan_word<=0;register_valid<=0;
                radius<=0;normal_ok<=0;error<=0;drained<=0;numeric_failed<=0;state<=CHECK;
            end
            CHECK:if(!point_legal || WIDTH<6 || WIDTH>1920 || (WIDTH%2)!=0 || HEIGHT<5 || HEIGHT>1080)begin
                error<=1;fault<=1;state<=LOCAL_CLOSE;
            end else state<=PLAN;
            PLAN:begin
                word<=0;numeric_failed<=0;
                if(pc>17 || (source_a<16 && !register_valid[source_a[3:0]]) ||
                    (source_b<16 && !register_valid[source_b[3:0]]))begin
                    error<=1;fault<=1;radius<=0;normal_ok<=0;state<=LOCAL_CLOSE;
                end else state<=A_READ;
            end
            A_READ:state<=A_CAPTURE;
            A_CAPTURE:begin
                if(source_a>=16)begin operand_a<=operand_constant;word<=0;state<=B_READ;end
                else begin
                    operand_a<={work_q,operand_a[127:16]};
                    if(word==7)begin word<=0;state<=B_READ;end
                    else begin word<=word+3'd1;state<=A_READ;end
                end
            end
            B_READ:state<=B_CAPTURE;
            B_CAPTURE:begin
                if(source_b>=16)begin operand_b<=operand_constant;state<=NUM_REQUEST;end
                else begin
                    operand_b<={work_q,operand_b[127:16]};
                    if(word==7)state<=NUM_REQUEST;
                    else begin word<=word+3'd1;state<=B_READ;end
                end
            end
            NUM_REQUEST:if(exhausted)begin
                error<=1;fault<=1;radius<=0;normal_ok<=0;state<=LOCAL_CLOSE;
            end else if(num_req_valid && num_req_ready)state<=NUM_WAIT;
            NUM_WAIT:if(num_rsp_valid)begin
                if(!response_owned)fail_unknown();
                else if(!response_header_ok || !(response_success || response_error_matrix) || !response_success)
                    // 正确错误矩阵仍是本点失败；非法矩阵也不能当成合法数值。
                    fail_known();
                else begin scan_word<=0;scan_bad<=0;state<=NUM_SCAN;end
            end
            NUM_SCAN:if(num_rsp_valid)begin
                if(!response_owned)fail_unknown();
                else begin
                    scan_bad<=scan_bad || piece_bad;
                    if(scan_word==24)begin
                        if(scan_bad || piece_bad || (opcode==5 && num_rsp_body[201:200]==2'd3))fail_known();
                        else begin word<=0;state<=REG_WRITE;end
                    end else scan_word<=scan_word+5'd1;
                end
            end
            REG_WRITE:if(num_rsp_valid)begin
                if(!response_owned)fail_unknown();
                else if(word==7)begin
                    register_valid[destination]<=1;
                    if(pc==5)radius<=num_rsp_body[217:200];
                    if(pc==17)normal_ok<=num_rsp_body[201:200]!=2'd2;
                    state<=NUM_CONSUME;
                end else word<=word+3'd1;
            end
            NUM_CONSUME:if(num_rsp_valid)begin
                if(!response_owned)fail_unknown();
                else if(num_rsp_ready)state<=NUM_CLOSE;
            end
            NUM_CLOSE:if(num_quiet)begin
                if(&closed_sequence)begin exhausted<=1;fault<=1;end
                else closed_sequence<=closed_sequence+64'd1;
                if(numeric_failed)begin drained<=1;state<=RESULT;end
                else if(pc==17 || (pc==5 && (radius==0 || radius_only_effective)))begin
                    // pc5已完整资格/提交/消费，只有本NUM_CLOSE真quiet沿才停止法线十二步。
                    if(pc==5 && radius_only_effective)normal_ok<=0;
                    drained<=1;state<=RESULT;
                end
                else begin pc<=pc+5'd1;state<=PLAN;end
            end
            LOCAL_CLOSE:if(num_quiet)begin drained<=1;state<=RESULT;end
            RESULT:if(eval_rsp_valid && eval_rsp_ready)state<=IDLE;
            UNKNOWN_RESULT:if(eval_rsp_valid && eval_rsp_ready)state<=ISOLATED;
            ISOLATED:begin end
            default:begin error<=1;fault<=1;radius<=0;normal_ok<=0;drained<=0;state<=ISOLATED;end
        endcase
    end
endmodule
