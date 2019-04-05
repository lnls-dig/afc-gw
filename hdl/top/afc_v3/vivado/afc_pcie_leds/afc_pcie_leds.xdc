#######################################################################
##                      Artix 7 AMC V3                               ##
#######################################################################

# FPGA_CLK1_P
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_p_i]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports sys_clk_p_i]
# FPGA_CLK1_N
set_property PACKAGE_PIN AL7 [get_ports sys_clk_n_i]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_n_i]
set_property IN_TERM UNTUNED_SPLIT_50 [get_ports sys_clk_n_i]

# System Reset
# Bank 16 VCCO - VADJ_FPGA - IO_25_16. NET = FPGA_RESET_DN, PIN = IO_L19P_T3_13
set_false_path -through [get_nets sys_rst_button_n_i]
set_property PACKAGE_PIN AG26 [get_ports sys_rst_button_n_i]
set_property IOSTANDARD LVCMOS25 [get_ports sys_rst_button_n_i]
set_property PULLUP true [get_ports sys_rst_button_n_i]

# AFC LEDs
# LED Red - IO_L6P_T0_36
set_property PACKAGE_PIN K10 [get_ports {leds_o[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds_o[2]}]
# Led Green - IO_25_36
set_property PACKAGE_PIN L7 [get_ports {leds_o[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds_o[1]}]
# Led Blue - IO_0_36
set_property PACKAGE_PIN H12 [get_ports {leds_o[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds_o[0]}]

#######################################################################
##                      ADN4604ASVZ Contraints                      ##
#######################################################################

set_property PACKAGE_PIN U24 [get_ports adn4604_vadj2_clk_updt_n_o]
set_property IOSTANDARD LVCMOS25 [get_ports adn4604_vadj2_clk_updt_n_o]
set_property PULLUP true [get_ports adn4604_vadj2_clk_updt_n_o]

#######################################################################
##                          PCIe constraints                        ##
#######################################################################

#PCIe clock
# MGT216_CLK1_N -> MGTREFCLK0N_216
set_property PACKAGE_PIN G18                     [get_ports pcie_clk_n_i]
# MGT216_CLK1_P -> MGTREFCLK0P_216
set_property PACKAGE_PIN H18                     [get_ports pcie_clk_p_i]

#XDC supplied by PCIe IP core generates
# GTP connection in reverse order, we have to swap it.
# Simply providing correct connections will generate
# errors "Cannot set LOC ... because the PACKAGE_PIN
# is occupied by ...".
# So, firstly set PCIe lanes to temporary locations
#PCIe lane 0
# TX213_0_P            -> MGTPTXP0_213
set_property PACKAGE_PIN AN19                    [get_ports {pci_exp_txp_o[0]}]
# TX213_0_N            -> MGTPTXN0_213
set_property PACKAGE_PIN AP19                    [get_ports {pci_exp_txn_o[0]}]
# RX213_0_P            -> MGTPRXP0_213
set_property PACKAGE_PIN AL18                    [get_ports {pci_exp_rxp_i[0]}]
# RX213_0_N            -> MGTPRXN0_213
set_property PACKAGE_PIN AM18                    [get_ports {pci_exp_rxn_i[0]}]
#PCIe lane 1
# TX213_1_P            -> MGTPTXP1_213
set_property PACKAGE_PIN AN21                    [get_ports {pci_exp_txp_o[1]}]
# TX213_1_N            -> MGTPTXN1_213
set_property PACKAGE_PIN AP21                    [get_ports {pci_exp_txn_o[1]}]
# RX213_1_P            -> MGTPRXP1_213
set_property PACKAGE_PIN AJ19                    [get_ports {pci_exp_rxp_i[1]}]
# RX213_1_N            -> MGTPRXN1_213
set_property PACKAGE_PIN AK19                    [get_ports {pci_exp_rxn_i[1]}]
#PCIe lane 2
# TX213_2_P            -> MGTPTXP2_213
set_property PACKAGE_PIN AL22                    [get_ports {pci_exp_txp_o[2]}]
# TX213_2_N            -> MGTPTXN2_213
set_property PACKAGE_PIN AM22                    [get_ports {pci_exp_txn_o[2]}]
# RX213_2_P            -> MGTPRXP2_213
set_property PACKAGE_PIN AL20                    [get_ports {pci_exp_rxp_i[2]}]
# RX213_2_N            -> MGTPRXN2_213
set_property PACKAGE_PIN AM20                    [get_ports {pci_exp_rxn_i[2]}]
#PCIe lane 3
# TX213_3_P            -> MGTPTXP3_213
set_property PACKAGE_PIN AN23                    [get_ports {pci_exp_txp_o[3]}]
# TX213_3_N            -> MGTPTXN3_213
set_property PACKAGE_PIN AP23                    [get_ports {pci_exp_txn_o[3]}]
# RX213_3_P            -> MGTPRXP3_213
set_property PACKAGE_PIN AJ21                    [get_ports {pci_exp_rxp_i[3]}]
# RX213_3_N            -> MGTPRXN3_213
set_property PACKAGE_PIN AK21                    [get_ports {pci_exp_rxn_i[3]}]

# Now assign the correct ones

#PCIe lane 0
# TX216_0_P            -> MGTPTXP0_216
set_property PACKAGE_PIN B23                     [get_ports {pci_exp_txp_o[0]}]
# TX216_0_N            -> MGTPTXN0_216
set_property PACKAGE_PIN A23                     [get_ports {pci_exp_txn_o[0]}]
# RX216_0_P            -> MGTPRXP0_216
set_property PACKAGE_PIN F21                     [get_ports {pci_exp_rxp_i[0]}]
# RX216_0_N            -> MGTPRXN0_216
set_property PACKAGE_PIN E21                     [get_ports {pci_exp_rxn_i[0]}]
#PCIe lane 1
# TX216_1_P            -> MGTPTXP1_216
set_property PACKAGE_PIN D22                     [get_ports {pci_exp_txp_o[1]}]
# TX216_1_N            -> MGTPTXN1_216
set_property PACKAGE_PIN C22                     [get_ports {pci_exp_txn_o[1]}]
# RX216_1_P            -> MGTPRXP1_216
set_property PACKAGE_PIN D20                     [get_ports {pci_exp_rxp_i[1]}]
# RX216_1_N            -> MGTPRXN1_216
set_property PACKAGE_PIN C20                     [get_ports {pci_exp_rxn_i[1]}]
#PCIe lane 2
# TX216_2_P            -> MGTPTXP2_216
set_property PACKAGE_PIN B21                     [get_ports {pci_exp_txp_o[2]}]
# TX216_2_N            -> MGTPTXN2_216
set_property PACKAGE_PIN A21                     [get_ports {pci_exp_txn_o[2]}]
# RX216_2_P            -> MGTPRXP2_216
set_property PACKAGE_PIN F19                     [get_ports {pci_exp_rxp_i[2]}]
# RX216_2_N            -> MGTPRXN2_216
set_property PACKAGE_PIN E19                     [get_ports {pci_exp_rxn_i[2]}]
#PCIe lane 3
# TX216_3_P            -> MGTPTXP3_216
set_property PACKAGE_PIN B19                     [get_ports {pci_exp_txp_o[3]}]
# TX216_3_N            -> MGTPTXN3_216
set_property PACKAGE_PIN A19                     [get_ports {pci_exp_txn_o[3]}]
# RX216_3_P            -> MGTPRXP3_216
set_property PACKAGE_PIN D18                     [get_ports {pci_exp_rxp_i[3]}]
# RX216_3_N            -> MGTPRXN3_216
set_property PACKAGE_PIN C18                     [get_ports {pci_exp_rxn_i[3]}]

#######################################################################
##                          Clocks                                   ##
#######################################################################

# 125 MHz AMC TCLKB input clock
create_clock -period 8.000 -name sys_clk_p_i      [get_ports sys_clk_p_i]

## 100 MHz wihsbone clock
create_generated_clock -name clk_sys              [get_pins -hier -filter {NAME =~ *cmp_sys_pll_inst/cmp_sys_pll/CLKOUT0}]
set clk_sys_period                                [get_property PERIOD [get_clocks clk_sys]]

# PCIE clock generated by IP
set clk_125mhz_period                             [get_property PERIOD [get_clocks clk_125mhz]]
set clk_125mhz_period_half                        [expr $clk_125mhz_period / 2]
# DDR3 clock generated by IP
set clk_pll_ddr_period                            [get_property PERIOD [get_clocks clk_pll_i]]
set clk_pll_ddr_period_less                       [expr $clk_pll_ddr_period - 1.000]

#######################################################################
##                          False Paths                              ##
#######################################################################

# Reset synchronization path.
set_false_path -through                            [get_pins -hier -filter {NAME =~ *cmp_reset/master_rstn_reg/C}]
# Get the cell driving the corresponding net
set reset_sys_ffs                                  [get_nets -hier -filter {NAME =~ *cmp_reset*/master_rstn*}]
set_property ASYNC_REG TRUE                        [get_cells [all_fanin -flat -only_cells -startpoints_only [get_pins -of_objects [get_nets $reset_sys_ffs]]]]

#######################################################################
##                              CDC                                  ##
#######################################################################

# Wishbone <-> PCIe. Using 1x source clock
set_max_delay -datapath_only -from               [get_clocks clk_sys]     -to [get_clocks clk_125mhz]   $clk_sys_period
set_max_delay -datapath_only -from               [get_clocks clk_125mhz]  -to [get_clocks clk_sys]      $clk_125mhz_period

# Constraint DDR <-> PCIe clocks CDC
set_max_delay -datapath_only -from               [get_clocks -include_generated_clocks pcie_clk] -to [get_clocks -include_generated_clocks clk_pll_i] $clk_125mhz_period_half
set_max_delay -datapath_only -from               [get_clocks -include_generated_clocks clk_pll_i] -to [get_clocks -include_generated_clocks pcie_clk] $clk_125mhz_period_half

#######################################################################
##                         Bitstream Settings                        ##
#######################################################################

set_property BITSTREAM.CONFIG.CONFIGRATE 12       [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES   [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4      [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES  [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE      [current_design]
set_property CFGBVS VCCO                          [current_design]
set_property CONFIG_VOLTAGE 3.3                   [current_design]
