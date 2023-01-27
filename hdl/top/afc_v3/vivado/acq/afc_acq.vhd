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
-- AFC Acq definitions
use work.afc_base_acq_pkg.all;
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
  -- Acquisition signals
  -----------------------------------------------------------------------------

  constant c_acq_fifo_size                   : natural := 256;

  -- Number of acquisition cores (FMC1, FMC2)
  constant c_acq_num_cores                   : natural := 2;
  -- Acquisition core IDs
  constant c_acq_core_0_id                   : natural := 0;
  constant c_acq_core_1_id                   : natural := 1;

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

  -- Acquisition clocks
  signal fs1_clk                             : std_logic;
  signal fs2_clk                             : std_logic;
  signal fs1_rstn                            : std_logic;
  signal fs2_rstn                            : std_logic;
  signal fs_clk_array                        : std_logic_vector(c_acq_num_cores-1 downto 0);
  signal fs_rst_n_array                      : std_logic_vector(c_acq_num_cores-1 downto 0);
  signal fs_ce_array                         : std_logic_vector(c_acq_num_cores-1 downto 0);

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

  constant c_trig_mux_num_cores              : natural  := 2;
  constant c_trig_mux_sync_edge              : string   := "positive";
  constant c_trig_mux_num_channels           : natural  := 10; -- Arbitrary for now
  constant c_trig_mux_intern_num             : positive := c_trig_mux_num_channels + c_acq_num_channels;
  constant c_trig_mux_rcv_intern_num         : positive := 2; -- 2 FMCs
  constant c_trig_mux_mux_num_cores          : natural  := c_acq_num_cores;
  constant c_trig_mux_out_resolver           : string   := "fanout";
  constant c_trig_mux_in_resolver            : string   := "or";
  constant c_trig_mux_with_input_sync        : boolean  := true;
  constant c_trig_mux_with_output_sync       : boolean  := true;

  -- Trigger RCV intern IDs
  constant c_trig_rcv_intern_chan_1_id       : natural := 0; -- Internal Channel 1
  constant c_trig_rcv_intern_chan_2_id       : natural := 1; -- Internal Channel 2

  -- Trigger core IDs
  constant c_trig_mux_0_id                   : natural := 0;
  constant c_trig_mux_1_id                   : natural := 1;

  signal trig_ref_clk                        : std_logic;
  signal trig_ref_rst_n                      : std_logic;

  signal trig_rcv_intern                     : t_trig_channel_array2d(c_trig_mux_num_cores-1 downto 0, c_trig_mux_rcv_intern_num-1 downto 0);
  signal trig_pulse_transm                   : t_trig_channel_array2d(c_trig_mux_num_cores-1 downto 0, c_trig_mux_intern_num-1 downto 0);
  signal trig_pulse_rcv                      : t_trig_channel_array2d(c_trig_mux_num_cores-1 downto 0, c_trig_mux_intern_num-1 downto 0);

  signal trig_fmc1_channel_1                 : t_trig_channel;
  signal trig_fmc1_channel_2                 : t_trig_channel;
  signal trig_fmc2_channel_1                 : t_trig_channel;
  signal trig_fmc2_channel_2                 : t_trig_channel;

  -----------------------------------------------------------------------------
  -- User Signals
  -----------------------------------------------------------------------------

  constant c_user_num_cores                  : natural := 1;

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

  signal user_wb_out                         : t_wishbone_master_out_array(c_user_num_cores-1 downto 0);
  signal user_wb_in                          : t_wishbone_master_in_array(c_user_num_cores-1 downto 0) := (others => c_DUMMY_WB_MASTER_IN);

begin

  cmp_afc_base_acq : afc_base_acq
    generic map (
      --  If true, instantiate a VIC/UART/SPI.
      g_WITH_VIC                               => true,
      g_WITH_UART_MASTER                       => true,
      g_WITH_TRIGGER                           => true,
      g_WITH_SPI                               => false,
      g_WITH_BOARD_I2C                         => true,
      g_ACQ_NUM_CORES                          => c_acq_num_cores,
      g_TRIG_MUX_NUM_CORES                     => c_trig_mux_num_cores,
      g_USER_NUM_CORES                         => c_user_num_cores,
      -- Acquisition module generics
      g_ACQ_NUM_CHANNELS                       => c_acq_num_channels,
      g_ACQ_MULTISHOT_RAM_SIZE                 => c_acq_multishot_ram_size,
      g_ACQ_FIFO_FC_SIZE                       => c_acq_fifo_size,
      g_FACQ_CHANNELS                          => c_facq_channels,
      -- Trigger Mux generic
      g_TRIG_MUX_SYNC_EDGE                     => c_trig_mux_sync_edge,
      g_TRIG_MUX_INTERN_NUM                    => c_trig_mux_intern_num,
      g_TRIG_MUX_RCV_INTERN_NUM                => c_trig_mux_rcv_intern_num,
      g_TRIG_MUX_OUT_RESOLVER                  => c_trig_mux_out_resolver,
      g_TRIG_MUX_IN_RESOLVER                   => c_trig_mux_in_resolver,
      g_TRIG_MUX_WITH_INPUT_SYNC               => c_trig_mux_with_input_sync,
      g_TRIG_MUX_WITH_OUTPUT_SYNC              => c_trig_mux_with_output_sync,
      -- User generic. Must be g_USER_NUM_CORES length
      g_USER_SDB_RECORD_ARRAY                  => c_DUMMY_SDB_RECORD_ARRAY,
      -- Auxiliary clock used to sync incoming triggers in the trigger module.
      -- If false, trigger will be synch'ed with clk_sys
      g_WITH_AUX_CLK                           => true,
      -- Number of user interrupts
      g_NUM_USER_IRQ                           => c_NUM_USER_IRQ
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

      -- Acquisition
      fs_clk_array_i                           => fs_clk_array,
      fs_ce_array_i                            => fs_ce_array,
      fs_rst_n_array_i                         => fs_rst_n_array,

      acq_chan_array_i                         => acq_chan_array,

      -- Triggers                                 -- Triggers
      trig_rcv_intern_i                        => trig_rcv_intern,
      trig_pulse_transm_i                      => trig_pulse_transm,
      trig_pulse_rcv_o                         => trig_pulse_rcv,

      trig_dbg_o                               => trig_dbg,
      trig_dbg_data_sync_o                     => trig_dbg_data_sync,
      trig_dbg_data_degliteched_o              => trig_dbg_data_degliteched,

      --  The wishbone bus from the pcie/host to the application
      --  LSB addresses are not available (used by the carrier).
      --  For the exact used addresses see SDB Description.
      --  This is a pipelined wishbone with byte granularity.
      user_wb_o                                 => user_wb_out,
      user_wb_i                                 => user_wb_in
    );

  pcb_rev_id <= (others => '0');

  ----------------------------------------------------------------------
  --                          Acquisition                             --
  ----------------------------------------------------------------------

  fs1_clk <= clk_sys;
  fs1_rstn <= clk_sys_rstn;
  fs2_clk <= clk_sys;
  fs2_rstn <= clk_sys_rstn;

  fs_clk_array   <= fs2_clk & fs1_clk;
  fs_ce_array    <= (others => '1');
  fs_rst_n_array <= fs2_rstn & fs1_rstn;

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

  ----------------------------------------------------------------------
  --                          Trigger                                 --
  ----------------------------------------------------------------------

  trig_ref_clk <= clk_trig_ref;
  trig_ref_rst_n <= clk_trig_ref_rstn;

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
