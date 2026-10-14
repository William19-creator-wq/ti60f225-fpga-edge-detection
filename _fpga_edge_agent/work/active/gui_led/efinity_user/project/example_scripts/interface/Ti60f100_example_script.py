######################################################################
# Copyright (C) 2017 - 2024 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# Ti60F100S3F2.py : Demonstrate how to use different Python API for different
#                   periphery block that is available for Ti60F100S3F2 device.
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
import api_service.excp.design_excp as DesignException  # Get access to API exception

is_verbose = True
design = DesignAPI(is_verbose)
device = DeviceAPI(is_verbose)

#create design
project_name = "Ti60_example"
device_name = "Ti60F100S3F2"
output_dir = "output_Ti60F100S3F2"
design.create(project_name, device_name, output_dir)

# ---------------------------------------------------------------------------- #
#                                    DEVICE                                    #
#                                                                              #
# Check for a list of supported periphery block for this particular device     #
# Ti60F100                                                                     #
# ---------------------------------------------------------------------------- #
supported_block = design.get_block_type()
print("== Available supported periphery block")
print(supported_block)

# ---------------------------------------------------------------------------- #
#                                      SEU                                     #
#                                                                              #
# Configures SEU detection with the following settings:                        #
#   - Enables SEU detection                                                    #
#   - SEU detection mode to "NORMAL"                                           #
#   - Set SEU Start detection pin name to "seu_START_test"                     #
# ---------------------------------------------------------------------------- #
design.set_device_property("seu","ENA_DETECT","1","SEU")
design.set_device_property("seu","MODE","MANUAL","SEU")
design.set_device_property("seu","START_PIN","seu_START_test","SEU")

# ---------------------------------------------------------------------------- #
#                                    IO BANK                                   #
#                                                                              #
# Configures Voltage level of the IO Bank                                      #
# ---------------------------------------------------------------------------- #
print("\n== All IO BANK voltage settings")
pprint.pprint(design.get_iobank_voltage())

design.set_iobank_voltage("3A", "1.2")
design.set_iobank_voltage("3B_4A", "1.2")

# ---------------------------------------------------------------------------- #
#                                     GPIO                                     #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
#                                      PLL                                     #
#                                                                              #
# Creates and configures PLL instances with the following settings:            #
#   - hyperram_pll                                                             #
#       - "PLL_TR0" as the resource & "EXTERNAL" as the clock source           #
#       - Use to configure the clock needed by HYPERRAM instance               #
#   - pll_mipi_tx                                                              #
#       - "PLL_BR0" as the resource & "CORE" as the clock source               #
#       - Use to configure the clock needed by MIPI TX instance                #
# ---------------------------------------------------------------------------- #
pll_inst = "hyperram_pll"
design.create_block(pll_inst, block_type="PLL")
design.gen_pll_ref_clock(pll_inst, pll_res="PLL_TR0", refclk_src="EXTERNAL", refclk_name="pll1_refclk", ext_refclk_no="0")
design.set_property("pll1_refclk","IO_STANDARD","1.2_V_LVCMOS")

write_pll_prop = {
    "CLKOUT1_EN": "1",
    "CLKOUT3_EN": "1",
    "REFCLK_FREQ": "25",
}
design.set_property(pll_inst, write_pll_prop, block_type="PLL")
design.calc_pll_clock(pll_inst)

target_freq = {
    "CLKOUT1_FREQ": "100.0",   # Output Clock 1 frequency in MHz
    "CLKOUT3_FREQ": "100.0",   # Output Clock 3 frequency in MHz
}
calc_result = design.auto_calc_pll_clock(pll_inst, target_freq)

write_output_name_prop = {
    "CLKOUT1_PIN": "cal_clk_pin",
    "CLKOUT1_DYNPHASE_EN": "1",
    "PHASE_SHIFT_ENA_PIN": "pll_inst1_SHIFT_ENA",
    "PHASE_SHIFT_SEL_PIN": "pll_inst1_SHIFT_SEL",
    "PHASE_SHIFT_PIN": "pll_inst1_SHIFT",
    "CLKOUT3_PIN": "core_clk",
}
design.set_property(pll_inst, write_output_name_prop, block_type="PLL")


pll_inst2 = "pll_mipi_tx"
design.create_block(pll_inst2, block_type="PLL")
design.gen_pll_ref_clock(pll_inst2, pll_res="PLL_BR0", refclk_src="CORE")
design.set_property(pll_inst2, "CORE_CLK_PIN", "core_clk", block_type="PLL")

write_pll_prop = {
    "CLKOUT0_EN" : "1",
    "CLKOUT1_EN": "1",
    "CLKOUT2_EN" : "1",
    "CLKOUT3_EN": "1",
    "REFCLK_FREQ": "25",
    "CLKOUT1_PIN": "mipi_fast_clk",
    "CLKOUT2_PIN": "mipi_slow_clk",
}
design.set_property(pll_inst2, write_pll_prop, block_type="PLL")

write_pll_prop = {
    "N" : "1",
    "M": "4",
    "O" : "8",
    "CLKOUT0_DIV": "4",
    "CLKOUT1_DIV": "4",
    "CLKOUT2_DIV": "2",
    "CLKOUT3_DIV": "8",
    "CLKOUT0_PHASE_STEP": "2",
    "CLKOUT1_PHASE_STEP": "4",
    "CLKOUT2_PHASE_STEP": "1",
    "CLKOUT3_PHASE_STEP": "0",
    "CLKOUT0_PIN": "i_mipi_txc_pclk",
    "CLKOUT1_PIN": "i_mipi_txc_sclk",
    "CLKOUT2_PIN": "i_mipi_txd_sclk",
    "CLKOUT3_PIN": "i_mipi_txd_pclk",
}
design.set_property(pll_inst2, write_pll_prop, block_type="PLL")

# ---------------------------------------------------------------------------- #
#                                 MIPI TX LANE                                 #
#                                                                              #
# Creates and configures MIPI TX Lane with the following settings:             #
#   - mipi_txd0                                                                #
#       - Configured as MIPI TX Data lane                                      #
#       - "GPIOR_PN_05" as resource                                            #
#   - mipi_txc                                                                 #
#       - Configured as MIPI TX Clock lane                                     #
#       - "GPIOR_PN_06" as resource                                            #
# ---------------------------------------------------------------------------- #
mipi_txd0 = design.create_block("mipi_txd0", block_type="MIPI_TX_LANE")
design.assign_resource(mipi_txd0, "GPIOR_PN_05", block_type="MIPI_TX_LANE")
mipi_txd0_prop = {
    # Parameters
    "DELAY":"0",
    "REVERSIBLE":"0",
    # Pins : All pins uses default except for the clocks
    "FASTCLK_PIN":"i_mipi_txd_sclk",
    "SLOWCLK_PIN": "i_mipi_txd_pclk"
}
design.set_property(mipi_txd0, mipi_txd0_prop, block_type="MIPI_TX_LANE")

mipi_txc = design.create_block("mipi_txc", mode="CLOCK_LANE", block_type="MIPI_TX_LANE")
design.assign_resource(mipi_txc, "GPIOR_PN_06", block_type="MIPI_TX_LANE")
mipi_txc_prop = {
    # Parameters
    "DELAY":"0",
    # Pins : All pins uses default except for the clocks
    "FASTCLK_PIN":"i_mipi_txc_sclk",
    "SLOWCLK_PIN": "i_mipi_txc_pclk"
}
design.set_property(mipi_txc, mipi_txc_prop, block_type="MIPI_TX_LANE")

# ---------------------------------------------------------------------------- #
#                                 MIPI RX LANE                                 #
#                                                                              #
# Creates and configures MIPI RX Lane with the following settings:             #
#   - mipi_rx_ln_inst1                                                         #
#       - Configured as MIPI RX Data lane                                      #
#       - "GPIOR_PN_14" as resource                                            #
#   - mipi_rx_ln_inst2                                                         #
#       - Configured as MIPI TX Clock lane                                     #
#       - Set Clock lane connection type to "gclk"                             #
#       - "GPIOR_PN_10" as resource                                            #
# ---------------------------------------------------------------------------- #
cam_rx_data0 = design.create_block("mipi_rx_ln_inst1", block_type="MIPI_RX_LANE")
design.assign_resource(cam_rx_data0, "GPIOR_PN_14", block_type="MIPI_RX_LANE")
cam_data0_prop = {
    # Parameters
    "DELAY_MODE":"STATIC",
    "DELAY":"5",
    "FIFO":"1",
    "REVERSIBLE":"0",
    # Pins
    "FIFO_RD_PIN":"o_cam_d0_FIFO_RD[0]",
    "FIFO_EMPTY_PIN":"i_cam_d0_FIFO_EMPTY[0]",
    "HS_ENA_PIN":"o_cam_d0_HS_ENA[0]",
    "HS_IN_PIN": "i_cam_d0_HS_IN_0",
    "HS_TERM_PIN":"o_cam_d0_HS_TERM[0]",
    "LP_N_IN_PIN":"i_cam_d0_LP_N_IN[0]",
    "LP_P_IN_PIN":"i_cam_d0_LP_P_IN[0]",
    "RST_PIN":"o_cam_d0_RST[0]"
}
design.set_property(cam_rx_data0, cam_data0_prop, block_type="MIPI_RX_LANE")

cam_rx_clk0 = design.create_block("mipi_rx_ln_inst2", mode="CLOCK_LANE", conn_type="GCLK", block_type="MIPI_RX_LANE")
design.assign_resource(cam_rx_clk0, "GPIOR_PN_10", block_type="MIPI_RX_LANE")
cam_clk0_prop = {
    # Parameters
    "DELAY_MODE":"STATIC",
    "DELAY":"4",
    # Pins
    "CLKOUT_PIN": "i_cam_ck_CLKOUT[0]",
    "HS_ENA_PIN":"o_cam_ck_HS_ENA[0]",
    "HS_TERM_PIN":"o_cam_ck_HS_TERM[0]",
    "LP_N_IN_PIN":"i_cam_ck_LP_N_IN[0]",
    "LP_P_IN_PIN":"i_cam_ck_LP_P_IN[0]"
}
design.set_property(cam_rx_clk0, cam_clk0_prop, block_type="MIPI_RX_LANE")

# ---------------------------------------------------------------------------- #
#                                   SPI FLASH                                  #
#                                                                              #
# Creates and configures SPI FLASH with the following settings:                #
#   - Assign "SPI_FLASH0" as the resource                                      #
#   - Set Enable Multiple Controller                                           #
#   - Set Read/Write Width to "x2"
# ---------------------------------------------------------------------------- #
spi_inst = "spi_flash_inst1"
design.create_block(spi_inst, block_type="SPI_FLASH")
design.assign_resource(spi_inst, "SPI_FLASH0", block_type="SPI_FLASH")

write_spi_flash_prop = {
    "MULT_CTRL_EN": "1",
    "RW_WIDTH": "x2"
}
design.set_property(spi_inst, write_spi_flash_prop, block_type="SPI_FLASH")

# ---------------------------------------------------------------------------- #
#                                   HYPERRAM                                   #
#                                                                              #
# Creates and configures HYPERRAM with the following settings:                 #
#   - Assign "HYPER_RAM0" as the resource                                      #
#   - Set the essential clock pin name for the HYPERRAM                        #
# ---------------------------------------------------------------------------- #
hyperram_inst = 'hyper_ram_inst1'
design.create_block(hyperram_inst, block_type="HYPERRAM")
design.assign_resource(hyperram_inst, "HYPER_RAM0", block_type="HYPERRAM")

write_hyperram_prop = {
    "CLK_PIN": "hyperram_clk_pin",
    "CLKCAL_PIN": "cal_clk_pin",
    "CLK90_PIN": "phase_shift_clk_pin"
}
design.set_property(hyperram_inst, write_hyperram_prop, block_type="HYPERRAM")

# ---------------------------------------------------------------------------- #
#                             DESIGN CHECK & EXPORT                            #
#                                                                              #
# Performs final design check and export steps:                                #
#   1. Check design integrity                                                  #
#   2. Export design as .isf file                                              #
#   3. Generate design constraints                                             #
#   4. Save design                                                             #
#                                                                              #
# Error Handling:                                                              #
#   - Design check failures                                                    #
#   - Constraint generation errors                                             #
#   - Report generation failures                                               #
# ---------------------------------------------------------------------------- #
design.check_design()
design.export_design()

try:
    design.generate(enable_bitstream=False)

except DesignException.PTDsgCheckException as excp:
    print("Design check fails : {} Msg={}".format(excp.get_msg_level(), excp.get_msg()))
    sys.exit(1)

except DesignException.PTDsgGenConstException as excp:
    print("Fail to generate constraint : {} Msg={}".format(excp.get_msg_level(), excp.get_msg()))
    sys.exit(1)

except DesignException.PTDsgGenReportException as excp:
    print("Fail to generate report : {} Msg={}".format(excp.get_msg_level(), excp.get_msg()))
    sys.exit(1)

design.save()