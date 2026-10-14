######################################################################
# Copyright (C) 2017 - 2024 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# ti375.py : Demonstrates how to use different Python API for different periphery
#            block that is available for Ti375N1156 device.
#
# Revision : 1.0 - Initial release
######################################################################

# Get access to useful python package
import os
import sys
import pprint

# Tell python where to get Interface Designer's API package
pt_demo = os.environ["EFXPT_HOME"]
sys.path.append(pt_demo + '/bin')

from api_service.design import DesignAPI  # Get access to design database API
from api_service.device import DeviceAPI  # Get access to device database API
import api_service.excp.design_excp as DesignException  # Get access to API exception

is_verbose = True
design = DesignAPI(is_verbose)
device = DeviceAPI(is_verbose)

#create empty design
project_name = "ti375_example"
device_name = "Ti375N1156"
output_dir = "output_Ti375N1156"
design.create(project_name, device_name, output_dir)

# ---------------------------------------------------------------------------- #
#                                    DEVICE                                    #
#                                                                              #
# Check for a list of supported periphery block for this particular device     #
# Ti375N1156                                                                   #
# ---------------------------------------------------------------------------- #
supported_block = design.get_block_type()
print("== Available supported periphery block")
print(supported_block)

# ---------------------------------------------------------------------------- #
#                                     GPIO                                     #
#                                                                              #
# Creates and configures GPIO instance with the following settings:            #
#   - Create a GPIO input with pcie_perstn as the connection type.             #
#   - Assigns "GPIOR_144" as the GPIO instance                                 #
# ---------------------------------------------------------------------------- #
gpio = design.create_input_gpio("pcie_perst_pin")
design.set_property(gpio, "CONN_TYPE", "PCIE_PERSTN")
design.assign_resource(gpio, "GPIOR_144")

# ---------------------------------------------------------------------------- #
#                                      PLL                                     #
#                                                                              #
# Creates and configures 2 PLL instances with the following settings:          #
#   - pll_inst1                                                                #
#       - Needed to configure DDR block                                        #
#       - Assigns "PLL_BL2" as the resource                                    #
#       - Set "External" as the clock source                                   #
#   - pll_inst2                                                                #
#       - Needed to configure SOC block                                        #
#       - Assigns "PLL_BL0" as the resource                                    #
#       - Set "External" as the clock source                                   #
# ---------------------------------------------------------------------------- #
#setting up PLL for DDR
pll_inst_name = "pll_inst1"
design.create_block(pll_inst_name, block_type="PLL")
design.gen_pll_ref_clock(pll_inst_name, pll_res="PLL_BL2", refclk_src="EXTERNAL", refclk_name="pll1_refclk", ext_refclk_no="0")

pll_config = {
    "CLKOUT3_EN":"1",
    "REFCLK_FREQ":"25"
}
design.set_property(pll_inst_name, pll_config, block_type="PLL")
target_freq = {
    "CLKOUT0_FREQ": "100.0",
    "CLKOUT0_PHASE": "0",
    "CLKOUT3_FREQ": "300.0",
    "CLKOUT3_PHASE": "0",
}
calc_result = design.auto_calc_pll_clock(pll_inst_name, target_freq)

#setting up PLL for SOC
pll_inst2_name = "pll_inst2"
design.create_block(pll_inst2_name, block_type="PLL")
design.gen_pll_ref_clock(pll_inst2_name, pll_res="PLL_BL0", refclk_src="EXTERNAL", refclk_name="pll2_refclk", ext_refclk_no="0")
pll2_config = {
    "CLKOUT1_EN": "1",
    "CLKOUT2_EN": "1",
    "REFCLK_FREQ":"25"
}
design.set_property(pll_inst2_name, pll2_config, block_type="PLL")

# ---------------------------------------------------------------------------- #
#                                  OSCILLATOR                                  #
#                                                                              #
# Creates and configures an Oscillator block required for quad blocks:         #
#   - Used by: 10GBASE_KR, SGMII, PMA_DIRECT                                   #
#   - Runs in free-running mode (ENA_PIN set to empty)                         #
#   - Cannot be tri-stated                                                     #
# ---------------------------------------------------------------------------- #
osc_inst_name = "osc_inst1"
design.create_block(osc_inst_name, block_type="OSC")
design.assign_resource(osc_inst_name, "OSC_0", block_type="OSC")
design.set_property(osc_inst_name, "ENA_PIN", "", block_type="OSC")

# ---------------------------------------------------------------------------- #
#                                  LVDS BIDIR                                  #
# Creates and configures LVDS BIDIR instances with the following settings:     #
#   - Assigns "GPIOB_PN_08" as the resource                                    #
# ---------------------------------------------------------------------------- #
lvds_bidir_inst = "lvds_bidir_inst1"
design.create_block(lvds_bidir_inst, block_type="LVDS_BIDIR")
design.assign_resource(lvds_bidir_inst, "GPIOB_PN_08", block_type="LVDS_BIDIR")

# ---------------------------------------------------------------------------- #
#                                      DDR                                     #
#                                                                              #
# Creates and configures Titanium DDR instance with the following settings:    #
#   - Assigns "DDR_0" as the resource                                          #
#   - LPDDR4 as memory type                                                    #
# ---------------------------------------------------------------------------- #
ddr_inst_name = "ddr_inst1"
ddr_inst = design.create_block(ddr_inst_name, block_type="DDR")

resources = device.get_block_resource_name(block_type="DDR")  # Get info for all usable DDR resource
print("== Available DDR resources")
pprint.pprint(resources)
design.assign_resource(ddr_inst_name, "DDR_0", block_type="DDR")

write_prop = {
    "MEMORY_TYPE": "LPDDR4",
    "CLKIN_SEL": "CLKIN 2",
    "TARGET0_EN": "1",
    "TARGET1_EN": "0",
    "AXI0_CLK_INPUT_PIN": "axi0_clk_pin",
    "CTRL_CLK_PIN": "ctrl_status_clk_pin"
}
design.set_property(ddr_inst, write_prop, block_type="DDR")

# ---------------------------------------------------------------------------- #
#                                   QUAD_PCIE                                  #
#                                                                              #
# Creates and configures PCIE instance with the following settings:            #
#   - Assigns "QUAD_2" as the resource                                         #
#   - Enables device property "User Status Control"                            #
# ---------------------------------------------------------------------------- #
print("\n== Inspect QUAD resource")
quad_pcie_res_list = device.get_block_resource_name(block_type="QUAD_PCIE")
pprint.pprint(quad_pcie_res_list)

pcie_inst = "pcie_inst1"
design.create_block(pcie_inst, block_type="QUAD_PCIE")
design.assign_resource(pcie_inst, "QUAD_2", block_type="QUAD_PCIE")

write_prop_pcie = {
    "AXI_CLK_PIN": "axi_clk_pin",
    "USER_APB_CLK_PIN": "apb_clk_pin_Q2"
}
design.set_property(pcie_inst, write_prop_pcie, block_type="QUAD_PCIE")

design.set_device_property("cfg", "STATUS_CTRL_EN", "1", "RU")
print("\n== Inspect Enable User Status Control property")
pprint.pprint(design.get_device_property(pcie_inst, "STATUS_CTRL_EN", "RU"))

# ---------------------------------------------------------------------------- #
#                                  PMA DIRECT                                  #
#                                                                              #
# Creates and configures PMA DIRECT instances with the following settings:     #
#   - 4 PMA DIRECT instances (4 lanes)                                         #
#   - Assigns all 4 instances to QUAD 1 resource                               #
#   - Selects preset for PMA DIRECT base settings                              #
# ---------------------------------------------------------------------------- #
pma_list = [f"pma_direct_inst{i}" for i in range(1, 5)]

quad_pma_direct_res_list = device.get_block_resource_name(block_type="PMA_DIRECT")
print("\n== Available PMA Direct resources")
print(quad_pma_direct_res_list)

res_info_map = device.get_block_resource("Q1_LN0", "PMA_DIRECT")
print("\n== Inspect Q1_LN0 resource")
pprint.pprint(res_info_map)

for idx, pma_inst in enumerate(pma_list, 0):
    design.create_block(pma_inst, block_type="PMA_DIRECT")
    design.assign_resource(pma_inst, f"Q1_LN{idx}", block_type="PMA_DIRECT")

    # Print out all the available PMA DIRECT presets.
    # pprint.pprint(design.get_all_preset_info(pma_inst, block_type="PMA_DIRECT"))

    write_prop = {
        "RX_CLK_CONN_TYPE": "gclk",
        "USER_APB_CLK_PIN": "test_apb_pin",
        "APB_EN": "1",
        "RAW_SERDES_TX_CLK_PIN": f"int_tx_ln{idx}_clk_pin",
        "RAW_SERDES_RX_CLK_PIN": f"int_rx_ln{idx}_clk_pin"
    }
    design.set_property(pma_inst, write_prop, block_type="PMA_DIRECT")
    design.set_preset(pma_inst, "1.25-100.0-20 bits", block_type="PMA_DIRECT") # Set and show preset for current instance
    prop_dict = design.get_preset(pma_inst, block_type="PMA_DIRECT")
    print(f"\n== Current preset applied to {pma_inst} instance")
    pprint.pprint(prop_dict)

# ---------------------------------------------------------------------------- #
#                                      SOC                                     #
#                                                                              #
# Create and configure SOC instance.                                           #
# ---------------------------------------------------------------------------- #
soc_inst_name = "qcrv32_inst1"
design.create_block(soc_inst_name, block_type="SOC")
design.assign_resource(soc_inst_name, "SOC_0", block_type="SOC")
design.set_property(soc_inst_name, "MEM_CLK_SOURCE", "Clock 0", block_type="SOC")
design.set_property(soc_inst_name, "SYS_CLK_SOURCE", "Clock 0", block_type="SOC")

write_prop = {
    "IO_PERIPHERALCLK_PIN": "periphery_ctrl_clk_pin",
    "IO_PERIPHERALCLK_INVERT_EN": "1"
}
design.set_property(soc_inst_name, write_prop, block_type="SOC")

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
#design.check_design()
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