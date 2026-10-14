######################################################################
# Copyright (C) 2017 - 2020 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# pll_core_clock.py : Demonstrates how to configure core clock source
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
output_dir = "output_core_clock"  # New periphery design will be generated in this directory
design.create(project_name, device_name, output_dir)

#
# Create PLL
#
design.create_block("pll0", block_type="PLL")
pll_config = {
    "CLKOUT2_EN":"1",   # Enable output clock 2, output clock 0 is enabled by default
}
design.set_property("pll0", pll_config, block_type="PLL")

# Create core clock source
design.gen_pll_ref_clock("pll0", pll_res="PLL_BR0", refclk_src="CORE")
design.set_property("pll0", "CORE_CLK_PIN", "core_clk", block_type="PLL")

# Inspect clock source-related properties
clock_source_prop = ["REFCLK_SOURCE", "CORE_CLK_PIN"]
prop_map = design.get_property("pll0", clock_source_prop, block_type="PLL")
pprint.pprint(prop_map)

# Save the configured periphery design
design.save()