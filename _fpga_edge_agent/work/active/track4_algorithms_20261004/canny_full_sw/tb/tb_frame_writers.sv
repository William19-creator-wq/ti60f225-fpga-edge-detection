`timescale 1ns/1ps
// FC-T03：直接公开端口注入metadata错误，不force内部状态；固定数学payload核末项/padding。
module tb_frame_writers;
    logic clk=0,rst=1,finished=0;always #5 clk=~clk;
    logic [1:0] cfg_valid=0,cfg_ready,cfg_rsp_valid,cfg_rsp_ready=0,cfg_rsp_error;
    logic [31:0] cfg_base[0:1];
    logic [95:0] class_id=96'hfedcba987654321001234567;
    logic [63:0] edge_id=64'ha9876543210fedcb;
    logic [1:0] in_valid=0,in_ready,abort_valid=0,done_valid,done_ready=0,done_error,done_aborted,done_drained,quarantined;
    logic [124:0] in_payload=0;logic [20:0] in_index=0;logic in_edge=0;logic [63:0] in_id;
    logic [21:0] count[0:1];
    logic [1:0] line_req_valid,line_req_ready=0,line_write,line_rsp_valid=0,line_rsp_ready,line_error=0,line_drained=3;
    logic [31:0] line_addr[0:1];logic [511:0] line_wdata[0:1];
    class_frame_writer #(.WIDTH(6),.HEIGHT(5)) classes(
        .clk(clk),.rst(rst),.cfg_valid(cfg_valid[0]),.cfg_ready(cfg_ready[0]),.cfg_base(cfg_base[0]),.cfg_id(class_id),
        .cfg_rsp_valid(cfg_rsp_valid[0]),.cfg_rsp_ready(cfg_rsp_ready[0]),.cfg_rsp_error(cfg_rsp_error[0]),
        .in_valid(in_valid[0]),.in_ready(in_ready[0]),.in_payload(in_payload),.abort_valid(abort_valid[0]),.abort_id(class_id),
        .done_valid(done_valid[0]),.done_ready(done_ready[0]),.done_error(done_error[0]),.done_aborted(done_aborted[0]),.done_drained(done_drained[0]),.count(count[0]),
        .line_req_valid(line_req_valid[0]),.line_req_ready(line_req_ready[0]),.line_write(line_write[0]),.line_addr(line_addr[0]),.line_wdata(line_wdata[0]),
        .line_rsp_valid(line_rsp_valid[0]),.line_rsp_ready(line_rsp_ready[0]),.line_rdata(512'd0),.line_error(line_error[0]),.line_drained(line_drained[0]),.quarantined(quarantined[0]));
    edge_frame_writer #(.WIDTH(6),.HEIGHT(5)) edges(
        .clk(clk),.rst(rst),.cfg_valid(cfg_valid[1]),.cfg_ready(cfg_ready[1]),.cfg_base(cfg_base[1]),.cfg_id(edge_id),
        .cfg_rsp_valid(cfg_rsp_valid[1]),.cfg_rsp_ready(cfg_rsp_ready[1]),.cfg_rsp_error(cfg_rsp_error[1]),
        .in_valid(in_valid[1]),.in_ready(in_ready[1]),.in_index(in_index),.in_edge(in_edge),.in_id(in_id),.abort_valid(abort_valid[1]),.abort_id(edge_id),
        .done_valid(done_valid[1]),.done_ready(done_ready[1]),.done_error(done_error[1]),.done_aborted(done_aborted[1]),.done_drained(done_drained[1]),.count(count[1]),
        .line_req_valid(line_req_valid[1]),.line_req_ready(line_req_ready[1]),.line_write(line_write[1]),.line_addr(line_addr[1]),.line_wdata(line_wdata[1]),
        .line_rsp_valid(line_rsp_valid[1]),.line_rsp_ready(line_rsp_ready[1]),.line_rdata(512'd0),.line_error(line_error[1]),.line_drained(line_drained[1]),.quarantined(quarantined[1]));
    logic [1:0] pending=0,hold_request=0,hold_response=0,next_error=0,next_drained=3,held_request=0,held_done=0;
    integer delay_count[0:1],cycles=0,cases=0,checked_lines=0;
    logic [544:0] request_body[0:1];logic [23:0] done_body[0:1];logic [511:0] expected_line[0:1];
    function automatic [124:0] class_payload(input integer pair_number);
        integer x,y;logic [2:0] markers;
        x=(pair_number%3)*2;y=pair_number/3;markers={pair_number==14,x==4,pair_number==0};
        return {markers,class_id,11'(y),11'(x),2'((pair_number+1)%3),2'(pair_number%3)};
    endfunction
    always @(negedge clk)begin
        for(integer lane=0;lane<2;lane++)begin
            line_req_ready[lane]=!rst && !pending[lane] && !hold_request[lane];
            line_rsp_valid[lane]=!rst && pending[lane] && delay_count[lane]==0 && !hold_response[lane];
        end
    end
    always @(posedge clk)begin
        cycles++;
        if(rst)begin pending=0;held_request=0;held_done=0;end
        else for(integer lane=0;lane<2;lane++)begin
            if(held_request[lane] && (!line_req_valid[lane] || request_body[lane]!=={line_write[lane],line_addr[lane],line_wdata[lane]}))$fatal(1,"Writer held RPC changed");
            if(held_done[lane] && (!done_valid[lane] || done_body[lane]!=={done_error[lane],done_aborted[lane],count[lane]}))$fatal(1,"Writer held done changed");
            held_request[lane]=line_req_valid[lane] && !line_req_ready[lane];request_body[lane]={line_write[lane],line_addr[lane],line_wdata[lane]};
            held_done[lane]=done_valid[lane] && !done_ready[lane];done_body[lane]={done_error[lane],done_aborted[lane],count[lane]};
            if(line_req_valid[lane] && line_req_ready[lane])begin
                if(pending[lane] || !line_write[lane] || line_addr[lane]!=cfg_base[lane] || line_wdata[lane]!==expected_line[lane])$fatal(1,"Writer line math/padding/last item mismatch");
                pending[lane]=1;delay_count[lane]=5;line_error[lane]=next_error[lane];line_drained[lane]=next_drained[lane];checked_lines++;
            end else if(pending[lane] && delay_count[lane]>0)delay_count[lane]--;
            if(line_rsp_valid[lane] && line_rsp_ready[lane])pending[lane]=0;
        end
        if(cycles>100000)$fatal(1,"Writer protocol watchdog");
    end
    task automatic reset_joint;
        @(negedge clk);rst=1;cfg_valid=0;cfg_rsp_ready=0;in_valid=0;abort_valid=0;done_ready=0;
        hold_request=0;hold_response=0;next_error=0;next_drained=3;in_id=edge_id;
        cfg_base[0]=32'h100000;cfg_base[1]=32'h200000;
        repeat(3)@(posedge clk);@(negedge clk);rst=0;
    endtask
    task automatic configure(input integer lane,input logic error_expected=0);
        @(negedge clk);cfg_valid[lane]=1;do @(posedge clk);while(!cfg_ready[lane]);
        @(negedge clk);cfg_valid[lane]=0;while(!cfg_rsp_valid[lane])@(negedge clk);
        if(cfg_rsp_error[lane]!==error_expected)$fatal(1,"Writer cfg rejection");
        cfg_rsp_ready[lane]=1;@(posedge clk);@(negedge clk);cfg_rsp_ready[lane]=0;
    endtask
    task automatic send_item(input integer lane,input integer ordinal,input integer corruption=0);
        @(negedge clk);
        if(lane==0)begin
            in_payload=class_payload(ordinal);
            case(corruption)
                1:in_payload[121:26]=class_id^(96'd1<<64);
                2:in_payload[14:4]=4;
                3:in_payload[122]=0;
                4:in_payload[1:0]=3;
                default:begin end
            endcase
        end else begin in_index=21'(ordinal)+(corruption==1 ? 21'd1 : 21'd0);in_id=corruption==2 ? edge_id^64'd1 : edge_id;in_edge=ordinal%5<2;end
        in_valid[lane]=1;do @(posedge clk);while(!in_ready[lane]);@(negedge clk);in_valid[lane]=0;
    endtask
    task automatic send_complete(input integer lane);
        for(integer j=0;j<(lane==0 ? 15 : 30);j++)send_item(lane,j);
    endtask
    task automatic cancel_private(input integer lane);
        @(negedge clk);abort_valid[lane]=1;@(posedge clk);@(negedge clk);abort_valid[lane]=0;
    endtask
    task automatic take_done(input integer lane,input logic error_expected,input logic aborted_expected);
        while(!done_valid[lane])@(negedge clk);
        if(done_error[lane]!==error_expected || done_aborted[lane]!==aborted_expected || !done_drained[lane] || pending[lane] || line_req_valid[lane])$fatal(1,"Writer completion/drain");
        repeat(4)@(negedge clk);done_ready[lane]=1;@(posedge clk);@(negedge clk);done_ready[lane]=0;cases++;
    endtask
    initial begin
        integer file_handle;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        expected_line[0]=0;expected_line[1]=0;
        for(integer j=0;j<15;j++)expected_line[0][j*4+:4]={2'((j+1)%3),2'(j%3)};
        for(integer j=0;j<30;j++)expected_line[1][j*8+:8]=j%5<2 ? 255 : 0;
        for(integer lane=0;lane<2;lane++)begin
            reset_joint();cfg_base[lane]++;configure(lane,1);if(!cfg_ready[lane])$fatal(1,"Rejected cfg retained context");cases++;
            for(integer bad=1;bad<=(lane==0 ? 4 : 2);bad++)begin
                reset_joint();configure(lane);send_item(lane,0,bad);take_done(lane,1,0);
                if(count[lane]!=1)$fatal(1,"Bad input acceptance ledger");
            end
            reset_joint();configure(lane);send_complete(lane);
            while(!done_valid[lane])@(negedge clk);cancel_private(lane);take_done(lane,0,0);
            reset_joint();configure(lane);for(integer j=0;j<3;j++)send_item(lane,j);cancel_private(lane);take_done(lane,1,1);
            if(count[lane]!=3)$fatal(1,"Partial cancel count");
            reset_joint();configure(lane);hold_request[lane]=1;send_complete(lane);
            while(!line_req_valid[lane])@(negedge clk);cancel_private(lane);repeat(12)@(negedge clk);
            if(!line_req_valid[lane])$fatal(1,"Public writer request withdrawn");hold_request[lane]=0;take_done(lane,1,1);
            reset_joint();configure(lane);next_error[lane]=1;hold_response[lane]=1;send_complete(lane);
            while(!pending[lane])@(negedge clk);cancel_private(lane);hold_response[lane]=0;take_done(lane,1,0);
            reset_joint();configure(lane);next_drained[lane]=0;send_complete(lane);
            while(!quarantined[lane])@(negedge clk);repeat(10)@(negedge clk);
            if(done_valid[lane] || cfg_ready[lane] || line_req_valid[lane])$fatal(1,"Writer unknown drain released ownership");cases++;
        end
        file_handle=$fopen("writer-protocol-metrics.json","w");$fwrite(file_handle,"{\"finished\":true,\"cases\":%0d,\"checked_lines\":%0d,\"cycles\":%0d}\n",cases,checked_lines,cycles);$fclose(file_handle);
        finished=1;$display("Writer protocol PASS cases=%0d checked_lines=%0d",cases,checked_lines);$finish;
    end
endmodule
