// VFREQ01..04 / VF01..06：不可反压记录运输；只有共同安全冷复位可清损失。
module raw_capture_fifo #(parameter integer WIDTH=128,DEPTH=1024)(
    input logic cold_reset_n,wr_clk,rd_clk,
    input logic wr_valid,input logic [WIDTH-1:0] wr_data,
    output wire wr_ready,wr_accept,wr_running,output logic wr_overflow,
    output logic [31:0] wr_loss_count,
    input logic rd_ready,output wire rd_valid,output wire [WIDTH-1:0] rd_data,
    output wire rd_running,rd_fault,output wire [$clog2(DEPTH):0] rd_available,
    output wire [$clog2(DEPTH):0] wr_free
);
    localparam integer AW=$clog2(DEPTH),STRIPES=(WIDTH+19)/20,PAD_WIDTH=STRIPES*20;
    localparam integer BANKS=DEPTH>512 ? DEPTH/512 : 1,BW=BANKS>1 ? $clog2(BANKS) : 1;
    (* ASYNC_REG="TRUE" *) logic [1:0] wr_reset_pipe,rd_reset_pipe;
    (* ASYNC_REG="TRUE" *) logic [AW:0] rgray_meta,rgray_sync,wgray_meta,wgray_sync;
    (* ASYNC_REG="TRUE" *) logic fault_meta,fault_sync;
    logic [AW:0] wbin,wgray,rbin,rgray;
    wire [AW:0] wnext=wbin+{{AW{1'b0}},1'b1},rnext=rbin+{{AW{1'b0}},1'b1};
    wire [AW:0] full_match={~rgray_sync[AW:AW-1],rgray_sync[AW-2:0]};
    wire full=wgray==full_match,empty=rgray==wgray_sync;
    wire [AW-1:0] waddr=wbin[AW-1:0],raddr=rbin[AW-1:0];
    wire [PAD_WIDTH-1:0] padded_input={{(PAD_WIDTH-WIDTH){1'b0}},wr_data};
    wire [19:0] ram_q [0:BANKS-1][0:STRIPES-1];
    wire [PAD_WIDTH-1:0] ram_record;
    logic [AW:0] synced_write_binary;
    logic [AW:0] synced_read_binary;
    always_comb begin
      synced_read_binary[AW]=rgray_sync[AW];
      for(integer k=AW-1;k>=0;k=k-1) synced_read_binary[k]=synced_read_binary[k+1]^rgray_sync[k];
    end
    assign wr_free=DEPTH-(wbin-synced_read_binary);
    always_comb begin
      synced_write_binary[AW]=wgray_sync[AW];
      for(integer k=AW-1;k>=0;k=k-1) synced_write_binary[k]=synced_write_binary[k+1]^wgray_sync[k];
    end
    logic [BW-1:0] read_bank;
    logic [WIDTH-1:0] slot0,slot1;
    logic head,tail,pending;
    logic [1:0] count;
    assign rd_available=(synced_write_binary-rbin)+count+pending;
    wire pop=rd_valid && rd_ready;
    // 回复和消费均按旧状态计算，再为本沿新RE预留信用。
    wire [2:0] after_capture={1'b0,count}+{2'b0,pending}-{2'b0,pop};
    wire read_issue=rd_running && !empty && after_capture<3'd2;
    assign wr_running=wr_reset_pipe==0;assign rd_running=rd_reset_pipe==0;
    assign wr_ready=wr_running && !wr_overflow && !full;
    assign wr_accept=wr_valid && wr_ready;
    assign rd_valid=rd_running && count!=0;
    assign rd_data=head ? slot1 : slot0;
    assign rd_fault=rd_running && fault_sync;

    always_ff @(posedge wr_clk or negedge cold_reset_n)
        if(!cold_reset_n)wr_reset_pipe<=2'b11;else wr_reset_pipe<={wr_reset_pipe[0],1'b0};
    always_ff @(posedge rd_clk or negedge cold_reset_n)
        if(!cold_reset_n)rd_reset_pipe<=2'b11;else rd_reset_pipe<={rd_reset_pipe[0],1'b0};

    always_ff @(posedge wr_clk or negedge cold_reset_n)begin
        if(!cold_reset_n)begin rgray_meta<=0;rgray_sync<=0;end
        else if(!wr_running)begin rgray_meta<=0;rgray_sync<=0;end
        else begin rgray_meta<=rgray;rgray_sync<=rgray_meta;end
    end
    always_ff @(posedge rd_clk or negedge cold_reset_n)begin
        if(!cold_reset_n)begin wgray_meta<=0;wgray_sync<=0;fault_meta<=0;fault_sync<=0;end
        else if(!rd_running)begin wgray_meta<=0;wgray_sync<=0;fault_meta<=0;fault_sync<=0;end
        else begin wgray_meta<=wgray;wgray_sync<=wgray_meta;fault_meta<=wr_overflow;fault_sync<=fault_meta;end
    end
    always_ff @(posedge wr_clk or negedge cold_reset_n)begin
        if(!cold_reset_n)begin wbin<=0;wgray<=0;wr_overflow<=0;wr_loss_count<=0;end
        else if(!wr_running)begin wbin<=0;wgray<=0;wr_overflow<=0;wr_loss_count<=0;end
        else begin
            if(wr_accept)begin wbin<=wnext;wgray<=(wnext>>1)^wnext;end
            if(wr_valid && !wr_ready)begin
                wr_overflow<=1;
                if(wr_loss_count!=32'hffffffff)wr_loss_count<=wr_loss_count+32'd1;
            end
        end
    end
    always_ff @(posedge rd_clk or negedge cold_reset_n)begin
        if(!cold_reset_n)begin rbin<=0;rgray<=0;read_bank<=0;head<=0;tail<=0;pending<=0;count<=0;slot0<=0;slot1<=0;end
        else if(!rd_running)begin rbin<=0;rgray<=0;read_bank<=0;head<=0;tail<=0;pending<=0;count<=0;slot0<=0;slot1<=0;end
        else begin
            pending<=read_issue;count<=after_capture[1:0];
            if(read_issue)begin rbin<=rnext;rgray<=(rnext>>1)^rnext;read_bank<=BW'(raddr>>9);end
            if(pending)begin
                if(tail)slot1<=ram_record[WIDTH-1:0];else slot0<=ram_record[WIDTH-1:0];
                tail<=!tail;
            end
            if(pop)head<=!head;
        end
    end
    for(genvar b=0;b<BANKS;b++)begin: bank
        for(genvar s=0;s<STRIPES;s++)begin: stripe
            wire write_enable=wr_accept && (waddr>>9)==b;
            wire read_enable=read_issue && (raddr>>9)==b;
            // 双时钟仅支持READ_UNKNOWN；Gray保守释放禁止同址冲突，不依赖冲突值。
            EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_UNKNOWN")) memory(
                .WCLK(wr_clk),.WE({2{write_enable}}),.WCLKE(1'b1),.WADDREN(1'b1),
                .WDATA(padded_input[s*20+:20]),.WADDR(9'(waddr)),
                .RCLK(rd_clk),.RE(read_enable),.RST(1'b0),.RADDREN(1'b1),.RDATA(ram_q[b][s]),.RADDR(9'(raddr)));
        end
    end
    for(genvar s=0;s<STRIPES;s++)begin: read_stripe
        assign ram_record[s*20+:20]=ram_q[read_bank][s];
    end
    // synthesis translate_off
    initial if(WIDTH<1 || WIDTH>320 || DEPTH<16 || DEPTH>4096 || (DEPTH&(DEPTH-1))!=0)$fatal(1,"Video FIFO parameter range");
    logic [AW:0] old_wgray,old_rgray;
    always @(posedge wr_clk)begin
        if(!wr_running)old_wgray=wgray;
        else begin
            if(!$onehot0(wgray^old_wgray))$fatal(1,"Write Gray changed multiple bits");old_wgray=wgray;
            if(wr_overflow && wr_accept)$fatal(1,"Overflow admitted new video record");
        end
    end
    always @(posedge rd_clk)begin
        if(!rd_running)old_rgray=rgray;
        else begin
            if(!$onehot0(rgray^old_rgray))$fatal(1,"Read Gray changed multiple bits");old_rgray=rgray;
            if({1'b0,count}+{2'b0,pending}>3'd2 || after_capture>3'd2)$fatal(1,"Video FIFO prefetch credit");
        end
    end
    // synthesis translate_on
endmodule
