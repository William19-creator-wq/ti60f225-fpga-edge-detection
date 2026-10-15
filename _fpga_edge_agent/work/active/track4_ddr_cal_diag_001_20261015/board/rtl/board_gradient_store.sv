// 全幅GRAD32存储：每像素原样保留gx/gy/方向，八组双像素组成一个64字节写事务。
// 此模块没有阈值筛选、抽样或点数截断；最终边缘筛选由后续识别读取者完成。
module board_gradient_store #(
    parameter integer WIDTH=1920,HEIGHT=1080,
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
    reg [511:0] block_data;
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
    // 每个槽只在自己的接受沿改写。没有清512位数据的必要：请求前八槽全部写齐。
    for(genvar slot=0;slot<8;slot=slot+1)begin: store_words
        always @(posedge clk)if(stage_write&&staged_index==slot)block_data[slot*64+:64]<=staged_word;
    end
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
