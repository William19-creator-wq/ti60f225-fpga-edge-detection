// 全部a<b anchor点对：梯度法线交点/条件门/两个半径/RNE平均，保留256个distinct最小rank。
// 原生DDR读回完整anchor；算术复用父级唯一scalar。全部点对、排序、256记录和META写回复结清才done。
module board_circle_seeds #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter [32:0] ADDRESS_BYTES=33'h10000000,
    parameter string PROGRAM_FILE="board/recognition_numeric/circle_seed_program.mem",
    parameter bit DSP_RECORDS=1'b0,
    parameter bit BORROW_SCOPE=1'b0
)(
    input wire clk,rst,start,input wire [95:0] scope,input wire [20:0] points,
    input wire [9:0] anchors,input wire [31:0] anchor_base,seed_base,
    output wire start_ready,done,output reg fault,output reg [8:0] seed_count,
    output reg [18:0] pairs_visited,legal_occurrences,local_rejected,geometry_rejected,
    output reg [18:0] duplicates,rank_pruned,rank_replaced,
    output wire req_valid,input wire req_ready,output wire req_write,output wire [31:0] req_addr,
    input wire rsp_valid,output wire rsp_ready,input wire [511:0] rsp_data,
    input wire rsp_error,rsp_drained,
    output wire pack_valid,output wire [2:0] pack_index,output wire [63:0] pack_data,
    output wire num_req_valid,input wire num_req_ready,output wire [621:0] num_req_body,
    input wire num_rsp_valid,output wire num_rsp_ready,input wire [584:0] num_rsp_body,
    input wire num_quiet
);
    localparam IDLE=0,LOAD_REQ=1,LOAD_RSP=2,PA_READ=3,PA_CAPTURE=4,PB_READ=5,PB_CAPTURE=6,
        PROGRAM_READ=7,PROGRAM_CAPTURE=8,A_READ=9,A_CAPTURE=10,B_READ=11,B_CAPTURE=12,
        NUM_REQUEST=13,NUM_WAIT=14,NUM_SCAN=15,REG_WRITE=16,NUM_CLOSE=17,PAIR_NEXT=18,
        SEED_READ=19,SEED_CAPTURE=20,SEED_CHOOSE=21,SEED_WRITE=22,SORT_SETUP=23,
        SORT_READ=24,SORT_CAPTURE=25,SORT_PREV_READ=26,SORT_PREV_CAPTURE=27,
        SORT_SHIFT=28,SORT_INSERT=29,EXPORT_READ=30,EXPORT_CAPTURE=31,EXPORT_LOW=32,
        EXPORT_HIGH=33,WRITE_REQ=34,WRITE_RSP=35,META_PACK=36,COMPLETE=37,FAILED=38,
        CLEAR=39,FINAL_QUIET=40,TABLE_READ=41,TABLE_CAPTURE=42;
    reg [5:0] state,pc,table_return;
    reg [2:0] table_word;
    reg [7:0] table_row;
    wire [95:0] locked_scope;
    reg [20:0] point_limit;
    reg [9:0] anchor_limit,loaded,pair_a,pair_b;
    reg [31:0] address,locked_seed_base;
    reg [2:0] load_lane,word,fill;
    reg [7:0] clear_index,scan_index,worst_index,write_index,export_index;
    reg [8:0] sort_index,sort_position;
    reg [63:0] point_a,point_b;
    // 数值调用关闭后才进入候选扫描/排序，两个阶段复用同样的全128位暂存。
    wire [127:0] numeric_or_candidate,numeric_or_worst;
    wire [127:0] operand_a=numeric_or_candidate,selected_record=numeric_or_candidate;
    wire [127:0] operand_b=numeric_or_worst,worst_record=numeric_or_worst;
    reg [17:0] center_x,center_y;
    reg [52:0] candidate_key;
    reg [63:0] hash_temporary;
    reg denominator_negative,have_worst;
    reg [15:0] register_valid;
    reg [23:0] call_counter,pending_call;
    reg [1:0] after_numeric;
    reg [4:0] scan_word;
    reg scan_bad,is_meta;
    reg [31:0] instruction;
    // 指令低到高：op3/srcA6/srcB6/dst4/aS/bS/storeS/storeBits8/mod64/geometry-domain。
    reg [31:0] program_memory[0:63],program_q;
    initial $readmemh(PROGRAM_FILE,program_memory);
    always @(posedge clk)program_q<=program_memory[pc];
    wire [2:0] opcode=instruction[2:0];
    wire [5:0] source_a=instruction[8:3],source_b=instruction[14:9];
    wire [3:0] destination=instruction[18:15];
    wire a_signed=instruction[19],b_signed=instruction[20],stored_signed=instruction[21];
    wire [7:0] stored_bits=instruction[29:22];
    wire modulo64=instruction[30],geometry_domain=instruction[31];
    // scalar各kind的公开返回域不同：COMPARE为2，SQRT_RNE最多97，其它本阶段用192。
    wire [8:0] requested_target=opcode==5?9'd2:opcode==4?9'd97:9'd192;
    wire [175:0] offered_id={8'd2,40'd0,call_counter,8'd0,locked_scope};
    wire [175:0] expected_id={8'd2,40'd0,pending_call,8'd0,locked_scope};
    // 有效请求仍公开offered ID；接受后改用同值pending ID，保持scalar借用header到真实关闭。
    wire [175:0] request_id=state==NUM_REQUEST?offered_id:expected_id;
    assign num_req_body={16'd0,{{64{b_signed&&operand_b[127]}},operand_b},
        {{64{a_signed&&operand_a[127]}},operand_a},requested_target,b_signed,a_signed,2'd0,opcode,
        8'd1,11'(HEIGHT),11'(WIDTH),request_id};
    assign num_req_valid=!rst&&state==NUM_REQUEST&&call_counter!=24'hffffff;
    assign num_rsp_ready=!rst&&state==NUM_CLOSE;
    assign start_ready=!rst&&(state==IDLE||state==COMPLETE)&&num_quiet;
    generate if(BORROW_SCOPE)begin:borrow_scope
        // 板端父actor持有同帧scope至META写回与numquiet完成；COMPLETE无有效正文。
        assign locked_scope=scope;
    end else begin:copy_scope
        reg [95:0] snapshot;
        assign locked_scope=snapshot;
        always @(posedge clk)begin
            if(rst)snapshot<=0;
            else if(start&&start_ready)snapshot<=scope;
        end
    end endgenerate
    assign done=!rst&&state==COMPLETE;
    assign req_valid=!rst&&(state==LOAD_REQ||state==WRITE_REQ);
    assign req_write=state==WRITE_REQ;
    assign req_addr=address;
    wire [63:0] load_point=rsp_data[load_lane*64+:64];
    wire signed [10:0] load_gx=load_point[10:0],load_gy=load_point[21:11];
    wire [10:0] load_ax=load_gx[10]?-load_gx:load_gx,load_ay=load_gy[10]?-load_gy:load_gy;
    wire load_legal=load_point[63]==0&&load_point[31:24]==0&&load_point[42:32]<WIDTH&&
        load_point[53:43]<HEIGHT&&load_gx>=-11'sd1020&&load_gx<=11'sd1020&&
        load_gy>=-11'sd1020&&load_gy<=11'sd1020&&load_point[21:0]!=0&&
        ({1'b0,load_ax}+{1'b0,load_ay})<=12'd1530;
    wire load_good=loaded<anchor_limit?load_legal:load_point==0;
    assign rsp_ready=!rst&&(state==WRITE_RSP||
        (state==LOAD_RSP&&(load_lane==7||rsp_error||!rsp_drained||!load_good)));

    // 实际DDR记录全部读/核验后才进入点对循环，末物理块padding也逐字核验。
    reg [63:0] anchor_memory[0:767],anchor_q;
    wire [9:0] anchor_read_address=(state==PB_READ||state==PB_CAPTURE)?pair_b:pair_a;
    always @(posedge clk)begin
        anchor_q<=anchor_memory[anchor_read_address];
        if(!rst&&state==LOAD_RSP&&rsp_valid&&rsp_drained&&!rsp_error&&loaded<anchor_limit&&load_legal)
            anchor_memory[loaded]<=load_point;
    end
    // 16个完整128位工作值按16bit words存一块RAM。此阶段最大真值112bit，完整385位先核再写。
    reg [15:0] work_memory[0:127],work_q;
    wire [5:0] operand_source=(state==B_READ||state==B_CAPTURE)?source_b:source_a;
    wire [6:0] work_read_address={operand_source[3:0],word};
    wire [127:0] response_low=num_rsp_body[200+:128];
    wire [15:0] response_write_word=modulo64&&word>=4?16'd0:response_low[word*16+:16];
    always @(posedge clk)begin
        work_q<=work_memory[work_read_address];
        if(!rst&&state==REG_WRITE&&num_rsp_valid)work_memory[{destination,word}]<=response_write_word;
    end
    function automatic [127:0] constant_source(input reg [5:0] source);
        begin
            constant_source=0;
            case(source)
                16:constant_source=0;
                17:constant_source=128'd1;
                18:constant_source=128'd2;
                19:constant_source=128'd4294836225;
                20:constant_source=128'd1048576;
                21:constant_source=128'd4296015875;
                22:constant_source=128'd140737488355333;
                23:constant_source=denominator_negative?{128{1'b1}}:128'd1;
                24:constant_source={{117{point_a[10]}},point_a[10:0]};
                25:constant_source={{117{point_a[21]}},point_a[21:11]};
                26:constant_source={{117{point_b[10]}},point_b[10:0]};
                27:constant_source={{117{point_b[21]}},point_b[21:11]};
                28:constant_source={113'd0,point_a[42:32],4'd0};
                29:constant_source={113'd0,point_a[53:43],4'd0};
                30:constant_source={113'd0,point_b[42:32],4'd0};
                31:constant_source={113'd0,point_b[53:43],4'd0};
                32:constant_source={75'd0,candidate_key}^{75'd0,candidate_key>>23};
                33:constant_source={64'd0,hash_temporary^(hash_temporary>>29)};
                default:begin end
            endcase
        end
    endfunction
    // 两个操作数分沿加载，同一来源选择树即可服务A/B，避免重复128位常量MUX。
    wire [127:0] operand_constant=constant_source(operand_source);
    wire result_extension=stored_signed&&num_rsp_body[584];
    wire [399:0] result_view={{15{result_extension}},num_rsp_body[584:200]};
    wire [15:0] result_piece=result_view[scan_word*16+:16];
    wire [8:0] result_cutoff={1'b0,stored_bits}-(stored_signed?9'd1:9'd0);
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
    reg piece_bad;
    always @*begin
        piece_bad=word_extension_bad(result_piece,scan_word,result_cutoff,result_extension);
    end
    // 完整128位记录拆为8个16位字；扫描、排序和导出均读完整记录。
    reg [15:0] seed_memory[0:2047],table_q;
    wire [127:0] seed_q;
    wire table_write=state==CLEAR||state==SEED_WRITE||state==SORT_SHIFT||state==SORT_INSERT;
    wire [7:0] table_write_row=state==CLEAR?clear_index:state==SEED_WRITE?write_index:sort_position[7:0];
    wire [127:0] table_write_record=state==SORT_SHIFT?seed_q:selected_record;
    wire [15:0] table_write_data=state==CLEAR?16'd0:table_write_record[table_word*16+:16];
    function automatic less_seed(input reg [127:0] a,b);
        less_seed=a[116:53]<b[116:53]||(a[116:53]==b[116:53]&&a[52:0]<b[52:0]);
    endfunction
    always @(posedge clk)begin
        table_q<=seed_memory[{table_row,table_word}];
        if(!rst&&table_write)seed_memory[{table_write_row,table_word}]<=table_write_data;
    end
    reg [511:0] metadata;
    always @*begin
        metadata=0;
        metadata[95:0]=locked_scope;metadata[116:96]=point_limit;metadata[126:117]=anchor_limit;
        metadata[135:127]=seed_count;metadata[154:136]=pairs_visited;metadata[173:155]=legal_occurrences;
        metadata[192:174]=local_rejected;metadata[211:193]=geometry_rejected;metadata[230:212]=duplicates;
        metadata[249:231]=rank_pruned;metadata[268:250]=rank_replaced;metadata[292:269]=call_counter;
        metadata[300:293]=8'd1;metadata[311:301]=11'(WIDTH);metadata[322:312]=11'(HEIGHT);metadata[323]=1;
    end
    assign pack_valid=!rst&&(state==EXPORT_LOW||state==EXPORT_HIGH||state==META_PACK);
    assign pack_index=fill;
    assign pack_data=state==META_PACK?metadata[fill*64+:64]:state==EXPORT_HIGH?seed_q[127:64]:seed_q[63:0];
    wire [19:0] expected_pairs=anchor_limit<2?20'd0:
        (({10'd0,anchor_limit}*({10'd0,anchor_limit}-20'd1))>>1);

    // 三个完整记录的写沿仍由原state/guard决定，数值调用期间保持两个操作数alias。
    // 不复位正文；完整8字加载及原状态检查隔离尚未组装的记录。
    wire [383:0] held_records;
    reg [383:0] record_input;
    reg [2:0] record_write;
    assign numeric_or_candidate=held_records[127:0];
    assign numeric_or_worst=held_records[255:128];
    assign seed_q=held_records[383:256];
    always @*begin
        record_input=0;record_write=0;
        if(rst)begin end
        else if(start&&start_ready)begin end
        else case(state)
            PROGRAM_READ:if(pc==47)begin
                record_write[0]=1;
                record_input[127:0]={10'd0,1'b1,hash_temporary^(hash_temporary>>31),candidate_key};
            end
            A_CAPTURE:begin
                record_write[0]=1;
                if(source_a>=16)record_input[127:0]=operand_constant;
                else record_input[127:0]={work_q,numeric_or_candidate[127:16]};
            end
            B_CAPTURE:begin
                record_write[1]=1;
                if(source_b>=16)record_input[255:128]=operand_constant;
                else record_input[255:128]={work_q,numeric_or_worst[127:16]};
            end
            TABLE_CAPTURE:begin
                record_write[2]=1;
                record_input[383:256]={table_q,seed_q[127:16]};
            end
            SEED_CAPTURE:begin
                if(seed_q[127:118]!=0||(!seed_q[117]&&seed_q!=0))begin end
                else if(seed_q[117]&&seed_q[52:0]==candidate_key)begin end
                else if(seed_q[117]&&(!have_worst||less_seed(worst_record,seed_q)))begin
                    record_write[1]=1;record_input[255:128]=seed_q;
                end
            end
            SORT_CAPTURE:begin
                if(!seed_q[117])begin end
                else begin record_write[0]=1;record_input[127:0]=seed_q;end
            end
            default:begin end
        endcase
    end
    generate for(genvar bank=0;bank<3;bank++)begin:record_bank
        if(DSP_RECORDS)begin:dsp_record
            // 写资格只由原record_write控制；CE关闭时DI无需再受reset/start/资格零门控。
            // 每个真实写沿的数据仍取同一来源，未写入时由DSP的O寄存器保持原记录。
            wire [127:0] active_input;
            if(bank==0)begin:candidate_input
                assign active_input=state==PROGRAM_READ?
                    {10'd0,1'b1,hash_temporary^(hash_temporary>>31),candidate_key}:
                    state==SORT_CAPTURE?seed_q:
                    source_a>=16?operand_constant:{work_q,numeric_or_candidate[127:16]};
            end else if(bank==1)begin:worst_input
                assign active_input=state==SEED_CAPTURE?seed_q:
                    source_b>=16?operand_constant:{work_q,numeric_or_worst[127:16]};
            end else begin:table_input
                assign active_input={table_q,seed_q[127:16]};
            end
            wire [143:0] padded_input={16'd0,active_input};
            wire [143:0] padded_output;
            assign held_records[bank*128+:128]=padded_output[127:0];
            for(genvar stripe=0;stripe<4;stripe++)begin:words
                wire [35:0] register_input=padded_input[stripe*36+:36];
                wire [47:0] registered_output;
                assign padded_output[stripe*36+:36]=registered_output[35:0];
                // unsigned高19位乘2^17加低17位，精确恢复36位；仅O寄存器采样。
                EFX_DSP48 #(.MODE("NORMAL"),.SIGNED(1'b0),.A_REG(1'b0),.B_REG(1'b0),
                    .C_REG(1'b0),.P_REG(1'b0),.OP_REG(1'b0),.W_REG(1'b0),.O_REG(1'b1),
                    .P_EXT("ALIGN_RIGHT"),.C_EXT("ALIGN_RIGHT"),
                    .M_SEL("P"),.N_SEL("C"),.W_SEL("X"),.SHIFTER(1'b0),
                    .RST_SYNC(1'b1),.O_REG_USE_CE(1'b1),.O_REG_USE_RST(1'b0)) storage(
                    .A(register_input[35:17]),.B(18'h20000),
                    .C({1'b0,register_input[16:0]}),.CASCIN(48'd0),.OP(2'b00),
                    .SHIFT_ENA(1'b0),.CLK(clk),.CE(record_write[bank]),.RST(1'b0),
                    .O(registered_output),.CASCOUT(),.OVFL());
            end
        end else begin:ff_record
            reg [127:0] held_record;
            assign held_records[bank*128+:128]=held_record;
            always @(posedge clk)if(record_write[bank])held_record<=record_input[bank*128+:128];
        end
    end endgenerate

    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;pc<=0;table_word<=0;table_row<=0;table_return<=IDLE;point_limit<=0;anchor_limit<=0;loaded<=0;pair_a<=0;pair_b<=1;
            address<=0;locked_seed_base<=0;load_lane<=0;word<=0;fill<=0;clear_index<=0;scan_index<=0;
            worst_index<=0;write_index<=0;export_index<=0;sort_index<=0;sort_position<=0;
            denominator_negative<=0;have_worst<=0;register_valid<=0;
            call_counter<=0;pending_call<=0;after_numeric<=0;scan_word<=0;scan_bad<=0;is_meta<=0;instruction<=0;
            fault<=0;seed_count<=0;pairs_visited<=0;legal_occurrences<=0;local_rejected<=0;
            geometry_rejected<=0;duplicates<=0;rank_pruned<=0;rank_replaced<=0;
        end else if(start&&start_ready)begin
            point_limit<=points;anchor_limit<=anchors;loaded<=0;pair_a<=0;pair_b<=1;
            address<=anchor_base;locked_seed_base<=seed_base;load_lane<=0;clear_index<=0;fill<=0;is_meta<=0;table_word<=0;
            call_counter<=0;register_valid<=0;fault<=0;seed_count<=0;pairs_visited<=0;legal_occurrences<=0;
            local_rejected<=0;geometry_rejected<=0;duplicates<=0;rank_pruned<=0;rank_replaced<=0;
            if(anchors>768||anchors>points||points>WIDTH*HEIGHT||anchor_base[5:0]!=0||seed_base[5:0]!=0||
                ({1'b0,anchor_base}+33'd6144)>ADDRESS_BYTES||({1'b0,seed_base}+33'd4160)>ADDRESS_BYTES)begin
                fault<=1;state<=FAILED;
            end else state<=CLEAR;
        end else case(state)
            CLEAR:if(table_word==7)begin
                table_word<=0;
                if(clear_index==255)state<=anchor_limit==0?SORT_SETUP:LOAD_REQ;
                else clear_index<=clear_index+8'd1;
            end else table_word<=table_word+3'd1;
            LOAD_REQ:if(req_valid&&req_ready)begin load_lane<=0;state<=LOAD_RSP;end
            LOAD_RSP:if(rsp_valid)begin
                if(rsp_error||!rsp_drained||!load_good)begin fault<=1;state<=FAILED;end
                else begin
                    if(loaded<anchor_limit)loaded<=loaded+10'd1;
                    if(load_lane==7)begin
                        if(loaded+(loaded<anchor_limit?10'd1:10'd0)>=anchor_limit)
                            state<=anchor_limit<2?SORT_SETUP:PA_READ;
                        else begin address<=address+32'd64;state<=LOAD_REQ;end
                    end else load_lane<=load_lane+3'd1;
                end
            end
            PA_READ:begin register_valid<=0;state<=PA_CAPTURE;end
            PA_CAPTURE:begin point_a<=anchor_q;state<=PB_READ;end
            PB_READ:state<=PB_CAPTURE;
            PB_CAPTURE:begin
                point_b<=anchor_q;
                if(point_a[53:32]==anchor_q[53:32])begin fault<=1;state<=FAILED;end
                else begin pc<=0;state<=PROGRAM_READ;end
            end
            PROGRAM_READ:begin
                if(pc==47)begin
                    scan_index<=0;have_worst<=0;state<=SEED_READ;
                end else state<=PROGRAM_CAPTURE;
            end
            PROGRAM_CAPTURE:begin
                instruction<=program_q;word<=0;
                if(program_q[2:0]>5||program_q[8:3]>33||program_q[14:9]>33||
                    program_q[29:22]==0||program_q[29:22]>128||
                    (program_q[8:3]<16&&!register_valid[program_q[6:3]])||
                    (program_q[14:9]<16&&!register_valid[program_q[12:9]]))begin fault<=1;state<=FAILED;end
                else state<=A_READ;
            end
            A_READ:state<=A_CAPTURE;
            A_CAPTURE:begin
                if(source_a>=16)begin word<=0;state<=B_READ;end
                else begin
                    if(word==7)begin word<=0;state<=B_READ;end
                    else begin word<=word+3'd1;state<=A_READ;end
                end
            end
            B_READ:state<=B_CAPTURE;
            B_CAPTURE:begin
                if(source_b>=16)begin state<=NUM_REQUEST;end
                else begin
                    if(word==7)state<=NUM_REQUEST;
                    else begin word<=word+3'd1;state<=B_READ;end
                end
            end
            NUM_REQUEST:begin
                if(call_counter==24'hffffff)begin fault<=1;state<=FAILED;end
                else if(num_req_valid&&num_req_ready)begin pending_call<=call_counter;call_counter<=call_counter+24'd1;state<=NUM_WAIT;end
            end
            NUM_WAIT:if(num_rsp_valid)begin
                if(num_rsp_body[175:0]!=expected_id||num_rsp_body[180:176]!={2'd0,opcode}||
                    num_rsp_body[189:181]!=requested_target||num_rsp_body[199:190]!=0)begin
                    fault<=1;after_numeric<=2;state<=NUM_CLOSE;
                end else begin scan_word<=0;scan_bad<=0;state<=NUM_SCAN;end
            end
            NUM_SCAN:if(num_rsp_valid)begin
                scan_bad<=scan_bad||piece_bad;
                if(scan_word==24)begin
                    after_numeric<=0;
                    if(scan_bad||piece_bad)begin
                        if(geometry_domain)begin geometry_rejected<=geometry_rejected+19'd1;after_numeric<=1;end
                        else begin fault<=1;after_numeric<=2;end
                        state<=NUM_CLOSE;
                    end else if(opcode==5&&num_rsp_body[200+:2]==3)begin
                        fault<=1;after_numeric<=2;state<=NUM_CLOSE;
                    end else if((pc==2&&num_rsp_body[200+:23]==0)||(pc==13&&num_rsp_body[200+:2]==1)||
                        (pc==42&&($signed(num_rsp_body[200+:19])<-19'sd128||$signed(num_rsp_body[200+:19])>19'sd128))||
                        (pc==44&&num_rsp_body[200+:17]==0))begin
                        local_rejected<=local_rejected+19'd1;after_numeric<=1;state<=NUM_CLOSE;
                    end else begin word<=0;state<=REG_WRITE;end
                end else scan_word<=scan_word+5'd1;
            end
            REG_WRITE:if(num_rsp_valid)begin
                if(word==7)begin
                    register_valid[destination]<=1;
                    if(pc==2)denominator_negative<=num_rsp_body[584];
                    if(pc==28)center_x<=num_rsp_body[200+:18];
                    if(pc==29)center_y<=num_rsp_body[200+:18];
                    if(pc==44)begin
                        candidate_key<={center_x^18'h20000,center_y^18'h20000,num_rsp_body[200+:17]};
                        legal_occurrences<=legal_occurrences+19'd1;
                    end
                    if(pc==45||pc==46)hash_temporary<=num_rsp_body[200+:64];
                    state<=NUM_CLOSE;
                end else word<=word+3'd1;
            end
            NUM_CLOSE:if(num_rsp_valid&&num_rsp_ready)begin
                if(after_numeric==2)state<=FAILED;
                else if(after_numeric==1)state<=PAIR_NEXT;
                else begin pc<=pc+6'd1;state<=PROGRAM_READ;end
            end
            SEED_READ:begin table_row<=scan_index;table_word<=0;table_return<=SEED_CAPTURE;state<=TABLE_READ;end
            TABLE_READ:state<=TABLE_CAPTURE;
            TABLE_CAPTURE:begin
                if(table_word==7)state<=table_return;
                else begin table_word<=table_word+3'd1;state<=TABLE_READ;end
            end
            SEED_CAPTURE:begin
                if(seed_q[127:118]!=0||(!seed_q[117]&&seed_q!=0))begin fault<=1;state<=FAILED;end
                else if(seed_q[117]&&seed_q[52:0]==candidate_key)begin duplicates<=duplicates+19'd1;state<=PAIR_NEXT;end
                else begin
                    if(seed_q[117]&&(!have_worst||less_seed(worst_record,seed_q)))begin
                        have_worst<=1;worst_index<=scan_index;
                    end
                    if(scan_index==255)state<=SEED_CHOOSE;
                    else begin scan_index<=scan_index+8'd1;state<=SEED_READ;end
                end
            end
            SEED_CHOOSE:begin
                table_word<=0;
                if(seed_count<256)begin write_index<=seed_count[7:0];seed_count<=seed_count+9'd1;state<=SEED_WRITE;end
                else if(!have_worst)begin fault<=1;state<=FAILED;end
                else if(less_seed(selected_record,worst_record))begin
                    write_index<=worst_index;rank_replaced<=rank_replaced+19'd1;state<=SEED_WRITE;
                end else begin rank_pruned<=rank_pruned+19'd1;state<=PAIR_NEXT;end
            end
            SEED_WRITE:if(table_word==7)state<=PAIR_NEXT;else table_word<=table_word+3'd1;
            PAIR_NEXT:begin
                pairs_visited<=pairs_visited+19'd1;
                if(pair_b+10'd1<anchor_limit)begin pair_b<=pair_b+10'd1;state<=PA_READ;end
                else if(pair_a+10'd2<anchor_limit)begin pair_a<=pair_a+10'd1;pair_b<=pair_a+10'd2;state<=PA_READ;end
                else state<=SORT_SETUP;
            end
            SORT_SETUP:begin
                if({1'b0,pairs_visited}!=expected_pairs)begin fault<=1;state<=FAILED;end
                else begin
                    address<=locked_seed_base;fill<=0;is_meta<=0;export_index<=0;sort_index<=1;
                    state<=seed_count<2?EXPORT_READ:SORT_READ;
                end
            end
            SORT_READ:begin table_row<=sort_index[7:0];table_word<=0;table_return<=SORT_CAPTURE;state<=TABLE_READ;end
            SORT_CAPTURE:begin
                if(!seed_q[117])begin fault<=1;state<=FAILED;end
                else begin sort_position<=sort_index;state<=SORT_PREV_READ;end
            end
            SORT_PREV_READ:begin
                table_word<=0;
                if(sort_position==0)state<=SORT_INSERT;
                else begin table_row<=8'(sort_position-9'd1);table_return<=SORT_PREV_CAPTURE;state<=TABLE_READ;end
            end
            SORT_PREV_CAPTURE:begin
                if(!seed_q[117])begin fault<=1;state<=FAILED;end
                else begin
                    table_word<=0;
                    state<=less_seed(selected_record,seed_q)?SORT_SHIFT:SORT_INSERT;
                end
            end
            SORT_SHIFT:if(table_word==7)begin sort_position<=sort_position-9'd1;state<=SORT_PREV_READ;end
                else table_word<=table_word+3'd1;
            SORT_INSERT:if(table_word==7)begin
                if(sort_index+9'd1>=seed_count)state<=EXPORT_READ;
                else begin sort_index<=sort_index+9'd1;state<=SORT_READ;end
            end else table_word<=table_word+3'd1;
            EXPORT_READ:begin table_row<=export_index;table_word<=0;table_return<=EXPORT_CAPTURE;state<=TABLE_READ;end
            EXPORT_CAPTURE:begin
                if((export_index<seed_count&&!seed_q[117])||(export_index>=seed_count&&seed_q!=0))begin fault<=1;state<=FAILED;end
                else state<=EXPORT_LOW;
            end
            EXPORT_LOW:begin fill<=fill+3'd1;state<=EXPORT_HIGH;end
            EXPORT_HIGH:if(fill==7)begin fill<=0;state<=WRITE_REQ;end
                else begin fill<=fill+3'd1;export_index<=export_index+8'd1;state<=EXPORT_READ;end
            META_PACK:if(fill==7)begin fill<=0;is_meta<=1;state<=WRITE_REQ;end else fill<=fill+3'd1;
            WRITE_REQ:if(req_valid&&req_ready)state<=WRITE_RSP;
            WRITE_RSP:if(rsp_valid&&rsp_ready)begin
                if(rsp_error||!rsp_drained)begin fault<=1;state<=FAILED;end
                else if(is_meta)state<=FINAL_QUIET;
                else begin
                    address<=address+32'd64;
                    if(export_index==255)state<=META_PACK;
                    else begin export_index<=export_index+8'd1;state<=EXPORT_READ;end
                end
            end
            FINAL_QUIET:if(num_quiet)state<=COMPLETE;
            IDLE,COMPLETE,FAILED:begin end
            default:begin fault<=1;state<=FAILED;end
        endcase
    end
endmodule
