// S01/S02/S04：消息位置只在此命名；core锁整包，身份不截短。
package scalar_protocol_pkg;
    localparam integer ID_BITS=176, REQ_BITS=622, RSP_BITS=585;
    localparam integer W_LO=176,H_LO=187,VERSION_LO=198,KIND_LO=206;
    localparam integer AS_LO=211,BS_LO=212,TARGET_LO=213,PAYLOAD_LO=222;
    localparam integer RSP_KIND_LO=176,RSP_TARGET_LO=181;
    localparam integer OUTCOME_LO=190,REASON_LO=192,VALUE_LO=200;
    localparam logic [1:0] VALUE=2'd0,FRAME_FAIL=2'd2,CANCEL_DROP=2'd3;
    localparam logic [7:0] NONE=8'd0,FORMAT=8'd2,COORD=8'd3;
    localparam logic [7:0] OVERFLOW=8'd8,DIV_ZERO=8'd11;
    localparam logic [7:0] UNSUPPORTED=8'd12,INTERNAL=8'd13;
    function automatic [8:0] maximum_target(input logic [4:0] kind);
        case(kind)
            0:maximum_target=385;
            1,2:maximum_target=194;
            3:maximum_target=193;
            4:maximum_target=97;
            5:maximum_target=2;
            6:maximum_target=192;
            7:maximum_target=96;
            default:maximum_target=0;
        endcase
    endfunction
endpackage
