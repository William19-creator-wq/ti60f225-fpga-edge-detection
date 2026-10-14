library verilog;
use verilog.vl_types.all;
entity efx_fifo_bin2gray_ff2243dff7ea4e838267735be7b7c5ee is
    generic(
        WIDTH           : integer := 5
    );
    port(
        gray_o          : out    vl_logic_vector;
        bin_i           : in     vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of WIDTH : constant is 1;
end efx_fifo_bin2gray_ff2243dff7ea4e838267735be7b7c5ee;
