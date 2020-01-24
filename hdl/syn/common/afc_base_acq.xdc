#######################################################################
##                      Artix 7 AMC V3                               ##
#######################################################################

#######################################################################
##                      FMC Connector HPC1                           ##
#######################################################################

###NET  "fmc1_prsnt_i"                            LOC =  | IOSTANDARD = "LVCMOS25";   // Connected to CPU
###NET  "fmc1_pg_m2c_i"                           LOC =  | IOSTANDARD = "LVCMOS25";   // Connected to CPU

#######################################################################
##                      FMC Connector HPC2                           ##
#######################################################################

###NET  "fmc2_prsnt_i"                            LOC =  | IOSTANDARD = "LVCMOS25";   // Connected to CPU
###NET  "fmc2_pg_m2c_i"                           LOC =  | IOSTANDARD = "LVCMOS25";   // Connected to CPU

#######################################################################
##                          Clocks                                   ##
#######################################################################

# ADC generated clocks
# For now, we are just using the "clk_aux" related constraints directly
#
#create_generated_clock -name fs1_ref_clk         [get_pins -hier -filter {NAME =~ *cmp_afc_base/*cmp_aux_sys_pll*/cmp_sys_pll*/CLKOUT0}]
#set fs1_ref_clk_period                           [get_property PERIOD [get_clocks fs1_ref_clk]]
#
#create_generated_clock -name fs2_ref_clk         [get_pins -hier -filter {NAME =~ *cmp_afc_base/*cmp_aux_sys_pll*/cmp_sys_pll*/CLKOUT0}]
#set fs2_ref_clk_period                           [get_property PERIOD [get_clocks fs2_ref_clk]]

#######################################################################
##                              CDC                                  ##
#######################################################################

# From Wishbone To ADC. These are slow control registers taken care of synched by FFs.
set_max_delay -datapath_only -from               [get_clocks clk_sys] -to [get_clocks clk_aux]    $clk_sys_period
set_max_delay -datapath_only -from               [get_clocks clk_sys] -to [get_clocks clk_aux]    $clk_sys_period

# From ADC/ADC To Wishbone. These are status registers taken care of synched by FFs.
set_max_delay -datapath_only -from               [get_clocks clk_aux]    -to [get_clocks clk_sys] $clk_aux_period
set_max_delay -datapath_only -from               [get_clocks clk_aux]    -to [get_clocks clk_sys] $clk_aux_period

# FIFO CDC timimng. Using < faster clock period
set_max_delay -datapath_only -from               [get_clocks clk_pll_i]   -to [get_clocks clk_aux]   $clk_pll_ddr_period_less
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks clk_pll_i]      $clk_pll_ddr_period_less

set_max_delay -datapath_only -from               [get_clocks clk_pll_i]   -to [get_clocks clk_aux]   $clk_pll_ddr_period_less
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks clk_pll_i]      $clk_pll_ddr_period_less

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

# Acquisition core register CDC
set_max_delay -datapath_only -from               [get_pins -hier -filter {NAME =~ *acq_core/*acq_fc_fifo/lmt_*_pkt*/C}] -to [get_clocks clk_pll_i] $clk_pll_ddr_period
set_max_delay -datapath_only -from               [get_pins -hier -filter {NAME =~ *acq_core/*acq_fc_fifo/lmt_shots*/C}] -to [get_clocks clk_pll_i] $clk_pll_ddr_period
set_max_delay -datapath_only -from               [get_pins -hier -filter {NAME =~ *acq_core/*acq_fc_fifo/lmt_curr_chan*/C}] -to [get_clocks clk_pll_i] $clk_pll_ddr_period

set_max_delay -datapath_only -from               [get_pins -hier -filter {NAME =~ *acq_core/*acq_ddr3_iface/lmt_*_pkt*/C}] -to [get_clocks clk_pll_i] $clk_pll_ddr_period
set_max_delay -datapath_only -from               [get_pins -hier -filter {NAME =~ *acq_core/*acq_ddr3_iface/lmt_shots*/C}] -to [get_clocks clk_pll_i] $clk_pll_ddr_period
set_max_delay -datapath_only -from               [get_pins -hier -filter {NAME =~ *acq_core/*acq_ddr3_iface/lmt_curr_chan*/C}] -to [get_clocks clk_pll_i] $clk_pll_ddr_period

# This path is only valid after acq_start signal, which is controlled by software and
# is activated many many miliseconds after all of the other. So, give it 2x the clock
# period
set_max_delay -datapath_only -from [get_pins -hier -filter {NAME =~ *acq_core/*/regs_o_reg[acq_chan_ctl_which_o][*]/C}] -to [get_pins -hier -filter {NAME =~ *acq_core/*/acq_in_post_trig_reg/D}] 8.000
set_max_delay -datapath_only -from [get_pins -hier -filter {NAME =~ *acq_core/*/regs_o_reg[acq_chan_ctl_which_o][*]/C}] -to [get_clocks clk_aux] 8.000
set_max_delay -datapath_only -from [get_pins -hier -filter {NAME =~ *acq_core/*/regs_o_reg[acq_chan_ctl_which_o][*]/C}] -to [get_clocks clk_aux] 8.000

# This path is only valid after acq_start
# signal, which is controlled by software and
# is activated many many miliseconds after
# all of the other. So, give it 1x the
# destination clock period
set_max_delay -datapath_only -from               [get_pins -hier -filter {NAME =~ *acq_core/*acq_core_regs/*/C}] -to [get_clocks clk_sys] $clk_sys_period

# Use Distributed RAMs for FMC ACQ FIFOs. They are small and sparse.
set_property RAM_STYLE DISTRIBUTED [get_cells -hier -filter {NAME =~ */cmp_acq_fc_fifo/cmp_fc_source/*/*ram_reg*}]

# Use Distributed RAMs for ACQ Multishot FC source
set_property RAM_STYLE DISTRIBUTED [get_cells -hier -filter {NAME =~ */cmp_acq_multishot_dpram/cmp_fc_source*/*ram_reg*}]

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
#
## The FMC #1 is poor placed on PCB, so we constraint it to the rightmost clock regions of the FPGA
#create_pblock GRP_fmc1
#add_cells_to_pblock [get_pblocks GRP_fmc1] [get_cells -hier -filter {NAME =~ *cmp1_xwb_fmc250m_4ch/*}]
#resize_pblock [get_pblocks GRP_fmc1] -add {CLOCKREGION_X1Y2:CLOCKREGION_X1Y4}
#
#create_pblock GRP_fmc2
#add_cells_to_pblock [get_pblocks GRP_fmc2] [get_cells -hier -filter {NAME =~ *cmp2_xwb_fmc250m_4ch/*}]
#resize_pblock [get_pblocks GRP_fmc2] -add {CLOCKREGION_X0Y0:CLOCKREGION_X0Y2}
#
## Constraint Position Calc Cores
#create_pblock GRP_position_calc_core1
#add_cells_to_pblock [get_pblocks GRP_position_calc_core1] [get_cells -hier -filter {NAME =~ *cmp1_xwb_position_calc_core/cmp_wb_position_calc_core/*}]
#resize_pblock [get_pblocks GRP_position_calc_core1] -add {CLOCKREGION_X1Y2:CLOCKREGION_X1Y4}
#
#create_pblock GRP_position_calc_core2
#add_cells_to_pblock [get_pblocks GRP_position_calc_core2] [get_cells -hier -filter {NAME =~ *cmp2_xwb_position_calc_core/cmp_wb_position_calc_core/*}]
#resize_pblock [get_pblocks GRP_position_calc_core2] -add {CLOCKREGION_X0Y0:CLOCKREGION_X0Y2}
#
## Place acquisition core 0
#create_pblock GRP_acq_core_0
#add_cells_to_pblock [get_pblocks GRP_acq_core_0] [get_cells -hier -filter {NAME =~ */cmp_wb_facq_core_mux/gen_facq_core[0].*}]
#resize_pblock [get_pblocks GRP_acq_core_0] -add {CLOCKREGION_X0Y3:CLOCKREGION_X1Y3} -remove {CLOCKREGION_X0Y4:CLOCKREGION_X1Y4}
