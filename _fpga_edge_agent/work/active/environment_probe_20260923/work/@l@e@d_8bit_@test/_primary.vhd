library verilog;
use verilog.vl_types.all;
entity LED_8bit_Test is
    port(
        pll_inst1_CLKOUT0: in     vl_logic;
        pll_inst1_LOCKED: in     vl_logic;
        led_data        : out    vl_logic_vector(7 downto 0)
    );
end LED_8bit_Test;
