library verilog;
use verilog.vl_types.all;
entity led_water_display is
    generic(
        LED_WIDTH       : integer := 8
    );
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        led_data        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of LED_WIDTH : constant is 1;
end led_water_display;
