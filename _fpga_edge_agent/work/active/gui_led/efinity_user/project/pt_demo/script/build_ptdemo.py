######################################################################
# Copyright (C) 2017 - 2020 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# build_ptdemo.py : pt_demo periphery design builder
#
# Revision : 1.0 - Initial release
# Revision : 2.0 - Add PLL and Oscillator
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
device = DeviceAPI(is_verbose)

# Create empty design
device_name = "T8F81"  # Matches Device name from Efinity's Project Editor
project_name = "pt_demo"
output_dir = "output"  # New pt_demo periphery design will be generated in this directory
design.create(project_name, device_name, output_dir)

# Create busses and GPIOs
design.create_output_gpio("Fled", 3, 0)
design.create_output_gpio("Oled", 3, 0)
design.create_inout_gpio("Sled", 3, 0)
design.create_clockout_gpio("Oclk_out")
design.create_global_control_gpio("resetn")

# Configure property
design.set_property("Fled", "OUT_REG", "REG")  # Set output to be registered
design.set_property("Fled", "OUT_CLK_PIN", "Fclk")  # Set output clock pin name
design.set_property("Oclk_out", "OUT_CLK_PIN", "Oclk")  # Set output clock pin name

# Pin assignment
design.assign_pkg_pin("Oled[0]", "H4")
design.assign_pkg_pin("Oled[1]", "J4")
design.assign_pkg_pin("Oled[2]", "A5")
design.assign_pkg_pin("Oled[3]", "C5")

design.assign_pkg_pin("Sled[0]", "E6")
design.assign_pkg_pin("Sled[1]", "G4")
design.assign_pkg_pin("Sled[2]", "E2")
design.assign_pkg_pin("Sled[3]", "G9")

design.assign_pkg_pin("Fled[0]", "J2")
design.assign_pkg_pin("Fled[1]", "C2")
design.assign_pkg_pin("Fled[2]", "F8")
design.assign_pkg_pin("Fled[3]", "D8")

design.assign_pkg_pin("resetn", "F1")
design.assign_pkg_pin("Oclk_out", "D6")

# Create PLL
design.create_block("pll0", block_type="PLL")

# Create PLL reference clock
# This will automatically configure its GPIO and assign resource to the PLL
design.gen_pll_ref_clock("pll0", pll_res="PLL_0", refclk_res="GPIOL_20", refclk_name="pll_clkin")

# Use trace function to find the PLL reference clock ie the GPIO
clksrc_info = design.trace_ref_clock("pll0", block_type="PLL")
pprint.pprint(clksrc_info)

# Enable PLL Output Clock 0 and 2
pll_prop = {
    "RSTN_PIN":"pll_resetn",
    "LOCKED_PIN":"locked",
    "CLKOUT0_EN": "1",
    "CLKOUT0_PIN": "Fclk",
    "CLKOUT2_EN": "1",
    "CLKOUT2_PIN": "Sclk"
}
design.set_property("pll0", pll_prop, block_type="PLL")

#
# Configure PLL clock manually
#
clock_prop = {
    "REFCLK_FREQ":"50",
    "M":"125",
    "N":"5",
    "O":"2",
    "CLKOUT0_DIV": "4",
    "CLKOUT2_DIV":"8"
}
design.set_property("pll0", clock_prop, block_type="PLL")

# Verify configuration, calculate frequencies based on current setting
freq_prop_map = design.calc_pll_clock("pll0")
pprint.pprint(freq_prop_map)

# Create oscillator
design.create_block("osc0", block_type="OSC")
design.set_property("osc0", "CLKOUT_PIN", "Oclk", block_type="OSC")

# Check design, generate constraints and reports
design.generate(enable_bitstream=False)

# Save the configured periphery design
design.save()