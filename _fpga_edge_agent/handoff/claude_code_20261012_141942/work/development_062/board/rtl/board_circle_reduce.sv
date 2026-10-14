// CF02/03：有限圆计算，复用父唯一 scalar；完整返回资格通过才收窄。
// command ID/op/data 自接受到 response 消费且 quiet 保持。冷复位之外不清序号。
module board_circle_reduce #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter bit SHARED_RETURN_WORDS=1'b0
)(
    input wire clk,rst,command_valid,output wire command_ready,
    input wire [2:0] command_op,input wire [175:0] command_id,input wire [319:0] command_data,
    output wire response_valid,input wire response_ready,
    output wire [2:0] response_op,output wire [175:0] response_id,
    output reg [95:0] value,output reg error,local_reject,drained,
    output wire quiet,output reg fault,
    output wire num_req_valid,input wire num_req_ready,output wire [621:0] num_req_body,
    input wire num_rsp_valid,output wire num_rsp_ready,input wire [584:0] num_rsp_body,
    input wire num_quiet,output wire [4:0] num_rsp_word_index,input wire [15:0] num_rsp_word16
);
    import scalar_protocol_pkg::*;
    localparam IDLE=0,CHECK=1,PLAN=2,A_READ=3,A_CAPTURE=4,B_READ=5,B_CAPTURE=6,
        NUM_REQUEST=7,NUM_WAIT=8,NUM_SCAN=9,REG_WRITE=10,NUM_CONSUME=11,
        NUM_CLOSE=12,RESULT=13,UNKNOWN_RESULT=14,ISOLATED=15,LOCAL_CLOSE=16;
    reg [4:0] state,pc,scan_word;
    reg [2:0] word;
    reg [63:0] closed_sequence;
    reg exhausted,scan_bad,stop_numeric;
    reg [15:0] register_valid;
    reg [127:0] operand_a,operand_b;
    reg [35:0] metric_square;
    wire [175:0] numeric_id={8'hc2,closed_sequence,8'd0,command_id[95:0]};
    assign response_id=command_id;
    assign response_op=command_op;
    assign quiet=!rst && state==IDLE && num_quiet;
    assign command_ready=quiet && !exhausted;
    assign response_valid=!rst && (state==RESULT || state==UNKNOWN_RESULT);

    wire [20:0] command_count=command_op==0 ? command_data[59:39] : command_data[20:0];
    wire signed [10:0] metric_gx=command_data[48:38],metric_gy=command_data[59:49];
    reg format_bad;
    always @*begin
        format_bad=command_id[103:96]!=0 || WIDTH<6 || WIDTH>1920 || WIDTH%2!=0 || HEIGHT<5 || HEIGHT>1080;
        case(command_op)
            0:format_bad=format_bad || command_data[319:60]!=0 || command_count>WIDTH*HEIGHT;
            1:format_bad=format_bad || command_data[319:78]!=0 ||
                metric_gx < -11'sd1020 || metric_gx>11'sd1020 || metric_gy < -11'sd1020 || metric_gy>11'sd1020;
            2:format_bad=format_bad || command_data[319:42]!=0 ||
                command_data[20:0]>command_data[41:21] || command_data[41:21]>WIDTH*HEIGHT;
            3:format_bad=format_bad || command_data[319:263]!=0 || command_count>WIDTH*HEIGHT;
            4:format_bad=format_bad || command_data[319:171]!=0 ||
                command_data[20:0]>command_data[41:21] || command_data[41:21]>WIDTH*HEIGHT ||
                command_data[101:95]>7'd64 || command_data[122:102]==0 || command_data[122:102]>WIDTH*HEIGHT;
            default:format_bad=1;
        endcase
    end

    reg [2:0] opcode;
    reg [5:0] source_a,source_b;
    reg [3:0] destination;
    reg a_signed,b_signed,stored_signed;
    reg [7:0] stored_bits;
    reg [4:0] final_pc;
    always @*begin
        opcode=0;source_a=16;source_b=16;destination=0;
        a_signed=0;b_signed=0;stored_signed=0;stored_bits=1;final_pc=0;
        case(command_op)
            0:begin opcode=3;source_a=16;source_b=17;stored_bits=18;end
            1:begin
                final_pc=3;
                case(pc)
                    0:begin source_a=16;source_b=16;destination=0;stored_bits=36;end
                    1:begin source_a=17;source_b=18;destination=1;a_signed=1;b_signed=1;stored_signed=1;stored_bits=30;end
                    2:begin source_a=19;source_b=20;destination=2;a_signed=1;b_signed=1;stored_signed=1;stored_bits=30;end
                    3:begin opcode=1;source_a=1;source_b=2;destination=3;a_signed=1;b_signed=1;stored_signed=1;stored_bits=31;end
                    default:begin end
                endcase
            end
            2:begin
                final_pc=1;
                if(pc==0)begin source_a=16;source_b=30;stored_bits=37;end
                else begin opcode=3;source_a=0;source_b=17;destination=1;stored_bits=17;end
            end
            3:begin
                final_pc=9;
                case(pc)
                    0:begin opcode=1;source_a=16;source_b=18;destination=0;stored_bits=44;end
                    1:begin source_a=16;source_b=18;destination=1;stored_bits=86;end
                    2:begin source_a=17;source_b=17;destination=2;a_signed=1;b_signed=1;stored_bits=88;end
                    3:begin opcode=2;source_a=1;source_b=2;destination=3;stored_signed=1;stored_bits=89;end
                    4:begin source_a=0;source_b=0;destination=4;stored_bits=88;end
                    5:begin source_a=3;source_b=31;destination=5;stored_bits=88;end
                    6:begin source_a=5;source_b=30;destination=6;stored_bits=104;end
                    7:begin source_a=4;source_b=32;destination=7;stored_bits=93;end
                    8:begin opcode=5;source_a=6;source_b=7;destination=8;stored_bits=2;end
                    9:begin opcode=3;source_a=6;source_b=4;destination=9;stored_bits=17;end
                    default:begin end
                endcase
            end
            4:begin
                final_pc=7;
                case(pc)
                    0:begin source_a=16;source_b=30;destination=0;stored_bits=37;end
                    1:begin source_a=17;source_b=21;destination=1;stored_bits=37;end
                    2:begin opcode=5;source_a=0;source_b=1;destination=2;stored_bits=2;end
                    3:begin source_a=19;source_b=30;destination=3;stored_bits=23;end
                    4:begin source_a=22;source_b=33;destination=4;stored_bits=23;end
                    5:begin opcode=5;source_a=3;source_b=4;destination=5;stored_bits=2;end
                    6:begin source_a=23;source_b=16;destination=6;stored_bits=37;end
                    7:begin opcode=5;source_a=18;source_b=6;destination=7;stored_bits=2;end
                    default:begin end
                endcase
            end
            default:begin end
        endcase
    end
    function automatic [127:0] constant_source(input reg [5:0] source);
        begin
            constant_source=0;
            case(source)
                30:constant_source=128'd65535;
                31:constant_source=128'd4;
                32:constant_source=128'd16;
                33:constant_source=128'd64;
                default:case(command_op)
                    0:case(source)
                        16:constant_source={89'd0,command_data[38:0]};
                        17:constant_source={107'd0,command_data[59:39]};
                        default:begin end
                    endcase
                    1:case(source)
                        16:constant_source={110'd0,command_data[77:60]};
                        17:constant_source={{117{command_data[48]}},command_data[48:38]};
                        18:constant_source={{109{command_data[18]}},command_data[18:0]};
                        19:constant_source={{117{command_data[59]}},command_data[59:49]};
                        20:constant_source={{109{command_data[37]}},command_data[37:19]};
                        default:begin end
                    endcase
                    2:case(source)
                        16:constant_source={107'd0,command_data[20:0]};
                        17:constant_source={107'd0,command_data[41:21]};
                        default:begin end
                    endcase
                    3:case(source)
                        16:constant_source={85'd0,command_data[63:21]};
                        17:constant_source={{84{command_data[107]}},command_data[107:64]};
                        18:constant_source={85'd0,command_data[150:108]};
                        default:begin end
                    endcase
                    4:case(source)
                        16:constant_source={107'd0,command_data[20:0]};
                        17:constant_source={107'd0,command_data[41:21]};
                        18:constant_source={75'd0,command_data[94:42]};
                        19:constant_source={121'd0,command_data[101:95]};
                        21:constant_source={112'd0,command_data[138:123]};
                        22:constant_source={112'd0,command_data[154:139]};
                        23:constant_source={112'd0,command_data[170:155]};
                        default:begin end
                    endcase
                    default:begin end
                endcase
            endcase
        end
    endfunction
    wire [5:0] operand_source=(state==B_READ || state==B_CAPTURE) ? source_b : source_a;
    wire [127:0] operand_constant=constant_source(operand_source);
    wire [8:0] requested_target=opcode==5 ? 9'd2 : 9'd192;
    assign num_req_body={16'd0,{{64{b_signed && operand_b[127]}},operand_b},
        {{64{a_signed && operand_a[127]}},operand_a},requested_target,b_signed,a_signed,
        2'd0,opcode,8'd1,11'(HEIGHT),11'(WIDTH),numeric_id};
    assign num_req_valid=!rst && state==NUM_REQUEST && !exhausted;
    wire response_owned=num_rsp_body[175:0]==numeric_id;
    assign num_rsp_ready=!rst && state==NUM_CONSUME && response_owned;
    wire response_header_ok=num_rsp_body[180:176]=={2'd0,opcode} && num_rsp_body[189:181]==requested_target;
    wire response_success=num_rsp_body[199:190]==0;
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
    task automatic fail_known;
        begin error<=1;fault<=1;value<=0;stop_numeric<=1;state<=NUM_CONSUME;end
    endtask
    task automatic fail_unknown;
        begin error<=1;fault<=1;value<=0;drained<=0;state<=UNKNOWN_RESULT;end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;pc<=0;scan_word<=0;word<=0;closed_sequence<=0;exhausted<=0;
            scan_bad<=0;stop_numeric<=0;register_valid<=0;metric_square<=0;
            value<=0;error<=0;local_reject<=0;drained<=0;fault<=0;
        end else case(state)
            IDLE:if(command_valid && command_ready)begin
                pc<=0;word<=0;scan_word<=0;register_valid<=0;stop_numeric<=0;
                value<=0;error<=0;local_reject<=0;drained<=0;metric_square<=0;state<=CHECK;
            end
            CHECK:begin
                if(format_bad)begin error<=1;fault<=1;state<=LOCAL_CLOSE;end
                else if((command_op==0 && command_count==0) || (command_op==2 && command_data[41:21]==0) ||
                    (command_op==3 && command_count<3))begin local_reject<=1;state<=LOCAL_CLOSE;end
                else if(command_op==4 && (command_data[41:21]==0 || command_data[20:0]<command_data[122:102]))
                    state<=LOCAL_CLOSE;
                else state<=PLAN;
            end
            PLAN:begin
                word<=0;stop_numeric<=0;
                if(pc>final_pc || (source_a<16 && !register_valid[source_a[3:0]]) ||
                    (source_b<16 && !register_valid[source_b[3:0]]))begin error<=1;fault<=1;value<=0;state<=LOCAL_CLOSE;end
                else state<=A_READ;
            end
            A_READ:state<=A_CAPTURE;
            A_CAPTURE:if(source_a>=16)begin operand_a<=operand_constant;word<=0;state<=B_READ;end
                else begin operand_a<={work_q,operand_a[127:16]};
                    if(word==7)begin word<=0;state<=B_READ;end else begin word<=word+3'd1;state<=A_READ;end end
            B_READ:state<=B_CAPTURE;
            B_CAPTURE:if(source_b>=16)begin operand_b<=operand_constant;state<=NUM_REQUEST;end
                else begin operand_b<={work_q,operand_b[127:16]};
                    if(word==7)state<=NUM_REQUEST;else begin word<=word+3'd1;state<=B_READ;end end
            NUM_REQUEST:if(exhausted)begin error<=1;fault<=1;value<=0;state<=LOCAL_CLOSE;end
                else if(num_req_valid && num_req_ready)state<=NUM_WAIT;
            NUM_WAIT:if(num_rsp_valid)begin
                if(!response_owned)fail_unknown();
                else if(!response_header_ok || !response_success)fail_known();
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
                    case(command_op)
                        0:begin
                            if(num_rsp_body[217:200]==0 || num_rsp_body[217])begin local_reject<=1;value<=0;end
                            else value<={79'd0,num_rsp_body[216:200]};
                        end
                        1:begin
                            if(pc==0)metric_square<=num_rsp_body[235:200];
                            if(pc==3)value<={58'd0,(num_rsp_body[230:200]==0 ? 2'd0 : num_rsp_body[230] ? 2'd2 : 2'd1),metric_square};
                        end
                        2:if(pc==1)begin
                            if(num_rsp_body[216])begin error<=1;fault<=1;value<=0;end
                            else value<={80'd0,num_rsp_body[215:200]};
                        end
                        3:begin
                            if((pc==0 && num_rsp_body[243:200]==0) ||
                                (pc==3 && (num_rsp_body[584] || num_rsp_body[288:200]==0)) ||
                                (pc==8 && num_rsp_body[201:200]==2'd1))begin
                                local_reject<=1;value<=0;stop_numeric<=1;
                            end
                            if(pc==9)begin
                                if(num_rsp_body[216])begin error<=1;fault<=1;value<=0;end
                                else value<={58'd0,1'b1,num_rsp_body[215:200],command_data[20:0]};
                            end
                        end
                        4:begin
                            if((pc==2 || pc==5) && num_rsp_body[201:200]==2'd1)begin value<=0;stop_numeric<=1;end
                            if(pc==7)value<=num_rsp_body[201:200]==2'd2 ? 96'd0 : 96'd1;
                        end
                        default:begin end
                    endcase
                    state<=NUM_CONSUME;
                end else word<=word+3'd1;
            end
            NUM_CONSUME:if(num_rsp_valid)begin
                if(!response_owned)fail_unknown();else if(num_rsp_ready)state<=NUM_CLOSE;
            end
            NUM_CLOSE:if(num_quiet)begin
                if(&closed_sequence)begin exhausted<=1;fault<=1;end else closed_sequence<=closed_sequence+64'd1;
                if(stop_numeric || pc==final_pc)begin drained<=1;state<=RESULT;end
                else begin pc<=pc+5'd1;state<=PLAN;end
            end
            LOCAL_CLOSE:if(num_quiet)begin drained<=1;state<=RESULT;end
            RESULT:if(response_valid && response_ready)state<=IDLE;
            UNKNOWN_RESULT:if(response_valid && response_ready)state<=ISOLATED;
            ISOLATED:begin end
            default:begin error<=1;fault<=1;value<=0;drained<=0;state<=ISOLATED;end
        endcase
    end
endmodule
