`timescale 1ns/1ps
module tb_display_rows #(parameter integer TEST_ROW_W=20,TEST_ROW_H=8,TEST_ROW_COUNT=24,TEST_ROW_MAX=0);
    import display_row_pkg::*;
    localparam integer PAIRS=TEST_ROW_W/2;
    localparam logic [63:0] INITIAL_GENERATION=TEST_ROW_MAX ? 64'hffffffffffffffff : 64'd1;
    logic core_clk=0,video_clk=0,safe_reset_n=0,finished=0,video_enable=1;
    always #5 core_clk=~core_clk;always #6.734 if(video_enable)video_clk=~video_clk;
    logic [2:0] fill_valid=0,fill_reply_ready=0,wr_valid=0,publish_valid=0,io_closed=0,producer_closed=0,abort_valid=0,return_ready=0,row_ready=0,rd_request_valid=0,rd_response_ready=0,release_valid=0;
    wire [2:0] fill_ready,fill_reply_valid,wr_ready,publish_ready,abort_ready,return_valid,core_busy,exhausted,quarantined,write_error,row_valid,owned,rd_request_ready,rd_response_valid,rd_error,release_ready,release_error;
    logic [2:0][542:0] fill_ticket=0;wire [2:0][542:0] fill_reply_ticket,return_ticket,row_ticket;
    wire [2:0][2:0] fill_reply_status;wire [2:0][1:0] return_kind;
    logic [2:0][63:0] wr_generation=0,publish_generation=0,abort_generation=0,rd_generation=0,release_generation=0;
    logic [2:0][9:0] wr_address=0,rd_address=0;wire [2:0][9:0] rd_response_address;
    logic [2:0][53:0] wr_data=0;wire [2:0][53:0] rd_data;logic [2:0][1:0] release_kind=0;
    display_rows3 #(.IMAGE_WIDTH(TEST_ROW_W),.IMAGE_HEIGHT(TEST_ROW_H),.INIT_GENERATION(INITIAL_GENERATION)) dut(.*);
    integer journal,fill_fires[3],write_fires[3],publish_fires[3],abort_fires[3],row_fires[3],read_fires[3],response_fires[3],release_fires[3],return_fires[3];
    integer writes=0,reads=0,errors=0,rows=0,returns=0,resets=0,held_cycles=0,safe_reset_aborted_rows=0;
    row_ticket_t accepted[3],video_owned[3];logic [63:0] generations[3];
    logic [64:0] expected0[$],expected1[$],expected2[$];
    logic [2:0] held=0;logic [2:0][64:0] held_record=0;
    function automatic logic [53:0] pattern(input row_ticket_t t,input integer address);
        logic [53:0] d;integer x,y,f;
        d=0;y=int'(t.source_y);f=int'(t.origin[130:99]);
        for(integer lane=0;lane<2;lane++)begin
            x=2*address+lane;
            d[lane*24+:24]={8'((x*37+y*11+f*3)%256),8'((x*13+y*47+f*7)%256),8'((x*53+y*19+f*17)%256)};
            d[48+lane]=((x+y+f)%3)==0;d[50+2*lane+:2]=2'((x*7+y*3+f)%4);
        end
        return d;
    endfunction
    function automatic row_ticket_t ticket(input integer b,input integer index);
        row_ticket_t t;integer y,mode,frame_no;logic [63:0] source;
        t='0;y=index%TEST_ROW_H;mode=index%6;frame_no=index/TEST_ROW_H+1;source=64'(100+frame_no);
        t.generation=generations[b];t.sequence_id=64'(frame_no+10);t.scan=64'(frame_no);t.result_handle=64'(500+frame_no);t.policy=1;
        t.origin={source,32'(frame_no),32'h45,source,3'(b)};t.target_y=11'(y);t.source_y=11'(y);t.mode=3'(mode);
        case(mode)
            0:begin t.required_mask=y<TEST_ROW_H/2 ? 1 : 2;t.source_y=11'(2*(y%(TEST_ROW_H/2)));end
            1,2:t.required_mask=1;3:t.required_mask=2;4:t.required_mask=3;5:t.required_mask=7;
        endcase
        return t;
    endfunction
    task automatic push_expected(input integer b,input logic [64:0] value);
        case(b)0:expected0.push_back(value);1:expected1.push_back(value);2:expected2.push_back(value);endcase
    endtask
    function automatic logic [64:0] pop_expected(input integer b);
        case(b)
            0:begin if(expected0.size()==0)$fatal(1,"Unaccepted read response");return expected0.pop_front();end
            1:begin if(expected1.size()==0)$fatal(1,"Unaccepted read response");return expected1.pop_front();end
            2:begin if(expected2.size()==0)$fatal(1,"Unaccepted read response");return expected2.pop_front();end
        endcase
    endfunction
    always @(posedge core_clk)if(safe_reset_n)for(integer b=0;b<3;b++)begin
        if(fill_valid[b]&&fill_ready[b])begin fill_fires[b]++;accepted[b]=fill_ticket[b];$fwrite(journal,"FILL,%0t,%0d,%h\n",$realtime,b,fill_ticket[b]);end
        if(fill_reply_valid[b]&&fill_reply_ready[b])$fwrite(journal,"FILL_REPLY,%0t,%0d,%h,%0d\n",$realtime,b,fill_reply_ticket[b],fill_reply_status[b]);
        if(wr_valid[b]&&wr_ready[b])begin write_fires[b]++;writes++;$fwrite(journal,"WRITE,%0t,%0d,%h,%0d,%h\n",$realtime,b,wr_generation[b],wr_address[b],wr_data[b]);end
        if(publish_valid[b]&&publish_ready[b])begin publish_fires[b]++;$fwrite(journal,"PUBLISH,%0t,%0d,%h,%b,%b\n",$realtime,b,publish_generation[b],io_closed[b],producer_closed[b]);end
        if(abort_valid[b]&&abort_ready[b])begin abort_fires[b]++;$fwrite(journal,"ABORT,%0t,%0d,%h,%b,%b\n",$realtime,b,abort_generation[b],io_closed[b],producer_closed[b]);end
        if(return_valid[b]&&return_ready[b])begin return_fires[b]++;returns++;$fwrite(journal,"RETURN,%0t,%0d,%h,%0d\n",$realtime,b,return_ticket[b],return_kind[b]);end
        if(write_error[b])$fwrite(journal,"WRITE_ERROR,%0t,%0d\n",$realtime,b);
    end
    always @(posedge video_clk)if(safe_reset_n)for(integer b=0;b<3;b++)begin
        logic [64:0] exp,actual;bit bad;
        if(row_valid[b]&&row_ready[b])begin video_owned[b]=row_ticket[b];row_fires[b]++;rows++;$fwrite(journal,"ROW,%0t,%0d,%h\n",$realtime,b,row_ticket[b]);end
        if(rd_request_valid[b]&&rd_request_ready[b])begin
            bad=rd_generation[b]!=video_owned[b].generation || rd_address[b]>=PAIRS;
            exp={bad ? 54'd0 : pattern(video_owned[b],int'(rd_address[b])),rd_address[b],bad};push_expected(b,exp);
            read_fires[b]++;$fwrite(journal,"READ,%0t,%0d,%h,%0d\n",$realtime,b,rd_generation[b],rd_address[b]);
        end
        actual={rd_data[b],rd_response_address[b],rd_error[b]};
        if(held[b] && (!rd_response_valid[b] || actual!==held_record[b]))$fatal(1,"Held row data changed bank=%0d",b);
        held[b]=rd_response_valid[b]&&!rd_response_ready[b];held_record[b]=actual;if(held[b])held_cycles++;
        if(rd_response_valid[b]&&rd_response_ready[b])begin
            exp=pop_expected(b);if(actual!==exp)$fatal(1,"Row data mismatch bank=%0d addr=%0d actual=%h expected=%h",b,rd_response_address[b],actual,exp);
            response_fires[b]++;reads++;if(rd_error[b])errors++;$fwrite(journal,"DATA,%0t,%0d,%0d,%h,%b\n",$realtime,b,rd_response_address[b],rd_data[b],rd_error[b]);
        end
        if(release_valid[b]&&release_ready[b])begin release_fires[b]++;$fwrite(journal,"RELEASE,%0t,%0d,%h,%0d\n",$realtime,b,release_generation[b],release_kind[b]);end
        if(release_error[b])$fwrite(journal,"RELEASE_ERROR,%0t,%0d\n",$realtime,b);
    end
    task automatic cold_reset;
        @(negedge core_clk);safe_reset_n=0;video_enable=1;fill_valid=0;fill_reply_ready=0;wr_valid=0;publish_valid=0;abort_valid=0;return_ready=0;row_ready=0;rd_request_valid=0;rd_response_ready=0;release_valid=0;held=0;
        expected0.delete();expected1.delete();expected2.delete();
        for(integer b=0;b<3;b++)begin generations[b]=INITIAL_GENERATION;fill_fires[b]=0;write_fires[b]=0;publish_fires[b]=0;abort_fires[b]=0;row_fires[b]=0;read_fires[b]=0;response_fires[b]=0;release_fires[b]=0;return_fires[b]=0;end
        repeat(7)@(negedge core_clk);safe_reset_n=1;repeat(7)@(negedge core_clk);resets++;
        $fwrite(journal,"RESET,%0t,%0d,%0d,%h\n",$realtime,TEST_ROW_W,TEST_ROW_H,INITIAL_GENERATION);
    endtask
    task automatic start_fill(input integer b,input row_ticket_t t,input integer status=0);
        integer n;@(negedge core_clk);n=fill_fires[b];fill_ticket[b]=t;fill_valid[b]=1;while(fill_fires[b]==n)@(negedge core_clk);fill_valid[b]=0;
        while(!fill_reply_valid[b])@(negedge core_clk);
        repeat(3+b)begin @(negedge core_clk);if(fill_reply_ticket[b]!==t || fill_reply_status[b]!=status || !fill_reply_valid[b] || wr_ready[b])$fatal(1,"Fill ack holding");end
        fill_reply_ready[b]=1;@(negedge core_clk);fill_reply_ready[b]=0;
    endtask
    task automatic write_pair(input integer b,input integer address,input row_ticket_t t);
        integer n;n=write_fires[b];wr_generation[b]=t.generation;wr_address[b]=10'(address);wr_data[b]=pattern(t,address);wr_valid[b]=1;
        while(write_fires[b]==n)@(negedge core_clk);wr_valid[b]=0;
    endtask
    task automatic read_pair(input integer b,input integer address,input logic [63:0] generation);
        integer n;n=read_fires[b];rd_generation[b]=generation;rd_address[b]=10'(address);rd_request_valid[b]=1;
        while(read_fires[b]==n)@(negedge video_clk);rd_request_valid[b]=0;
    endtask
    task automatic consume_return(input integer b,input row_ticket_t t,input integer kind=0);
        while(!return_valid[b])@(negedge core_clk);
        repeat(17)begin @(negedge core_clk);if(return_ticket[b]!==t || return_kind[b]!=kind || !return_valid[b] || fill_ready[b] || wr_ready[b])$fatal(1,"Return holding/writer reopened");end
        return_ready[b]=1;@(negedge core_clk);return_ready[b]=0;if(generations[b]!=64'hffffffffffffffff)generations[b]++;
    endtask
    task automatic run_bank(input integer b);
        row_ticket_t t;integer n,before_data;
        for(integer index=b;index<TEST_ROW_COUNT;index+=3)begin
            t=ticket(b,index);start_fill(b,t);io_closed[b]=0;producer_closed[b]=0;
            for(integer a=0;a<PAIRS;a++)write_pair(b,a,t);
            @(negedge core_clk);publish_valid[b]=1;publish_generation[b]=t.generation;io_closed[b]=1;
            repeat(5)begin @(negedge core_clk);if(publish_ready[b] || row_valid[b])$fatal(1,"Unknown producer closed exposed row");end
            producer_closed[b]=1;n=publish_fires[b];while(publish_fires[b]==n)@(negedge core_clk);publish_valid[b]=0;
            while(!row_valid[b])@(negedge video_clk);repeat(5)@(negedge video_clk);
            if(row_ticket[b]!==t)$fatal(1,"Torn row ticket");n=row_fires[b];row_ready[b]=1;while(row_fires[b]==n)@(negedge video_clk);row_ready[b]=0;rd_response_ready[b]=1;
            if(index<3)begin before_data=response_fires[b];read_pair(b,0,t.generation-1);while(response_fires[b]==before_data)@(negedge video_clk);end
            for(integer a=0;a<PAIRS;a++)begin
                read_pair(b,a,t.generation);
            end
            rd_response_ready[b]=0;
            release_valid[b]=1;release_generation[b]=t.generation;release_kind[b]=ROW_CONSUMED;
            repeat(11)begin @(negedge video_clk);if(release_ready[b] || !owned[b])$fatal(1,"Holding/pending escaped row borrow");end
            release_valid[b]=0;rd_response_ready[b]=1;
            while(rd_response_valid[b])@(negedge video_clk);
            // 错代归还是一个明确接纳的错误事件，不能清owned。
            if(index<3)begin
                release_generation[b]=t.generation+1;release_valid[b]=1;while(!release_ready[b])@(negedge video_clk);@(negedge video_clk);release_valid[b]=0;
                if(!release_error[b] || !owned[b])$fatal(1,"Wrong release lost borrow");
            end
            release_generation[b]=t.generation;n=release_fires[b];release_valid[b]=1;while(release_fires[b]==n)@(negedge video_clk);release_valid[b]=0;consume_return(b,t);
        end
    endtask
    initial begin
        row_ticket_t t,bad;integer metrics,before_abort,before_publish,before_row;
        if($test$plusargs("EXPECT_FATAL"))$fatal(1,"fatal exit probe");journal=$fopen("row-events.csv","w");cold_reset();
        fork run_bank(0);run_bank(1);run_bank(2);join
        if(TEST_ROW_MAX)begin if(exhausted!==3'b111 || fill_ready!=0)$fatal(1,"Generation wrapped");end
        else begin
            t=ticket(0,TEST_ROW_COUNT);start_fill(0,t);for(integer a=0;a<PAIRS;a++)write_pair(0,a,t);
            before_publish=publish_fires[0];publish_generation[0]=t.generation;io_closed[0]=1;producer_closed[0]=1;publish_valid[0]=1;
            while(publish_fires[0]==before_publish)@(negedge core_clk);publish_valid[0]=0;
            while(!row_valid[0])@(negedge video_clk);before_row=row_fires[0];row_ready[0]=1;
            while(row_fires[0]==before_row)@(negedge video_clk);row_ready[0]=0;video_enable=0;
            repeat(40)begin @(negedge core_clk);if(!core_busy[0] || wr_ready[0] || fill_ready[0] || return_valid[0])$fatal(1,"Stopped video borrow reclaimed");end
            safe_reset_aborted_rows++;cold_reset();
            if(owned!=0 || rd_response_valid!=0 || row_valid!=0)$fatal(1,"Old row escaped common safe reset");
            t=ticket(0,TEST_ROW_COUNT);bad=t;bad.required_mask^=3'd4;start_fill(0,bad,ROW_FIELD);bad=t;bad.generation++;start_fill(0,bad,ROW_IDENTITY);
            start_fill(0,t);write_pair(0,0,t);io_closed[0]=1;producer_closed[0]=1;publish_generation[0]=t.generation;publish_valid[0]=1;
            repeat(9)begin @(negedge core_clk);if(publish_ready[0] || row_valid[0])$fatal(1,"Incomplete row published");end
            publish_valid[0]=0;io_closed[0]=0;abort_generation[0]=t.generation;abort_valid[0]=1;
            repeat(9)begin @(negedge core_clk);if(abort_ready[0] || return_valid[0])$fatal(1,"Unknown IO abort closed");end
            before_abort=abort_fires[0];io_closed[0]=1;while(abort_fires[0]==before_abort)@(negedge core_clk);abort_valid[0]=0;consume_return(0,t,ROW_DISCARDED);
            t=ticket(0,TEST_ROW_COUNT+1);start_fill(0,t);wr_generation[0]=t.generation+1;wr_address[0]=0;wr_data[0]='1;wr_valid[0]=1;@(negedge core_clk);wr_valid[0]=0;
            if(!quarantined[0] || !write_error[0] || fill_ready[0] || return_valid[0])$fatal(1,"Wrong write not isolated");
            repeat(2)@(negedge core_clk);
        end
        if(expected0.size() || expected1.size() || expected2.size())$fatal(1,"Pending reads escaped suite");
        $fclose(journal);metrics=$fopen("protocol-metrics.json","w");
        $fwrite(metrics,"{\"finished\":true,\"width\":%0d,\"height\":%0d,\"row_count\":%0d,\"near_max\":%0d,\"writes\":%0d,\"reads\":%0d,\"errors\":%0d,\"rows\":%0d,\"returns\":%0d,\"resets\":%0d,\"held_cycles\":%0d,\"safe_reset_aborted_rows\":%0d}\n",TEST_ROW_W,TEST_ROW_H,TEST_ROW_COUNT,TEST_ROW_MAX,writes,reads,errors,rows,returns,resets,held_cycles,safe_reset_aborted_rows);$fclose(metrics);
        finished=1;$display("Display rows PASS writes=%0d reads=%0d rows=%0d",writes,reads,rows);$finish;
    end
    initial begin #(TEST_ROW_COUNT*(PAIRS*30+1000)*3);if(!finished)$fatal(1,"Row suite watchdog");end
endmodule
