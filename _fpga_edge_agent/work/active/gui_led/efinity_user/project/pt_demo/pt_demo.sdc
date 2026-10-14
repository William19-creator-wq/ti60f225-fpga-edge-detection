# Constraints copied from outflow/pt_demo.pt.sdc

# Oscillator Constraints
########################
create_clock -period 100000 -name Oclk [get_ports {Oclk}]

# PLL Constraints
#################
create_clock -period 6.40 -name Fclk [get_ports {Fclk}]
create_clock -period 12.80 -name Sclk [get_ports {Sclk}]

# GPIO Constraints
####################
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {resetn}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {resetn}]
set_output_delay -clock Fclk -max -3.903 [get_ports {Fled[0]}]
set_output_delay -clock Fclk -min -1.784 [get_ports {Fled[0]}]
set_output_delay -clock Fclk -max -3.903 [get_ports {Fled[1]}]
set_output_delay -clock Fclk -min -1.784 [get_ports {Fled[1]}]
set_output_delay -clock Fclk -max -3.903 [get_ports {Fled[2]}]
set_output_delay -clock Fclk -min -1.784 [get_ports {Fled[2]}]
set_output_delay -clock Fclk -max -3.903 [get_ports {Fled[3]}]
set_output_delay -clock Fclk -min -1.784 [get_ports {Fled[3]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Oled[0]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Oled[0]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Oled[1]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Oled[1]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Oled[2]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Oled[2]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Oled[3]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Oled[3]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Sled[0]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Sled[0]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Sled_OE[0]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Sled_OE[0]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Sled[1]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Sled[1]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Sled_OE[1]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Sled_OE[1]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Sled[2]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Sled[2]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Sled_OE[2]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Sled_OE[2]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Sled[3]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Sled[3]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {Sled_OE[3]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {Sled_OE[3]}]
