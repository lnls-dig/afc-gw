# Generate single .xdc file as the order is important, but Vivado
# does not seem to respect that.

filenames = [
    'pcie_core.xdc',
    'ddr_core.xdc',
    'afc_base_common.xdc'
]

# Generic part for appending .xdc files to synthesis
xdc_dict = {
    'acq':     "afc_base_acq.xdc",
}

try:
    if afc_base_xdc is not None:
        for p in afc_base_xdc:
            f = xdc_dict.get(p, None)
            assert f is not None, "unknown name {} in 'afc_base_xdc'".format(p)
            filenames.append(f)
except NameError:
    # Do nothing, as nothing needs to be added to the .xdc list
    pass

# Additional pass for custom user files, if any
try:
    if additional_xdc is not None:
        for f in additional_xdc:
            filenames.append(f)
            print("Additional .xdc files being merged: {}".format(f))
except NameError:
    # Do nothing, as nothing needs to be added to the .xdc list
    pass

# Merge all .xdc files into one in order
afc_base_xdc_gen_name = "afc_base_common_gen.xdc"
with open(afc_base_xdc_gen_name, 'w') as outfile:
    for fname in filenames:
        with open(fname) as infile:
            outfile.write(infile.read())

files = [
    "afc_base_common.xcf",
];

files.append(afc_base_xdc_gen_name)
