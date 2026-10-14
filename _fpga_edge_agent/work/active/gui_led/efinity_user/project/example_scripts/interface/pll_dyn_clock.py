######################################################################
# Copyright (C) 2017 - 2020 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# pll_dyn_clock.py : Demonstrates how to configure dynamic clock source
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

is_verbose = True  # Set to True to see detail messages from API engine
design = DesignAPI(is_verbose)

# Create empty design
device_name = "T20F256"  # Matches Device name from Efinity's Project Editor
project_name = "pll_demo"
output_dir = "output_dyn_clock"  # New periphery design will be generated in this directory
design.create(project_name, device_name, output_dir)

#
# Create PLL
#
design.create_block("pll0", block_type="PLL")

# Create dynamic clock source with 2 core clocks and 2 external clocks
# The external clock GPIO will be auto-generated
# Note:
# External clock 0 requires LVDS RX which is not supported by API yet
# It is listed here to complete the example
design.gen_pll_ref_clock("pll0", pll_res="PLL_BR0", refclk_src="DYNAMIC", refclk_name="ext_clk0", ext_refclk_no="0")
design.gen_pll_ref_clock("pll0", pll_res="PLL_BR0", refclk_src="DYNAMIC", refclk_name="ext_clk1", ext_refclk_no="1")
dyn_clock_pin = {
    "DYN_CLK_SEL_PIN":"clksel",
    "CORE_CLK_PIN":"core_clk1",
    "CORE_CLK1_PIN":"core_clk2"
}
design.set_property("pll0", dyn_clock_pin, block_type="PLL")

# Trace all auto-generated GPIO clock source
clksrc_info = design.trace_ref_clock("pll0", block_type="PLL")
pprint.pprint(clksrc_info)

# Inspect clock source-related properties
clock_source_prop = ["REFCLK_SOURCE", "DYN_CLK_SEL_PIN", "CORE_CLK_PIN", "CORE_CLK1_PIN"]
prop_map = design.get_property("pll0", clock_source_prop, block_type="PLL")
pprint.pprint(prop_map)

# Save the configured periphery design
design.save()