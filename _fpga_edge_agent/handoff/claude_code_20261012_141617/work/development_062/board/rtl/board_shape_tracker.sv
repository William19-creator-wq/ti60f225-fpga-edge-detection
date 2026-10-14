// 初版候选显示：四组可见强轮廓包围盒/方向分布；不声称完整复杂识别已实现。
// 原四组规则逐点保留。小RAM串行读改写，finish后结清两像素和四组输出才finished。
module board_shape_tracker(
    input wire clk,rst,start,finish,input wire [10:0] threshold,
    input wire grad_valid,output wire grad_ready,input wire [184:0] grad_payload,
    output wire finished,
    output reg [3:0] box_valid,output reg [3:0][10:0] box_x0,box_y0,box_x1,box_y1,
    output reg [3:0] is_circle
);
    localparam CLEAR=0,WAIT_PAIR=1,CHECK_POINT=2,BOX_READ=3,BOX_CAPTURE=4,
        BOX_WRITE=5,HIST_READ=6,HIST_WRITE=7,NEXT_POINT=8,
        FINAL_BOX_READ=9,FINAL_BOX_CAPTURE=10,FINAL_HIST_READ=11,
        FINAL_HIST_CAPTURE=12,FINAL_WRITE=13,COMPLETE=14;
    reg [3:0] state,clear_index;
    reg lane;
    // 仅保留原消息的坐标和两份GRAD；身份/marker仍由整帧调用者核对。
    reg [85:0] sample;
    reg [10:0] locked_threshold;
    reg [1:0] scan_slot,selected_slot,free_slot,final_direction;
    reg free_valid;
    reg [65:0] selected_record,final_record;
    reg [20:0] peak;
    // {used,count21,ymax11,ymin11,xmax11,xmin11}。
    (* syn_ramstyle="block_ram" *) reg [65:0] boxes[0:3];
    (* syn_ramstyle="block_ram" *) reg [20:0] histograms[0:15];
    reg [65:0] box_q;
    reg [20:0] histogram_q;
    reg [1:0] box_read_address,box_write_address;
    reg [3:0] histogram_address;
    reg box_we,histogram_we;
    reg [65:0] box_write_data;
    reg [20:0] histogram_write_data;
    wire [10:0] px=sample[74:64]+{10'd0,lane},py=sample[85:75];
    wire signed [10:0] gx=lane?sample[42:32]:sample[10:0];
    wire signed [10:0] gy=lane?sample[53:43]:sample[21:11];
    wire [10:0] ax=gx[10]?-gx:gx,ay=gy[10]?-gy:gy;
    wire [11:0] magnitude={1'b0,ax}+{1'b0,ay};
    wire [1:0] direction={1'b0,ax}>({1'b0,ay}<<1)?0:
        {1'b0,ay}>({1'b0,ax}<<1)?2:(gx[10]==gy[10]?1:3);
    wire box_matches=box_q[65]&&{1'b0,px}+12'd48>={1'b0,box_q[10:0]}&&
        {1'b0,px}<={1'b0,box_q[21:11]}+12'd48&&
        {1'b0,py}+12'd48>={1'b0,box_q[32:22]}&&
        {1'b0,py}<={1'b0,box_q[43:33]}+12'd48;
    wire [11:0] bw={1'b0,final_record[21:11]}-{1'b0,final_record[10:0]}+12'd1;
    wire [11:0] bh={1'b0,final_record[43:33]}-{1'b0,final_record[32:22]}+12'd1;
    wire [20:0] final_count=final_record[64:44];
    assign grad_ready=!rst&&state==WAIT_PAIR&&!finish;
    assign finished=!rst&&state==COMPLETE;
    always @(posedge clk)begin
        box_q<=boxes[box_read_address];
        histogram_q<=histograms[histogram_address];
        if(box_we)boxes[box_write_address]<=box_write_data;
        if(histogram_we)histograms[histogram_address]<=histogram_write_data;
    end
    always @*begin
        box_read_address=scan_slot;box_write_address=selected_slot;
        histogram_address={selected_slot,direction};
        box_we=0;histogram_we=0;box_write_data=selected_record;
        histogram_write_data=histogram_q+21'd1;
        if(state==CLEAR)begin
            box_we=clear_index<4;box_write_address=clear_index[1:0];box_write_data=0;
            histogram_address=clear_index;histogram_we=1;histogram_write_data=0;
        end
        if(state==BOX_WRITE)begin
            box_we=1;box_write_data[65]=1;
            box_write_data[64:44]=selected_record[64:44]+21'd1;
            if(!selected_record[65])begin
                box_write_data[10:0]=px;box_write_data[21:11]=px;
                box_write_data[32:22]=py;box_write_data[43:33]=py;
            end else begin
                if(px<selected_record[10:0])box_write_data[10:0]=px;
                if(px>selected_record[21:11])box_write_data[21:11]=px;
                if(py<selected_record[32:22])box_write_data[32:22]=py;
                if(py>selected_record[43:33])box_write_data[43:33]=py;
            end
        end
        if(state==HIST_WRITE)histogram_we=1;
        if(state==FINAL_HIST_READ||state==FINAL_HIST_CAPTURE)
            histogram_address={scan_slot,final_direction};
        if(rst||start)begin box_we=0;histogram_we=0;end
    end
    always @(posedge clk)begin
        if(rst||start)begin
            state<=CLEAR;clear_index<=0;lane<=0;sample<=0;locked_threshold<=threshold;
            scan_slot<=0;selected_slot<=0;free_slot<=0;free_valid<=0;
            final_direction<=0;selected_record<=0;final_record<=0;peak<=0;
            box_valid<=0;is_circle<=0;box_x0<=0;box_y0<=0;box_x1<=0;box_y1<=0;
        end else case(state)
            CLEAR:if(clear_index==15)state<=WAIT_PAIR;else clear_index<=clear_index+4'd1;
            WAIT_PAIR:begin
                if(finish)begin scan_slot<=0;state<=FINAL_BOX_READ;end
                else if(grad_valid&&grad_ready)begin sample<=grad_payload[85:0];lane<=0;state<=CHECK_POINT;end
            end
            CHECK_POINT:begin
                if(magnitude<{1'b0,locked_threshold})state<=NEXT_POINT;
                else begin scan_slot<=0;free_valid<=0;state<=BOX_READ;end
            end
            BOX_READ:state<=BOX_CAPTURE;
            BOX_CAPTURE:begin
                if(box_matches)begin selected_slot<=scan_slot;selected_record<=box_q;state<=BOX_WRITE;end
                else if(scan_slot==3)begin
                    if(free_valid||!box_q[65])begin
                        selected_slot<=free_valid?free_slot:scan_slot;selected_record<=0;state<=BOX_WRITE;
                    end else state<=NEXT_POINT;
                end else begin
                    if(!box_q[65]&&!free_valid)begin free_valid<=1;free_slot<=scan_slot;end
                    scan_slot<=scan_slot+2'd1;state<=BOX_READ;
                end
            end
            BOX_WRITE:state<=HIST_READ;
            HIST_READ:state<=HIST_WRITE;
            HIST_WRITE:state<=NEXT_POINT;
            NEXT_POINT:begin
                if(lane)state<=WAIT_PAIR;else begin lane<=1;state<=CHECK_POINT;end
            end
            FINAL_BOX_READ:state<=FINAL_BOX_CAPTURE;
            FINAL_BOX_CAPTURE:begin final_record<=box_q;final_direction<=0;peak<=0;state<=FINAL_HIST_READ;end
            FINAL_HIST_READ:state<=FINAL_HIST_CAPTURE;
            FINAL_HIST_CAPTURE:begin
                if(histogram_q>peak)peak<=histogram_q;
                if(final_direction==3)state<=FINAL_WRITE;
                else begin final_direction<=final_direction+2'd1;state<=FINAL_HIST_READ;end
            end
            FINAL_WRITE:begin
                box_valid[scan_slot]<=final_record[65]&&final_count>=128&&bw>=96&&bh>=96&&
                    bw<=1024&&bh<=1024&&bw<=bh*3&&bh<=bw*3&&final_count<((bw+bh)<<4);
                is_circle[scan_slot]<=bw*4>=bh*3&&bh*4>=bw*3&&({1'b0,peak}<<1)<{1'b0,final_count};
                box_x0[scan_slot]<=final_record[10:0];box_x1[scan_slot]<=final_record[21:11];
                box_y0[scan_slot]<=final_record[32:22];box_y1[scan_slot]<=final_record[43:33];
                if(scan_slot==3)state<=COMPLETE;
                else begin scan_slot<=scan_slot+2'd1;state<=FINAL_BOX_READ;end
            end
            COMPLETE:begin end
            default:state<=COMPLETE;
        endcase
    end
endmodule
