filenames = ['pcie_core.xdc', 'ddr_core.xdc', 'afc_pcie_leds.xdc']
with open('afc_pcie_leds_gen.xdc', 'w') as outfile:
    for fname in filenames:
        with open(fname) as infile:
            outfile.write(infile.read())

files = [ "afc_pcie_leds_gen.xdc",
          "afc_pcie_leds.vhd",
          "sys_pll.vhd",
          "clk_gen.vhd",
        ];

modules = { "local" :
             ["../../../.."
             ]
          };

