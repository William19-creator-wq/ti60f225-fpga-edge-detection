// One complete frame's classified contours -> largest four valid targets.
// Frame scope is checked on EVERY item. A scope mismatch or malformed valid
// label aborts the entire list; it must never be overlaid on another frame.
// Unknowns are counted and their reason flags retained, not guessed as shapes.
// Equal-area targets retain input order. Overflow means >4 valid targets, not
// loss of contour processing. Backpressure and insertion cannot drop an item.
module shape_target_list #(
    parameter integer W=1920,H=1080
)(
    input wire clk,rst,cancel,
    input wire start_valid,output wire start_ready,input wire [95:0] start_scope,
    input wire item_valid,output wire item_ready,input wire [95:0] item_scope,
    input wire [1:0] item_class,input wire [2:0] item_reason,
    input wire [43:0] item_box,input wire [23:0] item_center2,
    input wire [47:0] item_area_twice,
    input wire finish_valid,output wire finish_ready,
    output wire result_valid,input wire result_ready,
    output reg [95:0] result_scope,output reg [1:0] result_error,
    output wire result_overflow,
    output reg [21:0] valid_count,unknown_count,
    output reg [7:0] unknown_reasons,
    output reg [3:0] target_valid,
    output reg [7:0] target_class,
    output reg [175:0] target_box,
    output reg [95:0] target_center2,
    output reg [191:0] target_area_twice,
    output wire busy
);
    localparam IDLE=0,COLLECT=1,INSERT=2,RESULT=3;
    reg [1:0] state,index;
    reg carry_valid;
    reg [1:0] carry_class;
    reg [43:0] carry_box;
    reg [23:0] carry_center;
    reg [47:0] carry_area;
    wire [10:0] x0=item_box[10:0],y0=item_box[21:11],x1=item_box[32:22],y1=item_box[43:33];
    wire [23:0] expected_center={({1'b0,y0}+{1'b0,y1}),({1'b0,x0}+{1'b0,x1})};
    assign start_ready=!rst&&!cancel&&state==IDLE;
    assign item_ready=!rst&&!cancel&&state==COLLECT;
    // An item wins over finish when both are offered; finish must be held.
    assign finish_ready=!rst&&!cancel&&state==COLLECT&&!item_valid;
    assign result_valid=!rst&&state==RESULT;
    assign result_overflow=valid_count>4;
    assign busy=state!=IDLE;
    task clear_targets;
        begin
            target_valid<=0;target_class<=0;target_box<=0;target_center2<=0;target_area_twice<=0;
            valid_count<=0;unknown_count<=0;unknown_reasons<=0;carry_valid<=0;
        end
    endtask
    task fail(input [1:0] code);
        begin clear_targets();result_error<=code;state<=RESULT;end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;index<=0;result_scope<=0;result_error<=0;
            carry_class<=0;carry_box<=0;carry_center<=0;carry_area<=0;clear_targets();
        end else if(cancel&&state!=IDLE&&state!=RESULT)fail(3);
        else case(state)
            IDLE:if(start_valid&&start_ready)begin
                clear_targets();result_scope<=start_scope;result_error<=0;state<=COLLECT;
            end
            COLLECT:begin
                if(item_valid&&item_ready)begin
                    if(item_scope!=result_scope)fail(2);
                    else if({1'b0,valid_count}+{1'b0,unknown_count}>=W*H)fail(1);
                    else if(item_class==0)begin
                        unknown_count<=unknown_count+1'b1;unknown_reasons[item_reason]<=1'b1;
                    end else if(item_class==3||item_reason!=0||x0>=x1||y0>=y1||x1>=W||y1>=H||
                                item_area_twice==0||item_center2!=expected_center)fail(1);
                    else begin
                        valid_count<=valid_count+1'b1;
                        carry_valid<=1;carry_class<=item_class;carry_box<=item_box;
                        carry_center<=item_center2;carry_area<=item_area_twice;
                        index<=0;state<=INSERT;
                    end
                end else if(finish_valid&&finish_ready)state<=RESULT;
            end
            INSERT:begin
                // Rotate through four fixed slots. Four clocks restore output
                // order; only RESULT publishes the list. This avoids variable
                // 48/44/24-bit read muxes and write-lane decoders.
                if(carry_valid&&(!target_valid[0]||carry_area>target_area_twice[47:0]))begin
                    target_valid<={1'b1,target_valid[3:1]};carry_valid<=target_valid[0];
                    target_class<={carry_class,target_class[7:2]};carry_class<=target_class[1:0];
                    target_box<={carry_box,target_box[175:44]};carry_box<=target_box[43:0];
                    target_center2<={carry_center,target_center2[95:24]};carry_center<=target_center2[23:0];
                    target_area_twice<={carry_area,target_area_twice[191:48]};carry_area<=target_area_twice[47:0];
                end else begin
                    target_valid<={target_valid[0],target_valid[3:1]};
                    target_class<={target_class[1:0],target_class[7:2]};
                    target_box<={target_box[43:0],target_box[175:44]};
                    target_center2<={target_center2[23:0],target_center2[95:24]};
                    target_area_twice<={target_area_twice[47:0],target_area_twice[191:48]};
                end
                if(index==3)state<=COLLECT;
                else index<=index+1'b1;
            end
            RESULT:if(result_ready)state<=IDLE;
            default:fail(1);
        endcase
    end
endmodule
