vlib work
vlog -sv top_tb.sv
vlog -f  flist
vsim -t ps +notimingchecks -voptargs="+acc -debug +designfile" -qwavedb=+signal -logfile sim.log work.top_tb
run -All
