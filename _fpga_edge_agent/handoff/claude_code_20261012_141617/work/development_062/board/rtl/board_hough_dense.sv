// 全512 theta、每theta277个rho；按LANES路RAM/DSP复用，板级选择4路。
// 完整POINT每批扫描一次；原生DDR正文保持至该物理块全部点投票/尾padding检查结束。
// DENSE32按theta512/rho512的固定布局写满1MiB，277..511严格为0。
// 投票完成后复用前三个直方图RAM缓存NMS相邻三行；LINE64及META回复结清才done。
module board_hough_dense #(
    parameter integer WIDTH=1920,HEIGHT=1080,LANES=16,
    parameter [32:0] ADDRESS_BYTES=33'h10000000,
    parameter string COEFFICIENT_FILE="board/recognition_numeric/hough_coeff_q15.mem",
    parameter bit BORROW_SCOPE=1'b0
)(
    input wire clk,rst,start,input wire [95:0] scope,input wire [20:0] points,
    input wire [31:0] point_base,dense_base,metadata_base,line_base,
    input wire [20:0] line_min_support,
    output wire start_ready,done,output reg fault,
    output reg [7:0] point_passes,output reg [27:0] point_visits,output reg [29:0] vote_updates,
    output reg [10:0] line_count,
    output wire req_valid,input wire req_ready,output wire req_write,output wire [31:0] req_addr,
    input wire rsp_valid,output wire rsp_ready,input wire [511:0] rsp_data,input wire rsp_error,rsp_drained,
    output wire pack_valid,output wire [2:0] pack_index,output wire [63:0] pack_data
);
    localparam IDLE=0,CLEAR=1,COEFF_READ=2,COEFF_CAPTURE=3,POINT_REQ=4,POINT_WAIT=5,
        POINT_CAPTURE=6,MUL_CAPTURE=7,PROJECT=8,VOTE_READ=9,VOTE_WRITE=10,PADDING=11,POINT_CLOSE=12,
        EXPORT_SETUP=13,EXPORT_READ=14,EXPORT_CAPTURE=15,EXPORT_PACK=16,WRITE_REQ=17,WRITE_RSP=18,
        META_PACK=19,COMPLETE=20,FAILED=21,
        NMS_LOAD_SETUP=22,NMS_LOAD_REQ=23,NMS_LOAD_WAIT=24,NMS_LOAD_CAPTURE=25,NMS_LOAD_CLOSE=26,
        NMS_CENTER_READ=27,NMS_CENTER_CAPTURE=28,NMS_NEIGHBOR_READ=29,NMS_NEIGHBOR_CAPTURE=30,
        NMS_PEAK_PACK=31,NMS_LINE_REQ=32,NMS_LINE_RSP=33,NMS_PAD=34;
    reg [5:0] state;
    localparam integer LANE_BITS=$clog2(LANES),BATCH_BITS=9-LANE_BITS,BATCHES=512/LANES;
    reg [BATCH_BITS-1:0] batch;
    wire [95:0] locked_scope;
    generate if(BORROW_SCOPE)begin:borrowed_scope
        // 板端scope来自父RPC锁定的cj，完整META写回复结清前不允许父级换job。
        assign locked_scope=scope;
    end else begin:copied_scope
        reg [95:0] snapshot;
        assign locked_scope=snapshot;
        // 原Hough scope不复位，只有合法start接受沿捕获；默认模式保持此行为。
        always @(posedge clk)if(!rst&&start&&start_ready)snapshot<=scope;
    end endgenerate
    reg [20:0] point_limit,ordinal;
    reg [31:0] locked_point_base,locked_dense_base,locked_meta_base,address,point_address;
    reg [8:0] clear_row,export_row;
    reg [LANE_BITS-1:0] coefficient_lane,export_lane;
    reg [2:0] point_lane,fill;
    reg export_half,is_meta;
    reg [31:0] first_cell;
    reg [63:0] packed_word;
    reg [21:0] previous_xy;
    reg signed [11:0] centered_x,centered_y;
    reg [8:0] rho[0:LANES-1];
    reg [33:0] coefficient_rom[0:511],coefficient_q;
    reg [31:0] locked_line_base;
    reg [20:0] locked_line_min,center_votes;
    reg [8:0] nms_theta,nms_rho;
    reg [1:0] cache_plane;
    reg [4:0] cache_block;
    reg [3:0] cache_cell,nms_neighbor;
    reg line_tail;
    initial $readmemh(COEFFICIENT_FILE,coefficient_rom);
    always @(posedge clk)coefficient_q<=coefficient_rom[{batch,coefficient_lane}];
    wire signed [16:0] offered_c=coefficient_q[16:0],offered_s=coefficient_q[33:17];
    wire [16:0] abs_c=offered_c[16]?-offered_c:offered_c;
    wire [16:0] abs_s=offered_s[16]?-offered_s:offered_s;
    wire coefficient_good=offered_c>=-17'sd32768&&offered_c<=17'sd32768&&
        offered_s>=-17'sd32768&&offered_s<=17'sd32768&&(abs_c>=17'd21846||abs_s>=17'd21846);
    wire [2:0] selected_point_lane=state==NMS_LOAD_CAPTURE?cache_cell[3:1]:point_lane;
    wire [63:0] point=rsp_data[selected_point_lane*64+:64];
    wire [10:0] px=point[42:32],py=point[53:43];
    wire signed [10:0] gx=point[10:0],gy=point[21:11];
    wire [10:0] ax=gx[10]?-gx:gx,ay=gy[10]?-gy:gy;
    wire signed [12:0] x2=$signed({1'b0,px,1'b0})-13'(WIDTH-1);
    wire signed [12:0] y2=$signed({1'b0,py,1'b0})-13'(HEIGHT-1);
    wire point_good=point[63]==0&&point[31:24]==0&&px<WIDTH&&py<HEIGHT&&point[21:0]!=0&&
        gx>=-11'sd1020&&gx<=11'sd1020&&gy>=-11'sd1020&&gy<=11'sd1020&&
        ({1'b0,ax}+{1'b0,ay})<=12'd1530&&x2[12]==x2[11]&&y2[12]==y2[11]&&
        (ordinal==0||point[53:32]>previous_xy);
    wire response_good=rsp_valid&&!rsp_error&&rsp_drained;
    wire [32:0] point_bytes={9'd0,points,3'd0};
    wire [32:0] point_allocation=(point_bytes+33'd63)&~33'd63;
    wire [32:0] point_end={1'b0,point_base}+point_allocation;
    wire [32:0] dense_end={1'b0,dense_base}+33'd1048576;
    wire [32:0] meta_end={1'b0,metadata_base}+33'd64;
    wire [32:0] line_end={1'b0,line_base}+33'd8192;
    wire legal_start=points<=WIDTH*HEIGHT&&point_base[5:0]==0&&dense_base[10:0]==0&&metadata_base[5:0]==0&&
        line_base[5:0]==0&&line_min_support!=0&&
        point_end<=ADDRESS_BYTES&&dense_end<=ADDRESS_BYTES&&meta_end<=ADDRESS_BYTES&&line_end<=ADDRESS_BYTES&&
        (point_end<={1'b0,dense_base}||dense_end<={1'b0,point_base})&&
        (point_end<={1'b0,metadata_base}||meta_end<={1'b0,point_base})&&
        (dense_end<={1'b0,metadata_base}||meta_end<={1'b0,dense_base})&&
        (point_end<={1'b0,line_base}||line_end<={1'b0,point_base})&&
        (dense_end<={1'b0,line_base}||line_end<={1'b0,dense_base})&&
        (meta_end<={1'b0,line_base}||line_end<={1'b0,metadata_base});
    // theta首尾跨越时rho镜像；outside邻居票为0，比较顺序使用镜像后的真实坐标。
    wire [1:0] neighbor_plane=nms_neighbor<3?2'd0:nms_neighbor<6?2'd1:2'd2;
    wire signed [9:0] neighbor_unwrapped=$signed({1'b0,nms_rho})+
        ((nms_neighbor==0||nms_neighbor==3||nms_neighbor==6)?-10'sd1:
         (nms_neighbor==2||nms_neighbor==5||nms_neighbor==8)?10'sd1:10'sd0);
    wire neighbor_legal=neighbor_unwrapped>=0&&neighbor_unwrapped<=10'sd276;
    wire neighbor_mirror=(neighbor_plane==0&&nms_theta==0)||(neighbor_plane==2&&nms_theta==511);
    wire [8:0] neighbor_row=neighbor_mirror?9'd276-neighbor_unwrapped[8:0]:neighbor_unwrapped[8:0];
    wire [8:0] neighbor_theta=neighbor_plane==0?(nms_theta==0?9'd511:nms_theta-9'd1):
        neighbor_plane==2?(nms_theta==511?9'd0:nms_theta+9'd1):nms_theta;
    wire neighbor_precedes=neighbor_theta<nms_theta||(neighbor_theta==nms_theta&&neighbor_row<nms_rho);
    wire [8:0] cache_theta=cache_plane==0?(nms_theta==0?9'd511:nms_theta-9'd1):
        cache_plane==2?(nms_theta==511?9'd0:nms_theta+9'd1):nms_theta;
    wire [31:0] cache_value=cache_cell[0]?point[63:32]:point[31:0];
    wire cache_good=cache_value[31:15]==0&&cache_value[20:0]<=point_limit&&
        ({cache_block,cache_cell}<277||cache_value==0);
    // RNE(P/2^19)对负数先幅度舍入再恢复符号，半界按商的奇偶处理。
    function automatic signed [12:0] round_projection(input reg signed [29:0] p);
        reg [29:0] magnitude;reg [11:0] quotient;
        begin
            magnitude=p[29]?-p:p;quotient=12'(magnitude>>19);
            if(magnitude[18:0]>19'h40000||(magnitude[18:0]==19'h40000&&quotient[0]))quotient=quotient+12'd1;
            round_projection=p[29]?-$signed({1'b0,quotient}):$signed({1'b0,quotient});
        end
    endfunction
    wire signed [12:0] projected[0:LANES-1];
    wire signed [13:0] biased[0:LANES-1];
    reg projection_bad,counter_bad;
    // 完整Q15系数至少一轴abs>=21846。RNE rho箱的P跨度<=2^19，
    // 固定另一坐标时相邻像素P间隔>=43692，因此每行/列至多12个唯一POINT。
    // rowmajor严格递增已经排除重复；12*max(1920,1080)=23040<2^15。
    // 内部15位是该几何域的精确计数，DDR仍输出uint21/32，未截断全帧点数。
    wire [14:0] histogram_q[0:LANES-1];
    wire [8:0] ram_address[0:LANES-1];
    for(genvar lane=0;lane<LANES;lane++)begin:g_vote
        wire [47:0] mx,my;
        // B仅在本lane系数接受沿加载；O忽略CE、每沿采样，MUL_CAPTURE沿的乘积在PROJECT使用。
        // 与原外部乘积寄存器同一有效采样沿，系数和乘积暂存移入DSP，数值位宽保持不变。
        wire coefficient_load=!rst&&state==COEFF_CAPTURE&&coefficient_lane==lane&&coefficient_good;
        EFX_DSP48 #(.MODE("NORMAL"),.SIGNED(1'b1),.A_REG(1'b0),.B_REG(1'b1),.P_REG(1'b0),
            .W_REG(1'b0),.O_REG(1'b1),.B_REG_USE_CE(1'b1),.O_REG_USE_CE(1'b0),
            .B_REG_USE_RST(1'b0),.O_REG_USE_RST(1'b0),.SHIFTER(1'b0),.W_SEL("P"),.N_SEL("CONST0")) multiply_x(
            .A({{7{centered_x[11]}},centered_x}),.B({offered_c[16],offered_c}),
            .C(18'd0),.CASCIN(48'd0),.OP(2'd0),.SHIFT_ENA(1'b0),.CLK(clk),.CE(coefficient_load),.RST(1'b0),.O(mx),.CASCOUT(),.OVFL());
        EFX_DSP48 #(.MODE("NORMAL"),.SIGNED(1'b1),.A_REG(1'b0),.B_REG(1'b1),.P_REG(1'b0),
            .W_REG(1'b0),.O_REG(1'b1),.B_REG_USE_CE(1'b1),.O_REG_USE_CE(1'b0),
            .B_REG_USE_RST(1'b0),.O_REG_USE_RST(1'b0),.SHIFTER(1'b0),.W_SEL("P"),.N_SEL("CONST0")) multiply_y(
            .A({{7{centered_y[11]}},centered_y}),.B({offered_s[16],offered_s}),
            .C(18'd0),.CASCIN(48'd0),.OP(2'd0),.SHIFT_ENA(1'b0),.CLK(clk),.CE(coefficient_load),.RST(1'b0),.O(my),.CASCOUT(),.OVFL());
        assign projected[lane]=round_projection($signed({mx[28],mx[28:0]})+$signed({my[28],my[28:0]}));
        assign biased[lane]=$signed({projected[lane][12],projected[lane]})+14'sd138;
        // 每theta独立1R1W，同一点的LANES票在唯一VOTE_WRITE沿一起真实写入。
        reg [14:0] histogram[0:511],q;
        assign histogram_q[lane]=q;
        assign ram_address[lane]=state==CLEAR?clear_row:
            (state==NMS_LOAD_CAPTURE)?{cache_block,cache_cell}:
            (state==NMS_CENTER_READ||state==NMS_CENTER_CAPTURE)?nms_rho:
            (state==NMS_NEIGHBOR_READ||state==NMS_NEIGHBOR_CAPTURE)?neighbor_row:
            (state==EXPORT_READ||state==EXPORT_CAPTURE)?export_row:rho[lane];
        wire cache_write=lane<3&&state==NMS_LOAD_CAPTURE&&cache_plane==lane&&response_good&&cache_good;
        wire vote_write=state==VOTE_WRITE&&!counter_bad&&response_good;
        wire ram_write=!rst&&(state==CLEAR||vote_write||cache_write);
        wire [14:0] ram_write_data=state==CLEAR?15'd0:cache_write?cache_value[14:0]:q+15'd1;
        // 一个索引写口是实际1R1W RAM模板；clear、投票与缓存均在相同端口复用。
        always @(posedge clk)begin
            q<=histogram[ram_address[lane]];
            if(ram_write)histogram[ram_address[lane]]<=ram_write_data;
        end
    end
    wire [20:0] neighbor_votes=neighbor_plane==0?histogram_q[0]:
        neighbor_plane==1?histogram_q[1]:histogram_q[2];
    // 每个峰只推进一次。最后一行关闭时，先补齐真实64B尾写，再发布完整META。
    task automatic next_nms_center(input reg appended);
        begin
            if(nms_rho!=276)begin nms_rho<=nms_rho+9'd1;state<=NMS_CENTER_READ;end
            else if(nms_theta!=511)begin
                nms_theta<=nms_theta+9'd1;cache_plane<=0;cache_block<=0;state<=NMS_LOAD_SETUP;
            end else if(fill!=0||appended)begin line_tail<=1;state<=NMS_PAD;end
            else begin address<=locked_meta_base;fill<=0;is_meta<=1;state<=META_PACK;end
        end
    endtask
    always @*begin
        projection_bad=0;counter_bad=0;
        for(integer lane=0;lane<LANES;lane++)begin
            if(projected[lane]<-13'sd138||projected[lane]>13'sd138||biased[lane]<0||biased[lane]>276)projection_bad=1;
            if(histogram_q[lane]>=point_limit||histogram_q[lane]==15'h7fff)counter_bad=1;
        end
    end
    reg [511:0] metadata;
    always @*begin
        metadata=0;metadata[95:0]=locked_scope;metadata[116:96]=point_limit;
        metadata[124:117]=point_passes;metadata[152:125]=point_visits;metadata[182:153]=vote_updates;
        metadata[190:183]=8'd3;metadata[201:191]=11'(WIDTH);metadata[212:202]=11'(HEIGHT);metadata[213]=1;
        metadata[224:214]=line_count;metadata[245:225]=locked_line_min;
        metadata[277:246]=locked_line_base;metadata[278]=1;metadata[283:279]=5'(LANES);
    end
    assign start_ready=!rst&&(state==IDLE||state==COMPLETE);
    assign done=!rst&&state==COMPLETE;
    assign req_valid=!rst&&(state==POINT_REQ||state==WRITE_REQ||state==NMS_LOAD_REQ||state==NMS_LINE_REQ);
    assign req_write=state==WRITE_REQ||state==NMS_LINE_REQ;
    assign req_addr=(state==POINT_REQ||state==NMS_LINE_REQ)?point_address:address;
    assign rsp_ready=!rst&&(state==POINT_CLOSE||state==WRITE_RSP||state==NMS_LOAD_CLOSE||state==NMS_LINE_RSP);
    assign pack_valid=!rst&&(state==EXPORT_PACK||state==META_PACK||state==NMS_PEAK_PACK||state==NMS_PAD);
    assign pack_index=fill;
    assign pack_data=state==META_PACK?metadata[fill*64+:64]:
        state==NMS_PEAK_PACK?{25'd0,center_votes,nms_rho,nms_theta}:state==NMS_PAD?64'd0:packed_word;
    always @(posedge clk)begin
        if(rst)begin state<=IDLE;fault<=0;point_passes<=0;point_visits<=0;vote_updates<=0;line_count<=0;end
        else if(start&&start_ready)begin
            point_limit<=points;locked_point_base<=point_base;
            locked_dense_base<=dense_base;locked_meta_base<=metadata_base;point_address<=point_base;
            locked_line_base<=line_base;locked_line_min<=line_min_support;line_count<=0;line_tail<=0;
            batch<=0;clear_row<=0;coefficient_lane<=0;ordinal<=0;point_lane<=0;fill<=0;is_meta<=0;
            fault<=!legal_start;point_passes<=0;point_visits<=0;vote_updates<=0;state<=legal_start?CLEAR:FAILED;
        end else case(state)
            CLEAR:if(clear_row==511)begin coefficient_lane<=0;state<=COEFF_READ;end else clear_row<=clear_row+9'd1;
            COEFF_READ:state<=COEFF_CAPTURE;
            COEFF_CAPTURE:if(!coefficient_good)begin fault<=1;state<=FAILED;end else begin
                if(coefficient_lane==LANES-1)begin
                    ordinal<=0;point_lane<=0;point_address<=locked_point_base;
                    state<=point_limit==0?EXPORT_SETUP:POINT_REQ;
                end else begin coefficient_lane<=coefficient_lane+1'b1;state<=COEFF_READ;end
            end
            POINT_REQ:if(req_valid&&req_ready)state<=POINT_WAIT;
            POINT_WAIT:if(rsp_valid)begin
                if(!response_good)begin fault<=1;state<=POINT_CLOSE;end else state<=POINT_CAPTURE;
            end
            POINT_CAPTURE:if(!response_good||!point_good)begin fault<=1;state<=POINT_CLOSE;end else begin
                previous_xy<=point[53:32];centered_x<=x2[11:0];centered_y<=y2[11:0];state<=MUL_CAPTURE;
            end
            MUL_CAPTURE:state<=PROJECT;
            PROJECT:if(projection_bad)begin fault<=1;state<=POINT_CLOSE;end else begin
                for(integer lane=0;lane<LANES;lane++)rho[lane]<=biased[lane][8:0];state<=VOTE_READ;
            end
            VOTE_READ:state<=VOTE_WRITE;
            VOTE_WRITE:if(!response_good||counter_bad||point_visits==28'hfffffff||vote_updates>30'h3fffffff-LANES)begin
                fault<=1;state<=POINT_CLOSE;
            end else begin
                point_visits<=point_visits+28'd1;vote_updates<=vote_updates+30'(LANES);ordinal<=ordinal+21'd1;
                if(ordinal+21'd1==point_limit)begin
                    if(point_lane==7)state<=POINT_CLOSE;else begin point_lane<=point_lane+3'd1;state<=PADDING;end
                end else if(point_lane==7)state<=POINT_CLOSE;
                else begin point_lane<=point_lane+3'd1;state<=POINT_CAPTURE;end
            end
            PADDING:if(!response_good||point!=0)begin fault<=1;state<=POINT_CLOSE;end
                else if(point_lane==7)state<=POINT_CLOSE;else point_lane<=point_lane+3'd1;
            POINT_CLOSE:if(rsp_valid&&rsp_ready)begin
                if(fault||!response_good)begin fault<=1;state<=FAILED;end
                else if(ordinal==point_limit)state<=EXPORT_SETUP;
                else begin point_lane<=0;point_address<=point_address+32'd64;state<=POINT_REQ;end
            end
            EXPORT_SETUP:begin
                export_lane<=0;export_row<=0;export_half<=0;fill<=0;is_meta<=0;
                address<=locked_dense_base+(32'(batch)<<(LANE_BITS+11));state<=EXPORT_READ;
            end
            EXPORT_READ:state<=EXPORT_CAPTURE;
            EXPORT_CAPTURE:if(histogram_q[export_lane]>point_limit||(export_row>=277&&histogram_q[export_lane]!=0))begin
                fault<=1;state<=FAILED;
            end else if(!export_half)begin
                first_cell<={17'd0,histogram_q[export_lane]};export_half<=1;export_row<=export_row+9'd1;state<=EXPORT_READ;
            end else begin packed_word<={17'd0,histogram_q[export_lane],first_cell};export_half<=0;state<=EXPORT_PACK;end
            EXPORT_PACK:if(fill==7)begin fill<=0;state<=WRITE_REQ;end
                else begin fill<=fill+3'd1;export_row<=export_row+9'd1;state<=EXPORT_READ;end
            WRITE_REQ:if(req_valid&&req_ready)state<=WRITE_RSP;
            WRITE_RSP:if(rsp_valid&&rsp_ready)begin
                if(!response_good)begin fault<=1;state<=FAILED;end
                else if(is_meta)state<=COMPLETE;
                else begin
                    address<=address+32'd64;
                    if(export_row!=511)begin export_row<=export_row+9'd1;state<=EXPORT_READ;end
                    else if(export_lane!=LANES-1)begin export_lane<=export_lane+1'b1;export_row<=0;state<=EXPORT_READ;end
                    else begin
                        point_passes<=point_passes+8'd1;
                        if(batch!=BATCHES-1)begin batch<=batch+1'b1;clear_row<=0;state<=CLEAR;end
                        else begin
                            nms_theta<=0;cache_plane<=0;cache_block<=0;fill<=0;
                            point_address<=locked_line_base;state<=NMS_LOAD_SETUP;
                        end
                    end
                end
            end
            META_PACK:if(fill==7)begin fill<=0;state<=WRITE_REQ;end else fill<=fill+3'd1;
            NMS_LOAD_SETUP:begin
                address<=locked_dense_base+({23'd0,cache_theta}<<11)+({27'd0,cache_block}<<6);
                cache_cell<=0;state<=NMS_LOAD_REQ;
            end
            NMS_LOAD_REQ:if(req_valid&&req_ready)state<=NMS_LOAD_WAIT;
            NMS_LOAD_WAIT:if(rsp_valid)begin
                if(!response_good)begin fault<=1;state<=NMS_LOAD_CLOSE;end else state<=NMS_LOAD_CAPTURE;
            end
            NMS_LOAD_CAPTURE:if(!response_good||!cache_good)begin fault<=1;state<=NMS_LOAD_CLOSE;end
                else if(cache_cell==15)state<=NMS_LOAD_CLOSE;else cache_cell<=cache_cell+4'd1;
            NMS_LOAD_CLOSE:if(rsp_valid&&rsp_ready)begin
                if(fault||!response_good)begin fault<=1;state<=FAILED;end
                else if(cache_block!=31)begin cache_block<=cache_block+5'd1;state<=NMS_LOAD_SETUP;end
                else if(cache_plane!=2)begin cache_plane<=cache_plane+2'd1;cache_block<=0;state<=NMS_LOAD_SETUP;end
                else begin nms_rho<=0;state<=NMS_CENTER_READ;end
            end
            NMS_CENTER_READ:state<=NMS_CENTER_CAPTURE;
            NMS_CENTER_CAPTURE:begin
                center_votes<=histogram_q[1];
                if(histogram_q[1]==0||histogram_q[1]<locked_line_min)next_nms_center(1'b0);
                else begin nms_neighbor<=0;state<=NMS_NEIGHBOR_READ;end
            end
            NMS_NEIGHBOR_READ:state<=NMS_NEIGHBOR_CAPTURE;
            NMS_NEIGHBOR_CAPTURE:if(neighbor_legal&&
                (neighbor_votes>center_votes||(neighbor_votes==center_votes&&neighbor_precedes)))next_nms_center(1'b0);
                else if(nms_neighbor!=8)begin nms_neighbor<=nms_neighbor+4'd1;state<=NMS_NEIGHBOR_READ;end
                else if(line_count==1024)begin fault<=1;state<=FAILED;end
                else state<=NMS_PEAK_PACK;
            NMS_PEAK_PACK:begin
                line_count<=line_count+11'd1;
                if(fill==7)begin fill<=0;state<=NMS_LINE_REQ;end
                else begin fill<=fill+3'd1;next_nms_center(1'b1);end
            end
            NMS_PAD:if(fill==7)begin fill<=0;state<=NMS_LINE_REQ;end else fill<=fill+3'd1;
            NMS_LINE_REQ:if(req_valid&&req_ready)state<=NMS_LINE_RSP;
            NMS_LINE_RSP:if(rsp_valid&&rsp_ready)begin
                if(!response_good)begin fault<=1;state<=FAILED;end
                else if(line_tail)begin address<=locked_meta_base;fill<=0;is_meta<=1;state<=META_PACK;end
                else begin point_address<=point_address+32'd64;next_nms_center(1'b0);end
            end
            IDLE,COMPLETE,FAILED:begin end
            default:begin fault<=1;state<=FAILED;end
        endcase
    end
    // synthesis translate_off
    initial if(WIDTH<6||WIDTH>1920||WIDTH%2||HEIGHT<5||HEIGHT>1080)$fatal(1,"Hough geometry");
    initial if(LANES!=4&&LANES!=8&&LANES!=16)$fatal(1,"Hough lanes");
    // synthesis translate_on
endmodule
