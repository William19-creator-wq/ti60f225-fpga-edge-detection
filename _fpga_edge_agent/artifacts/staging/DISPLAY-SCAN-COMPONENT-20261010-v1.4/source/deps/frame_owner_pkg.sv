// FO01..07：原子帧账本的公开编码；packed字段从高到低。
package frame_owner_pkg;
    localparam integer CMD_BITS=941,REPLY_BITS=942;
    typedef enum logic [3:0] {ALLOC_SOURCE,SOURCE_EOF,SOURCE_END,ALLOC_RESULT,RESULT_END,
        OFFER,APPLY,DROP_RESULT,RETIRE,FREEZE,RESUME,BARRIER} operation_t;
    typedef enum logic [3:0] {OK,NO_SPACE,NO_SOURCE,STATE,IDENTITY,FIELD,NOT_READY,
        EXHAUSTED,QUARANTINED,ALREADY} status_t;
    typedef enum logic [2:0] {S_FREE,S_WRITING,S_DRAIN,S_COMPLETE,S_BAD,S_Q} source_state_t;
    typedef enum logic [2:0] {R_FREE,R_WORKING,R_DONE,R_OFFERED,R_DISPLAY,R_RETIRING,R_Q} result_state_t;
    typedef struct packed {
        logic [3:0] op;logic [7:0] flags;
        logic [63:0] source_handle,result_handle;logic [194:0] origin;
        logic [141:0] cj;logic [399:0] body;logic [63:0] policy;
    } command_t;
    typedef struct packed {
        logic [3:0] op,status;logic [63:0] source_handle,result_handle;
        logic [194:0] origin;logic [141:0] cj;logic [399:0] body;logic [63:0] policy;
        logic [2:0] source_slot;logic [1:0] result_slot;
    } reply_t;
    typedef struct packed {
        source_state_t state;logic [63:0] handle,frame_epoch;
    } source_t;
    typedef struct packed {
        result_state_t state;logic [63:0] handle;logic [2:0] source_slot;
        logic [77:0] config_snapshot;logic [111:0] render_snapshot;logic [63:0] policy;
    } result_t;
endpackage
