// 74.25 MHz domain. All outputs are pending configuration, adopted at frame start.
// KEY3 short action is emitted on release; a long press never also emits short.
module four_page_controls #(
    parameter integer DEBOUNCE_CYCLES=1485000,
    parameter integer LONG_CYCLES=59400000,
    parameter integer FRAME_WORKER_AVAILABLE=0,CANNY_AVAILABLE=0,
    parameter integer EDGE_SELECT_AVAILABLE=0, DEFAULT_EDGE_ENHANCE=1,
    // Only expose settings whose data paths are connected in this candidate.
    // Bits: filter, edge selector, edge source, linewidth, freeze, noise, comparison, edge display.
    parameter [7:0] MENU_MASK=8'hff
)(
    input wire clk,rst,key_minus_n,key_plus_n,key_mode_n,
    input wire key_probe_minus_n,key_probe_plus_n,
    output wire [4:0] key_levels_n,
    output wire [2:0] mode,
    output reg [10:0] threshold,canny_high,
    output reg [1:0] filter_mode,
    output reg menu_open,
    output reg [2:0] menu_item,
    output reg edge_enhance,overlay_canny,wide_overlay,freeze_request,
    output reg [1:0] noise_level,compare_mode,
    output reg [31:0] config_id
);
    // Page is the user operation, mode is the existing renderer/worker contract.
    // 0 original, 1 comparison, 2 edges, 3 recognition. Changing an edge
    // setting changes only pending configuration; video adopts it at frame start.
    reg [1:0] page;
    reg edge_overlay;
    assign mode=page==0?3'd0:page==1?3'd7:page==3?3'd6:
        edge_overlay?3'd4:overlay_canny?3'd5:3'd3;
    wire minus_press,plus_press,minus_down,plus_down,mode_down;
    key_press_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) minus_key(
        .clk(clk),.rst(rst),.raw_key_n(key_minus_n),.press(minus_press),.stable_pressed(minus_down),.synchronized_n(key_levels_n[4]));
    key_press_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) plus_key(
        .clk(clk),.rst(rst),.raw_key_n(key_plus_n),.press(plus_press),.stable_pressed(plus_down),.synchronized_n(key_levels_n[3]));
    key_press_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) mode_key(
        .clk(clk),.rst(rst),.raw_key_n(key_mode_n),.press(),.stable_pressed(mode_down),.synchronized_n(key_levels_n[2]));
    // Conflicting vendor maps: P14/N14 control; P13/N13 read-only probes.
    // Probe levels never trigger actions or participate in simultaneous-key cancellation.
    key_press_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) probe_minus_key(
        .clk(clk),.rst(rst),.raw_key_n(key_probe_minus_n),.press(),.stable_pressed(),.synchronized_n(key_levels_n[1]));
    key_press_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) probe_plus_key(
        .clk(clk),.rst(rst),.raw_key_n(key_probe_plus_n),.press(),.stable_pressed(),.synchronized_n(key_levels_n[0]));
    localparam integer CW=$clog2(LONG_CYCLES+1);
    reg [CW-1:0] hold_count;
    reg mode_previous,long_consumed;
    wire short_release=mode_previous&&!mode_down&&!long_consumed;
    wire long_event=mode_down&&!long_consumed&&hold_count==CW'(LONG_CYCLES-1);
    wire plus_event=plus_press&&!minus_press&&!minus_down;
    wire minus_event=minus_press&&!plus_press&&!plus_down;
    wire adjust=plus_event||minus_event;
    function automatic [2:0] next_menu(input [2:0] current);
        integer offset,index;reg found;
        begin
            next_menu=0;found=0;
            for(offset=1;offset<=8;offset=offset+1)begin
                index=int'(current)+offset;
                if(index>=8)index=index-8;
                if(!found&&MENU_MASK[index])begin next_menu=3'(index);found=1;end
            end
        end
    endfunction
    wire [10:0] selected_threshold=(mode==5||mode==6||(mode==4&&overlay_canny))?canny_high:threshold;
    wire [10:0] minimum_threshold=(mode==5||mode==6||(mode==4&&overlay_canny))?11'd2:11'd0;
    wire [10:0] next_threshold=plus_event?
        (selected_threshold>11'd2043 ? 11'd2047 : selected_threshold+11'd4):
        (selected_threshold<minimum_threshold+11'd4 ? minimum_threshold : selected_threshold-11'd4);
    always @(posedge clk)begin
        if(rst)begin
            page<=0;edge_overlay<=0;threshold<=64;canny_high<=96;filter_mode<=1;
            menu_open<=0;menu_item<=0;edge_enhance<=DEFAULT_EDGE_ENHANCE!=0;overlay_canny<=0;
            wide_overlay<=1;freeze_request<=0;noise_level<=0;compare_mode<=0;config_id<=0;
            hold_count<=0;mode_previous<=0;long_consumed<=0;
        end else begin
            mode_previous<=mode_down;
            if(!mode_down)begin hold_count<=0;long_consumed<=0;end
            else if(!long_consumed)begin
                if(long_event)long_consumed<=1;
                else hold_count<=hold_count+1'b1;
            end
            if(long_event)begin menu_open<=!menu_open;menu_item<=0;end
            else if(short_release)begin
                if(menu_open)menu_item<=next_menu(menu_item);
                else begin
                    page<=page+2'd1;
                    config_id<=config_id+32'd1;
                end
            end else if(adjust)begin
                if(!menu_open)begin
                    if(mode==5||mode==6||(mode==4&&overlay_canny))canny_high<=next_threshold;else threshold<=next_threshold;
                end else case(menu_item)
                    0:filter_mode<=plus_event?(filter_mode==2?2'd0:filter_mode+2'd1):(filter_mode==0?2'd2:filter_mode-2'd1);
                    1:edge_enhance<=!edge_enhance;
                    2:overlay_canny<=!overlay_canny;
                    3:wide_overlay<=!wide_overlay;
                    4:freeze_request<=!freeze_request;
                    5:noise_level<=plus_event?noise_level+2'd1:noise_level-2'd1;
                    6:compare_mode<=plus_event?(compare_mode==2?2'd0:compare_mode+2'd1):(compare_mode==0?2'd2:compare_mode-2'd1);
                    7:edge_overlay<=!edge_overlay;
                    default:begin end
                endcase
                config_id<=config_id+32'd1;
            end
        end
    end
    // synthesis translate_off
    initial if(!FRAME_WORKER_AVAILABLE||!CANNY_AVAILABLE)$fatal(1,"Four-page UI requires the complete integrated worker");
    initial if(LONG_CYCLES<2)$fatal(1,"Long press interval too short");
    // synthesis translate_on
endmodule
