######################################################################
# Copyright (C) 2017 - 2024 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# Ti180M484.py : Demonstrate how to use different Python API for different
#                periphery block that is available for Ti180M484 device.
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
project_name = "Ti180_example"
device_name = "Ti180M484"
output_dir = "output_Ti180M484"
design.create(project_name, device_name, output_dir)

# ---------------------------------------------------------------------------- #
#                                    DEVICE                                    #
#                                                                              #
# Check for a list of supported periphery block for this particular device     #
# Ti180M484                                                                     #
# ---------------------------------------------------------------------------- #
supported_block = design.get_block_type()
print("== Available supported periphery block")
print(supported_block)

# ---------------------------------------------------------------------------- #
#                                      SEU                                     #
#                                                                              #
# Configures SEU detection with the following settings:                        #
#   - Enables SEU detection                                                    #
#   - SEU detection mode to "NORMAL"                                           #
#   - Set SEU Start detection pin name to "seu_START_test"                     #
# ---------------------------------------------------------------------------- #
design.set_device_property("seu","ENA_DETECT","1","SEU")
design.set_device_property("seu","MODE","MANUAL","SEU")
design.set_device_property("seu","START_PIN","seu_START_test","SEU")

# ---------------------------------------------------------------------------- #
#                                 REMOTE UPDATE                                #
#                                                                              #
# Configures Device Remote Update with the following settings:                 #
#   - Enable Internal Reconfigureation Interface                               #
#   - Set Clock Pin Name to "rem_update_clk"                                   #
#   - Set Image Selector Bus Name to "cfg_CBSEL_test" & enable invert clock    #
# ---------------------------------------------------------------------------- #
design.set_device_property("cfg","RECONFIG_EN","1","RU")
design.set_device_property("cfg","CLK_PIN","rem_update_clk","RU")
design.set_device_property("cfg","CBSEL_PIN","cfg_CBSEL_test","RU")
design.set_device_property("cfg","INVERT_CLK_EN","1","RU")

# ---------------------------------------------------------------------------- #
#                         CLOCK / CONTROL CONFIGURATION                        #
#                                                                              #
# Configures the Dynamic Clock Multiplexers with the following settings:       #
#   - Define Core Clock 3 Pin Name to "rcore_clk"                              #
#   - Enable Dynamic Mux 0                                                     #
#   - Set the Dynamic Clock Mux Select Bus Name & Dynamic Clock Pin Name       #
#   - Assign "Core Clock 3:rcore_clk" to Dynamic Clock Input 0                 #
#   - Assign "OSC_0:osc_inst1_CLKOUT" to Dynamic Clock Input 3                 #
# ---------------------------------------------------------------------------- #
print("\n== List of all the Clock Multiplexer Names")
pprint.pprint(design.get_all_global_mux_name())

design.set_device_property("Right","CORE3_PIN","rcore_clk","CLKMUX")
design.set_device_property("Right","DYN_MUX0_EN","1","CLKMUX")

print("\n== List of all input resources for Clock Input 0 of Dynamic Mux 0")
pprint.pprint(design.get_global_dynamic_mux_input_info(clkmux_name="Right", dynamic_mux="0", clock_input="0"))
design.set_device_property("Right","DYN_MUX0_IN0","4","CLKMUX")
design.set_device_property("Right","DYN_MUX0_IN0_TO_CORE_EN","0","CLKMUX")

design.set_device_property("Right","DYN_MUX0_IN3","5","CLKMUX")
design.set_device_property("Right","DYN_MUX0_IN3_TO_CORE_EN","0","CLKMUX")

design.set_device_property("Right","DYN_MUX0_OUT_PIN","dyn0_rclk_out","CLKMUX")
design.set_device_property("Right","DYN_MUX0_SEL_PIN","dyn0_rclk_sel","CLKMUX")

design.set_device_property("Right","DYN_MUX7_EN","0","CLKMUX")

# ---------------------------------------------------------------------------- #
#                                     GPIO                                     #
#                                                                              #
# Creates and configures GPIO instance with the following settings:            #
#   - Create a GPIO input with mipi_clkin as connection type (GPIOL_28)        #
#   - Create a GPIO input with gclk as connection type (GPIOL_30)              #
# ---------------------------------------------------------------------------- #
design.create_mipi_input_clock_gpio("mipi_clkin_tx")
design.assign_resource("mipi_clkin_tx", "GPIOL_28")

design.create_input_clock_gpio("rem_update_clk")
design.assign_resource("rem_update_clk", "GPIOL_30")

# ---------------------------------------------------------------------------- #
#                                      PLL                                     #
#                                                                              #
# Create and configures PLL instances with the following settings:             #
#   - Enables 4 output clock (CLKOUT0, CLKOUT1, CLKOUT2, CLKOUT3)              #
#   - Assigns "PLL_TL1" as the resource and "EXTERNAL" as the clock source     #
#   - Output Clock 3 connection type as "gclk"                                 #
#   - Renames the output clock                                                 #
# ---------------------------------------------------------------------------- #
pll_inst1 = "pll_inst1"
design.create_block(pll_inst1, block_type="PLL")
design.assign_resource(pll_inst1, "PLL_TL1", block_type="PLL")

write_pll_config = {
    "REFCLK_SOURCE": "EXTERNAL",
    "EXT_CLK": "EXT_CLK0",
    "CLKOUT3_CONN_TYPE": "gclk",
    "CLKOUT1_EN": "1",
    "CLKOUT2_EN": "1",
    "CLKOUT3_EN": "1",
    "CLKOUT4_EN": "1",
    "REFCLK_FREQ": "25"
}
design.set_property(pll_inst1, write_pll_config, block_type="PLL")

target_freq = {
    "CLKOUT0_FREQ": "100.0",
    "CLKOUT1_FREQ": "600.0",
    "CLKOUT2_FREQ": "300.0",
    "CLKOUT3_FREQ": "100.0",
    "CLKOUT4_FREQ": "100.0"
}
design.auto_calc_pll_clock(pll_inst1, target_freq)

output_clk_name = {
    "CLKOUT0_PIN": "pll1_base_clk",
    "CLKOUT1_PIN": "pll1_fast_clk",
    "CLKOUT2_PIN": "pll1_slow_clk",
    "CLKOUT3_PIN": "pll_inst1_CLKOUT3",
    "CLKOUT4_PIN": "lvds_tx_refclk"
}
design.set_property(pll_inst1, output_clk_name, block_type="PLL")

# ---------------------------------------------------------------------------- #
#                                  OSCILLATOR                                  #
#                                                                              #
# Creates and configures an Oscillator block with the following settings:      #
#   - "OSC_0" as the oscillator resource                                       #
# ---------------------------------------------------------------------------- #
design.create_block("osc_inst1", block_type="OSC")
design.assign_resource("osc_inst1", "OSC_0", block_type="OSC")

# ---------------------------------------------------------------------------- #
#                                LVDS / SLVDS TX                               #
#                                                                              #
# Create and configures the LVDS/SLVDS TX block with the following settings:   #
#   - Two LVDS TX instances                                                    #
#   - Assigns "GPIOT_PN_17 & GPIOT_PN_19" as the resources                     #
# ---------------------------------------------------------------------------- #
lvds_tx_inst1 = "lvds_tx_inst1"
design.create_block(lvds_tx_inst1, block_type="LVDS_TX", tx_mode="CLKOUT")
design.assign_resource(lvds_tx_inst1, "GPIOT_PN_17", block_type="LVDS_TX")
design.set_property(lvds_tx_inst1, "TX_SLOWCLK_PIN", "lvds_tx_refclk", block_type="LVDS_TX")

lvds_tx_inst2 = "tx_bypass"
design.create_block(lvds_tx_inst2, block_type="LVDS_TX", tx_mode="DATA")
design.assign_resource(lvds_tx_inst2, "GPIOT_PN_19", block_type="LVDS_TX")

# ---------------------------------------------------------------------------- #
#                                LVDS / SLVDS RX                               #
#                                                                              #
# Create and configures the LVDS/SLVDS RX block with the following settings:   #
#   - lvds_gclk                                                                #
#       - "gclk" as connection type                                            #
#       - Assigns "GPIOT_PN_16" as the resource                                #
#   - lvds_rx_inst4                                                            #
#       - Default LVDS RX settings                                             #
#       - Assigns "GPIOT_PN_20" as the resource                                #
#   - pll_clkin                                                                #
#       - "pll_clkin" as connection type                                       #
#       - Assigns "GPIOT_PN_11" as the resource                                #
# ---------------------------------------------------------------------------- #
lvds_rx_inst1 = "lvds_gclk"
design.create_block(lvds_rx_inst1, block_type="LVDS_RX")
design.assign_resource(lvds_rx_inst1, "GPIOT_PN_16", block_type="LVDS_RX")

write_lvds_rx_prop = {
    "RX_CONN_TYPE": "GCLK",
}
design.set_property(lvds_rx_inst1, write_lvds_rx_prop, block_type="LVDS_RX")

lvds_rx_inst2 = "lvds_rx_inst4"
design.create_block(lvds_rx_inst2, block_type="LVDS_RX")
design.assign_resource(lvds_rx_inst2, "GPIOT_PN_20", block_type="LVDS_RX")

lvds_rx_inst3 = "pll_clkin"
design.create_block(lvds_rx_inst3, block_type="LVDS_RX", rx_conn_type="PLL_CLKIN")
design.assign_resource(lvds_rx_inst3, "GPIOT_PN_11", block_type="LVDS_RX")

# ---------------------------------------------------------------------------- #
#                                 MIPI DPHY TX                                 #
#                                                                              #
# Creates and configures MIPI DPHY TX with the following settings:             #
#   - mipi_dphy_tx_inst1                                                       #
#       - Assigns "MIPI_TX3" as the resource                                   #
#       - Reference Clock Source Type as "gpio" & refers to "mipi_clkin_tx"    #
#       - Set "HS Transmit Byte/Word Clock Pin Name" to "tx1_byte_clk"         #
#   - mipi_dphy_tx_inst3
#       - Assigns "MIPI_TX2" as the resource                                   #
#       - Set Reference Clock Frequency to 27 and type to pll                  #
#       - Reference clock resource refers to "pll_inst1":"pll_inst1_CLKOUT3"   #
#       - Set "HS Transmit Byte/Word Clock Pin Name" to "tx3_byte_clk"         #
# ---------------------------------------------------------------------------- #
mipi_dphy_tx = "mipi_dphy_tx_inst1"
design.create_block(mipi_dphy_tx, block_type="MIPI_DPHY_TX")
design.assign_resource(mipi_dphy_tx, "MIPI_TX3", block_type="MIPI_DPHY_TX")

write_mipi_dphy_tx_prop = {
    "WORD_CLKOUT_HS_PIN": "tx1_byte_clk",
    "WORD_CLKOUT_HS_CONN_TYPE": "rclk",
}
design.set_property(mipi_dphy_tx, write_mipi_dphy_tx_prop, block_type="MIPI_DPHY_TX")

mipi_dphy_tx_2 = "mipi_dphy_tx_inst3"
design.create_block(mipi_dphy_tx_2, block_type="MIPI_DPHY_TX")
design.assign_resource(mipi_dphy_tx_2, "MIPI_TX2", block_type="MIPI_DPHY_TX")

write_mipi_dphy_tx_prop = {
    "REF_CLK_FREQUENCY": "27.0",
    "REF_CLK_SELECT": "pll",
    "WORD_CLKOUT_HS_PIN": "tx3_byte_clk",
    "WORD_CLKOUT_HS_CONN_TYPE": "gclk",
}
design.set_property(mipi_dphy_tx_2, write_mipi_dphy_tx_prop, block_type="MIPI_DPHY_TX")

# ---------------------------------------------------------------------------- #
#                                 MIPI DPHY RX                                 #
#                                                                              #
# Creates and configures MIPI DPHY RX with the following settings:             #
#   - Assigns "MIPI_RX0" as the resource                                       #
#   - Set Configuration Clock Frequency to 80 MHz                              #
#   - Set "HS Receive Byte/Word Clock Pin Name" to "rx2_byte_clk"              #
# ---------------------------------------------------------------------------- #
mipi_dphy_rx = "mipi_dphy_rx_inst1"
design.create_block(mipi_dphy_rx, block_type="MIPI_DPHY_RX")
design.assign_resource(mipi_dphy_rx, "MIPI_RX0", block_type="MIPI_DPHY_RX")

write_mipi_dphy_rx_prop = {
    "CFG_CLK_FREQ": "80",
    "WORD_CLKOUT_HS_PIN": "rx2_byte_clk",
    "WORD_CLKOUT_HS_CONN_TYPE": "rclk",
}
design.set_property(mipi_dphy_rx, write_mipi_dphy_rx_prop, block_type="MIPI_DPHY_RX")

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