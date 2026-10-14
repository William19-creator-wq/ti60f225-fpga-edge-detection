// FIT v1 D/F：字段是独立整数；复合消息不能整体解释成有符号数。
package fit_protocol_pkg;
    localparam integer ID_BITS=176, REQ_BITS=622, RSP_BITS=585;
    localparam integer W_LO=176,H_LO=187,VERSION_LO=198,KIND_LO=206;
    localparam integer AS_LO=211,BS_LO=212,TARGET_LO=213,PAYLOAD_LO=222;
    localparam integer OUTCOME_LO=190,REASON_LO=192,VALUE_LO=200;
    localparam logic [1:0] VALUE=0,LOCAL_REJECT=1,FRAME_FAIL=2,CANCEL_DROP=3;
    localparam logic [7:0] NONE=0,FORMAT=2,COORD=3,DEGENERATE=4;
    localparam logic [7:0] ILL_CONDITION=5,GEOM_RANGE=6,COUNT=7;
    localparam logic [7:0] OVERFLOW=8,CAPACITY=9,DIV_ZERO=11,UNSUPPORTED=12,INTERNAL=13;

    function automatic [191:0] extend_field(input logic [191:0] raw,
                                           input integer bits,input logic signed_field);
        logic [191:0] mask;
        begin
            mask=(192'b1<<bits)-1;
            extend_field=raw & mask;
            if(signed_field && raw[bits-1]) extend_field=extend_field | ~mask;
        end
    endfunction

    function automatic logic fits_slot(input logic [191:0] number,
                                        input integer bits,input logic signed_field);
        fits_slot=(number==extend_field(number,bits,signed_field));
    endfunction

    // FT06：先查完整385位，然后才允许收192位工作槽。
    function automatic logic fits_return(input logic [384:0] number,
                                          input integer bits,input logic signed_field);
        logic [191:0] normalized;
        logic [384:0] canonical;
        begin
            // 先规范候选、再比全部385位；不是先截入工作槽。FIT的typed宽度不超过192。
            normalized=extend_field(number[191:0],bits,signed_field);
            canonical={{193{signed_field && normalized[191]}},normalized};
            fits_return=bits>=1 && bits<=192 && number==canonical;
        end
    endfunction

    function automatic logic normal_ok(input logic signed [31:0] nx,
                                        input logic signed [31:0] ny);
        normal_ok=(nx>=-32'sd1073741824 && nx<=32'sd1073741824 &&
                   ny>=-32'sd1073741824 && ny<=32'sd1073741824 && (nx!=0 || ny!=0));
    endfunction

    // 返回{reason,outcome}，顺序对应 C01…C05；只检查输入，未计算的K不抢先检查。
    function automatic [9:0] check_request(input logic [621:0] request);
        logic [10:0] width,height;
        logic [4:0] kind;
        logic [399:0] p;
        logic [21:0] count_limit;
        integer used;
        begin
            width=request[W_LO+:11]; height=request[H_LO+:11];
            kind=request[KIND_LO+:5]; p=request[PAYLOAD_LO+:400];
            count_limit={11'b0,width}*{11'b0,height}; used=0;
            case(kind)
                11:used=279; 12:used=233; 13:used=164; 14:used=104;
                15:used=94; 17:used=263; 18:used=217;
                default:used=0;
            endcase
            check_request=0;
            if(width<6 || width>1920 || width[0] || height<5 || height>1080)
                check_request={COORD,FRAME_FAIL};
            else if(request[VERSION_LO+:8]!=1 || request[96+:8]!=0 || used==0)
                check_request={UNSUPPORTED,FRAME_FAIL};
            else if(request[AS_LO+:11]!=0 || (p>>used)!=0)
                check_request={FORMAT,FRAME_FAIL};
            else if(kind==11 || kind==17 || kind==12 || kind==18) begin
                if({1'b0,p[20:0]}>count_limit) check_request={COUNT,FRAME_FAIL};
                else if(p[20:0]<((kind==11 || kind==17)?3:2))
                    check_request={COUNT,LOCAL_REJECT};
            end else if(kind==13) begin
                if(!normal_ok(p[0+:32],p[32+:32]) ||
                   !normal_ok(p[82+:32],p[114+:32])) check_request={INTERNAL,FRAME_FAIL};
            end else if(kind==14) begin
                if(!normal_ok(p[0+:32],p[32+:32])) check_request={INTERNAL,FRAME_FAIL};
                else if(p[82+:11]>=width || p[93+:11]>=height) check_request={COORD,FRAME_FAIL};
            end else if(kind==15 && (p[72+:11]>=width || p[83+:11]>=height))
                check_request={COORD,FRAME_FAIL};
        end
    endfunction

    function automatic [584:0] pack_response(input logic [621:0] request,
        input logic [1:0] outcome,input logic [7:0] reason,input logic [384:0] value);
        pack_response={value,reason,outcome,request[TARGET_LO+:9],
                       request[KIND_LO+:5],request[175:0]};
    endfunction

    // cmp：0等、1小、2大。非法3由调用方归INTERNAL，不能作为默认正常分支。
    function automatic [19:0] choose_midpoint_even(input logic [18:0] k,
                                                  input logic [1:0] cmp);
        choose_midpoint_even={1'b0,k}+((cmp==2 || (cmp==0 && k[0]))?20'd1:20'd0);
    endfunction

    function automatic logic qualify_distance_bounds(input logic [20:0] q,
                                                       input logic [1:0] cmp,
                                                       input logic upper_boundary);
        qualify_distance_bounds=(cmp==(upper_boundary?1:2)) || (cmp==0 && !q[0]);
    endfunction
endpackage
