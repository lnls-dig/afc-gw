# Generate single .xdc file as the order is important, but Vivado
# does not seem to respect that.

filenames = [
    'pcie_core.xdc',
    'ddr_core.xdc',
    'afc_base_common.xdc'
]
with open('afc_base_common_gen.xdc', 'w') as outfile:
    for fname in filenames:
        with open(fname) as infile:
            outfile.write(infile.read())

files = [ "afc_base_common.xcf",
          "afc_base_common_gen.xdc"
         ];

