// DH02..07：真实video域active与snapshot；row0和closed由叶模块提供。
module display_route #(
    parameter integer IMAGE_WIDTH=1920,IMAGE_HEIGHT=1080,FRAME_ALIGNMENT=64,
    parameter logic [63:0] INIT_POLICY=1,INIT_SCAN=0,INIT_LAST_SEQUENCE=0
)(
    input logic video_clk,safe_reset_n,
    input logic request_valid,output wire request_ready,input logic [1136:0] request,
    output wire response_valid,input logic response_ready,output wire [1206:0] response,
    input logic response_transport_ready,cancel_level,vsync_tick,scan_de,
    input logic prepared_valid,input logic [63:0] prepared_sequence,prepared_scan,prepared_result,prepared_policy,
    input logic [194:0] prepared_origin,input logic retire_capacity,
    input logic closed_valid,input logic [63:0] closed_sequence,closed_result,closed_policy,input logic [194:0] closed_origin,
    output wire candidate_valid,output wire [941:0] candidate_bundle,output wire [63:0] candidate_sequence,candidate_target_scan,
    output wire cancel_candidate,output logic prepare_selected,
    output logic active_valid,output logic [941:0] active_bundle,output logic active_changed,output logic [63:0] previous_result,
    output logic [63:0] scan_token,policy,frozen_source,
    output logic frozen,committed,snapshot_hold,video_quarantined,output logic [2:0] video_error,
    output wire idle,output logic heartbeat
);
    import display_handoff_pkg::*;
    typedef enum logic [2:0] {IDLE,CHECK,WAIT_OFFER,CANCEL_DRAIN,WAIT_FREEZE,WAIT_RESUME,SEND_RESPONSE,WAIT_ACK} state_t;
    state_t state;
    (* ASYNC_REG="TRUE" *) logic [1:0] reset_pipe,cancel_sync;
    route_request_t incoming,current;
    route_response_t reply_register;
    frame_owner_pkg::reply_t offer,active_view,snapshot_view,commit_view;
    logic [941:0] snapshot_bundle;
    logic [63:0] prepare_sequence,last_sequence;
    logic [194:0] frozen_origin;
    logic [7:0] heartbeat_divider;
    logic [2:0] validation_status;
    wire running=reset_pipe==0;
    wire [63:0] next_scan=scan_token+64'd1;
    localparam logic [31:0] N=32'(IMAGE_WIDTH*IMAGE_HEIGHT),RGB_L=3*N,EDGE_L=(N+7)/8,ANN_L=4224+(N+3)/4;
    assign incoming=request;assign offer=current.bundle;assign active_view=active_bundle;
    assign snapshot_view=snapshot_bundle;assign commit_view=current.bundle;
    assign response=reply_register;assign response_valid=running && state==SEND_RESPONSE;
    assign idle=running && state==IDLE && response_transport_ready && !video_quarantined;
    assign request_ready=idle;
    assign candidate_valid=running && (state==WAIT_OFFER || state==CANCEL_DRAIN);
    assign candidate_bundle=current.bundle;assign candidate_sequence=current.sequence_id;
    assign candidate_target_scan=next_scan;
    assign cancel_candidate=running && (state==CANCEL_DRAIN || (state==WAIT_OFFER && cancel_sync[1]));
    wire preparation_matches=prepared_valid && prepared_sequence==current.sequence_id && prepared_scan==next_scan &&
        prepared_result==offer.result_handle && prepared_origin==offer.origin && prepared_policy==current.target_policy;
    wire closure_matches=closed_valid && closed_sequence==current.sequence_id && closed_result==offer.result_handle &&
        closed_origin==offer.origin && closed_policy==current.target_policy;
    // DA01：帧分配粒度独立于AXI的16B beat；描述仍须逐位相等。
    function automatic logic [31:0] frame_allocation(input logic [31:0] n);
        return FRAME_ALIGNMENT==64 ? ((n+32'd63)&32'hffffffc0) : ((n+32'd15)&32'hfffffff0);
    endfunction
    function automatic logic source_identity(input frame_owner_pkg::reply_t b);
        return b.source_handle!=0 && b.source_slot<6 && b.origin[194:131]==b.source_handle && b.origin[66:3]==b.source_handle && b.origin[2:0]==b.source_slot;
    endfunction
    function automatic logic offer_validity(input frame_owner_pkg::reply_t b);
        logic [95:0] sd,ed,ad;logic [31:0] rb;logic [2:0] m;
        begin
            m=b.body[111:109];sd={32'(b.source_slot)*32'h00800000,RGB_L,frame_allocation(RGB_L)};ed=0;ad=0;
            rb=32'h03000000+32'(b.result_slot)*32'h00800000;
            if(m!=1 && m!=2)ed={rb,EDGE_L,frame_allocation(EDGE_L)};
            if(m==5)ad={rb+32'h00100000,ANN_L,frame_allocation(ANN_L)};
            return b.op==5 && b.status==0 && source_identity(b) && b.result_handle!=0 && b.result_slot<3 &&
                b.cj[63:0]==b.origin[130:67] && b.cj[106:96]==IMAGE_WIDTH && b.cj[117:107]==IMAGE_HEIGHT &&
                b.cj[128:118]<=b.cj[139:129] && m<6 && b.body[108:98]==IMAGE_HEIGHT/2 && b.body[399:112]=={sd,ed,ad};
        end
    endfunction
    always_comb begin
        validation_status=HC_OK;
        if(current.sequence_id==0 || current.sequence_id<=last_sequence)validation_status=HC_IDENTITY;
        else case(current.kind)
            HC_OFFER:begin
                if(current.cause!=0 || !offer_validity(offer))validation_status=HC_FIELD;
                else if(current.target_policy!=policy || offer.policy!=policy || (frozen && (!committed || offer.source_handle!=frozen_source)))validation_status=HC_STATE;
            end
            HC_PREPARE,HC_RESUME:begin
                if(current.cause!=0 || current.bundle!=0)validation_status=HC_FIELD;
                else if(policy==64'hffffffffffffffff)validation_status=HC_EXHAUSTED;
                else if(current.target_policy!=policy+1 || (current.kind==HC_PREPARE && frozen) ||
                    (current.kind==HC_RESUME && (!frozen || !committed || snapshot_hold)))validation_status=HC_STATE;
            end
            HC_COMMIT:begin
                if(!frozen || current.target_policy!=policy)validation_status=HC_STATE;
                else if(current.cause!=prepare_sequence)validation_status=HC_IDENTITY;
                else if(commit_view.op!=9 || commit_view.status!=0 || commit_view.policy!=policy)validation_status=HC_FIELD;
                else if(snapshot_view.source_handle!=0)begin
                    if(commit_view.source_handle!=snapshot_view.source_handle || commit_view.result_handle!=snapshot_view.result_handle ||
                        commit_view.origin!=snapshot_view.origin || commit_view.cj!=snapshot_view.cj || commit_view.body!=snapshot_view.body ||
                        commit_view.source_slot!=snapshot_view.source_slot || commit_view.result_slot!=snapshot_view.result_slot)validation_status=HC_IDENTITY;
                end else if(commit_view.source_handle==0)begin
                    if(commit_view.result_handle!=0 || commit_view.origin!=0 || commit_view.cj!=0 || commit_view.body!=0 || commit_view.source_slot!=7 || commit_view.result_slot!=3)validation_status=HC_FIELD;
                end else if(!source_identity(commit_view) || commit_view.result_handle!=0 || commit_view.cj!=0 || commit_view.body!=0 || commit_view.result_slot!=3)validation_status=HC_FIELD;
                if(validation_status==HC_OK && frozen_source!=0 && (commit_view.source_handle!=frozen_source || commit_view.origin!=frozen_origin))validation_status=HC_IDENTITY;
            end
            default:validation_status=HC_FIELD;
        endcase
    end
    // 固定回复字段在CHECK锁定；状态分支只补真实业务结果，SEND后不再修改。
    always_ff @(posedge video_clk or negedge safe_reset_n)
        if(!safe_reset_n)reset_pipe<=2'b11;else reset_pipe<={reset_pipe[0],1'b0};
    always_ff @(posedge video_clk or negedge safe_reset_n)
        if(!safe_reset_n)cancel_sync<=0;else cancel_sync<={cancel_sync[0],cancel_level};
    always_ff @(posedge video_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin
            state<=IDLE;current<=0;reply_register<=0;active_valid<=0;active_bundle<=0;active_changed<=0;previous_result<=0;
            scan_token<=INIT_SCAN;policy<=INIT_POLICY;last_sequence<=INIT_LAST_SEQUENCE;prepare_sequence<=0;
            frozen_source<=0;frozen_origin<=0;frozen<=0;committed<=0;snapshot_hold<=0;snapshot_bundle<=0;
            prepare_selected<=0;video_quarantined<=0;video_error<=0;heartbeat<=0;heartbeat_divider<=0;
        end else if(running)begin
            heartbeat_divider<=heartbeat_divider+8'd1;if(heartbeat_divider==8'hff)heartbeat<=!heartbeat;
            active_changed<=0;prepare_selected<=0;
            if(vsync_tick && !video_quarantined)begin
                if(scan_de)begin video_quarantined<=1;video_error<=4;end
                else if(scan_token==64'hffffffffffffffff)begin video_quarantined<=1;video_error<=3;end
                else scan_token<=next_scan;
            end
            if(!video_quarantined && !(vsync_tick && (scan_de || scan_token==64'hffffffffffffffff)))case(state)
                IDLE:if(request_valid && request_ready)begin current<=incoming;state<=CHECK;end
                CHECK:begin
                    reply_register<='0;reply_register.kind<=current.kind;reply_register.sequence_id<=current.sequence_id;
                    reply_register.cause<=current.cause;reply_register.policy<=policy;reply_register.has_active<=active_valid;reply_register.snapshot_held<=snapshot_hold;
                    if(current.sequence_id!=0 && current.sequence_id>last_sequence)last_sequence<=current.sequence_id;
                    if(validation_status!=HC_OK)begin reply_register.status<=validation_status;state<=SEND_RESPONSE;end
                    else case(current.kind)
                        HC_OFFER:state<=cancel_sync[1] ? CANCEL_DRAIN : WAIT_OFFER;
                        HC_PREPARE,HC_RESUME:if(cancel_sync[1])begin reply_register.status<=HC_CANCELED;reply_register.candidate_closed<=1;state<=SEND_RESPONSE;end
                            else state<=current.kind==HC_PREPARE ? WAIT_FREEZE : WAIT_RESUME;
                        HC_COMMIT:begin
                            if(cancel_sync[1])reply_register.status<=HC_CANCELED;
                            else begin committed<=1;snapshot_hold<=0;frozen_source<=commit_view.source_handle;frozen_origin<=commit_view.origin;
                                reply_register.bundle<=current.bundle;reply_register.snapshot_held<=0;end
                            reply_register.candidate_closed<=1;state<=SEND_RESPONSE;
                        end
                        default:state<=SEND_RESPONSE;
                    endcase
                end
                WAIT_OFFER:if(cancel_sync[1])state<=CANCEL_DRAIN;
                    else if(vsync_tick && preparation_matches && retire_capacity)begin
                        reply_register.bundle<=current.bundle;reply_register.previous_result<=active_valid ? active_view.result_handle : 64'd0;
                        reply_register.has_active<=1;previous_result<=active_valid ? active_view.result_handle : 64'd0;
                        active_bundle<=current.bundle;active_valid<=1;active_changed<=1;prepare_selected<=1;state<=SEND_RESPONSE;
                    end
                CANCEL_DRAIN:if(closure_matches)begin
                    reply_register.status<=HC_CANCELED;reply_register.bundle<=current.bundle;reply_register.candidate_closed<=1;state<=SEND_RESPONSE;
                end
                WAIT_FREEZE:if(cancel_sync[1])begin reply_register.status<=HC_CANCELED;reply_register.candidate_closed<=1;state<=SEND_RESPONSE;end
                    else if(vsync_tick)begin
                        policy<=current.target_policy;frozen<=1;committed<=0;snapshot_hold<=active_valid;prepare_sequence<=current.sequence_id;
                        snapshot_bundle<=active_valid ? active_bundle : 942'd0;frozen_source<=active_valid ? active_view.source_handle : 64'd0;
                        frozen_origin<=active_valid ? active_view.origin : 195'd0;
                        reply_register.policy<=current.target_policy;reply_register.bundle<=active_valid ? active_bundle : 942'd0;
                        reply_register.has_active<=active_valid;reply_register.snapshot_held<=active_valid;reply_register.candidate_closed<=1;state<=SEND_RESPONSE;
                    end
                WAIT_RESUME:if(cancel_sync[1])begin reply_register.status<=HC_CANCELED;reply_register.candidate_closed<=1;state<=SEND_RESPONSE;end
                    else if(vsync_tick)begin
                        policy<=current.target_policy;frozen<=0;committed<=0;snapshot_hold<=0;frozen_source<=0;frozen_origin<=0;
                        reply_register.policy<=current.target_policy;reply_register.bundle<=active_valid ? active_bundle : 942'd0;
                        reply_register.snapshot_held<=0;reply_register.candidate_closed<=1;state<=SEND_RESPONSE;
                    end
                SEND_RESPONSE:if(response_valid && response_ready)state<=WAIT_ACK;
                WAIT_ACK:if(response_transport_ready)state<=IDLE;
                default:state<=IDLE;
            endcase
        end
    end
    // synthesis translate_off
    initial if(FRAME_ALIGNMENT!=16 && FRAME_ALIGNMENT!=64)$fatal(1,"DA route alignment");
    // synthesis translate_on
endmodule
