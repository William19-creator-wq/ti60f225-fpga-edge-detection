`timescale 1ns/1ps
// RT1..5：每正沿采样公开输入，下一正沿逐位检查；独立二进制保留整个HD时隙。
module tb_display_renderer #(
    parameter integer TEST_RENDER_HD=0,TEST_RENDER_MIN=0
);
    localparam integer W=TEST_RENDER_HD ? 1920 : TEST_RENDER_MIN ? 4 : 20;
    localparam integer H=TEST_RENDER_HD ? 1080 : TEST_RENDER_MIN ? 2 : 8;
    localparam integer FRAME_SLOTS=1100*1125;
    logic clk=0,rst=1,timing_rst=1,hd_drive=0;
    always #6.734 clk=~clk;
    logic [53:0] direct_pair=0;logic [111:0] direct_render=0;
    logic [3:0] direct_controls=0;logic [10:0] direct_x=0,direct_y=0;
    logic direct_pixels=1,direct_identity=1,trace_drive=0;
    integer hd_frame=0;
    wire timing_de,timing_hs,timing_vs,timing_frame_start;
    wire [10:0] timing_x,timing_y;
    video_timing_1080p_pair timing(.clk,.rst(timing_rst),.de(timing_de),.hs(timing_hs),.vs(timing_vs),.frame_start(timing_frame_start),.x_even(timing_x),.y(timing_y));
    logic [53:0] in_pair;logic [111:0] in_render;
    logic [3:0] in_controls;logic [10:0] in_x,in_y;logic in_pixels,in_identity;
    wire [47:0] out_rgb_pair;wire out_de,out_hs,out_vs,out_frame_start;
    wire [10:0] out_x_even,out_y;wire [1:0] out_error;
    display_renderer #(.IMAGE_WIDTH(W),.IMAGE_HEIGHT(H)) dut(
        .clk,.rst,.in_de(in_controls[3]),.in_hs(in_controls[2]),.in_vs(in_controls[1]),.in_frame_start(in_controls[0]),
        .in_x_even(in_x),.in_y,.in_pair,.in_render,.in_pixels_valid(in_pixels),.in_identity_good(in_identity),
        .out_rgb_pair,.out_de,.out_hs,.out_vs,.out_frame_start,.out_x_even,.out_y,.out_error);
    function automatic logic [23:0] image_rgb(input integer x,y,f);
        return {8'((37*x+11*y+3*f)%256),8'((13*x+47*y+7*f)%256),8'((53*x+19*y+17*f)%256)};
    endfunction
    function automatic logic [111:0] configuration(input integer mode,flags);
        return {3'(mode),11'(H/2),24'hf12345,24'h13ab57,24'h2468de,24'hf0e1d2,2'(flags)};
    endfunction
    function automatic logic [53:0] image_pair(input integer mode,x,y);
        integer sy,mask;logic [47:0] rgb;logic [1:0] edge_bits;logic [3:0] ann;
        begin
            sy=y;mask=0;
            case(mode)
                0:begin sy=2*(y%(H/2));mask=y<H/2 ? 1 : 2;end
                1,2:mask=1;3:mask=2;4:mask=3;5:mask=7;
            endcase
            rgb=mask&1 ? {image_rgb(x+1,sy,mode+1),image_rgb(x,sy,mode+1)} : 0;
            edge_bits=mask&2 ? {1'(((x+1+sy+mode+1)%3)==0),1'(((x+sy+mode+1)%3)==0)} : 0;
            ann=mask&4 ? {2'((7*(x+1)+3*sy+mode+1)%4),2'((7*x+3*sy+mode+1)%4)} : 0;
            return {ann,edge_bits,rgb};
        end
    endfunction
    always_comb begin
        in_controls=direct_controls;in_x=direct_x;in_y=direct_y;
        in_pair=direct_pair;in_render=direct_render;in_pixels=direct_pixels;in_identity=direct_identity;
        if(hd_drive)begin
            in_controls={timing_de,timing_hs,timing_vs,timing_frame_start};in_x=timing_x;in_y=timing_y;
            in_pair=timing_de ? image_pair(hd_frame,timing_x,timing_y) : 54'h15a8cafe123456;
            in_render=configuration(hd_frame,hd_frame==0 ? 0 : 3);in_pixels=1;in_identity=1;
        end
    end
    typedef struct packed {
        logic valid,trace;
        logic [31:0] input_cycle;
        logic [2:0] frame_number;logic is_hd;
        logic [53:0] pair_bits;logic [111:0] render_bits;
        logic [3:0] controls;logic [10:0] x,y;logic pixels,identity;
        logic [47:0] rgb;logic [1:0] error;
    } expectation_t;
    expectation_t pending,current;
    integer cycle=0,trace_count=0,accepted=0,delivered=0,reset_aborted=0,reset_count=0;
    integer tracefd,metricsfd,framefd[0:5],frame_slots[0:5],frame_pixels[0:5];
    logic finished=0;logic previous_reset=0;
    // 黄金计算使用整数乘法；不调用DUT的移位函数/分支。
    function automatic logic [23:0] golden_color(input expectation_t e,input integer lane);
        integer rgb,r,g,b,gray,ann,edge_bit,mode,flags;logic [23:0] color;
        begin
            rgb=int'(24'(e.pair_bits>>(lane*24)));r=(rgb>>16)&255;g=(rgb>>8)&255;b=rgb&255;
            gray=(77*r+150*g+29*b+128)/256;ann=int'(2'(e.pair_bits>>(50+2*lane)));edge_bit=int'(e.pair_bits[48+lane]);
            mode=int'(e.render_bits[111:109]);flags=int'(e.render_bits[1:0]);color=24'(rgb);
            if(mode==0)color=e.y<H/2 ? {3{8'(gray)}} : edge_bit ? 24'hffffff : 0;
            else if(mode==2)color={3{8'(gray)}};
            else if(mode==3)color=edge_bit ? 24'hffffff : 0;
            else if(mode==4 || mode==5)begin
                if((flags&2) && edge_bit)color=e.render_bits[97:74];
                if(mode==5 && (flags&1) && ann!=0)case(ann)
                    1:color=e.render_bits[73:50];2:color=e.render_bits[49:26];3:color=e.render_bits[25:2];
                endcase
            end
            return color;
        end
    endfunction
    always @(posedge clk)begin
        cycle++;
        current='0;current.valid=1;current.trace=trace_drive;current.input_cycle=32'(cycle);
        current.frame_number=3'(hd_frame);current.is_hd=hd_drive;
        current.pair_bits=in_pair;current.render_bits=in_render;current.controls=in_controls;current.x=in_x;current.y=in_y;
        current.pixels=in_pixels;current.identity=in_identity;
        if(in_controls[3])begin
            if(in_render[111:109]>=6 || in_render[108:98]!=H/2 || in_x%2 || in_x>=W || in_y>=H)current.error=2;
            else if(!in_identity)current.error=3;else if(!in_pixels)current.error=1;
            if(current.error==0)current.rgb={golden_color(current,1),golden_color(current,0)};
        end
        #1;
        if(rst)begin
            if(pending.valid)reset_aborted++;
            if(!previous_reset)reset_count++;
            pending='0;
            if({out_rgb_pair,out_de,out_hs,out_vs,out_frame_start,out_x_even,out_y,out_error}!==0)$fatal(1,"Renderer reset output");
        end else begin
            if(pending.valid)begin
                if({out_rgb_pair,out_de,out_hs,out_vs,out_frame_start,out_x_even,out_y,out_error}!==
                   {pending.rgb,pending.controls,pending.x,pending.y,pending.error})
                    $fatal(1,"Renderer mismatch cycle %0d old input %0d mode %0d out=%h expected=%h error=%0d/%0d",cycle,pending.input_cycle,pending.render_bits[111:109],out_rgb_pair,pending.rgb,out_error,pending.error);
                if(cycle!=pending.input_cycle+1)$fatal(1,"Renderer latency");
                delivered++;
                if(pending.trace)begin
                    $fdisplay(tracefd,"%0d,%0d,%h,%h,%0d,%0d,%0d,%0d,%0d,%h,%0d,%0d,%0d,%0d",pending.input_cycle,cycle,pending.pair_bits,pending.render_bits,pending.controls,pending.x,pending.y,pending.pixels,pending.identity,out_rgb_pair,{out_de,out_hs,out_vs,out_frame_start},out_x_even,out_y,out_error);
                    trace_count++;
                end
                if(pending.is_hd)begin
                    $fwrite(framefd[pending.frame_number],"%c%c%c%c%c%c%c%c%c%c%c%c",out_rgb_pair[7:0],out_rgb_pair[15:8],out_rgb_pair[23:16],out_rgb_pair[31:24],out_rgb_pair[39:32],out_rgb_pair[47:40],{4'd0,out_de,out_hs,out_vs,out_frame_start},{6'd0,out_error},out_x_even[7:0],{5'd0,out_x_even[10:8]},out_y[7:0],{5'd0,out_y[10:8]});
                    frame_slots[pending.frame_number]++;
                    if(out_de)frame_pixels[pending.frame_number]+=2;
                end
            end else if({out_rgb_pair,out_de,out_hs,out_vs,out_frame_start,out_x_even,out_y,out_error}!==0)$fatal(1,"Nonempty initial stage");
            pending=current;accepted++;
        end
        previous_reset=rst;
    end
    task automatic stimulate(input integer mode,flags,metadata,half,invalid,input logic [47:0] rgb);
        begin
            @(negedge clk);
            trace_drive=1;direct_controls=4'(8+(cycle%8));direct_render=configuration(mode,flags);
            direct_x=11'(2*((cycle/3)%(W/2)));direct_y=half ? 11'(H/2) : 11'(H/2-1);
            direct_pair={6'(metadata),rgb};direct_pixels=1;direct_identity=1;
            case(invalid)
                1:direct_pixels=0;
                2:begin direct_identity=0;direct_pixels=0;end
                3:begin direct_render[98]=~direct_render[98];direct_identity=0;direct_pixels=0;end
                4:direct_x=1;
                5:direct_x=11'(W);
                6:direct_y=11'(H);
                7:begin direct_controls[3]=0;direct_render='1;direct_x='1;direct_y='1;direct_identity=0;direct_pixels=0;end
            endcase
        end
    endtask
    initial begin
        if($test$plusargs("EXPECT_FATAL"))begin #1;$fatal(1,"fatal exit probe");end
        pending='0;
        tracefd=$fopen("renderer-trace.csv","w");if(!tracefd)$fatal(1,"Trace open");
        $fdisplay(tracefd,"in_cycle,out_cycle,pair,render,in_ctrl,in_x,in_y,pixels,identity,out_rgb,out_ctrl,out_x,out_y,error");
        for(integer f=0;f<6;f++)begin frame_slots[f]=0;frame_pixels[f]=0;framefd[f]=0;end
        repeat(4)@(negedge clk);rst=0;
        for(integer mode=0;mode<8;mode++)
            for(integer flags=0;flags<4;flags++)
                for(integer metadata=0;metadata<64;metadata++)
                    for(integer half=0;half<2;half++)stimulate(mode,flags,metadata,half,0,48'hfd82150371ea);
        for(integer invalid=1;invalid<=7;invalid++)stimulate(5,3,63,invalid%2,invalid,48'hffffff010203);
        // 所有R/G字节组合；两个lane分别使用确定性B与互补RGB。
        for(integer n=0;n<65536;n++)stimulate(2,3,n%64,n%2,0,{24'(n^24'hffffff),8'(n>>8),8'(n),8'(((n>>8)^(n&255))*29+17)});
        for(integer n=0;n<256;n++)stimulate(2,0,0,n%2,0,{6{8'(n)}});
        // 正沿有新像素接受，随后共同同步复位作废旧S0，禁止作为有效交付。
        @(negedge clk);rst=1;repeat(3)@(negedge clk);rst=0;
        for(integer n=0;n<16;n++)stimulate(n%6,n%4,n%64,n%2,0,48'(64'h91f03ac73a*n));
        @(negedge clk);trace_drive=0;direct_controls=0;
        if(TEST_RENDER_HD)begin
            for(integer f=0;f<6;f++)begin framefd[f]=$fopen($sformatf("frame-mode%0d.bin",f),"wb");if(!framefd[f])$fatal(1,"Frame open");end
            for(integer slot=0;slot<6*FRAME_SLOTS;slot++)begin
                @(negedge clk);hd_drive=1;timing_rst=0;hd_frame=slot/FRAME_SLOTS;
            end
            @(negedge clk);hd_drive=0;timing_rst=1;
            repeat(3)@(negedge clk);
            for(integer f=0;f<6;f++)begin
                if(frame_slots[f]!=FRAME_SLOTS || frame_pixels[f]!=1920*1080)$fatal(1,"HD frame slots/pixels f=%0d slots=%0d pixels=%0d",f,frame_slots[f],frame_pixels[f]);
                $fclose(framefd[f]);
            end
        end
        repeat(3)@(negedge clk);
        metricsfd=$fopen("protocol-metrics.json","w");
        $fdisplay(metricsfd,"{\"width\":%0d,\"height\":%0d,\"trace_cases\":%0d,\"accepted\":%0d,\"delivered\":%0d,\"reset_aborted\":%0d,\"pending_at_finish\":1,\"resets\":%0d,\"hd_frames\":%0d,\"hd_slots_per_frame\":1237500,\"hd_pixels_per_frame\":2073600,\"finished\":true}",W,H,trace_count,accepted,delivered,reset_aborted,reset_count,TEST_RENDER_HD ? 6 : 0);
        $fclose(metricsfd);$fclose(tracefd);finished=1;$display("RENDERER PASS trace=%0d HD=%0d",trace_count,TEST_RENDER_HD);$finish;
    end
    initial begin #200000000;$fatal(1,"Renderer watchdog");end
endmodule
