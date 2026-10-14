// 全幅GRAD32存储：每像素原样保留gx/gy/方向，八组双像素组成一个64字节写事务。
// 此模块没有阈值筛选、抽样或点数截断；最终边缘筛选由后续识别读取者完成。
module board_gradient_store #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter bit ORDERED_PACK=0,RAM_PACK=0,
    parameter [32:0] ADDRESS_BYTES=33'h10000000
)(
    input wire clk,rst,start,producer_finished,
    input wire [31:0] base,input wire [95:0] scope,
    output wire start_ready,
    input wire in_valid,output wire in_ready,input wire [184:0] in_payload,
    input wire point_pack_valid,input wire [2:0] point_pack_index,input wire [63:0] point_pack_data,
    output wire req_valid,input wire req_ready,
    output wire [31:0] req_addr,output wire [511:0] req_data,
    input wire rsp_valid,output wire rsp_ready,input wire rsp_error,rsp_drained,
    output wire done,output reg fault,output reg [20:0] accepted_pairs
);
    localparam integer PAIRS=WIDTH*HEIGHT/2;
    localparam [32:0] STORAGE_BYTES=33'(WIDTH*HEIGHT*4);
    localparam IDLE=0,FILL=1,REQUEST=2,RESPONSE=3,COMPLETE=4,FAILED=5;
    reg [2:0] state,fill;
    reg [31:0] address;
    reg [95:0] locked_scope;
    reg [10:0] expected_x,expected_y;
    reg producer_closed;
    wire [511:0] block_data;
    wire [63:0] staged_word=point_pack_valid?point_pack_data:in_payload[63:0];
    wire [2:0] staged_index=point_pack_valid?point_pack_index:fill;
    wire stage_write=fire||(point_pack_valid&&state==COMPLETE);
    wire fire=in_valid&&in_ready;
    wire last_pair=accepted_pairs==PAIRS-1;
    wire last_x=expected_x==WIDTH-2;
    wire legal_record=in_payload[74:64]==expected_x&&in_payload[85:75]==expected_y&&
        in_payload[181:86]==locked_scope&&
        in_payload[182]==(accepted_pairs==0)&&in_payload[183]==last_x&&in_payload[184]==last_pair;
    assign start_ready=!rst&&(state==IDLE||state==COMPLETE);
    assign in_ready=!rst&&state==FILL&&accepted_pairs<PAIRS;
    assign req_valid=!rst&&state==REQUEST;
    assign req_addr=address;
    assign req_data=block_data;
    assign rsp_ready=!rst&&state==RESPONSE;
    assign done=!rst&&state==COMPLETE;
    // 正文只在真实打包接受沿改写；请求前八字全部写齐，复位无需清512位数据。
    generate if(RAM_PACK&&ORDERED_PACK)begin:ram_ordered_words
        // 整体512位高补8位，固定20位条带共26块RAM；64位移位只有固定导线拼接。
        // 接受沿采样旧Q并整体移位，保持原八64位槽逐沿行为，不依赖点打包索引。
        wire [519:0] padded_input={8'd0,staged_word,block_data[511:64]};
        wire [519:0] padded_output;
        assign block_data=padded_output[511:0];
        for(genvar stripe=0;stripe<26;stripe=stripe+1)begin:words
            EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("WRITE_FIRST")) storage(
                .WCLK(clk),.WE({2{stage_write}}),.WCLKE(1'b1),.WADDREN(1'b1),
                .WDATA(padded_input[stripe*20+:20]),.WADDR(9'd0),
                .RCLK(clk),.RE(1'b1),.RST(1'b0),.RADDREN(1'b1),
                .RDATA(padded_output[stripe*20+:20]),.RADDR(9'd0));
        end
    end else if(RAM_PACK)begin:ram_words
        // 索引模式保留八槽各四块20位RAM，64位正文高补16位。
        // WRITE_FIRST使接受沿后的Q立即包含新字，下一REQUEST沿可快照完整512位。
        // OUTPUT_REG必须为0；READ_FIRST/READ_UNKNOWN不能替代此处同址写后读语义。
        for(genvar slot=0;slot<8;slot=slot+1)begin:store_words
            wire [79:0] padded_input={16'd0,staged_word};
            wire [79:0] padded_output;
            wire slot_write=stage_write&&staged_index==slot;
            assign block_data[slot*64+:64]=padded_output[63:0];
            for(genvar stripe=0;stripe<4;stripe=stripe+1)begin:words
                EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("WRITE_FIRST")) storage(
                    .WCLK(clk),.WE({2{slot_write}}),.WCLKE(1'b1),.WADDREN(1'b1),
                    .WDATA(padded_input[stripe*20+:20]),.WADDR(9'd0),
                    .RCLK(clk),.RE(1'b1),.RST(1'b0),.RADDREN(1'b1),
                    .RDATA(padded_output[stripe*20+:20]),.RADDR(9'd0));
            end
        end
    end else begin:ff_words
        reg [511:0] held_data;
        assign block_data=held_data;
        if(ORDERED_PACK)begin:ordered_words
            // 板级全部调用者按0..7完整输出一个64B块；第8次接受后低字仍是第1个字。
            // 部分块不发布，abort/reset不要求保留未发布正文；通用随机索引模式保留在else。
            always @(posedge clk)if(stage_write)held_data<={staged_word,held_data[511:64]};
        end else begin:indexed_words
            for(genvar slot=0;slot<8;slot=slot+1)begin:store_words
                always @(posedge clk)if(stage_write&&staged_index==slot)held_data[slot*64+:64]<=staged_word;
            end
        end
    end endgenerate
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;fill<=0;address<=0;locked_scope<=0;expected_x<=0;expected_y<=0;
            producer_closed<=0;fault<=0;accepted_pairs<=0;
        end else if(start&&start_ready)begin
            fill<=0;address<=base;locked_scope<=scope;expected_x<=0;expected_y<=0;
            producer_closed<=0;fault<=0;accepted_pairs<=0;
            if(base[5:0]!=0||({1'b0,base}+STORAGE_BYTES)>ADDRESS_BYTES||PAIRS%8!=0)begin
                state<=COMPLETE;fault<=1;
            end else state<=FILL;
        end else begin
            if(producer_finished)producer_closed<=1;
            case(state)
                FILL:begin
                    if(fire)begin
                        if(!legal_record)fault<=1;
                        accepted_pairs<=accepted_pairs+21'd1;
                        if(last_x)begin expected_x<=0;expected_y<=expected_y+11'd1;end
                        else expected_x<=expected_x+11'd2;
                        if(fill==7)begin fill<=0;state<=REQUEST;end
                        else fill<=fill+3'd1;
                    end else if(producer_closed||producer_finished)begin
                        // 生产者已真实终结。短帧不是完整GRAD，未发出的部分槽无需写出。
                        if(accepted_pairs!=PAIRS||fill!=0)fault<=1;
                        state<=COMPLETE;
                    end
                end
                REQUEST:if(req_valid&&req_ready)state<=RESPONSE;
                RESPONSE:if(rsp_valid&&rsp_ready)begin
                    if(!rsp_drained)begin state<=FAILED;fault<=1;end
                    else begin
                        if(rsp_error)fault<=1;
                        address<=address+32'd64;
                        if(accepted_pairs==PAIRS)state<=COMPLETE;
                        else state<=FILL;
                    end
                end
                IDLE,COMPLETE,FAILED:begin end
                default:begin state<=FAILED;fault<=1;end
            endcase
        end
    end
endmodule
