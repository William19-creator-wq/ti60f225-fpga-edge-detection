// OBS-OP01…05：三typed口，608位原记录，19个32bit CRC提交沿。
module r2_result_crc_observer #(parameter integer W=1920,H=1080) (
    input wire clk,rst,job_start,input wire [141:0] cj,input wire retain_grad,
    input wire class_valid,output logic class_ready,input wire [124:0] class_payload,
    input wire grad_valid,output logic grad_ready,input wire [184:0] grad_payload,
    input wire status_valid,output logic status_ready,input wire [591:0] status_payload,
    input wire terminal_fixture_match,terminal_complete_ok,
    output logic [20:0] observed_class_pairs,observed_grad_pairs,observed_strong,observed_weak,
    output logic observed_class_eof,observed_grad_eof,record_protocol_ok,observer_fault_sticky,
    output logic terminal_done,last_result_valid,last_fixture_match,last_complete_ok,
    output logic [591:0] last_cs,output logic [31:0] last_crc
);
    localparam logic [20:0] P=(W/2)*H;
    localparam logic [9:0] LAST_Q=W/2-1;
    localparam logic [10:0] LAST_ROW=H-1;
    logic active,busy,round_robin,retain_locked;
    logic [141:0] job_context;
    logic [607:0] record_shift;
    logic [31:0] crc;
    logic [4:0] chunk_index;
    logic [1:0] held_type;
    logic [591:0] terminal_cs;
    logic held_fixture_match,held_complete_ok;
    logic [9:0] class_q,grad_q;
    logic [10:0] class_row,grad_row;
    wire class_fire=class_valid&&class_ready,grad_fire=grad_valid&&grad_ready;
    wire status_fire=status_valid&&status_ready;
    wire status_coexists=class_valid||grad_valid;
    logic data_protocol_bad;
    logic [21:0] next_class_pairs,next_grad_pairs,next_strong,next_weak;
    logic signed [11:0] gx,gy;

    // 不从busy的最后chunk透传ready；e19提交，下一沿e20才可capture。
    always_comb begin : select_one_type
        class_ready=0;grad_ready=0;status_ready=0;
        if(!rst&&active&&!busy) begin
            if(status_valid) status_ready=1;
            else if(record_protocol_ok&&!observer_fault_sticky) begin
                if(class_valid&&grad_valid&&retain_locked) begin
                    class_ready=!round_robin;grad_ready=round_robin;
                end else if(class_valid) class_ready=1;
                else if(grad_valid&&retain_locked) grad_ready=1;
            end
        end
    end
    function automatic logic metadata_ok(input logic [120:0] m,input logic [9:0] q,input logic [10:0] row);
        metadata_ok=m[117:22]==job_context[95:0]&&m[10:0]=={q,1'b0}&&m[21:11]==row
            &&m[118]==(q==0&&row==0)&&m[119]==(q==LAST_Q)&&m[120]==(q==LAST_Q&&row==LAST_ROW);
    endfunction
    always_comb begin : check_actual_data
        data_protocol_bad=0;gx=0;gy=0;
        next_class_pairs={1'b0,observed_class_pairs}+ (class_fire ? 22'd1 : 22'd0);
        next_grad_pairs={1'b0,observed_grad_pairs}+ (grad_fire ? 22'd1 : 22'd0);
        next_strong={1'b0,observed_strong};next_weak={1'b0,observed_weak};
        if(class_fire) begin
            if(!metadata_ok(class_payload[124:4],class_q,class_row)||next_class_pairs>{1'b0,P}) data_protocol_bad=1;
            for(integer lane=0;lane<2;lane=lane+1) begin
                case(class_payload[lane*2 +: 2])
                    2'b10:next_strong=next_strong+22'd1;
                    2'b01:next_weak=next_weak+22'd1;
                    2'b11:data_protocol_bad=1;
                    default:begin end
                endcase
            end
        end
        if(grad_fire) begin
            if(!metadata_ok(grad_payload[184:64],grad_q,grad_row)||next_grad_pairs>{1'b0,P}||!retain_locked)
                data_protocol_bad=1;
            for(integer lane=0;lane<2;lane=lane+1) begin
                gx=$signed({grad_payload[lane*32+10],grad_payload[lane*32 +: 11]});
                gy=$signed({grad_payload[lane*32+21],grad_payload[lane*32+11 +: 11]});
                if(grad_payload[lane*32+24 +: 8]!=0||gx < -12'sd1020||gx > 12'sd1020
                    ||gy < -12'sd1020||gy > 12'sd1020) data_protocol_bad=1;
            end
        end
        if(next_strong+next_weak>(next_class_pairs<<1)) data_protocol_bad=1;
    end
    // 参考用独立608逐bit循环；这里只处理当前旧shift最高32位。
    function automatic [31:0] crc_chunk(input logic [31:0] previous_crc,input logic [31:0] word);
        logic [31:0] c;logic feedback;
        begin
            c=previous_crc;
            for(integer bit_index=31;bit_index>=0;bit_index=bit_index-1) begin
                feedback=c[31]^word[bit_index];c={c[30:0],1'b0};
                if(feedback) c=c^32'h04c11db7;
            end
            crc_chunk=c;
        end
    endfunction
    wire [31:0] new_crc=crc_chunk(crc,record_shift[607:576]);
    always_ff @(posedge clk) begin : record_owner
        if(rst) begin
            active<=0;busy<=0;round_robin<=0;retain_locked<=0;job_context<=0;
            record_shift<=0;crc<=32'hffffffff;chunk_index<=0;held_type<=0;
            terminal_cs<=0;held_fixture_match<=0;held_complete_ok<=0;
            class_q<=0;grad_q<=0;class_row<=0;grad_row<=0;
            observed_class_pairs<=0;observed_grad_pairs<=0;observed_strong<=0;observed_weak<=0;
            observed_class_eof<=0;observed_grad_eof<=0;record_protocol_ok<=1;observer_fault_sticky<=0;
            terminal_done<=0;last_result_valid<=0;last_fixture_match<=0;last_complete_ok<=0;last_cs<=0;last_crc<=0;
        end else begin
            terminal_done<=0;
            if(job_start) begin
                active<=1;busy<=0;round_robin<=0;retain_locked<=retain_grad;job_context<=cj;
                crc<=32'hffffffff;chunk_index<=0;held_type<=0;
                class_q<=0;grad_q<=0;class_row<=0;grad_row<=0;
                observed_class_pairs<=0;observed_grad_pairs<=0;observed_strong<=0;observed_weak<=0;
                observed_class_eof<=0;observed_grad_eof<=0;record_protocol_ok<=1;observer_fault_sticky<=0;
                // last_*是上一次整体快照；新job初始化不半写或清除它。
            end else if(busy) begin
                crc<=new_crc;record_shift<={record_shift[575:0],32'd0};
                if(chunk_index==18) begin
                    busy<=0;
                    if(held_type==2) begin
                        last_crc<=new_crc^32'hffffffff;last_cs<=terminal_cs;
                        last_fixture_match<=held_fixture_match;last_complete_ok<=held_complete_ok;
                        last_result_valid<=1;terminal_done<=1;
                    end
                end else chunk_index<=chunk_index+5'd1;
            end else if(status_fire) begin
                record_shift<={14'd0,status_payload,2'd2};held_type<=2;chunk_index<=0;busy<=1;active<=0;
                terminal_cs<=status_payload;
                held_fixture_match<=terminal_fixture_match&&!status_coexists;
                held_complete_ok<=terminal_complete_ok&&!status_coexists;
                if(status_coexists) begin record_protocol_ok<=0;observer_fault_sticky<=1;end
            end else if(class_fire||grad_fire) begin
                busy<=1;chunk_index<=0;
                observed_class_pairs<=next_class_pairs[20:0];observed_grad_pairs<=next_grad_pairs[20:0];
                observed_strong<=next_strong[20:0];observed_weak<=next_weak[20:0];
                if(data_protocol_bad) begin record_protocol_ok<=0;observer_fault_sticky<=1;end
                if(class_fire) begin
                    record_shift<={481'd0,class_payload,2'd0};held_type<=0;round_robin<=1;
                    if(class_payload[124]) observed_class_eof<=1;
                    if(observed_class_pairs<P-1) begin
                        if(class_q==LAST_Q) begin class_q<=0;class_row<=class_row+11'd1;end
                        else class_q<=class_q+10'd1;
                    end
                end else begin
                    record_shift<={421'd0,grad_payload,2'd1};held_type<=1;round_robin<=0;
                    if(grad_payload[184]) observed_grad_eof<=1;
                    if(observed_grad_pairs<P-1) begin
                        if(grad_q==LAST_Q) begin grad_q<=0;grad_row<=grad_row+11'd1;end
                        else grad_q<=grad_q+10'd1;
                    end
                end
            end
        end
    end
    // synthesis translate_off
    initial if(W<6||W>1920||W%2!=0||H<5||H>1080) $fatal(1,"K dimensions");
    always @(posedge clk) if(!rst&&job_start&&busy) $fatal(1,"K new job before old record finished");
    // synthesis translate_on
endmodule
