`timescale 1ns/1ps
module tb_video_compare_presenter;
    logic clk=0,rst=1;always #5 clk=~clk;
    wire de,hs,vs,frame_start;wire [10:0] x_even,y;
    video_timing_1080p_pair timing(.clk(clk),.rst(rst),.de(de),.hs(hs),.vs(vs),.frame_start(frame_start),.x_even(x_even),.y(y));
    logic [1:0] cfg_mode=0;logic [47:0] rgb_pair;logic [15:0] gray_pair;logic [1:0] edge_pair;
    wire [10:0] source_x0,source_x1,source_y;wire [47:0] out_rgb_pair;wire out_de,out_hs,out_vs,out_frame_start;
    video_compare_presenter presenter(.clk(clk),.rst(rst),.in_de(de),.in_hs(hs),.in_vs(vs),.in_frame_start(frame_start),
        .in_x_even(x_even),.in_y(y),.cfg_mode(cfg_mode),.rgb_pair(rgb_pair),.gray_pair(gray_pair),.edge_pair(edge_pair),
        .source_x0(source_x0),.source_x1(source_x1),.source_y(source_y),.out_rgb_pair(out_rgb_pair),.out_de(out_de),.out_hs(out_hs),.out_vs(out_vs),.out_frame_start(out_frame_start));
    wire probe_led0,probe_led1;
    video_partial_probe_top probe(.clk_25m(clk),.key1_n(!rst),.led0(probe_led0),.led1(probe_led1));
    byte unsigned captured_gray[0:2073599];
    logic finished=0;string run_dir;integer capture_file,golden_file,actual_file,result_file,rc,probe_good_frames=0;
    logic [47:0] expected_file_word,expected_pair;
    function automatic [23:0] rgb(input integer x,v);rgb=((x%256)<<16)|((v%256)<<8)|((x^v)%256);endfunction
    function automatic logic edge_at(input integer x,v);
        integer center,right,down;
        begin
            center=captured_gray[v*1920+x];right=captured_gray[v*1920+(x==1919?1919:x+1)];down=captured_gray[(v==1079?1079:v+1)*1920+x];
            edge_at=(center>right?center-right:right-center)>=64 || (center>down?center-down:down-center)>=64;
        end
    endfunction
    always_comb begin
        rgb_pair={rgb(source_x1,source_y),rgb(source_x0,source_y)};
        gray_pair={captured_gray[source_y*1920+source_x1],captured_gray[source_y*1920+source_x0]};
        edge_pair={edge_at(source_x1,source_y),edge_at(source_x0,source_y)};
    end
    always @(posedge clk)if(!probe.core_rst)begin
        if(probe.error_valid || (probe.frame_end_valid && !probe.frame_end_good))$fatal(1,"video probe capture bad frame");
        if(probe.frame_end_valid && probe.frame_end_good)probe_good_frames++;
    end
    initial begin
        if(!$value$plusargs("RUN_DIR=%s",run_dir))$fatal(1,"RUN_DIR missing");
        capture_file=$fopen({run_dir,"/capture-gray.bin"},"rb");if(!capture_file)$fatal(1,"actual capture fixture missing");
        rc=$fread(captured_gray,capture_file);if(rc!=2073600)$fatal(1,"actual capture fixture size");$fclose(capture_file);
        repeat(2)@(posedge clk);@(negedge clk);rst=0;
        for(integer mode=0;mode<4;mode++)begin: frames
            integer de_count,hs_count,vs_count;
            de_count=0;hs_count=0;vs_count=0;cfg_mode=mode;
            golden_file=$fopen($sformatf("%s/vectors/mode%0d.rgb",run_dir,mode),"rb");actual_file=$fopen($sformatf("%s/actual-mode%0d.rgb",run_dir,mode),"wb");
            if(!golden_file || !actual_file)$fatal(1,"render file open");
            for(integer i=0;i<1237500;i++)begin
                integer h,v,display_x,s0,s1;logic active,want_hs,want_vs;
                h=i%1100;v=i/1100;active=h<960 && v<1080;want_hs=h>=1004 && h<1026;want_vs=v>=1084 && v<1089;display_x=2*h;
                @(posedge clk);
                if(de!==active || hs!==want_hs || vs!==want_vs || frame_start!==(i==0) ||
                    x_even!=(active?display_x:0) || y!=(active?v:0))$fatal(1,"timing mode%0d tick%0d",mode,i);
                if(active)begin
                    s0=mode==2?(display_x%960)*2:display_x;s1=s0+(mode==2?2:1);
                    if(source_x0!=s0 || source_x1!=s1 || source_y!=v)$fatal(1,"source request mapping");
                    rc=$fread(expected_file_word,golden_file);if(rc!=6)$fatal(1,"golden RGB short");
                    expected_pair={expected_file_word[23:0],expected_file_word[47:24]};de_count++;
                end else expected_pair=0;
                if(want_hs)hs_count++;if(want_vs)vs_count++;
                #1;
                if(out_de!==active || out_hs!==want_hs || out_vs!==want_vs || out_frame_start!==(i==0) || out_rgb_pair!==expected_pair)
                    $fatal(1,"presenter mode%0d tick%0d actual=%h expected=%h",mode,i,out_rgb_pair,expected_pair);
                if(active)$fwrite(actual_file,"%c%c%c%c%c%c",out_rgb_pair[23:16],out_rgb_pair[15:8],out_rgb_pair[7:0],out_rgb_pair[47:40],out_rgb_pair[39:32],out_rgb_pair[31:24]);
                @(negedge clk);cfg_mode=(mode+1)%4; // 故意帧中改配置，当前帧不能受影响。
            end
            if(de_count!=1036800 || hs_count!=24750 || vs_count!=5500)$fatal(1,"complete timing counts");
            if($fread(expected_file_word,golden_file)!=0)$fatal(1,"extra golden RGB");
            $fclose(golden_file);$fclose(actual_file);$display("PASS complete1080p mode%0d",mode);
        end
        if(probe_good_frames!=4)$fatal(1,"video probe incomplete capture frames%0d",probe_good_frames);
        result_file=$fopen({run_dir,"/presenter-result.json"},"w");
        $fwrite(result_file,"{\"status\":\"PASS\",\"finished\":true,\"modes\":4,\"pixels_checked\":8294400,\"timing_ticks\":4950000,\"probe_good_frames\":%0d}\n",probe_good_frames);
        $fclose(result_file);finished=1;$finish;
    end
endmodule
