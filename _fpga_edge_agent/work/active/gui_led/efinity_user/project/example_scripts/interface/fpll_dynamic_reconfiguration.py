######################################################################
# Copyright (C) 2017 - 2024 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# fpll_dynamic_reconfiguration.py : Demonstrates how to use FPLL dynamic reconfiguration.
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
import api_service.excp.design_excp as APIExcp  # Get access to API exception

is_verbose = True
design = DesignAPI(is_verbose)

# Create empty design
projet_name = "pll_ssc"
device_name = "Ti375N1156"
output_dir = "output_pll_ssc"
design.create(projet_name, device_name, output_dir)

# print(design.get_block_type())

#
# Create PLL
#
pll_inst = "pll_inst1"
design.create_block(pll_inst, block_type="PLL")
design.gen_pll_ref_clock(pll_inst, pll_res="PLL_BL2", refclk_src="EXTERNAL", refclk_name="pll1_refclk", ext_refclk_no="0")

writepll_config = {
    "SSC_MODE": "STATIC",
    "CLKOUT1_EN":"1",
    "REFCLK_FREQ":"25",
    "FEEDBACK_CLK": "CLK1",
    "FRACTIONAL_MODE_EN": "1",
    "FRACTIONAL_COEFFICIENT": "0"
}
design.set_property(pll_inst, writepll_config, block_type="PLL")

target_freq = {
    "CLKOUT0_FREQ": "100.0",
    "CLKOUT0_PHASE": "0",
    "CLKOUT1_FREQ": "100.0",
    "CLKOUT1_PHASE": "0",
}
calc_result = design.auto_calc_pll_clock(pll_inst, target_freq)

write_dynamic_config = {
    "DYNAMIC_CFG_EN": "1",
    "CFG_CLK_PIN": "pll_inst1_CFG_CLK",
    "CFG_DATA_IN_PIN": "pll_inst1_CFG_DATA_IN",
    "CFG_DATA_OUT_PIN": "pll_inst1_CFG_DATA_OUT",
    "CFG_SEL_PIN": "pll_inst1_CFG_SEL",
    "DYN_CLK_SEL_PIN": "pll_inst1_CLKSEL",
    "RSTN_PIN": "pll_inst1_RSTN",
    "CLKOUT1_PDIV": "13",
    "CLKOUT1_SDIV": "14",
}
design.set_property(pll_inst, write_dynamic_config, block_type="PLL")


design.check_design()
design.export_design()
design.save()
