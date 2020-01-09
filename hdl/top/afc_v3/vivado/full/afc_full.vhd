------------------------------------------------------------------------------
-- Title      : AFC design with full access to the board peripherals
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2020-01-08
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: AFC design with full access to the board peripherals
-------------------------------------------------------------------------------
-- Copyright (c) 2019 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2020-01-08  1.0      lucas.russo        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- Trigger definitions
use work.trigger_common_pkg.all;
-- AFC definitions
use work.afc_base_pkg.all;
-- IP cores constants
use work.ipcores_pkg.all;

entity afc_full is
port (
  ---------------------------------------------------------------------------
  -- Clocking pins
  ---------------------------------------------------------------------------
  sys_clk_p_i                              : in std_logic;
  sys_clk_n_i                              : in std_logic;

  aux_clk_p_i                              : in std_logic;
  aux_clk_n_i                              : in std_logic;

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
  trig_b                                   : inout std_logic_vector(c_NUM_TRIG-1 downto 0);

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

  board_i2c_scl_b                          : inout std_logic;
  board_i2c_sda_b                          : inout std_logic;

  ---------------------------------------------------------------------------
  -- Flash memory SPI interface
  ---------------------------------------------------------------------------

  spi_sclk_o                               : out std_logic;
  spi_cs_n_o                               : out std_logic;
  spi_mosi_o                               : out std_logic;
  spi_miso_i                               : in  std_logic := '0'
);
end entity afc_full;

architecture top of afc_full is

  constant c_NUM_USER_IRQ                  : natural := 1;

  -----------------------------------------------------------------------------
  -- Crossbar SDB layout.
  -----------------------------------------------------------------------------

  -- Number of slaves
  constant c_slaves                        : natural := 1;
  -- Number of masters
  constant c_masters                       : natural := 1;            -- Top master.

  constant c_layout_raw : t_sdb_record_array(c_slaves-1 downto 0) :=
  (
    0 => f_sdb_auto_device(c_DUMMY_SDB_DEVICE,             true)      -- Test interface
  );

  constant c_layout                        : t_sdb_record_array := f_sdb_auto_layout(c_layout_raw);
  -- Self Describing Bus ROM Address. It will be an addressed slave as well.
  constant c_sdb_address                   : t_wishbone_address := f_sdb_auto_sdb   (c_layout_raw);

  signal cbar_slave_in                     : t_wishbone_slave_in_array (c_masters-1 downto 0);
  signal cbar_slave_out                    : t_wishbone_slave_out_array(c_masters-1 downto 0);
  signal cbar_master_in                    : t_wishbone_master_in_array(c_slaves-1 downto 0) := (others => c_DUMMY_WB_MASTER_IN);
  signal cbar_master_out                   : t_wishbone_master_out_array(c_slaves-1 downto 0);

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  signal clk_sys                           : std_logic;
  signal clk_sys_rstn                      : std_logic;
  signal clk_aux                           : std_logic;
  signal clk_aux_rstn                      : std_logic;
  signal clk_200mhz                        : std_logic;
  signal clk_200mhz_rstn                   : std_logic;
  signal clk_pcie                          : std_logic;
  signal clk_pcie_rstn                     : std_logic;

  signal pcb_rev_id                        : std_logic_vector(3 downto 0);

  signal irq_user                          : std_logic_vector(c_NUM_USER_IRQ + 5 downto 6) := (others => '0');

  signal trig_out                          : t_trig_channel_array(c_NUM_TRIG-1 downto 0);
  signal trig_in                           : t_trig_channel_array(c_NUM_TRIG-1 downto 0) := (others => c_trig_channel_dummy);

  signal trig_dbg                          : std_logic_vector(c_NUM_TRIG-1 downto 0);
  signal trig_dbg_data_sync                : std_logic_vector(c_NUM_TRIG-1 downto 0);
  signal trig_dbg_data_degliteched         : std_logic_vector(c_NUM_TRIG-1 downto 0);

  signal app_wb_out                        : t_wishbone_master_out;
  signal app_wb_in                         : t_wishbone_master_in :=
  (
    ack => '1',
    err => '0',
    rty => '0',
    stall => '0',
    dat => (others => '0')
  );

begin

  cmp_afc_base : afc_base
    generic map (
      --  If true, instantiate a VIC/UART/DIAG/SPI.
      g_WITH_VIC                               => true,
      g_WITH_UART_MASTER                       => true,
      g_WITH_DIAG                              => true,
      g_WITH_TRIGGER                           => true,
      g_WITH_SPI                               => true,
      g_WITH_BOARD_I2C                         => true,
      -- Number of user interrupts
      g_NUM_USER_IRQ                           => c_NUM_USER_IRQ,
      -- Bridge SDB record of the application meta-data. If false, no address is
      -- going to be reserved for the application side.
      g_WITH_APP_SDB_BRIDGE                    => true,
      g_APP_SDB_BRIDGE_ADDR                    => c_sdb_address
    )
    port map (
      ---------------------------------------------------------------------------
      -- Clocking pins
      ---------------------------------------------------------------------------
      sys_clk_p_i                              => sys_clk_p_i,
      sys_clk_n_i                              => sys_clk_n_i,

      aux_clk_p_i                              => aux_clk_p_i,
      aux_clk_n_i                              => aux_clk_n_i,

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
      trig_dir_o                               => trig_dir_o,
      trig_b                                   => trig_b,

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
      pcb_rev_id_i                             => pcb_rev_id,

      ---------------------------------------------------------------------------
      --  User part
      ---------------------------------------------------------------------------

      --  Clocks and reset.
      clk_sys_o                                => clk_sys,
      rst_sys_n_o                              => rst_sys_n,

      clk_aux_o                                => clk_aux,
      rst_aux_n_o                              => rst_aux_n,

      clk_200mhz_o                             => clk_200mhz,
      rst_200mhz_n_o                           => rst_200mhz_n,

      clk_pcie_o                               => clk_pcie,
      rst_pcie_n_o                             => rst_pcie_n,

      --  Interrupts
      irq_user_i                               => irq_user,

      -- Trigger
      trig_out_o                               => trig_out,
      trig_in_i                                => trig_in,

      trig_dbg_o                               => trig_dbg,
      trig_dbg_data_sync_o                     => trig_dbg_data_sync,
      trig_dbg_data_degliteched_o              => trig_dbg_data_degliteched,

      --  The wishbone bus from the pcie/host to the application
      --  LSB addresses are not available (used by the carrier).
      --  For the exact used addresses see SDB Description.
      --  This is a pipelined wishbone with byte granularity.
      app_wb_o                                 => app_wb_out,
      app_wb_i                                 => app_wb_in
    );

  pcb_rev_id <= (others => '0');

  cmp_interconnect_dev : xwb_sdb_crossbar
  generic map(
    g_num_masters                              => c_masters,
    g_num_slaves                               => c_slaves,
    g_registered                               => true,
    g_wraparound                               => true, -- Should be true for nested buses
    g_layout                                   => c_layout,
    g_sdb_addr                                 => c_sdb_address
  )
  port map(
    clk_sys_i                                  => clk_sys,
    rst_n_i                                    => rst_sys_n,
    -- Master connections (INTERCON is a slave)
    slave_i                                    => cbar_slave_in,
    slave_o                                    => cbar_slave_out,
    -- Slave connections (INTERCON is a master)
    master_i                                   => cbar_master_in,
    master_o                                   => cbar_master_out
  );

  cbar_slave_in(0) <= app_wb_out;
  app_wb_in <= cbar_slave_out(0);

  -- Unused
  cbar_master_in(0) <= c_DUMMY_WB_MASTER_IN;

end architecture top;
