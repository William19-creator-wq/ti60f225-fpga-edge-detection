// FR01..03：两个完整64B槽由RAM保存；连续64位预取/128位拼接保持跨line六byte和held FP。
module rgb_frame_reader #(parameter integer WIDTH=1920,HEIGHT=1080)(
    input logic clk,rst,
    input logic job_valid,output wire job_ready,input logic [31:0] job_base,input logic [63:0] job_handle,
    output wire job_rsp_valid,input logic job_rsp_ready,output logic job_rsp_error,
    output wire out_valid,input logic out_ready,output logic [73:0] out_fp,output wire [63:0] out_id,
    input logic cancel_valid,input logic [63:0] cancel_id,
    output wire done_valid,input logic done_ready,output wire [63:0] done_id,
    output logic [1:0] outcome,output logic [7:0] reason,
    output logic [20:0] prepared_pairs,output_pairs,output logic [21:0] read_lines,discarded_lines,
    output wire source_stop,quarantined,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output logic [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained
);
    localparam integer P=WIDTH*HEIGHT/2,L=WIDTH*HEIGHT*3,A=((L+63)/64)*64,LINES=A/64;
    typedef enum logic [2:0] {IDLE,CFG_REPLY,RUN,ABORT,DONE,QUARANTINE} state_t;
    typedef enum logic [1:0] {RPC_IDLE,REQUEST,WAIT_RESPONSE} rpc_state_t;
    typedef enum logic [1:0] {EMPTY,RESERVED,VALID} slot_state_t;
    state_t state;rpc_state_t rpc_state;slot_state_t slot_state[0:1];
    logic [31:0] base;logic [63:0] handle;
    logic head,tail,reserved_slot,fp_valid;
    logic [2:0] load_word,read_word;
    logic word_pending,pending_slot,pending_last;
    logic [127:0] reservoir,next_reservoir;
    logic [4:0] bytes;
    logic [5:0] next_bytes;
    logic [10:0] next_x,next_y;
    logic [21:0] next_line;
    wire matching_cancel=cancel_valid && cancel_id==handle && (state==RUN || (state==CFG_REPLY && !job_rsp_error));
    wire response_fire=line_rsp_valid && line_rsp_ready;
    wire response_error=response_fire && (line_error || !line_drained);
    wire stop_new=matching_cancel || response_error || state==ABORT || state==QUARANTINE;
    wire [32:0] grant_end={1'b0,job_base}+33'(A);
    wire [47:0] stream=reservoir[47:0];
    wire [47:0] rgb={stream[31:24],stream[39:32],stream[47:40],stream[7:0],stream[15:8],stream[23:16]};
    wire build_fp=state==RUN && !stop_new && (!fp_valid || out_ready) && prepared_pairs<21'(P) && bytes>=6;
    wire load_enable=!rst&&rpc_state==WAIT_RESPONSE&&line_rsp_valid&&line_drained&&!line_error&&!stop_new;
    wire read_enable=!rst&&state==RUN&&!stop_new&&prepared_pairs<21'(P)&&
        next_bytes<=8&&slot_state[head]==VALID;
    wire [79:0] ram_input={16'd0,line_rdata[load_word*64+:64]};
    wire [79:0] ram_output;
    for(genvar stripe=0;stripe<4;stripe++)begin:rgb_line_slots
        EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_UNKNOWN")) storage(
            .WCLK(clk),.WE({2{load_enable}}),.WCLKE(1'b1),.WADDREN(1'b1),
            .WDATA(ram_input[stripe*20+:20]),.WADDR({5'd0,reserved_slot,load_word}),
            .RCLK(clk),.RE(read_enable),.RST(1'b0),.RADDREN(1'b1),
            .RDATA(ram_output[stripe*20+:20]),.RADDR({5'd0,head,read_word}));
    end
    always_comb begin
        next_reservoir=build_fp?(reservoir>>48):reservoir;
        next_bytes={1'b0,bytes}-(build_fp?6'd6:6'd0);
        if(word_pending&&!stop_new)begin
            next_reservoir=next_reservoir|({64'd0,ram_output[63:0]}<<{next_bytes,3'd0});
            next_bytes=next_bytes+6'd8;
        end
    end
    wire fp_fire=out_valid && out_ready;
    assign job_ready=!rst && state==IDLE;
    assign job_rsp_valid=!rst && state==CFG_REPLY;
    assign out_valid=!rst && fp_valid;
    assign out_id=handle;assign done_id=handle;
    assign done_valid=!rst && state==DONE;
    assign source_stop=matching_cancel || state==ABORT || state==DONE || state==QUARANTINE || (state==RUN && prepared_pairs==21'(P));
    assign quarantined=state==QUARANTINE;
    assign line_req_valid=!rst && rpc_state==REQUEST;
    // 原服务保持全部512位，8个64位字真正安装后才消费回复；取消/错误立即结清。
    assign line_rsp_ready=!rst && rpc_state==WAIT_RESPONSE && state!=QUARANTINE &&
        (load_word==7||matching_cancel||state==ABORT||line_error||!line_drained);
    assign line_write=1'b0;assign line_wdata=512'd0;
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;rpc_state<=RPC_IDLE;slot_state[0]<=EMPTY;slot_state[1]<=EMPTY;
            base<=0;handle<=0;head<=0;tail<=0;reserved_slot<=0;fp_valid<=0;
            load_word<=0;read_word<=0;word_pending<=0;pending_slot<=0;pending_last<=0;reservoir<=0;bytes<=0;
            next_x<=0;next_y<=0;next_line<=0;line_addr<=0;out_fp<=0;job_rsp_error<=0;
            outcome<=0;reason<=0;prepared_pairs<=0;output_pairs<=0;read_lines<=0;discarded_lines<=0;
        end else begin
            word_pending<=read_enable;
            if(load_enable&&load_word!=7)load_word<=load_word+3'd1;
            if(read_enable)begin
                pending_slot<=head;pending_last<=read_word==7;
                if(read_word==7)begin read_word<=0;head<=!head;end
                else read_word<=read_word+3'd1;
            end
            if(word_pending&&pending_last&&!stop_new)slot_state[pending_slot]<=EMPTY;
            if(state==RUN)begin reservoir<=next_reservoir;bytes<=next_bytes[4:0];end
            if(fp_fire)begin fp_valid<=0;output_pairs<=output_pairs+21'd1;end
            if(state==RUN && !stop_new && rpc_state==RPC_IDLE && slot_state[tail]==EMPTY && next_line<22'(LINES) && prepared_pairs<21'(P))begin
                reserved_slot<=tail;slot_state[tail]<=RESERVED;tail<=!tail;
                load_word<=0;
                line_addr<=base+({10'd0,next_line}<<6);next_line<=next_line+22'd1;rpc_state<=REQUEST;
            end
            if(rpc_state==REQUEST && line_req_ready)rpc_state<=WAIT_RESPONSE;
            if(response_fire)begin
                if(!line_drained)begin state<=QUARANTINE;outcome<=1;reason<=16;end
                else begin
                    rpc_state<=RPC_IDLE;
                    if(line_error)begin slot_state[reserved_slot]<=EMPTY;state<=ABORT;outcome<=1;reason<=16;end
                    else if(stop_new)begin slot_state[reserved_slot]<=EMPTY;discarded_lines<=discarded_lines+22'd1;end
                    else begin
                        slot_state[reserved_slot]<=VALID;read_lines<=read_lines+22'd1;
                    end
                end
            end
            if(build_fp)begin
                out_fp<={1'b0,prepared_pairs==21'(P-1),next_x==11'(WIDTH-2),prepared_pairs==0,next_y,next_x,rgb};
                fp_valid<=1;prepared_pairs<=prepared_pairs+21'd1;
                if(next_x==11'(WIDTH-2))begin next_x<=0;next_y<=next_y+11'd1;end else next_x<=next_x+11'd2;
            end
            case(state)
                IDLE:if(job_valid && job_ready)begin
                    base<=job_base;handle<=job_handle;job_rsp_error<=job_base[5:0]!=0 || grant_end>33'h100000000;
                    outcome<=cancel_valid && cancel_id==job_handle ? 2 : 0;reason<=cancel_valid && cancel_id==job_handle ? 128 : 0;
                    head<=0;tail<=0;load_word<=0;read_word<=0;word_pending<=0;
                    reservoir<=0;bytes<=0;next_x<=0;next_y<=0;next_line<=0;
                    prepared_pairs<=0;output_pairs<=0;read_lines<=0;discarded_lines<=0;state<=CFG_REPLY;
                end
                CFG_REPLY:if(job_rsp_ready)state<=job_rsp_error ? IDLE : (outcome==2 || matching_cancel ? ABORT : RUN);
                RUN:if(prepared_pairs==21'(P) && output_pairs==21'(P) && !fp_valid && !word_pending && rpc_state==RPC_IDLE && !stop_new)begin
                    state<=DONE;slot_state[0]<=EMPTY;slot_state[1]<=EMPTY;
                    if(read_lines!=22'(LINES))begin outcome<=1;reason<=17;end
                end
                ABORT:begin
                    for(integer s=0;s<2;s++)if(slot_state[s]==VALID)slot_state[s]<=EMPTY;
                    if(rpc_state==RPC_IDLE && !fp_valid && !word_pending)begin state<=DONE;slot_state[0]<=EMPTY;slot_state[1]<=EMPTY;end
                end
                DONE:if(done_ready)state<=IDLE;
                default:begin end
            endcase
            if(matching_cancel)begin
                if(state!=CFG_REPLY)state<=ABORT;
                if(outcome==0)begin outcome<=2;reason<=128;end
            end
            if(response_error)begin state<=line_drained ? ABORT : QUARANTINE;outcome<=1;reason<=16;end
        end
    end
    // synthesis translate_off
    initial if(WIDTH<4 || WIDTH>1920 || WIDTH%2 || HEIGHT<2 || HEIGHT>1080)$fatal(1,"RGB reader geometry");
    always @(posedge clk)if(!rst)begin
        if(prepared_pairs<output_pairs || prepared_pairs-output_pairs>1)$fatal(1,"RGB reader FP reservation ledger");
        if(rpc_state!=RPC_IDLE && slot_state[reserved_slot]!=RESERVED)$fatal(1,"RGB reader response capacity missing");
        if(done_valid && (fp_valid || word_pending || rpc_state!=RPC_IDLE || slot_state[0]!=EMPTY || slot_state[1]!=EMPTY))$fatal(1,"RGB reader done with borrow");
        if(next_line>22'(LINES) || prepared_pairs>21'(P))$fatal(1,"RGB reader overrun");
    end
    // synthesis translate_on
endmodule
