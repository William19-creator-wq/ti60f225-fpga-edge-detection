`timescale 1ns/1ps
// 图服务与queue是行为模型；所有输入/输出由真实fire推进，不能当DDR实证。
module tb_hysteresis_core #(
    parameter integer WIDTH=12,HEIGHT=9
);
    localparam integer N=WIDTH*HEIGHT;
    logic clk=0,rst=1,job_valid=0,cancel_valid=0,done_ready=0,pixel_ready=0;
    always #5 clk=~clk;
    logic [63:0] job_id=0,cancel_id=0;
    wire job_ready,sv,sready,qv,qready,pv,dv;
    wire [1:0] sop,outcome;
    wire [20:0] si,qi,pi;
    wire qpush,pe;
    wire [63:0] pixel_id,done_id;
    wire [7:0] reason;
    wire [21:0] enqueued,popped,outputs;
    logic sreq_ready=0,qreq_ready=0,srsp_valid=0,qrsp_valid=0;
    logic [1:0] sold;
    logic sclaimed,serror,qerror;
    logic [20:0] qreply;
    hysteresis_core #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) dut(
        .clk(clk),.rst(rst),.job_valid(job_valid),.job_id(job_id),.job_ready(job_ready),
        .cancel_valid(cancel_valid),.cancel_id(cancel_id),
        .state_req_valid(sv),.state_req_ready(sreq_ready),.state_req_op(sop),.state_req_index(si),
        .state_rsp_valid(srsp_valid),.state_rsp_ready(sready),.state_rsp_old(sold),
        .state_rsp_claimed(sclaimed),.state_rsp_error(serror),
        .queue_req_valid(qv),.queue_req_ready(qreq_ready),.queue_req_push(qpush),.queue_req_index(qi),
        .queue_rsp_valid(qrsp_valid),.queue_rsp_ready(qready),.queue_rsp_index(qreply),.queue_rsp_error(qerror),
        .pixel_valid(pv),.pixel_ready(pixel_ready),.pixel_index(pi),.pixel_edge(pe),.pixel_job_id(pixel_id),
        .done_valid(dv),.done_ready(done_ready),.done_job_id(done_id),.outcome(outcome),.reason(reason),
        .enqueue_count(enqueued),.pop_count(popped),.output_count(outputs));
    logic [1:0] image[0:N-1];
    integer fifo[0:N-1],head=0,tail=0;
    integer state_delay=-1,queue_delay=-1;
    bit claimed_once[0:N-1];
    integer kind=0,case_index=0,cycle=0,job_cycles=0,received=0,edges=0;
    integer state_requests=0,queue_requests=0,trigger_cycle=-1;
    integer output_file=0,results_file,case_file,fixture_file,fields,expect_outcome,expect_reason,expect_edges;
    logic [31:0] random_bits=32'h43106025;
    bit running=0,triggered=0,reset_injected=0,finished=0;
    bit held_s=0,held_q=0,held_p=0,held_d=0;
    logic [22:0] held_s_body;
    logic [21:0] held_q_body;
    logic [85:0] held_p_body;
    logic [139:0] held_d_body;
    string input_name,output_name;

    always @(negedge clk)begin
        if(running && !rst)begin
            random_bits={random_bits[30:0],random_bits[31]^random_bits[21]^random_bits[1]^random_bits[0]};
            sreq_ready=state_delay<0 && !srsp_valid && random_bits[1:0]!=0;
            qreq_ready=queue_delay<0 && !qrsp_valid && random_bits[3:2]!=0;
            pixel_ready=random_bits[5:4]!=0;
            cancel_valid=0;
            if(kind==6 && !triggered && sv)begin sreq_ready=0;triggered=1;trigger_cycle=cycle;cancel_valid=1;end
            if(kind==6 && triggered && cycle-trigger_cycle<4)sreq_ready=0;
            if(kind==7 && !triggered && dut.state==dut.STATE_WAIT)begin triggered=1;cancel_valid=1;end
            if(kind==8 && !triggered && pv)begin pixel_ready=0;triggered=1;trigger_cycle=cycle;cancel_valid=1;end
            if(kind==8 && triggered && cycle-trigger_cycle<4)pixel_ready=0;
            if(kind==9 && !triggered && sv)begin triggered=1;cancel_valid=1;cancel_id=job_id+64'd1;end
            if(kind==10 && !triggered && dv)begin triggered=1;cancel_valid=1;end
            if(kind==13 && !triggered && dut.state==dut.DIVIDE)begin triggered=1;cancel_valid=1;end
        end else begin sreq_ready=0;qreq_ready=0;pixel_ready=0;cancel_valid=0;end
    end

    always @(posedge clk)begin
        cycle=cycle+1;
        if(rst)begin
            srsp_valid<=0;qrsp_valid<=0;state_delay=-1;queue_delay=-1;head=0;tail=0;
            held_s=0;held_q=0;held_p=0;held_d=0;
        end else if(running)begin
            job_cycles=job_cycles+1;
            if(held_s && (!sv || {sop,si}!==held_s_body))$fatal(1,"state request changed under stall");
            if(held_q && (!qv || {qpush,qi}!==held_q_body))$fatal(1,"queue request changed under stall");
            if(held_p && (!pv || {pixel_id,pi,pe}!==held_p_body))$fatal(1,"pixel changed under stall");
            if(held_d && (!dv || {done_id,outcome,reason,enqueued,popped,outputs}!==held_d_body))$fatal(1,"done changed under stall");
            held_s=sv && !sreq_ready;held_s_body={sop,si};
            held_q=qv && !qreq_ready;held_q_body={qpush,qi};
            held_p=pv && !pixel_ready;held_p_body={pixel_id,pi,pe};
            held_d=dv && !done_ready;held_d_body={done_id,outcome,reason,enqueued,popped,outputs};
            if(srsp_valid && sready)srsp_valid<=0;
            if(qrsp_valid && qready)qrsp_valid<=0;
            if(state_delay>0)state_delay=state_delay-1;
            else if(state_delay==0)begin srsp_valid<=1;state_delay=-1;end
            if(queue_delay>0)queue_delay=queue_delay-1;
            else if(queue_delay==0)begin qrsp_valid<=1;queue_delay=-1;end
            if(sv && sreq_ready)begin
                if(si>=N || state_delay>=0 || srsp_valid || qv || qrsp_valid)$fatal(1,"state operation ownership/range");
                sold<=image[si];sclaimed<=0;serror<=0;
                if((sop==1 && image[si]==2) || (sop==2 && image[si]==1))begin
                    if(claimed_once[si])$fatal(1,"duplicate claim");
                    claimed_once[si]=1;image[si]=3;sclaimed<=1;
                end
                if(kind==2 && state_requests==0)serror<=1;
                if(kind==3 && state_requests==0)sclaimed<=0;
                state_requests++;state_delay=1+integer'(random_bits[9:7]);
            end
            if(qv && qreq_ready)begin
                if(queue_delay>=0 || qrsp_valid || sv || srsp_valid)$fatal(1,"queue ownership");
                qerror<=0;
                if(qpush)begin
                    if(tail>=N || qi>=N || !claimed_once[qi])$fatal(1,"queue full or unclaimed append");
                    fifo[tail]=qi;tail++;qreply<=qi;
                    if(kind==4 && queue_requests==0)qreply<=21'(N);
                end else begin
                    if(head>=tail)$fatal(1,"queue underflow");
                    qreply<=21'(fifo[head]);head++;
                end
                if(kind==5 && queue_requests==0)qerror<=1;
                queue_requests++;queue_delay=1+integer'(random_bits[12:10]);
            end
            if(pv && pixel_ready)begin
                if(pixel_id!=job_id || pi!=received || pi>=N || $isunknown(pe))$fatal(1,"pixel identity/order");
                $fwrite(output_file,"%0d\n",pe);received++;edges+=pe;
            end
            if(job_cycles>200*N+10000)$fatal(1,"per job watchdog");
        end
    end

    initial begin
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");
        results_file=$fopen("actual-results.txt","w");case_file=$fopen("cases.txt","r");
        if(!results_file || !case_file)$fatal(1,"fixture open failed");
        repeat(4)@(negedge clk);rst=0;
        while(!$feof(case_file))begin
            fields=$fscanf(case_file,"%d %d %d %d\n",kind,expect_outcome,expect_reason,expect_edges);
            if(fields!=4)$fatal(1,"bad metadata");
            input_name=$sformatf("case-%0d.class",case_index);
            fixture_file=$fopen(input_name,"r");
            if(!fixture_file)$fatal(1,"class fixture missing: %s",input_name);
            $fclose(fixture_file);$readmemh(input_name,image);
            for(integer i=0;i<N;i++)claimed_once[i]=0;
            head=0;tail=0;received=0;edges=0;job_cycles=0;state_requests=0;queue_requests=0;
            triggered=0;reset_injected=0;trigger_cycle=-1;
            output_name=$sformatf("actual-%0d.edge",case_index);output_file=$fopen(output_name,"w");
            @(negedge clk);running=1;job_id=64'(case_index)+64'd100;cancel_id=job_id;job_valid=1;
            // job/cancel同沿单独放在posedge之前，避开常规negedge取消驱动。
            if(kind==12)begin #1;cancel_valid=1;end
            do begin @(posedge clk);#1;end while(!job_ready && dut.state==dut.IDLE);
            @(negedge clk);job_valid=0;
            while(!dv)begin
                @(negedge clk);
                if(kind==11 && !reset_injected && sv)begin
                    rst=1;running=0;reset_injected=1;
                    @(negedge clk);$readmemh(input_name,image);
                    for(integer i=0;i<N;i++)claimed_once[i]=0;
                    received=0;edges=0;job_cycles=0;state_requests=0;queue_requests=0;
                    @(negedge clk);rst=0;running=1;job_id=job_id+64'd1000;cancel_id=job_id;job_valid=1;
                    @(negedge clk);job_valid=0;
                end
            end
            repeat(8)@(negedge clk);
            if(outcome!=expect_outcome || reason!=expect_reason || done_id!=job_id)$fatal(1,"terminal differs case%0d got%0d/%0d",case_index,outcome,reason);
            if(state_delay>=0 || queue_delay>=0 || srsp_valid || qrsp_valid)$fatal(1,"terminal before service drain");
            if(outcome==0 && (received!=N || edges!=expect_edges || enqueued!=edges || popped!=edges || outputs!=received))$fatal(1,"completion/count");
            if((kind>=6 && kind<=10 || kind==13) && !triggered)$fatal(1,"cancel scenario did not execute");
            $fwrite(results_file,"%0d %0d %0d %0d %0d %0d %0d %0d\n",case_index,outcome,reason,enqueued,popped,outputs,edges,job_cycles);
            $fclose(output_file);
            done_ready=1;@(negedge clk);done_ready=0;running=0;case_index++;
        end
        $fclose(results_file);$fclose(case_file);
        finished=1;#1;$display("HY complete cases=%0d",case_index);$finish;
    end
endmodule
