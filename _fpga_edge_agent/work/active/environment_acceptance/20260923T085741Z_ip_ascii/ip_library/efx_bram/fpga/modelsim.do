vlib work
vlog -sv tb.sv
vlog -f  flist
vsim -t ns +notimingchecks -voptargs="+acc -debug +designfile" work.tb -qwavedb=+signal -logfile sim.log
run -All
