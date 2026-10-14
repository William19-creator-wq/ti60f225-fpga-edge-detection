// OBS-IF01/04/07/08 / E5：外CJ/source owner，不另存完整CS。
module r2_job_controller #(parameter integer W=1920,H=1080) (
    input wire clk,rst,output wire cj_valid,input wire cj_ready,output wire [141:0] cj,
    input wire source_last_fire,source_input_fire,
    input wire status_valid,input wire [591:0] status_payload,input wire status_fire,
    input wire [20:0] observed_class_pairs,observed_grad_pairs,observed_strong,observed_weak,
    input wire observed_class_eof,observed_grad_eof,record_protocol_ok,observer_fault_sticky,
    input wire terminal_done,last_fixture_match,last_complete_ok,input wire [31:0] last_crc,
    output wire job_start,output wire [1:0] pattern,output wire fault,source_stop,cancel,
    output logic terminal_fixture_match,terminal_complete_ok
);
    localparam logic [2:0] START=0,FEED=1,DRAIN=2,TERMINAL=3,ERROR=4,EXHAUSTED=5;
    localparam logic [20:0] P=(W/2)*H,FAULT_COUNT=(H/2)*(W/2)+2;
    logic [2:0] state;logic [31:0] k;
    logic [141:0] locked_cj;
    logic [20:0] source_accepted_pairs;
    logic source_last_seen,cancel_requested;
    logic [10:0] tl,th;
    wire [141:0] proposed_cj={k[1],k[0],th,tl,11'(H),11'(W),k,k,32'd1};
    wire owned=state==FEED||state==DRAIN;
    wire [21:0] source_pairs_after_fire={1'b0,source_accepted_pairs}
        +(owned&&source_input_fire ? 22'd1 : 22'd0);
    assign cj_valid=!rst&&state==START;
    assign cj=state==START ? proposed_cj : locked_cj;
    assign job_start=cj_valid&&cj_ready;
    assign pattern=k[3:2];assign fault=k[6];
    assign source_stop=!rst&&owned&&status_valid;
    assign cancel=!rst&&owned&&(cancel_requested||observer_fault_sticky);
    always_comb begin : thresholds_from_fixture_index
        case(k[5:4])
            0:begin tl=0;th=64;end
            1:begin tl=64;th=512;end
            2:begin tl=512;th=1530;end
            3:begin tl=1530;th=2047;end
        endcase
    end
    wire [162:0] fs=status_payload[591:429];
    wire [20:0] counts[0:7];
    genvar i;generate for(i=0;i<8;i=i+1) begin : cs_count_fields
        assign counts[i]=status_payload[211+i*21 +: 21];
    end endgenerate
    logic common_ok,full_counts,fault_ok;
    logic [21:0] classified_pixels;
    always_comb begin : terminal_candidates_before_fire
        classified_pixels={1'b0,status_payload[407:387]}+{1'b0,status_payload[428:408]};
        common_ok=owned&&status_payload[141:0]==locked_cj&&status_payload[182:179]==4'd7
            &&fs[98:3]==locked_cj[95:0]&&record_protocol_ok&&!observer_fault_sticky
            &&observed_class_pairs==counts[6]&&observed_grad_pairs==counts[7]
            &&observed_class_eof==status_payload[385]&&observed_grad_eof==status_payload[386]
            &&observed_strong==status_payload[407:387]&&observed_weak==status_payload[428:408]
            &&classified_pixels<=({1'b0,counts[6]}<<1)
            &&(locked_cj[141]||(counts[7]==0&&!status_payload[386]));
        full_counts=1;
        for(integer port_index=0;port_index<7;port_index=port_index+1)
            if(counts[port_index]!=P) full_counts=0;
        if(counts[7]!=(locked_cj[141] ? P : 21'd0)) full_counts=0;
        terminal_complete_ok=common_ok&&state==DRAIN&&source_last_seen&&source_accepted_pairs==P
            &&status_payload[146:142]==0&&status_payload[178:147]==0&&status_payload[210:183]==28'd30
            &&fs[2:0]==0&&fs[119:99]==P&&fs[140:120]==P&&fs[162:141]==0&&full_counts
            &&status_payload[386:379]==(locked_cj[141] ? 8'hff : 8'h7f);
        fault_ok=common_ok&&status_payload[146:142]==5&&status_payload[178:147]==32'd32
            &&status_payload[210:183]=={11'(H/2),11'd2,1'b0,4'd1,1'b1}
            &&fs[2:0]==2&&fs[151:141]==2&&fs[162:152]==H/2
            &&counts[0]==FAULT_COUNT&&source_accepted_pairs==FAULT_COUNT&&fs[119:99]==FAULT_COUNT
            &&counts[1]==fs[140:120]&&counts[1]<counts[0]
            &&counts[6]<=counts[5]&&counts[5]<=counts[4]&&counts[4]<=counts[3]
            &&counts[3]<=counts[2]&&counts[2]<=counts[1]&&counts[7]<=counts[4]
            &&status_payload[386:379]==0;
        terminal_fixture_match=k[6] ? fault_ok : terminal_complete_ok;
    end
    always_ff @(posedge clk) begin : outer_job_lifecycle
        if(rst) begin
            state<=START;k<=0;locked_cj<=0;source_accepted_pairs<=0;source_last_seen<=0;cancel_requested<=0;
        end else begin
            if(owned) begin
                if(source_input_fire) source_accepted_pairs<=source_pairs_after_fire[20:0];
                if(source_last_fire) source_last_seen<=1;
                if(observer_fault_sticky) cancel_requested<=1;
            end
            case(state)
                START:if(job_start) begin
                    locked_cj<=proposed_cj;source_accepted_pairs<=0;source_last_seen<=0;cancel_requested<=0;state<=FEED;
                end
                FEED:begin
                    if(source_last_fire) state<=DRAIN;
                    if(status_fire) state<=TERMINAL;
                end
                DRAIN:if(status_fire) state<=TERMINAL;
                TERMINAL:if(terminal_done) begin
                    if(!last_fixture_match||cancel_requested||observer_fault_sticky) state<=ERROR;
                    else if(k==32'hffffffff) state<=EXHAUSTED;
                    else begin k<=k+32'd1;state<=START;end
                end
                ERROR:begin end
                EXHAUSTED:begin end
                default:state<=ERROR;
            endcase
        end
    end
    // synthesis translate_off
    initial if(W<6||W>1920||W%2!=0||H<5||H>1080) $fatal(1,"J dimensions");
    always @(posedge clk) if(!rst&&owned&&source_input_fire&&source_accepted_pairs>=P)
        $fatal(1,"J source cannot accept more than complete frame");
    // synthesis translate_on
endmodule
