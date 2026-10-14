// PM1/PM2：默认保留父唯一scalar的共享NUM路径；FAST1用一个DSP/一个RAM本地计算半径与法线。
// FAST1仍先取得父NUM owner1 lease，EVAL消费且PM quiet后才允许释放，不能以NUM始终quiet伪关闭。
// EVAL 正文从接受到回复消费且 quiet 保持；UNKNOWN 保持借用及物理所有权到共同复位。
module board_geometry_point_math #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter bit SHARED_RETURN_WORDS=1'b0,ENABLE_RADIUS_ONLY=1'b0,FAST_POINT_MATH=1'b0
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
    generate if(!FAST_POINT_MATH)begin:shared_numeric_path
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
    if(SHARED_RETURN_WORDS)begin:shared_return_word
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
    end
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
    end else begin:fast_point_path
        // 本地PM只接EVAL，仍由父先授予NUM owner1，直到EVAL消费及PM quiet才释放。
        // 一个16x16 DSP、一个简单双端口RAM；共享NUM既不请求也不消费。
        localparam F_IDLE=0,F_CHECK=1,F_PLAN=2,F_PREP=3,F_ASIGN_READ=4,F_ASIGN_CAPTURE=5,
            F_BSIGN_READ=6,F_BSIGN_CAPTURE=7,F_CLEAR=8,F_MA_READ=9,F_MA_CAPTURE=10,
            F_MB_READ=11,F_MB_CAPTURE=12,F_MP_READ=13,F_MP_CAPTURE=14,F_MACC=15,F_MCARRY=16,
            F_COMMIT_READ=17,F_COMMIT_WRITE=18,F_AA_READ=19,F_AA_CAPTURE=20,
            F_AB_READ=21,F_AB_CAPTURE=22,F_ADD_WORD=23,F_ROOT_READ=24,F_ROOT_CAPTURE=25,
            F_ROOT_STEP=26,F_ROOT_ROUND=27,F_ROOT_WRITE=28,F_CA_READ=29,F_CA_CAPTURE=30,
            F_CB_READ=31,F_CB_CAPTURE=32,F_COMPARE=33,F_COMPARE_WRITE=34,F_CLOSE=35,
            F_LOCAL_CLOSE=36,F_RESULT=37,F_UNKNOWN=38,F_ISOLATED=39;
        reg [5:0] state;
        reg [4:0] pc;
        reg [2:0] word,multiply_i,multiply_j;
        reg [3:0] limbs_a,limbs_b;
        reg [63:0] closed_sequence;
        reg exhausted,numeric_failed,bad_zero,bad_one,isolate_after_result;
        reg [15:0] register_valid,a_word,b_word,multiply_existing,multiply_carry;
        reg [31:0] product;
        reg a_negative,b_negative,a_convert_carry,b_convert_carry,negative_product,commit_carry;
        reg a_nonzero,b_nonzero,alu_carry;
        reg [1:0] comparison,root_pair;
        reg [6:0] root_remaining;
        reg [19:0] root_value;
        reg [21:0] root_remainder;
        reg [2:0] opcode;
        reg [5:0] source_a,source_b;
        reg [3:0] destination;
        reg a_signed,b_signed,stored_signed;
        reg [7:0] stored_bits;
        wire radius_only_effective=ENABLE_RADIUS_ONLY&&eval_radius_only;
        wire signed [10:0] gx=eval_point[10:0],gy=eval_point[21:11];
        wire [10:0] ax=gx[10] ? -gx : gx;
        wire [10:0] ay=gy[10] ? -gy : gy;
        wire point_legal=eval_point[63]==0 && eval_point[31:24]==0 &&
            eval_point[42:32]<WIDTH && eval_point[53:43]<HEIGHT &&
            gx>=-11'sd1020 && gx<=11'sd1020 && gy>=-11'sd1020 && gy<=11'sd1020 &&
            ({1'b0,ax}+{1'b0,ay})<=12'd1530 && eval_point[21:0]!=0 &&
            eval_ordinal<WIDTH*HEIGHT;
        wire lease_safe=num_quiet&&!num_rsp_valid;
        wire active=state!=F_IDLE&&state!=F_RESULT&&state!=F_UNKNOWN&&state!=F_ISOLATED;
        assign quiet=!rst&&state==F_IDLE&&lease_safe;
        assign eval_req_ready=quiet&&!exhausted;
        assign eval_rsp_valid=!rst&&(state==F_RESULT||state==F_UNKNOWN);
        assign eval_rsp_scope=eval_scope;
        assign eval_rsp_seed=eval_seed;
        assign eval_rsp_pass=eval_pass;
        assign eval_rsp_ordinal=eval_ordinal;
        assign num_req_valid=1'b0;
        assign num_req_body=622'd0;
        assign num_rsp_ready=1'b0;
        assign num_rsp_word_index=5'd0;

        // 与旧pc的整数式及资格位界一一对应；slot15的两次生命期不混淆。
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
        function automatic [3:0] source_limbs(input reg [5:0] source,input reg [4:0] instruction);
            begin
                source_limbs=4'd1;
                case(source)
                    0,1,5,6,7,8,11,12,13,14,19,20,24:source_limbs=4'd2;
                    2,3,4:source_limbs=4'd3;
                    9:source_limbs=4'd4;
                    10:source_limbs=4'd6;
                    15:source_limbs=instruction==16 ? 4'd4 : 4'd6;
                    default:begin end
                endcase
            end
        endfunction
        // 常量逐16位提供；signed常量的高字是完整符号扩展，不仅取低词猜符号。
        function automatic [15:0] constant_word(input reg [5:0] source,input reg [2:0] index);
            reg [31:0] value;
            reg extension;
            begin
                value=0;extension=0;
                case(source)
                    17:value={17'd0,eval_point[42:32],4'd0};
                    18:value={17'd0,eval_point[53:43],4'd0};
                    19:begin value={{14{eval_cx[17]}},eval_cx};extension=eval_cx[17];end
                    20:begin value={{14{eval_cy[17]}},eval_cy};extension=eval_cy[17];end
                    21:begin value={{21{gx[10]}},gx};extension=gx[10];end
                    22:begin value={{21{gy[10]}},gy};extension=gy[10];end
                    23:value={16'd0,eval_tolerance};
                    24:value=32'd4294836225;
                    default:begin end
                endcase
                if(index==0)constant_word=value[15:0];
                else if(index==1)constant_word=value[31:16];
                else constant_word={16{extension}};
            end
        endfunction

        reg [5:0] read_source;
        reg [2:0] read_word;
        reg [8:0] read_address,write_address;
        reg read_enable,write_enable;
        reg [15:0] write_value;
        wire [19:0] ram_q;
        wire [3:0] work_column={1'b0,multiply_i}+{1'b0,multiply_j};
        wire [4:0] work_carry_column={2'd0,multiply_i}+{1'b0,limbs_b};
        always @*begin
            read_source=source_a;read_word=word;read_enable=0;
            case(state)
                F_ASIGN_READ,F_ASIGN_CAPTURE:begin read_word=3'(limbs_a-4'd1);end
                F_BSIGN_READ,F_BSIGN_CAPTURE:begin read_source=source_b;read_word=3'(limbs_b-4'd1);end
                F_MA_READ,F_MA_CAPTURE:read_word=multiply_i;
                F_MB_READ,F_MB_CAPTURE:begin read_source=source_b;read_word=multiply_j;end
                F_AB_READ,F_AB_CAPTURE,F_CB_READ,F_CB_CAPTURE:read_source=source_b;
                default:begin end
            endcase
            read_address={2'd0,read_source[3:0],read_word};
            case(state)
                F_ASIGN_READ:read_enable=a_signed&&source_a<16;
                F_BSIGN_READ:read_enable=b_signed&&source_b<16;
                F_MA_READ,F_MB_READ,F_AA_READ,F_AB_READ,F_CA_READ,F_CB_READ:read_enable=read_source<16;
                F_MP_READ:begin read_enable=1;read_address=9'd128+{5'd0,work_column};end
                F_COMMIT_READ:begin read_enable=1;read_address=9'd128+{6'd0,word};end
                F_ROOT_READ:begin
                    read_enable=1;read_address=9'd32+9'((root_remaining-7'd1)>>3);
                end
                default:begin end
            endcase
            if(rst||!lease_safe)read_enable=0;
        end
        wire [15:0] offered_word=read_source<16 ? ram_q[15:0] : constant_word(read_source,read_word);
        wire [16:0] a_absolute={1'b0,(a_negative ? ~offered_word : offered_word)}+
            {16'd0,(a_negative&&a_convert_carry)};
        wire [16:0] b_absolute={1'b0,(b_negative ? ~offered_word : offered_word)}+
            {16'd0,(b_negative&&b_convert_carry)};
        wire [47:0] dsp_product;
        EFX_DSP48 #(.MODE("NORMAL"),.SIGNED(1'b0),.A_REG(1'b0),.B_REG(1'b0),.C_REG(1'b0),
            .P_REG(1'b0),.OP_REG(1'b0),.W_REG(1'b0),.O_REG(1'b0),.SHIFTER(1'b0),
            .P_EXT("ALIGN_RIGHT"),.M_SEL("P"),.N_SEL("CONST0"),.W_SEL("P")) multiply(
            .A({3'd0,a_word}),.B({2'd0,b_word}),.C(18'd0),.CASCIN(48'd0),.OP(2'd0),
            .SHIFT_ENA(1'b0),.CLK(1'b0),.CE(1'b0),.RST(1'b0),.O(dsp_product),.CASCOUT(),.OVFL());
        wire [32:0] multiply_sum={1'b0,product}+{17'd0,multiply_existing}+{17'd0,multiply_carry};
        wire [16:0] committed_sum={1'b0,(negative_product ? ~ram_q[15:0] : ram_q[15:0])}+
            {16'd0,(negative_product&&commit_carry)};
        wire [16:0] add_sum={1'b0,a_word}+{1'b0,(opcode==2 ? ~b_word : b_word)}+{16'd0,alu_carry};
        wire [15:0] qualified_piece=state==F_COMMIT_WRITE ? committed_sum[15:0] : add_sum[15:0];
        function automatic [15:0] extension_mask(input reg [2:0] index,input reg [7:0] bits,
            input reg signed_value);
            reg [8:0] cutoff;
            begin
                cutoff={1'b0,bits}-(signed_value ? 9'd1 : 9'd0);
                if({2'd0,index}<cutoff[8:4])extension_mask=0;
                else if({2'd0,index}>cutoff[8:4])extension_mask=16'hffff;
                else extension_mask=16'hffff<<cutoff[3:0];
            end
        endfunction
        wire [15:0] piece_mask=extension_mask(word,stored_bits,stored_signed);
        wire piece_bad_zero=|(qualified_piece&piece_mask);
        wire piece_bad_one=|((~qualified_piece)&piece_mask);
        wire final_extension=stored_signed&&qualified_piece[15];
        wire final_bad=final_extension ? bad_one||piece_bad_one : bad_zero||piece_bad_zero;
        wire [23:0] shifted_remainder={root_remainder,root_pair};
        wire [21:0] root_trial={root_value,2'b01};
        wire root_accept=shifted_remainder[21:0]>=root_trial;
        wire [22:0] root_difference={1'b0,shifted_remainder[21:0]}-{1'b0,root_trial};
        wire [20:0] appended_root={root_value,root_accept};
        wire [20:0] rounded_root={1'b0,root_value}+
            (({2'd0,root_remainder}>{4'd0,root_value}) ? 21'd1 : 21'd0);
        wire [1:0] next_comparison=comparison!=0 ? comparison :
            a_word<b_word ? 2'd1 : a_word>b_word ? 2'd2 : 2'd0;
        always @*begin
            write_enable=0;write_address=0;write_value=0;
            case(state)
                F_CLEAR:begin write_enable=1;write_address=9'd128+{6'd0,word};end
                F_MACC:begin
                    write_enable=!multiply_sum[32];write_address=9'd128+{5'd0,work_column};write_value=multiply_sum[15:0];
                end
                F_MCARRY:begin
                    write_enable=1;write_address=9'd128+{4'd0,work_carry_column};write_value=multiply_carry;
                end
                F_COMMIT_WRITE:begin
                    write_enable=1;write_address={2'd0,destination,word};write_value=committed_sum[15:0];
                end
                F_ADD_WORD:begin
                    write_enable=1;write_address={2'd0,destination,word};write_value=add_sum[15:0];
                end
                F_ROOT_WRITE:begin
                    write_enable=1;write_address={2'd0,destination,word};
                    if(word==0)write_value=root_value[15:0];
                    else if(word==1)write_value={12'd0,root_value[19:16]};
                end
                F_COMPARE_WRITE:begin
                    write_enable=comparison!=3;write_address={2'd0,destination,word};
                    if(word==0)write_value={14'd0,comparison};
                end
                default:begin end
            endcase
            if(rst||!lease_safe)write_enable=0;
        end
        EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_FIRST")) work_memory(
            .WCLK(clk),.WE({2{write_enable}}),.WCLKE(1'b1),.WADDREN(1'b1),.WDATA({4'd0,write_value}),.WADDR(write_address),
            .RCLK(clk),.RE(read_enable),.RST(1'b0),.RADDREN(1'b1),.RDATA(ram_q),.RADDR(read_address));
        task automatic fail_known;
            begin error<=1;fault<=1;radius<=0;normal_ok<=0;numeric_failed<=1;state<=F_CLOSE;end
        endtask
        task automatic fail_local;
            begin error<=1;fault<=1;radius<=0;normal_ok<=0;state<=F_LOCAL_CLOSE;end
        endtask
        task automatic fail_unknown;
            begin error<=1;fault<=1;radius<=0;normal_ok<=0;drained<=0;state<=F_UNKNOWN;end
        endtask
        always @(posedge clk)begin
            if(rst)begin
                state<=F_IDLE;pc<=0;word<=0;multiply_i<=0;multiply_j<=0;limbs_a<=0;limbs_b<=0;
                closed_sequence<=0;exhausted<=0;numeric_failed<=0;register_valid<=0;isolate_after_result<=0;
                bad_zero<=0;bad_one<=0;a_negative<=0;b_negative<=0;a_convert_carry<=0;b_convert_carry<=0;
                negative_product<=0;commit_carry<=0;a_nonzero<=0;b_nonzero<=0;alu_carry<=0;
                comparison<=0;root_remaining<=0;root_value<=0;root_remainder<=0;root_pair<=0;
                radius<=0;normal_ok<=0;error<=0;drained<=0;fault<=0;
            end else if(state==F_RESULT)begin
                // valid已发布后身份/数值/error/drained不得撤回；晚到NUM异常只记录故障。
                // 真消费后隔离且quiet保持0，不消费NUM、不伪关闭，也不发布第二回复。
                if(!lease_safe)begin fault<=1;isolate_after_result<=1;end
                if(eval_rsp_valid&&eval_rsp_ready)
                    state<=isolate_after_result||!lease_safe ? F_ISOLATED : F_IDLE;
            end else if(active&&!lease_safe)fail_unknown();
            else case(state)
                F_IDLE:if(eval_req_valid&&eval_req_ready)begin
                    pc<=0;word<=0;register_valid<=0;numeric_failed<=0;isolate_after_result<=0;
                    radius<=0;normal_ok<=0;error<=0;drained<=0;state<=F_CHECK;
                end
                F_CHECK:if(!point_legal||WIDTH<6||WIDTH>1920||(WIDTH%2)!=0||HEIGHT<5||HEIGHT>1080)
                    fail_local();
                else state<=F_PLAN;
                F_PLAN:if(exhausted||pc>17||(source_a<16&&!register_valid[source_a[3:0]])||
                    (source_b<16&&!register_valid[source_b[3:0]]))fail_local();
                else state<=F_PREP;
                F_PREP:begin
                    word<=0;bad_zero<=0;bad_one<=0;numeric_failed<=0;
                    limbs_a<=source_limbs(source_a,pc);limbs_b<=source_limbs(source_b,pc);
                    a_negative<=0;b_negative<=0;a_convert_carry<=0;b_convert_carry<=0;
                    a_nonzero<=0;b_nonzero<=0;negative_product<=0;commit_carry<=0;
                    case(opcode)
                        0:state<=F_ASIGN_READ;
                        1,2:begin alu_carry<=opcode==2;state<=F_AA_READ;end
                        4:begin root_value<=0;root_remainder<=0;root_remaining<=20;state<=F_ROOT_READ;end
                        5:begin comparison<=0;word<=5;state<=F_CA_READ;end
                        default:fail_local();
                    endcase
                end
                F_ASIGN_READ:if(a_signed)state<=F_ASIGN_CAPTURE;else state<=F_BSIGN_READ;
                F_ASIGN_CAPTURE:begin
                    a_negative<=offered_word[15];a_convert_carry<=offered_word[15];state<=F_BSIGN_READ;
                end
                F_BSIGN_READ:if(b_signed)state<=F_BSIGN_CAPTURE;else state<=F_CLEAR;
                F_BSIGN_CAPTURE:begin b_negative<=offered_word[15];state<=F_CLEAR;end
                F_CLEAR:if(word==7)begin multiply_i<=0;multiply_j<=0;state<=F_MA_READ;end
                    else word<=word+3'd1;
                F_MA_READ:state<=F_MA_CAPTURE;
                F_MA_CAPTURE:begin
                    a_word<=a_absolute[15:0];a_convert_carry<=a_negative&&a_absolute[16];
                    a_nonzero<=a_nonzero||a_absolute[15:0]!=0;
                    b_convert_carry<=b_negative;multiply_carry<=0;multiply_j<=0;state<=F_MB_READ;
                end
                F_MB_READ:state<=F_MB_CAPTURE;
                F_MB_CAPTURE:begin
                    b_word<=b_absolute[15:0];b_convert_carry<=b_negative&&b_absolute[16];
                    b_nonzero<=b_nonzero||b_absolute[15:0]!=0;state<=F_MP_READ;
                end
                F_MP_READ:state<=F_MP_CAPTURE;
                F_MP_CAPTURE:if(|dsp_product[47:32])fail_known();
                    else begin product<=dsp_product[31:0];multiply_existing<=ram_q[15:0];state<=F_MACC;end
                F_MACC:if(multiply_sum[32])fail_known();else begin
                    multiply_carry<=multiply_sum[31:16];
                    if({1'b0,multiply_j}+4'd1==limbs_b)state<=F_MCARRY;
                    else begin multiply_j<=multiply_j+3'd1;state<=F_MB_READ;end
                end
                F_MCARRY:if({1'b0,multiply_i}+4'd1==limbs_a)begin
                    negative_product<=(a_negative^b_negative)&&a_nonzero&&b_nonzero;
                    commit_carry<=(a_negative^b_negative)&&a_nonzero&&b_nonzero;
                    word<=0;state<=F_COMMIT_READ;
                end else begin multiply_i<=multiply_i+3'd1;state<=F_MA_READ;end
                F_COMMIT_READ:state<=F_COMMIT_WRITE;
                F_COMMIT_WRITE:begin
                    commit_carry<=negative_product&&committed_sum[16];
                    bad_zero<=bad_zero||piece_bad_zero;bad_one<=bad_one||piece_bad_one;
                    if(word==7)begin
                        if(final_bad)fail_known();else begin register_valid[destination]<=1;state<=F_CLOSE;end
                    end else begin word<=word+3'd1;state<=F_COMMIT_READ;end
                end
                F_AA_READ:state<=F_AA_CAPTURE;
                F_AA_CAPTURE:begin a_word<=offered_word;state<=F_AB_READ;end
                F_AB_READ:state<=F_AB_CAPTURE;
                F_AB_CAPTURE:begin b_word<=offered_word;state<=F_ADD_WORD;end
                F_ADD_WORD:begin
                    alu_carry<=add_sum[16];bad_zero<=bad_zero||piece_bad_zero;bad_one<=bad_one||piece_bad_one;
                    if(word==7)begin
                        if(final_bad)fail_known();else begin register_valid[destination]<=1;state<=F_CLOSE;end
                    end else begin word<=word+3'd1;state<=F_AA_READ;end
                end
                F_ROOT_READ:state<=F_ROOT_CAPTURE;
                F_ROOT_CAPTURE:begin
                    root_pair<=ram_q[((root_remaining-7'd1)&7'd7)*2+:2];state<=F_ROOT_STEP;
                end
                F_ROOT_STEP:if(|shifted_remainder[23:22]||appended_root[20])fail_known();
                    else begin
                        root_value<=appended_root[19:0];
                        root_remainder<=root_accept ? root_difference[21:0] : shifted_remainder[21:0];
                        if(root_remaining==1)state<=F_ROOT_ROUND;
                        else begin root_remaining<=root_remaining-7'd1;state<=F_ROOT_READ;end
                    end
                F_ROOT_ROUND:if(|rounded_root[20:18])fail_known();
                    else begin root_value<=rounded_root[19:0];word<=0;state<=F_ROOT_WRITE;end
                F_ROOT_WRITE:if(word==7)begin
                    register_valid[destination]<=1;radius<=root_value[17:0];state<=F_CLOSE;
                end else word<=word+3'd1;
                F_CA_READ:state<=F_CA_CAPTURE;
                F_CA_CAPTURE:begin a_word<=offered_word;state<=F_CB_READ;end
                F_CB_READ:state<=F_CB_CAPTURE;
                F_CB_CAPTURE:begin b_word<=offered_word;state<=F_COMPARE;end
                F_COMPARE:begin
                    comparison<=next_comparison;
                    if(word==0)begin word<=0;state<=F_COMPARE_WRITE;end
                    else begin word<=word-3'd1;state<=F_CA_READ;end
                end
                F_COMPARE_WRITE:if(comparison==3)fail_known();else if(word==7)begin
                    register_valid[destination]<=1;normal_ok<=comparison!=2;state<=F_CLOSE;
                end else word<=word+3'd1;
                F_CLOSE:begin
                    if(&closed_sequence)begin exhausted<=1;fault<=1;end
                    else closed_sequence<=closed_sequence+64'd1;
                    if(numeric_failed)begin drained<=1;state<=F_RESULT;end
                    else if(pc==17||(pc==5&&(radius==0||radius_only_effective)))begin
                        if(pc==5&&radius_only_effective)normal_ok<=0;
                        drained<=1;state<=F_RESULT;
                    end else begin pc<=pc+5'd1;state<=F_PLAN;end
                end
                F_LOCAL_CLOSE:begin drained<=1;state<=F_RESULT;end
                F_RESULT:begin end // 已在held优先分支处理，保持全部已发布EVAL字段。
                F_UNKNOWN:if(eval_rsp_valid&&eval_rsp_ready)state<=F_ISOLATED;
                F_ISOLATED:begin end
                default:fail_unknown();
            endcase
        end
    end endgenerate
endmodule
