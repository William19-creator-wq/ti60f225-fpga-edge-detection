// SC21..27：固定视频时隙，三native银行；真正545通知之后才能重新分配。
module display_scan_video #(
    parameter integer IMAGE_WIDTH=1920,IMAGE_HEIGHT=1080
)(
    input logic video_clk,safe_reset_n,vsync_tick,
    input logic scan_de,input logic [10:0] scan_x_even,scan_y,
    input logic candidate_valid,input logic [941:0] candidate_bundle,
    input logic [63:0] candidate_sequence,candidate_target_scan,input logic cancel_candidate,
    input logic active_valid,input logic [941:0] active_bundle,input logic active_changed,
    input logic [63:0] scan_token,
    output logic prepared_valid,output logic [63:0] prepared_sequence,prepared_scan,prepared_result,prepared_policy,
    output logic [194:0] prepared_origin,
    output wire candidate_closed_valid,output wire [386:0] candidate_closed_ref,
    output wire close_capacity,
    output wire request_valid,input logic request_ready,output wire [480:0] request,
    output wire request_cancel,input logic receipt_valid,output logic receipt_ready,input logic [614:0] receipt,
    input logic [2:0] row_valid,input logic [2:0][542:0] row_ticket,
    output logic [2:0] reserve_valid,input logic [2:0] reserve_ready,
    output logic [2:0][542:0] reserve_ticket,output logic [2:0] reserve_discard,
    input logic [2:0] stream_prepared,stream_live,stream_quarantined,owned,
    input logic [2:0][386:0] stream_ref,
    output logic [2:0] display_start,display_de,discard,
    output logic [478:0] display_demand,
    input logic [2:0][53:0] stream_pair,input logic [2:0] stream_pixels_valid,stream_identity_good,
    output logic [53:0] pixels,output logic pixels_valid,identity_good,
    output logic [111:0] render,
    input logic [2:0] returned_valid,output logic [2:0] returned_ready,
    input logic [2:0][544:0] returned,
    output logic fence_valid,input logic fence_ready,output logic [387:0] fence_request,
    input logic fence_done_valid,output wire fence_done_ready,input logic [387:0] fence_done,
    input logic fault,
    output logic quarantined,output wire [63:0] active_sequence,
    output wire [2:0] banks_free,output logic [31:0] underrun_lines
);
    import display_fetch_pkg::*;
    import display_row_pkg::*;
    typedef enum logic [1:0] {FREE,REQUESTED,BORROWED,BANK_Q} bank_state_t;
    bank_state_t bank_state[0:2];
    (* ASYNC_REG="TRUE" *) logic [1:0] reset_pipe;
    wire running=reset_pipe==0;
    request_t current_request;
    receipt_t receipt_view;
    frame_owner_pkg::reply_t active_view,candidate_view;
    frame_ref_t current_active_ref,effective_ref,candidate_ref;
    logic request_live,request_pending;
    logic [10:0] normal_cursor,row_floor;
    logic repeat_sent;
    logic [63:0] candidate_last_sequence,candidate_last_scan;
    logic [1:0] line_bank;
    logic [1:0] selected_bank;
    demand_t wanted;
    logic [1:0] old_valid;
    frame_ref_t old_ref[0:1];
    logic [1:0] old_guard[0:1];
    logic fence_inflight;
    logic [387:0] current_fence;
    logic canceled_closed;
    frame_ref_t canceled_ref;
    logic [2:0] bank_allowed,bank_not_borrowed;
    logic current_allowed,current_success,current_safe_failure;
    logic create_request;
    request_t next_request;
    logic [1:0] create_kind;
    logic protocol_fault;
    logic [1:0] matching_rows;
    assign active_view=active_bundle;
    assign candidate_view=candidate_bundle;
    assign receipt_view=receipt;
    assign effective_ref=active_changed ?
        frame_ref_t'({candidate_sequence,active_view.result_handle,active_view.policy,active_view.origin}) : current_active_ref;
    assign candidate_ref={candidate_sequence,candidate_view.result_handle,candidate_view.policy,candidate_view.origin};
    assign active_sequence=effective_ref.sequence_id;
    assign close_capacity=!(&old_valid) && !quarantined;
    assign request=current_request;
    assign request_valid=running && request_pending; // 已提出的承诺不因取消/Q撤回。
    assign request_cancel=request_live && (!current_allowed || quarantined || fault);
    assign candidate_closed_valid=running && canceled_closed && candidate_valid && cancel_candidate &&
        canceled_ref==candidate_ref && !quarantined;
    assign candidate_closed_ref=canceled_ref;
    assign fence_done_ready=running && fence_inflight && !quarantined;
    for(genvar b=0;b<3;b++)begin: free_flags
        assign banks_free[b]=bank_state[b]==FREE;
    end
    function automatic demand_t make_demand(
        input frame_ref_t f,input logic [63:0] scan,input logic [2:0] mode,input logic [10:0] y
    );
        demand_t d;
        begin
            d='0;d.sequence_id=f.sequence_id;d.scan=scan;d.result_handle=f.result_handle;
            d.policy=f.policy;d.origin=f.origin;d.target_y=y;d.source_y=y;d.mode=mode;
            case(mode)
                0:begin d.required_mask=y<IMAGE_HEIGHT/2 ? 1 : 2;d.source_y=11'(2*(y%(IMAGE_HEIGHT/2)));end
                1,2:d.required_mask=1;
                3:d.required_mask=2;
                4:d.required_mask=3;
                5:d.required_mask=7;
                default:d.required_mask=0;
            endcase
            return d;
        end
    endfunction
    // 所有动态条件显式作为参数，避免常量参数函数隐藏帧/配置读集。
    function automatic logic allowed_demand(
        input demand_t d,input logic av,input frame_ref_t af,input logic [63:0] current_scan,
        input logic [2:0] am,input logic [10:0] floor_y,input logic selected_de,
        input logic [10:0] current_y,
        input logic cv,input frame_ref_t cf,input logic [63:0] cs,input logic [2:0] cm
    );
        logic a,c;
        begin
            a=av && demand_ref(d)==af &&
                ((d.scan==current_scan && (d.target_y>=floor_y || (selected_de && d.target_y==current_y))) ||
                 (current_scan!=64'hffffffffffffffff && d.scan==current_scan+64'd1 && d.target_y==0)) &&
                d==make_demand(af,d.scan,am,d.target_y);
            c=cv && demand_ref(d)==cf && d.scan==cs && d.target_y==0 && d==make_demand(cf,cs,cm,0);
            return a||c;
        end
    endfunction
    function automatic logic locally_quiet(
        input frame_ref_t f,input logic req_live,input request_t req,
        input logic [2:0] free_mask,input logic [2:0][542:0] tickets,
        input logic [2:0] live,input logic [2:0][386:0] refs
    );
        logic quiet;
        begin
            quiet=!(req_live && demand_ref(req.demand)==f);
            for(integer b=0;b<3;b++)begin
                if(!free_mask[b] && ticket_ref(row_ticket_t'(tickets[b]))==f)quiet=0;
                if(live[b] && refs[b]==f)quiet=0;
            end
            return quiet;
        end
    endfunction
    always_comb begin
        wanted=make_demand(effective_ref,scan_token,active_view.body[111:109],scan_y);
        selected_bank=line_bank;matching_rows=0;
        if(scan_de && scan_x_even==0)begin
            selected_bank=3;
            for(integer b=0;b<3;b++)begin
                if(active_valid && bank_state[b]==BORROWED && row_ticket[b][478:0]==wanted)begin
                    selected_bank=2'(b);matching_rows=matching_rows+2'd1;
                end
            end
        end
        display_start=0;display_de=0;display_demand=wanted;
        pixels=0;pixels_valid=0;identity_good=1;
        render=active_valid ? active_view.body[111:0] : {3'd1,11'(IMAGE_HEIGHT/2),96'd0,2'd0};
        if(scan_de && selected_bank<3)begin
            display_de[selected_bank]=1;
            display_start[selected_bank]=scan_x_even==0;
            pixels=stream_pair[selected_bank];pixels_valid=stream_pixels_valid[selected_bank];
            identity_good=stream_identity_good[selected_bank];
        end
        bank_allowed=0;bank_not_borrowed=0;
        for(integer b=0;b<3;b++)begin
            bank_not_borrowed[b]=bank_state[b]!=BORROWED;
            bank_allowed[b]=allowed_demand(demand_t'(row_ticket[b][478:0]),active_valid,effective_ref,
                scan_token,active_view.body[111:109],row_floor,display_de[b],scan_y,
                candidate_valid && !cancel_candidate,candidate_ref,candidate_target_scan,candidate_view.body[111:109]);
        end
        current_allowed=allowed_demand(current_request.demand,active_valid,effective_ref,
            scan_token,active_view.body[111:109],row_floor,
            1'b0,scan_y,
            candidate_valid && !cancel_candidate,candidate_ref,candidate_target_scan,candidate_view.body[111:109]);
        reserve_valid=0;reserve_ticket=0;reserve_discard=0;receipt_ready=0;
        current_success=receipt_view.status==0 && receipt_view.outcome==0 && receipt_view.row_granted &&
            receipt_view.drained && !receipt_view.row_returned && receipt_view.prepared==IMAGE_WIDTH/2 && receipt_view.delivered==IMAGE_WIDTH/2;
        current_safe_failure=receipt_view.status!=FC_BUSY && receipt_view.outcome!=3 && receipt_view.drained &&
            (!receipt_view.row_granted || receipt_view.row_returned);
        if(running && receipt_valid && !quarantined && request_live && receipt_view.bank<3)begin
            if(current_success)begin
                reserve_valid[receipt_view.bank]=1;reserve_ticket[receipt_view.bank]=receipt_view.ticket;
                reserve_discard[receipt_view.bank]=!current_allowed || fault;
                receipt_ready=reserve_ready[receipt_view.bank];
            end else receipt_ready=current_safe_failure;
        end
        discard=0;returned_ready=0;protocol_fault=fault || (|stream_quarantined) || matching_rows>1;
        for(integer b=0;b<3;b++)begin
            row_return_t rr;
            rr=returned[b];
            discard[b]=bank_state[b]==BORROWED && (!bank_allowed[b] || quarantined || fault);
            if(returned_valid[b])begin
                if(bank_state[b]!=BORROWED || rr.ticket!=row_ticket[b] || rr.kind>1)protocol_fault=1;
                else returned_ready[b]=running && !stream_live[b] && !owned[b] && !quarantined;
            end
        end
        if(receipt_valid && request_live &&
           (receipt_view.bank!=current_request.bank || receipt_view.ticket[478:0]!=current_request.demand ||
            receipt_view.bank>=3 || (!current_success && !current_safe_failure)))protocol_fault=1;
        prepared_valid=0;prepared_sequence=candidate_sequence;prepared_scan=candidate_target_scan;
        prepared_result=candidate_view.result_handle;prepared_policy=candidate_view.policy;prepared_origin=candidate_view.origin;
        for(integer b=0;b<3;b++)
            if(candidate_valid && !cancel_candidate && !quarantined && bank_state[b]==BORROWED && stream_prepared[b] &&
               row_ticket[b][478:0]==make_demand(candidate_ref,candidate_target_scan,candidate_view.body[111:109],0))prepared_valid=1;
        create_request=0;next_request='0;create_kind=0;
        if(running && !quarantined && !protocol_fault && !request_live && !vsync_tick && !active_changed)begin
            // 低编号FREE优先。只在创建沿占槽，不能同沿使用刚收到的归还。
            for(integer b=2;b>=0;b--)if(bank_state[b]==FREE)begin
                if(active_valid && normal_cursor<IMAGE_HEIGHT)begin
                    create_request=1;create_kind=0;
                    next_request={2'(b),make_demand(effective_ref,scan_token,active_view.body[111:109],normal_cursor)};
                end else if(active_valid && !repeat_sent && scan_token!=64'hffffffffffffffff)begin
                    create_request=1;create_kind=1;
                    next_request={2'(b),make_demand(effective_ref,scan_token+64'd1,active_view.body[111:109],0)};
                end else if(candidate_valid && !cancel_candidate &&
                   (candidate_last_sequence!=candidate_sequence || candidate_last_scan!=candidate_target_scan))begin
                    create_request=1;create_kind=2;
                    next_request={2'(b),make_demand(candidate_ref,candidate_target_scan,candidate_view.body[111:109],0)};
                end
            end
        end
        fence_valid=0;fence_request=0;
        if(running && !quarantined && !protocol_fault && !fence_inflight)begin
            for(integer n=1;n>=0;n--)
                if(old_valid[n] && old_guard[n]==0 && locally_quiet(old_ref[n],request_live,current_request,
                   bank_not_borrowed,row_ticket,stream_live,stream_ref))begin fence_valid=1;fence_request={1'b1,old_ref[n]};end
            if(candidate_valid && cancel_candidate && !(canceled_closed && canceled_ref==candidate_ref) &&
               locally_quiet(candidate_ref,request_live,current_request,bank_not_borrowed,row_ticket,stream_live,stream_ref))begin
                fence_valid=1;fence_request={1'b0,candidate_ref};
            end
        end
    end
    always_ff @(posedge video_clk or negedge safe_reset_n)
        if(!safe_reset_n)reset_pipe<=2'b11;else reset_pipe<={reset_pipe[0],1'b0};
    always_ff @(posedge video_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin
            for(integer b=0;b<3;b++)bank_state[b]<=FREE;
            current_request<=0;request_live<=0;request_pending<=0;current_active_ref<=0;
            normal_cursor<=1;row_floor<=0;repeat_sent<=0;candidate_last_sequence<=0;candidate_last_scan<=0;
            line_bank<=3;old_valid<=0;old_ref[0]<=0;old_ref[1]<=0;old_guard[0]<=0;old_guard[1]<=0;
            fence_inflight<=0;current_fence<=0;canceled_closed<=0;canceled_ref<=0;quarantined<=0;underrun_lines<=0;
        end else if(running)begin
            for(integer n=0;n<2;n++)old_guard[n]<={1'b0,old_guard[n][1]};
            if(protocol_fault)quarantined<=1;
            if(request_valid && request_ready)request_pending<=0;
            if(!candidate_valid || candidate_ref!=canceled_ref)canceled_closed<=0;
            if(active_changed && !quarantined)begin
                if(current_active_ref.sequence_id!=0)begin
                    if(!old_valid[0])begin old_valid[0]<=1;old_ref[0]<=current_active_ref;old_guard[0]<=3;end
                    else if(!old_valid[1])begin old_valid[1]<=1;old_ref[1]<=current_active_ref;old_guard[1]<=3;end
                    else quarantined<=1;
                end
                current_active_ref<=effective_ref;
                normal_cursor<=1;repeat_sent<=0;
            end
            if(vsync_tick)begin normal_cursor<=1;row_floor<=0;repeat_sent<=0;end
            if(scan_de && scan_x_even==0)begin
                line_bank<=selected_bank;row_floor<=scan_y+11'd1;
                if(active_valid && (selected_bank>=3 || !stream_prepared[selected_bank]))
                    if(underrun_lines!=32'hffffffff)underrun_lines<=underrun_lines+32'd1;
            end
            for(integer b=0;b<3;b++)if(returned_valid[b] && returned_ready[b])bank_state[b]<=FREE;
            if(receipt_valid && receipt_ready)begin
                request_live<=0;
                bank_state[receipt_view.bank]<=current_success ? BORROWED : FREE;
            end
            if(create_request)begin
                current_request<=next_request;request_live<=1;request_pending<=1;
                bank_state[next_request.bank]<=REQUESTED;
                case(create_kind)
                    0:normal_cursor<=normal_cursor+11'd1;
                    1:repeat_sent<=1;
                    2:begin candidate_last_sequence<=candidate_sequence;candidate_last_scan<=candidate_target_scan;end
                    default:begin end
                endcase
            end
            if(fence_valid && fence_ready)begin fence_inflight<=1;current_fence<=fence_request;end
            if(fence_done_valid && fence_done_ready)begin
                if(fence_done!=current_fence)quarantined<=1;
                else begin
                    fence_inflight<=0;
                    if(current_fence[387])begin
                        for(integer n=0;n<2;n++)if(old_valid[n] && old_ref[n]==current_fence[386:0])old_valid[n]<=0;
                    end else begin canceled_closed<=1;canceled_ref<=current_fence[386:0];end
                end
            end
        end
    end
    // synthesis translate_off
    initial if(IMAGE_WIDTH<4 || IMAGE_WIDTH>1920 || IMAGE_WIDTH%2 || IMAGE_HEIGHT<2 || IMAGE_HEIGHT>1080 || IMAGE_HEIGHT%2)
        $fatal(1,"Scan geometry");
    always @(posedge video_clk)if(running)begin
        if(create_request && bank_state[next_request.bank]!=FREE)$fatal(1,"Reused unreturned bank");
        if(fence_valid && request_live && demand_ref(current_request.demand)==fence_request[386:0])
            $fatal(1,"Scope fence before request closed");
    end
    // synthesis translate_on
endmodule
