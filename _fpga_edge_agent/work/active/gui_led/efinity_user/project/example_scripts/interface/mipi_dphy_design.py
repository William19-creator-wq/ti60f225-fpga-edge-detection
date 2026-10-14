######################################################################
# Copyright (C) 2017 - 2021 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# mipi_dphy_design.py :
# Demonstrates how to configure Ti60 4-Lanes MIPI D-PHY RX/TX design.
# This is based on MIPI D-PHY IP Core example design.
# efx-mipi-dphy-v1.0
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
device_name = "Ti60F225"  # Matches Device name from Efinity's Project Editor
project_name = "mipi_dphy_design"
output_dir = "output_mipi_dphy"  # New periphery design will be generated in this directory
design.create(project_name, device_name, output_dir)

######################################################################################

print("\n== Build GPIO")
design.create_input_gpio("gpio_inst6")
design.create_output_gpio("led2")
design.create_output_gpio("led3")

print("\n-- Configure GPIO")
design.set_property("gpio_inst6","IN_PIN","reset_n")
led2_prop = {
    "IO_STANDARD":"1.2_V_LVCMOS",
    "OUT_PIN":"led[2]",
    "DRIVE_STRENGTH":"2"
}
design.set_property("led2", led2_prop)

led3_prop = {
    "IO_STANDARD":"1.2_V_LVCMOS",
    "OUT_PIN":"led[3]",
    "DRIVE_STRENGTH":"2"
}
design.set_property("led3", led3_prop)
print("\n== Build GPIO done")

######################################################################################

print("\n== Build PLL")
design.create_block("pll_inst1","PLL")

print("\n-- Generate GPIO clock source for PLL reference clock")
design.gen_pll_ref_clock("pll_inst1", pll_res="PLL_TL0", refclk_src="EXTERNAL", refclk_name="pll_clkin", ext_refclk_no="0")

print("\n-- Configure PLL")
# Enable and configure Output Clock 0
design.set_property("pll_inst1","CLKOUT0_EN","1", block_type="PLL")
pll_outclk0_prop = {
    "CLKOUT0_DIV":"32",
    "CLKOUT0_PIN":"mipi_dphy_tx_SLOWCLK"
}
design.set_property("pll_inst1", pll_outclk0_prop, block_type="PLL")

# Enable and configure Output Clock 1
design.set_property("pll_inst1","CLKOUT1_EN","1", block_type="PLL")
pll_outclk1_prop = {
    "CLKOUT1_DIV":"4",
    "CLKOUT1_PHASE_SETTING":"3",
    "CLKOUT1_PIN":"mipi_dphy_tx_FASTCLK_C"
}
design.set_property("pll_inst1", pll_outclk1_prop, block_type="PLL")

# Enable and configure Output Clock 2
design.set_property("pll_inst1","CLKOUT2_EN","1", block_type="PLL")
pll_outclk2_prop = {
    "CLKOUT2_DIV":"4",
    "CLKOUT2_PHASE_SETTING":"1",
    "CLKOUT2_PIN":"mipi_dphy_tx_FASTCLK_D"
}
design.set_property("pll_inst1", pll_outclk2_prop, block_type="PLL")

# Enable and configure Output Clock 3
design.set_property("pll_inst1","CLKOUT3_EN","1", block_type="PLL")
pll_outclk3_prop = {
    "CLKOUT3_DIV":"32",
    "CLKOUT3_PIN":"mipi_clk"
}
design.set_property("pll_inst1", pll_outclk3_prop, block_type="PLL")

# Set after output clock because of feedback setting
pll_prop = {
    "LOCKED_PIN":"pll_locked",
    "M":"4",
    "N":"1",
    "O":"1",
    "REFCLK_FREQ":"25.0",
    "RSTN_PIN":"pll_rstn",
    "FEEDBACK_MODE":"CORE",
    "FEEDBACK_CLK":"CLK0"
}
design.set_property("pll_inst1", pll_prop, block_type="PLL")

print("\n== Build PLL done")

######################################################################################

print("\n== Build MIPI RX Lane")
design.create_block("mipi_dphy_rx_clk","MIPI_RX_LANE",mode="CLOCK_LANE",conn_type="GCLK")
design.create_block("mipi_dphy_rx_data0","MIPI_RX_LANE",mode="DATA_LANE")
design.create_block("mipi_dphy_rx_data1","MIPI_RX_LANE",mode="DATA_LANE")
design.create_block("mipi_dphy_rx_data2","MIPI_RX_LANE",mode="DATA_LANE")
design.create_block("mipi_dphy_rx_data3","MIPI_RX_LANE",mode="DATA_LANE")

print("\n-- Configure MIPI RX Lane")
mipi_dphy_rx_clk_prop = {
    "DELAY":"5",
    "DELAY_MODE":"STATIC",
    "FIFO":"0",
    "REVERSIBLE":"0"
}
design.set_property("mipi_dphy_rx_clk", mipi_dphy_rx_clk_prop, block_type="MIPI_RX_LANE")

mipi_dphy_rx_data0_prop = {
    "DELAY":"0",
    "DELAY_MODE":"STATIC",
    "FIFO":"1",
    "REVERSIBLE":"0"
}
design.set_property("mipi_dphy_rx_data0", mipi_dphy_rx_data0_prop, block_type="MIPI_RX_LANE")

mipi_dphy_rx_data1_prop = {
    "DELAY":"0",
    "DELAY_MODE":"STATIC",
    "FIFO":"1",
    "REVERSIBLE":"0"
}
design.set_property("mipi_dphy_rx_data1", mipi_dphy_rx_data1_prop, block_type="MIPI_RX_LANE")

mipi_dphy_rx_data2_prop = {
    "DELAY":"0",
    "DELAY_MODE":"STATIC",
    "FIFO":"1",
    "REVERSIBLE":"0"
}
design.set_property("mipi_dphy_rx_data2", mipi_dphy_rx_data2_prop, block_type="MIPI_RX_LANE")

mipi_dphy_rx_data3_prop = {
    "DELAY":"0",
    "DELAY_MODE":"STATIC",
    "FIFO":"1",
    "REVERSIBLE":"0"
}
design.set_property("mipi_dphy_rx_data3", mipi_dphy_rx_data3_prop, block_type="MIPI_RX_LANE")

print("\n== Build MIPI RX Lane done")

######################################################################################

print("\n== Build MIPI TX Lane")
design.create_block("mipi_dphy_tx_clk","MIPI_TX_LANE",mode="CLOCK_LANE")
design.create_block("mipi_dphy_tx_data0","MIPI_TX_LANE",mode="DATA_LANE")
design.create_block("mipi_dphy_tx_data1","MIPI_TX_LANE",mode="DATA_LANE")
design.create_block("mipi_dphy_tx_data2","MIPI_TX_LANE",mode="DATA_LANE")
design.create_block("mipi_dphy_tx_data3","MIPI_TX_LANE",mode="DATA_LANE")

print("\n-- Configure MIPI TX Lane")
mipi_dphy_tx_clk_prop = {
    "DELAY":"0",
    "REVERSIBLE":"0",
    "HS_OE_PIN":"mipi_dphy_tx_HS_enable_C",
    "FASTCLK_PIN":"mipi_dphy_tx_FASTCLK_C",
    "SLOWCLK_PIN":"mipi_dphy_tx_SLOWCLK"
}
design.set_property("mipi_dphy_tx_clk", mipi_dphy_tx_clk_prop, block_type="MIPI_TX_LANE")

mipi_dphy_tx_data0_prop = {
    "DELAY":"0",
    "REVERSIBLE":"0",
    "FASTCLK_PIN":"mipi_dphy_tx_FASTCLK_D",
    "SLOWCLK_PIN":"mipi_dphy_tx_SLOWCLK"
}
design.set_property("mipi_dphy_tx_data0", mipi_dphy_tx_data0_prop, block_type="MIPI_TX_LANE")

mipi_dphy_tx_data1_prop = {
    "DELAY":"0",
    "REVERSIBLE":"0",
    "FASTCLK_PIN":"mipi_dphy_tx_FASTCLK_D",
    "SLOWCLK_PIN":"mipi_dphy_tx_SLOWCLK"
}
design.set_property("mipi_dphy_tx_data1", mipi_dphy_tx_data1_prop, block_type="MIPI_TX_LANE")

mipi_dphy_tx_data2_prop = {
    "DELAY":"0",
    "REVERSIBLE":"0",
    "FASTCLK_PIN":"mipi_dphy_tx_FASTCLK_D",
    "SLOWCLK_PIN":"mipi_dphy_tx_SLOWCLK"
}
design.set_property("mipi_dphy_tx_data2", mipi_dphy_tx_data2_prop, block_type="MIPI_TX_LANE")

mipi_dphy_tx_data3_prop = {
    "DELAY":"0",
    "REVERSIBLE":"0",
    "FASTCLK_PIN":"mipi_dphy_tx_FASTCLK_D",
    "SLOWCLK_PIN":"mipi_dphy_tx_SLOWCLK"
}
design.set_property("mipi_dphy_tx_data3", mipi_dphy_tx_data3_prop, block_type="MIPI_TX_LANE")

print("\n== Build MIPI TX Lane done")

######################################################################################
print("\n== Assign resource")

print("\n-- Assign GPIO package pin")
design.assign_pkg_pin("gpio_inst6","C9")
design.assign_pkg_pin("led2","J15")
design.assign_pkg_pin("led3","H15")

print("\n-- Assign MIPI RX Lane resource")
design.assign_resource("mipi_dphy_rx_clk","GPIOB_PN_14","MIPI_RX_LANE")
design.assign_resource("mipi_dphy_rx_data0","GPIOB_PN_12","MIPI_RX_LANE")
design.assign_resource("mipi_dphy_rx_data1","GPIOB_PN_13","MIPI_RX_LANE")
design.assign_resource("mipi_dphy_rx_data2","GPIOB_PN_15","MIPI_RX_LANE")
design.assign_resource("mipi_dphy_rx_data3","GPIOB_PN_17","MIPI_RX_LANE")

print("\n-- Assign MIPI TX Lane resource")
design.assign_resource("mipi_dphy_tx_clk","GPIOB_PN_03","MIPI_TX_LANE")
design.assign_resource("mipi_dphy_tx_data0","GPIOB_PN_00","MIPI_TX_LANE")
design.assign_resource("mipi_dphy_tx_data1","GPIOB_PN_01","MIPI_TX_LANE")
design.assign_resource("mipi_dphy_tx_data2","GPIOB_PN_02","MIPI_TX_LANE")
design.assign_resource("mipi_dphy_tx_data3","GPIOB_PN_04","MIPI_TX_LANE")

print("\n== Assign resource done")

######################################################################################

print("\n== Save, run design check and generate constraint files")
design.save()
design.generate(enable_bitstream=False)
print("\n== MIPI DPHY interface configuration done")












