# ----------------- Template for timing constraints ----------------- #
#
# Set the desired value for the clock period in nanoseconds (at line 6)
# and uncomment all the lines below (lines 6 - 14) by removing #
#
# ------------------------------------------------------------------- #

create_clock -name clk -period 15 [get_ports clk]

set_false_path -from [get_ports reset_n] -to [get_clocks clk]

set_input_delay  -min 1.5 -clock [get_clocks clk] [all_inputs ]
set_input_delay  -max 3 -clock [get_clocks clk] [all_inputs ]
set_output_delay -min 1.5 -clock [get_clocks clk] [all_outputs]
set_output_delay -max 3 -clock [get_clocks clk] [all_outputs]