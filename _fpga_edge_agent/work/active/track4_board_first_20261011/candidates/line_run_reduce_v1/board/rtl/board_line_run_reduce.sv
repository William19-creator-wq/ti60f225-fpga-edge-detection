// LR01：CELL/EXT的完整4096项流归并。全run输出，eligible不替父截掉候选。
// 相同cell_index在边界发布期间不接受；上游RW回复保持到entry_fire再消费。
module board_line_run_reduce #(
    parameter integer WIDTH=1920,HEIGHT=1080
)(
    input wire clk,rst,start,output wire start_ready,
    input wire table_kind,input wire [20:0] point_limit,minimum_support,
    input wire [15:0] run_gap,coverage_min,
    input wire entry_valid,output wire entry_ready,input wire [79:0] entry,
    output reg [11:0] cell_index,
    output wire run_valid,input wire run_ready,
    output reg signed [17:0] tlo,thi,
    output reg [20:0] total,shared,
    output wire [11:0] occupied,output reg [17:0] maxgap,
    output wire [16:0] covered,span,output wire eligible,
    output wire done,quiet,output reg error
);
    localparam IDLE=0,SCAN=1,PUBLISH=2,COMPLETE=3,FAILED=4,VALIDATE=5;
    reg [2:0] state;
    reg locked_table,active,final_run;
    reg [20:0] locked_limit,locked_min,table_total;
    reg [15:0] locked_gap,locked_coverage;
    reg [12:0] occupied_count;
    reg [3:0] first_sub,last_sub;

    function automatic [3:0] mask_low(input [15:0] mask);
        integer bit_index;reg found;
        begin
            mask_low=0;found=0;
            for(bit_index=0;bit_index<16;bit_index=bit_index+1)
                if(mask[bit_index] && !found)begin mask_low=bit_index[3:0];found=1;end
        end
    endfunction
    function automatic [3:0] mask_high(input [15:0] mask);
        integer bit_index;
        begin
            mask_high=0;
            for(bit_index=0;bit_index<16;bit_index=bit_index+1)
                if(mask[bit_index])mask_high=bit_index[3:0];
        end
    endfunction
    function automatic [4:0] mask_count(input [15:0] mask);
        integer bit_index;
        begin
            mask_count=0;
            for(bit_index=0;bit_index<16;bit_index=bit_index+1)
                mask_count=mask_count+{4'd0,mask[bit_index]};
        end
    endfunction
    function automatic [3:0] mask_gap(input [15:0] mask);
        integer bit_index;reg found;reg [3:0] previous,difference;
        begin
            mask_gap=0;found=0;previous=0;difference=0;
            for(bit_index=0;bit_index<16;bit_index=bit_index+1)
                if(mask[bit_index])begin
                    difference=bit_index[3:0]-previous;
                    if(found && difference>mask_gap)mask_gap=difference;
                    previous=bit_index[3:0];found=1;
                end
        end
    endfunction

    wire [20:0] count=entry[20:0];
    wire [20:0] old_count=locked_table ? entry[41:21] : 21'd0;
    wire [3:0] minimum=locked_table ? entry[45:42] : entry[24:21];
    wire [3:0] maximum=locked_table ? entry[49:46] : entry[28:25];
    wire valid_cell=locked_table ? entry[50] : entry[29];
    wire [15:0] mask=locked_table ? entry[79:64] : entry[47:32];
    wire reserved_zero=locked_table ? entry[63:51]==0 : entry[79:48]==0 && entry[31:30]==0;
    wire entry_good=reserved_zero && (count==0 ? entry==0 :
        valid_cell && count<=locked_limit && old_count<=count && mask!=0 &&
        minimum==mask_low(mask) && maximum==mask_high(mask) &&
        count>={16'd0,mask_count(mask)});
    wire signed [17:0] cell_origin=$signed({2'd0,cell_index,4'd0})-18'sd32768;
    wire signed [17:0] next_lo=cell_origin+$signed({14'd0,minimum});
    wire signed [17:0] next_hi=cell_origin+$signed({14'd0,maximum});
    wire signed [18:0] cross_gap=$signed({next_lo[17],next_lo})-$signed({thi[17],thi});
    wire boundary=active && count!=0 && cross_gap>$signed({3'd0,locked_gap});
    wire [3:0] within_gap=mask_gap(mask);
    wire [21:0] next_table_total={1'b0,table_total}+{1'b0,count};
    wire [21:0] next_total={1'b0,total}+{1'b0,count};
    wire [21:0] next_shared={1'b0,shared}+{1'b0,old_count};

    // 首末cell只计真实端点内长度；中间各occupied cell计完整1px区间。
    wire signed [18:0] span_wide=$signed({thi[17],thi})-$signed({tlo[17],tlo});
    wire signed [18:0] covered_wide=$signed({2'd0,occupied_count,4'd0})-19'sd16-
        $signed({15'd0,first_sub})+$signed({15'd0,last_sub});
    wire run_format_good=active && !occupied_count[12] && occupied_count!=0 &&
        span_wide>=0 && span_wide<=19'sd65535 && covered_wide>=0 && covered_wide<=span_wide;
    assign occupied=occupied_count[11:0];
    assign covered=covered_wide[16:0];
    assign span=span_wide[16:0];
    wire [31:0] coverage_left={covered[15:0],16'd0}-{16'd0,covered[15:0]};
    wire [31:0] coverage_right=span[15:0]*locked_coverage;
    assign eligible=run_format_good && total>=locked_min && occupied_count>=2 &&
        span_wide>0 && coverage_left>=coverage_right;

    assign quiet=!rst && (state==IDLE || state==COMPLETE || state==FAILED);
    assign start_ready=quiet;
    assign done=!rst && (state==COMPLETE || state==FAILED);
    assign run_valid=!rst && state==PUBLISH;
    // 非法entry先真实接受再报告known失败；边界entry保持在上游，不多计/提前取走。
    assign entry_ready=!rst && state==SCAN && (!entry_valid || !entry_good || !boundary);
    wire entry_fire=entry_valid && entry_ready;
    wire parameters_good=WIDTH>=6 && WIDTH<=1920 && WIDTH%2==0 && HEIGHT>=5 && HEIGHT<=1080 &&
        {1'b0,point_limit}<=22'(WIDTH*HEIGHT) && minimum_support!=0 &&
        {1'b0,minimum_support}<=22'(WIDTH*HEIGHT) && run_gap>=16'd15;

    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;locked_table<=0;locked_limit<=0;locked_min<=0;locked_gap<=0;locked_coverage<=0;
            cell_index<=0;table_total<=0;active<=0;final_run<=0;error<=0;
            tlo<=0;thi<=0;total<=0;shared<=0;occupied_count<=0;maxgap<=0;first_sub<=0;last_sub<=0;
        end else if(start && start_ready)begin
            locked_table<=table_kind;locked_limit<=point_limit;locked_min<=minimum_support;
            locked_gap<=run_gap;locked_coverage<=coverage_min;cell_index<=0;table_total<=0;
            active<=0;final_run<=0;error<=!parameters_good;
            tlo<=0;thi<=0;total<=0;shared<=0;occupied_count<=0;maxgap<=0;first_sub<=0;last_sub<=0;
            state<=parameters_good ? SCAN : FAILED;
        end else case(state)
            SCAN:begin
                if(entry_valid && entry_good && boundary)begin
                    if(!run_format_good)begin error<=1;active<=0;state<=FAILED;end
                    else begin final_run<=0;state<=VALIDATE;end
                end else if(entry_fire)begin
                    if(!entry_good || next_table_total[21] || next_table_total>{1'b0,locked_limit} ||
                        (active && count!=0 && (cross_gap<0 || next_total[21] ||
                        next_total>{1'b0,locked_limit} || next_shared[21] || next_shared>next_total)))begin
                        error<=1;active<=0;state<=FAILED;
                    end else begin
                        table_total<=next_table_total[20:0];
                        if(count!=0)begin
                            thi<=next_hi;last_sub<=maximum;
                            if(!active)begin
                                active<=1;tlo<=next_lo;first_sub<=minimum;
                                total<=count;shared<=old_count;occupied_count<=1;maxgap<={14'd0,within_gap};
                            end else begin
                                total<=next_total[20:0];shared<=next_shared[20:0];occupied_count<=occupied_count+13'd1;
                                if(cross_gap>$signed({1'b0,maxgap}))
                                    maxgap<=cross_gap[17:0]>{14'd0,within_gap} ? cross_gap[17:0] : {14'd0,within_gap};
                                else if({14'd0,within_gap}>maxgap)maxgap<={14'd0,within_gap};
                            end
                        end
                        if(cell_index==4095)begin
                            final_run<=1;
                            if(active || count!=0)state<=VALIDATE;else state<=COMPLETE;
                        end else cell_index<=cell_index+12'd1;
                    end
                end
            end
            VALIDATE:begin
                // 最后entry的非阻塞更新已完成；容量/覆盖资格在valid前单独核查。
                if(!run_format_good)begin error<=1;active<=0;state<=FAILED;end
                else state<=PUBLISH;
            end
            PUBLISH:if(run_valid && run_ready)begin
                active<=0;total<=0;shared<=0;occupied_count<=0;
                state<=final_run ? COMPLETE : SCAN;
            end
            IDLE,COMPLETE,FAILED:begin end
            default:begin error<=1;active<=0;state<=FAILED;end
        endcase
    end
endmodule
