// AN01/02/03：沿用NUM622/RESP585身份；四kind字段各自有符号，不解释整个消息。
package angle_protocol_pkg;
    localparam integer W_LO=176,H_LO=187,VERSION_LO=198,KIND_LO=206,TARGET_LO=213,PAYLOAD_LO=222;
    localparam logic [1:0] VALUE=0,LOCAL_REJECT=1,FRAME_FAIL=2,CANCEL_DROP=3;
    localparam logic [7:0] NONE=0,GRAD_ZERO=1,FORMAT=2,COORD_ERROR=3,DEGENERATE=4,OVERFLOW=8,UNSUPPORTED=12,INTERNAL=13;
    function automatic [9:0] check_request(input logic [621:0] request);
        logic [10:0] w,h;logic [4:0] kind;logic [399:0] p;integer used;
        logic signed [10:0] gx,gy;logic signed [18:0] dx,dy;
        begin
            w=request[W_LO+:11];h=request[H_LO+:11];kind=request[KIND_LO+:5];p=request[PAYLOAD_LO+:400];
            gx=p[0+:11];gy=p[11+:11];dx=p[0+:19];dy=p[19+:19];
            case(kind)8:used=22;9:used=38;10:used=31;16:used=9;default:used=0;endcase
            check_request=0;
            if(w<6 || w>1920 || w[0] || h<5 || h>1080)check_request={COORD_ERROR,FRAME_FAIL};
            else if(request[VERSION_LO+:8]!=1 || request[96+:8]!=0 || used==0)check_request={UNSUPPORTED,FRAME_FAIL};
            else if(request[211+:11]!=0 || (p>>used)!=0)check_request={FORMAT,FRAME_FAIL};
            else if(kind==8 && (gx < -11'sd1020 || gx>11'sd1020 || gy < -11'sd1020 || gy>11'sd1020))check_request={COORD_ERROR,FRAME_FAIL};
            else if(kind==9 && (dx < -20'sd262143 || dx>20'sd262143 || dy < -20'sd262143 || dy>20'sd262143))check_request={COORD_ERROR,FRAME_FAIL};
            else if(kind==10 && (p[0+:11]>=w || p[11+:11]>=h))check_request={COORD_ERROR,FRAME_FAIL};
            else if(kind==8 && gx==0 && gy==0)check_request={GRAD_ZERO,FRAME_FAIL};
            else if(kind==9 && dx==0 && dy==0)check_request={DEGENERATE,LOCAL_REJECT};
        end
    endfunction
    function automatic [584:0] pack_response(input logic [621:0] request,
        input logic [1:0] outcome,input logic [7:0] reason,input logic [384:0] value);
        pack_response={value,reason,outcome,request[TARGET_LO+:9],request[KIND_LO+:5],request[175:0]};
    endfunction
endpackage
