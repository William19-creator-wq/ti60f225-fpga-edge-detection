// 32-bit byte-strobed operations -> existing ordered 64-byte DDR line service.
// Four direct-mapped write-through lines. Source frame/scratch storage must be
// exclusively owned for the job. Invalidate before starting a new job because
// Canny or another owner may have rewritten DDR since the preceding job.
// Writes respond ONLY after the line write response. There are no dirty lines
// to flush on cancel: caller drains its word response before releasing memory.
// A response with drained=0 locks the cache until external bus and cache reset.
module shape_word_cache(
    input wire clk,rst,
    input wire invalidate_valid,output wire invalidate_ready,
    input wire mem_req_valid,output wire mem_req_ready,
    input wire [31:0] mem_addr,mem_wdata,input wire [3:0] mem_wstrb,
    output wire mem_rsp_valid,input wire mem_rsp_ready,
    output reg [31:0] mem_rdata,output reg mem_error,mem_drained,
    output wire line_req_valid,input wire line_req_ready,output wire line_write,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    input wire line_rsp_valid,output wire line_rsp_ready,input wire [511:0] line_rdata,
    input wire line_error,line_drained,
    output reg quarantined,output wire busy
);
    localparam IDLE=0,LOOKUP=1,READ_REQ=2,READ_WAIT=3,APPLY=4,WRITE_REQ=5,WRITE_WAIT=6,RESULT=7,LOCKED=8,
        FILL=9,HIT_READ=10,HIT_CAPTURE=11,GATHER_READ=12,GATHER_CAPTURE=13,WRITE_COMMIT=14;
    reg [3:0] state;
    reg [3:0] valid;
    // A [0:3] x 512-bit array wastes 26 RAM10 blocks; four register lines cost
    // nearly 6000 LUTs. Serialize cache accesses as 64 x 32-bit words instead.
    // Sixteen clocks fill/gather a DDR line, trading latency for bounded area.
    reg [25:0] tag0,tag1,tag2,tag3;
    reg [25:0] selected_tag;
    reg [31:0] address,write_data;
    reg [3:0] strobes;
    reg [1:0] index;
    wire [511:0] transfer;
    reg [3:0] cursor;
    reg [31:0] updated_word;
    wire ram_read=state==HIT_READ||state==GATHER_READ;
    wire ram_write=state==FILL||state==WRITE_COMMIT;
    wire [5:0] ram_address={index,(state==HIT_READ||state==WRITE_COMMIT)?address[5:2]:cursor};
    wire [31:0] ram_data=state==WRITE_COMMIT?updated_word:transfer[31:0];
    wire [31:0] ram_q;
    shape_cache_words32 words(.clk(clk),.re(ram_read),.we(ram_write),.address(ram_address),.data(ram_data),.q(ram_q));
    // Patch the selected word as it passes the serial line assembler. This
    // removes both the variable 512-bit read mux and byte-write decoder.
    wire [31:0] incoming_word=state==FILL?transfer[31:0]:ram_q;
    reg [31:0] patched_word;
    integer b;
    always @*begin
        patched_word=incoming_word;
        if(cursor==address[5:2])
            for(integer lane=0;lane<4;lane=lane+1)
                if(strobes[lane])patched_word[lane*8+:8]=write_data[lane*8+:8];
    end
    // Same synchronous transfer slot, packed into 15 native DSP registers.
    // All payload remains stable through WRITE_REQ/WAIT and word responses.
    wire transfer_load=state==READ_WAIT&&line_rsp_valid&&!line_error&&line_drained;
    wire transfer_rotate=state==GATHER_CAPTURE||state==FILL;
    wire [511:0] transfer_next=transfer_load?line_rdata:{patched_word,transfer[511:32]};
    wire [539:0] transfer_in={28'd0,transfer_next};wire [539:0] transfer_out;
    assign transfer=transfer_out[511:0];
    for(genvar chunk=0;chunk<15;chunk++)begin:shape_line_storage
        wire [35:0] data_word=transfer_in[chunk*36+:36];wire [47:0] held;
        EFX_DSP48 #(.SIGNED(0),.O_REG(1),.RST_SYNC(1),.N_SEL("C")) storage(
            .A(data_word[35:17]),.B(18'h20000),.C({1'b0,data_word[16:0]}),.CASCIN(48'd0),
            .OP(2'b00),.SHIFT_ENA(1'b0),.CLK(clk),.CE(transfer_load||transfer_rotate),
            .RST(rst),.O(held),.CASCOUT(),.OVFL());
        assign transfer_out[chunk*36+:36]=held[35:0];
    end
    always @*case(index)
        0:selected_tag=tag0;
        1:selected_tag=tag1;
        2:selected_tag=tag2;
        3:selected_tag=tag3;
    endcase
    task store_tag;
        begin
            case(index)
                0:tag0<=address[31:6];
                1:tag1<=address[31:6];
                2:tag2<=address[31:6];
                3:tag3<=address[31:6];
            endcase
            valid[index]<=1;
        end
    endtask
    assign mem_req_ready=!rst&&!quarantined&&state==IDLE&&!invalidate_valid;
    assign invalidate_ready=!rst&&!quarantined&&state==IDLE;
    assign mem_rsp_valid=!rst&&state==RESULT;
    assign busy=state!=IDLE;
    assign line_req_valid=!rst&&(state==READ_REQ||state==WRITE_REQ);
    assign line_write=state==WRITE_REQ;
    assign line_addr={address[31:6],6'd0};
    assign line_wdata=transfer;
    assign line_rsp_ready=!rst&&(state==READ_WAIT||state==WRITE_WAIT);
    task fault;
        begin
            valid<=0;mem_error<=1;mem_drained<=line_drained;mem_rdata<=0;
            if(!line_drained)quarantined<=1;
            state<=RESULT;
        end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;valid<=0;address<=0;write_data<=0;strobes<=0;index<=0;cursor<=0;updated_word<=0;
            mem_rdata<=0;mem_error<=0;mem_drained<=1;quarantined<=0;
        end else case(state)
            IDLE:if(invalidate_valid&&invalidate_ready)valid<=0;
                else if(mem_req_valid&&mem_req_ready)begin
                    address<=mem_addr;write_data<=mem_wdata;strobes<=mem_wstrb;
                    index<=mem_addr[7:6]^mem_addr[23:22];
                    mem_error<=0;mem_drained<=1;mem_rdata<=0;state<=LOOKUP;
                end
            LOOKUP:if(valid[index]&&selected_tag==address[31:6])begin cursor<=0;state<=strobes==0?HIT_READ:GATHER_READ;end
                else state<=READ_REQ;
            HIT_READ:state<=HIT_CAPTURE;
            HIT_CAPTURE:begin mem_rdata<=ram_q;state<=RESULT;end
            GATHER_READ:state<=GATHER_CAPTURE;
            GATHER_CAPTURE:begin
                
                if(cursor==address[5:2])updated_word<=patched_word;
                if(cursor==15)state<=WRITE_REQ;else begin cursor<=cursor+1'b1;state<=GATHER_READ;end
            end
            READ_REQ:if(line_req_ready)state<=READ_WAIT;
            READ_WAIT:if(line_rsp_valid)begin
                if(line_error||!line_drained)fault();
                else begin cursor<=0;state<=FILL;end
            end
            FILL:begin
                // Rotating sixteen words restores original line order. RAM
                // gets original data; a write becomes visible only after ACK.
                
                if(cursor==address[5:2])begin
                    mem_rdata<=incoming_word;updated_word<=patched_word;
                end
                if(cursor==15)begin store_tag();state<=strobes==0?RESULT:WRITE_REQ;end
                else cursor<=cursor+1'b1;
            end
            WRITE_REQ:if(line_req_ready)state<=WRITE_WAIT;
            WRITE_WAIT:if(line_rsp_valid)begin
                if(line_error||!line_drained)fault();
                else begin
                    state<=WRITE_COMMIT;
                end
            end
            WRITE_COMMIT:begin mem_rdata<=updated_word;state<=RESULT;end
            RESULT:if(mem_rsp_ready)state<=quarantined?LOCKED:IDLE;
            LOCKED:begin end
            default:begin valid<=0;mem_error<=1;mem_drained<=0;mem_rdata<=0;quarantined<=1;state<=RESULT;end
        endcase
    end
endmodule

// Synchronous single-port word RAM; no data reset. Read and write phases never
// coincide. q updates at the read edge and is consumed on the following edge.
module shape_cache_words32(
    input wire clk,re,we,input wire [5:0] address,input wire [31:0] data,
    output reg [31:0] q
);
    reg [31:0] memory[0:63];
    always @(posedge clk)begin
        if(we)memory[address]<=data;
        if(re)q<=memory[address];
    end
endmodule
