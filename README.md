
# RAL 
This project aims to learn about Register Abstraction Layer (RAL) and use it to test a device. I've written a simple Register File that can be found in the src folder with the purpose of starting with a easy device. Note that although the file is called 'WINDOWEDRF' it's only a regular RF with a single port used for both reading or writing. I plan to expand this in the future, eventually testing a fully functional Windowed RF with RAL.  
 

## RAL structure
In the file RAL_pkg you can find the Register Model: I define a 64 bit register with a single field, then I instance it 64 times in a reg_block. I then instance the reg block in a top_reg_block. I believe this is not strictly necessary, and would only be useful if I wanted to add more memory elements to the model, is this correct? 

## Test Structure
I've designed a regular agent, with driver, sequencer and monitor. I have an environment that contains it  and the adapter, and a top_env that contains the smaller env and instances the regmodel. The test runs 3 sequences: 
- Reset Sequence: applies the reset and sets other input signals to zero 
- rand_rw_seq: Creates sequence items with random values. These may be write or read operations that the Predictor automatically translates in reg_item operations.  
- regmodel_rw: extends uvm_reg_sequence is meant to test the dut using direct methods of the registers in the model. By calling the 'reg.write(...)' or 'reg.read()'. 

## Problem
The problem I'm facing at the moment is that the Register model I've written is not working as intended: When I try to issue a read operation it's interpreted as a write.


## To navigate this project:   

- SRC: includes all .vhd files necessary to compile my version of the RF. 

- TB  : includes test files. I have decided to include all test components in a single package in a single file. I know this is not good for reusability but I find it more convenient for the writing code process. I can change this in the near future if necessary. 
    - RAL_pkg is the file that contains the Register model. 
    - RF_if_wrap includes the interface and the wrapper of the DUT. 
    - RF_testbench includes the package with all test components as well as the top module that runs the test. 
- SIM contains the work library and necessary files for simulation, coverage etc.


# How to compile and Simulate  
1. Compile the DUT's source file: vcom -F compile_vhd.f
2. Compile the test files: vlog -F compile_sv.f
3. Simulate the test: vsim -c -sv_seed random -do sim.do
