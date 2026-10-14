######################################################################
# Copyright (C) 2017 - 2024 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# T120F576.py : Demonstrate how to use different Python API for different
#               periphery block that is available for T120F576 device.
#
# Revision : 1.0 - Initial release
######################################################################

# Get access to useful python package
import os
import sys
import pprint

# Tell python where to get Interface Designer's API package
pt_home = os.environ['EFXPT_HOME']
sys.path.append(pt_home + "/bin")

from api_service.design import DesignAPI  # Get access to design database API
from api_service.device import DeviceAPI  # Get access to device database API
import api_service.excp.design_excp as DesignException  # Get access to API exception

is_verbose = True
design = DesignAPI(is_verbose)
device = DeviceAPI(is_verbose)

#create design
project_name = "Ti120_example"
device_name = "T120F576"
output_dir = "output_T120F576"
design.create(project_name, device_name, output_dir)

# ---------------------------------------------------------------------------- #
#                                    DEVICE                                    #
#                                                                              #
# Check for a list of supported periphery block for this particular device     #
# T120F576                                                                     #
# ---------------------------------------------------------------------------- #
supported_block = design.get_block_type()
print(supported_block)

# ---------------------------------------------------------------------------- #
#                                     GPIO                                     #
#                                                                              #
# Creates and configures GPIO instance with the following settings:            #
#   - Create a GPIO input with mipi_clkin as the connection type.              #
#   - Assigns "GPIOR_169" as the GPIO instance                                 #
# ---------------------------------------------------------------------------- #
mipi_clk_gpio = design.create_mipi_input_clock_gpio("mipiclkin_gpio")
design.assign_resource(mipi_clk_gpio, "GPIOR_169", block_type="GPIO")

# ---------------------------------------------------------------------------- #
#                                      PLL                                     #
#                                                                              #
# Create and configures PLL instances with the following settings:             #
#   - Enable 3 output clock (CLKOUT0, CLKOUT1, CLKOUT2)                        #
#   - Assigns PLL_BR0 as the resource                                          #
#   - Set "External" as the clock source                                       #
#   - External clock source 0 correspond to "GPIOR_186"                        #
#   - Renames the 3 output clock                                               #
# ---------------------------------------------------------------------------- #
pll_inst = design.create_block("pll1", block_type="PLL")
# When refclk_src="EXTERNAL", a GPIO instance with pll_clkin as connection type will automatically be configured.
design.gen_pll_ref_clock(pll_inst, pll_res="PLL_BR0", refclk_src="EXTERNAL", refclk_name="pll1_refclk", ext_refclk_no="0")

clksrc_info = design.trace_ref_clock(pll_inst, block_type="PLL") # Trace the auto-generated GPIO clock source
pprint.pprint(clksrc_info)

pll_config = {
    "CLKOUT1_EN":"1",
    "CLKOUT2_EN":"1",   # Enable output clock 2, output clock 0 is enabled by default
    "REFCLK_FREQ":"50"  # Reference clock frequency in MHz
}
design.set_property("pll1", pll_config, block_type="PLL")

target_freq = {
    "CLKOUT0_FREQ": "100.0",  # Output Clock 0 frequency in MHz
    "CLKOUT0_PHASE": "0",    # Output Clock 0 phase in degree
    "CLKOUT1_FREQ": "400.0",   # Output Clock 1 frequency in MHz
    "CLKOUT1_PHASE": "90",    # Output Clock 1 phase in degree
    "CLKOUT2_FREQ": "100.0",   # Output Clock 2 frequency in MHz
    "CLKOUT2_PHASE": "0"    # Output Clock 2 phase in degree
}
calc_result = design.auto_calc_pll_clock("pll1", target_freq)

design.set_property("pll1","CLKOUT0_PIN","axi0_clk_pin","PLL")
design.set_property("pll1","CLKOUT1_PIN","test_fastclk_pin","PLL")
design.set_property("pll1","CLKOUT2_PIN","test_slowclk_pin","PLL")

# ---------------------------------------------------------------------------- #
#                                  LVDS TX/RX                                  #
#                                                                              #
# Create and configures LVDS TX instances with the following settings:         #
#   - Create 3 LVDS TX data lane & 1 LVDS TX clock lane                        #
#   - Set some LVDS API property                                               #
# ---------------------------------------------------------------------------- #
lvds_tx_list = [f"lvds_tx_inst{i}" for i in range(1, 4)]

print("\n== Build LVDS Tx : Serial Data Output")
for idx, lvds_inst in enumerate(lvds_tx_list, 1):
    design.create_block(lvds_inst, block_type="LVDS_TX", tx_mode="DATA")
    design.assign_resource(lvds_inst, f"GPIOB_TX0{idx}", block_type="LVDS_TX")
    lvds_ref_clk_out_prop = {
        "TX_EN_SER": "1",
        "TX_OUT_PIN": f"{lvds_inst}_DATA",
        "TX_OUTPUT_LOAD": "7",
        "TX_REDUCED_SWING": "1",
        "TX_SER": "8",
        "TX_FASTCLK_PIN": "test_fastclk_pin",
        "TX_SLOWCLK_PIN": "test_slowclk_pin",
    }
    design.set_property(lvds_inst, lvds_ref_clk_out_prop, block_type="LVDS_TX")

print("\n== Build LVDS Tx : Reference Clock Output")
lvds_clk = design.create_block("lvds_clk", block_type="LVDS_TX", tx_mode="CLKOUT")
design.assign_resource(lvds_clk, "GPIOB_TX04", block_type="LVDS_TX")
lvds_ref_clk_out_prop = {
    "TX_FASTCLK_PIN": "test_fastclk_pin",
    "TX_SLOWCLK_PIN": "test_slowclk_pin",
}
design.set_property(lvds_clk, lvds_ref_clk_out_prop, block_type="LVDS_TX")

# ---------------------------------------------------------------------------- #
#                                  MIPI TX/RX                                  #
#                                                                              #
# Creates and configures MIPI TX/RX instances with the following settings:     #
#   - Assigns "MIPI_TX0" & "MIPI_RX0" as the resources                         #
#   - Set several MIPI API property                                            #
# ---------------------------------------------------------------------------- #
mipi_tx_inst = "mipi_tx_inst1"
design.create_block(mipi_tx_inst, block_type="MIPI_TX")
design.assign_resource(mipi_tx_inst, "MIPI_TX0", block_type="MIPI_TX")

write_data_mipi_tx = {
    "PHY_FREQ": "1500",
    "ESC_CLK_PIN": "esc_clk_pin",
    "PIXEL_CLK_PIN": "pixel_clk_pin"
}
design.set_property(mipi_tx_inst, write_data_mipi_tx, block_type="MIPI_TX")

mipi_rx_inst = "mipi_rx_inst1"
design.create_block(mipi_rx_inst, block_type="MIPI_RX")
design.assign_resource(mipi_rx_inst, "MIPI_RX0", block_type="MIPI_RX")

write_data_mipi_rx = {
    "CAL_CLK_PIN": "dphy_cal_clk_pin",
    "PIXEL_CLK_PIN": "pixel_clk_pin"
}
design.set_property(mipi_rx_inst, write_data_mipi_rx, block_type="MIPI_RX")

# ---------------------------------------------------------------------------- #
#                                     JTAG                                     #
#                                                                              #
# Creates and configures a JTAG instance with the following settings:          #
#   - Assigns JTAG_USER4 as the resource                                       #
#   - Renames TDI pin to "new_pin_name"                                        #
# ---------------------------------------------------------------------------- #
jtag_inst = design.create_block("jtag1", block_type="JTAG")
design.assign_resource(jtag_inst,"JTAG_USER4")
design.set_property(jtag_inst, "TDI", "new_pin_name")


# ---------------------------------------------------------------------------- #
#                                      DDR                                     #
#                                                                              #
# Create and configures a Trion DDR instance with the following settings:      #
#   - Assigns DDR_0 as the resource                                            #
#   - Writes some DDR API property such as the MEMORY_TYPE, PRECHARGE_PD       #
#   - Uses preset to configure basic DDR settings.                             #
# ---------------------------------------------------------------------------- #
ddr_inst_name = "ddr1"
ddr_inst = design.create_block(ddr_inst_name, block_type="DDR")

ddr_resource = "DDR_0"
design.assign_resource(ddr_inst, ddr_resource)
resource = device.get_block_resource(ddr_resource, block_type="DDR")
pprint.pprint(resource)

write_prop = {
    "MEMORY_TYPE": "DDR3",
    "PRECHARGE_PD": "On",
    "TARGET0_EN": "1",
    "TARGET1_EN": "0",
    "AXI0_CLK_INPUT_PIN": "axi0_clk_pin"
}
design.set_property(ddr_inst, write_prop, block_type="DDR")

read_data = [
    "MEMORY_TYPE",
    "PRECHARGE_PD",
    "TARGET1_EN",
    "AXI0_CLK_INPUT_PIN"
]
for prop in read_data:
    prop_dict = design.get_property(ddr_inst, prop, block_type="DDR")
    pprint.pprint(prop_dict)

prop_dict = design.get_all_preset_info(ddr_inst_name) # Get all preset options for current DDR
pprint.pprint(prop_dict)

design.set_preset(ddr_inst_name, "154") # Set and show preset for current DDR
prop_dict = design.get_preset(ddr_inst_name)
pprint.pprint(prop_dict)

# ---------------------------------------------------------------------------- #
#                             DESIGN CHECK & EXPORT                            #
#                                                                              #
# Performs final design check and export steps:                                #
#   1. Check design integrity                                                  #
#   2. Export design as .isf file                                              #
#   3. Generate design constraints                                             #
#   4. Save design                                                             #
#                                                                              #
# Error Handling:                                                              #
#   - Design check failures                                                    #
#   - Constraint generation errors                                             #
#   - Report generation failures                                               #
# ---------------------------------------------------------------------------- #
design.check_design()
design.export_design()

try:
    design.generate(enable_bitstream=False)

except DesignException.PTDsgCheckException as excp:
    print("Design check fails : {} Msg={}".format(excp.get_msg_level(), excp.get_msg()))
    sys.exit(1)

except DesignException.PTDsgGenConstException as excp:
    print("Fail to generate constraint : {} Msg={}".format(excp.get_msg_level(), excp.get_msg()))
    sys.exit(1)

except DesignException.PTDsgGenReportException as excp:
    print("Fail to generate report : {} Msg={}".format(excp.get_msg_level(), excp.get_msg()))
    sys.exit(1)

design.save()