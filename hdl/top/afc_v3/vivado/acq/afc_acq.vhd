------------------------------------------------------------------------------
-- Title      : AFC design with Acquisition Core + 2 Trigger Muxes
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2020-01-17
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: AFC design with Acquisition Core + 2 Trigger Muxes
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2020-01-17  1.0      lucas.russo        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- Custom Wishbone Modules
use work.ifc_wishbone_pkg.all;
-- Custom common cores
use work.ifc_common_pkg.all;
-- Trigger definitions
use work.trigger_common_pkg.all;
-- Trigger Modules
use work.trigger_pkg.all;
-- AFC definitions
use work.afc_base_pkg.all;
-- IP cores constants
use work.ipcores_pkg.all;
-- Meta Package
use work.synthesis_descriptor_pkg.all;
-- Data Acquisition core
use work.acq_core_pkg.all;
-- AXI cores
use work.pcie_cntr_axi_pkg.all;

entity afc_acq is
port (
  ---------------------------------------------------------------------------
  -- Clocking pins
  ---------------------------------------------------------------------------
  sys_clk_p_i                                : in std_logic;
  sys_clk_n_i                                : in std_logic;

  aux_clk_p_i                                : in std_logic;
  aux_clk_n_i                                : in std_logic;

  ---------------------------------------------------------------------------
  -- Reset Button
  ---------------------------------------------------------------------------
  sys_rst_button_n_i                         : in std_logic := '1';

  ---------------------------------------------------------------------------
  -- UART pins
  ---------------------------------------------------------------------------

  uart_rxd_i                                 : in  std_logic := '1';
  uart_txd_o                                 : out std_logic;

  ---------------------------------------------------------------------------
  -- Trigger pins
  ---------------------------------------------------------------------------
  trig_dir_o                                 : out   std_logic_vector(c_NUM_TRIG-1 downto 0);
  trig_b                                     : inout std_logic_vector(c_NUM_TRIG-1 downto 0);

  ---------------------------------------------------------------------------
  -- AFC Diagnostics
  ---------------------------------------------------------------------------

  diag_spi_cs_i                              : in std_logic := '0';
  diag_spi_si_i                              : in std_logic := '0';
  diag_spi_so_o                              : out std_logic;
  diag_spi_clk_i                             : in std_logic := '0';

  ---------------------------------------------------------------------------
  -- ADN4604ASVZ
  ---------------------------------------------------------------------------
  adn4604_vadj2_clk_updt_n_o                 : out std_logic;

  ---------------------------------------------------------------------------
  -- PCIe pins
  ---------------------------------------------------------------------------

  -- DDR3 memory pins
  ddr3_dq_b                                  : inout std_logic_vector(c_ddr_dq_width-1 downto 0);
  ddr3_dqs_p_b                               : inout std_logic_vector(c_ddr_dqs_width-1 downto 0);
  ddr3_dqs_n_b                               : inout std_logic_vector(c_ddr_dqs_width-1 downto 0);
  ddr3_addr_o                                : out   std_logic_vector(c_ddr_row_width-1 downto 0);
  ddr3_ba_o                                  : out   std_logic_vector(c_ddr_bank_width-1 downto 0);
  ddr3_cs_n_o                                : out   std_logic_vector(0 downto 0);
  ddr3_ras_n_o                               : out   std_logic;
  ddr3_cas_n_o                               : out   std_logic;
  ddr3_we_n_o                                : out   std_logic;
  ddr3_reset_n_o                             : out   std_logic;
  ddr3_ck_p_o                                : out   std_logic_vector(c_ddr_ck_width-1 downto 0);
  ddr3_ck_n_o                                : out   std_logic_vector(c_ddr_ck_width-1 downto 0);
  ddr3_cke_o                                 : out   std_logic_vector(c_ddr_cke_width-1 downto 0);
  ddr3_dm_o                                  : out   std_logic_vector(c_ddr_dm_width-1 downto 0);
  ddr3_odt_o                                 : out   std_logic_vector(c_ddr_odt_width-1 downto 0);

  -- PCIe transceivers
  pci_exp_rxp_i                              : in  std_logic_vector(c_pcielanes - 1 downto 0);
  pci_exp_rxn_i                              : in  std_logic_vector(c_pcielanes - 1 downto 0);
  pci_exp_txp_o                              : out std_logic_vector(c_pcielanes - 1 downto 0);
  pci_exp_txn_o                              : out std_logic_vector(c_pcielanes - 1 downto 0);

  -- PCI clock and reset signals
  pcie_clk_p_i                               : in std_logic;
  pcie_clk_n_i                               : in std_logic;

  ---------------------------------------------------------------------------
  -- User LEDs
  ---------------------------------------------------------------------------
  leds_o                                     : out std_logic_vector(2 downto 0);

  ---------------------------------------------------------------------------
  -- FMC interface
  ---------------------------------------------------------------------------

  board_i2c_scl_b                            : inout std_logic;
  board_i2c_sda_b                            : inout std_logic

  ---------------------------------------------------------------------------
  -- Flash memory SPI interface
  ---------------------------------------------------------------------------
  --
  -- spi_sclk_o                              : out std_logic;
  -- spi_cs_n_o                              : out std_logic;
  -- spi_mosi_o                              : out std_logic;
  -- spi_miso_i                              : in  std_logic := '0'
);
end entity afc_acq;

architecture top of afc_acq is

  constant c_NUM_USER_IRQ                    : natural := 1;

  -----------------------------------------------------------------------------
  -- Crossbar SDB layout.
  -----------------------------------------------------------------------------

  -- Number of slaves
  constant c_slaves                          : natural := 4;
  -- Number of masters
  constant c_masters                         : natural := 1;            -- Top master.

  -- Slaves indexes
  constant c_slv_acq_core_0_id               : natural := 0;
  constant c_slv_acq_core_1_id               : natural := 1;
  constant c_slv_trig_mux_0_id               : natural := 2;
  constant c_slv_trig_mux_1_id               : natural := 3;
  -- These are not account in the number of slaves as these are special
  constant c_slv_sdb_repo_url_id             : natural := 4;
  constant c_slv_sdb_top_syn_id              : natural := 5;
  constant c_slv_sdb_gen_cores_id            : natural := 6;
  constant c_slv_sdb_infra_cores_id          : natural := 7;

  constant c_layout_raw : t_sdb_record_array(c_slaves+4-1 downto 0) :=
  (
    c_slv_acq_core_0_id           => f_sdb_auto_device(c_xwb_acq_core_sdb,             true),      -- Acq Core 0
    c_slv_acq_core_1_id           => f_sdb_auto_device(c_xwb_acq_core_sdb,             true),      -- Acq Core 1
    c_slv_trig_mux_0_id           => f_sdb_auto_device(c_xwb_trigger_mux_sdb,          true),      -- Trigger Mux 1 port
    c_slv_trig_mux_1_id           => f_sdb_auto_device(c_xwb_trigger_mux_sdb,          true),      -- Trigger Mux 2 port
    c_slv_sdb_repo_url_id         => f_sdb_embed_repo_url(c_sdb_repo_url),
    c_slv_sdb_top_syn_id          => f_sdb_embed_synthesis(c_sdb_top_syn_info),
    c_slv_sdb_gen_cores_id        => f_sdb_embed_synthesis(c_sdb_general_cores_syn_info),
    c_slv_sdb_infra_cores_id      => f_sdb_embed_synthesis(c_sdb_infra_cores_syn_info)
  );

  constant c_layout                          : t_sdb_record_array := f_sdb_auto_layout(c_layout_raw);
  -- Self Describing Bus ROM Address. It will be an addressed slave as well.
  constant c_sdb_address                     : t_wishbone_address := f_sdb_auto_sdb   (c_layout_raw);

  signal cbar_slave_in                       : t_wishbone_slave_in_array (c_masters-1 downto 0);
  signal cbar_slave_out                      : t_wishbone_slave_out_array(c_masters-1 downto 0);
  signal cbar_master_in                      : t_wishbone_master_in_array(c_slaves-1 downto 0) := (others => c_DUMMY_WB_MASTER_IN);
  signal cbar_master_out                     : t_wishbone_master_out_array(c_slaves-1 downto 0);

  -----------------------------------------------------------------------------
  -- Acquisition signals
  -----------------------------------------------------------------------------

  constant c_acq_fifo_size                   : natural := 256;

  -- Number of acquisition cores (FMC1, FMC2)
  constant c_acq_num_cores                   : natural := 2;
  -- Type of DDR3 core interface
  constant c_ddr_interface_type              : string := "AXIS";

  constant c_acq_addr_width                  : natural := c_ddr_addr_width;
  -- Post-Mortem Acq Cores dont need Multishot. So, set them to 0
  constant c_acq_multishot_ram_size          : t_property_value_array(c_acq_num_cores-1 downto 0) := (2048, 2048);
  constant c_acq_ddr_addr_res_width          : natural := 32;
  constant c_acq_ddr_addr_diff               : natural := c_acq_ddr_addr_res_width-c_ddr_addr_width;

  -- Number of channels per acquisition core
  constant c_acq_num_channels                : natural := 1; -- ADC for each FMC
  -- Acquisition channels IDs
  constant c_acq_adc_id                      : natural := 0;

  -- Acquisition core IDs
  constant c_acq_core_0_id                   : natural := 0;
  constant c_acq_core_1_id                   : natural := 1;

  constant c_acq_width_u64                   : unsigned(c_acq_chan_cmplt_width_log2-1 downto 0) :=
                                                 to_unsigned(64, c_acq_chan_cmplt_width_log2);
  constant c_acq_width_u128                  : unsigned(c_acq_chan_cmplt_width_log2-1 downto 0) :=
                                                 to_unsigned(128, c_acq_chan_cmplt_width_log2);
  constant c_acq_width_u256                  : unsigned(c_acq_chan_cmplt_width_log2-1 downto 0) :=
                                                 to_unsigned(256, c_acq_chan_cmplt_width_log2);
  constant c_acq_num_atoms_u4                : unsigned(c_acq_num_atoms_width_log2-1 downto 0) :=
                                                 to_unsigned(4, c_acq_num_atoms_width_log2);
  constant c_acq_num_atoms_u8                : unsigned(c_acq_num_atoms_width_log2-1 downto 0) :=
                                                 to_unsigned(8, c_acq_num_atoms_width_log2);
  constant c_acq_atom_width_u16              : unsigned(c_acq_atom_width_log2-1 downto 0) :=
                                                 to_unsigned(16, c_acq_atom_width_log2);
  constant c_acq_atom_width_u32              : unsigned(c_acq_atom_width_log2-1 downto 0) :=
                                                 to_unsigned(32, c_acq_atom_width_log2);

  constant c_facq_params_adc                 : t_facq_chan_param := (
    width                                    => to_unsigned(64, c_acq_chan_cmplt_width_log2),
    num_atoms                                => to_unsigned(4, c_acq_num_atoms_width_log2),
    atom_width                               => to_unsigned(16, c_acq_atom_width_log2) -- 2^4 = 16-bit
  );

  constant c_facq_channels                   : t_facq_chan_param_array(c_acq_num_channels-1 downto 0) :=
  (
     c_acq_adc_id            => c_facq_params_adc
  );

  signal acq_chan_array                      : t_facq_chan_array2d(c_acq_num_cores-1 downto 0, c_acq_num_channels-1 downto 0);

  -- Acquisition Wishbone
  signal acq_core_slave_i                    : t_wishbone_slave_in_array (c_acq_num_cores-1 downto 0);
  signal acq_core_slave_o                    : t_wishbone_slave_out_array(c_acq_num_cores-1 downto 0);

  -- Acquisition clocks
  signal fs1_clk                             : std_logic;
  signal fs2_clk                             : std_logic;
  signal fs1_rstn                            : std_logic;
  signal fs2_rstn                            : std_logic;
  signal fs_clk_array                        : std_logic_vector(c_acq_num_cores-1 downto 0);
  signal fs_rst_n_array                      : std_logic_vector(c_acq_num_cores-1 downto 0);
  signal fs_ce_array                         : std_logic_vector(c_acq_num_cores-1 downto 0);

  signal ddr_aximm_clk                       : std_logic;
  signal ddr_aximm_rstn                      : std_logic;
  signal ddr_aximm_r_ma_in                   : t_aximm_r_master_in;
  signal ddr_aximm_r_ma_out                  : t_aximm_r_master_out;
  signal ddr_aximm_w_ma_in                   : t_aximm_w_master_in;
  signal ddr_aximm_w_ma_out                  : t_aximm_w_master_out;

  -----------------------------------------------------------------------------
  -- FMC signals
  -----------------------------------------------------------------------------

  constant c_num_unprocessed_bits            : natural := 16;
  constant c_num_unprocessed_se_bits         : natural := 16;

  signal fmc1_adc_data_ch0                   : std_logic_vector(c_num_unprocessed_bits-1 downto 0) := (others => '0');
  signal fmc1_adc_data_ch1                   : std_logic_vector(c_num_unprocessed_bits-1 downto 0) := (others => '0');
  signal fmc1_adc_data_ch2                   : std_logic_vector(c_num_unprocessed_bits-1 downto 0) := (others => '0');
  signal fmc1_adc_data_ch3                   : std_logic_vector(c_num_unprocessed_bits-1 downto 0) := (others => '0');

  signal fmc1_adc_data_se_ch0                : std_logic_vector(c_num_unprocessed_se_bits-1 downto 0) := (others => '0');
  signal fmc1_adc_data_se_ch1                : std_logic_vector(c_num_unprocessed_se_bits-1 downto 0) := (others => '0');
  signal fmc1_adc_data_se_ch2                : std_logic_vector(c_num_unprocessed_se_bits-1 downto 0) := (others => '0');
  signal fmc1_adc_data_se_ch3                : std_logic_vector(c_num_unprocessed_se_bits-1 downto 0) := (others => '0');

  signal fmc1_adc_valid                      : std_logic := '0';

  signal fmc2_adc_data_ch0                   : std_logic_vector(c_num_unprocessed_bits-1 downto 0) := (others => '0');
  signal fmc2_adc_data_ch1                   : std_logic_vector(c_num_unprocessed_bits-1 downto 0) := (others => '0');
  signal fmc2_adc_data_ch2                   : std_logic_vector(c_num_unprocessed_bits-1 downto 0) := (others => '0');
  signal fmc2_adc_data_ch3                   : std_logic_vector(c_num_unprocessed_bits-1 downto 0) := (others => '0');

  signal fmc2_adc_data_se_ch0                : std_logic_vector(c_num_unprocessed_se_bits-1 downto 0) := (others => '0');
  signal fmc2_adc_data_se_ch1                : std_logic_vector(c_num_unprocessed_se_bits-1 downto 0) := (others => '0');
  signal fmc2_adc_data_se_ch2                : std_logic_vector(c_num_unprocessed_se_bits-1 downto 0) := (others => '0');
  signal fmc2_adc_data_se_ch3                : std_logic_vector(c_num_unprocessed_se_bits-1 downto 0) := (others => '0');

  signal fmc2_adc_valid                      : std_logic := '0';

  -----------------------------------------------------------------------------
  -- Trigger signals
  -----------------------------------------------------------------------------

  constant c_trig_sync_edge                  : string   := "positive";
  constant c_trig_num_channels               : natural  := 10; -- Arbitrary for now
  constant c_trig_intern_num                 : positive := c_trig_num_channels + c_acq_num_channels;
  constant c_trig_rcv_intern_num             : positive := 2; -- 2 FMCs
  constant c_trig_num_mux_interfaces         : natural  := c_acq_num_cores;
  constant c_trig_out_resolver               : string   := "fanout";
  constant c_trig_in_resolver                : string   := "or";
  constant c_trig_with_input_sync            : boolean  := true;
  constant c_trig_with_output_sync           : boolean  := true;

  -- Trigger RCV intern IDs
  constant c_trig_rcv_intern_chan_1_id       : natural := 0; -- Internal Channel 1
  constant c_trig_rcv_intern_chan_2_id       : natural := 1; -- Internal Channel 2

  -- Trigger core IDs
  constant c_trig_mux_0_id                   : natural := 0;
  constant c_trig_mux_1_id                   : natural := 1;

  signal trig_ref_clk                        : std_logic;
  signal trig_ref_rst_n                      : std_logic;

  signal trig_core_slave_i                   : t_wishbone_slave_in_array (c_trig_num_mux_interfaces-1 downto 0);
  signal trig_core_slave_o                   : t_wishbone_slave_out_array(c_trig_num_mux_interfaces-1 downto 0);

  signal trig_rcv_intern                     : t_trig_channel_array2d(c_trig_num_mux_interfaces-1 downto 0, c_trig_rcv_intern_num-1 downto 0);
  signal trig_pulse_transm                   : t_trig_channel_array2d(c_trig_num_mux_interfaces-1 downto 0, c_trig_intern_num-1 downto 0);
  signal trig_pulse_rcv                      : t_trig_channel_array2d(c_trig_num_mux_interfaces-1 downto 0, c_trig_intern_num-1 downto 0);

  signal trig_fmc1_channel_1                 : t_trig_channel;
  signal trig_fmc1_channel_2                 : t_trig_channel;
  signal trig_fmc2_channel_1                 : t_trig_channel;
  signal trig_fmc2_channel_2                 : t_trig_channel;

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  signal clk_sys                             : std_logic;
  signal clk_sys_rstn                        : std_logic;
  signal clk_aux                             : std_logic;
  signal clk_aux_rstn                        : std_logic;
  signal clk_200mhz                          : std_logic;
  signal clk_200mhz_rstn                     : std_logic;
  signal clk_pcie                            : std_logic;
  signal clk_pcie_rstn                       : std_logic;
  signal clk_trig_ref                        : std_logic;
  signal clk_trig_ref_rstn                   : std_logic;

  signal pcb_rev_id                          : std_logic_vector(3 downto 0);

  signal irq_user                            : std_logic_vector(c_NUM_USER_IRQ + 5 downto 6) := (others => '0');

  signal trig_out                            : t_trig_channel_array(c_NUM_TRIG-1 downto 0);
  signal trig_in                             : t_trig_channel_array(c_NUM_TRIG-1 downto 0) := (others => c_trig_channel_dummy);

  signal trig_dbg                            : std_logic_vector(c_NUM_TRIG-1 downto 0);
  signal trig_dbg_data_sync                  : std_logic_vector(c_NUM_TRIG-1 downto 0);
  signal trig_dbg_data_degliteched           : std_logic_vector(c_NUM_TRIG-1 downto 0);

  signal app_wb_out                          : t_wishbone_master_out;
  signal app_wb_in                           : t_wishbone_master_in := c_DUMMY_WB_MASTER_IN;

begin

  cmp_afc_base : afc_base
    generic map (
      --  If true, instantiate a VIC/UART/DIAG/SPI.
      g_WITH_VIC                               => true,
      g_WITH_UART_MASTER                       => true,
      g_WITH_DIAG                              => true,
      g_WITH_TRIGGER                           => true,
      g_WITH_SPI                               => false,
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
     --
     -- spi_sclk_o                               => spi_sclk_o,
     -- spi_cs_n_o                               => spi_cs_n_o,
     -- spi_mosi_o                               => spi_mosi_o,
     -- spi_miso_i                               => spi_miso_i,
     --
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
      rst_sys_n_o                              => clk_sys_rstn,

      clk_aux_o                                => clk_aux,
      rst_aux_n_o                              => clk_aux_rstn,

      clk_200mhz_o                             => clk_200mhz,
      rst_200mhz_n_o                           => clk_200mhz_rstn,

      clk_pcie_o                               => clk_pcie,
      rst_pcie_n_o                             => clk_pcie_rstn,

      clk_trig_ref_o                           => clk_trig_ref,
      rst_trig_ref_n_o                         => clk_trig_ref_rstn,

      --  Interrupts
      irq_user_i                               => irq_user,

      -- DDR memory controller interface --
      ddr_aximm_sl_aclk_o                      => ddr_aximm_clk,
      ddr_aximm_sl_aresetn_o                   => ddr_aximm_rstn,
      ddr_aximm_r_sl_i                         => ddr_aximm_r_ma_out,
      ddr_aximm_r_sl_o                         => ddr_aximm_r_ma_in,
      ddr_aximm_w_sl_i                         => ddr_aximm_w_ma_out,
      ddr_aximm_w_sl_o                         => ddr_aximm_w_ma_in,

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
    rst_n_i                                    => clk_sys_rstn,
    -- Master connections (INTERCON is a slave)
    slave_i                                    => cbar_slave_in,
    slave_o                                    => cbar_slave_out,
    -- Slave connections (INTERCON is a master)
    master_i                                   => cbar_master_in,
    master_o                                   => cbar_master_out
  );

  cbar_slave_in(0) <= app_wb_out;
  app_wb_in <= cbar_slave_out(0);

  ----------------------------------------------------------------------
  --                      Acquisition Core                            --
  ----------------------------------------------------------------------

  --------------------
  -- ADC 1 data
  --------------------

  -- FOR TESTING
  fmc1_adc_data_se_ch3 <= std_logic_vector(to_unsigned(54321, fmc1_adc_data_se_ch3'length));
  fmc1_adc_data_se_ch2 <= std_logic_vector(to_unsigned(12345, fmc1_adc_data_se_ch2'length));
  fmc1_adc_data_se_ch1 <= std_logic_vector(to_unsigned(25,    fmc1_adc_data_se_ch1'length));
  fmc1_adc_data_se_ch0 <= std_logic_vector(to_unsigned(10,    fmc1_adc_data_se_ch0'length));
  fmc1_adc_valid <= '1';

  acq_chan_array(c_acq_core_0_id, c_acq_adc_id).val(to_integer(c_facq_channels(c_acq_adc_id).width)-1 downto 0) <=
                                                                 fmc1_adc_data_se_ch3 &
                                                                 fmc1_adc_data_se_ch2 &
                                                                 fmc1_adc_data_se_ch1 &
                                                                 fmc1_adc_data_se_ch0;
  acq_chan_array(c_acq_core_0_id, c_acq_adc_id).dvalid        <= fmc1_adc_valid;
  acq_chan_array(c_acq_core_0_id, c_acq_adc_id).trig          <= trig_pulse_rcv(c_trig_mux_0_id, c_acq_adc_id).pulse;

  --------------------
  -- ADC 2 data
  --------------------

  -- FOR TESTING
  fmc2_adc_data_se_ch3 <= std_logic_vector(to_unsigned(65535, fmc2_adc_data_se_ch3'length));
  fmc2_adc_data_se_ch2 <= std_logic_vector(to_unsigned(10000, fmc2_adc_data_se_ch2'length));
  fmc2_adc_data_se_ch1 <= std_logic_vector(to_unsigned(75,    fmc2_adc_data_se_ch1'length));
  fmc2_adc_data_se_ch0 <= std_logic_vector(to_unsigned(50,    fmc2_adc_data_se_ch0'length));
  fmc2_adc_valid <= '1';

  acq_chan_array(c_acq_core_1_id, c_acq_adc_id).val(to_integer(c_facq_channels(c_acq_adc_id).width)-1 downto 0) <=
                                                                 fmc2_adc_data_se_ch3 &
                                                                 fmc2_adc_data_se_ch2 &
                                                                 fmc2_adc_data_se_ch1 &
                                                                 fmc2_adc_data_se_ch0;
  acq_chan_array(c_acq_core_1_id, c_acq_adc_id).dvalid        <= fmc2_adc_valid;
  acq_chan_array(c_acq_core_1_id, c_acq_adc_id).trig          <= trig_pulse_rcv(c_trig_mux_1_id, c_acq_adc_id).pulse;

  --------------------
  -- Clocks & Resets
  --------------------

  fs1_clk <= clk_aux;
  fs1_rstn <= clk_aux_rstn;
  fs2_clk <= clk_aux;
  fs2_rstn <= clk_aux_rstn;

  cmp_xwb_facq_core_mux : xwb_facq_core_mux
  generic map
  (
    g_interface_mode                         => PIPELINED,
    g_address_granularity                    => BYTE,
    g_acq_addr_width                         => c_acq_addr_width,
    g_acq_num_channels                       => c_acq_num_channels,
    g_facq_channels                          => c_facq_channels,
    g_ddr_payload_width                      => c_ddr_payload_width,
    g_ddr_dq_width                           => c_ddr_dq_width,
    g_ddr_addr_width                         => c_ddr_addr_width,
    g_multishot_ram_size                     => c_acq_multishot_ram_size,
    g_fifo_fc_size                           => c_acq_fifo_size,
    --g_sim_readback                           => false
    g_acq_num_cores                          => c_acq_num_cores,
    g_ddr_interface_type                     => c_ddr_interface_type,
    g_max_burst_size                         => c_ddr_datamover_bpm_burst_size
  )
  port map
  (
    fs_clk_array_i                           => fs_clk_array,
    fs_ce_array_i                            => fs_ce_array,
    fs_rst_n_array_i                         => fs_rst_n_array,

    -- Clock signals for Wishbone
    sys_clk_i                                => clk_sys,
    sys_rst_n_i                              => clk_sys_rstn,

    -- From DDR3 Controller
    ext_clk_i                                => ddr_aximm_clk,
    ext_rst_n_i                              => ddr_aximm_rstn,

    -----------------------------
    -- Wishbone Control Interface signals
    -----------------------------
    wb_slv_i                                 => acq_core_slave_i,
    wb_slv_o                                 => acq_core_slave_o,

    -----------------------------
    -- External Interface
    -----------------------------
    acq_chan_array_i                         => acq_chan_array,

    -----------------------------
    -- DDR3 SDRAM Interface
    -----------------------------
    -- AXIMM Read Channel
    ddr_aximm_r_ma_i                         => ddr_aximm_r_ma_in,
    ddr_aximm_r_ma_o                         => ddr_aximm_r_ma_out,
    -- AXIMM Write Channel
    ddr_aximm_w_ma_i                         => ddr_aximm_w_ma_in,
    ddr_aximm_w_ma_o                         => ddr_aximm_w_ma_out
  );

  fs_clk_array   <= fs2_clk & fs1_clk;
  fs_ce_array    <= (others => '1');
  fs_rst_n_array <= fs2_rstn & fs1_rstn;

  -- c_slv_acq_core_*_id is Wishbone slave index
  -- c_acq_core_*_id is Acquisition core index
  acq_core_slave_i <= cbar_master_out(c_slv_acq_core_1_id) &
                      cbar_master_out(c_slv_acq_core_0_id);
  cbar_master_in(c_slv_acq_core_0_id) <= acq_core_slave_o(c_acq_core_0_id);
  cbar_master_in(c_slv_acq_core_1_id) <= acq_core_slave_o(c_acq_core_1_id);

  ----------------------------------------------------------------------
  --                          Trigger                                 --
  ----------------------------------------------------------------------
  trig_ref_clk <= clk_trig_ref;
  trig_ref_rst_n <= clk_trig_ref_rstn;

  cmp_xwb_trigger : xwb_trigger
    generic map (
      g_address_granularity                => BYTE,
      g_interface_mode                     => PIPELINED,
      g_with_external_iface                => true,
      g_trig_num                           => c_NUM_TRIG,
      g_intern_num                         => c_trig_intern_num,
      g_rcv_intern_num                     => c_trig_rcv_intern_num,
      g_num_mux_interfaces                 => c_trig_num_mux_interfaces,
      g_out_resolver                       => c_trig_out_resolver,
      g_in_resolver                        => c_trig_in_resolver,
      g_with_input_sync                    => c_trig_with_input_sync,
      g_with_output_sync                   => c_trig_with_output_sync
    )
    port map (
      clk_i                                => clk_sys,
      rst_n_i                              => clk_sys_rstn,

      ref_clk_i                            => trig_ref_clk,
      ref_rst_n_i                          => trig_ref_rst_n,

      fs_clk_array_i                       => fs_clk_array,
      fs_rst_n_array_i                     => fs_rst_n_array,

      trig_in_i                            => trig_out,
      trig_out_o                           => trig_in,

      wb_slv_trigger_mux_i                 => trig_core_slave_i,
      wb_slv_trigger_mux_o                 => trig_core_slave_o,

      trig_rcv_intern_i                    => trig_rcv_intern,
      trig_pulse_transm_i                  => trig_pulse_transm,
      trig_pulse_rcv_o                     => trig_pulse_rcv
  );

  trig_core_slave_i <= cbar_master_out(c_slv_trig_mux_1_id) &
                       cbar_master_out(c_slv_trig_mux_0_id);
  cbar_master_in(c_slv_trig_mux_0_id)    <= trig_core_slave_o(c_trig_mux_0_id);
  cbar_master_in(c_slv_trig_mux_1_id)    <= trig_core_slave_o(c_trig_mux_1_id);

  -- Assign FMCs trigger pulses to trigger channel interfaces
  trig_fmc1_channel_1.pulse <= '0';
  trig_fmc1_channel_2.pulse <= '0';

  trig_fmc2_channel_1.pulse <= '0';
  trig_fmc2_channel_2.pulse <= '0';

  -- Assign intern triggers to trigger module
  trig_rcv_intern(c_trig_mux_0_id, c_trig_rcv_intern_chan_1_id) <= trig_fmc1_channel_1;
  trig_rcv_intern(c_trig_mux_0_id, c_trig_rcv_intern_chan_2_id) <= trig_fmc1_channel_2;
  trig_rcv_intern(c_trig_mux_1_id, c_trig_rcv_intern_chan_1_id) <= trig_fmc2_channel_1;
  trig_rcv_intern(c_trig_mux_1_id, c_trig_rcv_intern_chan_2_id) <= trig_fmc2_channel_2;

end architecture top;
