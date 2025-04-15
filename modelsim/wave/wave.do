onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /SAE_tb_checks/clk
add wave -noupdate -radix hexadecimal /SAE_tb_checks/reset_n
add wave -noupdate -radix hexadecimal /SAE_tb_checks/mode_w
add wave -noupdate -radix hexadecimal /SAE_tb_checks/input_data_w
add wave -noupdate -radix hexadecimal /SAE_tb_checks/input_key_w
add wave -noupdate -radix hexadecimal /SAE_tb_checks/valid_inputs_w
add wave -noupdate -radix hexadecimal /SAE_tb_checks/output_ready_w
add wave -noupdate -radix hexadecimal /SAE_tb_checks/output_data_w
add wave -noupdate -radix hexadecimal /SAE_tb_checks/err_invalid_seckey_w
add wave -noupdate -radix hexadecimal /SAE_tb_checks/mode_j
add wave -noupdate -radix hexadecimal /SAE_tb_checks/input_data_j
add wave -noupdate -radix hexadecimal /SAE_tb_checks/input_key_j
add wave -noupdate -radix hexadecimal /SAE_tb_checks/valid_inputs_j
add wave -noupdate -radix hexadecimal /SAE_tb_checks/output_ready_j
add wave -noupdate -radix hexadecimal /SAE_tb_checks/output_data_j
add wave -noupdate -radix hexadecimal /SAE_tb_checks/err_invalid_seckey_j
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {2288 ps}
