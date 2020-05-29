# AFC Base Gateware

This repository contains the AFC board support gateware
with all the board funcionality exposed, such as PCIe, DDR,
triggers, LEDs and UART, as well as some often used modules
like acquistion engines and interrupt support.

## Project Folder Organization

```
*
|
|-- hdl:
|    |   HDL (Verilog/VHDL) cores related to the AFC.
|    |
|    |-- ip_cores:
|    |    |   Third party reusable modules, primarily Open hardware
|    |    |     modules (http://www.ohwr.org).
|    |    |
|    |    |-- infra-cores:
|    |    |       General reusable modules from LNLS.
|    |    |-- general-cores (fork from original project):
|    |            General reusable modules from OHWR.
|    |
|    |-- modules:
|    |        Modules specific to this project.
|    |
|    |-- platform:
|    |        Platform-specific code, such as Xilinx Chipscope wrappers.
|    |
|    |-- sim:
|    |        Generic simulation files, reusable Bus Functional Modules (BFMs),
|    |          constants definitions.
|    |
|    |-- syn:
|    |        Synthesis specific files (user constraints files and top design
|    |          specification).
|    |
|    |-- testbench:
|    |        Testbenches for modules and top level designs. May use modules
|    |          defined elsewhere (specific within the 'sim" directory).
|    |
|    |-- top:
|             Top design modules.
```

## Cloning Instructions

This repository makes use of git submodules, located at 'hdl/ip_cores' folder:
  hdl/ip_cores/general-cores
  hdl/ip_cores/infra-cores

To clone the whole repository use the following command:

    git clone --recursive git://github.com/lnls-dig/afc-gw.git (read only)

  or

    git clone --recursive git@github.com:lnls-dig/afc-gw.git (read+write)

For older versions of Git (<1.6.5), use the following:

    git clone git://github.com/lnls-dig/afc-gw.git

or

    git clone git@github.com:lnls-dig/afc-gw.git

    git submodule init
    git submodule update

To update each submodule within this project use:

    git submodule foreach git rebase origin master

## Simulation Instructions

Go to a testbench directory. It must have a top manifest file:

    cd hdl/testbench/path_to_testbench

Run the following commands. You must have hdlmake command available
in your PATH environment variable.

Create the simulation makefile

    hdlmake

Compile the project

    make

Execute the simulation with GUI and adittional commands

    vsim -do run.do &

## Synthesis Instructions

Synthesis was tested with Vivado 2018.3. Other versions might work,
but it's not guaranteed.

Go to a syn directory. It must have a synthesis manifest file:

    cd hdl/syn/path_to_syn_design

Run the following commands. You must have hdlmake command available
in your PATH environment variable.

    ./build_bitstream_local.sh
