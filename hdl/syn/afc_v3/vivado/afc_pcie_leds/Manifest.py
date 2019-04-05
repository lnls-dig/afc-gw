target = "xilinx"
action = "synthesis"

language = "vhdl"

syn_device = "xc7a200t"
syn_grade = "-2"
syn_package = "ffg1156"
syn_top = "afc_pcie_leds"
syn_project = "afc_pcie_leds"
syn_tool = "vivado"

import os
import sys
if os.path.isfile("synthesis_descriptor_pkg.vhd"):
    files = ["synthesis_descriptor_pkg.vhd"];
else:
    sys.exit("Generate the SDB descriptor before using HDLMake (./build_synthesis_sdb.sh)")

modules = { "local" : [ "../../../../top/afc_v3/vivado/afc_pcie_leds" ] };
