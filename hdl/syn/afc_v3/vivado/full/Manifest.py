target = "xilinx"
action = "synthesis"

language = "vhdl"

# Allow the user to override fetchto using:
#  hdlmake -p "fetchto='xxx'"
if locals().get('fetchto', None) is None:
  fetchto = "../../../../ip_cores"

syn_device = "xc7a200t"
syn_grade = "-2"
syn_package = "ffg1156"
syn_top = "afc_full"
syn_project = "afc_full"
syn_tool = "vivado"

board = "afc"

import os
import sys
if os.path.isfile("synthesis_descriptor_pkg.vhd"):
    files = ["synthesis_descriptor_pkg.vhd"];
else:
    sys.exit("Generate the SDB descriptor before using HDLMake (./build_synthesis_sdb.sh)")

modules = {
  "local" : [
      "../../../../top/afc_v3/vivado/full",
  ],
  "git" : [
      "https://github.com/lnls-dig/infra-cores.git",
	  "https://github.com/lnls-dig/general-cores.git",
  ],
}
