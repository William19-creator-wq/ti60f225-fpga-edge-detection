######################################################################
# Copyright (C) 2017 - 2020 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# pll_manual_clock.py : Demonstrates how to do manual clock configuration
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
output_dir = "output_auto_clock"  # New periphery design will be generated in this directory
design.create(project_name, device_name, output_dir)

#
# Create PLL
#
design.create_block("pll0", block_type="PLL")
pll_config = {
    "CLKOUT2_EN":"1",   # Enable output clock 2, output clock 0 is enabled by default
    "REFCLK_FREQ":"50",  # Reference clock frequency in MHz
    "M":"16",  # Multiplier
    "N":"1",   # Pre Divider
    "O":"8",   # Post Divider
    "CLKOUT0_DIV":"1",  # Output Clock 0 Divider
    "CLKOUT2_DIV": "2",  # Output Clock 2 Divider
    "CLKOUT0_PHASE":"0",  # Output Clock 0 Phase
    "CLKOUT2_PHASE":"180"  # Output Clock 2 Phase
}
design.set_property("pll0", pll_config, block_type="PLL")

# Calculate all frequencies
design.calc_pll_clock("pll0")

# Inspect frequency-related properties
freq_prop = ["VCO_FREQ", "PLL_FREQ", "CLKOUT0_FREQ", "CLKOUT2_FREQ"]
prop_map = design.get_property("pll0", freq_prop, block_type="PLL")
pprint.pprint(prop_map)

# Save the configured periphery design
design.save()
