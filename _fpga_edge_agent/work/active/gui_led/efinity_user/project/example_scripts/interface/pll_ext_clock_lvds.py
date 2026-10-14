######################################################################
# Copyright (C) 2017 - 2021 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# pll_ext_clock_lvds.py :
# Demonstrates how to configure external clock source using LVDS.
# Currently LVDS is only supported for Titanium.
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
device_name = "Ti60F225"  # Matches Device name from Efinity's Project Editor
project_name = "pll_demo_with_lvds_refclk"
output_dir = "output_ext_clock_lvds"  # New periphery design will be generated in this directory
design.create(project_name, device_name, output_dir)

#
# Create PLL with LVDS RX reference clock
#
design.create_block("pll0", block_type="PLL")

# Create external clock source using external clock 0
# The external clock LVDS RX will be auto-generated
design.gen_pll_ref_clock("pll0", pll_res="PLL_TL0", refclk_src="EXTERNAL", refclk_name="pll0_refclk", ext_refclk_no="0", ext_refclk_type="LVDS_RX")

# Trace all auto-generated clock source
# This will return a LVDS
clksrc_info = design.trace_ref_clock("pll0", block_type="PLL")
pprint.pprint(clksrc_info)

# Inspect clock source-related properties
clock_source_prop = ["REFCLK_SOURCE", "EXT_CLK"]
prop_map = design.get_property("pll0", clock_source_prop, block_type="PLL")
pprint.pprint(prop_map)

#
# Create PLL with LVDS BIDIR reference clock
#
design.create_block("pll1", block_type="PLL")

# Create external clock source using external clock 0
# The external clock LVDS BIDIR will be auto-generated and its RX will be configured
design.gen_pll_ref_clock("pll1", pll_res="PLL_BR0", refclk_src="EXTERNAL", refclk_name="pll1_refclk", ext_refclk_no="0", ext_refclk_type="LVDS_BIDIR")

# Trace all auto-generated clock source
# This will return a LVDS
clksrc_info = design.trace_ref_clock("pll1", block_type="PLL")
pprint.pprint(clksrc_info)

# Inspect clock source-related properties
clock_source_prop = ["REFCLK_SOURCE", "EXT_CLK"]
prop_map = design.get_property("pll1", clock_source_prop, block_type="PLL")
pprint.pprint(prop_map)

# Save the configured periphery design
design.save()