// FC02/04：一个私有512bit累加槽；末项使用next_buffer；公开RPC直到drain。
module packed_frame_line_sink #(
    parameter integer unsigned ITEM_BITS=4,ITEMS=1036800,ID_BITS=96,EXTERNAL_STORAGE=0
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
    input logic line_error,line_drained,output wire quarantined,
    output wire storage_clear,storage_write,output wire [511:0] storage_next,
    input wire [511:0] storage_current
);
    localparam integer unsigned PER_LINE=512/ITEM_BITS,SLOT_BITS=$clog2(PER_LINE);
    localparam logic [32:0] ALLOCATION=33'(((ITEMS+PER_LINE-1)/PER_LINE)*64);
    typedef enum logic [2:0] {IDLE,CFG_REPLY,ACCEPT,REQUEST,WAIT_RESPONSE,DONE,QUARANTINE,PAD} state_t;
    state_t state;
    logic [31:0] base;
    logic [ID_BITS-1:0] active_id;
    logic abort_sticky;
    logic [SLOT_BITS-1:0] pad_left;
    wire [511:0] buffer;logic [511:0] next_buffer;
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
    // Spend otherwise idle hard DSP registers on the wide line holding slot.
    // This is a bit-exact one-clock enabled register, not arithmetic or an
    // extra pipeline stage. Control validity and DDR ownership are unchanged.
    wire clear_buffer=(state==IDLE&&cfg_valid&&cfg_ready)||
        (state==WAIT_RESPONSE&&line_rsp_valid&&line_drained&&!line_error&&!stopping&&count!=22'(ITEMS));
    wire write_buffer=(state==ACCEPT&&in_valid&&in_ready&&!in_bad&&count<22'(ITEMS))||(state==PAD&&!stopping);
    assign storage_clear=clear_buffer;
    assign storage_write=write_buffer;
    assign storage_next=next_buffer;
    generate if(EXTERNAL_STORAGE)begin:external_payload
        assign buffer=storage_current;
    end else begin:private_payload
        packed_frame_storage storage(.clk,.rst(rst||clear_buffer),
            .write_enable(write_buffer),.next_data(next_buffer),.held_data(buffer));
    end endgenerate
    always_comb begin
        // Serial packing avoids a 512-bit indexed update mux. After PER_LINE
        // shifts the earliest item is in the low bits. A partial final line
        // shifts zeros before it is published, preserving exact tail padding.
        next_buffer={(state==PAD?{ITEM_BITS{1'b0}}:in_data),buffer[511:ITEM_BITS]};
    end
    initial if((ITEM_BITS!=4 && ITEM_BITS!=8 && ITEM_BITS!=64) || ITEMS==0 || ITEMS>2073600 || ID_BITS<64)
        $fatal(1,"Unsupported packed line sink parameters");
    task automatic finish_task(input logic error_value,input logic aborted_value);
        begin done_error<=error_value;done_aborted<=aborted_value;state<=DONE;end
    endtask
    always_ff @(posedge clk)begin
        if(rst)begin state<=IDLE;pad_left<=0;base<=0;active_id<=0;abort_sticky<=0;count<=0;line_addr<=0;cfg_rsp_error<=0;done_error<=0;done_aborted<=0;end
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
                            
                            if(count[SLOT_BITS-1:0]==SLOT_BITS'(PER_LINE-1) || count==22'(ITEMS-1))begin
                                line_addr<=32'({1'b0,base}+({11'd0,(count>>SLOT_BITS)}<<6));
                                if(count[SLOT_BITS-1:0]==SLOT_BITS'(PER_LINE-1))state<=REQUEST;
                                else begin pad_left<=SLOT_BITS'(PER_LINE-1)-count[SLOT_BITS-1:0];state<=PAD;end
                            end
                        end
                    end
                end
                PAD:if(stopping)finish_task(1,1);else if(pad_left==1)begin pad_left<=0;state<=REQUEST;end
                    else pad_left<=pad_left-1'b1;
                REQUEST:if(line_req_ready)state<=WAIT_RESPONSE;
                WAIT_RESPONSE:if(line_rsp_valid)begin
                    if(!line_drained)state<=QUARANTINE;
                    else if(line_error)finish_task(1,0);
                    else if(stopping)finish_task(1,1);
                    else if(count==22'(ITEMS))finish_task(0,0);
                    else begin state<=ACCEPT;end
                end
                DONE:if(done_ready)state<=IDLE;
                default:begin end
            endcase
        end
    end
endmodule

// Native DSP register bank. Exactly one enabled transfer, synchronous reset.
// Sharing is legal only after the preceding writer's drained done response.
module packed_frame_storage(
    input wire clk,rst,write_enable,input wire [511:0] next_data,
    output wire [511:0] held_data
);
    wire [539:0] hard_line_storage_in={28'd0,next_data};wire [539:0] hard_line_storage_out;
    assign held_data=hard_line_storage_out[511:0];
    for(genvar chunk=0;chunk<15;chunk++)begin:hard_line_storage
        wire [35:0] data_word=hard_line_storage_in[chunk*36+:36];wire [47:0] held;
        EFX_DSP48 #(.SIGNED(0),.O_REG(1),.RST_SYNC(1),.N_SEL("C")) storage(
            .A(data_word[35:17]),.B(18'h20000),.C({1'b0,data_word[16:0]}),.CASCIN(48'd0),
            .OP(2'b00),.SHIFT_ENA(1'b0),.CLK(clk),.CE(write_enable),
            .RST(rst),.O(held),.CASCOUT(),.OVFL());
        assign hard_line_storage_out[chunk*36+:36]=held[35:0];
    end
endmodule
