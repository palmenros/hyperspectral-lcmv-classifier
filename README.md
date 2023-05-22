# Hyperspectral LCMV Classifier

This repository contains the source code for a fully hardware implementation of the LCMV Target Classifier for hyperspectral images.

The repo is organized as follows:

- `rtl` contains the fully hardware LCMV implementation. It is subdivided in the following folders:
	- `design` has all the SystemVerilog files needed to implement the classifier.
	- `sim` has all the SystemVerilog testbenches for the design modules.
	- `sim_data` contains data used by the testbenches to verify the correct functionality of the hardware modules.
	- `utils` contains auxiliary files needed by the testbenches.
- `embedded` contains the C code that runs on the Microblaze processor in the embedded system for integration.
- `software-model` contains a C++ implementation of the LCMV target classifier, which serves as a comparison model.