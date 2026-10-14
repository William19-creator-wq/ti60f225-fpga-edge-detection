// R2-D1：仅公共位宽/位序/命名，包内不保存状态、不实现算法。
package r2_protocol_pkg;
    localparam integer CJ_BITS = 142;
    localparam integer FP_BITS = 74;
    localparam integer FJ_BITS = 110;
    localparam integer FS_BITS = 163;
    localparam integer SIDE_BITS = 121;
    localparam integer DERR_BITS = 120;
    localparam integer CS_BITS = 592;
    localparam integer RECORD_BITS = 608;
    localparam integer CLASS_BITS = 125;
    localparam integer GRAD_BITS = 185;
    localparam integer COUNT_BITS = 21;
    // packed 字段从高位到低位声明；x 是 side 的最低11位。
    typedef struct packed {
        logic eof, eol, sof;
        logic [31:0] config_id, frame_id, epoch_id;
        logic [10:0] y, x_even;
    } side_t;
    typedef struct packed {
        logic retain_grad, median_enable;
        logic [10:0] threshold_high, threshold_low, height, width;
        logic [31:0] config_id, frame_id, epoch_id;
    } job_t;
    localparam logic [1:0] DIR_H = 2'b00, DIR_NW_SE = 2'b01,
        DIR_V = 2'b10, DIR_SW_NE = 2'b11;
    localparam logic [1:0] CLASS_NONE = 2'b00, CLASS_WEAK = 2'b01,
        CLASS_STRONG = 2'b10;
    localparam logic [1:0] RECORD_CLASS = 2'b00, RECORD_GRAD = 2'b01,
        RECORD_STATUS = 2'b10;
endpackage
