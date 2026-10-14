// 完整POINT表两遍统计接真实FIT：先写原始STAT，再拟合并写完整RSP，全部写回复结清才关闭。
// 这是完整点表数值链路，不把全帧一个统计对象当作已完成多目标识别。
module board_recognition_stats #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter [32:0] ADDRESS_BYTES=33'h10000000,
    parameter bit BORROW_SCOPE=1'b0,SHARED_RETURN_WORDS=1'b0
)(
    input wire clk,rst,start,input wire [95:0] scope,
    input wire [20:0] points,input wire [31:0] point_base,stat_base,
    output wire start_ready,done,output reg fault,
    output wire req_valid,input wire req_ready,output wire req_write,output wire [31:0] req_addr,
    input wire rsp_valid,output wire rsp_ready,input wire [511:0] rsp_data,
    input wire rsp_error,rsp_drained,
    output wire anchor_point_valid,input wire anchor_point_ready,output wire [63:0] anchor_point,
    output wire pack_valid,output wire [2:0] pack_index,output wire [63:0] pack_data,
    output wire shared_req_valid,output wire [621:0] shared_req_body,input wire shared_req_ready,
    input wire shared_rsp_valid,input wire [584:0] shared_rsp_body,output wire shared_rsp_ready,
    output wire shared_cancel_valid,output wire [175:0] shared_cancel_id,input wire shared_quiet,
    output wire [4:0] shared_rsp_word_index,input wire [15:0] shared_rsp_word16
);
    localparam IDLE=0,START_SCAN=1,POINT_REQUEST=2,POINT_WAIT=3,POINT_SEND=4,
        END_SCAN=5,STAT_WAIT=6,PACK=7,WRITE_REQUEST=8,WRITE_WAIT=9,
        CLOSE_STAT=10,NEXT_SCAN=11,COMPLETE=12,FAILED=13,FIT_REQUEST=14,FIT_WAIT=15,CLOSE_FIT=16;
    reg [4:0] state;
    reg tls_pass,second_block,packing_fit;
    wire [95:0] locked_scope;
    reg [20:0] total_points,ordinal;
    reg [31:0] point_address,result_address,locked_point_base,locked_stat_base;
    reg [2:0] lane,pack_slot;
    wire [175:0] numeric_id={63'd0,tls_pass,16'd0,locked_scope};
    wire [4:0] fit_kind=tls_pass?5'd12:5'd11;
    wire [63:0] point_word=rsp_data[lane*64+:64];
    wire [10:0] px=point_word[42:32],py=point_word[53:43];
    wire point_legal=px<WIDTH&&py<HEIGHT&&point_word[63]==0&&point_word[31:24]==0&&
        point_word[21:0]!=0;
    wire token_valid,token_ready,stat_valid,stat_ready,stats_quiet,stats_fault;
    wire [7:0] stats_reason;
    reg [83:0] token_data;
    reg [1:0] token_op;
    wire [261:0] token_body={token_data,token_op,numeric_id};
    wire [631:0] stat_body;
    wire [1023:0] stat_view={392'd0,stat_body};
    wire fit_req_valid,fit_req_ready,fit_rsp_valid,fit_rsp_ready,fit_quiet;
    wire [584:0] fit_rsp_body;
    wire [1023:0] fit_view={439'd0,fit_rsp_body};
    wire [3:0] stat_word={second_block,pack_slot};
    wire token_fire=token_valid&&token_ready;
    wire last_point=ordinal==total_points-21'd1;
    wire write_good=rsp_valid&&rsp_drained&&!rsp_error;
    assign start_ready=!rst&&(state==IDLE||state==COMPLETE)&&stats_quiet&&fit_quiet;
    generate if(BORROW_SCOPE)begin:borrow_scope
        // 板端同帧Canny actor持有scope至全部统计/FIT/写回关闭，COMPLETE无有效正文。
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
    assign req_valid=!rst&&(state==POINT_REQUEST||state==WRITE_REQUEST);
    assign req_write=state==WRITE_REQUEST;
    assign req_addr=req_write?result_address:point_address;
    // 原物理512位返回保持到这一组实际token交付完毕，不再复制正文。
    assign rsp_ready=!rst&&(state==WRITE_WAIT||
        (state==POINT_SEND&&token_fire&&(lane==7||last_point)));
    assign pack_valid=!rst&&state==PACK;
    assign pack_index=pack_slot;
    assign pack_data=packing_fit?fit_view[stat_word*64+:64]:stat_view[stat_word*64+:64];
    assign token_valid=!rst&&(state==START_SCAN||state==END_SCAN||
        (state==POINT_SEND&&rsp_valid&&point_legal&&(tls_pass||anchor_point_ready)));
    // 同一个真实POINT交付沿，同时交给统计与anchor；任一接收者不ready都不推进光栅序列。
    assign anchor_point_valid=!rst&&state==POINT_SEND&&!tls_pass&&rsp_valid&&point_legal&&token_ready;
    assign anchor_point=point_word;
    assign stat_ready=!rst&&(state==CLOSE_STAT||state==FAILED)&&fit_quiet;
    assign fit_req_valid=!rst&&state==FIT_REQUEST&&stat_valid;
    assign fit_rsp_ready=!rst&&(state==CLOSE_FIT||state==FAILED);
    always @*begin
        token_data=0;token_op=stats_protocol_pkg::START;
        case(state)
            START_SCAN:begin
                token_data[10:0]=11'(WIDTH);token_data[21:11]=11'(HEIGHT);
                token_data[26:22]=fit_kind;token_data[34:27]=8'd1;
                token_data[50:35]=16'd64;token_data[71:51]=total_points;
            end
            POINT_SEND:begin
                token_op=stats_protocol_pkg::POINT;
                token_data[20:0]=ordinal;token_data[21]=1;
                token_data[32:22]=px;token_data[43:33]=py;
                token_data[54:44]=point_word[10:0];token_data[65:55]=point_word[21:11];
            end
            END_SCAN:begin token_op=stats_protocol_pkg::END_SCAN;token_data[21:0]={1'b0,total_points};end
            default:begin end
        endcase
    end
    // numeric_id仅在两子核quiet后切换遍次；STAT持有期间所有TOKEN均沿用同一身份。
    stats_core #(.BORROW_CONTEXT(1'b1)) statistics(
        .clk,.rst,.token_valid,.token_body,.token_ready,.stat_valid,.stat_body,.stat_ready,
        .fault_active(stats_fault),.fault_reason(stats_reason),.quiet(stats_quiet));
    fit_core #(.BORROW_PAYLOAD(1'b1),.LS_TLS_ONLY(1'b1),.SERIAL_LOCAL_MOVES(1'b1),.EXTERNAL_SCALAR(1'b1),.ROM_SCALAR(1'b1),.WORD_SLOTS(1'b1),.DSP_OPERAND_RESULT(1'b1),.SHARED_RETURN_WORDS(SHARED_RETURN_WORDS)) fitting(
        .clk,.rst,.req_valid(fit_req_valid),.req_ready(fit_req_ready),.req_body(stat_body[621:0]),
        .rsp_valid(fit_rsp_valid),.rsp_ready(fit_rsp_ready),.rsp_body(fit_rsp_body),
        .cancel_valid(1'b0),.cancel_id(176'd0),.quiet(fit_quiet),
        .shared_req_valid,.shared_req_body,.shared_req_ready,.shared_rsp_valid,.shared_rsp_body,.shared_rsp_ready,
        .shared_cancel_valid,.shared_cancel_id,.shared_quiet,.shared_rsp_word_index,.shared_rsp_word16);
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;tls_pass<=0;second_block<=0;packing_fit<=0;total_points<=0;ordinal<=0;
            point_address<=0;result_address<=0;locked_point_base<=0;locked_stat_base<=0;lane<=0;pack_slot<=0;fault<=0;
        end else if(start&&start_ready)begin
            total_points<=points;ordinal<=0;tls_pass<=0;second_block<=0;
            point_address<=point_base;locked_point_base<=point_base;locked_stat_base<=stat_base;
            result_address<=stat_base;packing_fit<=0;lane<=0;pack_slot<=0;fault<=0;
            if(points>WIDTH*HEIGHT||point_base[5:0]!=0||stat_base[5:0]!=0||
                ({1'b0,point_base}+({12'd0,points}<<3))>ADDRESS_BYTES||
                ({1'b0,stat_base}+33'd512)>ADDRESS_BYTES)begin state<=FAILED;fault<=1;end
            else state<=START_SCAN;
        end else case(state)
            START_SCAN:if(token_fire)state<=total_points==0?END_SCAN:POINT_REQUEST;
            POINT_REQUEST:if(req_valid&&req_ready)state<=POINT_WAIT;
            POINT_WAIT:if(rsp_valid)begin
                if(rsp_error||!rsp_drained)begin state<=FAILED;fault<=1;end
                else begin lane<=0;state<=POINT_SEND;end
            end
            POINT_SEND:if(rsp_valid)begin
                if(!point_legal)begin state<=FAILED;fault<=1;end
                else if(token_fire)begin
                    ordinal<=ordinal+21'd1;
                    if(last_point)state<=END_SCAN;
                    else if(lane==7)begin point_address<=point_address+32'd64;state<=POINT_REQUEST;end
                    else lane<=lane+3'd1;
                end
            end
            END_SCAN:if(token_fire)state<=STAT_WAIT;
            STAT_WAIT:if(stat_valid)begin
                if(stat_body[631:624]!=0||stat_body[623:622]!=0||stat_body[175:0]!=numeric_id||
                    stat_body[210:206]!=fit_kind||stat_body[242:222]!=total_points)begin
                    state<=FAILED;fault<=1;
                end else begin second_block<=0;pack_slot<=0;state<=PACK;end
            end
            PACK:begin
                if(pack_slot==7)state<=WRITE_REQUEST;
                else pack_slot<=pack_slot+3'd1;
            end
            WRITE_REQUEST:if(req_valid&&req_ready)state<=WRITE_WAIT;
            WRITE_WAIT:if(rsp_valid&&rsp_ready)begin
                if(!write_good)begin state<=FAILED;fault<=1;end
                else begin
                    result_address<=result_address+32'd64;
                    if(second_block)state<=packing_fit?CLOSE_FIT:FIT_REQUEST;
                    else begin second_block<=1;pack_slot<=0;state<=PACK;end
                end
            end
            FIT_REQUEST:if(fit_req_valid&&fit_req_ready)state<=FIT_WAIT;
            FIT_WAIT:if(fit_rsp_valid)begin
                if(fit_rsp_body[175:0]!=numeric_id||fit_rsp_body[180:176]!=fit_kind||
                    fit_rsp_body[189:181]!=0||fit_rsp_body[191:190]>1)begin
                    state<=FAILED;fault<=1;
                end else begin
                    // LOCAL_REJECT原样记录，不把退化统计伪造为成功几何。
                    packing_fit<=1;second_block<=0;pack_slot<=0;
                    result_address<=locked_stat_base+(tls_pass?32'd384:32'd256);state<=PACK;
                end
            end
            CLOSE_FIT:if(fit_rsp_valid&&fit_rsp_ready)state<=CLOSE_STAT;
            CLOSE_STAT:if(stat_valid&&stat_ready)state<=NEXT_SCAN;
            NEXT_SCAN:if(stats_quiet&&fit_quiet)begin
                if(tls_pass)state<=COMPLETE;
                else begin tls_pass<=1;ordinal<=0;point_address<=locked_point_base;
                    result_address<=locked_stat_base+32'd128;packing_fit<=0;state<=START_SCAN;end
            end
            IDLE,COMPLETE,FAILED:begin end
            default:begin state<=FAILED;fault<=1;end
        endcase
    end
endmodule
