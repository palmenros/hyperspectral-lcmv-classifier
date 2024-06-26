# Hyperspectral LCMV Classifier

This repository contains the source code for a fully hardware implementation of the LCMV Target Classifier for hyperspectral images using LDL decomposition.

The repo is organized as follows:

- `rtl` contains the fully hardware LCMV implementation. It is subdivided in the following folders:
	- `design` has all the SystemVerilog files needed to implement the classifier.
	- `sim` has all the SystemVerilog testbenches for the design modules.
	- `sim_data` contains data used by the testbenches to verify the correct functionality of the hardware modules.
	- `utils` contains auxiliary files needed by the testbenches.
- `microblaze` contains the C code that runs on the Microblaze processor in the FPGA embedded system for testing and integration with the FPGA RTL hardware.
- `software-model` contains code for the LCMV algorithm implemented in software:
	- `cpp` contains a C++ implementation of the LCMV target classifier, which serves as a comparison model.
	- `matlab` contains a Matlab implementation (both using LDL and Gauss-Jordan inverse), which serves as both a comparison model and code for Matlabs's Fixed-Point Converter, in order to determine the fixed-point width needed.
- `embedded` contains the C and CUDA code that runs on the Jetson Orin Nano embedded GPU and CPU.
