######################################################################
# Copyright (C) 2017 - 2020 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# query_ptdemo.py : Get information from pt_demo periphery design
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
from api_service.api_info import APIVersion  # Get access to API version

is_verbose = True  # Set to True to see detail messages from API engine
design = DesignAPI(is_verbose)
device = DeviceAPI(is_verbose)

#
# Check API version
#
api_version = APIVersion()
print("Get current version: " + api_version.get_current_version())

api_version_info = api_version.get_current_version_info()
print("Get Major No: {}".format(api_version_info.get_major_no()))
print("Get Minor No: {}".format(api_version_info.get_minor_no()))
print("Get Revision No: {}".format(api_version_info.get_revision_no()))

#
# Query design data
#
# Load pt_demo design
efx_home = os.environ['EFINITY_HOME']
design_file = efx_home + "/project/pt_demo/pt_demo.peri.xml"
design.load(design_file)

# Get resource info for GPIO_13
res_info_map = device.get_gpio_resource("GPIOL_13")
pprint.pprint(res_info_map)

# Inspect all property name for GPIO
prop_map = design.get_all_property(block_type="GPIO")
pprint.pprint(prop_map)

# Get global reset
reset_gpio = design.get_gpio("resetn")
if reset_gpio is None:
    print("Cannot find global reset")
else:

    # Check object type
    obj_type = design.get_object_block_type(reset_gpio)
    print("reset_gpio object type=" + obj_type)

    # Get single property
    prop_map = design.get_property(reset_gpio, "IO_STANDARD")
    io_std = prop_map.get("IO_STANDARD")
    print("resetn io_std=" + io_std)

    # Get multiple properties in a single call
    prop_map = design.get_property(reset_gpio, ["IO_STANDARD", "SCHMITT_TRIGGER"])
    io_std = prop_map.get("IO_STANDARD")
    schmitt_trig = prop_map.get("SCHMITT_TRIGGER")
    print("resetn io_std=" + io_std)
    print("resetn schmitt_trigger=" + schmitt_trig)

# Inspect Oscillator
prop_map = design.get_all_property(block_type="OSC")
pprint.pprint(prop_map)

osc_inst = design.get_block("osc0", block_type="OSC")
if osc_inst is None:
    print("Cannot find osc0")
else:
    # Get the property
    prop_map = design.get_property(osc_inst, ["RESOURCE", "CLKOUT_PIN"])
    osc_def = prop_map.get("RESOURCE")
    clock_name = prop_map.get("CLKOUT_PIN")
    print("osc0 resource=" + osc_def + " : clock name=" + clock_name)


