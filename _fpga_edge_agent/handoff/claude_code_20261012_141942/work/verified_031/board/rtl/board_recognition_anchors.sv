// 全E点按8x6空间桶、8方向桶各留两个最小rank；实际RAM结果压紧写DDR，写回结清才done。
// POINT64 v2={zero1,theta9,y11,x11,GRAD32}。这是搜索种子选择，不限定场景目标数量/尺度。
module board_recognition_anchors #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter [32:0] ADDRESS_BYTES=33'h10000000
)(
    input wire clk,rst,start,input wire [95:0] scope,input wire [20:0] expected_points,
    input wire [31:0] anchor_base,
    input wire in_valid,output wire in_ready,input wire [63:0] in_point,
    input wire finish,output wire start_ready,done,output reg fault,
    output reg [9:0] anchor_count,
    output wire req_valid,input wire req_ready,output wire [31:0] req_addr,
    input wire rsp_valid,output wire rsp_ready,input wire rsp_error,rsp_drained,
    output wire pack_valid,output wire [2:0] pack_index,output wire [63:0] pack_data
);
    localparam IDLE=0,CLEAR=1,WAIT_POINT=2,FIRST_READ=3,FIRST_CAPTURE=4,
        SECOND_READ=5,SECOND_CAPTURE=6,CHOOSE=7,KEEP_FIRST=8,WRITE_NEW=9,
        EXPORT_READ=10,EXPORT_CAPTURE=11,EXPORT_STAGE=12,EXPORT_REQUEST=13,
        EXPORT_RESPONSE=14,EXPORT_PAD=15,COMPLETE=16,FAILED=17;
    reg [4:0] state;
    reg [95:0] locked_scope;
    reg [20:0] limit,accepted,last_linear,new_rank;
    reg have_last;
    reg [63:0] held_point,export_point;
    reg [85:0] first_record,second_record;
    reg [9:0] clear_index,bucket_slot,new_slot,export_index,exported;
    reg [2:0] fill;
    reg export_finished;
    reg [31:0] address;
    wire [10:0] px=in_point[42:32],py=in_point[53:43];
    wire [21:0] linear_full={11'd0,py}*22'(WIDTH)+{11'd0,px};
    wire [20:0] rank_xor=linear_full[20:0]^(linear_full[20:0]>>11);
    wire [27:0] rank_product={7'd0,rank_xor}*28'd109+28'd37;
    wire [20:0] point_rank=rank_product[20:0]^(rank_product[20:0]>>7);
    wire [3:0] spatial_x=4'(({3'd0,px}<<3)/WIDTH);
    wire [2:0] spatial_y=3'(({3'd0,py}*14'd6)/HEIGHT);
    wire [8:0] bucket=9'(spatial_y)*9'd64+{2'd0,spatial_x,3'd0}+{6'd0,in_point[62:60]};
    wire point_legal=px<WIDTH&&py<HEIGHT&&!linear_full[21]&&linear_full<WIDTH*HEIGHT&&
        in_point[63]==0&&in_point[31:24]==0&&in_point[21:0]!=0&&
        spatial_x<8&&spatial_y<6&&(!have_last||linear_full[20:0]>last_linear);
    // 独立86位有效/rank/正文，任何资格更新都与完整记录真实写入同沿完成。
    reg [85:0] records[0:767];
    reg [85:0] read_record;
    reg [9:0] ram_read_address,ram_write_address;
    reg [85:0] ram_write_data;
    reg ram_write;
    always @(posedge clk)begin
        read_record<=records[ram_read_address];
        if(ram_write)records[ram_write_address]<=ram_write_data;
    end
    assign start_ready=!rst&&(state==IDLE||state==COMPLETE);
    assign in_ready=!rst&&state==WAIT_POINT&&!finish;
    assign done=!rst&&state==COMPLETE;
    assign req_valid=!rst&&state==EXPORT_REQUEST;
    assign req_addr=address;
    assign rsp_ready=!rst&&state==EXPORT_RESPONSE;
    assign pack_valid=!rst&&(state==EXPORT_STAGE||state==EXPORT_PAD);
    assign pack_index=fill;
    assign pack_data=state==EXPORT_STAGE?export_point:64'd0;
    always @*begin
        ram_read_address=bucket_slot;
        if(state==SECOND_READ||state==SECOND_CAPTURE)ram_read_address=bucket_slot+10'd1;
        if(state==EXPORT_READ||state==EXPORT_CAPTURE)ram_read_address=export_index;
        ram_write=0;ram_write_address=0;ram_write_data=0;
        case(state)
            CLEAR:begin ram_write=1;ram_write_address=clear_index;end
            KEEP_FIRST:begin ram_write=1;ram_write_address=bucket_slot+10'd1;ram_write_data=first_record;end
            WRITE_NEW:begin ram_write=1;ram_write_address=new_slot;ram_write_data={1'b1,new_rank,held_point};end
            default:begin end
        endcase
        if(rst)ram_write=0;
    end
    task automatic export_continue;
        begin
            if(export_index==767)begin
                export_finished<=1;
                if(exported!=anchor_count)begin fault<=1;state<=FAILED;end
                else if(fill!=0)state<=EXPORT_PAD;
                else state<=COMPLETE;
            end else begin export_index<=export_index+10'd1;state<=EXPORT_READ;end
        end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;locked_scope<=0;limit<=0;accepted<=0;last_linear<=0;new_rank<=0;have_last<=0;
            held_point<=0;export_point<=0;first_record<=0;second_record<=0;
            clear_index<=0;bucket_slot<=0;new_slot<=0;export_index<=0;exported<=0;
            fill<=0;export_finished<=0;address<=0;anchor_count<=0;fault<=0;
        end else if(start&&start_ready)begin
            locked_scope<=scope;limit<=expected_points;accepted<=0;last_linear<=0;have_last<=0;
            clear_index<=0;export_index<=0;exported<=0;fill<=0;export_finished<=0;
            address<=anchor_base;anchor_count<=0;fault<=0;
            if(expected_points>WIDTH*HEIGHT||anchor_base[5:0]!=0||
                ({1'b0,anchor_base}+33'd6144)>ADDRESS_BYTES)begin fault<=1;state<=FAILED;end
            else state<=CLEAR;
        end else case(state)
            CLEAR:if(clear_index==767)state<=WAIT_POINT;else clear_index<=clear_index+10'd1;
            WAIT_POINT:begin
                if(finish)begin
                    if(accepted!=limit)begin fault<=1;state<=FAILED;end
                    else begin export_index<=0;exported<=0;fill<=0;state<=EXPORT_READ;end
                end else if(in_valid&&in_ready)begin
                    if(!point_legal||accepted>=limit)begin fault<=1;state<=FAILED;end
                    else begin
                        held_point<=in_point;new_rank<=point_rank;bucket_slot<={bucket,1'b0};
                        accepted<=accepted+21'd1;last_linear<=linear_full[20:0];have_last<=1;state<=FIRST_READ;
                    end
                end
            end
            FIRST_READ:state<=FIRST_CAPTURE;
            FIRST_CAPTURE:begin first_record<=read_record;state<=SECOND_READ;end
            SECOND_READ:state<=SECOND_CAPTURE;
            SECOND_CAPTURE:begin second_record<=read_record;state<=CHOOSE;end
            CHOOSE:begin
                if(!first_record[85]&&second_record[85])begin fault<=1;state<=FAILED;end
                else if(!first_record[85]||new_rank<first_record[84:64])begin
                    new_slot<=bucket_slot;
                    if(first_record[85])begin
                        if(!second_record[85])anchor_count<=anchor_count+10'd1;
                        state<=KEEP_FIRST;
                    end else begin anchor_count<=anchor_count+10'd1;state<=WRITE_NEW;end
                end else if(!second_record[85]||new_rank<second_record[84:64])begin
                    new_slot<=bucket_slot+10'd1;
                    if(!second_record[85])anchor_count<=anchor_count+10'd1;
                    state<=WRITE_NEW;
                end else state<=WAIT_POINT;
            end
            KEEP_FIRST:state<=WRITE_NEW;
            WRITE_NEW:state<=WAIT_POINT;
            EXPORT_READ:state<=EXPORT_CAPTURE;
            EXPORT_CAPTURE:if(read_record[85])begin export_point<=read_record[63:0];state<=EXPORT_STAGE;end
                else export_continue();
            EXPORT_STAGE:begin
                exported<=exported+10'd1;
                if(fill==7)begin
                    fill<=0;export_finished<=export_index==767;state<=EXPORT_REQUEST;
                end else begin
                    fill<=fill+3'd1;
                    if(export_index==767)begin export_finished<=1;state<=EXPORT_PAD;end
                    else begin export_index<=export_index+10'd1;state<=EXPORT_READ;end
                end
            end
            EXPORT_PAD:if(fill==7)begin fill<=0;state<=EXPORT_REQUEST;end else fill<=fill+3'd1;
            EXPORT_REQUEST:if(req_valid&&req_ready)state<=EXPORT_RESPONSE;
            EXPORT_RESPONSE:if(rsp_valid&&rsp_ready)begin
                if(rsp_error||!rsp_drained)begin fault<=1;state<=FAILED;end
                else begin
                    address<=address+32'd64;
                    if(export_finished)begin
                        if(exported!=anchor_count)begin fault<=1;state<=FAILED;end else state<=COMPLETE;
                    end else begin export_index<=export_index+10'd1;state<=EXPORT_READ;end
                end
            end
            IDLE,COMPLETE,FAILED:begin end
            default:begin fault<=1;state<=FAILED;end
        endcase
    end
endmodule
