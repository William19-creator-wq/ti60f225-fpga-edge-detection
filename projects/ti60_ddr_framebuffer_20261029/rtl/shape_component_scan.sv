// Serialized DDR edge scan, eight-connected components and Moore outer trace.
// Memory port is one ordered 32-bit request/response with byte strobes. A later
// cache/line adapter may coalesce it, but a response means the write is complete.
// Edge image is read-only, byte per pixel. Visited is byte per pixel; the BFS
// queue has W*H 32-bit entries, sufficient even for an all-edge frame. The outer
// contour is stored as {10'b0,y[10:0],x[10:0]}. A pathological contour can revisit
// pixels; exceeding CONTOUR_CAPACITY yields explicit component_overflow, never
// a guessed classification. Consumer must reject such a partial contour.
// component_ready releases the contour storage, so it must wait until ALL
// consumer reads have drained. Source/result and scratch ranges are disjoint.
// Cancel drains an accepted/presented request before returning. An undrained
// memory fault quarantines this engine until reset AND external bus reset.
module shape_component_scan #(
    parameter integer W=1920,H=1080,CONTOUR_CAPACITY=W*H
)(
    input wire clk,rst,cancel,
    input wire start_valid,output wire start_ready,input wire [95:0] start_scope,
    input wire [31:0] edge_base,visited_base,queue_base,contour_base,
    output wire component_valid,input wire component_ready,
    output reg [95:0] component_scope,
    output reg [43:0] component_box,
    output reg [21:0] component_pixels,component_points,
    output reg component_clipped,component_overflow,component_no_contour,
    output reg [31:0] component_address,
    output wire done_valid,input wire done_ready,
    output reg [95:0] done_scope,output reg [2:0] done_error,
    output reg [31:0] components_completed,
    output reg quarantined,output wire busy,
    output wire mem_req_valid,input wire mem_req_ready,
    output reg [31:0] mem_addr,mem_wdata,output reg [3:0] mem_wstrb,
    input wire mem_rsp_valid,output wire mem_rsp_ready,
    input wire [31:0] mem_rdata,input wire mem_error,mem_drained
);
    localparam integer N=W*H,VBYTES=((N+3)/4)*4;
    localparam IDLE=0,CLEAR=1,CLEAR_ACK=2,SCAN=3,SCAN_VISIT=4,SCAN_EDGE=5,
        PUSH_MARK=6,PUSH_QUEUE=7,PUSH_DONE=8,POP=9,POP_DONE=10,
        NEIGHBOR=11,NEIGHBOR_VISIT=12,NEIGHBOR_EDGE=13,TRACE_START=14,
        TRACE=15,TRACE_EDGE=16,TRACE_APPEND=17,TRACE_NEXT=18,
        COMPONENT=19,ADVANCE=20,DONE=21,LOCKED=22,MEM_REQ=23,MEM_WAIT=24;
    reg [4:0] state,resume_state;
    reg [31:0] eb,vb,qb,cb,clear_offset,scan_index;
    reg [10:0] scan_x,scan_y,seed_x,seed_y,pop_x,pop_y,nx,ny,tx,ty,next_x,next_y,first_x,first_y;
    reg [10:0] min_x,min_y,max_x,max_y;
    reg [21:0] head,tail,trace_count;
    reg [3:0] neighbor_index,attempts;
    reg [2:0] direction;
    reg [2:0] next_back;
    reg first_found,push_seed,abort_pending;
    reg [31:0] reply;
    wire [7:0] reply_byte=reply>>(mem_addr[1:0]*8);
    wire [31:0] neighbor_pixel=32'(ny)*W+32'(nx);
    reg signed [12:0] neighbor_x,neighbor_y;
    reg [2:0] lookup;
    function automatic signed [12:0] offset_x(input [2:0] d);
        case(d)0,6,7:offset_x=-1;2,3,4:offset_x=1;default:offset_x=0;endcase
    endfunction
    function automatic signed [12:0] offset_y(input [2:0] d);
        case(d)0,1,2:offset_y=-1;4,5,6:offset_y=1;default:offset_y=0;endcase
    endfunction
    function automatic [2:0] back_direction(input [2:0] d);
        case(d)0,7:back_direction=5;1,2:back_direction=7;3,4:back_direction=1;default:back_direction=3;endcase
    endfunction
    function automatic ranges_overlap(input [31:0] a,input integer al,input [31:0] b,input integer bl);
        ranges_overlap=({32'd0,a}<{32'd0,b}+64'(bl))&&({32'd0,b}<{32'd0,a}+64'(al));
    endfunction
    always @*begin
        lookup=state==NEIGHBOR?neighbor_index[2:0]:direction;
        neighbor_x=$signed({2'b0,state==NEIGHBOR?pop_x:tx})+offset_x(lookup);
        neighbor_y=$signed({2'b0,state==NEIGHBOR?pop_y:ty})+offset_y(lookup);
    end
    assign start_ready=!rst&&!cancel&&!quarantined&&state==IDLE;
    assign component_valid=!rst&&state==COMPONENT&&!abort_pending&&!cancel;
    assign done_valid=!rst&&state==DONE;
    assign busy=state!=IDLE;
    assign mem_req_valid=!rst&&state==MEM_REQ;
    assign mem_rsp_ready=!rst&&state==MEM_WAIT;
    task access(input [31:0] address,input [31:0] data,input [3:0] strobes,input [4:0] continuation);
        begin mem_addr<=address;mem_wdata<=data;mem_wstrb<=strobes;resume_state<=continuation;state<=MEM_REQ;end
    endtask
    task read_byte(input [31:0] address,input [4:0] continuation);
        begin access(address,0,0,continuation);end
    endtask
    task visit(input [31:0] address,input [4:0] continuation);
        begin access(address,32'd1<<(address[1:0]*8),4'b0001<<address[1:0],continuation);end
    endtask
    task publish_component;
        begin
            component_box<={max_y,max_x,min_y,min_x};component_pixels<=tail;
            component_points<=trace_count;component_address<=cb;
            component_clipped<=min_x==0||min_y==0||max_x==W-1||max_y==H-1;
            state<=COMPONENT;
        end
    endtask
    task fail(input [2:0] code);
        begin done_error<=code;state<=DONE;end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;resume_state<=IDLE;eb<=0;vb<=0;qb<=0;cb<=0;
            clear_offset<=0;scan_index<=0;scan_x<=0;scan_y<=0;seed_x<=0;seed_y<=0;
            pop_x<=0;pop_y<=0;nx<=0;ny<=0;tx<=0;ty<=0;next_x<=0;next_y<=0;first_x<=0;first_y<=0;
            min_x<=0;min_y<=0;max_x<=0;max_y<=0;head<=0;tail<=0;trace_count<=0;
            neighbor_index<=0;attempts<=0;direction<=0;next_back<=0;first_found<=0;push_seed<=0;abort_pending<=0;
            reply<=0;component_scope<=0;component_box<=0;component_pixels<=0;component_points<=0;
            component_clipped<=0;component_overflow<=0;component_no_contour<=0;component_address<=0;
            done_scope<=0;done_error<=0;components_completed<=0;quarantined<=0;
            mem_addr<=0;mem_wdata<=0;mem_wstrb<=0;
        end else begin
            if(cancel&&state!=IDLE&&state!=DONE&&state!=LOCKED)abort_pending<=1;
            if((cancel||abort_pending)&&state!=IDLE&&state!=DONE&&state!=LOCKED&&state!=MEM_REQ&&state!=MEM_WAIT)fail(2);
            else case(state)
                IDLE:if(start_valid&&start_ready)begin
                    component_scope<=start_scope;done_scope<=start_scope;done_error<=0;components_completed<=0;
                    eb<=edge_base;vb<=visited_base;qb<=queue_base;cb<=contour_base;
                    clear_offset<=0;scan_index<=0;scan_x<=0;scan_y<=0;abort_pending<=0;
                    if(|edge_base[5:0]|| |visited_base[5:0]|| |queue_base[5:0]|| |contour_base[5:0]||
                       edge_base<32'h04000000||visited_base<32'h04000000||queue_base<32'h04000000||contour_base<32'h04000000||
                       {32'd0,edge_base}+N>64'h08000000||{32'd0,visited_base}+VBYTES>64'h08000000||
                       {32'd0,queue_base}+64'(4*N)>64'h08000000||{32'd0,contour_base}+64'(4*CONTOUR_CAPACITY)>64'h08000000||
                       ranges_overlap(edge_base,N,visited_base,VBYTES)||ranges_overlap(edge_base,N,queue_base,4*N)||
                       ranges_overlap(edge_base,N,contour_base,4*CONTOUR_CAPACITY)||ranges_overlap(visited_base,VBYTES,queue_base,4*N)||
                       ranges_overlap(visited_base,VBYTES,contour_base,4*CONTOUR_CAPACITY)||ranges_overlap(queue_base,4*N,contour_base,4*CONTOUR_CAPACITY))fail(4);
                    else state<=CLEAR;
                end
                CLEAR:access(vb+clear_offset,0,4'b1111,CLEAR_ACK);
                CLEAR_ACK:if(clear_offset+4>=VBYTES)state<=SCAN;
                    else begin clear_offset<=clear_offset+4;state<=CLEAR;end
                SCAN:read_byte(vb+scan_index,SCAN_VISIT);
                SCAN_VISIT:if(reply_byte!=0)state<=ADVANCE;else read_byte(eb+scan_index,SCAN_EDGE);
                SCAN_EDGE:if(reply_byte==0)state<=ADVANCE;
                    else begin
                        seed_x<=scan_x;seed_y<=scan_y;nx<=scan_x;ny<=scan_y;
                        min_x<=scan_x;max_x<=scan_x;min_y<=scan_y;max_y<=scan_y;
                        head<=0;tail<=0;trace_count<=0;push_seed<=1;
                        component_overflow<=0;component_no_contour<=0;state<=PUSH_MARK;
                    end
                PUSH_MARK:if(tail>=N)fail(4);else visit(vb+neighbor_pixel,PUSH_QUEUE);
                PUSH_QUEUE:access(qb+({10'd0,tail}<<2),{10'd0,ny,nx},4'b1111,PUSH_DONE);
                PUSH_DONE:begin
                    tail<=tail+1'b1;
                    if(nx<min_x)min_x<=nx;if(nx>max_x)max_x<=nx;
                    if(ny<min_y)min_y<=ny;if(ny>max_y)max_y<=ny;
                    if(push_seed)begin push_seed<=0;state<=POP;end
                    else begin neighbor_index<=neighbor_index+1'b1;state<=NEIGHBOR;end
                end
                POP:if(head==tail)state<=TRACE_START;
                    else access(qb+({10'd0,head}<<2),0,0,POP_DONE);
                POP_DONE:begin pop_x<=reply[10:0];pop_y<=reply[21:11];head<=head+1'b1;neighbor_index<=0;state<=NEIGHBOR;end
                NEIGHBOR:if(neighbor_index==8)state<=POP;
                    else if(neighbor_x<0||neighbor_y<0||neighbor_x>=W||neighbor_y>=H)neighbor_index<=neighbor_index+1'b1;
                    else begin
                        nx<=neighbor_x[10:0];ny<=neighbor_y[10:0];
                        read_byte(vb+32'(neighbor_y)*W+32'(neighbor_x),NEIGHBOR_VISIT);
                    end
                NEIGHBOR_VISIT:if(reply_byte!=0)begin neighbor_index<=neighbor_index+1'b1;state<=NEIGHBOR;end
                    else read_byte(eb+neighbor_pixel,NEIGHBOR_EDGE);
                NEIGHBOR_EDGE:if(reply_byte!=0)state<=PUSH_MARK;
                    else begin neighbor_index<=neighbor_index+1'b1;state<=NEIGHBOR;end
                TRACE_START:begin tx<=seed_x;ty<=seed_y;first_found<=0;direction<=0;attempts<=0;state<=TRACE;end
                TRACE:if(attempts==8)begin component_no_contour<=1;publish_component();end
                    else if(neighbor_x<0||neighbor_y<0||neighbor_x>=W||neighbor_y>=H)begin direction<=direction+1'b1;attempts<=attempts+1'b1;end
                    else begin nx<=neighbor_x[10:0];ny<=neighbor_y[10:0];read_byte(eb+32'(neighbor_y)*W+32'(neighbor_x),TRACE_EDGE);end
                TRACE_EDGE:if(reply_byte==0)begin direction<=direction+1'b1;attempts<=attempts+1'b1;state<=TRACE;end
                    else if(first_found&&tx==seed_x&&ty==seed_y&&nx==first_x&&ny==first_y)publish_component();
                    else if(trace_count>=CONTOUR_CAPACITY)begin component_overflow<=1;publish_component();end
                    else begin
                        if(!first_found)begin first_found<=1;first_x<=nx;first_y<=ny;end
                        next_x<=nx;next_y<=ny;next_back<=back_direction(direction);state<=TRACE_APPEND;
                    end
                TRACE_APPEND:access(cb+({10'd0,trace_count}<<2),{10'd0,ty,tx},4'b1111,TRACE_NEXT);
                TRACE_NEXT:begin trace_count<=trace_count+1'b1;tx<=next_x;ty<=next_y;direction<=next_back+1'b1;attempts<=0;state<=TRACE;end
                COMPONENT:if(component_ready)begin components_completed<=components_completed+1'b1;state<=ADVANCE;end
                ADVANCE:if(scan_index==N-1)state<=DONE;
                    else begin
                        scan_index<=scan_index+1;
                        if(scan_x==W-1)begin scan_x<=0;scan_y<=scan_y+1'b1;end else scan_x<=scan_x+1'b1;
                        state<=SCAN;
                    end
                MEM_REQ:if(mem_req_ready)state<=MEM_WAIT;
                MEM_WAIT:if(mem_rsp_valid)begin
                    reply<=mem_rdata;
                    if(!mem_drained)begin quarantined<=1;fail(3);end
                    else if(mem_error)fail(1);
                    else if(abort_pending||cancel)fail(2);
                    else state<=resume_state;
                end
                DONE:if(done_ready)state<=quarantined?LOCKED:IDLE;
                LOCKED:begin end
                default:fail(4);
            endcase
        end
    end
endmodule
