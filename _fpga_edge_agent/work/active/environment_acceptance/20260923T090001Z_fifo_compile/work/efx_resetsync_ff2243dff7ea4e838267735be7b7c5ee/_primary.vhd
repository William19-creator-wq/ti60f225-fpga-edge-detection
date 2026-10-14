library verilog;
use verilog.vl_types.all;
entity efx_resetsync_ff2243dff7ea4e838267735be7b7c5ee is
    generic(
        ASYNC_STAGE     : integer := 2;
        ACTIVE_LOW      : integer := 1
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        d_o             : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of ASYNC_STAGE : constant is 1;
    attribute mti_svvh_generic_type of ACTIVE_LOW : constant is 1;
end efx_resetsync_ff2243dff7ea4e838267735be7b7c5ee;
