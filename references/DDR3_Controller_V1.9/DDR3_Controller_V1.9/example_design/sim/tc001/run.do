quit -sim
vlib work
vlib msim


vlib msim/work
vmap work msim/work


#Compile all modules#

vlog  -work work -64 -incr -mfcu "../../rtl/ddr3_controller/*.v"
vlog  -work work -64 -incr -mfcu "../../rtl/ddr3_controller/ddr3_parameter.vh"
vlog  -work work -64 -incr -mfcu "../../rtl/ddr3_controller/axi4_bus_ctl/*.v"
vlog  -work work -64 -incr -mfcu "../../rtl/ddr3_controller/memory_bus_ctl/*.v"
vlog  -work work -64 -incr -mfcu "../../rtl/ddr3_controller/phy_ctl/*.v"
vlog  -work work -64 -incr -mfcu "../../rtl/ddr3_controller/local_bus_ctl/*.v"
vlog  -work work -64 -incr -mfcu "../../rtl/ddr3_controller/common/*.v"
vlog  -work work -64 -incr -mfcu "../../rtl/ddr3_controller/common/efx_fifo_v2.3/*.v"

vlog  -work work -64 -incr -mfcu "../../rtl/memory_test/*.v"
vlog  -work work -64 -incr -mfcu "../../rtl/*.v"

#vlog  -work work -64 -incr "tb/DDR3_SDRAM_Verilog_Model/*.v"
vlog  -work work -64 -incr "tb/EXF_sim/*.v"

#vlog  -incr imports/glbl.v

vlog  -work work -64 -incr -mfcu "tb/tb_top.v"

vlog -sv +define+den1024Mb +define+sg125 +define+x8 "tb/ddr3.sv"

#eval vopt -64 -L work +acc tb_top -o semp_tb_top_vopt

#vsim -t fs -vopt -coverage work.semp_tb_top_vopt
vsim -t fs work.tb_top


###vsim###


radix hex
log -r /*
view signals wave
do wave.do

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

run -all