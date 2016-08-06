vsim work.testbench
add wave -group TestBench -position insertpoint sim:/testbench/*
add wave -group CPU -position insertpoint sim:/testbench/cpu_i/* 
add wave -group Arbiter -position insertpoint sim:/testbench/cpu_i/arbiter/*
add wave -group write_back_fetch -position insertpoint sim:/testbench/cpu_i/wbf/*
add wave -group decode_regsiter_file -position insertpoint sim:/testbench/cpu_i/d_rf/*
add wave -group execute -position insertpoint sim:/testbench/cpu_i/x/*
add wave -group Hazard_Detection_Unit -position insertpoint sim:/testbench/cpu_i/hdu1/*
run -a