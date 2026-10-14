// 同帧最终EDGE1 + GRAD32 -> POINT64。完整扫描后且全部写事务真实排空才提交。
// POINT64 v2={1'b0,theta9,y11,x11,GRAD32}；theta是实际角度核结果，末尾填充不计入point_count。
module board_recognition_points #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter [32:0] ADDRESS_BYTES=33'h10000000,
    parameter bit BORROW_SCOPE=1'b0
)(
    input wire clk,rst,start,input wire [95:0] scope,
    input wire [31:0] edge_base,gradient_base,point_base,
    output wire start_ready,done,output reg fault,output reg [20:0] point_count,
    output wire req_valid,input wire req_ready,output wire req_write,output wire [31:0] req_addr,
    input wire rsp_valid,output wire rsp_ready,input wire [511:0] rsp_data,
    input wire rsp_error,rsp_drained,
    output wire pack_valid,output wire [2:0] pack_index,output wire [63:0] pack_data
);
    localparam integer PIXELS=WIDTH*HEIGHT;
    localparam IDLE=0,EDGE_REQUEST=1,EDGE_WAIT=2,EDGE_LOAD=3,GRAD_REQUEST=4,
        GRAD_WAIT=5,SCAN=6,PACK_BEGIN=7,PACK_READ=8,PACK_CAPTURE=9,
        WRITE_REQUEST=10,WRITE_WAIT=11,RESUME=12,COMPLETE=13,FAILED=14,ANGLE_REQUEST=15,ANGLE_CAPTURE=16,PACK_PAD=17;
    reg [4:0] state;
    wire [95:0] locked_scope;
    generate if(BORROW_SCOPE)begin:borrowed_scope
        // 板端scope来自父RPC锁定的cj，直到所有消息关闭且整帧done消费才允许换job。
        assign locked_scope=scope;
    end else begin:copied_scope
        reg [95:0] snapshot;
        assign locked_scope=snapshot;
        always @(posedge clk)if(rst)snapshot<=0;
            else if(start&&start_ready)snapshot<=scope;
    end endgenerate
    reg [31:0] edge_address,gradient_address,point_address;
    reg [4:0] chunk,queue_write,queue_read;
    reg [5:0] queue_count;
    reg [3:0] load_index,lane,pack_total;
    reg [2:0] pack_slot;
    reg [15:0] edge_mask;
    reg [20:0] scanned_pixels,written_points;
    reg [10:0] x,y;
    reg image_finished;
    wire scan_fire=state==SCAN&&rsp_valid;
    wire [31:0] gradient_word=rsp_data[lane*32+:32];
    wire angle_req_valid,angle_req_ready,angle_rsp_valid,angle_rsp_ready,angle_quiet;
    wire [175:0] angle_id={8'd1,43'd0,point_count,8'd0,locked_scope};
    wire [621:0] angle_req_body={378'd0,gradient_word[21:0],9'd0,2'd0,5'd8,8'd1,11'(HEIGHT),11'(WIDTH),angle_id};
    wire [584:0] angle_rsp_body;
    wire angle_result_good=angle_rsp_body[175:0]==angle_id&&angle_rsp_body[180:176]==8&&
        angle_rsp_body[199:181]==0&&angle_rsp_body[584:209]==0;
    wire include_point=state==ANGLE_CAPTURE&&angle_rsp_valid&&rsp_valid&&angle_result_good;
    wire [63:0] point_word={1'd0,angle_rsp_body[208:200],y,x,gradient_word};
    wire [79:0] queue_input={16'd0,point_word};
    wire [79:0] queue_output;
    wire [39:0] edge_output;
    wire [39:0] edge_input={8'd0,rsp_data[load_index*32+:32]};
    wire edge_load=state==EDGE_LOAD&&rsp_valid;
    wire gradient_request_fire=state==GRAD_REQUEST&&req_valid&&req_ready;
    wire queue_read_enable=state==PACK_READ;
    assign start_ready=!rst&&(state==IDLE||state==COMPLETE)&&angle_quiet;
    assign done=!rst&&state==COMPLETE;
    assign req_valid=!rst&&(state==EDGE_REQUEST||state==GRAD_REQUEST||state==WRITE_REQUEST);
    assign req_write=state==WRITE_REQUEST;
    assign req_addr=state==EDGE_REQUEST?edge_address:state==GRAD_REQUEST?gradient_address:point_address;
    // 读回复由物理服务持有；读取16个像素后才消费，避免再复制一份512位GRAD。
    assign rsp_ready=!rst&&(state==WRITE_WAIT||(state==EDGE_LOAD&&load_index==15)||
        (state==SCAN&&lane==15&&!edge_mask[lane])||(include_point&&lane==15));
    assign pack_valid=!rst&&(state==PACK_CAPTURE||state==PACK_PAD);
    assign pack_index=pack_slot;
    assign pack_data=state==PACK_PAD?64'd0:queue_output[63:0];
    assign angle_req_valid=!rst&&state==ANGLE_REQUEST&&rsp_valid;
    assign angle_rsp_ready=!rst&&state==ANGLE_CAPTURE&&rsp_valid;
    angle_core #(.BORROW_REQUEST(1'b1)) direction(
        .clk,.rst,.req_valid(angle_req_valid),.req_body(angle_req_body),.req_ready(angle_req_ready),
        .rsp_valid(angle_rsp_valid),.rsp_body(angle_rsp_body),.rsp_ready(angle_rsp_ready),
        .cancel_valid(1'b0),.cancel_id(176'd0),.quiet(angle_quiet));
    task automatic advance_pixel;
        begin
            scanned_pixels<=scanned_pixels+21'd1;
            if(x==WIDTH-1)begin x<=0;y<=y+11'd1;end else x<=x+11'd1;
            if(lane==15)begin
                gradient_address<=gradient_address+32'd64;
                image_finished<=scanned_pixels==PIXELS-1;state<=PACK_BEGIN;
            end else begin lane<=lane+4'd1;state<=SCAN;end
        end
    endtask

    // EDGE缓存512位用两块RAM，点队列32×64用四块RAM；读写均为当前core时钟。
    for(genvar s=0;s<2;s=s+1)begin: edge_stripes
        EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_UNKNOWN")) memory(
            .WCLK(clk),.WE({2{edge_load}}),.WCLKE(1'b1),.WADDREN(1'b1),
            .WDATA(edge_input[s*20+:20]),.WADDR({5'd0,load_index}),
            .RCLK(clk),.RE(gradient_request_fire),.RST(1'b0),.RADDREN(1'b1),
            .RDATA(edge_output[s*20+:20]),.RADDR({5'd0,chunk[4:1]}));
    end
    for(genvar s=0;s<4;s=s+1)begin: point_stripes
        EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_UNKNOWN")) memory(
            .WCLK(clk),.WE({2{include_point}}),.WCLKE(1'b1),.WADDREN(1'b1),
            .WDATA(queue_input[s*20+:20]),.WADDR({4'd0,queue_write}),
            .RCLK(clk),.RE(queue_read_enable),.RST(1'b0),.RADDREN(1'b1),
            .RDATA(queue_output[s*20+:20]),.RADDR({4'd0,queue_read}));
    end

    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;edge_address<=0;gradient_address<=0;point_address<=0;
            chunk<=0;queue_write<=0;queue_read<=0;queue_count<=0;load_index<=0;lane<=0;
            pack_total<=0;pack_slot<=0;edge_mask<=0;scanned_pixels<=0;written_points<=0;
            x<=0;y<=0;image_finished<=0;fault<=0;point_count<=0;
        end else if(start&&start_ready)begin
            edge_address<=edge_base;gradient_address<=gradient_base;point_address<=point_base;
            chunk<=0;queue_write<=0;queue_read<=0;queue_count<=0;load_index<=0;lane<=0;
            pack_total<=0;pack_slot<=0;scanned_pixels<=0;written_points<=0;x<=0;y<=0;
            image_finished<=0;fault<=0;point_count<=0;
            if(PIXELS%512!=0||edge_base[5:0]!=0||gradient_base[5:0]!=0||point_base[5:0]!=0||
                ({1'b0,edge_base}+33'(PIXELS/8))>ADDRESS_BYTES||
                ({1'b0,gradient_base}+33'(PIXELS*4))>ADDRESS_BYTES||
                ({1'b0,point_base}+33'(PIXELS*8))>ADDRESS_BYTES)begin
                state<=FAILED;fault<=1;
            end else state<=EDGE_REQUEST;
        end else case(state)
            EDGE_REQUEST:if(req_valid&&req_ready)state<=EDGE_WAIT;
            EDGE_WAIT:if(rsp_valid)begin
                if(rsp_error||!rsp_drained)begin state<=FAILED;fault<=1;end
                else begin load_index<=0;state<=EDGE_LOAD;end
            end
            EDGE_LOAD:if(edge_load)begin
                if(load_index==15)begin chunk<=0;state<=GRAD_REQUEST;end
                else load_index<=load_index+4'd1;
            end
            GRAD_REQUEST:if(gradient_request_fire)state<=GRAD_WAIT;
            GRAD_WAIT:if(rsp_valid)begin
                if(rsp_error||!rsp_drained)begin state<=FAILED;fault<=1;end
                else begin
                    edge_mask<=chunk[0]?edge_output[31:16]:edge_output[15:0];
                    lane<=0;state<=SCAN;
                end
            end
            SCAN:if(scan_fire)begin
                if(scanned_pixels>=PIXELS||(edge_mask[lane]&&(queue_count>=32||point_count>=PIXELS)))begin
                    state<=FAILED;fault<=1;
                end else if(edge_mask[lane])state<=ANGLE_REQUEST;
                else advance_pixel();
            end
            ANGLE_REQUEST:if(angle_req_valid&&angle_req_ready)state<=ANGLE_CAPTURE;
            ANGLE_CAPTURE:if(angle_rsp_valid&&angle_rsp_ready)begin
                if(!angle_result_good)begin state<=FAILED;fault<=1;end
                else begin
                    queue_write<=queue_write+5'd1;queue_count<=queue_count+6'd1;
                    point_count<=point_count+21'd1;advance_pixel();
                end
            end
            PACK_BEGIN:begin
                if(queue_count>=8||(image_finished&&queue_count!=0))begin
                    pack_total<=queue_count>=8?4'd8:{1'b0,queue_count[2:0]};
                    pack_slot<=0;state<=PACK_READ;
                end else state<=RESUME;
            end
            PACK_READ:state<=PACK_CAPTURE;
            PACK_CAPTURE:begin
                queue_read<=queue_read+5'd1;queue_count<=queue_count-6'd1;
                if({1'b0,pack_slot}+4'd1==pack_total)begin
                    if(pack_slot==7)state<=WRITE_REQUEST;
                    else begin pack_slot<=pack_slot+3'd1;state<=PACK_PAD;end
                end
                else begin pack_slot<=pack_slot+3'd1;state<=PACK_READ;end
            end
            // 每个物理64字节块均提交八个字；尾部补零不弹队列，也不增加逻辑点数。
            PACK_PAD:begin
                if(pack_slot==7)state<=WRITE_REQUEST;
                else pack_slot<=pack_slot+3'd1;
            end
            WRITE_REQUEST:if(req_valid&&req_ready)state<=WRITE_WAIT;
            WRITE_WAIT:if(rsp_valid&&rsp_ready)begin
                if(rsp_error||!rsp_drained)begin state<=FAILED;fault<=1;end
                else begin
                    written_points<=written_points+{17'd0,pack_total};
                    point_address<=point_address+32'd64;state<=PACK_BEGIN;
                end
            end
            RESUME:begin
                if(image_finished)begin
                    if(queue_count!=0||scanned_pixels!=PIXELS||written_points!=point_count)begin
                        state<=FAILED;fault<=1;
                    end else state<=COMPLETE;
                end else if(chunk==31)begin edge_address<=edge_address+32'd64;state<=EDGE_REQUEST;end
                else begin chunk<=chunk+5'd1;state<=GRAD_REQUEST;end
            end
            IDLE,COMPLETE,FAILED:begin end
            default:begin state<=FAILED;fault<=1;end
        endcase
    end
endmodule
