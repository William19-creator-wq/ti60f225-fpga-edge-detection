######################################################################
# Copyright (C) 2017 - 2020 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# robust_build_ptdemo.py : Handles critical error in building
# pt_demo periphery design.
#
# Revision : 1.0
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
project_name = "pt_demo_error_handling"
output_dir = "output"  # New pt_demo periphery design will be generated in this directory

try:
    design.create(project_name, device_name, output_dir)
except APIExcp.PTAPIException as excp:
    print("Fail to create design : {} Msg={}".format(excp.get_msg_level(), excp.get_msg()))
    sys.exit(1)

# Create busses and GPIOs
design.create_output_gpio("Fled", 3, 0)
design.create_output_gpio("Oled", 3, 0)
design.create_inout_gpio("Sled", 3, 0)
design.create_clockout_gpio("Oclk_out")
design.create_pll_input_clock_gpio("pll_clkin")
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
design.assign_pkg_pin("pll_clkin", "C3")

# Check design, generate constraints and reports
try:
    design.generate(enable_bitstream=False)
except APIExcp.PTDsgCheckException as excp:
    print("Design check fails : {} Msg={}".format(excp.get_msg_level(), excp.get_msg()))
    sys.exit(1)
except APIExcp.PTDsgGenConstException as excp:
    print("Fail to generate constraint : {} Msg={}".format(excp.get_msg_level(), excp.get_msg()))
    sys.exit(1)
except APIExcp.PTDsgGenReportException as excp:
    print("Fail to generate report : {} Msg={}".format(excp.get_msg_level(), excp.get_msg()))
    sys.exit(1)

# Save the configured periphery design
design.save()
