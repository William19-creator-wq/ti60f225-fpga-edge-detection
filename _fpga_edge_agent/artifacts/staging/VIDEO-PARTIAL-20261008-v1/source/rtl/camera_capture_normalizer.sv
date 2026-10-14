// VP01：已解包RAW10接口；无ready，坏帧必须给终态，预览不是去马赛克彩色。
module camera_capture_normalizer #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter logic [31:0] FIRST_FRAME_ID=32'd0
)(
    input logic clk,rst,in_valid,input logic [19:0] raw_pair,
    input logic in_sof,in_eol,in_bad,
    output logic pixel_valid,output logic [19:0] raw_pair_out,output logic [15:0] gray_pair,
    output logic [10:0] x_even,y,output logic [31:0] frame_id,output logic sof,eol,eof,
    output logic frame_end_valid,output logic [31:0] frame_end_id,
    output logic frame_end_good,output logic [2:0] frame_end_reason,
    output logic error_valid,output logic [2:0] error_reason
);
    typedef enum logic [1:0] {IDLE,CAPTURE,DISCARD,HALT} capture_state_t;
    capture_state_t state;
    localparam logic [10:0] LAST_X=WIDTH-2,LAST_Y=HEIGHT-1;
    logic [10:0] next_x,next_y;
    logic [31:0] active_id,next_id;
    logic sequence_exhausted;
    logic [2:0] start_error,active_error;
    always_comb begin
        start_error=in_bad?3'd4:(sequence_exhausted?3'd5:(in_eol?3'd3:3'd0));
        active_error=in_bad?3'd4:(in_sof?3'd2:((in_eol!=(next_x==LAST_X))?3'd3:3'd0));
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            state<=IDLE;next_x<=0;next_y<=0;active_id<=0;next_id<=FIRST_FRAME_ID;sequence_exhausted<=0;
            pixel_valid<=0;raw_pair_out<=0;gray_pair<=0;x_even<=0;y<=0;frame_id<=0;sof<=0;eol<=0;eof<=0;
            frame_end_valid<=0;frame_end_id<=0;frame_end_good<=0;frame_end_reason<=0;error_valid<=0;error_reason<=0;
        end else begin
            pixel_valid<=0;frame_end_valid<=0;error_valid<=0;
            if(in_valid) case(state)
                IDLE,DISCARD:begin
                    if(in_sof) begin
                        if(start_error!=0) begin
                            error_valid<=1;error_reason<=start_error;
                            state<=start_error==5?HALT:DISCARD;
                        end else begin
                            active_id<=next_id;if(&next_id)sequence_exhausted<=1;else next_id<=next_id+32'd1;
                            pixel_valid<=1;raw_pair_out<=raw_pair;gray_pair<={raw_pair[19:12],raw_pair[9:2]};
                            x_even<=0;y<=0;frame_id<=next_id;sof<=1;eol<=0;eof<=0;
                            next_x<=2;next_y<=0;state<=CAPTURE;
                        end
                    end else if(state==IDLE) begin error_valid<=1;error_reason<=1;state<=DISCARD;end
                end
                CAPTURE:begin
                    if(active_error!=0) begin
                        error_valid<=1;error_reason<=active_error;
                        frame_end_valid<=1;frame_end_id<=active_id;frame_end_good<=0;frame_end_reason<=active_error;state<=DISCARD;
                    end else begin
                        pixel_valid<=1;raw_pair_out<=raw_pair;gray_pair<={raw_pair[19:12],raw_pair[9:2]};
                        x_even<=next_x;y<=next_y;frame_id<=active_id;sof<=0;eol<=in_eol;eof<=next_x==LAST_X && next_y==LAST_Y;
                        if(next_x==LAST_X) begin
                            next_x<=0;
                            if(next_y==LAST_Y) begin
                                frame_end_valid<=1;frame_end_id<=active_id;frame_end_good<=1;frame_end_reason<=0;state<=IDLE;
                            end else next_y<=next_y+11'd1;
                        end else next_x<=next_x+11'd2;
                    end
                end
                HALT:if(in_sof)begin error_valid<=1;error_reason<=5;end
            endcase
        end
    end
endmodule
