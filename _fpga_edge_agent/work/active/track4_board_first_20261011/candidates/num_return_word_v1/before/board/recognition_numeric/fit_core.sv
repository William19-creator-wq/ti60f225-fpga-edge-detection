// FIT v1 B–H：七类复合运算，只有一份私有算术核；步骤号对应中文顺序表。
module fit_core #(parameter bit BORROW_PAYLOAD=0,parameter bit LS_TLS_ONLY=0,
                  parameter bit SERIAL_LOCAL_MOVES=0,parameter bit EXTERNAL_SCALAR=0,
                  parameter bit ROM_SCALAR=0,parameter string PROGRAM_FILE="board/recognition_numeric/fit_program.mem",
                  parameter bit WORD_SLOTS=0,parameter bit DSP_OPERAND_RESULT=0)(
    input logic clk,rst,
    input logic req_valid,input logic [621:0] req_body,output logic req_ready,
    output logic rsp_valid,output logic [584:0] rsp_body,input logic rsp_ready,
    input logic cancel_valid,input logic [175:0] cancel_id,output logic quiet,
    output wire shared_req_valid,output wire [621:0] shared_req_body,input wire shared_req_ready,
    input wire shared_rsp_valid,input wire [584:0] shared_rsp_body,output wire shared_rsp_ready,
    output wire shared_cancel_valid,output wire [175:0] shared_cancel_id,input wire shared_quiet
);
    import fit_protocol_pkg::*;
    localparam bit USE_WORD_SLOTS=WORD_SLOTS&&SERIAL_LOCAL_MOVES;
    typedef enum logic [4:0] {IDLE,CHECK,PREPARE,READ_A,LOAD_A,READ_B,LOAD_B,ISSUE,WAIT_RETURN,SCAN_RETURN,QUALIFY_RETURN,
                              ADVANCE,SCAN_LOCAL,LOCAL_COMMIT,DRAIN,PACK,HELD,FETCH_MICRO,SAVE_RETURN,SAVE_LOCAL} fit_state_t;
    fit_state_t state;
    logic [221:0] held_header;
    wire [399:0] held_payload;
    wire [621:0] held_request={held_payload,held_header};
    generate if(BORROW_PAYLOAD)begin:borrowed_input
        // 板级STATS保持同一正文，直到FIT终态真实消费且quiet以后才关闭统计。
        assign held_payload=req_body[621:222];
    end else begin:copied_input
        logic [399:0] snapshot;
        assign held_payload=snapshot;
        always_ff @(posedge clk)if(rst)snapshot<=0;
            else if(req_valid&&req_ready)snapshot<=req_body[621:222];
    end endgenerate
    // 标量命令全部关闭后才发布最终回复，384位操作数和完整385位结果复用一份暂存。
    // 有效位隔离未初始化/旧正文；DRAIN与成功终态均在发布前定义完整385位。
    logic [384:0] scalar_or_final_value;
    wire [384:0] response_value=scalar_or_final_value;
    logic [1:0] response_outcome;
    logic [7:0] response_reason;
    // TS02：逻辑192读口由唯一的定宽物理槽展开。
    wire [191:0] work_slot[0:15];
    logic [15:0] slot_zero,slot_geometry_ok,slot_normal_ok;
    logic [15:0] slot_u16_ok,slot_k_min_ok;
    wire [191:0] slot_read_value;
    wire [15:0] slot_word_q;
    logic [3:0] operand_word;
    logic slot_saved;
    logic [15:0] slot_valid;
    logic anis_valid,mu_valid;
    logic [6:0] step,pending_next_step;
    logic [3:0] subphase,pending_next_phase;
    logic negative_branch,outer_cancel,command_published,cmd_pending;
    logic [21:0] command_header;
    wire [405:0] published_command={scalar_or_final_value[383:0],command_header};
    logic [3:0] reserved_destination;
    logic [7:0] reserved_width;
    logic reserved_signed,return_signed;
    logic [63:0] cache_key[0:3];
    logic [64:0] cache_k[0:3];
    logic [32:0] cache_m[0:3];
    logic [3:0] cache_valid;
    logic [1:0] replacement;

    logic bridge_ready,bridge_valid,bridge_quiet,bridge_result_ready;
    logic [402:0] bridge_result;
    logic child_req_valid,child_req_ready,child_rsp_valid,child_rsp_ready,child_quiet;
    logic [621:0] child_req_body;
    logic [584:0] child_rsp_body;
    logic child_cancel_valid;
    logic [175:0] child_cancel_id;
    logic matching_cancel,cmd_fire,result_fire;
    logic [9:0] input_check;
    // 板级全点统计仅发布11/12。常量选择让综合删除未调用的几何分支，
    // 原始kind先独立核查，不能把其它消息改写成11/12后执行。
    wire [4:0] kind=LS_TLS_ONLY?(held_request[KIND_LO]?5'd11:5'd12):held_request[KIND_LO+:5];
    wire [621:0] checked_request={held_request[621:211],kind,held_request[205:0]};
    logic [399:0] payload;

    // 组合计划只读旧槽；PREPARE锁命令，返回提交后ADVANCE才允许读取新槽。
    logic [1:0] plan_class; // 0私有调用，1局部提交，2完成，3拒绝
    logic [405:0] plan_command;
    logic [5:0] plan_a_source,plan_b_source;
    logic [5:0] held_a_source,held_b_source;
    logic local_shared,plan_local_shared;
    logic local_negative,plan_local_negative;
    logic [5:0] held_local_shift,plan_local_shift,plan_local_source;
    wire [191:0] local_scale_factor;
    // shift为0..63；-2^shift从该位起全1，正2^shift仅该位为1，保留完整192位。
    for(genvar factor_bit=0;factor_bit<192;factor_bit++)begin:g_local_factor
        if(factor_bit<64)begin:low_bits
            assign local_scale_factor[factor_bit]=local_negative?
                (held_local_shift<=6'(factor_bit)):(held_local_shift==6'(factor_bit));
        end else begin:high_bits
            assign local_scale_factor[factor_bit]=local_negative;
        end
    end
    logic [191:0] plan_local;
    logic [3:0] plan_destination;
    logic [7:0] plan_width;
    logic plan_signed,plan_return_signed;
    logic [15:0] required_slots;
    logic [6:0] next_step;
    logic [3:0] next_phase;
    logic [1:0] plan_outcome;
    logic [7:0] plan_reason;
    logic [384:0] plan_value;
    logic cache_hit;
    logic [1:0] hit_index;
    logic [63:0] normal_key;
    logic [63:0] install_key;
    logic install_hit;
    integer i;

    // OS02：内部来源码；分支只选来源，两个共用192位读口恢复完整命令。
    localparam logic [5:0] SRC_ZERO=6'd0;
    localparam logic [5:0] SRC_SLOT0=6'd1;
    localparam logic [5:0] SRC_SLOT1=6'd2;
    localparam logic [5:0] SRC_SLOT2=6'd3;
    localparam logic [5:0] SRC_SLOT3=6'd4;
    localparam logic [5:0] SRC_SLOT4=6'd5;
    localparam logic [5:0] SRC_SLOT5=6'd6;
    localparam logic [5:0] SRC_SLOT6=6'd7;
    localparam logic [5:0] SRC_SLOT7=6'd8;
    localparam logic [5:0] SRC_SLOT8=6'd9;
    localparam logic [5:0] SRC_SLOT9=6'd10;
    localparam logic [5:0] SRC_SLOT10=6'd11;
    localparam logic [5:0] SRC_SLOT11=6'd12;
    localparam logic [5:0] SRC_SLOT12=6'd13;
    localparam logic [5:0] SRC_SLOT13=6'd14;
    localparam logic [5:0] SRC_SLOT14=6'd15;
    localparam logic [5:0] SRC_SLOT15=6'd16;
    localparam logic [5:0] SRC_CONST65535=6'd17;
    localparam logic [5:0] SRC_P21_U43=6'd18;
    localparam logic [5:0] SRC_P108_U43=6'd19;
    localparam logic [5:0] SRC_P64_S44=6'd20;
    localparam logic [5:0] SRC_P263_U16=6'd21;
    localparam logic [5:0] SRC_P151_S56=6'd22;
    localparam logic [5:0] SRC_P207_S56=6'd23;
    localparam logic [5:0] SRC_P0_U21=6'd24;
    localparam logic [5:0] SRC_P87_U43=6'd25;
    localparam logic [5:0] SRC_P21_S33=6'd26;
    localparam logic [5:0] SRC_P130_U43=6'd27;
    localparam logic [5:0] SRC_P54_S33=6'd28;
    localparam logic [5:0] SRC_P173_S44=6'd29;
    localparam logic [5:0] SRC_P217_U16=6'd30;
    localparam logic [5:0] SRC_WIDTH_LAST=6'd31;
    localparam logic [5:0] SRC_HEIGHT_LAST=6'd32;
    localparam logic [5:0] SRC_P0_S32=6'd33;
    localparam logic [5:0] SRC_P32_S32=6'd34;
    localparam logic [5:0] SRC_P82_S32=6'd35;
    localparam logic [5:0] SRC_P114_S32=6'd36;
    localparam logic [5:0] SRC_P64_S18=6'd37;
    localparam logic [5:0] SRC_P146_S18=6'd38;
    localparam logic [5:0] SRC_P82_U11=6'd39;
    localparam logic [5:0] SRC_P93_U11=6'd40;
    localparam logic [5:0] SRC_P72_U11_SHIFT4=6'd41;
    localparam logic [5:0] SRC_P0_S18=6'd42;
    localparam logic [5:0] SRC_P83_U11_SHIFT4=6'd43;
    localparam logic [5:0] SRC_P18_S18=6'd44;
    localparam logic [5:0] SRC_P36_S18=6'd45;
    localparam logic [5:0] SRC_P54_S18=6'd46;
    localparam logic [5:0] SRC_LOCAL_FACTOR=6'd47;

    function automatic [191:0] pf(input logic [399:0] p,input integer low,input integer bits,input logic signed_field);
        logic [399:0] shifted;
        begin shifted=p>>low; pf=extend_field(shifted[191:0],bits,signed_field); end
    endfunction

    function automatic integer slot_maximum_bits(input logic [3:0] destination);
        begin
            case(destination)
                0:slot_maximum_bits=67; 1:slot_maximum_bits=89; 2:slot_maximum_bits=88; 3:slot_maximum_bits=104;
                4:slot_maximum_bits=102; 5:slot_maximum_bits=133; 6:slot_maximum_bits=105; 7:slot_maximum_bits=165;
                8:slot_maximum_bits=132; 9:slot_maximum_bits=106; 10:slot_maximum_bits=37; 11:slot_maximum_bits=32;
                12:slot_maximum_bits=171; 13,14:slot_maximum_bits=170; 15:slot_maximum_bits=104;
                default:slot_maximum_bits=192;
            endcase
        end
    endfunction
    // 只保留计划实际直接读取的字段；全部算术操作数、复制/移位仍取完整192位RAM。
    function automatic integer metadata_bits(input logic [3:0] destination);
        case(destination)
            0:metadata_bits=65;1:metadata_bits=33;2:metadata_bits=1;3:metadata_bits=21;
            4,5:metadata_bits=39;6:metadata_bits=1;7:metadata_bits=78;8:metadata_bits=39;
            9:metadata_bits=18;10,11:metadata_bits=32;12:metadata_bits=65;13:metadata_bits=33;
            14:metadata_bits=18;15:metadata_bits=34;default:metadata_bits=1;
        endcase
    endfunction
    // 逻辑槽仍为192位。下表涵盖该槽每个已批准typed写入，显式共享冗余高位。
    function automatic [191:0] canonical_slot(input logic [191:0] value,input logic [3:0] destination);
        integer bits;
        logic [191:0] mask;
        begin
            bits=slot_maximum_bits(destination);
            mask=(192'b1<<bits)-1;
            canonical_slot=(value & mask) | (value[191]?~mask:192'd0);
        end
    endfunction
    // q由完整返回资格保证u21。先扩22位保留进位，再形成完整192位候选。
    // 下边界只用于q>0；q=0仍由原调度分支跳过。
    function automatic [191:0] line_odd_boundary(input logic [20:0] q,input logic upper);
        logic [21:0] odd;
        begin
            odd=upper?({q,1'b0}+22'd1):({q,1'b0}-22'd1);
            line_odd_boundary={170'd0,odd};
        end
    endfunction
    function automatic [191:0] line_neighbor(input logic [20:0] q,input logic increment);
        logic [21:0] adjacent;
        begin
            adjacent=increment?({1'b0,q}+22'd1):({1'b0,q}-22'd1);
            line_neighbor={170'd0,adjacent};
        end
    endfunction
    function automatic [191:0] finite_odd_boundary(input logic [18:0] q,input logic upper);
        logic [19:0] odd;
        begin
            odd=upper?({q,1'b0}+20'd1):({q,1'b0}-20'd1);
            finite_odd_boundary={172'd0,odd};
        end
    endfunction

    // FR02：槽已canonical；N+2先容纳最负值的正幅度，最后再扩成完整192位。
    function automatic [191:0] local_negate(input logic [3:0] slot,input logic [191:0] value);
        begin
            case(slot)
                0:begin
                    logic signed [68:0] expanded,negative;
                    expanded=$signed({{2{value[191]}},value[66:0]});
                    negative=-expanded;
                    local_negate={{123{negative[68]}},negative};
                end
                1:begin
                    logic signed [90:0] expanded,negative;
                    expanded=$signed({{2{value[191]}},value[88:0]});
                    negative=-expanded;
                    local_negate={{101{negative[90]}},negative};
                end
                2:begin
                    logic signed [89:0] expanded,negative;
                    expanded=$signed({{2{value[191]}},value[87:0]});
                    negative=-expanded;
                    local_negate={{102{negative[89]}},negative};
                end
                8:begin
                    logic signed [133:0] expanded,negative;
                    expanded=$signed({{2{value[191]}},value[131:0]});
                    negative=-expanded;
                    local_negate={{58{negative[133]}},negative};
                end
                10:begin
                    logic signed [38:0] expanded,negative;
                    expanded=$signed({{2{value[191]}},value[36:0]});
                    negative=-expanded;
                    local_negate={{153{negative[38]}},negative};
                end
                11:begin
                    logic signed [33:0] expanded,negative;
                    expanded=$signed({{2{value[191]}},value[31:0]});
                    negative=-expanded;
                    local_negate={{158{negative[33]}},negative};
                end
                default:local_negate=-value;
            endcase
        end
    endfunction
    // FR02：v0的完整192减一位模式也保留为all-ones，公共COORD检查仍原样。
    function automatic [191:0] coordinate_last(input logic [10:0] value);
        logic signed [11:0] expanded,last;
        begin
            expanded=$signed({1'b0,value});last=expanded-12'sd1;
            coordinate_last={{180{last[11]}},last};
        end
    endfunction

    // E2：纯组合、完整默认；S/U只描述原pf字段，不窄化192位结果。
    function automatic logic [191:0] operand_source(input logic [5:0] selector);
        begin
            case(selector)
                SRC_ZERO:operand_source=192'd0;
                SRC_CONST65535:operand_source=192'd65535;
                SRC_P21_U43:operand_source=pf(payload,21,43,0);
                SRC_P108_U43:operand_source=pf(payload,108,43,0);
                SRC_P64_S44:operand_source=pf(payload,64,44,1);
                SRC_P263_U16:operand_source=pf(payload,263,16,0);
                SRC_P151_S56:operand_source=pf(payload,151,56,1);
                SRC_P207_S56:operand_source=pf(payload,207,56,1);
                SRC_P0_U21:operand_source=pf(payload,0,21,0);
                SRC_P87_U43:operand_source=pf(payload,87,43,0);
                SRC_P21_S33:operand_source=pf(payload,21,33,1);
                SRC_P130_U43:operand_source=pf(payload,130,43,0);
                SRC_P54_S33:operand_source=pf(payload,54,33,1);
                SRC_P173_S44:operand_source=pf(payload,173,44,1);
                SRC_P217_U16:operand_source=pf(payload,217,16,0);
                SRC_WIDTH_LAST:operand_source=coordinate_last(held_request[W_LO+:11]);
                SRC_HEIGHT_LAST:operand_source=coordinate_last(held_request[H_LO+:11]);
                SRC_P0_S32:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,0,32,1));
                SRC_P32_S32:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,32,32,1));
                SRC_P82_S32:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,82,32,1));
                SRC_P114_S32:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,114,32,1));
                SRC_P64_S18:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,64,18,1));
                SRC_P146_S18:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,146,18,1));
                SRC_P82_U11:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,82,11,0));
                SRC_P93_U11:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,93,11,0));
                SRC_P72_U11_SHIFT4:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,72,11,0)<<4);
                SRC_P0_S18:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,0,18,1));
                SRC_P83_U11_SHIFT4:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,83,11,0)<<4);
                SRC_P18_S18:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,18,18,1));
                SRC_P36_S18:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,36,18,1));
                SRC_P54_S18:operand_source=LS_TLS_ONLY?192'd0:(pf(payload,54,18,1));
                SRC_LOCAL_FACTOR:operand_source=local_scale_factor;
                default:operand_source=192'd0;
            endcase
        end
    endfunction

    // 固定数值指令放同步ROM；分支、前置槽检查和完整返回资格仍由原调度执行。
    logic plan_micro_valid;
    logic [7:0] plan_micro_index;
    logic [36:0] micro_program[0:255],micro_q;
    initial if(ROM_SCALAR)$readmemh(PROGRAM_FILE,micro_program);
    always_ff @(posedge clk)if(ROM_SCALAR)micro_q<=micro_program[plan_micro_index];
    task automatic rom_scalar(input logic [7:0] index);
        begin plan_class=0;plan_micro_valid=1;plan_micro_index=index;end
    endtask
    task automatic rom_local(input logic [7:0] index,input logic negative);
        begin plan_class=1;plan_local_shared=1;plan_micro_valid=1;plan_micro_index=index;
            plan_local_negative=negative;end
    endtask

    task automatic need(input logic [15:0] mask);
        required_slots=required_slots | mask;
    endtask
    task automatic call_scalar(input logic [2:0] op,input logic sa,sb,
        input integer bits,destination,input logic stored_signed,
        input logic [5:0] a_source,b_source);
        begin
            plan_class=0; plan_destination=destination[3:0]; plan_width=bits[7:0];
            plan_signed=stored_signed;
            plan_return_signed=(op==2 || ((op==0 || op==1) && (sa || sb)) || (op==3 && sa));
            plan_a_source=a_source; plan_b_source=b_source;
            plan_command[21:0]={bits[8:0],sb,sa,op,4'd0,destination[3:0]};
        end
    endtask
    task automatic local_write(input integer destination,bits,input logic signed_field,
                                input logic [191:0] value);
        begin
            plan_class=1; plan_destination=destination[3:0]; plan_width=bits[7:0];
            plan_signed=signed_field; plan_local=value;plan_local_shared=0;
            plan_local_negative=0;
        end
    endtask
    task automatic local_move(input integer destination,bits,input logic signed_field,
                              input logic [5:0] source,shift);
        begin
            plan_class=1;plan_destination=destination[3:0];plan_width=bits[7:0];plan_signed=signed_field;
            plan_local_shared=1;plan_local_source=source;plan_local_shift=shift;plan_local=0;
            plan_local_negative=0;
        end
    endtask
    task automatic local_signed_move(input integer destination,bits,input logic signed_field,
                                     input logic [5:0] source,input logic negate_value);
        begin
            local_move(destination,bits,signed_field,source,0);
            plan_local_negative=negate_value;
        end
    endtask
    task automatic reject(input logic [1:0] outcome,input logic [7:0] reason);
        begin plan_class=3; plan_outcome=outcome; plan_reason=reason; end
    endtask
    task automatic geometry(input integer destination,input logic [5:0] source);
        begin
            local_move(destination,18,1,source,0);
            if(!slot_geometry_ok[source-6'd1]) reject(LOCAL_REJECT,GEOM_RANGE);
        end
    endtask

    scalar_bridge #(.BORROW_COMMAND(1'b1),.BORROW_RESULT(1'b1),.CLOSE_SEQUENCE(1'b1)) private_bridge(
        .clk(clk),.rst(rst),.cmd_valid(command_published),.cmd_body(published_command),.cmd_ready(bridge_ready),
        .result_valid(bridge_valid),.result_body(bridge_result),.result_ready(bridge_result_ready),
        .abort(state==DRAIN || matching_cancel || outer_cancel),.bridge_quiet(bridge_quiet),
        .child_req_valid(child_req_valid),.child_req_body(child_req_body),.child_req_ready(child_req_ready),
        .child_rsp_valid(child_rsp_valid),.child_rsp_body(child_rsp_body),.child_rsp_ready(child_rsp_ready),
        .child_cancel_valid(child_cancel_valid),.child_cancel_id(child_cancel_id),.child_quiet(child_quiet)
    );
    generate if(EXTERNAL_SCALAR)begin:shared_arithmetic_port
        // 父级仅在FIT完全quiet且借用结果已经归还后切换阶段，不能仅按child rsp_fire切换。
        assign shared_req_valid=child_req_valid;assign shared_req_body=child_req_body;
        assign child_req_ready=shared_req_ready;
        assign child_rsp_valid=shared_rsp_valid;assign child_rsp_body=shared_rsp_body;
        assign shared_rsp_ready=child_rsp_ready;
        assign shared_cancel_valid=child_cancel_valid;assign shared_cancel_id=child_cancel_id;
        assign child_quiet=shared_quiet;
    end else begin:private_arithmetic_port
        assign shared_req_valid=0;assign shared_req_body=0;assign shared_rsp_ready=0;
        assign shared_cancel_valid=0;assign shared_cancel_id=0;
        scalar_core_words #(.BORROW_PAYLOAD(1'b1)) private_arithmetic(
        .clk(clk),.rst(rst),.req_valid(child_req_valid),.req_body(child_req_body),.req_ready(child_req_ready),
        .rsp_valid(child_rsp_valid),.rsp_body(child_rsp_body),.rsp_ready(child_rsp_ready),
        .cancel_valid(child_cancel_valid),.cancel_id(child_cancel_id),.quiet(child_quiet)
        );
    end endgenerate

    always_comb begin
        payload=held_request[PAYLOAD_LO+:400];
        req_ready=!rst && state==IDLE && !command_published && !cmd_pending && bridge_quiet;
        quiet=req_ready; rsp_valid=!rst && state==HELD;
        rsp_body=pack_response(held_request,response_outcome,response_reason,response_value);
        matching_cancel=cancel_valid && ((state==IDLE && req_valid && req_ready && cancel_id==req_body[175:0]) ||
            (state!=IDLE && state!=HELD && cancel_id==held_request[175:0]));
        cmd_fire=command_published && bridge_ready;
        // 合格返回在12个物理字写齐前不归还借用正文；坏返回仍立即沿原路径关闭。
        bridge_result_ready=!rst && (state==DRAIN || (state==QUALIFY_RETURN &&
            (!USE_WORD_SLOTS || slot_saved || !scalar_slot_qualified)));
        result_fire=bridge_valid && bridge_result_ready;
        input_check=check_request(checked_request);
        if(LS_TLS_ONLY&&held_request[KIND_LO+:5]!=11&&held_request[KIND_LO+:5]!=12)
            input_check={UNSUPPORTED,FRAME_FAIL};
        normal_key=payload[63:0]; cache_hit=0; hit_index=0;
        install_key=kind==14?normal_key:{work_slot[11][31:0],work_slot[10][31:0]}; install_hit=0;
        for(integer c=0;c<4;c=c+1) begin
            if(cache_valid[c] && cache_key[c]==normal_key) begin cache_hit=1; hit_index=c[1:0]; end
            if(cache_valid[c] && cache_key[c]==install_key) install_hit=1;
        end
    end

    always_comb begin
        plan_class=3; plan_command=0; plan_local=0; plan_destination=0;
        plan_a_source=SRC_ZERO; plan_b_source=SRC_ZERO;
        plan_width=1; plan_signed=0; plan_return_signed=0; required_slots=0;
        plan_local_shared=0;plan_local_source=SRC_ZERO;plan_local_shift=0;
        plan_local_negative=0;plan_micro_valid=0;plan_micro_index=0;
        next_step=step+7'd1; next_phase=0;
        plan_outcome=FRAME_FAIL; plan_reason=INTERNAL; plan_value=0;
        case(kind)
            11,17:begin // L01…L21：圆LS；诊断L07后直接L20。
                case(step)
                    1:begin if(ROM_SCALAR) rom_scalar(8'd0); else call_scalar(1,0,0,44,0,0,SRC_P21_U43,SRC_P108_U43); end
                    2:begin if(ROM_SCALAR) rom_scalar(8'd1); else call_scalar(0,0,0,86,13,0,SRC_P21_U43,SRC_P108_U43); end
                    3:begin if(ROM_SCALAR) rom_scalar(8'd2); else call_scalar(0,1,1,88,14,0,SRC_P64_S44,SRC_P64_S44); end
                    4:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd3); else call_scalar(2,0,0,89,1,1,SRC_SLOT13,SRC_SLOT14); end end
                    5:begin
                        need(16'h0003); begin if(ROM_SCALAR) rom_scalar(8'd4); else call_scalar(0,0,0,88,2,0,SRC_SLOT0,SRC_SLOT0); end
                        if(work_slot[1][191]||slot_zero[1]) reject(LOCAL_REJECT,DEGENERATE);
                        else if(slot_zero[0]) reject(FRAME_FAIL,INTERNAL);
                    end
                    6:begin need(16'h0002); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd5,0); end else local_move(12,88,0,SRC_SLOT1,2); end end
                    7:begin need(16'h1000); begin if(ROM_SCALAR) rom_scalar(8'd6); else call_scalar(0,0,0,104,3,0,SRC_SLOT12,SRC_CONST65535); end if(kind==17) next_step=20; end
                    8:begin need(16'h0004); begin if(ROM_SCALAR) rom_scalar(8'd7); else call_scalar(0,0,0,104,15,0,SRC_P263_U16,SRC_SLOT2); end end
                    9:begin need(16'h8008); begin if(ROM_SCALAR) rom_scalar(8'd8); else call_scalar(5,0,0,2,11,0,SRC_SLOT3,SRC_SLOT15); end end
                    10:begin
                        need(16'h0800); begin if(ROM_SCALAR) rom_scalar(8'd9); else call_scalar(0,1,0,99,13,1,SRC_P151_S56,SRC_P108_U43); end
                        if(work_slot[11]==1) reject(LOCAL_REJECT,ILL_CONDITION);
                    end
                    11:begin if(ROM_SCALAR) rom_scalar(8'd10); else call_scalar(0,1,1,100,14,1,SRC_P64_S44,SRC_P207_S56); end
                    12:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd11); else call_scalar(2,1,1,101,4,1,SRC_SLOT13,SRC_SLOT14); end end
                    13:begin if(ROM_SCALAR) rom_scalar(8'd12); else call_scalar(0,0,1,99,13,1,SRC_P21_U43,SRC_P207_S56); end
                    14:begin if(ROM_SCALAR) rom_scalar(8'd13); else call_scalar(0,1,1,100,14,1,SRC_P64_S44,SRC_P151_S56); end
                    15:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd14); else call_scalar(2,1,1,101,5,1,SRC_SLOT13,SRC_SLOT14); end end
                    16:begin need(16'h0010); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd15,0); end else local_move(6,105,1,SRC_SLOT4,4); end end
                    17:begin need(16'h0020); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd16,0); end else local_move(7,105,1,SRC_SLOT5,4); end end
                    18:begin need(16'h0042); begin if(ROM_SCALAR) rom_scalar(8'd17); else call_scalar(3,1,0,106,8,1,SRC_SLOT6,SRC_SLOT1); end end
                    19:begin
                        need(16'h0182); begin if(ROM_SCALAR) rom_scalar(8'd18); else call_scalar(3,1,0,106,9,1,SRC_SLOT7,SRC_SLOT1); end
                        if(!slot_geometry_ok[8]) reject(LOCAL_REJECT,GEOM_RANGE);
                    end
                    20:begin
                        need(16'h000c); begin if(ROM_SCALAR) rom_scalar(8'd19); else call_scalar(3,0,0,17,10,0,SRC_SLOT3,SRC_SLOT2); end
                        if(kind==11) begin need(16'h0200); if(!slot_geometry_ok[9]) reject(LOCAL_REJECT,GEOM_RANGE); end
                    end
                    21:begin
                        need(16'h0400); plan_class=2;
                        if(!slot_u16_ok[10]) reject(FRAME_FAIL,INTERNAL);
                        if(kind==11) begin
                            need(16'h0300); plan_value[0+:18]=work_slot[8][17:0]; plan_value[18+:18]=work_slot[9][17:0];
                            plan_value[36+:21]=payload[20:0]; plan_value[57+:16]=work_slot[10][15:0];
                        end else begin plan_value[0+:21]=payload[20:0]; plan_value[21+:16]=work_slot[10][15:0]; end
                    end
                    default:reject(FRAME_FAIL,INTERNAL);
                endcase
            end
            12,18:begin // T01…T61：TLS。所有交换/反号/复合字段写分沿提交。
                case(step)
                    1:begin if(ROM_SCALAR) rom_scalar(8'd20); else call_scalar(0,0,0,64,13,0,SRC_P0_U21,SRC_P87_U43); end
                    2:begin if(ROM_SCALAR) rom_scalar(8'd21); else call_scalar(0,1,1,66,14,0,SRC_P21_S33,SRC_P21_S33); end
                    3:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd22); else call_scalar(2,0,0,67,0,1,SRC_SLOT13,SRC_SLOT14); end end
                    4:begin if(ROM_SCALAR) rom_scalar(8'd23); else call_scalar(0,0,0,64,13,0,SRC_P0_U21,SRC_P130_U43); end
                    5:begin if(ROM_SCALAR) rom_scalar(8'd24); else call_scalar(0,1,1,66,14,0,SRC_P54_S33,SRC_P54_S33); end
                    6:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd25); else call_scalar(2,0,0,67,1,1,SRC_SLOT13,SRC_SLOT14); end end
                    7:begin if(ROM_SCALAR) rom_scalar(8'd26); else call_scalar(0,0,1,65,13,1,SRC_P0_U21,SRC_P173_S44); end
                    8:begin if(ROM_SCALAR) rom_scalar(8'd27); else call_scalar(0,1,1,66,14,1,SRC_P21_S33,SRC_P54_S33); end
                    9:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd28); else call_scalar(2,1,1,67,2,1,SRC_SLOT13,SRC_SLOT14); end end
                    10:begin
                        need(16'h0003); local_move(subphase==0?0:1,64,0,subphase==0?SRC_SLOT0:SRC_SLOT1,0);
                        if(work_slot[0][191] || work_slot[1][191]) reject(FRAME_FAIL,INTERNAL);
                        if(subphase==0) begin next_step=10; next_phase=1; end
                    end
                    11:begin need(16'h0003); begin if(ROM_SCALAR) rom_scalar(8'd29); else call_scalar(0,0,0,128,13,0,SRC_SLOT0,SRC_SLOT1); end end
                    12:begin need(16'h0004); begin if(ROM_SCALAR) rom_scalar(8'd30); else call_scalar(0,1,1,134,14,0,SRC_SLOT2,SRC_SLOT2); end end
                    13:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd31); else call_scalar(5,0,0,2,12,0,SRC_SLOT13,SRC_SLOT14); end end
                    14:begin
                        need(16'h1007);
                        if(subphase==0) begin begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd32,0); end else local_move(2,65,1,SRC_SLOT2,0); end next_step=14; next_phase=1; end
                        else begin if(ROM_SCALAR) rom_scalar(8'd33); else call_scalar(1,0,0,65,13,0,SRC_SLOT0,SRC_SLOT1); end
                        if(work_slot[12]==1) reject(FRAME_FAIL,INTERNAL);
                    end
                    15:begin need(16'h2000); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd34,0); end else local_move(14,81,0,SRC_SLOT13,16); end if(slot_zero[13]) reject(LOCAL_REJECT,DEGENERATE); end
                    16:begin need(16'h0003); begin if(ROM_SCALAR) rom_scalar(8'd35); else call_scalar(2,0,0,65,3,1,SRC_SLOT0,SRC_SLOT1); end end
                    17:begin need(16'h0004); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd36,0); end else local_move(4,66,1,SRC_SLOT2,1); end end
                    18:begin need(16'h0008); begin if(ROM_SCALAR) rom_scalar(8'd37); else call_scalar(0,1,1,130,7,0,SRC_SLOT3,SRC_SLOT3); end end
                    19:begin need(16'h0010); begin if(ROM_SCALAR) rom_scalar(8'd38); else call_scalar(0,1,1,132,8,0,SRC_SLOT4,SRC_SLOT4); end end
                    20:begin need(16'h0180); begin if(ROM_SCALAR) rom_scalar(8'd39); else call_scalar(1,0,0,133,5,0,SRC_SLOT7,SRC_SLOT8); end end
                    21:begin need(16'h0020); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd40,0); end else local_move(7,165,0,SRC_SLOT5,32); end if(slot_zero[5]) reject(LOCAL_REJECT,DEGENERATE); end
                    22:begin need(16'h0080); begin if(ROM_SCALAR) rom_scalar(8'd41); else call_scalar(4,0,0,83,6,0,SRC_SLOT7,SRC_ZERO); end end
                    23:begin need(16'h0040); begin if(ROM_SCALAR) rom_scalar(8'd42); else call_scalar(0,0,0,99,7,0,SRC_SLOT6,SRC_CONST65535); end if(kind==18) next_step=26; end
                    24:begin need(16'h4000); begin if(ROM_SCALAR) rom_scalar(8'd43); else call_scalar(0,0,0,97,8,0,SRC_P217_U16,SRC_SLOT14); end end
                    25:begin need(16'h0180); begin if(ROM_SCALAR) rom_scalar(8'd44); else call_scalar(5,0,0,2,12,0,SRC_SLOT7,SRC_SLOT8); end end
                    26:begin
                        if(subphase==0) begin
                            need(16'h4080); begin if(ROM_SCALAR) rom_scalar(8'd45); else call_scalar(3,0,0,17,12,0,SRC_SLOT7,SRC_SLOT14); end
                            next_step=26; next_phase=1;
                            if(kind==12) begin need(16'h1000); if(work_slot[12]==1) reject(LOCAL_REJECT,ILL_CONDITION); end
                        end else begin
                            need(16'h1000); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd46,0); end else local_move(15,34,0,SRC_SLOT12,18); end
                            if(!slot_u16_ok[12]) reject(FRAME_FAIL,INTERNAL);
                            if(kind==18) next_step=61;
                        end
                    end
                    27:begin need(16'h0008); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd47,0); end else local_move(7,81,1,SRC_SLOT3,16); end end
                    28:begin need(16'h0010); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd48,0); end else local_move(8,82,1,SRC_SLOT4,16); end end
                    29:begin
                        need(16'h0048);
                        if(!work_slot[3][191]) begin if(ROM_SCALAR) rom_scalar(8'd49); else call_scalar(1,0,1,85,7,1,SRC_SLOT6,SRC_SLOT7); end
                        else begin if(ROM_SCALAR) rom_scalar(8'd50); else call_scalar(2,0,1,85,3,1,SRC_SLOT6,SRC_SLOT7); end
                    end
                    30:begin
                        if(!negative_branch) begin need(16'h0100); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd51,0); end else local_move(8,85,1,SRC_SLOT8,0); end end
                        else if(subphase==0) begin need(16'h0100); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd52,0); end else local_move(7,85,1,SRC_SLOT8,0); end next_step=30; next_phase=1; end
                        else begin need(16'h0008); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd53,0); end else local_move(8,85,1,SRC_SLOT3,0); end end
                    end
                    31:begin need(16'h0080); begin if(ROM_SCALAR) rom_scalar(8'd54); else call_scalar(0,1,1,170,13,0,SRC_SLOT7,SRC_SLOT7); end end
                    32:begin need(16'h0100); begin if(ROM_SCALAR) rom_scalar(8'd55); else call_scalar(0,1,1,170,14,0,SRC_SLOT8,SRC_SLOT8); end end
                    33:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd56); else call_scalar(1,0,0,171,12,0,SRC_SLOT13,SRC_SLOT14); end end
                    34:begin need(16'h1000); begin if(ROM_SCALAR) rom_scalar(8'd57); else call_scalar(4,0,0,86,9,0,SRC_SLOT12,SRC_ZERO); end end
                    35:begin need(16'h0280); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd58,0); end else local_move(13,115,1,SRC_SLOT7,30); end if(slot_zero[9]) reject(FRAME_FAIL,INTERNAL); end
                    36:begin need(16'h2200); begin if(ROM_SCALAR) rom_scalar(8'd59); else call_scalar(3,1,0,116,7,1,SRC_SLOT13,SRC_SLOT9); end end
                    37:begin need(16'h0180); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd60,0); end else local_move(14,115,1,SRC_SLOT8,30); end
                        if(!slot_normal_ok[7]) reject(FRAME_FAIL,INTERNAL); end
                    38:begin need(16'h4200); begin if(ROM_SCALAR) rom_scalar(8'd61); else call_scalar(3,1,0,116,8,1,SRC_SLOT14,SRC_SLOT9); end end
                    39:begin
                        need(16'h0180); local_signed_move(subphase==0?10:11,32,1,subphase==0?SRC_SLOT8:SRC_SLOT7,subphase==0);
                        if(!slot_normal_ok[8]) reject(FRAME_FAIL,INTERNAL);
                        if(subphase==0) begin next_step=39; next_phase=1; end
                    end
                    40:begin
                        need(16'h0c00);
                        if(subphase==0) begin
                            begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd62,work_slot[11][191]||(slot_zero[11]&&work_slot[10][191])); end else local_signed_move(10,32,1,SRC_SLOT10,work_slot[11][191]||(slot_zero[11]&&work_slot[10][191])); end
                            next_step=40; next_phase=1;
                        end else begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd63,negative_branch); end else local_signed_move(11,32,1,SRC_SLOT11,negative_branch); end
                    end
                    41:begin need(16'h0400); begin if(ROM_SCALAR) rom_scalar(8'd64); else call_scalar(0,1,1,65,13,1,SRC_SLOT10,SRC_P21_S33); end end
                    42:begin need(16'h0800); begin if(ROM_SCALAR) rom_scalar(8'd65); else call_scalar(0,1,1,65,7,1,SRC_SLOT11,SRC_P54_S33); end end
                    43:begin need(16'h2080); begin if(ROM_SCALAR) rom_scalar(8'd66); else call_scalar(1,1,1,66,3,1,SRC_SLOT13,SRC_SLOT7); end end
                    44:begin need(16'h0400); begin if(ROM_SCALAR) rom_scalar(8'd67); else call_scalar(0,1,0,44,13,1,SRC_SLOT10,SRC_WIDTH_LAST); end end
                    45:begin need(16'h0800); begin if(ROM_SCALAR) rom_scalar(8'd68); else call_scalar(0,1,0,44,7,1,SRC_SLOT11,SRC_HEIGHT_LAST); end end
                    46:begin need(16'h2080); begin if(ROM_SCALAR) rom_scalar(8'd69); else call_scalar(1,1,1,45,8,1,SRC_SLOT13,SRC_SLOT7); end end
                    47:begin need(16'h0100); begin if(ROM_SCALAR) rom_scalar(8'd70); else call_scalar(0,1,0,67,13,1,SRC_SLOT8,SRC_P0_U21); end end
                    48:begin need(16'h2008); begin if(ROM_SCALAR) rom_scalar(8'd71); else call_scalar(1,1,1,68,3,1,SRC_SLOT3,SRC_SLOT13); end end
                    49:begin need(16'h0008); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd72,0); end else local_move(3,69,1,SRC_SLOT3,3); end end
                    50:begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd73,0); end else local_move(4,52,0,SRC_P0_U21,30); end
                    51:begin
                        if(subphase==0) begin need(16'h0018); begin if(ROM_SCALAR) rom_scalar(8'd74); else call_scalar(3,1,0,70,14,1,SRC_SLOT3,SRC_SLOT4); end next_step=51; next_phase=1; end
                        else begin need(16'h4000); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd75,0); if(!slot_geometry_ok[SRC_SLOT14-6'd1]) reject(LOCAL_REJECT,GEOM_RANGE); end else geometry(14,SRC_SLOT14); end end
                    end
                    52:begin need(16'h0800); begin if(ROM_SCALAR) rom_scalar(8'd76); else call_scalar(0,1,1,65,13,1,SRC_SLOT11,SRC_P21_S33); end end
                    53:begin need(16'h0400); begin if(ROM_SCALAR) rom_scalar(8'd77); else call_scalar(0,1,1,65,7,1,SRC_SLOT10,SRC_P54_S33); end end
                    54:begin need(16'h2080); begin if(ROM_SCALAR) rom_scalar(8'd78); else call_scalar(2,1,1,66,8,1,SRC_SLOT13,SRC_SLOT7); end end
                    55:begin need(16'h0100); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd79,0); end else local_move(8,69,1,SRC_SLOT8,3); end end
                    56:begin
                        if(subphase==0) begin need(16'h0110); begin if(ROM_SCALAR) rom_scalar(8'd80); else call_scalar(3,1,0,70,9,1,SRC_SLOT8,SRC_SLOT4); end next_step=56; next_phase=1; end
                        else begin
                            need(16'h8200); local_write(15,34,0,{158'd0,work_slot[15][33:18],work_slot[9][17:0]});
                            if(!anis_valid) reject(FRAME_FAIL,INTERNAL);
                            if(!slot_geometry_ok[9]) reject(LOCAL_REJECT,GEOM_RANGE);
                        end
                    end
                    57:begin need(16'h0400); begin if(ROM_SCALAR) rom_scalar(8'd81); else call_scalar(0,1,1,64,13,0,SRC_SLOT10,SRC_SLOT10); end end
                    58:begin need(16'h0800); begin if(ROM_SCALAR) rom_scalar(8'd82); else call_scalar(0,1,1,64,7,0,SRC_SLOT11,SRC_SLOT11); end end
                    59:begin need(16'h2080); begin if(ROM_SCALAR) rom_scalar(8'd83); else call_scalar(1,0,0,65,12,0,SRC_SLOT13,SRC_SLOT7); end end
                    60:begin need(16'h1000); begin if(ROM_SCALAR) rom_scalar(8'd84); else call_scalar(4,0,0,33,13,0,SRC_SLOT12,SRC_ZERO); end
                        if(!slot_k_min_ok[12]) reject(FRAME_FAIL,INTERNAL); end
                    61:begin
                        need(16'h8000); plan_class=2;
                        if(!anis_valid) reject(FRAME_FAIL,INTERNAL);
                        if(kind==18) begin plan_value[0+:21]=payload[20:0]; plan_value[21+:16]=work_slot[15][33:18]; end
                        else begin
                            need(16'hfc00); if(!mu_valid || slot_zero[13]) reject(FRAME_FAIL,INTERNAL);
                            plan_value[0+:32]=work_slot[10][31:0]; plan_value[32+:32]=work_slot[11][31:0];
                            plan_value[64+:32]=work_slot[11][31:0]; plan_value[96+:32]=-work_slot[10][31:0];
                            plan_value[128+:18]=work_slot[14][17:0]; plan_value[146+:18]=work_slot[15][17:0];
                            plan_value[164+:16]=work_slot[15][33:18]; plan_value[180+:65]=work_slot[12][64:0]; plan_value[245+:33]=work_slot[13][32:0];
                        end
                    end
                    default:reject(FRAME_FAIL,INTERNAL);
                endcase
            end
            13:begin // 两normal各三调用核K，然后 I01…15。
                case(step)
                    1:begin if(ROM_SCALAR) rom_scalar(8'd85); else call_scalar(0,1,1,64,13,0,SRC_P0_S32,SRC_P0_S32); end
                    2:begin if(ROM_SCALAR) rom_scalar(8'd86); else call_scalar(0,1,1,64,14,0,SRC_P32_S32,SRC_P32_S32); end
                    3:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd87); else call_scalar(1,0,0,65,12,0,SRC_SLOT13,SRC_SLOT14); end end
                    4:begin need(16'h1000); begin if(ROM_SCALAR) rom_scalar(8'd88); else call_scalar(0,1,1,64,13,0,SRC_P82_S32,SRC_P82_S32); end if(!slot_k_min_ok[12]) reject(FRAME_FAIL,INTERNAL); end
                    5:begin if(ROM_SCALAR) rom_scalar(8'd89); else call_scalar(0,1,1,64,14,0,SRC_P114_S32,SRC_P114_S32); end
                    6:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd87); else call_scalar(1,0,0,65,12,0,SRC_SLOT13,SRC_SLOT14); end end
                    7:begin need(16'h1000); begin if(ROM_SCALAR) rom_scalar(8'd90); else call_scalar(0,1,1,64,13,1,SRC_P0_S32,SRC_P114_S32); end if(!slot_k_min_ok[12]) reject(FRAME_FAIL,INTERNAL); end
                    8:begin if(ROM_SCALAR) rom_scalar(8'd91); else call_scalar(0,1,1,64,14,1,SRC_P32_S32,SRC_P82_S32); end
                    9:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd92); else call_scalar(2,1,1,65,0,1,SRC_SLOT13,SRC_SLOT14); end end
                    10:begin need(16'h0001); begin if(ROM_SCALAR) rom_scalar(8'd93); else call_scalar(0,1,1,50,13,1,SRC_P64_S18,SRC_P114_S32); end if(slot_zero[0]) reject(LOCAL_REJECT,DEGENERATE); end
                    11:begin if(ROM_SCALAR) rom_scalar(8'd94); else call_scalar(0,1,1,50,14,1,SRC_P146_S18,SRC_P32_S32); end
                    12:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd95); else call_scalar(2,1,1,51,1,1,SRC_SLOT13,SRC_SLOT14); end end
                    13:begin need(16'h0002); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd96,0); end else local_move(1,81,1,SRC_SLOT1,30); end end
                    14:begin if(ROM_SCALAR) rom_scalar(8'd97); else call_scalar(0,1,1,50,13,1,SRC_P0_S32,SRC_P146_S18); end
                    15:begin if(ROM_SCALAR) rom_scalar(8'd98); else call_scalar(0,1,1,50,14,1,SRC_P82_S32,SRC_P64_S18); end
                    16:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd99); else call_scalar(2,1,1,51,2,1,SRC_SLOT13,SRC_SLOT14); end end
                    17:begin need(16'h0004); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd100,0); end else local_move(2,81,1,SRC_SLOT2,30); end end
                    18:begin
                        need(16'h0007);
                        if(subphase==0) begin begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd101,work_slot[0][191]); end else local_signed_move(0,65,0,SRC_SLOT0,work_slot[0][191]); end next_step=18; next_phase=1; end
                        else if(subphase==1) begin begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd102,negative_branch); end else local_signed_move(1,82,1,SRC_SLOT1,negative_branch); end next_step=18; next_phase=2; end
                        else begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd103,negative_branch); end else local_signed_move(2,82,1,SRC_SLOT2,negative_branch); end
                    end
                    19:begin need(16'h0003); begin if(ROM_SCALAR) rom_scalar(8'd104); else call_scalar(3,1,0,83,3,1,SRC_SLOT1,SRC_SLOT0); end end
                    20:begin need(16'h000d); begin if(ROM_SCALAR) rom_scalar(8'd105); else call_scalar(3,1,0,83,4,1,SRC_SLOT2,SRC_SLOT0); end if(!slot_geometry_ok[3]) reject(LOCAL_REJECT,GEOM_RANGE); end
                    21:begin need(16'h0018); plan_class=2; plan_value[0+:18]=work_slot[3][17:0]; plan_value[18+:18]=work_slot[4][17:0]; if(!slot_geometry_ok[4]) reject(LOCAL_REJECT,GEOM_RANGE); end
                    default:reject(FRAME_FAIL,INTERNAL);
                endcase
            end
            14:begin // D01…25：命中只跳四个K/M调用；边界比较始终全宽。
                case(step)
                    1:begin
                        if(cache_hit) begin local_write(0,65,0,{127'd0,cache_k[hit_index]}); next_step=2; next_phase=1; end
                        else begin if(ROM_SCALAR) rom_scalar(8'd85); else call_scalar(0,1,1,64,13,0,SRC_P0_S32,SRC_P0_S32); end
                    end
                    2:begin
                        if(subphase==1) begin local_write(1,33,0,{159'd0,cache_m[hit_index]}); next_step=5; end
                        else begin if(ROM_SCALAR) rom_scalar(8'd86); else call_scalar(0,1,1,64,14,0,SRC_P32_S32,SRC_P32_S32); end
                    end
                    3:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd106); else call_scalar(1,0,0,65,0,0,SRC_SLOT13,SRC_SLOT14); end end
                    4:begin need(16'h0001); begin if(ROM_SCALAR) rom_scalar(8'd107); else call_scalar(4,0,0,33,1,0,SRC_SLOT0,SRC_ZERO); end if(!slot_k_min_ok[0]) reject(FRAME_FAIL,INTERNAL); end
                    5:begin need(16'h0003); begin if(ROM_SCALAR) rom_scalar(8'd108); else call_scalar(0,1,0,43,13,1,SRC_P0_S32,SRC_P82_U11); end if(!slot_k_min_ok[0] || slot_zero[1]) reject(FRAME_FAIL,INTERNAL); end
                    6:begin if(ROM_SCALAR) rom_scalar(8'd109); else call_scalar(0,1,0,43,14,1,SRC_P32_S32,SRC_P93_U11); end
                    7:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd110); else call_scalar(1,1,1,44,2,1,SRC_SLOT13,SRC_SLOT14); end end
                    8:begin need(16'h0004); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd111,0); end else local_move(2,48,1,SRC_SLOT2,4); end end
                    9:begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd112,0); end else local_move(13,48,1,SRC_P64_S18,30); end
                    10:begin need(16'h2004); begin if(ROM_SCALAR) rom_scalar(8'd113); else call_scalar(2,1,1,50,2,1,SRC_SLOT2,SRC_SLOT13); end end
                    11:begin need(16'h0004); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd114,work_slot[2][191]); end else local_signed_move(13,50,0,SRC_SLOT2,work_slot[2][191]); end end
                    12:begin need(16'h2002); begin if(ROM_SCALAR) rom_scalar(8'd115); else call_scalar(3,0,0,21,3,0,SRC_SLOT13,SRC_SLOT1); end end
                    13:begin need(16'h0004); begin if(ROM_SCALAR) rom_scalar(8'd116); else call_scalar(0,1,1,100,14,0,SRC_SLOT2,SRC_SLOT2); end end
                    14:begin need(16'h4000); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd117,0); end else local_move(4,102,0,SRC_SLOT14,2); end end
                    15:begin
                        need(16'h0008); local_write(5,22,0,line_odd_boundary(work_slot[3][20:0],0));
                        if(slot_zero[3]) begin local_write(5,22,0,0); next_step=19; end
                    end
                    16:begin need(16'h0020); begin if(ROM_SCALAR) rom_scalar(8'd118); else call_scalar(0,0,0,44,6,0,SRC_SLOT5,SRC_SLOT5); end end
                    17:begin need(16'h0041); begin if(ROM_SCALAR) rom_scalar(8'd119); else call_scalar(0,0,0,109,7,0,SRC_SLOT6,SRC_SLOT0); end end
                    18:begin
                        need(16'h0090);
                        if(subphase==0) begin begin if(ROM_SCALAR) rom_scalar(8'd120); else call_scalar(5,0,0,2,15,0,SRC_SLOT4,SRC_SLOT7); end next_step=18; next_phase=1; end
                        else begin
                            need(16'h8008); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd121,0); end else local_move(3,21,0,SRC_SLOT3,0); end
                            if(work_slot[15]==1 || (slot_zero[15] && work_slot[3][0])) begin local_write(3,21,0,line_neighbor(work_slot[3][20:0],0)); next_step=24; end
                        end
                    end
                    19:begin need(16'h0008); local_write(5,22,0,line_odd_boundary(work_slot[3][20:0],1)); end
                    20:begin need(16'h0020); begin if(ROM_SCALAR) rom_scalar(8'd118); else call_scalar(0,0,0,44,6,0,SRC_SLOT5,SRC_SLOT5); end end
                    21:begin need(16'h0041); begin if(ROM_SCALAR) rom_scalar(8'd119); else call_scalar(0,0,0,109,7,0,SRC_SLOT6,SRC_SLOT0); end end
                    22:begin need(16'h0090); begin if(ROM_SCALAR) rom_scalar(8'd120); else call_scalar(5,0,0,2,15,0,SRC_SLOT4,SRC_SLOT7); end end
                    23:begin
                        need(16'h8008); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd121,0); end else local_move(3,21,0,SRC_SLOT3,0); end
                        if(work_slot[15]==2 || (slot_zero[15] && work_slot[3][0])) local_write(3,21,0,line_neighbor(work_slot[3][20:0],1));
                    end
                    24:begin
                        need(16'h0009); next_step=24; next_phase=subphase+4'd1;
                        case(subphase)
                            0:local_write(5,22,0,line_odd_boundary(work_slot[3][20:0],1));
                            1:begin need(16'h0020); begin if(ROM_SCALAR) rom_scalar(8'd118); else call_scalar(0,0,0,44,6,0,SRC_SLOT5,SRC_SLOT5); end end
                            2:begin need(16'h0040); begin if(ROM_SCALAR) rom_scalar(8'd119); else call_scalar(0,0,0,109,7,0,SRC_SLOT6,SRC_SLOT0); end end
                            3:begin need(16'h0090); begin if(ROM_SCALAR) rom_scalar(8'd120); else call_scalar(5,0,0,2,15,0,SRC_SLOT4,SRC_SLOT7); end end
                            4:begin
                                need(16'h8000); local_write(5,22,0,line_odd_boundary(work_slot[3][20:0],0));
                                if(!qualify_distance_bounds(work_slot[3][20:0],work_slot[15][1:0],1)) reject(FRAME_FAIL,INTERNAL);
                                if(slot_zero[3]) begin next_step=25; next_phase=0; local_write(5,22,0,0); end
                            end
                            5:begin need(16'h0020); begin if(ROM_SCALAR) rom_scalar(8'd118); else call_scalar(0,0,0,44,6,0,SRC_SLOT5,SRC_SLOT5); end end
                            6:begin need(16'h0040); begin if(ROM_SCALAR) rom_scalar(8'd119); else call_scalar(0,0,0,109,7,0,SRC_SLOT6,SRC_SLOT0); end end
                            7:begin need(16'h0090); begin if(ROM_SCALAR) rom_scalar(8'd120); else call_scalar(5,0,0,2,15,0,SRC_SLOT4,SRC_SLOT7); end end
                            8:begin
                                need(16'h8000); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd121,0); end else local_move(3,21,0,SRC_SLOT3,0); end next_step=25; next_phase=0;
                                if(!qualify_distance_bounds(work_slot[3][20:0],work_slot[15][1:0],0)) reject(FRAME_FAIL,INTERNAL);
                            end
                            default:reject(FRAME_FAIL,INTERNAL);
                        endcase
                    end
                    25:begin need(16'h000b); plan_class=2; plan_value[0+:21]=work_slot[3][20:0]; plan_value[21+:65]=work_slot[0][64:0]; plan_value[86+:33]=work_slot[1][32:0]; end
                    default:reject(FRAME_FAIL,INTERNAL);
                endcase
            end
            15:begin // F01…F22；z分支只改变原N/D，尾段使用floor后精确舍入。
                case(step)
                    1:begin if(ROM_SCALAR) rom_scalar(8'd122); else call_scalar(2,0,1,19,0,1,SRC_P72_U11_SHIFT4,SRC_P0_S18); end
                    2:begin if(ROM_SCALAR) rom_scalar(8'd123); else call_scalar(2,0,1,19,1,1,SRC_P83_U11_SHIFT4,SRC_P18_S18); end
                    3:begin if(ROM_SCALAR) rom_scalar(8'd124); else call_scalar(2,1,1,19,2,1,SRC_P36_S18,SRC_P0_S18); end
                    4:begin if(ROM_SCALAR) rom_scalar(8'd125); else call_scalar(2,1,1,19,3,1,SRC_P54_S18,SRC_P18_S18); end
                    5:begin need(16'h0004); begin if(ROM_SCALAR) rom_scalar(8'd126); else call_scalar(0,1,1,38,13,0,SRC_SLOT2,SRC_SLOT2); end end
                    6:begin need(16'h0008); begin if(ROM_SCALAR) rom_scalar(8'd127); else call_scalar(0,1,1,38,14,0,SRC_SLOT3,SRC_SLOT3); end end
                    7:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd128); else call_scalar(1,0,0,39,4,0,SRC_SLOT13,SRC_SLOT14); end end
                    8:begin need(16'h0015); begin if(ROM_SCALAR) rom_scalar(8'd129); else call_scalar(0,1,1,38,13,1,SRC_SLOT0,SRC_SLOT2); end if(slot_zero[4]) reject(LOCAL_REJECT,DEGENERATE); end
                    9:begin need(16'h000a); begin if(ROM_SCALAR) rom_scalar(8'd130); else call_scalar(0,1,1,38,14,1,SRC_SLOT1,SRC_SLOT3); end end
                    10:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd131); else call_scalar(1,1,1,39,5,1,SRC_SLOT13,SRC_SLOT14); end end
                    11:begin
                        need(16'h003f); next_step=11; next_phase=subphase+4'd1;
                        if(work_slot[5][191] || slot_zero[5] || $signed(work_slot[5])>=$signed(work_slot[4])) begin
                            case(subphase)
                                0:begin
                                    if($signed(work_slot[5])>=$signed(work_slot[4])) begin if(ROM_SCALAR) rom_scalar(8'd132); else call_scalar(2,0,1,19,0,1,SRC_P72_U11_SHIFT4,SRC_P36_S18); end
                                    else begin begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd133,0); end else local_move(0,19,1,SRC_SLOT0,0); end next_phase=2; end
                                end
                                1:begin if(ROM_SCALAR) rom_scalar(8'd134); else call_scalar(2,0,1,19,1,1,SRC_P83_U11_SHIFT4,SRC_P54_S18); end
                                2:begin if(ROM_SCALAR) rom_scalar(8'd135); else call_scalar(0,1,1,38,13,0,SRC_SLOT0,SRC_SLOT0); end
                                3:begin if(ROM_SCALAR) rom_scalar(8'd136); else call_scalar(0,1,1,38,14,0,SRC_SLOT1,SRC_SLOT1); end
                                4:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd137); else call_scalar(1,0,0,39,7,0,SRC_SLOT13,SRC_SLOT14); end end
                                5:begin local_write(8,39,0,192'd1); next_step=12; next_phase=0; end
                                default:reject(FRAME_FAIL,INTERNAL);
                            endcase
                        end else begin
                            case(subphase)
                                0:begin if(ROM_SCALAR) rom_scalar(8'd138); else call_scalar(0,1,1,38,13,1,SRC_SLOT0,SRC_SLOT3); end
                                1:begin if(ROM_SCALAR) rom_scalar(8'd139); else call_scalar(0,1,1,38,14,1,SRC_SLOT1,SRC_SLOT2); end
                                2:begin need(16'h6000); begin if(ROM_SCALAR) rom_scalar(8'd140); else call_scalar(2,1,1,39,6,1,SRC_SLOT13,SRC_SLOT14); end end
                                3:begin need(16'h0040); begin if(ROM_SCALAR) rom_scalar(8'd141); else call_scalar(0,1,1,78,7,0,SRC_SLOT6,SRC_SLOT6); end end
                                4:begin begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd142,0); end else local_move(8,39,0,SRC_SLOT4,0); end next_step=12; next_phase=0; end
                                default:reject(FRAME_FAIL,INTERNAL);
                            endcase
                        end
                    end
                    12:begin need(16'h0080); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd143,0); end else local_move(9,80,0,SRC_SLOT7,2); end end
                    13:begin need(16'h0180); begin if(ROM_SCALAR) rom_scalar(8'd144); else call_scalar(6,0,0,37,10,0,SRC_SLOT7,SRC_SLOT8); end if(slot_zero[8]) reject(FRAME_FAIL,INTERNAL); end
                    14:begin need(16'h0400); begin if(ROM_SCALAR) rom_scalar(8'd145); else call_scalar(7,0,0,19,11,0,SRC_SLOT10,SRC_ZERO); end end
                    15:begin need(16'h0800); local_write(6,20,0,finite_odd_boundary(work_slot[11][18:0],1)); end
                    16:begin need(16'h0040); begin if(ROM_SCALAR) rom_scalar(8'd146); else call_scalar(0,0,0,40,13,0,SRC_SLOT6,SRC_SLOT6); end end
                    17:begin need(16'h2100); begin if(ROM_SCALAR) rom_scalar(8'd147); else call_scalar(0,0,0,79,13,0,SRC_SLOT13,SRC_SLOT8); end end
                    18:begin need(16'h2200); begin if(ROM_SCALAR) rom_scalar(8'd148); else call_scalar(5,0,0,2,15,0,SRC_SLOT9,SRC_SLOT13); end end
                    19:begin need(16'h8800); local_write(12,19,0,{172'd0,choose_midpoint_even(work_slot[11][18:0],work_slot[15][1:0])}); end
                    20,21:begin
                        need(16'h1100); next_step=step; next_phase=subphase+4'd1;
                        case(subphase)
                            0:begin
                                local_write(6,20,0,finite_odd_boundary(work_slot[12][18:0],step==20));
                                if(step==21 && slot_zero[12]) begin local_write(6,20,0,0); next_step=22; next_phase=0; end
                            end
                            1:begin need(16'h0040); begin if(ROM_SCALAR) rom_scalar(8'd146); else call_scalar(0,0,0,40,13,0,SRC_SLOT6,SRC_SLOT6); end end
                            2:begin need(16'h2000); begin if(ROM_SCALAR) rom_scalar(8'd147); else call_scalar(0,0,0,79,13,0,SRC_SLOT13,SRC_SLOT8); end end
                            3:begin need(16'h2200); begin if(ROM_SCALAR) rom_scalar(8'd148); else call_scalar(5,0,0,2,15,0,SRC_SLOT9,SRC_SLOT13); end end
                            4:begin
                                need(16'h8000); begin if(ROM_SCALAR&&SERIAL_LOCAL_MOVES) begin rom_local(8'd149,0); end else local_move(12,19,0,SRC_SLOT12,0); end next_step=step+7'd1; next_phase=0;
                                if(!qualify_distance_bounds(work_slot[12][20:0],work_slot[15][1:0],step==20)) reject(FRAME_FAIL,INTERNAL);
                            end
                            default:reject(FRAME_FAIL,INTERNAL);
                        endcase
                    end
                    22:begin need(16'h1180); plan_class=2; plan_value[0+:78]=work_slot[7][77:0]; plan_value[78+:39]=work_slot[8][38:0]; plan_value[117+:19]=work_slot[12][18:0]; end
                    default:reject(FRAME_FAIL,INTERNAL);
                endcase
            end
            default:reject(FRAME_FAIL,INTERNAL);
        endcase
        // 两个操作数由LOAD_A/LOAD_B复用唯一读口；PREPARE仅保存22位命令与来源码。
        if((slot_valid & required_slots)!=required_slots) reject(FRAME_FAIL,INTERNAL);
        // 本地结果在SCAN_LOCAL中查完整192位；此处不生成动态宽位掩码。
    end

    wire [5:0] operand_selector=(state==READ_B||state==LOAD_B)?held_b_source:held_a_source;
    wire operand_is_slot=operand_selector>=SRC_SLOT0&&operand_selector<=SRC_SLOT15;
    wire [191:0] selected_operand=operand_is_slot?slot_read_value:operand_source(operand_selector);
    wire [191:0] local_loaded_value=local_negative?(~selected_operand)+192'd1:selected_operand;
    wire [191:0] local_value=local_shared?published_command[22+:192]:plan_local;

    // 命令/最终结果共用的385位bank只有原LOAD与终态提交沿可写，取消保留FSM外层优先。
    logic [384:0] scalar_value_next;
    logic scalar_value_write;
    always_comb begin
        // DSP已用各条纹CE保留不写入的值；关闭CE时的输入无需再生成旧值反馈MUX。
        // 默认FF仍保持原整bank部分赋值语义，DSP只在跨边界条纹保留实际采样的旧位。
        scalar_value_next=DSP_OPERAND_RESULT?385'd0:scalar_or_final_value;scalar_value_write=0;
        if(!rst&&!(matching_cancel&&state!=IDLE))case(state)
            PREPARE:begin
                if(ROM_SCALAR&&plan_micro_valid&&(plan_class==0||(plan_class==1&&plan_local_shared)))begin end
                else if(plan_class==0)begin end
                else if(plan_class==1)begin end
                else if(plan_class==2)begin scalar_value_next=plan_value;scalar_value_write=1;end
            end
            LOAD_A:begin
                scalar_value_write=1;
                if(DSP_OPERAND_RESULT)scalar_value_next[215:192]=scalar_or_final_value[215:192];
                if(USE_WORD_SLOTS&&operand_is_slot)
                    scalar_value_next[191:0]={slot_word_q,scalar_or_final_value[191:16]};
                else if(local_shared&&!SERIAL_LOCAL_MOVES)
                    scalar_value_next[191:0]=local_loaded_value<<held_local_shift;
                else scalar_value_next[191:0]=selected_operand;
            end
            LOAD_B:begin
                scalar_value_write=1;
                if(DSP_OPERAND_RESULT)begin
                    scalar_value_next[191:180]=scalar_or_final_value[191:180];
                    scalar_value_next[384]=scalar_or_final_value[384];
                end
                if(USE_WORD_SLOTS&&operand_is_slot)
                    scalar_value_next[383:192]={slot_word_q,scalar_or_final_value[383:208]};
                else scalar_value_next[383:192]=selected_operand;
            end
            DRAIN:if(!command_published&&!cmd_pending&&bridge_quiet)begin
                scalar_value_next=0;scalar_value_write=1;
            end
            default:begin end
        endcase
    end
    generate if(DSP_OPERAND_RESULT)begin:dsp_operand_result
        wire [395:0] padded_value={11'd0,scalar_value_next};
        for(genvar word=0;word<11;word++)begin:words
            wire [35:0] input_word=padded_value[word*36+:36];
            wire [47:0] stored_word;
            wire word_write;
            // 不碰未被原部分赋值覆盖的半bank；word5跨192位边界，保留另半原值。
            if(word<5)begin:a_words
                assign word_write=scalar_value_write&&state!=LOAD_B;
            end else if(word>5)begin:b_words
                assign word_write=scalar_value_write&&state!=LOAD_A;
            end else begin:boundary_word
                assign word_write=scalar_value_write;
            end
            EFX_DSP48 #(.MODE("NORMAL"),.SIGNED(1'b0),
                .A_REG(1'b0),.B_REG(1'b0),.C_REG(1'b0),.P_REG(1'b0),.OP_REG(1'b0),
                .W_REG(1'b0),.O_REG(1'b1),.SHIFTER(1'b0),.RST_SYNC(1'b1),
                .P_EXT("ALIGN_RIGHT"),.C_EXT("ALIGN_RIGHT"),
                .M_SEL("P"),.N_SEL("C"),.W_SEL("X"),
                .O_REG_USE_CE(1'b1),.O_REG_USE_RST(1'b0)) storage(
                .A(input_word[35:17]),.B(18'h20000),.C({1'b0,input_word[16:0]}),
                .CASCIN(48'd0),.OP(2'd0),.SHIFT_ENA(1'b0),.CLK(clk),
                .CE(word_write),.RST(1'b0),.O(stored_word),.CASCOUT(),.OVFL());
            if(word==10)begin:tail_word
                assign scalar_or_final_value[384:360]=stored_word[24:0];
            end else begin:full_word
                assign scalar_or_final_value[word*36+:36]=stored_word[35:0];
            end
        end
    end else begin:ff_operand_result
        // 默认FF沿用同一nextdata/CE，不复位数据，全部385位数值语义保留。
        always_ff @(posedge clk)if(scalar_value_write)scalar_or_final_value<=scalar_value_next;
    end endgenerate


    // TS03：与原QUALIFY_RETURN相同的有序选择；完整资格检查不因物理变窄而删减。
    logic scalar_slot_qualified;
    logic [4:0] return_word;
    logic return_bad,slot_bad,return_word_bad,slot_word_bad;
    wire return_extension=return_signed&&bridge_result[402];
    wire slot_extension=reserved_signed&&bridge_result[209];
    wire [399:0] return_view={{15{return_extension}},bridge_result[18+:385]};
    wire [15:0] return_piece=return_view[return_word*16+:16];
    wire [8:0] return_cutoff={1'b0,reserved_width}-(return_signed?9'd1:9'd0);
    wire [8:0] slot_cutoff={1'b0,reserved_width}-(reserved_signed?9'd1:9'd0);
    wire local_extension=plan_signed&&local_value[191];
    wire [15:0] local_piece=local_value[return_word*16+:16];
    wire [8:0] local_cutoff={1'b0,plan_width}-(plan_signed?9'd1:9'd0);
    logic local_word_bad;
    function automatic word_extension_bad(input logic [15:0] piece,input logic [4:0] index,
        input logic [8:0] cutoff,input logic extension);
        logic [15:0] mask;
        begin
            if(index<cutoff[8:4])mask=0;
            else if(index>cutoff[8:4])mask=16'hffff;
            else mask=16'hffff<<cutoff[3:0];
            word_extension_bad=|((piece^{16{extension}})&mask);
        end
    endfunction
    // 返回正文由bridge持有到真实result_fire。两个资格独立累积，仍保留原首错次序。
    always_comb begin
        return_word_bad=word_extension_bad(return_piece,return_word,return_cutoff,return_extension);
        slot_word_bad=return_word<12&&word_extension_bad(return_piece,return_word,slot_cutoff,slot_extension);
        local_word_bad=word_extension_bad(local_piece,return_word,local_cutoff,local_extension);
    end
    always_comb begin
        scalar_slot_qualified=0;
        if(!cmd_pending || bridge_result[7:0]!={4'd0,reserved_destination}) scalar_slot_qualified=0;
        else if(bridge_result[8+:2]!=VALUE || bridge_result[10+:8]!=NONE) scalar_slot_qualified=0;
        else if(return_bad) scalar_slot_qualified=0;
        else if(!reserved_signed && bridge_result[402]) scalar_slot_qualified=0;
        else if(slot_bad) scalar_slot_qualified=0;
        else if(published_command[8+:3]==5 && bridge_result[18+:385]>2) scalar_slot_qualified=0;
        else scalar_slot_qualified=1;
    end

    // 完整192位槽保存在同步RAM；计划的低字段/sign及完整谓词仍在最后提交沿更新。
    // WORD_SLOTS只在串行局部算术模式启用；12字写齐以后才归还结果/改metadata。
    wire slot_write_enable=!rst&&!(matching_cancel&&state!=IDLE)&&
        ((state==QUALIFY_RETURN&&result_fire&&scalar_slot_qualified)||
         (state==LOCAL_COMMIT&&plan_class==1&&!slot_bad&&(!USE_WORD_SLOTS||slot_saved)));
    wire [3:0] slot_write_address=state==QUALIFY_RETURN?reserved_destination:plan_destination;
    wire [191:0] slot_write_value=state==QUALIFY_RETURN?bridge_result[18+:192]:local_value;
    wire slot_write_geometry_ok=fits_slot(slot_write_value,18,1);
    wire slot_write_normal_ok=$signed(slot_write_value)>=-192'sd1073741824&&
                               $signed(slot_write_value)<=192'sd1073741824;
    generate if(USE_WORD_SLOTS)begin:word_slots
        // 16槽×16字，前12字是完整192位，其余4字从不参与数值；一块16×256 RAM。
        logic [15:0] slot_memory[0:255],read_word;
        wire [7:0] read_address={4'(operand_selector-SRC_SLOT0),operand_word};
        wire [3:0] write_slot=state==SAVE_RETURN?reserved_destination:plan_destination;
        wire [7:0] write_address={write_slot,return_word[3:0]};
        wire [15:0] write_word=state==SAVE_RETURN?return_piece:local_piece;
        wire write_enable=!rst&&!matching_cancel&&!outer_cancel&&
            ((state==SAVE_RETURN&&bridge_valid&&scalar_slot_qualified)||
             (state==SAVE_LOCAL&&plan_class==1&&!slot_bad));
        always_ff @(posedge clk)begin
            read_word<=slot_memory[read_address];
            if(write_enable)slot_memory[write_address]<=write_word;
        end
        assign slot_word_q=read_word;
        assign slot_read_value=192'd0; // 槽操作数经LOAD逐字装入命令bank，不再旁路读取宽行。
    end else begin:wide_slots
        logic [191:0] slot_memory[0:15],read_value;
        always_ff @(posedge clk)begin
            read_value<=slot_memory[4'(operand_selector-SRC_SLOT0)];
            if(slot_write_enable)slot_memory[slot_write_address]<=slot_write_value;
        end
        assign slot_read_value=read_value;
        assign slot_word_q=16'd0;
    end endgenerate
    for(genvar row=0;row<16;row++)begin : g_slot_metadata
        localparam integer METADATA_BITS=metadata_bits(4'(row));
        logic [METADATA_BITS:0] stored;
        assign work_slot[row]={{(192-METADATA_BITS){stored[METADATA_BITS]}},stored[METADATA_BITS-1:0]};
        always_ff @(posedge clk)if(slot_write_enable&&slot_write_address==4'(row))begin
            stored<={slot_write_value[191],slot_write_value[METADATA_BITS-1:0]};
            slot_zero[row]<=slot_write_value==0;
            slot_geometry_ok[row]<=slot_write_geometry_ok;
            slot_normal_ok[row]<=slot_write_normal_ok;
            slot_u16_ok[row]<=slot_write_value<=192'd65535;
            slot_k_min_ok[row]<=slot_write_value>=(192'd1<<58);
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            state<=IDLE; response_outcome<=VALUE; response_reason<=NONE;
            slot_valid<=0; anis_valid<=0; mu_valid<=0; step<=1; subphase<=0;
            pending_next_step<=1; pending_next_phase<=0; negative_branch<=0; outer_cancel<=0;
            command_published<=0; cmd_pending<=0;held_a_source<=0;held_b_source<=0;
            operand_word<=0;slot_saved<=0;
            local_shared<=0;local_negative<=0;held_local_shift<=0;
            reserved_destination<=0; reserved_width<=1; reserved_signed<=0; return_signed<=0;
            cache_valid<=0; replacement<=0;
        end else begin
            // 已经公开的握手先记真实fire；取消不撤回消息、不抢改HELD。
            if(cmd_fire) begin command_published<=0; cmd_pending<=1;slot_saved<=0; end
            if(result_fire) cmd_pending<=0;
            if(matching_cancel && state!=IDLE) begin outer_cancel<=1; state<=DRAIN; end
            else case(state)
                IDLE:if(req_valid && req_ready) begin
                    held_header<=req_body[221:0]; slot_valid<=0; anis_valid<=0; mu_valid<=0;
                    step<=1; subphase<=0; response_outcome<=VALUE; response_reason<=NONE;
                    operand_word<=0;slot_saved<=0;
                    outer_cancel<=matching_cancel; state<=matching_cancel?DRAIN:CHECK;
                end
                CHECK:begin
                    if(input_check!=0) begin response_outcome<=input_check[1:0]; response_reason<=input_check[9:2]; state<=DRAIN; end
                    else state<=PREPARE;
                end
                PREPARE:begin
                    if(ROM_SCALAR&&plan_micro_valid&&(plan_class==0||(plan_class==1&&plan_local_shared)))begin
                        command_published<=0;local_negative<=plan_local_negative;
                        pending_next_step<=next_step;pending_next_phase<=next_phase;
                        if(kind==12&&step==29&&plan_class==0)negative_branch<=work_slot[3][191];
                        state<=FETCH_MICRO;
                    end else if(plan_class==0) begin
                        command_header<=plan_command[21:0];command_published<=0;
                        local_shared<=0;
                        held_a_source<=plan_a_source;held_b_source<=plan_b_source;
                        reserved_destination<=plan_destination; reserved_width<=plan_width;
                        reserved_signed<=plan_signed; return_signed<=plan_return_signed;
                        pending_next_step<=next_step; pending_next_phase<=next_phase;
                        if(kind==12 && step==29) negative_branch<=work_slot[3][191];
                        operand_word<=0;slot_saved<=0;state<=READ_A;
                    end else if(plan_class==1)begin
                        local_shared<=plan_local_shared;
                        local_negative<=plan_local_negative;
                        if(plan_local_shared)begin
                            held_a_source<=plan_local_source;held_local_shift<=plan_local_shift;
                            if(SERIAL_LOCAL_MOVES)begin
                                // 完整值乘以带符号的2^shift；复用已有字算术核，去掉192位桶形移位器。
                                // 请求域192保证输入不先窄化；返回仍按局部目的的原宽度/符号检查。
                                command_header<={9'd192,1'b1,1'b1,3'd0,4'd0,plan_destination};
                                command_published<=0;held_b_source<=SRC_LOCAL_FACTOR;
                                reserved_destination<=plan_destination;reserved_width<=plan_width;
                                reserved_signed<=plan_signed;return_signed<=plan_signed;
                                pending_next_step<=next_step;pending_next_phase<=next_phase;
                            end
                            operand_word<=0;slot_saved<=0;state<=READ_A;
                        end else begin return_word<=11;slot_saved<=0;slot_bad<=plan_width==0||plan_width>192;state<=SCAN_LOCAL;end
                    end
                    else if(plan_class==2) begin state<=PACK; end
                    else begin response_outcome<=plan_outcome; response_reason<=plan_reason; state<=DRAIN; end
                end
                FETCH_MICRO:begin
                    // PREPARE沿锁定该ROM地址；这里消费同步读值，旧step/phase和槽仍保持。
                    local_shared<=micro_q[36];held_local_shift<=micro_q[35:30];
                    held_a_source<=micro_q[5:0];held_b_source<=micro_q[11:6];
                    reserved_destination<=micro_q[20:17];reserved_width<=micro_q[28:21];
                    reserved_signed<=micro_q[29];
                    return_signed<=micro_q[36]?micro_q[29]:
                        (micro_q[14:12]==2||((micro_q[14:12]==0||micro_q[14:12]==1)&&
                        (micro_q[16]||micro_q[15]))||(micro_q[14:12]==3&&micro_q[16]));
                    command_header<={micro_q[36]?9'd192:{1'b0,micro_q[28:21]},
                        micro_q[15],micro_q[16],micro_q[14:12],4'd0,micro_q[20:17]};
                    operand_word<=0;slot_saved<=0;state<=READ_A;
                end
                READ_A:state<=LOAD_A;
                LOAD_A:begin
                    if(USE_WORD_SLOTS&&operand_is_slot)begin
                        // 0..11按低字先读，12次接受后与原192位整行布局完全相同。
                        if(operand_word==11)begin operand_word<=0;state<=READ_B;end
                        else begin operand_word<=operand_word+4'd1;state<=READ_A;end
                    end else if(local_shared&&!SERIAL_LOCAL_MOVES)begin
                        // 复制/移位使用同一192位读口和既有命令暂存；仍扫描全部192位后才写槽。
                        return_word<=11;slot_bad<=plan_width==0||plan_width>192;state<=SCAN_LOCAL;
                    end else begin operand_word<=0;state<=READ_B;end
                end
                READ_B:state<=LOAD_B;
                LOAD_B:begin
                    if(USE_WORD_SLOTS&&operand_is_slot)begin
                        if(operand_word==11)begin command_published<=1;state<=ISSUE;end
                        else begin operand_word<=operand_word+4'd1;state<=READ_B;end
                    end else begin
                        command_published<=1;state<=ISSUE;
                    end
                end
                ISSUE:if(cmd_fire) state<=WAIT_RETURN;
                WAIT_RETURN:if(bridge_valid)begin
                    return_word<=24;return_bad<=reserved_width==0||reserved_width>192;
                    slot_bad<=0;state<=SCAN_RETURN;
                end
                SCAN_RETURN:begin
                    return_bad<=return_bad||return_word_bad;slot_bad<=slot_bad||slot_word_bad;
                    if(return_word==0)state<=QUALIFY_RETURN;
                    else return_word<=return_word-5'd1;
                end
                QUALIFY_RETURN:if(USE_WORD_SLOTS&&!slot_saved&&bridge_valid&&scalar_slot_qualified)begin
                    // 所有385位及目的资格已经检查；先保存完整192位，再真实交付held结果。
                    return_word<=0;state<=SAVE_RETURN;
                end else if(result_fire) begin
                    if(!cmd_pending || bridge_result[7:0]!={4'd0,reserved_destination}) begin response_outcome<=FRAME_FAIL; response_reason<=INTERNAL; state<=DRAIN; end
                    else if(bridge_result[8+:2]!=VALUE || bridge_result[10+:8]!=NONE) begin
                        response_outcome<=FRAME_FAIL; response_reason<=bridge_result[10+:8]; state<=DRAIN;
                    end else if(return_bad) begin
                        response_outcome<=FRAME_FAIL; response_reason<=OVERFLOW; state<=DRAIN;
                    end else if(!reserved_signed && bridge_result[402]) begin
                        response_outcome<=FRAME_FAIL; response_reason<=INTERNAL; state<=DRAIN;
                    end else if(slot_bad) begin
                        response_outcome<=FRAME_FAIL; response_reason<=OVERFLOW; state<=DRAIN;
                    end else if(published_command[8+:3]==5 && bridge_result[18+:385]>2) begin
                        response_outcome<=FRAME_FAIL; response_reason<=INTERNAL; state<=DRAIN;
                    end else begin
                        // TS03：同沿的g_typed_slot保存数据，此处保留原有效性/状态提交。
                        slot_valid[reserved_destination]<=1;
                        if(SERIAL_LOCAL_MOVES&&local_shared)begin
                            // 与原LOCAL_COMMIT同一提交语义，数据先通过完整资格检查才更新控制。
                            if((kind==12||kind==18)&&step==26&&subphase==1)anis_valid<=1;
                            if(kind==12&&step==56&&subphase==1)mu_valid<=1;
                            if(kind==12&&step==40&&subphase==0)
                                negative_branch<=work_slot[11][191]||(slot_zero[11]&&work_slot[10][191]);
                            if(kind==13&&step==18&&subphase==0)negative_branch<=work_slot[0][191];
                        end
                        if(!LS_TLS_ONLY&&((kind==14 && step==4) || (kind==12 && step==60))) begin
                            // M当前返回、K来自旧槽；只有完整资格通过且未取消才原子安装。
                            if(bridge_result[18+:192]!=0 && !install_hit) begin
                                cache_key[replacement]<=install_key;
                                cache_k[replacement]<=kind==14?work_slot[0][64:0]:work_slot[12][64:0];
                                cache_m[replacement]<=bridge_result[18+:33]; cache_valid[replacement]<=1; replacement<=replacement+2'd1;
                            end
                        end
                        state<=ADVANCE;
                    end
                end
                SAVE_RETURN:if(bridge_valid)begin
                    if(!scalar_slot_qualified)begin slot_saved<=0;state<=QUALIFY_RETURN;end
                    else if(return_word==11)begin slot_saved<=1;state<=QUALIFY_RETURN;end
                    else return_word<=return_word+5'd1;
                end
                ADVANCE:begin step<=pending_next_step; subphase<=pending_next_phase; state<=PREPARE; end
                SCAN_LOCAL:begin
                    // 旧槽、step和subphase保持，因此plan_local在12沿期间保持同一完整值。
                    slot_bad<=slot_bad||local_word_bad;
                    if(return_word==0)state<=LOCAL_COMMIT;
                    else return_word<=return_word-5'd1;
                end
                LOCAL_COMMIT:begin
                    if(plan_class!=1) begin response_outcome<=plan_outcome; response_reason<=plan_reason; state<=DRAIN; end
                    else if(slot_bad)begin response_outcome<=FRAME_FAIL;response_reason<=OVERFLOW;state<=DRAIN;end
                    else if(USE_WORD_SLOTS&&!slot_saved)begin return_word<=0;state<=SAVE_LOCAL;end
                    else begin
                        // TS03：局部数据同沿由g_typed_slot提交，控制与缓存仍读旧状态。
                        slot_valid[plan_destination]<=1;
                        if((kind==12 || kind==18) && step==26 && subphase==1) anis_valid<=1;
                        if(kind==12 && step==56 && subphase==1) mu_valid<=1;
                        if(kind==12 && step==40 && subphase==0)
                            negative_branch<=(work_slot[11][191] || (slot_zero[11] && work_slot[10][191]));
                        if(kind==13 && step==18 && subphase==0) negative_branch<=work_slot[0][191];
                        step<=next_step; subphase<=next_phase; state<=PREPARE;
                    end
                end
                SAVE_LOCAL:begin
                    // step/subphase与work_slot metadata均保持旧值，因此local_value不会因RAM部分写变化。
                    if(plan_class!=1||slot_bad)begin slot_saved<=0;state<=LOCAL_COMMIT;end
                    else if(return_word==11)begin slot_saved<=1;state<=LOCAL_COMMIT;end
                    else return_word<=return_word+5'd1;
                end
                DRAIN:if(!command_published && !cmd_pending && bridge_quiet) begin
                    if(outer_cancel) begin response_outcome<=CANCEL_DROP; response_reason<=NONE; end
                    state<=PACK;
                end
                PACK:if(!command_published && !cmd_pending && bridge_quiet) state<=HELD;
                HELD:if(rsp_valid && rsp_ready) state<=IDLE;
                default:begin response_outcome<=FRAME_FAIL; response_reason<=INTERNAL; state<=DRAIN; end
            endcase
        end
    end
endmodule
