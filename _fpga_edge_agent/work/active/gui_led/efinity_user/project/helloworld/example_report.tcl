##report timing example
report_timing -detail summary -npaths 10 -nworst 5 -from [ get_pins {*count*|Q} ] -to [ get_pins {*|D} ]

##report path example
report_path -npaths 10 -nworst 1 -summary -from [ get_pins {*count*|Q} ] -to [ get_pins {*|D} ]

