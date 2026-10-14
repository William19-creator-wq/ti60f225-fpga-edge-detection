library verilog;
use verilog.vl_types.all;
entity smoke_fifo is
    port(
        prog_full_o     : out    vl_logic;
        full_o          : out    vl_logic;
        empty_o         : out    vl_logic;
        wr_clk_i        : in     vl_logic;
        rd_clk_i        : in     vl_logic;
        wr_en_i         : in     vl_logic;
        rd_en_i         : in     vl_logic;
        wdata           : in     vl_logic_vector(7 downto 0);
        rst_busy        : out    vl_logic;
        rdata           : out    vl_logic_vector(15 downto 0);
        a_rst_i         : in     vl_logic;
        wr_datacount_o  : out    vl_logic_vector(9 downto 0);
        rd_datacount_o  : out    vl_logic_vector(8 downto 0);
        underflow_o     : out    vl_logic;
        overflow_o      : out    vl_logic
    );
end smoke_fifo;
