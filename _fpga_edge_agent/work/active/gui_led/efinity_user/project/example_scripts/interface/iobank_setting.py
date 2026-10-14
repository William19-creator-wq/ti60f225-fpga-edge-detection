######################################################################
# Copyright (C) 2017 - 2021 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# iobank_setting.py : Demonstrates how to set iobank voltage
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

print("\n== Create empty design")
device_name = "Ti60F225ES"  # Matches Device name from Efinity's Project Editor
project_name = "iobank_setting"
output_dir = "output_iobank_setting"  # New periphery design will be generated in this directory
design.create(project_name, device_name, output_dir)

# Inspect all iobank name
iobank_list = design.get_all_iobank_name()
pprint.pprint(iobank_list)

# Get all I/O Bank voltage setting
bank_voltage_map = design.get_iobank_voltage()
pprint.pprint(bank_voltage_map)

# Get single I/O Bank voltage setting
voltage = design.get_iobank_voltage("1A")
pprint.pprint(voltage)

# Set voltage for one or more I/O Bank
bank_voltage_map = {
    "1A": '1.5',
    "1B": '1.2'
}
design.set_iobank_voltage(bank_voltage_map)

# Set single I/O Bank voltage setting
design.set_iobank_voltage("2A", "1.5")

# Inspect the changes
bank_voltage_map = design.get_iobank_voltage()
pprint.pprint(bank_voltage_map)

design.save()
