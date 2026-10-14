// SC03/CT01：公开字段、诊断编码；原表顺序另在实际RAM10。
package sc431hai_profile_pkg;
    localparam integer WRITE_COUNT=164,VERIFY_COUNT=14;
    localparam logic [7:0] NONE=0,BAD_FIELD=1,NACK=2,ARBITRATION=3,TIMEOUT=4,ID_MISMATCH=5,READBACK=6,PLATFORM=7,TAG_EXHAUSTED=8,PROTOCOL=9;
    localparam logic [15:0] SENSOR_ID=16'hcd6b;
    function automatic logic [15:0] verify_address(input logic [3:0] index);
        case(index)
            4'd0:verify_address=16'h0100;
            4'd1:verify_address=16'h3018;
            4'd2:verify_address=16'h3031;
            4'd3:verify_address=16'h3037;
            4'd4:verify_address=16'h303f;
            4'd5:verify_address=16'h3208;
            4'd6:verify_address=16'h3209;
            4'd7:verify_address=16'h320a;
            4'd8:verify_address=16'h320b;
            4'd9:verify_address=16'h3210;
            4'd10:verify_address=16'h3211;
            4'd11:verify_address=16'h3212;
            4'd12:verify_address=16'h3213;
            4'd13:verify_address=16'h3221;
            default:verify_address=0;
        endcase
    endfunction
    function automatic logic [7:0] verify_expected(input logic [3:0] index);
        case(index)
            4'd0:verify_expected=8'h01;
            4'd1:verify_expected=8'h60;
            4'd2:verify_expected=8'h0a;
            4'd3:verify_expected=8'h20;
            4'd4:verify_expected=8'h00;
            4'd5:verify_expected=8'h07;
            4'd6:verify_expected=8'h80;
            4'd7:verify_expected=8'h04;
            4'd8:verify_expected=8'h38;
            4'd9:verify_expected=8'h01;
            4'd10:verify_expected=8'h44;
            4'd11:verify_expected=8'h00;
            4'd12:verify_expected=8'h05;
            4'd13:verify_expected=8'h66;
            default:verify_expected=0;
        endcase
    endfunction
    function automatic logic [7:0] verify_bits(input logic [3:0] index);
        case(index)
            4'd0:verify_bits=8'h01;
            4'd1:verify_bits=8'he0;
            4'd2:verify_bits=8'h0f;
            4'd3:verify_bits=8'h60;
            4'd4:verify_bits=8'h80;
            4'd5:verify_bits=8'hff;
            4'd6:verify_bits=8'hff;
            4'd7:verify_bits=8'hff;
            4'd8:verify_bits=8'hff;
            4'd9:verify_bits=8'hff;
            4'd10:verify_bits=8'hff;
            4'd11:verify_bits=8'hff;
            4'd12:verify_bits=8'hff;
            4'd13:verify_bits=8'h66;
            default:verify_bits=0;
        endcase
    endfunction
endpackage
