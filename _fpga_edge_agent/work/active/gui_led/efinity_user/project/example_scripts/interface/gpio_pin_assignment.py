######################################################################
# Copyright (C) 2017 - 2021 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# gpio_pin_assignment.py
# - Demonstrates how to do pin assignment based on csv input file
#
# Revision : 1.0 - Initial release
######################################################################

# Get access to useful python package
import os
import sys
import pprint
import csv

# Tell python where to get Interface Designer's API package
pt_home = os.environ['EFXPT_HOME']
sys.path.append(pt_home + "/bin")

from api_service.design import DesignAPI  # Get access to design database API
from api_service.device import DeviceAPI  # Get access to device database API
import api_service.excp.design_excp as APIExcp  # Get access to API exception
from api_service.api_info import APIVersion  # Get access to API version

is_verbose = True  # Set to True to see detail messages from API engine
design = DesignAPI(is_verbose)
device = DeviceAPI(is_verbose)

# Load design
efx_home = os.environ['EFINITY_HOME']
design_file = efx_home + "/project/pt_demo/pt_demo.peri.xml"
design.load(design_file)

# Read csv pin data and store it in python dictionary
csv_filename = "gpio_pin_data.csv"
with open(csv_filename, mode='r', encoding='UTF-8') as inp:
    print(f"Read csv file: {csv_filename}")
    reader = csv.reader(inp)
    gpio_pin_data = {rows[0]:rows[1] for rows in reader}

# Print out the content of the dictionary, using pprint for pretty-printing
pprint.pprint(gpio_pin_data)

# Get all gpio instance and assign its package pin based on the csv file data
gpio_list = design.get_all_gpio()

for gpio in gpio_list:
    # Get gpio instance name
    prop_map = design.get_property(gpio, "NAME", block_type="GPIO")
    gpio_name = prop_map["NAME"]

    # Clear current pin assignment
    design.assign_pkg_pin(gpio,"")

    # Get pin name, if doesn't exist, set default to empty name
    pin_name = gpio_pin_data.get(gpio_name,"")
    if pin_name != "": # Assign only if pin name is not empty
        print(f"Assign {pin_name} to {gpio_name}")
        design.assign_pkg_pin(gpio, pin_name)

# Save to file.
# If you have Interface Designer opened, it will inform that the file has changed and you need to reopen.
design.save()

# Check design, generate constraints and reports
design.generate(enable_bitstream=False)

print("Finished assignment")

