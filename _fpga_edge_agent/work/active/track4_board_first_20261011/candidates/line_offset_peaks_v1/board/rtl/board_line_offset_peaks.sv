// OP01…03：完整49偏移计票，radius1 NMS，同票左优先，全部峰按偏移升序交付。
// 父先关闭RP成功回调，再提交包括非投票点在内的全部ordinal；失败时整次前缀作废。
module board_line_offset_peaks #(
    parameter integer WIDTH=1920,HEIGHT=1080
)(
    input wire clk,rst,start,output wire start_ready,
    input wire [20:0] point_limit,minimum_support,
    input wire point_valid,output wire point_ready,input wire [20:0] ordinal,
    input wire offset_valid,input wire [5:0] offset_index,input wire normal_ok,
    output wire peak_valid,input wire peak_ready,
    output wire [5:0] peak_index,output wire [20:0] peak_votes,
    output reg [5:0] peak_count,output wire done,quiet,output reg error
);
    localparam IDLE=0,CLEAR=1,COLLECT=2,VOTE_READ_LO=3,VOTE_CAPTURE_LO=4,
        VOTE_READ_HI=5,VOTE_CAPTURE_HI=6,VOTE_WRITE_LO=7,VOTE_WRITE_HI=8,
        SCAN_READ_LO=9,SCAN_CAPTURE_LO=10,SCAN_READ_HI=11,SCAN_CAPTURE_HI=12,
        QUALIFY=13,PUBLISH=14,NEXT=15,COMPLETE=16,FAILED=17;
    reg [4:0] state;
    reg [20:0] locked_limit,locked_min,seen,updated_count,left_count,center_count,right_count;
    reg [6:0] clear_word;
    reg [5:0] vote_bin,candidate;
    reg [1:0] neighbor;
    reg [15:0] read_low;

    wire point_fire=point_valid&&point_ready;
    wire cast_vote=normal_ok&&offset_valid;
    wire point_legal=ordinal==seen && (!cast_vote || offset_index<=6'd48);
    wire [21:0] next_seen={1'b0,seen}+22'd1;
    wire configuration_legal=WIDTH>=1 && WIDTH<=1920 && HEIGHT>=1 && HEIGHT<=1080 &&
        WIDTH*HEIGHT<=2073600 && point_limit<=WIDTH*HEIGHT &&
        minimum_support!=0 && minimum_support<=WIDTH*HEIGHT;

    assign start_ready=!rst&&(state==IDLE||state==COMPLETE);
    assign point_ready=!rst&&state==COLLECT&&seen<locked_limit;
    assign peak_valid=!rst&&state==PUBLISH;
    assign peak_index=candidate;
    assign peak_votes=center_count;
    assign done=!rst&&state==COMPLETE;
    assign quiet=!rst&&(state==IDLE||state==COMPLETE||state==FAILED);

    wire vote_read=state==VOTE_READ_LO||state==VOTE_CAPTURE_LO||
        state==VOTE_READ_HI||state==VOTE_CAPTURE_HI;
    wire read_high=state==VOTE_READ_HI||state==VOTE_CAPTURE_HI||
        state==SCAN_READ_HI||state==SCAN_CAPTURE_HI;
    wire boundary_neighbor=(candidate==0&&neighbor==0)||(candidate==48&&neighbor==2);
    // 边界邻居直接为0；回绕的scan_bin从不进入实际读取/采样路径。
    wire [5:0] scan_bin=neighbor==0 ? candidate-6'd1 : neighbor==1 ? candidate : candidate+6'd1;
    wire [8:0] read_address={2'd0,(vote_read ? vote_bin : scan_bin),read_high};
    wire ram_write=!rst&&(state==CLEAR||state==VOTE_WRITE_LO||state==VOTE_WRITE_HI);
    wire [8:0] write_address=state==CLEAR ? {2'd0,clear_word} :
        {2'd0,vote_bin,(state==VOTE_WRITE_HI)};
    wire [15:0] write_data=state==CLEAR ? 16'd0 : state==VOTE_WRITE_HI ?
        {11'd0,updated_count[20:16]} : updated_count[15:0];
    wire ram_read=!rst&&(state==VOTE_READ_LO||state==VOTE_READ_HI||
        ((state==SCAN_READ_LO||state==SCAN_READ_HI)&&!boundary_neighbor));
    wire [15:0] ram_q;
    EFX_RAM10 #(.READ_WIDTH(16),.WRITE_WIDTH(16),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_UNKNOWN")) votes(
        .WCLK(clk),.WE({2{ram_write}}),.WCLKE(1'b1),.WADDREN(1'b1),
        .WDATA(write_data),.WADDR(write_address),
        .RCLK(clk),.RE(ram_read),.RST(1'b0),.RADDREN(1'b1),.RDATA(ram_q),.RADDR(read_address));
    wire [20:0] read_count={ram_q[4:0],read_low};
    wire [21:0] incremented_count={1'b0,read_count}+22'd1;
    wire read_format_legal=ram_q[15:5]==0&&read_count<=locked_limit;
    wire selected_peak=center_count>=locked_min&&center_count>left_count&&center_count>=right_count;

    task automatic fail_closed;
        begin error<=1;state<=FAILED;end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;locked_limit<=0;locked_min<=0;seen<=0;updated_count<=0;
            left_count<=0;center_count<=0;right_count<=0;clear_word<=0;vote_bin<=0;
            candidate<=0;neighbor<=0;read_low<=0;peak_count<=0;error<=0;
        end else begin
            case(state)
                IDLE,COMPLETE:if(start&&start_ready)begin
                    locked_limit<=point_limit;locked_min<=minimum_support;seen<=0;
                    clear_word<=0;candidate<=0;neighbor<=0;peak_count<=0;error<=0;
                    left_count<=0;center_count<=0;right_count<=0;
                    if(!configuration_legal)fail_closed();else state<=CLEAR;
                end
                CLEAR:begin
                    // 末字97在此沿真实写入；下一阶段只能在该写入后读票。
                    if(clear_word==97)state<=locked_limit==0 ? SCAN_READ_LO : COLLECT;
                    else clear_word<=clear_word+7'd1;
                end
                COLLECT:if(point_fire)begin
                    if(!point_legal||next_seen[21]||next_seen>locked_limit)fail_closed();
                    else begin
                        seen<=next_seen[20:0];
                        if(cast_vote)begin vote_bin<=offset_index;state<=VOTE_READ_LO;end
                        else if(next_seen==locked_limit)state<=SCAN_READ_LO;
                    end
                end
                VOTE_READ_LO:state<=VOTE_CAPTURE_LO;
                VOTE_CAPTURE_LO:begin read_low<=ram_q;state<=VOTE_READ_HI;end
                VOTE_READ_HI:state<=VOTE_CAPTURE_HI;
                VOTE_CAPTURE_HI:begin
                    if(!read_format_legal||read_count>=locked_limit||incremented_count[21]||
                        incremented_count>locked_limit)fail_closed();
                    else begin updated_count<=incremented_count[20:0];state<=VOTE_WRITE_LO;end
                end
                VOTE_WRITE_LO:state<=VOTE_WRITE_HI;
                VOTE_WRITE_HI:begin
                    // 最后token也须在高字写回后才进入NMS，不能扫描半更新的bin。
                    state<=seen==locked_limit ? SCAN_READ_LO : COLLECT;
                end
                SCAN_READ_LO:begin
                    if(boundary_neighbor)begin
                        if(neighbor==0)begin left_count<=0;neighbor<=1;end
                        else begin right_count<=0;state<=QUALIFY;end
                    end else state<=SCAN_CAPTURE_LO;
                end
                SCAN_CAPTURE_LO:begin read_low<=ram_q;state<=SCAN_READ_HI;end
                SCAN_READ_HI:state<=SCAN_CAPTURE_HI;
                SCAN_CAPTURE_HI:begin
                    if(!read_format_legal)fail_closed();
                    else case(neighbor)
                        0:begin left_count<=read_count;neighbor<=1;state<=SCAN_READ_LO;end
                        1:begin center_count<=read_count;neighbor<=2;state<=SCAN_READ_LO;end
                        2:begin right_count<=read_count;state<=QUALIFY;end
                        default:fail_closed();
                    endcase
                end
                QUALIFY:begin
                    if(selected_peak)begin
                        if(peak_count>=25)fail_closed();else state<=PUBLISH;
                    end else state<=NEXT;
                end
                PUBLISH:if(peak_valid&&peak_ready)begin
                    peak_count<=peak_count+6'd1;state<=NEXT;
                end
                NEXT:begin
                    if(candidate==48)state<=COMPLETE;
                    else begin candidate<=candidate+6'd1;neighbor<=0;state<=SCAN_READ_LO;end
                end
                FAILED:begin end
                default:fail_closed();
            endcase
        end
    end
endmodule
