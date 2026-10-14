// RW01…04：4096项CELL/EXT，单64B行缓存；POINT缓存由父另持有。
// 父先消费POINT读回复再调用，借用249bit命令保持至回应消费且quiet；UNKNOWN至共同冷复位。
module board_line_workspace #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter [32:0] ADDRESS_BYTES=33'h10000000,
    parameter bit BORROW_COMMAND=1'b0
)(
    input wire clk,rst,command_valid,output wire command_ready,
    input wire [175:0] command_id,input wire [1:0] command_op,input wire command_table,
    input wire [31:0] command_base,input wire [20:0] command_points,
    input wire [11:0] command_index,input wire [3:0] command_sub,input wire command_old_member,
    output wire response_valid,input wire response_ready,
    output wire [175:0] response_id,output wire [1:0] response_op,output wire response_table,
    output wire [79:0] response_entry,output reg [12:0] cleared_entries,
    output reg error,drained,output wire quiet,output reg fault,quarantined,
    output wire req_valid,input wire req_ready,output wire req_write,output wire [31:0] req_addr,
    input wire rsp_valid,output wire rsp_ready,input wire [511:0] rsp_data,input wire rsp_error,rsp_drained,
    output wire pack_valid,output wire [2:0] pack_index,output wire [63:0] pack_data
);
    localparam [1:0] CLEAR_TABLE=0,UPDATE_ENTRY=1,READ_ENTRY=2;
    localparam IDLE=0,CHECK=1,ZERO_PACK=2,READ_REQUEST=3,READ_WAIT=4,COPY32=5,
        READ_RELEASE=6,ERROR_RELEASE=7,ITEM_READ=8,ITEM_CAPTURE=9,ITEM_CHECK=10,
        CHECK_LINE=11,TARGET_READ=12,TARGET_CAPTURE=13,TARGET_CHECK=14,
        UPDATE_PLAN=15,STORE8=16,PACK_READ=17,PACK_CAPTURE=18,PACK_EMIT=19,
        WRITE_REQUEST=20,WRITE_WAIT=21,RESULT=22,UNKNOWN_RESULT=23,ISOLATED=24;
    reg [4:0] state,copy_index;
    reg command_active,native_pending,native_write,line_bad,padding_bad;
    reg [31:0] address;
    reg [9:0] clear_block;
    reg [1:0] item_slot,pack_piece;
    reg [2:0] item_word,pack_slot;
    reg [79:0] entry;
    reg [63:0] packed_word;

    wire [248:0] held_command;
    wire command_fire=command_valid && command_ready;
    generate if(BORROW_COMMAND)begin:borrow_command
        assign held_command={command_id,command_op,command_table,command_base,command_points,
            command_index,command_sub,command_old_member};
    end else begin:snapshot_command
        reg [248:0] snapshot;
        assign held_command=snapshot;
        always @(posedge clk)if(rst)snapshot<=0;else if(command_fire)
            snapshot<={command_id,command_op,command_table,command_base,command_points,
                command_index,command_sub,command_old_member};
    end endgenerate
    wire [175:0] held_id=held_command[248:73];
    wire [1:0] operation=held_command[72:71];
    wire table_kind=held_command[70];
    wire [31:0] table_base=held_command[69:38];
    wire [20:0] point_limit=held_command[37:17];
    wire [11:0] index=held_command[16:5];
    wire [3:0] sub=held_command[4:1];
    wire old_member=held_command[0];
    wire [32:0] table_end={1'b0,table_base}+33'd65536;
    wire [32:0] line_address={1'b0,table_base}+{17'd0,index[11:2],6'd0};
    wire parameters_good=WIDTH>=6 && WIDTH<=1920 && WIDTH%2==0 && HEIGHT>=5 && HEIGHT<=1080;
    wire command_good=parameters_good && held_id[103:96]==0 && operation!=3 &&
        table_base[5:0]==0 && table_end<=ADDRESS_BYTES && table_end<=33'h100000000 &&
        {1'b0,point_limit}<=22'(WIDTH*HEIGHT) &&
        (operation!=CLEAR_TABLE || (index==0 && sub==0 && !old_member)) &&
        (operation!=READ_ENTRY || (sub==0 && !old_member)) &&
        (operation!=UPDATE_ENTRY || ((!old_member || table_kind) && point_limit!=0));

    assign response_id=held_id;
    assign response_op=operation;
    assign response_table=table_kind;
    assign response_entry=entry;
    assign response_valid=!rst && (state==RESULT || state==UNKNOWN_RESULT);
    wire response_fire=response_valid && response_ready;
    // 现native arbiter空闲也提供真实drained；不能把“没有valid”当成服务已关闭。
    assign quiet=!rst && state==IDLE && !command_active && !native_pending &&
        !rsp_valid && rsp_drained && !quarantined;
    assign command_ready=quiet;

    wire reply_state=state==READ_WAIT || state==COPY32 || state==READ_RELEASE ||
        state==ERROR_RELEASE || state==WRITE_WAIT;
    wire held_read=state==COPY32 || state==READ_RELEASE || state==ERROR_RELEASE;
    wire protocol_bad=(rsp_valid && (!native_pending || !reply_state || !rsp_drained)) ||
        (native_pending && held_read && !rsp_valid);
    wire reply_success=rsp_valid && native_pending && rsp_drained && !rsp_error;
    assign req_valid=!rst && !quarantined && !protocol_bad && !native_pending &&
        (state==READ_REQUEST || state==WRITE_REQUEST);
    // UNKNOWN未消费旧回复时也保留accepted write侧带，不能因隔离状态而改成read。
    assign req_write=native_write;
    assign req_addr=address;
    assign rsp_ready=!rst && !quarantined && !protocol_bad && native_pending && rsp_valid &&
        rsp_drained && ((state==READ_WAIT && rsp_error) || state==READ_RELEASE ||
        state==ERROR_RELEASE || state==WRITE_WAIT);
    wire request_fire=req_valid && req_ready;
    wire reply_fire=rsp_valid && rsp_ready;
    assign pack_valid=!rst && !quarantined && !protocol_bad &&
        (state==ZERO_PACK || state==PACK_EMIT);
    assign pack_index=pack_slot;
    assign pack_data=state==ZERO_PACK ? 64'd0 : packed_word;

    // 一套32×16同步行RAM。所有copy/检查/修改/PACK严格分阶段，不依同址返回模式。
    reg [15:0] line_words[0:31],line_q;
    reg [4:0] ram_address;
    reg [15:0] store_piece;
    always @*begin
        ram_address=0;
        case(state)
            COPY32:ram_address=copy_index;
            ITEM_READ,ITEM_CAPTURE,ITEM_CHECK:ram_address={item_slot,item_word};
            TARGET_READ,TARGET_CAPTURE,TARGET_CHECK,STORE8:ram_address={index[1:0],item_word};
            PACK_READ,PACK_CAPTURE,PACK_EMIT:ram_address={pack_slot,pack_piece};
            default:begin end
        endcase
        store_piece=0;
        case(item_word)
            0:store_piece=entry[15:0];
            1:store_piece=entry[31:16];
            2:store_piece=entry[47:32];
            3:store_piece=entry[63:48];
            4:store_piece=entry[79:64];
            default:begin end
        endcase
    end
    always @(posedge clk)begin
        line_q<=line_words[ram_address];
        if(!rst && !quarantined && !protocol_bad)begin
            if(state==COPY32 && reply_success)line_words[ram_address]<=rsp_data[copy_index*16+:16];
            else if(state==STORE8)line_words[ram_address]<=store_piece;
        end
    end

    function automatic [3:0] mask_low(input [15:0] mask);
        integer bit_index;reg found;
        begin
            mask_low=0;found=0;
            for(bit_index=0;bit_index<16;bit_index=bit_index+1)
                if(mask[bit_index] && !found)begin mask_low=bit_index[3:0];found=1;end
        end
    endfunction
    function automatic [3:0] mask_high(input [15:0] mask);
        integer bit_index;
        begin
            mask_high=0;
            for(bit_index=0;bit_index<16;bit_index=bit_index+1)
                if(mask[bit_index])mask_high=bit_index[3:0];
        end
    endfunction
    function automatic [4:0] mask_count(input [15:0] mask);
        integer bit_index;
        begin
            mask_count=0;
            for(bit_index=0;bit_index<16;bit_index=bit_index+1)
                mask_count=mask_count+{4'd0,mask[bit_index]};
        end
    endfunction
    wire [20:0] count=entry[20:0];
    wire [20:0] old_count=table_kind ? entry[41:21] : 21'd0;
    wire [3:0] minimum=table_kind ? entry[45:42] : entry[24:21];
    wire [3:0] maximum=table_kind ? entry[49:46] : entry[28:25];
    wire occupied=table_kind ? entry[50] : entry[29];
    wire [15:0] mask=table_kind ? entry[79:64] : entry[47:32];
    wire reserved_zero=table_kind ? entry[63:51]==0 : entry[79:48]==0 && entry[31:30]==0;
    wire entry_good=!padding_bad && reserved_zero && (count==0 ? entry==0 :
        count<=point_limit && occupied && mask!=0 && minimum<=maximum &&
        minimum==mask_low(mask) && maximum==mask_high(mask) &&
        count>={16'd0,mask_count(mask)} && old_count<=count);
    wire [21:0] next_count={1'b0,count}+22'd1;
    wire [21:0] next_old_count={1'b0,old_count}+{21'd0,old_member};
    wire [15:0] next_mask=mask | (16'h0001<<sub);
    wire update_good=!next_count[21] && next_count<={1'b0,point_limit} &&
        !next_old_count[21] && next_old_count<=next_count;
    reg [79:0] next_entry;
    always @*begin
        next_entry=0;next_entry[20:0]=next_count[20:0];
        if(table_kind)begin
            next_entry[41:21]=next_old_count[20:0];next_entry[45:42]=mask_low(next_mask);
            next_entry[49:46]=mask_high(next_mask);next_entry[50]=1;next_entry[79:64]=next_mask;
        end else begin
            next_entry[24:21]=mask_low(next_mask);next_entry[28:25]=mask_high(next_mask);
            next_entry[29]=1;next_entry[47:32]=next_mask;
        end
    end
    task automatic known_failure;
        begin entry<=0;cleared_entries<=0;error<=1;drained<=1;fault<=1;state<=RESULT;end
    endtask
    task automatic unknown_failure;
        begin
            entry<=0;cleared_entries<=0;error<=1;drained<=0;fault<=1;quarantined<=1;
            state<=command_active ? UNKNOWN_RESULT : ISOLATED;
        end
    endtask

    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;command_active<=0;native_pending<=0;native_write<=0;line_bad<=0;padding_bad<=0;
            address<=0;clear_block<=0;item_slot<=0;item_word<=0;copy_index<=0;
            pack_piece<=0;pack_slot<=0;entry<=0;packed_word<=0;
            cleared_entries<=0;error<=0;drained<=0;fault<=0;quarantined<=0;
        end else begin
            if(request_fire)native_pending<=1;
            if(reply_fire)native_pending<=0;
            if(protocol_bad)begin
                fault<=1;quarantined<=1;
                // 已valid回应绝不撤回或改body；晚异常只在真实消费后隔离。
                if(state==RESULT || state==UNKNOWN_RESULT)begin
                    if(response_fire)begin command_active<=0;state<=ISOLATED;end
                end else unknown_failure();
            end else case(state)
                IDLE:if(command_fire)begin
                    command_active<=1;entry<=0;cleared_entries<=0;error<=0;drained<=0;
                    line_bad<=0;padding_bad<=0;copy_index<=0;item_word<=0;item_slot<=0;
                    pack_piece<=0;pack_slot<=0;clear_block<=0;state<=CHECK;
                end
                CHECK:if(!command_good)known_failure();else begin
                    address<=operation==CLEAR_TABLE ? table_base : line_address[31:0];
                    native_write<=operation==CLEAR_TABLE;
                    state<=operation==CLEAR_TABLE ? ZERO_PACK : READ_REQUEST;
                end
                ZERO_PACK:if(pack_slot==7)begin pack_slot<=0;state<=WRITE_REQUEST;end
                    else pack_slot<=pack_slot+3'd1;
                READ_REQUEST:if(request_fire)state<=READ_WAIT;
                READ_WAIT:if(rsp_valid)begin
                    if(rsp_error)begin if(reply_fire)known_failure();end
                    else begin copy_index<=0;state<=COPY32;end
                end
                COPY32:if(rsp_error)state<=ERROR_RELEASE;
                    else if(copy_index==31)state<=READ_RELEASE;
                    else copy_index<=copy_index+5'd1;
                READ_RELEASE:if(reply_fire)begin
                    if(rsp_error)known_failure();else begin
                        item_slot<=0;item_word<=0;line_bad<=0;padding_bad<=0;state<=ITEM_READ;
                    end
                end
                ERROR_RELEASE:if(reply_fire)known_failure();
                ITEM_READ:state<=ITEM_CAPTURE;
                ITEM_CAPTURE:begin
                    if(item_word<5)entry<={line_q,entry[79:16]};
                    else padding_bad<=padding_bad || line_q!=0;
                    if(item_word==7)state<=ITEM_CHECK;
                    else begin item_word<=item_word+3'd1;state<=ITEM_READ;end
                end
                ITEM_CHECK:begin
                    line_bad<=line_bad || !entry_good;
                    if(item_slot==3)state<=CHECK_LINE;
                    else begin item_slot<=item_slot+2'd1;item_word<=0;padding_bad<=0;state<=ITEM_READ;end
                end
                CHECK_LINE:if(line_bad)known_failure();else begin
                    // 全四项先核完再重读目标，不并存第二份80位target。
                    item_word<=0;padding_bad<=0;state<=TARGET_READ;
                end
                TARGET_READ:state<=TARGET_CAPTURE;
                TARGET_CAPTURE:begin
                    if(item_word<5)entry<={line_q,entry[79:16]};
                    else padding_bad<=padding_bad || line_q!=0;
                    if(item_word==7)state<=TARGET_CHECK;
                    else begin item_word<=item_word+3'd1;state<=TARGET_READ;end
                end
                TARGET_CHECK:if(!entry_good)known_failure();
                    else if(operation==READ_ENTRY)begin drained<=1;state<=RESULT;end
                    else state<=UPDATE_PLAN;
                UPDATE_PLAN:if(!update_good)known_failure();else begin
                    entry<=next_entry;item_word<=0;state<=STORE8;
                end
                STORE8:if(item_word==7)begin pack_slot<=0;pack_piece<=0;state<=PACK_READ;end
                    else item_word<=item_word+3'd1;
                PACK_READ:state<=PACK_CAPTURE;
                PACK_CAPTURE:begin
                    packed_word<={line_q,packed_word[63:16]};
                    if(pack_piece==3)state<=PACK_EMIT;
                    else begin pack_piece<=pack_piece+2'd1;state<=PACK_READ;end
                end
                PACK_EMIT:if(pack_slot==7)begin native_write<=1;state<=WRITE_REQUEST;end
                    else begin pack_slot<=pack_slot+3'd1;pack_piece<=0;state<=PACK_READ;end
                WRITE_REQUEST:if(request_fire)state<=WRITE_WAIT;
                WRITE_WAIT:if(reply_fire)begin
                    if(rsp_error)known_failure();
                    else if(operation==CLEAR_TABLE && clear_block!=1023)begin
                        clear_block<=clear_block+10'd1;address<=address+32'd64;pack_slot<=0;state<=ZERO_PACK;
                    end else begin
                        if(operation==CLEAR_TABLE)begin entry<=0;cleared_entries<=13'd4096;end
                        drained<=1;state<=RESULT;
                    end
                end
                RESULT:if(response_fire)begin
                    command_active<=0;state<=quarantined ? ISOLATED : IDLE;
                end
                UNKNOWN_RESULT:if(response_fire)begin command_active<=0;state<=ISOLATED;end
                ISOLATED:begin end
                default:unknown_failure();
            endcase
        end
    end
endmodule
