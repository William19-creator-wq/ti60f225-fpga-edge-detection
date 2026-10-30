`timescale 1ns/1ps
module tb_canny_controls;
    logic clk=0,rst=1,minus_n=0,plus_n=0,sw3_n=0;
    always #5 clk=~clk;
    wire [2:0] mode,item;wire [10:0] threshold,canny;
    wire [1:0] filter;wire menu,enhance;
    integration_controls #(.DEBOUNCE_CYCLES(4),.LONG_CYCLES(60),.EDGE_SELECT_AVAILABLE(1),.DEFAULT_EDGE_ENHANCE(0),.CANNY_AVAILABLE(1)) dut(
        .clk,.rst,.key_minus_n(minus_n),.key_plus_n(plus_n),.key_mode_n(sw3_n),
        .key_probe_minus_n(1'b1),.key_probe_plus_n(1'b1),.key_levels_n(),
        .mode,.threshold,.canny_high(canny),.filter_mode(filter),.menu_open(menu),.menu_item(item),
        .edge_enhance(enhance),.overlay_canny(),.wide_overlay(),.freeze_request(),.noise_level(),.config_id());
    task automatic tick(input integer count);repeat(count)@(negedge clk);endtask
    task automatic short_press;sw3_n=0;tick(12);sw3_n=1;tick(12);endtask
    task automatic plus;plus_n=0;tick(12);plus_n=1;tick(12);endtask
    task automatic minus;minus_n=0;tick(12);minus_n=1;tick(12);endtask
    task automatic long_press;sw3_n=0;tick(90);sw3_n=1;tick(12);endtask
    initial begin
        tick(4);rst=0;tick(120);
        if(mode!=0||threshold!=64||canny!=96||menu)$fatal(1,"Startup-held SW3 changed configuration");
        minus_n=1;plus_n=1;sw3_n=1;tick(12);
        for(integer repeat_cycle=0;repeat_cycle<3;repeat_cycle++)begin
            for(integer index=1;index<=7;index++)begin
                short_press();if(mode!=index%7)$fatal(1,"Seven-mode sequence failed at %0d",index);
            end
        end
        repeat(3)short_press();plus();if(mode!=3||threshold!=68||canny!=96)$fatal(1,"Sobel threshold changed Canny");
        repeat(2)short_press();plus();if(mode!=5||threshold!=68||canny!=100)$fatal(1,"Canny threshold changed Sobel");
        short_press();plus();if(mode!=6||canny!=104||threshold!=68)$fatal(1,"Canny overlay threshold selection");
        for(integer i=0;i<550;i++)minus();if(canny!=2||threshold!=68)$fatal(1,"Canny lower saturation");
        for(integer i=0;i<550;i++)plus();if(canny!=2047)$fatal(1,"Canny upper saturation");
        long_press();if(!menu||mode!=6)$fatal(1,"SW3 long press also switched mode");
        plus();if(filter!=2)$fatal(1,"Original detail filter unavailable");
        short_press();plus();if(item!=1||!enhance||mode!=6)$fatal(1,"Original enhancement setting unavailable");
        long_press();if(menu||mode!=6)$fatal(1,"Menu close generated short press");
        short_press();if(mode!=0)$fatal(1,"M6 failed to wrap to M0");
        rst=1;tick(3);if(mode!=0||threshold!=64||canny!=96||filter!=1)$fatal(1,"Reset defaults changed");
        $display("CANNY_CONTROLS_PASS seven_modes original_modes separate_thresholds SW3_short_long");$finish;
    end
    initial begin #10000000;$fatal(1,"Controls timeout");end
endmodule
