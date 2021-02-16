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

# FP2_CLK1_C_P
set_property PACKAGE_PIN AG16 [get_ports aux_clk_p_i]
# FP2_CLK1_C_N
set_property PACKAGE_PIN AH16 [get_ports aux_clk_n_i]

# LINK01_CLK1_P
set_property PACKAGE_PIN AG18 [get_ports afc_link01_clk_p_i]
# LINK01_CLK1_N
set_property PACKAGE_PIN AH18 [get_ports afc_link01_clk_n_i]

# TXD		IO_25_34
set_property PACKAGE_PIN AB11 [get_ports uart_txd_o]
set_property IOSTANDARD LVCMOS25 [get_ports uart_txd_o]
# VADJ1_RXD	IO_0_34
set_property PACKAGE_PIN Y11 [get_ports uart_rxd_i]
set_property IOSTANDARD LVCMOS25 [get_ports uart_rxd_i]

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
##                           Trigger	                             ##
#######################################################################

set_property PACKAGE_PIN AM9 [get_ports {trig_b[0]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_b[0]}]

set_property PACKAGE_PIN AP11 [get_ports {trig_b[1]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_b[1]}]

set_property PACKAGE_PIN AP10 [get_ports {trig_b[2]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_b[2]}]

set_property PACKAGE_PIN AM11 [get_ports {trig_b[3]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_b[3]}]

set_property PACKAGE_PIN AN8 [get_ports {trig_b[4]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_b[4]}]

set_property PACKAGE_PIN AP8 [get_ports {trig_b[5]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_b[5]}]

set_property PACKAGE_PIN AL8 [get_ports {trig_b[6]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_b[6]}]

set_property PACKAGE_PIN AL9 [get_ports {trig_b[7]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_b[7]}]

set_property PACKAGE_PIN AJ10 [get_ports {trig_dir_o[0]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[0]}]

set_property PACKAGE_PIN AK11 [get_ports {trig_dir_o[1]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[1]}]

set_property PACKAGE_PIN AJ11 [get_ports {trig_dir_o[2]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[2]}]

set_property PACKAGE_PIN AL10 [get_ports {trig_dir_o[3]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[3]}]

set_property PACKAGE_PIN AM10 [get_ports {trig_dir_o[4]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[4]}]

set_property PACKAGE_PIN AN11 [get_ports {trig_dir_o[5]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[5]}]

set_property PACKAGE_PIN AN9 [get_ports {trig_dir_o[6]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[6]}]

set_property PACKAGE_PIN AP9 [get_ports {trig_dir_o[7]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[7]}]

#######################################################################
##                      AFC Diagnostics Contraints                   ##
#######################################################################

set_property PACKAGE_PIN J9 [get_ports diag_spi_cs_i]
set_property IOSTANDARD LVCMOS25 [get_ports diag_spi_cs_i]

set_property PACKAGE_PIN V28 [get_ports diag_spi_si_i]
set_property IOSTANDARD LVCMOS25 [get_ports diag_spi_si_i]

set_property PACKAGE_PIN V29 [get_ports diag_spi_so_o]
set_property IOSTANDARD LVCMOS25 [get_ports diag_spi_so_o]

set_property PACKAGE_PIN J8 [get_ports diag_spi_clk_i]
set_property IOSTANDARD LVCMOS25 [get_ports diag_spi_clk_i]

#######################################################################
##                      SPI Flash Constraints                        ##
#######################################################################
#
# set_property PACKAGE_PIN J9 [get_ports spi_cs_n_o]
# set_property IOSTANDARD LVCMOS25 [get_ports spi_cs_n_o]
#
# set_property PACKAGE_PIN V28 [get_ports spi_miso_i]
# set_property IOSTANDARD LVCMOS25 [get_ports spi_miso_i]
#
# set_property PACKAGE_PIN V29 [get_ports spi_mosi_o]
# set_property IOSTANDARD LVCMOS25 [get_ports spi_mosi_o]
#
# set_property PACKAGE_PIN J8 [get_ports spi_sclk_o]
# set_property IOSTANDARD LVCMOS25 [get_ports spi_sclk_o]
#
#######################################################################
##                      ADN4604ASVZ Contraints                      ##
#######################################################################

set_property PACKAGE_PIN U24 [get_ports adn4604_vadj2_clk_updt_n_o]
set_property IOSTANDARD LVCMOS25 [get_ports adn4604_vadj2_clk_updt_n_o]
set_property PULLUP true [get_ports adn4604_vadj2_clk_updt_n_o]

#######################################################################
##                        AFC SI57x Contraints                       ##
#######################################################################

set_property PACKAGE_PIN V24 [get_ports afc_si57x_scl_b]
set_property IOSTANDARD LVCMOS25 [get_ports afc_si57x_scl_b]

set_property PACKAGE_PIN W24 [get_ports afc_si57x_sda_b]
set_property IOSTANDARD LVCMOS25 [get_ports afc_si57x_sda_b]

set_property PACKAGE_PIN AD23 [get_ports afc_si57x_oe_o]
set_property IOSTANDARD LVCMOS25 [get_ports afc_si57x_oe_o]

#######################################################################
##                      FMC Connector HPC1                           ##
#######################################################################

###NET  "fmc1_prsnt_i"                            LOC =  | IOSTANDARD = "LVCMOS25";   // Connected to CPU
###NET  "fmc1_pg_m2c_i"                           LOC =  | IOSTANDARD = "LVCMOS25";   // Connected to CPU

# EEPROM (multiplexer PCA9548) (Connected to the CPU)
# FPGA I2C SCL
set_property PACKAGE_PIN P6 [get_ports board_i2c_scl_b]
set_property IOSTANDARD LVCMOS25 [get_ports board_i2c_scl_b]
# FPGA I2C SDA
set_property PACKAGE_PIN R11 [get_ports board_i2c_sda_b]
set_property IOSTANDARD LVCMOS25 [get_ports board_i2c_sda_b]

#######################################################################
##                      FMC Connector HPC2                           ##
#######################################################################

###NET  "fmc2_prsnt_i"                            LOC =  | IOSTANDARD = "LVCMOS25";   // Connected to CPU
###NET  "fmc2_pg_m2c_i"                           LOC =  | IOSTANDARD = "LVCMOS25";   // Connected to CPU

## EEPROM (multiplexer PCA9548) (Connected to the CPU)
## FPGA I2C SCL
#set_property PACKAGE_PIN P6 [get_ports fmc2_eeprom_scl_pad_b]
#set_property IOSTANDARD LVCMOS25 [get_ports fmc2_eeprom_scl_pad_b]
## FPGA I2C SDA
#set_property PACKAGE_PIN R11 [get_ports fmc2_eeprom_sda_pad_b]
#set_property IOSTANDARD LVCMOS25 [get_ports fmc2_eeprom_sda_pad_b]

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
##               Pinout and Related I/O Constraints                  ##
#######################################################################

#######################################################################
##                         DIFF TERM                                 ##
#######################################################################

#######################################################################
##                          Clocks                                   ##
#######################################################################

# 125 MHz AMC TCLKB input clock
create_clock -period 8.000 -name sys_clk_p_i       [get_ports sys_clk_p_i]

# 64.440 MHz AMC TCLKB input clock
create_clock -period 14.400 -name aux_clk_p_i      [get_ports aux_clk_p_i]

## 100 MHz wihsbone clock
create_generated_clock -name clk_sys               [get_pins -hier -filter {NAME =~ *cmp_sys_pll_inst/cmp_sys_pll/CLKOUT0}]
set clk_sys_period                                 [get_property PERIOD [get_clocks clk_sys]]
# 200 MHz DDR3 and IDELAY CONTROL clock
create_generated_clock -name clk_200mhz            [get_pins -hier -filter {NAME =~ *cmp_sys_pll_inst/cmp_sys_pll/CLKOUT1}]
set clk_200mhz_period                              [get_property PERIOD [get_clocks clk_200mhz]]

## 64.440 MHz aux clock
create_generated_clock -name clk_aux               [get_pins -hier -filter {NAME =~ *cmp_aux_sys_pll_inst/cmp_sys_pll/CLKOUT0}]
set clk_aux_period                                 [get_property PERIOD [get_clocks clk_aux]]

# DDR3 clock generated by IP
set clk_pll_ddr_period                             [get_property PERIOD [get_clocks clk_pll_i]]
set clk_pll_ddr_period_less                        [expr $clk_pll_ddr_period - 1.000]

# PCIE clock generated by IP
set clk_125mhz_period                             [get_property PERIOD [get_clocks clk_125mhz]]

#######################################################################
##                               Clocks                              ##
#######################################################################

# Reset synchronization path.
set_false_path -through                            [get_pins -hier -filter {NAME =~ *cmp_reset/master_rstn_reg/C}]
# Get the cell driving the corresponding net
set reset_sys_ffs                                  [get_nets -hier -filter {NAME =~ *cmp_reset*/master_rstn*}]
set_property ASYNC_REG TRUE                        [get_cells [all_fanin -flat -only_cells -startpoints_only [get_pins -of_objects [get_nets $reset_sys_ffs]]]]

# Reset synchronization path.
set_false_path -through                            [get_pins -hier -filter {NAME =~ *cmp_aux_reset/master_rstn_reg/C}]
# Get the cell driving the corresponding net
set reset_aux_ffs                                  [get_nets -hier -filter {NAME =~ *cmp_aux_reset*/master_rstn*}]
set_property ASYNC_REG TRUE                        [get_cells [all_fanin -flat -only_cells -startpoints_only [get_pins -of_objects [get_nets $reset_aux_ffs]]]]

# DDR 3 temperature monitor reset path
# chain of FFs synched with clk_sys.
#  We use asynchronous assertion and
#  synchronous deassertion
set_false_path -through                            [get_nets -hier -filter {NAME =~ *theTlpControl/Memory_Space/wb_FIFO_Rst}]
# DDR 3 temperature monitor reset path
set_max_delay -datapath_only -from                 [get_cells -hier -filter {NAME =~ *ddr3_infrastructure/rstdiv0_sync_r1_reg*}] -to [get_cells -hier -filter {NAME =~ *temp_mon_enabled.u_tempmon/xadc_supplied_temperature.rst_r1*}] 20.000

#######################################################################
##                              CDC                                  ##
#######################################################################

# FIFO generated CDC. Xilinx recommends 2x the slower clock period delay. But let's be more strict and allow
# only 1x faster clock period delay
set_max_delay -datapath_only -from               [get_clocks clk_pll_i]    -to [get_clocks clk_userclk2]   $clk_pll_ddr_period
set_max_delay -datapath_only -from               [get_clocks clk_userclk2] -to [get_clocks clk_pll_i]      $clk_pll_ddr_period

# Wishbone <-> PCIe. Using 1x source clock
set_max_delay -datapath_only -from               [get_clocks clk_sys]     -to [get_clocks clk_125mhz]   $clk_sys_period
set_max_delay -datapath_only -from               [get_clocks clk_125mhz]  -to [get_clocks clk_sys]      $clk_125mhz_period

# PCIe <-> DDR3. Give 1x the source clock
set_max_delay -from                              [get_clocks clk_pll_i] -to [get_clocks clk_125mhz] $clk_pll_ddr_period

# Acquisition core <-> DDR3 clock. 1x source clock destination
set_max_delay -datapath_only -from               [get_clocks clk_sys]   -to [get_clocks clk_pll_i] $clk_sys_period
set_max_delay -datapath_only -from               [get_clocks clk_pll_i] -to [get_clocks clk_sys]   $clk_pll_ddr_period

# DDR3 reset path. Copied from
# ddr_core.xdc and modified accordingly
set_max_delay -datapath_only -from               [get_pins -hier -filter {NAME =~ *cmp_pcie_cntr/user_lnk_up_int_i/C}] -to [get_cells -hier *rstdiv0_sync_r*] 5

# Constraint the asynchronous reset of the DDR3 module. It should be safe to declare it
# as a false path, but let's give it a 5 ns, as the constraint above.
# Here we want to get a valid startpoint from the NET name ddr_reset. So, we must:
# 1. Get the complete name of this NET
# 2. Get the pin name that is connected to this NET and filter it
#     so get only the OUT pins and the LEAF name of it (as opposed to
#     a hierarchical name)
# 3. This pin will be probably the Q pin of the driving FF, but for a timing,
#     analysis we want a valid startpoint. So, we get only this by using the all_fanin
#     command
# FIXME. This might not work if the tools change the name of the "ddr_reset" net.
# Instead, use the actual name of the driving "ddr_reset" net
#set pcie_user_ddr_reset                          [all_fanin -flat -only_cells -startpoints_only [get_pins -of_objects [get_nets -hier -filter {NAME =~ */theTlpControl/Memory_Space/ddr_reset}] -filter {IS_LEAF && (DIRECTION == "OUT")}]]
set pcie_user_ddr_reset                          [get_cells -hier -filter {NAME =~ */theTlpControl/Memory_Space/General_Control_i_reg[16]}]
set_max_delay -from                              [get_cells $pcie_user_ddr_reset] 5.000

# Constraint DDR <-> PCIe clocks CDC
set_max_delay -datapath_only -from               [get_clocks -include_generated_clocks pcie_clk] -to [get_clocks -include_generated_clocks clk_pll_i] 5.000
set_max_delay -datapath_only -from               [get_clocks -include_generated_clocks clk_pll_i] -to [get_clocks -include_generated_clocks pcie_clk] 5.000

# Aux clock to Sys clock. Path used to/from registers
set_max_delay -datapath_only -from               [get_clocks clk_sys] -to [get_clocks clk_aux]    $clk_sys_period
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks clk_sys]    $clk_sys_period

#######################################################################
##                      Placement Constraints                        ##
#######################################################################

# Constrain the PCIe core elements placement, so that it won't fail
# timing analysis.
# Comment out because we use nonstandard GTP location
#create_pblock GRP_pcie_core
#add_cells_to_pblock [get_pblocks GRP_pcie_core] [get_cells -hier -filter {NAME =~ *pcie_core_i/*}]
#resize_pblock [get_pblocks GRP_pcie_core] -add {CLOCKREGION_X0Y4:CLOCKREGION_X0Y4}
#
## Place the DMA design not far from PCIe core, otherwise it also breaks timing
#create_pblock GRP_ddr_core
#add_cells_to_pblock [get_pblocks GRP_ddr_core] [get_cells -hier -filter  {NAME =~ *pcie_core_i/DDRs_ctrl_module/ddr_core_inst/*]]
#resize_pblock [get_pblocks GRP_ddr_core] -add {CLOCKREGION_X1Y0:CLOCKREGION_X1Y1}
#
## Place DDR core temperature monitor
#create_pblock GRP_ddr_core_temp_mon
#add_cells_to_pblock [get_pblocks GRP_ddr_core_temp_mon] [get_cells -quiet -hier -filter [NAME =~ *u_ddr_core/temp_mon_enabled.u_tempmon/*]]
#resize_pblock [get_pblocks GRP_ddr_core_temp_mon] -add {CLOCKREGION_X0Y2:CLOCKREGION_X0Y3}

#######################################################################
##                         CE Constraints                            ##
#######################################################################

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
