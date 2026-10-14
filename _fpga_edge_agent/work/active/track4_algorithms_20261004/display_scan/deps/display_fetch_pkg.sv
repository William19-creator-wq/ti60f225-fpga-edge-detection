// FC01/02/07：完整身份公开字典；需求与原row ticket低479位同序。
package display_fetch_pkg;
    typedef struct packed {
        logic [63:0] sequence_id,scan,result_handle,policy;
        logic [194:0] origin;
        logic [10:0] target_y,source_y;
        logic [2:0] mode,required_mask;
    } demand_t;
    typedef struct packed {logic [1:0] bank;demand_t demand;} request_t;
    typedef struct packed {
        logic [63:0] sequence_id,result_handle,policy;
        logic [194:0] origin;
    } frame_ref_t;
    typedef struct packed {
        logic [1:0] bank;
        display_row_pkg::row_ticket_t ticket;
        logic [2:0] status;
        logic row_granted;
        logic [1:0] outcome;
        logic [7:0] reason;
        logic drained,row_returned;
        logic [10:0] prepared,delivered;
        logic [31:0] read_beats;
    } receipt_t;
    localparam logic [2:0] FC_OK=0,FC_FIELD=1,FC_PERMISSION=2,FC_BUSY=3,
        FC_ROW_REJECT=4,FC_CANCEL_NO_START=5,FC_EXHAUSTED=6,FC_DISABLED_NO_START=7;
    function automatic frame_ref_t demand_ref(input demand_t d);
        return {d.sequence_id,d.result_handle,d.policy,d.origin};
    endfunction
    function automatic frame_ref_t ticket_ref(input display_row_pkg::row_ticket_t t);
        return {t.sequence_id,t.result_handle,t.policy,t.origin};
    endfunction
endpackage
