// Basic full-resolution shape recognition. Retains CCL, complete contour,
// immutable frame ownership, top-four and drain/quarantine behavior.
// Geometry: bounding-box area fill and contour border support for near-axis
// rectangles; aspect, area fill and squared radial band for basic circles.
// Rotated rectangles, precise fitting and 95% quality target are not promised.
module shape_recognition_frame #(
    parameter integer W=1920,H=1080,CONTOUR_CAPACITY=W*H
)(
    input wire clk,rst,cancel,
    input wire start_valid,output wire start_ready,input wire [95:0] start_scope,
    input wire [31:0] edge_base,visited_base,queue_base,contour_base,
    output wire result_valid,input wire result_ready,
    output reg [95:0] result_scope,output reg [2:0] result_error,
    output reg [3:0] target_valid,output reg [7:0] target_class,
    output reg [175:0] target_box,output reg [95:0] target_center2,
    output reg [191:0] target_area_twice,
    output reg [21:0] valid_count,unknown_count,output reg [7:0] unknown_reasons,
    output reg result_overflow,output reg [63:0] processing_cycles,
    output wire quarantined,output wire busy,
    output wire line_req_valid,input wire line_req_ready,output wire line_write,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    input wire line_rsp_valid,output wire line_rsp_ready,input wire [511:0] line_rdata,
    input wire line_error,line_drained
);
    localparam IDLE=0,FENCE=1,LIST_START=2,SCAN_START=3,SCAN=4,RDP_START=5,RDP_WAIT=6,
        MET_START=7,MET_READ=8,MET_WAIT=9,MET_SEND=10,MET_DONE=11,CLASS_START=12,CLASS_WAIT=13,
        ITEM=14,SKIP=15,RELEASE=16,FINISH=17,LIST_WAIT=18,DRAIN=19,RESULT=20,LOCKED=21,CLOSE=22,DECIDE=23,POINT_CALC=24;
    reg [4:0] state;
    // Private engines process exactly one leased frame at a time. Public
    // frame/config identity remains the complete 96-bit result_scope above.
    // A local transaction epoch avoids replicating that public metadata in
    // every sequential arithmetic stage. It is NOT a truncated frame ID.
    // Epoch wrap is safe only because RESULT/IDLE follow child completion or
    // DRAIN; an undrained response quarantines the engine until bus reset.
    reg [31:0] private_epoch;
    wire [95:0] private_scope = {64'b0, private_epoch};
    reg [1:0] owner;
    reg [31:0] eb,vb,qb,cb,point_word;
    reg [21:0] point_index;
    reg [2:0] skip_reason;
    reg abort_pending;
    wire cancel_all=cancel||abort_pending||state==DRAIN;
    wire scan_ready,component_valid,scan_done,scan_busy,scan_lock;
    wire [95:0] component_scope,scan_scope;
    wire [43:0] component_box;
    wire [21:0] component_pixels,component_points;
    wire clipped,overflow,no_contour;
    wire [31:0] component_address,components_completed;
    wire [2:0] scan_error;
    wire scan_req,scan_rsp_ready;
    wire [31:0] scan_addr,scan_data;
    wire [3:0] scan_mask;
    wire cache_ready,cache_valid,cache_error,cache_drained,cache_lock,cache_busy,invalidate_ready;
    wire [31:0] cache_data;
    wire cache_req=owner==0?scan_req:state==MET_READ;
    wire cache_rsp_ready=owner==0?scan_rsp_ready:state==MET_WAIT;
    wire [31:0] cache_addr=owner==0?scan_addr:component_address+{8'b0,point_index,2'b0};
    wire [31:0] cache_wdata=owner==0?scan_data:32'b0;
    wire [3:0] cache_mask=owner==0?scan_mask:4'b0;
    shape_word_cache cache(.clk(clk),.rst(rst),.invalidate_valid(state==FENCE),.invalidate_ready(invalidate_ready),
        .mem_req_valid(cache_req),.mem_req_ready(cache_ready),.mem_addr(cache_addr),.mem_wdata(cache_wdata),.mem_wstrb(cache_mask),
        .mem_rsp_valid(cache_valid),.mem_rsp_ready(cache_rsp_ready),.mem_rdata(cache_data),.mem_error(cache_error),.mem_drained(cache_drained),
        .line_req_valid(line_req_valid),.line_req_ready(line_req_ready),.line_write(line_write),.line_addr(line_addr),.line_wdata(line_wdata),
        .line_rsp_valid(line_rsp_valid),.line_rsp_ready(line_rsp_ready),.line_rdata(line_rdata),.line_error(line_error),.line_drained(line_drained),
        .quarantined(cache_lock),.busy(cache_busy));
    shape_component_scan #(.W(W),.H(H),.CONTOUR_CAPACITY(CONTOUR_CAPACITY)) scan(
        .clk(clk),.rst(rst),.cancel(cancel_all),.start_valid(state==SCAN_START&&!cancel_all),.start_ready(scan_ready),.start_scope(private_scope),
        .edge_base(eb),.visited_base(vb),.queue_base(qb),.contour_base(cb),
        .component_valid(component_valid),.component_ready(state==RELEASE&&!cancel_all),.component_scope(component_scope),
        .component_box(component_box),.component_pixels(component_pixels),.component_points(component_points),
        .component_clipped(clipped),.component_overflow(overflow),.component_no_contour(no_contour),.component_address(component_address),
        .done_valid(scan_done),.done_ready(state==FINISH||state==DRAIN),.done_scope(scan_scope),.done_error(scan_error),
        .components_completed(components_completed),.quarantined(scan_lock),.busy(scan_busy),
        .mem_req_valid(scan_req),.mem_req_ready(cache_ready&&owner==0),.mem_addr(scan_addr),.mem_wdata(scan_data),.mem_wstrb(scan_mask),
        .mem_rsp_valid(cache_valid&&owner==0),.mem_rsp_ready(scan_rsp_ready),.mem_rdata(cache_data),.mem_error(cache_error),.mem_drained(cache_drained));
    reg [1:0] class_value;
    reg [2:0] class_reason;
    wire [43:0] class_box=component_box;
    reg [47:0] class_area;
    reg signed [47:0] twice_area;
    reg [10:0] first_x,first_y,previous_x,previous_y;
    wire [10:0] px=point_word[10:0],py=point_word[21:11];
    wire [10:0] x0=component_box[10:0],y0=component_box[21:11];
    wire [10:0] x1=component_box[32:22],y1=component_box[43:33];
    wire [11:0] cx2={1'b0,x0}+{1'b0,x1},cy2={1'b0,y0}+{1'b0,y1};
    wire [23:0] class_center={cy2,cx2};
    wire [11:0] bw={1'b0,x1}-{1'b0,x0},bh={1'b0,y1}-{1'b0,y0};
    reg [23:0] box_area;
    reg [24:0] radius_reference;
    reg [25:0] min_radius,max_radius;
    reg [21:0] border_count;
    wire signed [12:0] dx=$signed({1'b0,px,1'b0})-$signed({1'b0,cx2});
    wire signed [12:0] dy=$signed({1'b0,py,1'b0})-$signed({1'b0,cy2});
    wire [25:0] sx=dx*dx,sy=dy*dy;
    wire [26:0] radius2={1'b0,sx}+{1'b0,sy};
    wire [21:0] cross_a=previous_x*py,cross_b=px*previous_y;
    wire signed [22:0] cross_delta=$signed({1'b0,cross_a})-$signed({1'b0,cross_b});
    wire [21:0] close_a=previous_x*first_y,close_b=first_x*previous_y;
    wire signed [22:0] close_delta=$signed({1'b0,close_a})-$signed({1'b0,close_b});
    wire signed [47:0] closed_area=twice_area+{{25{close_delta[22]}},close_delta};
    wire [23:0] bw2=bw*bw,bh2=bh*bh;
    wire on_border=(px-x0<=(bw>>4))||(x1-px<=(bw>>4))||
                   (py-y0<=(bh>>4))||(y1-py<=(bh>>4));
    // Bounds: 2,073,600 terms * max 22-bit cross fits signed 44 bits.
    // Area scales below use 48 bits; radii use 28 bits, no truncating shifts.
    wire [47:0] full_area2={23'd0,box_area,1'b0};
    wire rectangle_ok=(class_area<<3)>=((full_area2<<3)-full_area2)&&
        ({3'b0,border_count}<<3)>=(({3'b0,component_points}<<3)-{3'b0,component_points});
    wire aspect_ok=({2'b0,bw}<<2)<=(({2'b0,bh}<<2)+bh)&&
                   ({2'b0,bh}<<2)<=(({2'b0,bw}<<2)+bw);
    wire circle_ok=aspect_ok&&(class_area<<3)>=((full_area2<<2)+full_area2)&&
        (class_area<<3)<=((full_area2<<3)-full_area2)&&
        ({2'b0,min_radius}<<2)>=(({3'b0,radius_reference}<<1)+radius_reference)&&
        ({2'b0,max_radius}<<2)<=(({3'b0,radius_reference}<<2)+radius_reference);
    wire list_ready,item_ready,finish_ready,list_done,list_busy,list_overflow;
    wire [95:0] list_scope;
    wire [1:0] list_error;
    wire [21:0] list_valid_count,list_unknown_count;
    wire [7:0] list_unknown_reasons,list_class;
    wire [3:0] list_valid;
    wire [175:0] list_box;
    wire [95:0] list_center;
    wire [191:0] list_area;
    shape_target_list #(.W(W),.H(H)) targets(.clk(clk),.rst(rst),.cancel(cancel_all),
        .start_valid(state==LIST_START&&!cancel_all),.start_ready(list_ready),.start_scope(private_scope),
        .item_valid((state==ITEM||state==SKIP)&&!cancel_all),.item_ready(item_ready),.item_scope(private_scope),
        .item_class(state==SKIP?2'd0:class_value),.item_reason(state==SKIP?skip_reason:class_reason),
        .item_box(class_box),.item_center2(class_center),.item_area_twice(class_area),
        .finish_valid(state==FINISH&&!cancel_all),.finish_ready(finish_ready),
        .result_valid(list_done),.result_ready(state==LIST_WAIT||state==DRAIN),.result_scope(list_scope),.result_error(list_error),
        .result_overflow(list_overflow),.valid_count(list_valid_count),.unknown_count(list_unknown_count),.unknown_reasons(list_unknown_reasons),
        .target_valid(list_valid),.target_class(list_class),.target_box(list_box),.target_center2(list_center),.target_area_twice(list_area),.busy(list_busy));
    assign quarantined=cache_lock||scan_lock;
    assign start_ready=!rst&&!cancel&&!quarantined&&state==IDLE;
    assign result_valid=!rst&&state==RESULT;
    assign busy=state!=IDLE;
    // The top-four list retains its fields after RESULT is consumed. It is
    // restarted only for the next frame, after this engine's result handshake.
    // Borrow that immutable storage rather than copying a second result bank.
    // Error results remain all zero, including faults after list completion.
    assign target_valid=result_error==0?list_valid:'0;
    assign target_class=result_error==0?list_class:'0;
    assign target_box=result_error==0?list_box:'0;
    assign target_center2=result_error==0?list_center:'0;
    assign target_area_twice=result_error==0?list_area:'0;
    assign valid_count=result_error==0?list_valid_count:'0;
    assign unknown_count=result_error==0?list_unknown_count:'0;
    assign unknown_reasons=result_error==0?list_unknown_reasons:'0;
    assign result_overflow=result_error==0?list_overflow:'0;
    task fail(input [2:0] code);
        begin result_error<=code;abort_pending<=1;state<=DRAIN;end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;owner<=0;eb<=0;vb<=0;qb<=0;cb<=0;point_word<=0;point_index<=0;skip_reason<=0;
            abort_pending<=0;result_scope<=0;private_epoch<=0;result_error<=0;processing_cycles<=0;
            class_value<=0;class_reason<=0;class_area<=0;twice_area<=0;
            first_x<=0;first_y<=0;previous_x<=0;previous_y<=0;
            box_area<=0;radius_reference<=0;min_radius<=0;max_radius<=0;border_count<=0;
        end else begin
            if(state!=IDLE&&state!=RESULT&&state!=LOCKED)processing_cycles<=processing_cycles+1'b1;
            // Reader requests must remain presented and be drained before DRAIN.
            if(cancel&&state!=IDLE&&state!=RESULT&&state!=LOCKED)abort_pending<=1;
            if((cancel||abort_pending)&&state!=IDLE&&state!=RESULT&&state!=LOCKED&&state!=DRAIN&&state!=MET_READ&&state!=MET_WAIT)fail(2);
            else case(state)
                IDLE:if(start_valid&&start_ready)begin
                    eb<=edge_base;vb<=visited_base;qb<=queue_base;cb<=contour_base;result_scope<=start_scope;private_epoch<=private_epoch+1'b1;
                    result_error<=0;processing_cycles<=0;abort_pending<=0;owner<=0;state<=FENCE;
                end
                FENCE:if(invalidate_ready)state<=LIST_START;
                LIST_START:if(list_ready)state<=SCAN_START;
                SCAN_START:if(scan_ready)state<=SCAN;
                SCAN:if(scan_done)begin
                    if(scan_scope!=private_scope||scan_error!=0)fail(scan_error==3?3'd3:3'd1);else state<=FINISH;
                end else if(component_valid)begin
                    if(component_scope!=private_scope)fail(4);
                    else if(clipped||overflow||no_contour||component_points<4)begin skip_reason<=clipped?3'd1:3'd5;state<=SKIP;end
                    else if(component_box[32:22]-component_box[10:0]+1<32||component_box[43:33]-component_box[21:11]+1<32)begin skip_reason<=2;state<=SKIP;end
                    else begin owner<=1;state<=MET_START;end
                end
                MET_START:begin
                    point_index<=0;twice_area<=0;border_count<=0;class_value<=0;class_reason<=4;
                    min_radius<=26'h3ffffff;max_radius<=0;box_area<=bw*bh;
                    radius_reference<=({1'b0,bw2}+{1'b0,bh2})>>1;
                    state<=MET_READ;
                end
                MET_READ:if(cache_ready)state<=MET_WAIT;
                MET_WAIT:if(cache_valid)begin
                    if(cache_error)fail(cache_drained?3'd1:3'd3);
                    else if(cancel||abort_pending)fail(2);
                    else begin point_word<=cache_data;state<=POINT_CALC;end
                end
                POINT_CALC:begin
                    if(point_word[31:22]!=0||px<x0||px>x1||py<y0||py>y1)fail(4);
                    else begin
                        if(point_index==0)begin first_x<=px;first_y<=py;end
                        else twice_area<=twice_area+{{25{cross_delta[22]}},cross_delta};
                        previous_x<=px;previous_y<=py;
                        if(radius2<min_radius)min_radius<=radius2[25:0];
                        if(radius2>max_radius)max_radius<=radius2[25:0];
                        if(on_border)border_count<=border_count+1'b1;
                        if(point_index+1==component_points)state<=CLOSE;
                        else begin point_index<=point_index+1'b1;state<=MET_READ;end
                    end
                end
                CLOSE:begin class_area<=closed_area[47]?-closed_area:closed_area;state<=DECIDE;end
                DECIDE:begin
                    if(rectangle_ok)begin class_value<=2;class_reason<=0;end
                    else if(circle_ok)begin class_value<=1;class_reason<=0;end
                    state<=ITEM;
                end
                ITEM,SKIP:if(item_ready)begin owner<=0;state<=RELEASE;end
                RELEASE:state<=SCAN;
                FINISH:if(finish_ready)state<=LIST_WAIT;
                LIST_WAIT:if(list_done)begin
                    if(list_scope!=private_scope||list_error!=0)fail(4);
                    else begin

                        state<=RESULT;
                    end
                end
                DRAIN:if((!scan_busy||scan_lock)&&!list_busy&&(!cache_busy||cache_lock))begin
                    if(quarantined)result_error<=3;state<=RESULT;
                end
                RESULT:if(result_ready)state<=quarantined?LOCKED:IDLE;
                LOCKED:state<=LOCKED;
                default:fail(4);
            endcase
        end
    end
endmodule
