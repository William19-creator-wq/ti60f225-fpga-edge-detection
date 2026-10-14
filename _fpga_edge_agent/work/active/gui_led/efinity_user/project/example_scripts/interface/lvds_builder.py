######################################################################
# Copyright (C) 2017 - 2021 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# lvds_builder.py :
# Demonstrates how to create different LVDS types.
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

print("\n== Create empty design")
device_name = "Ti60F225ES"  # Matches Device name from Efinity's Project Editor
project_name = "lvds_builder"
output_dir = "output_lvds_builder"  # New periphery design will be generated in this directory
design.create(project_name, device_name, output_dir)

# LVDS TX : data output
lvds_tx1 = design.create_block("lvds_tx1", block_type="LVDS_TX")
# LVDS TX : clock output
lvds_tx2 = design.create_block("lvds_tx2", block_type="LVDS_TX", tx_mode="CLKOUT")

# LVDS RX : normal connection
lvds_rx1 = design.create_block("lvds_rx1", block_type="LVDS_RX")
# LVDS RX : PLL clockin
lvds_rx2 = design.create_block("lvds_rx2", block_type="LVDS_RX", rx_conn_type="PLL_CLKIN")

# Bidrectional LVDS : TX = data output, RX : normal connection
lvds_bidir1 = design.create_block("lvds_bidir1", block_type="LVDS_BIDIR")
# Bidrectional LVDS : TX = clock output, RX : normal connection
lvds_bidir2 = design.create_block("lvds_bidir2", block_type="LVDS_BIDIR", tx_mode="CLKOUT")
# Bidrectional LVDS : TX = clock output, RX : normal connection
lvds_bidir3 = design.create_block("lvds_bidir3", block_type="LVDS_BIDIR", rx_conn_type="PLL_CLKIN")
# Bidrectional LVDS : TX = clock output, RX : PLL clock in
lvds_bidir4 = design.create_block("lvds_bidir4", block_type="LVDS_BIDIR", tx_mode="CLKOUT", rx_conn_type="PLL_CLKIN")

design.save()