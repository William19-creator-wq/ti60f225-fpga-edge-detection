######################################################################
# Copyright (C) 2017 - 2020 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# pll_ext_clock_gpio.py :
# Demonstrates how to configure external clock source using GPIO
#
# Revision : 1.0 - Initial release
# Revision : 1.1 - Update script name to indicate this is for GPIO clock source
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
output_dir = "output_ext_clock"  # New periphery design will be generated in this directory
design.create(project_name, device_name, output_dir)

#
# Create PLL
#
design.create_block("pll0", block_type="PLL")

# Create external clock source using external clock 1
# The external clock GPIO will be auto-generated
design.gen_pll_ref_clock("pll0", pll_res="PLL_BR0", refclk_src="EXTERNAL", refclk_name="ext_clk1", ext_refclk_no="1")

# Trace all auto-generated clock source
# This will return a GPIO
clksrc_info = design.trace_ref_clock("pll0", block_type="PLL")
pprint.pprint(clksrc_info)

# Inspect clock source-related properties
clock_source_prop = ["REFCLK_SOURCE", "EXT_CLK"]
prop_map = design.get_property("pll0", clock_source_prop, block_type="PLL")
pprint.pprint(prop_map)

# Save the configured periphery design
design.save()