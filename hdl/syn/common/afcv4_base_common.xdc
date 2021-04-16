#######################################################################
##                      Artix 7 AMC V4                               ##
#######################################################################

# From clock OSC3 125MHz. Fixed
# FPGA_CLK1_P
set_property IOSTANDARD DIFF_SSTL15     [get_ports sys_clk_p_i]
set_property IN_TERM UNTUNED_SPLIT_50   [get_ports sys_clk_p_i]
# FPGA_CLK1_N
set_property PACKAGE_PIN AL7            [get_ports sys_clk_n_i]
set_property IOSTANDARD DIFF_SSTL15     [get_ports sys_clk_n_i]
set_property IN_TERM UNTUNED_SPLIT_50   [get_ports sys_clk_n_i]

# From clock switch port 15: FLEX_CLK3
# MGT213_CLK1_P: From FLEX_GTP213_CLK1_P
set_property PACKAGE_PIN AG18           [get_ports aux_clk_p_i]
# MGT213_CLK1_N: from FLEX_GTP213_CLK1_N
set_property PACKAGE_PIN AH18           [get_ports aux_clk_n_i]

# From clock switch port 13: FLEX_CLK1
# MGT113_CLK1_P: From FLEX_GTP113_CLK1_P
set_property PACKAGE_PIN AG16           [get_ports afc_fp2_clk1_p_i]
# MGT113_CLK1_N: From FLEX_GTP113_CLK1_P
set_property PACKAGE_PIN AH16           [get_ports afc_fp2_clk1_n_i]

# PRI_UART_Tx
set_property PACKAGE_PIN AG30    [get_ports uart_txd_o]
set_property IOSTANDARD LVCMOS25 [get_ports uart_txd_o]
# PRI_UART_Rx
set_property PACKAGE_PIN AG29    [get_ports uart_rxd_i]
set_property IOSTANDARD LVCMOS25 [get_ports uart_rxd_i]

# System Reset
# Bank 16 VCCO - VADJ_FPGA - IO_25_16. NET = FPGA_RESET_DN, PIN = IO_L19P_T3_13
set_false_path -through             [get_nets sys_rst_button_n_i]
set_property PACKAGE_PIN AG26       [get_ports sys_rst_button_n_i]
set_property IOSTANDARD LVCMOS25    [get_ports sys_rst_button_n_i]
set_property PULLUP true            [get_ports sys_rst_button_n_i]

# AFC LEDs
# LED Red
set_property PACKAGE_PIN H6      [get_ports {leds_o[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds_o[2]}]
# Led Green
set_property PACKAGE_PIN J6      [get_ports {leds_o[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds_o[1]}]
# Led Blue
set_property PACKAGE_PIN J5      [get_ports {leds_o[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {leds_o[0]}]

#######################################################################
##                           Trigger	                             ##
#######################################################################

# FPGA MLVDS_O_8_C: To MLVDS_O_8. Drives Rx17_P/N, Backplane trigger channel 0
set_property PACKAGE_PIN AN8      [get_ports {trig_o[0]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_o[0]}]

# FPGA MLVDS_O_7_C: To MLVDS_O_7. Drives Tx17_P/N, Backplane trigger channel 1
set_property PACKAGE_PIN AP9      [get_ports {trig_o[1]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_o[1]}]

# FPGA MLVDS_O_6_C: To MLVDS_O_6. Drives Rx18_P/N, Backplane trigger channel 2
set_property PACKAGE_PIN AN9      [get_ports {trig_o[2]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_o[2]}]

# FPGA MLVDS_O_5_C: To MLVDS_O_5. Drives Tx18_P/N, Backplane trigger channel 3
set_property PACKAGE_PIN AP10     [get_ports {trig_o[3]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_o[3]}]

# FPGA MLVDS_O_4_C: To MLVDS_O_4. Drives Rx19_P/N, Backplane trigger channel 4
set_property PACKAGE_PIN AM9      [get_ports {trig_o[4]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_o[4]}]

# FPGA MLVDS_O_3_C: To MLVDS_O_3. Drives Tx19_P/N, Backplane trigger channel 5
set_property PACKAGE_PIN AP11     [get_ports {trig_o[5]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_o[5]}]

# FPGA MLVDS_O_2_C: To MLVDS_O_2. Drives Rx20_P/N, Backplane trigger channel 6
set_property PACKAGE_PIN AN11     [get_ports {trig_o[6]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_o[6]}]

# FPGA MLVDS_O_1_C: To MLVDS_O_1. Drives Rx20_P/N, Backplane trigger channel 7
set_property PACKAGE_PIN AM10     [get_ports {trig_o[7]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_o[7]}]

# FPGA MLVDS_I_8_C: From MLVDS_I_8. Receives Rx17_P/N, Backplane trigger channel 0
set_property PACKAGE_PIN AL9      [get_ports {trig_i[0]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_i[0]}]

# FPGA MLVDS_I_7_C: From MLVDS_I_7. Receives Tx17_P/N, Backplane trigger channel 1
set_property PACKAGE_PIN AL8      [get_ports {trig_i[1]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_i[1]}]

# FPGA MLVDS_I_6_C: From MLVDS_I_6. Receives Rx18_P/N, Backplane trigger channel 2
set_property PACKAGE_PIN AP8      [get_ports {trig_i[2]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_i[2]}]

# FPGA MLVDS_I_5_C: From MLVDS_I_5. Receives Tx18_P/N, Backplane trigger channel 3
set_property PACKAGE_PIN AM11     [get_ports {trig_i[3]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_i[3]}]

# FPGA MLVDS_I_4_C: From MLVDS_I_4. Receives Rx19_P/N, Backplane trigger channel 4
set_property PACKAGE_PIN AL10     [get_ports {trig_i[4]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_i[4]}]

# FPGA MLVDS_I_3_C: From MLVDS_I_3. Receives Tx19_P/N, Backplane trigger channel 5
set_property PACKAGE_PIN AK11     [get_ports {trig_i[5]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_i[5]}]

# FPGA MLVDS_I_2_C: From MLVDS_I_2. Receives Rx20_P/N, Backplane trigger channel 6
set_property PACKAGE_PIN AJ11     [get_ports {trig_i[6]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_i[6]}]

# FPGA MLVDS_I_1_C: From MLVDS_I_1. Receives Rx20_P/N, Backplane trigger channel 7
set_property PACKAGE_PIN AJ10     [get_ports {trig_i[7]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_i[7]}]

# FPGA MLVDS_DE_8_C: To MLVDS_DE_8. Controls DIR Rx17_P/N, Backplane trigger channel 0
set_property PACKAGE_PIN L7       [get_ports {trig_dir_o[0]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[0]}]

# FPGA MLVDS_DE_7_C: To MLVDS_DE_7. Controls DIR Tx17_P/N, Backplane trigger channel 1
set_property PACKAGE_PIN J8       [get_ports {trig_dir_o[1]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[1]}]

# FPGA MLVDS_DE_6_C: To MLVDS_DE_6. Controls DIR Rx18_P/N, Backplane trigger channel 2
set_property PACKAGE_PIN J9       [get_ports {trig_dir_o[2]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[2]}]

# FPGA MLVDS_DE_5_C: To MLVDS_DE_5. Controls DIR Tx18_P/N, Backplane trigger channel 3
set_property PACKAGE_PIN K10      [get_ports {trig_dir_o[3]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[3]}]

# FPGA MLVDS_DE_4_C: To MLVDS_DE_4. Controls DIR Rx19_P/N, Backplane trigger channel 4
set_property PACKAGE_PIN H7       [get_ports {trig_dir_o[4]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[4]}]

# FPGA MLVDS_DE_3_C: To MLVDS_DE_3. Controls DIR Tx19_P/N, Backplane trigger channel 5
set_property PACKAGE_PIN K12      [get_ports {trig_dir_o[5]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[5]}]

# FPGA MLVDS_DE_2_C: To MLVDS_DE_2. Controls DIR Rx20_P/N, Backplane trigger channel 6
set_property PACKAGE_PIN L12      [get_ports {trig_dir_o[6]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[6]}]

# FPGA MLVDS_DE_1_C: To MLVDS_DE_1. Controls DIR Tx20_P/N, Backplane trigger channel 7
set_property PACKAGE_PIN H12      [get_ports {trig_dir_o[7]}]
set_property IOSTANDARD LVCMOS15  [get_ports {trig_dir_o[7]}]

#######################################################################
##                      AFC Diagnostics Contraints                   ##
#######################################################################

# FPGA MMC_FPGA_SSEL_C: From MMC_FPGA_SSEL
set_property PACKAGE_PIN N4      [get_ports diag_spi_cs_i]
set_property IOSTANDARD LVCMOS25 [get_ports diag_spi_cs_i]

# FPGA MMC_FPGA_MOSI_C: From MMC_FPGA_MOSI
set_property PACKAGE_PIN P5      [get_ports diag_spi_si_i]
set_property IOSTANDARD LVCMOS25 [get_ports diag_spi_si_i]

# FPGA MMC_FPGA_MISO_C: To MMC_FPGA_MISO
set_property PACKAGE_PIN R6      [get_ports diag_spi_so_o]
set_property IOSTANDARD LVCMOS25 [get_ports diag_spi_so_o]

# FPGA MMC_FPGA_SCK_C: From MMC_FPGA_SCK
set_property PACKAGE_PIN R5      [get_ports diag_spi_clk_i]
set_property IOSTANDARD LVCMOS25 [get_ports diag_spi_clk_i]

#######################################################################
##                      SPI Flash Constraints                        ##
#######################################################################
#
# FPGA FLASH_FCS_B
# set_property PACKAGE_PIN Y27     [get_ports spi_cs_n_o]
# set_property IOSTANDARD LVCMOS25 [get_ports spi_cs_n_o]
#
# FPGA FLASH_SI_D0
# set_property PACKAGE_PIN V28     [get_ports {spi_mosi_o[0]}]
# set_property IOSTANDARD LVCMOS25 [get_ports {spi_mosi_o[0]}]
#
# FPGA FLASH_Q_D1
# set_property PACKAGE_PIN V29     [get_ports {spi_mosi_o[1]}]
# set_property IOSTANDARD LVCMOS25 [get_ports {spi_mosi_o[1]}]
#
# FPGA FLASH_SI_D2
# set_property PACKAGE_PIN V26     [get_ports {spi_mosi_o[2]}]
# set_property IOSTANDARD LVCMOS25 [get_ports {spi_mosi_o[2]}]
#
# FPGA FLASH_SI_D3
# set_property PACKAGE_PIN V27     [get_ports {spi_mosi_o[3]}]
# set_property IOSTANDARD LVCMOS25 [get_ports {spi_mosi_o[3]}]
#
# FPGA FPGA_CCLK
# set_property PACKAGE_PIN W11     [get_ports spi_sclk_o]
# set_property IOSTANDARD LVCMOS25 [get_ports spi_sclk_o]
#

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

# FPGA FMC1_PRSNT_M2C_N
set_property PACKAGE_PIN M9      [get_ports fmc0_prsnt_m2c_n_i]
set_property IOSTANDARD LVCMOS25 [get_ports fmc0_prsnt_m2c_n_i]

# FPGA I2C SCL
set_property PACKAGE_PIN P6      [get_ports board_i2c_scl_b]
set_property IOSTANDARD LVCMOS25 [get_ports board_i2c_scl_b]
# FPGA I2C SDA
set_property PACKAGE_PIN R11     [get_ports board_i2c_sda_b]
set_property IOSTANDARD LVCMOS25 [get_ports board_i2c_sda_b]

#######################################################################
##                      FMC Connector HPC2                           ##
#######################################################################
#
# FPGA FMC2_PRSNT_M2C_N
set_property PACKAGE_PIN AE31    [get_ports fmc1_prsnt_m2c_n_i]
set_property IOSTANDARD LVCMOS25 [get_ports fmc1_prsnt_m2c_n_i]

# I2C accessible through board_i2c_sda behind a PCA9547 I2C switch

#######################################################################
##                          PCIe constraints                        ##
#######################################################################

# PCIe clock
# MGT216_CLK0_N: FCLK_GTP216_CLK0_N -> MGTREFCLK0N_216
set_property PACKAGE_PIN G18                     [get_ports pcie_clk_n_i]
# MGT216_CLK0_P: FCLK_GTP216_CLK0_P -> MGTREFCLK0P_216
set_property PACKAGE_PIN H18                     [get_ports pcie_clk_p_i]

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
