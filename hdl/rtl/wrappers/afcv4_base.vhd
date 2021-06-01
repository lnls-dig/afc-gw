------------------------------------------------------------------------------
-- Title      : AFCv4 Base wrapper design
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2021-05-31
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: AFCv4 Base wrapper design
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2021-05-31  1.0      lucas.russo        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- Trigger definitions
use work.trigger_common_pkg.all;
-- IP cores constants
use work.ipcores_pkg.all;
-- AFC Acq definitions
use work.afc_base_pkg.all;
-- AXI cores
use work.pcie_cntr_axi_pkg.all;

entity afcv4_base is
generic (
  -- system PLL parameters
  g_DIVCLK_DIVIDE                          : integer := 5;
  g_CLKBOUT_MULT_F                         : integer := 48;
  g_CLK0_DIVIDE_F                          : integer := 12;
  g_CLK0_PHASE                             : real    := 0.0;
  g_CLK1_DIVIDE                            : integer := 6;
  g_CLK1_PHASE                             : real    := 0.0;
  g_CLK2_DIVIDE                            : integer := 4;
  g_CLK2_PHASE                             : real    := 0.0;
  g_CLK3_DIVIDE                            : integer := 4;
  g_CLK3_PHASE                             : real    := 0.0;
  g_SYS_CLOCK_FREQ                         : integer := 100000000;
  -- AFC Si57x parameters
  g_AFC_SI57x_I2C_FREQ                     : integer := 400000;
  -- Whether or not to initialize oscilator with the specified values
  g_AFC_SI57x_INIT_OSC                     : boolean := true;
  -- Init Oscillator values
  g_AFC_SI57x_INIT_RFREQ_VALUE             : std_logic_vector(37 downto 0) := "00" & x"3017a66ad";
  g_AFC_SI57x_INIT_N1_VALUE                : std_logic_vector(6 downto 0) := "0000011";
  g_AFC_SI57x_INIT_HS_VALUE                : std_logic_vector(2 downto 0) := "111";
  --  If true, instantiate a VIC/UART/DIAG/SPI.
  g_WITH_VIC                               : boolean := true;
  g_WITH_UART_MASTER                       : boolean := true;
  g_WITH_DIAG                              : boolean := true;
  g_WITH_TRIGGER                           : boolean := true;
  g_WITH_SPI                               : boolean := true;
  g_WITH_AFC_SI57x                         : boolean := true;
  g_WITH_BOARD_I2C                         : boolean := true;
  -- Auxiliary clock used to sync incoming triggers in the trigger module.
  -- If false, trigger will be synch'ed with clk_sys
  g_WITH_AUX_CLK                           : boolean := true;
  -- Number of user interrupts
  g_NUM_USER_IRQ                           : natural := 1;
  -- Bridge SDB record of the application meta-data. If false, no address is
 -- going to be reserved for the application side.
  g_WITH_APP_SDB_BRIDGE                    : boolean := true;
  g_APP_SDB_BRIDGE_ADDR                    : std_logic_vector(31 downto 0) := x"0000_0000"
);
port (
  ---------------------------------------------------------------------------
  -- Clocking pins
  ---------------------------------------------------------------------------
  sys_clk_p_i                              : in std_logic;
  sys_clk_n_i                              : in std_logic;

  aux_clk_p_i                              : in std_logic := '0';
  aux_clk_n_i                              : in std_logic := '1';

  -- FP2_CLK1 clock. From clock switch
  afc_fp2_clk1_p_i                         : in std_logic := '0';
  afc_fp2_clk1_n_i                         : in std_logic := '1';

  ---------------------------------------------------------------------------
  -- Reset Button
  ---------------------------------------------------------------------------
  sys_rst_button_n_i                       : in std_logic := '1';

  ---------------------------------------------------------------------------
  -- UART pins
  ---------------------------------------------------------------------------

  uart_rxd_i                               : in  std_logic := '1';
  uart_txd_o                               : out std_logic;

  ---------------------------------------------------------------------------
  -- Trigger pins
  ---------------------------------------------------------------------------
  trig_dir_o                               : out   std_logic_vector(c_NUM_TRIG-1 downto 0);
  trig_i                                   : in    std_logic_vector(c_NUM_TRIG-1 downto 0) := (others => '0');
  trig_o                                   : out   std_logic_vector(c_NUM_TRIG-1 downto 0);

  ---------------------------------------------------------------------------
  -- AFC Diagnostics
  ---------------------------------------------------------------------------

  diag_spi_cs_i                            : in std_logic := '0';
  diag_spi_si_i                            : in std_logic := '0';
  diag_spi_so_o                            : out std_logic;
  diag_spi_clk_i                           : in std_logic := '0';

  ---------------------------------------------------------------------------
  -- ADN4604ASVZ
  ---------------------------------------------------------------------------
  adn4604_vadj2_clk_updt_n_o               : out std_logic;

  ---------------------------------------------------------------------------
  -- AFC I2C.
  ---------------------------------------------------------------------------
  -- Si57x oscillator
  afc_si57x_scl_b                          : inout std_logic;
  afc_si57x_sda_b                          : inout std_logic;

  -- Si57x oscillator output enable
  afc_si57x_oe_o                           : out   std_logic;

  ---------------------------------------------------------------------------
  -- PCIe pins
  ---------------------------------------------------------------------------

  -- DDR3 memory pins
  ddr3_dq_b                                : inout std_logic_vector(c_ddr_dq_width-1 downto 0);
  ddr3_dqs_p_b                             : inout std_logic_vector(c_ddr_dqs_width-1 downto 0);
  ddr3_dqs_n_b                             : inout std_logic_vector(c_ddr_dqs_width-1 downto 0);
  ddr3_addr_o                              : out   std_logic_vector(c_ddr_row_width-1 downto 0);
  ddr3_ba_o                                : out   std_logic_vector(c_ddr_bank_width-1 downto 0);
  ddr3_cs_n_o                              : out   std_logic_vector(0 downto 0);
  ddr3_ras_n_o                             : out   std_logic;
  ddr3_cas_n_o                             : out   std_logic;
  ddr3_we_n_o                              : out   std_logic;
  ddr3_reset_n_o                           : out   std_logic;
  ddr3_ck_p_o                              : out   std_logic_vector(c_ddr_ck_width-1 downto 0);
  ddr3_ck_n_o                              : out   std_logic_vector(c_ddr_ck_width-1 downto 0);
  ddr3_cke_o                               : out   std_logic_vector(c_ddr_cke_width-1 downto 0);
  ddr3_dm_o                                : out   std_logic_vector(c_ddr_dm_width-1 downto 0);
  ddr3_odt_o                               : out   std_logic_vector(c_ddr_odt_width-1 downto 0);

  -- PCIe transceivers
  pci_exp_rxp_i                            : in  std_logic_vector(c_pcielanes - 1 downto 0);
  pci_exp_rxn_i                            : in  std_logic_vector(c_pcielanes - 1 downto 0);
  pci_exp_txp_o                            : out std_logic_vector(c_pcielanes - 1 downto 0);
  pci_exp_txn_o                            : out std_logic_vector(c_pcielanes - 1 downto 0);

  -- PCI clock and reset signals
  pcie_clk_p_i                             : in std_logic;
  pcie_clk_n_i                             : in std_logic;

  ---------------------------------------------------------------------------
  -- User LEDs
  ---------------------------------------------------------------------------
  leds_o                                   : out std_logic_vector(2 downto 0);

  ---------------------------------------------------------------------------
  -- FMC interface
  ---------------------------------------------------------------------------

  ---- I2C interface for accessing FMC EEPROM. Connected to CPU
  --fmc0_scl_b                               : inout std_logic;
  --fmc0_sda_b                               : inout std_logic;

  -- Presence
  fmc0_prsnt_m2c_n_i                       : in std_logic := '1';

  ---- I2C interface for accessing FMC EEPROM. Connected to CPU
  --fmc1_scl_b                               : inout std_logic;
  --fmc1_sda_b                               : inout std_logic;

  -- Presence
  fmc1_prsnt_m2c_n_i                       : in std_logic := '1';

  board_i2c_scl_b                          : inout std_logic;
  board_i2c_sda_b                          : inout std_logic;

  ---------------------------------------------------------------------------
  -- Flash memory SPI interface
  ---------------------------------------------------------------------------

  spi_sclk_o                               : out std_logic;
  spi_cs_n_o                               : out std_logic;
  spi_mosi_o                               : out std_logic;
  spi_miso_i                               : in  std_logic := '0';

  ---------------------------------------------------------------------------
  -- Miscellanous AFC pins
  ---------------------------------------------------------------------------

  -- PCB version
  pcb_rev_id_i                             : in std_logic_vector(3 downto 0);

  ---------------------------------------------------------------------------
  --  User part
  ---------------------------------------------------------------------------

  --  Clocks and reset.
  clk_sys_o                                : out std_logic;
  rst_sys_n_o                              : out std_logic;

  clk_aux_o                                : out std_logic;
  rst_aux_n_o                              : out std_logic;

  clk_aux_raw_o                            : out std_logic;
  rst_aux_raw_n_o                          : out std_logic;

  clk_200mhz_o                             : out std_logic;
  rst_200mhz_n_o                           : out std_logic;

  clk_pcie_o                               : out std_logic;
  rst_pcie_n_o                             : out std_logic;

  clk_user2_o                              : out std_logic;
  rst_user2_n_o                            : out std_logic;

  clk_user3_o                              : out std_logic;
  rst_user3_n_o                            : out std_logic;

  clk_trig_ref_o                           : out std_logic;
  rst_trig_ref_n_o                         : out std_logic;

  clk_fp2_clk1_p_o                         : out std_logic;
  clk_fp2_clk1_n_o                         : out std_logic;

  --  Interrupts
  irq_user_i                               : in std_logic_vector(g_NUM_USER_IRQ + 5 downto 6) := (others => '0');

  -- DDR memory controller interface --
  ddr_aximm_sl_aclk_o                      : out std_logic;
  ddr_aximm_sl_aresetn_o                   : out std_logic;
  -- AXIMM Read Channel
  ddr_aximm_r_sl_i                         : in t_aximm_r_slave_in := cc_dummy_aximm_r_slave_in;
  ddr_aximm_r_sl_o                         : out t_aximm_r_slave_out;
  -- AXIMM Write Channel
  ddr_aximm_w_sl_i                         : in t_aximm_w_slave_in := cc_dummy_aximm_w_slave_in;
  ddr_aximm_w_sl_o                         : out t_aximm_w_slave_out;

  -- Trigger
  trig_out_o                               : out t_trig_channel_array(c_NUM_TRIG-1 downto 0);
  trig_in_i                                : in  t_trig_channel_array(c_NUM_TRIG-1 downto 0) := (others => c_trig_channel_dummy);

  trig_dbg_o                               : out std_logic_vector(c_NUM_TRIG-1 downto 0);
  trig_dbg_data_sync_o                     : out std_logic_vector(c_NUM_TRIG-1 downto 0);
  trig_dbg_data_degliteched_o              : out std_logic_vector(c_NUM_TRIG-1 downto 0);

  -- AFC Si57x
  afc_si57x_ext_wr_i                       : in  std_logic := '0';
  afc_si57x_ext_rfreq_value_i              : in  std_logic_vector(37 downto 0) := (others => '0');
  afc_si57x_ext_n1_value_i                 : in  std_logic_vector(6 downto 0) := (others => '0');
  afc_si57x_ext_hs_value_i                 : in  std_logic_vector(2 downto 0) := (others => '0');
  afc_si57x_sta_reconfig_done_o            : out std_logic;

  afc_si57x_oe_i                           : in std_logic := '1';
  afc_si57x_addr_i                         : in std_logic_vector(7 downto 0) := "10101010";

  --  The wishbone bus from the pcie/host to the application
  --  LSB addresses are not available (used by the carrier).
  --  For the exact used addresses see SDB Description.
  --  This is a pipelined wishbone with byte granularity.
  app_wb_o                                 : out t_wishbone_master_out;
  app_wb_i                                 : in  t_wishbone_master_in := c_DUMMY_WB_MASTER_IN
);
end entity afcv4_base;

architecture top of afcv4_base is

begin

  cmp_afc_base : afc_base
    generic map (
      -- system PLL parameters
      g_DIVCLK_DIVIDE                          => g_DIVCLK_DIVIDE,
      g_CLKBOUT_MULT_F                         => g_CLKBOUT_MULT_F,
      g_CLK0_DIVIDE_F                          => g_CLK0_DIVIDE_F,
      g_CLK0_PHASE                             => g_CLK0_PHASE,
      g_CLK1_DIVIDE                            => g_CLK1_DIVIDE,
      g_CLK1_PHASE                             => g_CLK1_PHASE,
      g_CLK2_DIVIDE                            => g_CLK2_DIVIDE,
      g_CLK2_PHASE                             => g_CLK2_PHASE,
      g_CLK3_DIVIDE                            => g_CLK3_DIVIDE,
      g_CLK3_PHASE                             => g_CLK3_PHASE,
      g_SYS_CLOCK_FREQ                         => g_SYS_CLOCK_FREQ,
      -- AFC Si57x parameters
      g_AFC_SI57x_I2C_FREQ                     => g_AFC_SI57x_I2C_FREQ,
      -- Whether or not to initialize oscilator with the specified values
      g_AFC_SI57x_INIT_OSC                     => g_AFC_SI57x_INIT_OSC,
      -- Init Oscillator values
      g_AFC_SI57x_INIT_RFREQ_VALUE             => g_AFC_SI57x_INIT_RFREQ_VALUE,
      g_AFC_SI57x_INIT_N1_VALUE                => g_AFC_SI57x_INIT_N1_VALUE,
      g_AFC_SI57x_INIT_HS_VALUE                => g_AFC_SI57x_INIT_HS_VALUE,
      --  If true, instantiate a VIC/UART/DIAG/SPI.
      g_WITH_VIC                               => g_WITH_VIC,
      g_WITH_UART_MASTER                       => g_WITH_UART_MASTER,
      g_WITH_DIAG                              => g_WITH_DIAG,
      g_WITH_TRIGGER                           => g_WITH_TRIGGER,
      g_WITH_SPI                               => g_WITH_SPI,
      g_WITH_AFC_SI57x                         => g_WITH_AFC_SI57x,
      g_WITH_BOARD_I2C                         => g_WITH_BOARD_I2C,
      -- Select between tristate and bidirection triggers. AFCv3 and lower
      -- has a tristate port and AFCv4 has bidirectional ones
      g_TRIGGER_TRISTATE                       => false,
      -- Auxiliary clock used to sync incoming triggers in the trigger module.
      -- If false, trigger will be synch'ed with clk_sys
      g_WITH_AUX_CLK                           => g_WITH_AUX_CLK,
      -- Number of user interrupts
      g_NUM_USER_IRQ                           => g_NUM_USER_IRQ,
      -- Bridge SDB record of the application meta-data. If false, no address is
      -- going to be reserved for the application side.
      g_WITH_APP_SDB_BRIDGE                    => g_WITH_APP_SDB_BRIDGE,
      g_APP_SDB_BRIDGE_ADDR                    => g_APP_SDB_BRIDGE_ADDR
    )
    port map (
      ---------------------------------------------------------------------------
      -- Clocking pins
      ---------------------------------------------------------------------------
      sys_clk_p_i                              => sys_clk_p_i,
      sys_clk_n_i                              => sys_clk_n_i,

      aux_clk_p_i                              => aux_clk_p_i,
      aux_clk_n_i                              => aux_clk_n_i,

      afc_fp2_clk1_p_i                         => afc_fp2_clk1_p_i,
      afc_fp2_clk1_n_i                         => afc_fp2_clk1_n_i,

      ---------------------------------------------------------------------------
      -- Reset Button
      ---------------------------------------------------------------------------
      sys_rst_button_n_i                       => sys_rst_button_n_i,

      ---------------------------------------------------------------------------
      -- UART pins
      ---------------------------------------------------------------------------

      uart_rxd_i                               => uart_rxd_i,
      uart_txd_o                               => uart_txd_o,

      ---------------------------------------------------------------------------
      -- Trigger pins
      ---------------------------------------------------------------------------
      trig_i                                   => trig_i,
      trig_o                                   => trig_o,
      trig_dir_o                               => trig_dir_o,

      ---------------------------------------------------------------------------
      -- AFC Diagnostics
      ---------------------------------------------------------------------------

      diag_spi_cs_i                            => diag_spi_cs_i,
      diag_spi_si_i                            => diag_spi_si_i,
      diag_spi_so_o                            => diag_spi_so_o,
      diag_spi_clk_i                           => diag_spi_clk_i,

      ---------------------------------------------------------------------------
      -- ADN4604ASVZ
      ---------------------------------------------------------------------------
      adn4604_vadj2_clk_updt_n_o               => adn4604_vadj2_clk_updt_n_o,

      ---------------------------------------------------------------------------
      -- AFC I2C.
      ---------------------------------------------------------------------------
      -- Si57x oscillator
      afc_si57x_scl_b                          => afc_si57x_scl_b,
      afc_si57x_sda_b                          => afc_si57x_sda_b,

      -- Si57x oscillator output enable
      afc_si57x_oe_o                           => afc_si57x_oe_o,

      ---------------------------------------------------------------------------
      -- PCIe pins
      ---------------------------------------------------------------------------

      -- DDR3 memory pins
      ddr3_dq_b                                => ddr3_dq_b,
      ddr3_dqs_p_b                             => ddr3_dqs_p_b,
      ddr3_dqs_n_b                             => ddr3_dqs_n_b,
      ddr3_addr_o                              => ddr3_addr_o,
      ddr3_ba_o                                => ddr3_ba_o,
      ddr3_cs_n_o                              => ddr3_cs_n_o,
      ddr3_ras_n_o                             => ddr3_ras_n_o,
      ddr3_cas_n_o                             => ddr3_cas_n_o,
      ddr3_we_n_o                              => ddr3_we_n_o,
      ddr3_reset_n_o                           => ddr3_reset_n_o,
      ddr3_ck_p_o                              => ddr3_ck_p_o,
      ddr3_ck_n_o                              => ddr3_ck_n_o,
      ddr3_cke_o                               => ddr3_cke_o,
      ddr3_dm_o                                => ddr3_dm_o,
      ddr3_odt_o                               => ddr3_odt_o,

      -- PCIe transceivers
      pci_exp_rxp_i                            => pci_exp_rxp_i,
      pci_exp_rxn_i                            => pci_exp_rxn_i,
      pci_exp_txp_o                            => pci_exp_txp_o,
      pci_exp_txn_o                            => pci_exp_txn_o,

      -- PCI clock and reset signals
      pcie_clk_p_i                             => pcie_clk_p_i,
      pcie_clk_n_i                             => pcie_clk_n_i,

      ---------------------------------------------------------------------------
      -- User LEDs
      ---------------------------------------------------------------------------
      leds_o                                   => leds_o,

      ---------------------------------------------------------------------------
      -- FMC interface
      ---------------------------------------------------------------------------

      board_i2c_scl_b                          => board_i2c_scl_b,
      board_i2c_sda_b                          => board_i2c_sda_b,

      ---------------------------------------------------------------------------
      -- Flash memory SPI interface
      ---------------------------------------------------------------------------

      spi_sclk_o                               => spi_sclk_o,
      spi_cs_n_o                               => spi_cs_n_o,
      spi_mosi_o                               => spi_mosi_o,
      spi_miso_i                               => spi_miso_i,

      ---------------------------------------------------------------------------
      -- Miscellanous AFC pins
      ---------------------------------------------------------------------------

      -- PCB version
      pcb_rev_id_i                             => pcb_rev_id_i,

      ---------------------------------------------------------------------------
      --  User part
      ---------------------------------------------------------------------------

      --  Clocks and reset.
      clk_sys_o                                => clk_sys_o,
      rst_sys_n_o                              => rst_sys_n_o,

      clk_aux_o                                => clk_aux_o,
      rst_aux_n_o                              => rst_aux_n_o,

      clk_aux_raw_o                            => clk_aux_raw_o,
      rst_aux_raw_n_o                          => rst_aux_raw_n_o,

      clk_200mhz_o                             => clk_200mhz_o,
      rst_200mhz_n_o                           => rst_200mhz_n_o,

      clk_pcie_o                               => clk_pcie_o,
      rst_pcie_n_o                             => rst_pcie_n_o,

      clk_user2_o                              => clk_user2_o,
      rst_user2_n_o                            => rst_user2_n_o,

      clk_user3_o                              => clk_user3_o,
      rst_user3_n_o                            => rst_user3_n_o,

      clk_trig_ref_o                           => clk_trig_ref_o,
      rst_trig_ref_n_o                         => rst_trig_ref_n_o,

      clk_fp2_clk1_p_o                         => clk_fp2_clk1_p_o,
      clk_fp2_clk1_n_o                         => clk_fp2_clk1_n_o,

      --  Interrupts
      irq_user_i                               => irq_user_i,

      -- DDR memory controller interface
      ddr_aximm_sl_aclk_o                      => ddr_aximm_sl_aclk_o,
      ddr_aximm_sl_aresetn_o                   => ddr_aximm_sl_aresetn_o,
      ddr_aximm_r_sl_i                         => ddr_aximm_r_sl_i,
      ddr_aximm_r_sl_o                         => ddr_aximm_r_sl_o,
      ddr_aximm_w_sl_i                         => ddr_aximm_w_sl_i,
      ddr_aximm_w_sl_o                         => ddr_aximm_w_sl_o,

      -- Trigger
      trig_out_o                               => trig_out_o,
      trig_in_i                                => trig_in_i,

      trig_dbg_o                               => trig_dbg_o,
      trig_dbg_data_sync_o                     => trig_dbg_data_sync_o,
      trig_dbg_data_degliteched_o              => trig_dbg_data_degliteched_o,

      -- AFC Si57x
      afc_si57x_ext_wr_i                       => afc_si57x_ext_wr_i,
      afc_si57x_ext_rfreq_value_i              => afc_si57x_ext_rfreq_value_i,
      afc_si57x_ext_n1_value_i                 => afc_si57x_ext_n1_value_i,
      afc_si57x_ext_hs_value_i                 => afc_si57x_ext_hs_value_i,
      afc_si57x_sta_reconfig_done_o            => afc_si57x_sta_reconfig_done_o,

      afc_si57x_oe_i                           => afc_si57x_oe_i,
      afc_si57x_addr_i                         => afc_si57x_addr_i,

      app_wb_o                                 => app_wb_o,
      app_wb_i                                 => app_wb_i
    );

end architecture top;
