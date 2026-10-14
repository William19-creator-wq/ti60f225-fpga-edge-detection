// ST01…08：token、STAT和NUM是三种消息，字段独立解释；位图见设计D。
package stats_protocol_pkg;
    localparam integer TOKEN_BITS=262, STAT_BITS=632, OP_LO=176, DATA_LO=178;
    localparam logic [1:0] START=0, POINT=1, END_SCAN=2, ABORT_SCAN=3;

    function automatic [261:0] token(input logic [175:0] id,
        input logic [1:0] op,input logic [83:0] data);
        token={data,op,id};
    endfunction

    function automatic [7:0] check_start(input logic [175:0] id,input logic [83:0] h);
        logic [10:0] w,v; logic [4:0] kind; logic [21:0] limit;
        begin
            w=h[0+:11]; v=h[11+:11]; kind=h[22+:5];
            limit={11'd0,w}*{11'd0,v}; check_start=0;
            if(w<6 || w>1920 || w[0] || v<5 || v>1080) check_start=fit_protocol_pkg::COORD;
            else if(h[27+:8]!=1 || id[96+:8]!=0 ||
                    !(kind==11 || kind==12 || kind==17 || kind==18)) check_start=fit_protocol_pkg::UNSUPPORTED;
            else if(h[83:72]!=0 || ((kind==17 || kind==18) && h[35+:16]!=0)) check_start=fit_protocol_pkg::FORMAT;
            else if({1'b0,h[51+:21]}>limit) check_start=fit_protocol_pkg::COUNT;
        end
    endfunction

    // 先检查完整候选，资格通过才允许收窄到原FIT字段。
    function automatic logic fits_accumulator(input logic signed [56:0] value,
        input logic tls,input integer slot);
        integer bits; logic signed_field; logic signed [56:0] minimum,maximum;
        begin
            bits=56; signed_field=1;
            if(tls) case(slot)
                0,1:bits=33; 2,3:begin bits=43; signed_field=0; end
                4:bits=44; default:bits=0;
            endcase
            else case(slot)
                0,2:begin bits=43; signed_field=0; end
                1:bits=44; 3,4:bits=56; default:bits=0;
            endcase
            minimum=signed_field?-(57'sd1<<<(bits-1)):57'sd0;
            maximum=signed_field?((57'sd1<<<(bits-1))-57'sd1):((57'sd1<<<bits)-57'sd1);
            fits_accumulator=bits!=0 && value>=minimum && value<=maximum;
        end
    endfunction

    function automatic logic fits_raw_count(input logic [22:0] value);
        fits_raw_count=!value[22];
    endfunction

    function automatic [7:0] qualify_commit(input logic [21:0] count,limit,input logic tls,
        input logic signed [56:0] v0,v1,v2,v3,v4);
        begin
            qualify_commit=0;
            if(count[21] || count>limit) qualify_commit=fit_protocol_pkg::COUNT;
            else if(!fits_accumulator(v0,tls,0) || !fits_accumulator(v1,tls,1) ||
                    !fits_accumulator(v2,tls,2) || !fits_accumulator(v3,tls,3) || !fits_accumulator(v4,tls,4))
                qualify_commit=fit_protocol_pkg::OVERFLOW;
        end
    endfunction

    function automatic [621:0] pack_numeric(input logic [175:0] id,input logic [83:0] h,
        input logic [20:0] n,input logic signed [55:0] v0,v1,v2,v3,v4,
        input logic payload_valid);
        logic [399:0] p; logic [4:0] kind;
        begin
            p=0; kind=h[22+:5];
            if(payload_valid) begin
                p[0+:21]=n;
                if(kind==11 || kind==17) begin
                    p[21+:43]=v0[42:0]; p[64+:44]=v1[43:0]; p[108+:43]=v2[42:0];
                    p[151+:56]=v3; p[207+:56]=v4;
                    if(kind==11) p[263+:16]=h[35+:16];
                end else begin
                    p[21+:33]=v0[32:0]; p[54+:33]=v1[32:0]; p[87+:43]=v2[42:0];
                    p[130+:43]=v3[42:0]; p[173+:44]=v4[43:0];
                    if(kind==12) p[217+:16]=h[35+:16];
                end
            end
            pack_numeric={p,9'd0,2'd0,kind,h[27+:8],h[11+:11],h[0+:11],id};
        end
    endfunction
endpackage
