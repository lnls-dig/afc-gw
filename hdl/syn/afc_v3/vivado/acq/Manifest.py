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
syn_top = "afc_acq"
syn_project = "afc_acq"
syn_tool = "vivado"
syn_properties = [
    ["steps.synth_design.args.more options", "-verbose"],
    ["steps.synth_design.args.retiming", "1"],
    ["steps.synth_design.args.assert", "1"],
#    ["steps.place_design.args.directive", "Explore"],
#    ["steps.place_design.args.more options", "-verbose"],
#    ["steps.route_design.args.directive", "Explore"],
#    ["steps.route_design.args.more options", "-verbose"],
    ["steps.write_bitstream.args.verbose", "1"]
]

board = "afc"

import os
import sys
if os.path.isfile("synthesis_descriptor_pkg.vhd"):
    files = ["synthesis_descriptor_pkg.vhd"];
else:
    sys.exit("Generate the SDB descriptor before using HDLMake (./build_synthesis_sdb.sh)")

modules = {
  "local" : [
      "../../../../top/afc_v3/vivado/acq",
  ],
  "git" : [
      "https://github.com/lnls-dig/infra-cores.git",
	  "https://github.com/lnls-dig/general-cores.git",
  ],
}
