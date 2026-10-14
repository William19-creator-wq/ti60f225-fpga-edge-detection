// DR01..07：全身份行票据；pair54={ann4,edge2,rgb48}，低lane0。
package display_row_pkg;
    typedef struct packed {
        logic [63:0] generation,sequence_id,scan,result_handle,policy;
        logic [194:0] origin;
        logic [10:0] target_y,source_y;
        logic [2:0] mode,required_mask;
    } row_ticket_t;
    typedef struct packed {row_ticket_t ticket;logic [1:0] kind;} row_return_t;
    typedef struct packed {logic [53:0] data;logic [9:0] address;logic error;} read_record_t;
    localparam logic [2:0] ROW_OK=0,ROW_FIELD=1,ROW_IDENTITY=2,ROW_EXHAUSTED=3;
    localparam logic [1:0] ROW_CONSUMED=0,ROW_DISCARDED=1;
endpackage
