// RA01..08：唯一帧账本直接授权只读；闭合证据仍来自实际叶客户端。
module frame_owner_read_authority #(
    parameter integer IMAGE_WIDTH=1920,IMAGE_HEIGHT=1080,FRAME_ALIGNMENT=64,
    parameter logic [63:0] INIT_SOURCE_HANDLE=64'd1,INIT_RESULT_HANDLE=64'd1,INIT_POLICY=64'd1,
    parameter logic [63:0] INIT_LAST_OFFER_SEQUENCE=64'd0
)(
    input logic core_clk,safe_reset_n,
    input logic cmd_valid,output wire cmd_ready,input logic [940:0] command,
    input logic [63:0] offer_sequence,
    input logic lookup_valid,output wire lookup_ready,input logic [478:0] lookup_demand,
    output logic lookup_permitted,output logic [941:0] lookup_bundle,
    output logic reply_valid,input logic reply_ready,output wire [941:0] reply,
    output wire [17:0] source_states,output wire [8:0] result_states,
    output logic [63:0] latest_handle,freeze_handle,policy,
    output logic frozen,quarantined,output wire source_exhausted,result_exhausted
);
    import frame_owner_pkg::*;
    import display_fetch_pkg::*;
    localparam logic [10:0] HALF_HEIGHT=11'(IMAGE_HEIGHT/2);
    logic [63:0] ro_sequence[0:2],next_ro_sequence[0:2];
    logic [63:0] last_offer_sequence,n_last_offer_sequence;
    demand_t read_demand;
    assign read_demand=lookup_demand;
    // RA06：命令与回执优先；权限/描述仅在实际lookup fire沿有效。
    localparam logic [31:0] PIXELS=32'(IMAGE_WIDTH*IMAGE_HEIGHT),RGB_BYTES=PIXELS*3,
        EDGE_BYTES=(PIXELS+7)/8,ANN_BYTES=32'd4224+(PIXELS+3)/4;
    source_t sources[0:5],next_sources[0:5];result_t results[0:2],next_results[0:2];
    logic [63:0] next_source_handle,next_result_handle,n_source_handle,n_result_handle;
    logic source_limit,result_limit,n_source_limit,n_result_limit;
    logic [63:0] n_latest,n_freeze,n_policy;logic n_frozen,n_quarantine;
    reply_t reply_register,answer;command_t request;
    (* ASYNC_REG="TRUE" *) logic [1:0] reset_pipe;
    integer source_index,result_index,free_source,free_result,selected_source;
    logic source_match,result_match,frame_collision,offered_exists,retained;
    logic [7:0] allowed_flags;logic [95:0] src_desc,edge_desc,ann_desc;
    logic [31:0] src_base,res_base;logic [2:0] mode;
    wire running=reset_pipe==0;
    assign lookup_ready=running && !cmd_valid && !reply_valid;
    assign request=command;assign reply=reply_register;
    assign cmd_ready=running && !reply_valid;
    assign source_exhausted=source_limit;assign result_exhausted=result_limit;
    for(genvar s=0;s<6;s++)assign source_states[s*3+:3]=sources[s].state;
    for(genvar r=0;r<3;r++)assign result_states[r*3+:3]=results[r].state;
    function automatic logic [31:0] frame_allocation(input logic [31:0] bytes);
        // PB04：物理写回为64B时分配A64；logical长度和槽身份不变。
        return FRAME_ALIGNMENT==64 ? ((bytes+32'd63)&32'hffffffc0) : ((bytes+32'd15)&32'hfffffff0);
    endfunction

    // 逻辑身份始终完整；内部借用slot保留源代次，避免重复保存同一元数据。
    function automatic logic [194:0] source_origin(input source_t value,input logic [2:0] slot);
        return {value.handle,value.frame_epoch,value.handle,slot};
    endfunction
    function automatic logic [399:0] result_body(input result_t value,input logic [1:0] slot);
        logic [31:0] sb,rb;logic [95:0] sd,ed,ad;logic [2:0] m;
        begin
            sb=32'(value.source_slot)*32'h00800000;rb=32'h03000000+32'(slot)*32'h00800000;m=value.render_snapshot[111:109];
            sd={sb,RGB_BYTES,frame_allocation(RGB_BYTES)};ed=0;ad=0;
            if(m!=1 && m!=2)ed={rb,EDGE_BYTES,frame_allocation(EDGE_BYTES)};
            if(m==5)ad={rb+32'h00100000,ANN_BYTES,frame_allocation(ANN_BYTES)};
            return {sd,ed,ad,value.render_snapshot};
        end
    endfunction

    always_comb begin
        for(integer s=0;s<6;s++)next_sources[s]=sources[s];
        for(integer r=0;r<3;r++)begin next_results[r]=results[r];next_ro_sequence[r]=ro_sequence[r];end
        n_last_offer_sequence=last_offer_sequence;
        n_source_handle=next_source_handle;n_result_handle=next_result_handle;
        n_source_limit=source_limit;n_result_limit=result_limit;
        n_latest=latest_handle;n_freeze=freeze_handle;n_policy=policy;n_frozen=frozen;n_quarantine=quarantined;
        answer='0;answer.op=request.op;answer.status=OK;answer.policy=policy;answer.source_slot=7;answer.result_slot=3;
        source_index=-1;result_index=-1;free_source=-1;free_result=-1;selected_source=-1;
        frame_collision=0;offered_exists=0;source_match=0;result_match=0;retained=0;
        allowed_flags=0;src_desc=0;edge_desc=0;ann_desc=0;src_base=0;res_base=0;mode=request.body[111:109];
        for(integer s=0;s<6;s++)begin
            if(sources[s].state!=S_FREE && sources[s].handle==request.source_handle)source_index=s;
            if(sources[s].state==S_FREE && free_source<0)free_source=s;
            if(sources[s].state!=S_FREE && sources[s].frame_epoch==request.origin[130:67])frame_collision=1;
        end
        for(integer r=0;r<3;r++)begin
            if(results[r].state!=R_FREE && results[r].handle==request.result_handle)result_index=r;
            if(results[r].state==R_FREE && free_result<0)free_result=r;
            if(results[r].state==R_OFFERED)offered_exists=1;
        end
        if(source_index>=0)source_match=source_origin(sources[source_index],3'(source_index))==request.origin;
        if(result_index>=0)begin
            result_match=source_match && results[result_index].source_slot==source_index &&
                results[result_index].config_snapshot==request.cj[141:64] && sources[source_index].frame_epoch==request.cj[63:0] && results[result_index].policy==request.policy;
        end
        case(request.op)
            SOURCE_END,RESULT_END: allowed_flags=8'h07;
            ALLOC_RESULT:allowed_flags=8'h10;
            DROP_RESULT:allowed_flags=8'h0e;
            RETIRE:allowed_flags=8'h0a;
            FREEZE:allowed_flags=8'h01;
            default:allowed_flags=0;
        endcase
        if(cmd_valid && cmd_ready)begin
            if(request.op>11 || (request.flags & ~allowed_flags)!=0)answer.status=FIELD;
            else case(request.op)
                ALLOC_SOURCE:begin
                    if(quarantined)answer.status=QUARANTINED;
                    else if(source_limit)answer.status=EXHAUSTED;
                    else if(frame_collision)answer.status=IDENTITY;
                    else if(free_source<0)answer.status=NO_SPACE;
                    else begin
                        next_sources[free_source].state=S_WRITING;next_sources[free_source].handle=next_source_handle;
                        next_sources[free_source].frame_epoch=request.origin[130:67];
                        source_index=free_source;
                        if(next_source_handle==64'hffffffffffffffff)n_source_limit=1;else n_source_handle=next_source_handle+64'd1;
                    end
                end
                SOURCE_EOF,SOURCE_END:begin
                    if(!source_match)answer.status=IDENTITY;
                    else if(sources[source_index].state!=S_WRITING && sources[source_index].state!=S_DRAIN)answer.status=STATE;
                    else if(request.op==SOURCE_EOF)begin
                        if(sources[source_index].state!=S_WRITING)answer.status=STATE;
                        else next_sources[source_index].state=S_DRAIN;
                    end else if(!request.flags[1] || !request.flags[2])begin
                        next_sources[source_index].state=S_Q;n_quarantine=1;answer.status=QUARANTINED;
                    end else if(request.flags[0])begin
                        if(sources[source_index].state!=S_DRAIN)answer.status=STATE;
                        else begin
                            next_sources[source_index].state=S_COMPLETE;
                            if(latest_handle==0 || request.source_handle>latest_handle)n_latest=request.source_handle;
                            if(frozen && freeze_handle==0)n_freeze=request.source_handle;
                        end
                    end else next_sources[source_index].state=S_BAD;
                end
                ALLOC_RESULT:begin
                    if(request.source_handle!=0)begin if(source_match)selected_source=source_index;end
                    else for(integer s=0;s<6;s++)
                        if(sources[s].state!=S_FREE && sources[s].handle==(frozen ? freeze_handle : latest_handle))selected_source=s;
                    if(quarantined)answer.status=QUARANTINED;
                    else if(result_limit)answer.status=EXHAUSTED;
                    else if(free_result<0)answer.status=NO_SPACE;
                    else if(request.source_handle!=0 && !source_match)answer.status=IDENTITY;
                    else if(selected_source<0)answer.status=NO_SOURCE;
                    else if(sources[selected_source].state!=S_COMPLETE &&
                        !(request.flags[4] && request.source_handle!=0 && (sources[selected_source].state==S_WRITING || sources[selected_source].state==S_DRAIN)))answer.status=NOT_READY;
                    else if(request.cj[106:96]!=IMAGE_WIDTH || request.cj[117:107]!=IMAGE_HEIGHT || request.cj[128:118]>request.cj[139:129] ||
                        mode>5 || request.body[108:98]!=IMAGE_HEIGHT/2 || request.body[399:112]!=0)answer.status=FIELD;
                    else begin
                        src_base=32'(selected_source)*32'h00800000;res_base=32'h03000000+32'(free_result)*32'h00800000;
                        src_desc={src_base,RGB_BYTES,frame_allocation(RGB_BYTES)};
                        if(mode!=1 && mode!=2)edge_desc={res_base,EDGE_BYTES,frame_allocation(EDGE_BYTES)};
                        if(mode==5)ann_desc={res_base+32'h00100000,ANN_BYTES,frame_allocation(ANN_BYTES)};
                        next_results[free_result].state=R_WORKING;next_results[free_result].handle=next_result_handle;
                        next_results[free_result].source_slot=3'(selected_source);
                        next_results[free_result].config_snapshot=request.cj[141:64];
                        next_results[free_result].render_snapshot=request.body[111:0];next_results[free_result].policy=policy;
                        result_index=free_result;
                        if(next_result_handle==64'hffffffffffffffff)n_result_limit=1;else n_result_handle=next_result_handle+64'd1;
                    end
                end
                RESULT_END,OFFER,APPLY,DROP_RESULT,RETIRE:begin
                    if(!result_match)answer.status=IDENTITY;
                    else case(request.op)
                        RESULT_END:if(results[result_index].state!=R_WORKING)answer.status=STATE;
                            else if(!request.flags[1] || !request.flags[2])begin next_results[result_index].state=R_Q;n_quarantine=1;answer.status=QUARANTINED;end
                            else next_results[result_index].state=request.flags[0] ? R_DONE : R_FREE;
                        OFFER:if(quarantined)answer.status=QUARANTINED;
                            else if(results[result_index].state!=R_DONE)answer.status=STATE;
                            else if(results[result_index].policy!=policy || sources[results[result_index].source_slot].state!=S_COMPLETE ||
                                (frozen && sources[results[result_index].source_slot].handle!=freeze_handle))answer.status=NOT_READY;
                            else if(offered_exists)answer.status=NO_SPACE;
                            else if(offer_sequence==0 || offer_sequence<=last_offer_sequence)answer.status=IDENTITY;
                            else begin
                                next_results[result_index].state=R_OFFERED;
                                next_ro_sequence[result_index]=offer_sequence;n_last_offer_sequence=offer_sequence;
                            end
                        APPLY:if(results[result_index].state!=R_OFFERED)answer.status=STATE;
                            else begin
                                for(integer r=0;r<3;r++)if(results[r].state==R_DISPLAY)next_results[r].state=R_RETIRING;
                                next_results[result_index].state=R_DISPLAY;
                            end
                        DROP_RESULT:if(results[result_index].state!=R_WORKING && results[result_index].state!=R_DONE && results[result_index].state!=R_OFFERED)answer.status=STATE;
                            else if(!request.flags[1] || (results[result_index].state==R_WORKING && !request.flags[2]) ||
                                (results[result_index].state==R_OFFERED && !request.flags[3]))begin next_results[result_index].state=R_Q;n_quarantine=1;answer.status=QUARANTINED;end
                            else next_results[result_index].state=R_FREE;
                        RETIRE:if(results[result_index].state!=R_RETIRING)answer.status=STATE;
                            else if(!request.flags[1] || !request.flags[3])begin next_results[result_index].state=R_Q;n_quarantine=1;answer.status=QUARANTINED;end
                            else next_results[result_index].state=R_FREE;
                        default:answer.status=FIELD;
                    endcase
                end
                FREEZE:begin
                    if(frozen)answer.status=ALREADY;
                    else if(policy==64'hffffffffffffffff)answer.status=EXHAUSTED;
                    else if(request.flags[0] && (!source_match || !result_match))answer.status=IDENTITY;
                    else if(request.flags[0] && (sources[source_index].state!=S_COMPLETE ||
                        (results[result_index].state!=R_OFFERED && results[result_index].state!=R_DISPLAY && results[result_index].state!=R_RETIRING)))answer.status=STATE;
                    else begin n_frozen=1;n_policy=policy+64'd1;n_freeze=request.flags[0] ? request.source_handle : latest_handle;end
                end
                RESUME:if(!frozen)answer.status=ALREADY;
                    else if(policy==64'hffffffffffffffff)answer.status=EXHAUSTED;
                    else begin n_frozen=0;n_freeze=0;n_policy=policy+64'd1;end
                BARRIER:if(policy==64'hffffffffffffffff)answer.status=EXHAUSTED;else n_policy=policy+64'd1;
                default:answer.status=FIELD;
            endcase

            if(answer.status==OK)begin
                if(request.op==ALLOC_SOURCE)begin
                    answer.source_handle=next_source_handle;answer.source_slot=3'(free_source);
                    answer.origin={next_source_handle,request.origin[130:67],next_source_handle,3'(free_source)};
                end else if(request.op==SOURCE_EOF || request.op==SOURCE_END)begin
                    answer.source_handle=sources[source_index].handle;answer.source_slot=3'(source_index);
                    answer.origin=source_origin(sources[source_index],3'(source_index));
                end else if(request.op==ALLOC_RESULT)begin
                    answer.result_handle=next_result_handle;answer.result_slot=2'(free_result);
                    answer.source_handle=sources[selected_source].handle;answer.source_slot=3'(selected_source);
                    answer.origin=source_origin(sources[selected_source],3'(selected_source));
                    answer.cj={request.cj[141:64],sources[selected_source].frame_epoch};
                    answer.body={src_desc,edge_desc,ann_desc,request.body[111:0]};
                end else if(request.op==RESULT_END || request.op==OFFER || request.op==APPLY || request.op==DROP_RESULT || request.op==RETIRE || (request.op==FREEZE && request.flags[0]))begin
                    answer.result_handle=results[result_index].handle;answer.result_slot=2'(result_index);
                    answer.source_handle=sources[source_index].handle;answer.source_slot=3'(source_index);
                    answer.origin=source_origin(sources[source_index],3'(source_index));
                    answer.cj={results[result_index].config_snapshot,sources[source_index].frame_epoch};
                    answer.body=result_body(results[result_index],2'(result_index));answer.policy=results[result_index].policy;
                end else if(request.op==FREEZE && !request.flags[0] && n_freeze!=0)begin
                    for(integer s=0;s<6;s++)if(sources[s].handle==n_freeze && sources[s].state==S_COMPLETE)begin
                        answer.source_handle=n_freeze;answer.origin=source_origin(sources[s],3'(s));answer.source_slot=3'(s);
                    end
                end
                if(request.op==FREEZE || request.op==RESUME || request.op==BARRIER)answer.policy=n_policy;
            end
            // 先合并本沿所有引用变化，再统一回收；writer和Q永不由引用清零释放。
            for(integer s=0;s<6;s++)begin
                retained=next_sources[s].handle==n_latest || next_sources[s].handle==n_freeze;
                for(integer r=0;r<3;r++)if(next_results[r].state!=R_FREE && next_results[r].source_slot==s)retained=1;
                if((next_sources[s].state==S_COMPLETE || next_sources[s].state==S_BAD) && !retained)next_sources[s].state=S_FREE;
            end
            // RA07：只在真实释放后清绑定；slot重用不能承认旧FrameRef。
            for(integer r=0;r<3;r++)if(next_results[r].state==R_FREE)next_ro_sequence[r]=0;
        end
    end
    // RA03..07：旧账本是唯一事实源。查询不增加影子bundle或修改引用。
    always_comb begin : read_authority
        reply_t selected_reply;
        logic [2:0] expected_mask,stored_mode;
        logic [10:0] expected_y;
        integer borrowed_source;
        selected_reply='0;lookup_permitted=0;expected_mask=0;stored_mode=0;expected_y=0;borrowed_source=0;
        if(lookup_valid && lookup_ready && !quarantined && read_demand.sequence_id!=0 &&
            read_demand.scan!=0 && read_demand.target_y<IMAGE_HEIGHT)begin
            for(integer r=0;r<3;r++)begin
                if((results[r].state==R_OFFERED || results[r].state==R_DISPLAY || results[r].state==R_RETIRING) &&
                    results[r].handle==read_demand.result_handle && results[r].policy==read_demand.policy &&
                    ro_sequence[r]==read_demand.sequence_id && results[r].source_slot<6)begin
                    borrowed_source=int'(results[r].source_slot);
                    stored_mode=results[r].render_snapshot[111:109];
                    expected_y=read_demand.target_y;expected_mask=0;
                    case(stored_mode)
                        0:begin
                            expected_mask=read_demand.target_y<HALF_HEIGHT ? 3'd1 : 3'd2;
                            expected_y=(read_demand.target_y<HALF_HEIGHT ? read_demand.target_y :
                                read_demand.target_y-HALF_HEIGHT)<<1;
                        end
                        1,2:expected_mask=3'd1;
                        3:expected_mask=3'd2;
                        4:expected_mask=3'd3;
                        5:expected_mask=3'd7;
                        default:expected_mask=0;
                    endcase
                    if(sources[borrowed_source].state==S_COMPLETE &&
                        source_origin(sources[borrowed_source],3'(borrowed_source))==read_demand.origin &&
                        read_demand.mode==stored_mode && read_demand.source_y==expected_y &&
                        expected_mask!=0 && read_demand.required_mask==expected_mask)begin
                        lookup_permitted=1;selected_reply.op=OFFER;selected_reply.status=OK;
                        selected_reply.source_handle=sources[borrowed_source].handle;
                        selected_reply.result_handle=results[r].handle;
                        selected_reply.origin=source_origin(sources[borrowed_source],3'(borrowed_source));
                        selected_reply.cj={results[r].config_snapshot,sources[borrowed_source].frame_epoch};
                        selected_reply.body=result_body(results[r],2'(r));
                        // global policy可以更新；旧scope仍使用该Result的不可变policy。
                        selected_reply.policy=results[r].policy;
                        selected_reply.source_slot=3'(borrowed_source);selected_reply.result_slot=2'(r);
                    end
                end
            end
        end
        lookup_bundle=selected_reply;
    end
    always_ff @(posedge core_clk or negedge safe_reset_n)
        if(!safe_reset_n)reset_pipe<=2'b11;else reset_pipe<={reset_pipe[0],1'b0};
    always_ff @(posedge core_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin
            for(integer s=0;s<6;s++)sources[s]<='0;
            for(integer r=0;r<3;r++)begin results[r]<='0;ro_sequence[r]<=0;end
            last_offer_sequence<=INIT_LAST_OFFER_SEQUENCE;
            next_source_handle<=INIT_SOURCE_HANDLE;next_result_handle<=INIT_RESULT_HANDLE;source_limit<=0;result_limit<=0;
            latest_handle<=0;freeze_handle<=0;policy<=INIT_POLICY;frozen<=0;quarantined<=0;reply_valid<=0;reply_register<=0;
        end else if(running)begin
            if(reply_valid && reply_ready)reply_valid<=0;
            if(cmd_valid && cmd_ready)begin
                for(integer s=0;s<6;s++)sources[s]<=next_sources[s];
                for(integer r=0;r<3;r++)begin results[r]<=next_results[r];ro_sequence[r]<=next_ro_sequence[r];end
                last_offer_sequence<=n_last_offer_sequence;
                next_source_handle<=n_source_handle;next_result_handle<=n_result_handle;source_limit<=n_source_limit;result_limit<=n_result_limit;
                latest_handle<=n_latest;freeze_handle<=n_freeze;policy<=n_policy;frozen<=n_frozen;quarantined<=n_quarantine;
                reply_register<=answer;reply_valid<=1;
            end
        end
    end
    // synthesis translate_off
    initial if(IMAGE_WIDTH<4 || IMAGE_WIDTH>1920 || IMAGE_WIDTH%2!=0 || IMAGE_HEIGHT<2 || IMAGE_HEIGHT>1080 || IMAGE_HEIGHT%2!=0 || INIT_SOURCE_HANDLE==0 || INIT_RESULT_HANDLE==0 || INIT_POLICY==0)$fatal(1,"Frame owner parameters");
    // synthesis translate_on
    // synthesis translate_off
    initial if(FRAME_ALIGNMENT!=16 && FRAME_ALIGNMENT!=64) $fatal(1,"PB owner frame alignment");
    // synthesis translate_on
endmodule
