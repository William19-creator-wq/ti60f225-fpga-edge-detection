// FIT v1 B–H：七类复合运算，只有一份私有算术核；步骤号对应中文顺序表。
module fit_core_original(
    input logic clk,rst,
    input logic req_valid,input logic [621:0] req_body,output logic req_ready,
    output logic rsp_valid,output logic [584:0] rsp_body,input logic rsp_ready,
    input logic cancel_valid,input logic [175:0] cancel_id,output logic quiet
);
    import fit_protocol_pkg::*;
    typedef enum logic [3:0] {IDLE,CHECK,PREPARE,ISSUE,WAIT_RETURN,QUALIFY_RETURN,
                              ADVANCE,LOCAL_COMMIT,DRAIN,PACK,HELD} fit_state_t;
    fit_state_t state;
    logic [621:0] held_request;
    logic [384:0] response_value;
    logic [1:0] response_outcome;
    logic [7:0] response_reason;
    logic [191:0] work_slot[0:15];
    logic [15:0] slot_valid;
    logic anis_valid,mu_valid;
    logic [6:0] step,pending_next_step;
    logic [3:0] subphase,pending_next_phase;
    logic negative_branch,outer_cancel,command_published,cmd_pending;
    logic [405:0] published_command;
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
    logic [4:0] kind;
    logic [399:0] payload;

    // 组合计划只读旧槽；PREPARE锁命令，返回提交后ADVANCE才允许读取新槽。
    logic [1:0] plan_class; // 0私有调用，1局部提交，2完成，3拒绝
    logic [405:0] plan_command;
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

    task automatic need(input logic [15:0] mask);
        required_slots=required_slots | mask;
    endtask
    task automatic call_scalar(input logic [2:0] op,input logic sa,sb,
        input integer bits,destination,input logic stored_signed,
        input logic [191:0] a,b);
        begin
            plan_class=0; plan_destination=destination[3:0]; plan_width=bits[7:0];
            plan_signed=stored_signed;
            plan_return_signed=(op==2 || ((op==0 || op==1) && (sa || sb)) || (op==3 && sa));
            plan_command={b,a,bits[8:0],sb,sa,op,4'd0,destination[3:0]};
        end
    endtask
    task automatic local_write(input integer destination,bits,input logic signed_field,
                                input logic [191:0] value);
        begin
            plan_class=1; plan_destination=destination[3:0]; plan_width=bits[7:0];
            plan_signed=signed_field; plan_local=value;
        end
    endtask
    task automatic reject(input logic [1:0] outcome,input logic [7:0] reason);
        begin plan_class=3; plan_outcome=outcome; plan_reason=reason; end
    endtask
    task automatic geometry(input integer destination,input logic [191:0] value);
        begin
            local_write(destination,18,1,value);
            if(!fits_slot(value,18,1)) reject(LOCAL_REJECT,GEOM_RANGE);
        end
    endtask

    scalar_bridge private_bridge(
        .clk(clk),.rst(rst),.cmd_valid(command_published),.cmd_body(published_command),.cmd_ready(bridge_ready),
        .result_valid(bridge_valid),.result_body(bridge_result),.result_ready(bridge_result_ready),
        .abort(state==DRAIN || matching_cancel || outer_cancel),.bridge_quiet(bridge_quiet),
        .child_req_valid(child_req_valid),.child_req_body(child_req_body),.child_req_ready(child_req_ready),
        .child_rsp_valid(child_rsp_valid),.child_rsp_body(child_rsp_body),.child_rsp_ready(child_rsp_ready),
        .child_cancel_valid(child_cancel_valid),.child_cancel_id(child_cancel_id),.child_quiet(child_quiet)
    );
    scalar_core private_arithmetic(
        .clk(clk),.rst(rst),.req_valid(child_req_valid),.req_body(child_req_body),.req_ready(child_req_ready),
        .rsp_valid(child_rsp_valid),.rsp_body(child_rsp_body),.rsp_ready(child_rsp_ready),
        .cancel_valid(child_cancel_valid),.cancel_id(child_cancel_id),.quiet(child_quiet)
    );

    always_comb begin
        kind=held_request[KIND_LO+:5]; payload=held_request[PAYLOAD_LO+:400];
        req_ready=!rst && state==IDLE && !command_published && !cmd_pending && bridge_quiet;
        quiet=req_ready; rsp_valid=!rst && state==HELD;
        rsp_body=pack_response(held_request,response_outcome,response_reason,response_value);
        matching_cancel=cancel_valid && ((state==IDLE && req_valid && req_ready && cancel_id==req_body[175:0]) ||
            (state!=IDLE && state!=HELD && cancel_id==held_request[175:0]));
        cmd_fire=command_published && bridge_ready;
        bridge_result_ready=!rst && (state==QUALIFY_RETURN || state==DRAIN);
        result_fire=bridge_valid && bridge_result_ready;
        input_check=check_request(held_request);
        normal_key=payload[63:0]; cache_hit=0; hit_index=0;
        install_key=kind==14?normal_key:{work_slot[11][31:0],work_slot[10][31:0]}; install_hit=0;
        for(integer c=0;c<4;c=c+1) begin
            if(cache_valid[c] && cache_key[c]==normal_key) begin cache_hit=1; hit_index=c[1:0]; end
            if(cache_valid[c] && cache_key[c]==install_key) install_hit=1;
        end
    end

    always_comb begin
        plan_class=3; plan_command=0; plan_local=0; plan_destination=0;
        plan_width=1; plan_signed=0; plan_return_signed=0; required_slots=0;
        next_step=step+7'd1; next_phase=0;
        plan_outcome=FRAME_FAIL; plan_reason=INTERNAL; plan_value=0;
        case(kind)
            11,17:begin // L01…L21：圆LS；诊断L07后直接L20。
                case(step)
                    1:call_scalar(1,0,0,44,0,0,pf(payload,21,43,0),pf(payload,108,43,0));
                    2:call_scalar(0,0,0,86,13,0,pf(payload,21,43,0),pf(payload,108,43,0));
                    3:call_scalar(0,1,1,88,14,0,pf(payload,64,44,1),pf(payload,64,44,1));
                    4:begin need(16'h6000); call_scalar(2,0,0,89,1,1,work_slot[13],work_slot[14]); end
                    5:begin
                        need(16'h0003); call_scalar(0,0,0,88,2,0,work_slot[0],work_slot[0]);
                        if($signed(work_slot[1])<=0) reject(LOCAL_REJECT,DEGENERATE);
                        else if(work_slot[0]==0) reject(FRAME_FAIL,INTERNAL);
                    end
                    6:begin need(16'h0002); local_write(12,88,0,work_slot[1]<<2); end
                    7:begin need(16'h1000); call_scalar(0,0,0,104,3,0,work_slot[12],192'd65535); if(kind==17) next_step=20; end
                    8:begin need(16'h0004); call_scalar(0,0,0,104,15,0,pf(payload,263,16,0),work_slot[2]); end
                    9:begin need(16'h8008); call_scalar(5,0,0,2,11,0,work_slot[3],work_slot[15]); end
                    10:begin
                        need(16'h0800); call_scalar(0,1,0,99,13,1,pf(payload,151,56,1),pf(payload,108,43,0));
                        if(work_slot[11]==1) reject(LOCAL_REJECT,ILL_CONDITION);
                    end
                    11:call_scalar(0,1,1,100,14,1,pf(payload,64,44,1),pf(payload,207,56,1));
                    12:begin need(16'h6000); call_scalar(2,1,1,101,4,1,work_slot[13],work_slot[14]); end
                    13:call_scalar(0,0,1,99,13,1,pf(payload,21,43,0),pf(payload,207,56,1));
                    14:call_scalar(0,1,1,100,14,1,pf(payload,64,44,1),pf(payload,151,56,1));
                    15:begin need(16'h6000); call_scalar(2,1,1,101,5,1,work_slot[13],work_slot[14]); end
                    16:begin need(16'h0010); local_write(6,105,1,work_slot[4]<<4); end
                    17:begin need(16'h0020); local_write(7,105,1,work_slot[5]<<4); end
                    18:begin need(16'h0042); call_scalar(3,1,0,106,8,1,work_slot[6],work_slot[1]); end
                    19:begin
                        need(16'h0182); call_scalar(3,1,0,106,9,1,work_slot[7],work_slot[1]);
                        if(!fits_slot(work_slot[8],18,1)) reject(LOCAL_REJECT,GEOM_RANGE);
                    end
                    20:begin
                        need(16'h000c); call_scalar(3,0,0,17,10,0,work_slot[3],work_slot[2]);
                        if(kind==11) begin need(16'h0200); if(!fits_slot(work_slot[9],18,1)) reject(LOCAL_REJECT,GEOM_RANGE); end
                    end
                    21:begin
                        need(16'h0400); plan_class=2;
                        if(work_slot[10]>65535) reject(FRAME_FAIL,INTERNAL);
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
                    1:call_scalar(0,0,0,64,13,0,pf(payload,0,21,0),pf(payload,87,43,0));
                    2:call_scalar(0,1,1,66,14,0,pf(payload,21,33,1),pf(payload,21,33,1));
                    3:begin need(16'h6000); call_scalar(2,0,0,67,0,1,work_slot[13],work_slot[14]); end
                    4:call_scalar(0,0,0,64,13,0,pf(payload,0,21,0),pf(payload,130,43,0));
                    5:call_scalar(0,1,1,66,14,0,pf(payload,54,33,1),pf(payload,54,33,1));
                    6:begin need(16'h6000); call_scalar(2,0,0,67,1,1,work_slot[13],work_slot[14]); end
                    7:call_scalar(0,0,1,65,13,1,pf(payload,0,21,0),pf(payload,173,44,1));
                    8:call_scalar(0,1,1,66,14,1,pf(payload,21,33,1),pf(payload,54,33,1));
                    9:begin need(16'h6000); call_scalar(2,1,1,67,2,1,work_slot[13],work_slot[14]); end
                    10:begin
                        need(16'h0003); local_write(subphase==0?0:1,64,0,work_slot[subphase==0?0:1]);
                        if(work_slot[0][191] || work_slot[1][191]) reject(FRAME_FAIL,INTERNAL);
                        if(subphase==0) begin next_step=10; next_phase=1; end
                    end
                    11:begin need(16'h0003); call_scalar(0,0,0,128,13,0,work_slot[0],work_slot[1]); end
                    12:begin need(16'h0004); call_scalar(0,1,1,134,14,0,work_slot[2],work_slot[2]); end
                    13:begin need(16'h6000); call_scalar(5,0,0,2,12,0,work_slot[13],work_slot[14]); end
                    14:begin
                        need(16'h1007);
                        if(subphase==0) begin local_write(2,65,1,work_slot[2]); next_step=14; next_phase=1; end
                        else call_scalar(1,0,0,65,13,0,work_slot[0],work_slot[1]);
                        if(work_slot[12]==1) reject(FRAME_FAIL,INTERNAL);
                    end
                    15:begin need(16'h2000); local_write(14,81,0,work_slot[13]<<16); if(work_slot[13]==0) reject(LOCAL_REJECT,DEGENERATE); end
                    16:begin need(16'h0003); call_scalar(2,0,0,65,3,1,work_slot[0],work_slot[1]); end
                    17:begin need(16'h0004); local_write(4,66,1,work_slot[2]<<1); end
                    18:begin need(16'h0008); call_scalar(0,1,1,130,7,0,work_slot[3],work_slot[3]); end
                    19:begin need(16'h0010); call_scalar(0,1,1,132,8,0,work_slot[4],work_slot[4]); end
                    20:begin need(16'h0180); call_scalar(1,0,0,133,5,0,work_slot[7],work_slot[8]); end
                    21:begin need(16'h0020); local_write(7,165,0,work_slot[5]<<32); if(work_slot[5]==0) reject(LOCAL_REJECT,DEGENERATE); end
                    22:begin need(16'h0080); call_scalar(4,0,0,83,6,0,work_slot[7],0); end
                    23:begin need(16'h0040); call_scalar(0,0,0,99,7,0,work_slot[6],192'd65535); if(kind==18) next_step=26; end
                    24:begin need(16'h4000); call_scalar(0,0,0,97,8,0,pf(payload,217,16,0),work_slot[14]); end
                    25:begin need(16'h0180); call_scalar(5,0,0,2,12,0,work_slot[7],work_slot[8]); end
                    26:begin
                        if(subphase==0) begin
                            need(16'h4080); call_scalar(3,0,0,17,12,0,work_slot[7],work_slot[14]);
                            next_step=26; next_phase=1;
                            if(kind==12) begin need(16'h1000); if(work_slot[12]==1) reject(LOCAL_REJECT,ILL_CONDITION); end
                        end else begin
                            need(16'h1000); local_write(15,34,0,work_slot[12]<<18);
                            if(work_slot[12]>65535) reject(FRAME_FAIL,INTERNAL);
                            if(kind==18) next_step=61;
                        end
                    end
                    27:begin need(16'h0008); local_write(7,81,1,work_slot[3]<<16); end
                    28:begin need(16'h0010); local_write(8,82,1,work_slot[4]<<16); end
                    29:begin
                        need(16'h0048);
                        if($signed(work_slot[3])>=0) call_scalar(1,0,1,85,7,1,work_slot[6],work_slot[7]);
                        else call_scalar(2,0,1,85,3,1,work_slot[6],work_slot[7]);
                    end
                    30:begin
                        if(!negative_branch) begin need(16'h0100); local_write(8,85,1,work_slot[8]); end
                        else if(subphase==0) begin need(16'h0100); local_write(7,85,1,work_slot[8]); next_step=30; next_phase=1; end
                        else begin need(16'h0008); local_write(8,85,1,work_slot[3]); end
                    end
                    31:begin need(16'h0080); call_scalar(0,1,1,170,13,0,work_slot[7],work_slot[7]); end
                    32:begin need(16'h0100); call_scalar(0,1,1,170,14,0,work_slot[8],work_slot[8]); end
                    33:begin need(16'h6000); call_scalar(1,0,0,171,12,0,work_slot[13],work_slot[14]); end
                    34:begin need(16'h1000); call_scalar(4,0,0,86,9,0,work_slot[12],0); end
                    35:begin need(16'h0280); local_write(13,115,1,work_slot[7]<<30); if(work_slot[9]==0) reject(FRAME_FAIL,INTERNAL); end
                    36:begin need(16'h2200); call_scalar(3,1,0,116,7,1,work_slot[13],work_slot[9]); end
                    37:begin need(16'h0180); local_write(14,115,1,work_slot[8]<<30);
                        if($signed(work_slot[7]) < -192'sd1073741824 || $signed(work_slot[7]) >192'sd1073741824) reject(FRAME_FAIL,INTERNAL); end
                    38:begin need(16'h4200); call_scalar(3,1,0,116,8,1,work_slot[14],work_slot[9]); end
                    39:begin
                        need(16'h0180); local_write(subphase==0?10:11,32,1,subphase==0?-work_slot[8]:work_slot[7]);
                        if($signed(work_slot[8]) < -192'sd1073741824 || $signed(work_slot[8]) >192'sd1073741824) reject(FRAME_FAIL,INTERNAL);
                        if(subphase==0) begin next_step=39; next_phase=1; end
                    end
                    40:begin
                        need(16'h0c00);
                        if(subphase==0) begin
                            local_write(10,32,1,($signed(work_slot[11])<0 || (work_slot[11]==0 && $signed(work_slot[10])<0))?-work_slot[10]:work_slot[10]);
                            next_step=40; next_phase=1;
                        end else local_write(11,32,1,negative_branch?-work_slot[11]:work_slot[11]);
                    end
                    41:begin need(16'h0400); call_scalar(0,1,1,65,13,1,work_slot[10],pf(payload,21,33,1)); end
                    42:begin need(16'h0800); call_scalar(0,1,1,65,7,1,work_slot[11],pf(payload,54,33,1)); end
                    43:begin need(16'h2080); call_scalar(1,1,1,66,3,1,work_slot[13],work_slot[7]); end
                    44:begin need(16'h0400); call_scalar(0,1,0,44,13,1,work_slot[10],{181'd0,held_request[W_LO+:11]}-192'd1); end
                    45:begin need(16'h0800); call_scalar(0,1,0,44,7,1,work_slot[11],{181'd0,held_request[H_LO+:11]}-192'd1); end
                    46:begin need(16'h2080); call_scalar(1,1,1,45,8,1,work_slot[13],work_slot[7]); end
                    47:begin need(16'h0100); call_scalar(0,1,0,67,13,1,work_slot[8],pf(payload,0,21,0)); end
                    48:begin need(16'h2008); call_scalar(1,1,1,68,3,1,work_slot[3],work_slot[13]); end
                    49:begin need(16'h0008); local_write(3,69,1,work_slot[3]<<3); end
                    50:local_write(4,52,0,pf(payload,0,21,0)<<30);
                    51:begin
                        if(subphase==0) begin need(16'h0018); call_scalar(3,1,0,70,14,1,work_slot[3],work_slot[4]); next_step=51; next_phase=1; end
                        else begin need(16'h4000); geometry(14,work_slot[14]); end
                    end
                    52:begin need(16'h0800); call_scalar(0,1,1,65,13,1,work_slot[11],pf(payload,21,33,1)); end
                    53:begin need(16'h0400); call_scalar(0,1,1,65,7,1,work_slot[10],pf(payload,54,33,1)); end
                    54:begin need(16'h2080); call_scalar(2,1,1,66,8,1,work_slot[13],work_slot[7]); end
                    55:begin need(16'h0100); local_write(8,69,1,work_slot[8]<<3); end
                    56:begin
                        if(subphase==0) begin need(16'h0110); call_scalar(3,1,0,70,9,1,work_slot[8],work_slot[4]); next_step=56; next_phase=1; end
                        else begin
                            need(16'h8200); local_write(15,34,0,{158'd0,work_slot[15][33:18],work_slot[9][17:0]});
                            if(!anis_valid) reject(FRAME_FAIL,INTERNAL);
                            if(!fits_slot(work_slot[9],18,1)) reject(LOCAL_REJECT,GEOM_RANGE);
                        end
                    end
                    57:begin need(16'h0400); call_scalar(0,1,1,64,13,0,work_slot[10],work_slot[10]); end
                    58:begin need(16'h0800); call_scalar(0,1,1,64,7,0,work_slot[11],work_slot[11]); end
                    59:begin need(16'h2080); call_scalar(1,0,0,65,12,0,work_slot[13],work_slot[7]); end
                    60:begin need(16'h1000); call_scalar(4,0,0,33,13,0,work_slot[12],0);
                        if(work_slot[12]<(192'd1<<58)) reject(FRAME_FAIL,INTERNAL); end
                    61:begin
                        need(16'h8000); plan_class=2;
                        if(!anis_valid) reject(FRAME_FAIL,INTERNAL);
                        if(kind==18) begin plan_value[0+:21]=payload[20:0]; plan_value[21+:16]=work_slot[15][33:18]; end
                        else begin
                            need(16'hfc00); if(!mu_valid || work_slot[13]==0) reject(FRAME_FAIL,INTERNAL);
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
                    1:call_scalar(0,1,1,64,13,0,pf(payload,0,32,1),pf(payload,0,32,1));
                    2:call_scalar(0,1,1,64,14,0,pf(payload,32,32,1),pf(payload,32,32,1));
                    3:begin need(16'h6000); call_scalar(1,0,0,65,12,0,work_slot[13],work_slot[14]); end
                    4:begin need(16'h1000); call_scalar(0,1,1,64,13,0,pf(payload,82,32,1),pf(payload,82,32,1)); if(work_slot[12]<(192'd1<<58)) reject(FRAME_FAIL,INTERNAL); end
                    5:call_scalar(0,1,1,64,14,0,pf(payload,114,32,1),pf(payload,114,32,1));
                    6:begin need(16'h6000); call_scalar(1,0,0,65,12,0,work_slot[13],work_slot[14]); end
                    7:begin need(16'h1000); call_scalar(0,1,1,64,13,1,pf(payload,0,32,1),pf(payload,114,32,1)); if(work_slot[12]<(192'd1<<58)) reject(FRAME_FAIL,INTERNAL); end
                    8:call_scalar(0,1,1,64,14,1,pf(payload,32,32,1),pf(payload,82,32,1));
                    9:begin need(16'h6000); call_scalar(2,1,1,65,0,1,work_slot[13],work_slot[14]); end
                    10:begin need(16'h0001); call_scalar(0,1,1,50,13,1,pf(payload,64,18,1),pf(payload,114,32,1)); if(work_slot[0]==0) reject(LOCAL_REJECT,DEGENERATE); end
                    11:call_scalar(0,1,1,50,14,1,pf(payload,146,18,1),pf(payload,32,32,1));
                    12:begin need(16'h6000); call_scalar(2,1,1,51,1,1,work_slot[13],work_slot[14]); end
                    13:begin need(16'h0002); local_write(1,81,1,work_slot[1]<<30); end
                    14:call_scalar(0,1,1,50,13,1,pf(payload,0,32,1),pf(payload,146,18,1));
                    15:call_scalar(0,1,1,50,14,1,pf(payload,82,32,1),pf(payload,64,18,1));
                    16:begin need(16'h6000); call_scalar(2,1,1,51,2,1,work_slot[13],work_slot[14]); end
                    17:begin need(16'h0004); local_write(2,81,1,work_slot[2]<<30); end
                    18:begin
                        need(16'h0007);
                        if(subphase==0) begin local_write(0,65,0,work_slot[0][191]?-work_slot[0]:work_slot[0]); next_step=18; next_phase=1; end
                        else if(subphase==1) begin local_write(1,82,1,negative_branch?-work_slot[1]:work_slot[1]); next_step=18; next_phase=2; end
                        else local_write(2,82,1,negative_branch?-work_slot[2]:work_slot[2]);
                    end
                    19:begin need(16'h0003); call_scalar(3,1,0,83,3,1,work_slot[1],work_slot[0]); end
                    20:begin need(16'h000d); call_scalar(3,1,0,83,4,1,work_slot[2],work_slot[0]); if(!fits_slot(work_slot[3],18,1)) reject(LOCAL_REJECT,GEOM_RANGE); end
                    21:begin need(16'h0018); plan_class=2; plan_value[0+:18]=work_slot[3][17:0]; plan_value[18+:18]=work_slot[4][17:0]; if(!fits_slot(work_slot[4],18,1)) reject(LOCAL_REJECT,GEOM_RANGE); end
                    default:reject(FRAME_FAIL,INTERNAL);
                endcase
            end
            14:begin // D01…25：命中只跳四个K/M调用；边界比较始终全宽。
                case(step)
                    1:begin
                        if(cache_hit) begin local_write(0,65,0,{127'd0,cache_k[hit_index]}); next_step=2; next_phase=1; end
                        else call_scalar(0,1,1,64,13,0,pf(payload,0,32,1),pf(payload,0,32,1));
                    end
                    2:begin
                        if(subphase==1) begin local_write(1,33,0,{159'd0,cache_m[hit_index]}); next_step=5; end
                        else call_scalar(0,1,1,64,14,0,pf(payload,32,32,1),pf(payload,32,32,1));
                    end
                    3:begin need(16'h6000); call_scalar(1,0,0,65,0,0,work_slot[13],work_slot[14]); end
                    4:begin need(16'h0001); call_scalar(4,0,0,33,1,0,work_slot[0],0); if(work_slot[0]<(192'd1<<58)) reject(FRAME_FAIL,INTERNAL); end
                    5:begin need(16'h0003); call_scalar(0,1,0,43,13,1,pf(payload,0,32,1),pf(payload,82,11,0)); if(work_slot[0]<(192'd1<<58) || work_slot[1]==0) reject(FRAME_FAIL,INTERNAL); end
                    6:call_scalar(0,1,0,43,14,1,pf(payload,32,32,1),pf(payload,93,11,0));
                    7:begin need(16'h6000); call_scalar(1,1,1,44,2,1,work_slot[13],work_slot[14]); end
                    8:begin need(16'h0004); local_write(2,48,1,work_slot[2]<<4); end
                    9:local_write(13,48,1,pf(payload,64,18,1)<<30);
                    10:begin need(16'h2004); call_scalar(2,1,1,50,2,1,work_slot[2],work_slot[13]); end
                    11:begin need(16'h0004); local_write(13,50,0,work_slot[2][191]?-work_slot[2]:work_slot[2]); end
                    12:begin need(16'h2002); call_scalar(3,0,0,21,3,0,work_slot[13],work_slot[1]); end
                    13:begin need(16'h0004); call_scalar(0,1,1,100,14,0,work_slot[2],work_slot[2]); end
                    14:begin need(16'h4000); local_write(4,102,0,work_slot[14]<<2); end
                    15:begin
                        need(16'h0008); local_write(5,22,0,line_odd_boundary(work_slot[3][20:0],0));
                        if(work_slot[3]==0) begin local_write(5,22,0,0); next_step=19; end
                    end
                    16:begin need(16'h0020); call_scalar(0,0,0,44,6,0,work_slot[5],work_slot[5]); end
                    17:begin need(16'h0041); call_scalar(0,0,0,109,7,0,work_slot[6],work_slot[0]); end
                    18:begin
                        need(16'h0090);
                        if(subphase==0) begin call_scalar(5,0,0,2,15,0,work_slot[4],work_slot[7]); next_step=18; next_phase=1; end
                        else begin
                            need(16'h8008); local_write(3,21,0,work_slot[3]);
                            if(work_slot[15]==1 || (work_slot[15]==0 && work_slot[3][0])) begin local_write(3,21,0,line_neighbor(work_slot[3][20:0],0)); next_step=24; end
                        end
                    end
                    19:begin need(16'h0008); local_write(5,22,0,line_odd_boundary(work_slot[3][20:0],1)); end
                    20:begin need(16'h0020); call_scalar(0,0,0,44,6,0,work_slot[5],work_slot[5]); end
                    21:begin need(16'h0041); call_scalar(0,0,0,109,7,0,work_slot[6],work_slot[0]); end
                    22:begin need(16'h0090); call_scalar(5,0,0,2,15,0,work_slot[4],work_slot[7]); end
                    23:begin
                        need(16'h8008); local_write(3,21,0,work_slot[3]);
                        if(work_slot[15]==2 || (work_slot[15]==0 && work_slot[3][0])) local_write(3,21,0,line_neighbor(work_slot[3][20:0],1));
                    end
                    24:begin
                        need(16'h0009); next_step=24; next_phase=subphase+4'd1;
                        case(subphase)
                            0:local_write(5,22,0,(work_slot[3]<<1)+192'd1);
                            1:begin need(16'h0020); call_scalar(0,0,0,44,6,0,work_slot[5],work_slot[5]); end
                            2:begin need(16'h0040); call_scalar(0,0,0,109,7,0,work_slot[6],work_slot[0]); end
                            3:begin need(16'h0090); call_scalar(5,0,0,2,15,0,work_slot[4],work_slot[7]); end
                            4:begin
                                need(16'h8000); local_write(5,22,0,(work_slot[3]<<1)-192'd1);
                                if(!qualify_distance_bounds(work_slot[3][20:0],work_slot[15][1:0],1)) reject(FRAME_FAIL,INTERNAL);
                                if(work_slot[3]==0) begin next_step=25; next_phase=0; local_write(5,22,0,0); end
                            end
                            5:begin need(16'h0020); call_scalar(0,0,0,44,6,0,work_slot[5],work_slot[5]); end
                            6:begin need(16'h0040); call_scalar(0,0,0,109,7,0,work_slot[6],work_slot[0]); end
                            7:begin need(16'h0090); call_scalar(5,0,0,2,15,0,work_slot[4],work_slot[7]); end
                            8:begin
                                need(16'h8000); local_write(3,21,0,work_slot[3]); next_step=25; next_phase=0;
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
                    1:call_scalar(2,0,1,19,0,1,pf(payload,72,11,0)<<4,pf(payload,0,18,1));
                    2:call_scalar(2,0,1,19,1,1,pf(payload,83,11,0)<<4,pf(payload,18,18,1));
                    3:call_scalar(2,1,1,19,2,1,pf(payload,36,18,1),pf(payload,0,18,1));
                    4:call_scalar(2,1,1,19,3,1,pf(payload,54,18,1),pf(payload,18,18,1));
                    5:begin need(16'h0004); call_scalar(0,1,1,38,13,0,work_slot[2],work_slot[2]); end
                    6:begin need(16'h0008); call_scalar(0,1,1,38,14,0,work_slot[3],work_slot[3]); end
                    7:begin need(16'h6000); call_scalar(1,0,0,39,4,0,work_slot[13],work_slot[14]); end
                    8:begin need(16'h0015); call_scalar(0,1,1,38,13,1,work_slot[0],work_slot[2]); if(work_slot[4]==0) reject(LOCAL_REJECT,DEGENERATE); end
                    9:begin need(16'h000a); call_scalar(0,1,1,38,14,1,work_slot[1],work_slot[3]); end
                    10:begin need(16'h6000); call_scalar(1,1,1,39,5,1,work_slot[13],work_slot[14]); end
                    11:begin
                        need(16'h003f); next_step=11; next_phase=subphase+4'd1;
                        if($signed(work_slot[5])<=0 || $signed(work_slot[5])>=$signed(work_slot[4])) begin
                            case(subphase)
                                0:begin
                                    if($signed(work_slot[5])>=$signed(work_slot[4])) call_scalar(2,0,1,19,0,1,pf(payload,72,11,0)<<4,pf(payload,36,18,1));
                                    else begin local_write(0,19,1,work_slot[0]); next_phase=2; end
                                end
                                1:call_scalar(2,0,1,19,1,1,pf(payload,83,11,0)<<4,pf(payload,54,18,1));
                                2:call_scalar(0,1,1,38,13,0,work_slot[0],work_slot[0]);
                                3:call_scalar(0,1,1,38,14,0,work_slot[1],work_slot[1]);
                                4:begin need(16'h6000); call_scalar(1,0,0,39,7,0,work_slot[13],work_slot[14]); end
                                5:begin local_write(8,39,0,192'd1); next_step=12; next_phase=0; end
                                default:reject(FRAME_FAIL,INTERNAL);
                            endcase
                        end else begin
                            case(subphase)
                                0:call_scalar(0,1,1,38,13,1,work_slot[0],work_slot[3]);
                                1:call_scalar(0,1,1,38,14,1,work_slot[1],work_slot[2]);
                                2:begin need(16'h6000); call_scalar(2,1,1,39,6,1,work_slot[13],work_slot[14]); end
                                3:begin need(16'h0040); call_scalar(0,1,1,78,7,0,work_slot[6],work_slot[6]); end
                                4:begin local_write(8,39,0,work_slot[4]); next_step=12; next_phase=0; end
                                default:reject(FRAME_FAIL,INTERNAL);
                            endcase
                        end
                    end
                    12:begin need(16'h0080); local_write(9,80,0,work_slot[7]<<2); end
                    13:begin need(16'h0180); call_scalar(6,0,0,37,10,0,work_slot[7],work_slot[8]); if(work_slot[8]==0) reject(FRAME_FAIL,INTERNAL); end
                    14:begin need(16'h0400); call_scalar(7,0,0,19,11,0,work_slot[10],0); end
                    15:begin need(16'h0800); local_write(6,20,0,finite_odd_boundary(work_slot[11][18:0],1)); end
                    16:begin need(16'h0040); call_scalar(0,0,0,40,13,0,work_slot[6],work_slot[6]); end
                    17:begin need(16'h2100); call_scalar(0,0,0,79,13,0,work_slot[13],work_slot[8]); end
                    18:begin need(16'h2200); call_scalar(5,0,0,2,15,0,work_slot[9],work_slot[13]); end
                    19:begin need(16'h8800); local_write(12,19,0,{172'd0,choose_midpoint_even(work_slot[11][18:0],work_slot[15][1:0])}); end
                    20,21:begin
                        need(16'h1100); next_step=step; next_phase=subphase+4'd1;
                        case(subphase)
                            0:begin
                                local_write(6,20,0,finite_odd_boundary(work_slot[12][18:0],step==20));
                                if(step==21 && work_slot[12]==0) begin local_write(6,20,0,0); next_step=22; next_phase=0; end
                            end
                            1:begin need(16'h0040); call_scalar(0,0,0,40,13,0,work_slot[6],work_slot[6]); end
                            2:begin need(16'h2000); call_scalar(0,0,0,79,13,0,work_slot[13],work_slot[8]); end
                            3:begin need(16'h2200); call_scalar(5,0,0,2,15,0,work_slot[9],work_slot[13]); end
                            4:begin
                                need(16'h8000); local_write(12,19,0,work_slot[12]); next_step=step+7'd1; next_phase=0;
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
        if((slot_valid & required_slots)!=required_slots) reject(FRAME_FAIL,INTERNAL);
        if(plan_class==1 && !fits_slot(plan_local,plan_width,plan_signed)) reject(FRAME_FAIL,OVERFLOW);
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            state<=IDLE; held_request<=0; response_value<=0; response_outcome<=VALUE; response_reason<=NONE;
            slot_valid<=0; anis_valid<=0; mu_valid<=0; step<=1; subphase<=0;
            pending_next_step<=1; pending_next_phase<=0; negative_branch<=0; outer_cancel<=0;
            command_published<=0; cmd_pending<=0; published_command<=0;
            reserved_destination<=0; reserved_width<=1; reserved_signed<=0; return_signed<=0;
            cache_valid<=0; replacement<=0;
        end else begin
            // 已经公开的握手先记真实fire；取消不撤回消息、不抢改HELD。
            if(cmd_fire) begin command_published<=0; cmd_pending<=1; end
            if(result_fire) cmd_pending<=0;
            if(matching_cancel && state!=IDLE) begin outer_cancel<=1; state<=DRAIN; end
            else case(state)
                IDLE:if(req_valid && req_ready) begin
                    held_request<=req_body; slot_valid<=0; anis_valid<=0; mu_valid<=0;
                    step<=1; subphase<=0; response_value<=0; response_outcome<=VALUE; response_reason<=NONE;
                    outer_cancel<=matching_cancel; state<=matching_cancel?DRAIN:CHECK;
                end
                CHECK:begin
                    if(input_check!=0) begin response_outcome<=input_check[1:0]; response_reason<=input_check[9:2]; state<=DRAIN; end
                    else state<=PREPARE;
                end
                PREPARE:begin
                    if(plan_class==0) begin
                        published_command<=plan_command; command_published<=1;
                        reserved_destination<=plan_destination; reserved_width<=plan_width;
                        reserved_signed<=plan_signed; return_signed<=plan_return_signed;
                        pending_next_step<=next_step; pending_next_phase<=next_phase;
                        if(kind==12 && step==29) negative_branch<=work_slot[3][191];
                        state<=ISSUE;
                    end else if(plan_class==1) state<=LOCAL_COMMIT;
                    else if(plan_class==2) begin response_value<=plan_value; state<=PACK; end
                    else begin response_outcome<=plan_outcome; response_reason<=plan_reason; state<=DRAIN; end
                end
                ISSUE:if(cmd_fire) state<=WAIT_RETURN;
                WAIT_RETURN:if(bridge_valid) state<=QUALIFY_RETURN;
                QUALIFY_RETURN:if(result_fire) begin
                    if(!cmd_pending || bridge_result[7:0]!={4'd0,reserved_destination}) begin response_outcome<=FRAME_FAIL; response_reason<=INTERNAL; state<=DRAIN; end
                    else if(bridge_result[8+:2]!=VALUE || bridge_result[10+:8]!=NONE) begin
                        response_outcome<=FRAME_FAIL; response_reason<=bridge_result[10+:8]; state<=DRAIN;
                    end else if(!fits_return(bridge_result[18+:385],reserved_width,return_signed)) begin
                        response_outcome<=FRAME_FAIL; response_reason<=OVERFLOW; state<=DRAIN;
                    end else if(!reserved_signed && bridge_result[402]) begin
                        response_outcome<=FRAME_FAIL; response_reason<=INTERNAL; state<=DRAIN;
                    end else if(!fits_slot(bridge_result[18+:192],reserved_width,reserved_signed)) begin
                        response_outcome<=FRAME_FAIL; response_reason<=OVERFLOW; state<=DRAIN;
                    end else if(published_command[8+:3]==5 && bridge_result[18+:385]>2) begin
                        response_outcome<=FRAME_FAIL; response_reason<=INTERNAL; state<=DRAIN;
                    end else begin
                        // 行号在展开后为常量；每沿只有预约目的的一行写使能，不增加逻辑写入次数。
                        for(integer row=0;row<16;row=row+1)
                            if(reserved_destination==row[3:0]) work_slot[row]<=canonical_slot(bridge_result[18+:192],row[3:0]);
                        slot_valid[reserved_destination]<=1;
                        if((kind==14 && step==4) || (kind==12 && step==60)) begin
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
                ADVANCE:begin step<=pending_next_step; subphase<=pending_next_phase; state<=PREPARE; end
                LOCAL_COMMIT:begin
                    if(plan_class!=1) begin response_outcome<=plan_outcome; response_reason<=plan_reason; state<=DRAIN; end
                    else begin
                        for(integer row=0;row<16;row=row+1)
                            if(plan_destination==row[3:0]) work_slot[row]<=canonical_slot(plan_local,row[3:0]);
                        slot_valid[plan_destination]<=1;
                        if((kind==12 || kind==18) && step==26 && subphase==1) anis_valid<=1;
                        if(kind==12 && step==56 && subphase==1) mu_valid<=1;
                        if(kind==12 && step==40 && subphase==0)
                            negative_branch<=($signed(work_slot[11])<0 || (work_slot[11]==0 && $signed(work_slot[10])<0));
                        if(kind==13 && step==18 && subphase==0) negative_branch<=work_slot[0][191];
                        step<=next_step; subphase<=next_phase; state<=PREPARE;
                    end
                end
                DRAIN:if(!command_published && !cmd_pending && bridge_quiet) begin
                    response_value<=0;
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
