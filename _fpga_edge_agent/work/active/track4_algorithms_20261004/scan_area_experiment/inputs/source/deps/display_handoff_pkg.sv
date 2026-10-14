// DH01..08：当前owner942整包，不缩短身份；control和candidate关闭分开。
package display_handoff_pkg;
    localparam integer REQUEST_BITS=1137,RESPONSE_BITS=1207;
    localparam logic [2:0] HC_OFFER=0,HC_PREPARE=1,HC_COMMIT=2,HC_RESUME=3;
    localparam logic [2:0] HC_OK=0,HC_FIELD=1,HC_IDENTITY=2,HC_STATE=3,HC_CANCELED=4,HC_EXHAUSTED=5;
    typedef struct packed {
        logic [2:0] kind;logic [63:0] sequence_id,cause,target_policy;logic [941:0] bundle;
    } route_request_t;
    typedef struct packed {
        logic [2:0] kind,status;logic [63:0] sequence_id,cause,policy;logic [941:0] bundle;
        logic [63:0] previous_result;logic has_active,snapshot_held,candidate_closed;
    } route_response_t;
endpackage
