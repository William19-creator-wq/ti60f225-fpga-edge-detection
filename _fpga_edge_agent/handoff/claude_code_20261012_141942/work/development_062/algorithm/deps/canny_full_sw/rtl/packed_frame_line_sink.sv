// FC02/04：一个私有512bit累加槽；末项使用next_buffer；公开RPC直到drain。
module packed_frame_line_sink #(
    parameter integer unsigned ITEM_BITS=4,ITEMS=1036800,ID_BITS=96,
    parameter bit DSP_BUFFER=1'b0
)(
    input logic clk,rst,
    input logic cfg_valid,output wire cfg_ready,input logic [31:0] cfg_base,input logic [ID_BITS-1:0] cfg_id,
    output wire cfg_rsp_valid,input logic cfg_rsp_ready,output logic cfg_rsp_error,
    input logic in_valid,output wire in_ready,input logic [ITEM_BITS-1:0] in_data,input logic in_bad,
    input logic abort_valid,input logic [ID_BITS-1:0] abort_id,
    output wire done_valid,input logic done_ready,output logic done_error,done_aborted,output wire done_drained,
    output logic [21:0] count,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output logic [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained,output wire quarantined
);
    localparam integer unsigned PER_LINE=512/ITEM_BITS,SLOT_BITS=$clog2(PER_LINE);
    localparam integer unsigned TAIL_ITEMS=ITEMS%PER_LINE,TAIL_SHIFT=(PER_LINE-TAIL_ITEMS)*ITEM_BITS;
    localparam logic [32:0] ALLOCATION=33'(((ITEMS+PER_LINE-1)/PER_LINE)*64);
    typedef enum logic [2:0] {IDLE,CFG_REPLY,ACCEPT,REQUEST,WAIT_RESPONSE,DONE,QUARANTINE} state_t;
    state_t state;
    logic [31:0] base;
    logic [ID_BITS-1:0] active_id;
    logic abort_sticky;
    wire [511:0] buffer;
    logic [511:0] next_buffer;
    wire matching_abort=abort_valid && state!=IDLE && state!=DONE && abort_id==active_id;
    wire stopping=abort_sticky || matching_abort;
    wire [32:0] cfg_end={1'b0,cfg_base}+ALLOCATION;
    assign cfg_ready=!rst && state==IDLE;
    assign cfg_rsp_valid=!rst && state==CFG_REPLY;
    assign in_ready=!rst && state==ACCEPT && !stopping;
    assign done_valid=!rst && state==DONE;
    assign done_drained=state==DONE;
    assign line_req_valid=!rst && state==REQUEST;
    assign line_rsp_ready=!rst && state==WAIT_RESPONSE;
    assign line_write=1'b1;
    assign line_wdata=buffer;
    assign quarantined=state==QUARANTINE;
    always_comb next_buffer={in_data,buffer[511:ITEM_BITS]};
    wire buffer_write=!rst && state==ACCEPT && !stopping && in_valid && in_ready &&
        !in_bad && count<22'(ITEMS);
    wire [511:0] buffer_write_data=(TAIL_ITEMS!=0&&count==22'(ITEMS-1))?
        (next_buffer>>TAIL_SHIFT):next_buffer;
    generate if(DSP_BUFFER)begin:dsp_buffer
        wire [539:0] padded_input={28'd0,buffer_write_data};
        wire [539:0] padded_output;
        assign buffer=padded_output[511:0];
        for(genvar stripe=0;stripe<15;stripe++)begin:words
            wire [35:0] register_input=padded_input[stripe*36+:36];
            wire [47:0] registered_output;
            assign padded_output[stripe*36+:36]=registered_output[35:0];
            // 高19bit乘2^17与低17bit相加，无位重叠；硬O寄存器在原buffer写沿采样。
            // CE为0保持公开正文；数据不复位，原状态/计数隔离未完整组装的块。
            EFX_DSP48 #(.MODE("NORMAL"),.SIGNED(1'b0),.A_REG(1'b0),.B_REG(1'b0),
                .C_REG(1'b0),.P_REG(1'b0),.OP_REG(1'b0),.W_REG(1'b0),.O_REG(1'b1),
                .P_EXT("ALIGN_RIGHT"),.C_EXT("ALIGN_RIGHT"),
                .M_SEL("P"),.N_SEL("C"),.W_SEL("X"),.SHIFTER(1'b0),
                .RST_SYNC(1'b1),.O_REG_USE_CE(1'b1),.O_REG_USE_RST(1'b0)) storage(
                .A(register_input[35:17]),.B(18'h20000),
                .C({1'b0,register_input[16:0]}),.CASCIN(48'd0),.OP(2'b00),
                .SHIFT_ENA(1'b0),.CLK(clk),.CE(buffer_write),.RST(1'b0),
                .O(registered_output),.CASCOUT(),.OVFL());
        end
    end else begin:ff_buffer
        logic [511:0] held_buffer;
        assign buffer=held_buffer;
        always_ff @(posedge clk)if(buffer_write)held_buffer<=buffer_write_data;
    end endgenerate
    initial if((ITEM_BITS!=1 && ITEM_BITS!=4 && ITEM_BITS!=8) || ITEMS==0 || ITEMS>2073600 || ID_BITS<64)
        $fatal(1,"Unsupported packed line sink parameters");
    task automatic finish_task(input logic error_value,input logic aborted_value);
        begin done_error<=error_value;done_aborted<=aborted_value;state<=DONE;end
    endtask
    always_ff @(posedge clk)begin
        if(rst)begin state<=IDLE;base<=0;active_id<=0;abort_sticky<=0;count<=0;line_addr<=0;cfg_rsp_error<=0;done_error<=0;done_aborted<=0;end
        else begin
            if(matching_abort)abort_sticky<=1;
            case(state)
                IDLE:if(cfg_valid && cfg_ready)begin
                    base<=cfg_base;active_id<=cfg_id;abort_sticky<=0;count<=0;done_error<=0;done_aborted<=0;
                    cfg_rsp_error<=cfg_base[5:0]!=0 || cfg_end>33'h100000000;state<=CFG_REPLY;
                end
                CFG_REPLY:if(cfg_rsp_ready)state<=cfg_rsp_error ? IDLE : ACCEPT;
                ACCEPT:begin
                    if(stopping)finish_task(1,1);
                    else if(in_valid && in_ready)begin
                        count<=count+22'd1;
                        if(in_bad || count>=22'(ITEMS))finish_task(1,0);
                        else begin
                            // 完整块自然恢复LSB-first。末尾不足一块时只做参数确定的常量右移，高pad为0。
                            // 正文在相同接受沿由上方存储分支更新；尾部仍用常量移位补零。
                            if(count[SLOT_BITS-1:0]==SLOT_BITS'(PER_LINE-1) || count==22'(ITEMS-1))begin
                                line_addr<=32'({1'b0,base}+({11'd0,(count>>SLOT_BITS)}<<6));state<=REQUEST;
                            end
                        end
                    end
                end
                REQUEST:if(line_req_ready)state<=WAIT_RESPONSE;
                WAIT_RESPONSE:if(line_rsp_valid)begin
                    if(!line_drained)state<=QUARANTINE;
                    else if(line_error)finish_task(1,0);
                    else if(stopping)finish_task(1,1);
                    else if(count==22'(ITEMS))finish_task(0,0);
                    else state<=ACCEPT;
                end
                DONE:if(done_ready)state<=IDLE;
                default:begin end
            endcase
        end
    end
endmodule
