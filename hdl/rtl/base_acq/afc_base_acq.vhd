------------------------------------------------------------------------------
-- Title      : AFC design with Acquisition Core + Trigger Muxes + Generic number of user cores
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2020-01-17
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: AFC design with Acquisition Core + Trigger Muxes + Generic number of user cores
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

entity afc_base_acq is
generic (
  --  If true, instantiate a VIC/UART/DIAG/SPI.
  g_WITH_VIC                                 : boolean := true;
  g_WITH_UART_MASTER                         : boolean := true;
  g_WITH_DIAG                                : boolean := true;
  g_WITH_TRIGGER                             : boolean := true;
  g_WITH_SPI                                 : boolean := true;
  g_WITH_BOARD_I2C                           : boolean := true;
  g_ACQ_NUM_CORES                            : natural := 2;
  g_TRIG_MUX_NUM_CORES                       : natural := 2;
  g_USER_NUM_CORES                           : natural := 1;
  -- Acquisition module generics
  g_ACQ_NUM_CHANNELS                         : natural := c_default_acq_num_channels;
  g_ACQ_MULTISHOT_RAM_SIZE                   : t_property_value_array := c_default_multishot_ram_size;
  g_ACQ_FIFO_FC_SIZE                         : natural := 64;
  g_FACQ_CHANNELS                            : t_facq_chan_param_array := c_default_facq_chan_param_array;
  -- Trigger Mux generic
  g_TRIG_MUX_SYNC_EDGE                       : string  := "positive";
  g_TRIG_MUX_INTERN_NUM                      : natural := 8; -- channels facing inside the FPGA. Limit defined by wb_trigger_regs.vhd
  g_TRIG_MUX_RCV_INTERN_NUM                  : natural := 2; -- signals from inside the FPGA that can be used as input at a rcv mux.
  g_TRIG_MUX_OUT_RESOLVER                    : string  := "fanout"; -- Resolver policy for output triggers
  g_TRIG_MUX_IN_RESOLVER                     : string  := "or";     -- Resolver policy for input triggers
  g_TRIG_MUX_WITH_INPUT_SYNC                 : boolean := true;
  g_TRIG_MUX_WITH_OUTPUT_SYNC                : boolean := true;
  -- User generic. Must be g_USER_NUM_CORES length
  g_USER_SDB_DEVICE_ARRAY                    : t_sdb_device_array := c_DUMMY_SDB_DEVICE_ARRAY;
  -- Auxiliary clock used to sync incoming triggers in the trigger module.
  -- If false, trigger will be synch'ed with clk_sys
  g_WITH_AUX_CLK                             : boolean := true;
  -- Number of user interrupts
  g_NUM_USER_IRQ                             : natural := 1
);
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
  board_i2c_sda_b                            : inout std_logic;

  ---------------------------------------------------------------------------
  -- Flash memory SPI interface
  ---------------------------------------------------------------------------

  spi_sclk_o                                 : out std_logic;
  spi_cs_n_o                                 : out std_logic;
  spi_mosi_o                                 : out std_logic;
  spi_miso_i                                 : in  std_logic := '0';

  ---------------------------------------------------------------------------
  -- Miscellanous AFC pins
  ---------------------------------------------------------------------------

  -- PCB version
  pcb_rev_id_i                               : in std_logic_vector(3 downto 0);

  ---------------------------------------------------------------------------
  --  User part
  ---------------------------------------------------------------------------

  --  Clocks and reset.
  clk_sys_o                                  : out std_logic;
  rst_sys_n_o                                : out std_logic;

  clk_aux_o                                  : out std_logic;
  rst_aux_n_o                                : out std_logic;

  clk_200mhz_o                               : out std_logic;
  rst_200mhz_n_o                             : out std_logic;

  clk_pcie_o                                 : out std_logic;
  rst_pcie_n_o                               : out std_logic;

  clk_trig_ref_o                             : out std_logic;
  rst_trig_ref_n_o                           : out std_logic;

  --  Interrupts
  irq_user_i                                 : in std_logic_vector(g_NUM_USER_IRQ + 5 downto 6) := (others => '0');

  -- Acquisition
  fs_clk_array_i                             : in std_logic_vector(g_ACQ_NUM_CORES-1 downto 0) := (others => '0');
  fs_ce_array_i                              : in std_logic_vector(g_ACQ_NUM_CORES-1 downto 0) := (others => '0');
  fs_rst_n_array_i                           : in std_logic_vector(g_ACQ_NUM_CORES-1 downto 0) := (others => '0');

  acq_chan_array_i                           : in t_facq_chan_array2d(g_ACQ_NUM_CORES-1 downto 0, g_ACQ_NUM_CHANNELS-1 downto 0) := (others => (others => c_default_facq_chan));

  -- Triggers
  trig_rcv_intern_i                          : in  t_trig_channel_array2d(g_TRIG_MUX_NUM_CORES-1 downto 0, g_TRIG_MUX_RCV_INTERN_NUM-1 downto 0) := (others => (others => c_trig_channel_dummy));
  trig_pulse_transm_i                        : in  t_trig_channel_array2d(g_TRIG_MUX_NUM_CORES-1 downto 0, g_TRIG_MUX_INTERN_NUM-1 downto 0) := (others => (others => c_trig_channel_dummy));
  trig_pulse_rcv_o                           : out t_trig_channel_array2d(g_TRIG_MUX_NUM_CORES-1 downto 0, g_TRIG_MUX_INTERN_NUM-1 downto 0);

  trig_dbg_o                                 : out std_logic_vector(c_NUM_TRIG-1 downto 0);
  trig_dbg_data_sync_o                       : out std_logic_vector(c_NUM_TRIG-1 downto 0);
  trig_dbg_data_degliteched_o                : out std_logic_vector(c_NUM_TRIG-1 downto 0);

  --  The wishbone bus from the pcie/host to the application
  --  LSB addresses are not available (used by the carrier).
  --  For the exact used addresses see SDB Description.
  --  This is a pipelined wishbone with byte granularity.
  user_wb_o                                  : out t_wishbone_master_out_array(g_USER_NUM_CORES-1 downto 0);
  user_wb_i                                  : in  t_wishbone_master_in_array(g_USER_NUM_CORES-1 downto 0) := (others => c_DUMMY_WB_MASTER_IN)
);
end entity afc_base_acq;

architecture top of afc_base_acq is

  -----------------------------------------------------------------------------
  -- Crossbar SDB layout.
  -----------------------------------------------------------------------------

  -- Number of slaves
  constant c_slaves                          : natural := g_ACQ_NUM_CORES + 1 +
                                                          g_TRIG_MUX_NUM_CORES + 1 +
                                                          g_USER_NUM_CORES + 1;
  -- Number of masters
  constant c_masters                         : natural := 1;            -- Top master.

  -- Slaves indexes. We use g_ACQ_NUM_CORES and g_TRIG_MUX_NUM_CORES as the top index, as
  -- we later check if this is 0 or 1 to determine if we need to omit acquisition core
  -- or trigger_mux core
  constant c_slv_acq_core_ids                : t_natural_array(g_ACQ_NUM_CORES downto 0) :=
        f_gen_ramp(0,
          g_ACQ_NUM_CORES+1);
  constant c_slv_trig_mux_ids                : t_natural_array(g_TRIG_MUX_NUM_CORES downto 0) :=
        f_gen_ramp(c_slv_acq_core_ids'length,
          c_slv_acq_core_ids'length+g_TRIG_MUX_NUM_CORES+1);
  constant c_slv_user_ids                    : t_natural_array(g_USER_NUM_CORES downto 0) :=
        f_gen_ramp(c_slv_acq_core_ids'length + c_slv_trig_mux_ids'length,
          c_slv_acq_core_ids'length + c_slv_trig_mux_ids'length+g_USER_NUM_CORES+1);

  constant c_slv_user_cores_end              : natural := c_slv_acq_core_ids'length +
                                                            c_slv_trig_mux_ids'length +
                                                            c_slv_user_ids'length;

  constant c_int_sdb_repo_url_id             : natural := 0;
  constant c_int_sdb_top_syn_id              : natural := 1;
  constant c_int_sdb_gen_cores_id            : natural := 2;
  constant c_int_sdb_infra_cores_id          : natural := 3;

  -- These are not account in the number of slaves as these are special
  constant c_slv_sdb_repo_url_id             : natural := c_slv_user_cores_end + c_int_sdb_repo_url_id;
  constant c_slv_sdb_top_syn_id              : natural := c_slv_user_cores_end + c_int_sdb_top_syn_id;
  constant c_slv_sdb_gen_cores_id            : natural := c_slv_user_cores_end + c_int_sdb_gen_cores_id;
  constant c_slv_sdb_infra_cores_id          : natural := c_slv_user_cores_end + c_int_sdb_infra_cores_id;
  constant c_meta_records                    : natural := c_slv_sdb_infra_cores_id-c_slv_sdb_repo_url_id+1;

  constant c_layout_meta_raw : t_sdb_record_array(c_meta_records-1 downto 0) :=
  (
    c_int_sdb_repo_url_id     => f_sdb_embed_repo_url(c_sdb_repo_url),
    c_int_sdb_top_syn_id      => f_sdb_embed_synthesis(c_sdb_top_syn_info),
    c_int_sdb_gen_cores_id    => f_sdb_embed_synthesis(c_sdb_general_cores_syn_info),
    c_int_sdb_infra_cores_id  => f_sdb_embed_synthesis(c_sdb_infra_cores_syn_info)
  );

  -- User SDB
  constant c_layout_user_cores_raw : t_sdb_record_array(g_USER_NUM_CORES downto 0) := f_build_auto_device_array(g_USER_SDB_DEVICE_ARRAY, c_slv_user_ids'length);

  -- Acquisition SDB
  constant c_layout_acq_cores_raw : t_sdb_record_array(g_ACQ_NUM_CORES downto 0) := f_build_auto_device_array(c_xwb_acq_core_sdb, c_slv_acq_core_ids'length);

  -- Trigger Mux SDB
  constant c_layout_trig_mux_cores_raw : t_sdb_record_array(g_TRIG_MUX_NUM_CORES downto 0) := f_build_auto_device_array(c_xwb_trigger_mux_sdb, c_slv_trig_mux_ids'length);

  -- Raw layout
  constant c_layout_raw                      : t_sdb_record_array := c_layout_meta_raw &
                                                                     c_layout_user_cores_raw &
                                                                     c_layout_trig_mux_cores_raw &
                                                                     c_layout_acq_cores_raw;
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

  -- Type of DDR3 core interface
  constant c_ddr_interface_type              : string := "AXIS";

  constant c_acq_addr_width                  : natural := c_ddr_addr_width;
  constant c_acq_ddr_addr_res_width          : natural := 32;
  constant c_acq_ddr_addr_diff               : natural := c_acq_ddr_addr_res_width-c_ddr_addr_width;

  -- Acquisition Wishbone
  signal acq_core_slave_in                   : t_wishbone_slave_in_array (g_ACQ_NUM_CORES-1 downto 0);
  signal acq_core_slave_out                  : t_wishbone_slave_out_array(g_ACQ_NUM_CORES-1 downto 0);

  signal ddr_aximm_clk                       : std_logic;
  signal ddr_aximm_rstn                      : std_logic;
  signal ddr_aximm_r_ma_in                   : t_aximm_r_master_in;
  signal ddr_aximm_r_ma_out                  : t_aximm_r_master_out;
  signal ddr_aximm_w_ma_in                   : t_aximm_w_master_in;
  signal ddr_aximm_w_ma_out                  : t_aximm_w_master_out;

  -----------------------------------------------------------------------------
  -- Trigger signals
  -----------------------------------------------------------------------------

  signal trig_core_slave_in                  : t_wishbone_slave_in_array (g_TRIG_MUX_NUM_CORES-1 downto 0);
  signal trig_core_slave_out                 : t_wishbone_slave_out_array(g_TRIG_MUX_NUM_CORES-1 downto 0);

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

  signal trig_out                            : t_trig_channel_array(c_NUM_TRIG-1 downto 0);
  signal trig_in                             : t_trig_channel_array(c_NUM_TRIG-1 downto 0) := (others => c_trig_channel_dummy);

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
      g_NUM_USER_IRQ                           => g_NUM_USER_IRQ,
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
      pcb_rev_id_i                             => pcb_rev_id_i,

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
      irq_user_i                               => irq_user_i,

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

      trig_dbg_o                               => trig_dbg_o,
      trig_dbg_data_sync_o                     => trig_dbg_data_sync_o,
      trig_dbg_data_degliteched_o              => trig_dbg_data_degliteched_o,

      --  The wishbone bus from the pcie/host to the application
      --  LSB addresses are not available (used by the carrier).
      --  For the exact used addresses see SDB Description.
      --  This is a pipelined wishbone with byte granularity.
      app_wb_o                                 => app_wb_out,
      app_wb_i                                 => app_wb_in
    );

  -- Output clocks/resets
  clk_sys_o        <= clk_sys;
  rst_sys_n_o      <= clk_sys_rstn;

  clk_aux_o        <= clk_aux;
  rst_aux_n_o      <= clk_aux_rstn;

  clk_200mhz_o     <= clk_200mhz;
  rst_200mhz_n_o   <= clk_200mhz_rstn;

  clk_pcie_o       <= clk_pcie;
  rst_pcie_n_o     <= clk_pcie_rstn;

  clk_trig_ref_o   <= clk_trig_ref;
  rst_trig_ref_n_o <= clk_trig_ref_rstn;

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

  cmp_xwb_facq_core_mux : xwb_facq_core_mux
  generic map
  (
    g_interface_mode                         => PIPELINED,
    g_address_granularity                    => BYTE,
    g_acq_addr_width                         => c_acq_addr_width,
    g_acq_num_channels                       => g_ACQ_NUM_CHANNELS,
    g_facq_channels                          => g_FACQ_CHANNELS,
    g_ddr_payload_width                      => c_ddr_payload_width,
    g_ddr_dq_width                           => c_ddr_dq_width,
    g_ddr_addr_width                         => c_ddr_addr_width,
    g_multishot_ram_size                     => g_ACQ_MULTISHOT_RAM_SIZE,
    g_fifo_fc_size                           => g_ACQ_FIFO_FC_SIZE,
    --g_sim_readback                           => false
    g_acq_num_cores                          => g_ACQ_NUM_CORES,
    g_ddr_interface_type                     => c_ddr_interface_type,
    g_max_burst_size                         => c_ddr_datamover_bpm_burst_size
  )
  port map
  (
    fs_clk_array_i                           => fs_clk_array_i,
    fs_ce_array_i                            => fs_ce_array_i,
    fs_rst_n_array_i                         => fs_rst_n_array_i,

    -- Clock signals for Wishbone
    sys_clk_i                                => clk_sys,
    sys_rst_n_i                              => clk_sys_rstn,

    -- From DDR3 Controller
    ext_clk_i                                => ddr_aximm_clk,
    ext_rst_n_i                              => ddr_aximm_rstn,

    -----------------------------
    -- Wishbone Control Interface signals
    -----------------------------
    wb_slv_i                                 => acq_core_slave_in,
    wb_slv_o                                 => acq_core_slave_out,

    -----------------------------
    -- External Interface
    -----------------------------
    acq_chan_array_i                         => acq_chan_array_i,

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

  -- Top most index is always a placeholder
  gen_wishbone_acq_idx : for i in 0 to g_ACQ_NUM_CORES-1 generate

    acq_core_slave_in(i) <= cbar_master_out(c_slv_acq_core_ids(i));
    cbar_master_in(c_slv_acq_core_ids(i)) <= acq_core_slave_out(i);

  end generate;

  -- Placeholder device
  cbar_master_in(c_slv_acq_core_ids(c_slv_acq_core_ids'left)) <= c_DUMMY_WB_MASTER_IN;

  ----------------------------------------------------------------------
  --                          Trigger                                 --
  ----------------------------------------------------------------------

  cmp_xwb_trigger : xwb_trigger
    generic map (
      g_address_granularity                => BYTE,
      g_interface_mode                     => PIPELINED,
      g_with_external_iface                => true,
      g_trig_num                           => c_NUM_TRIG,
      g_intern_num                         => g_TRIG_MUX_INTERN_NUM,
      g_rcv_intern_num                     => g_TRIG_MUX_RCV_INTERN_NUM,
      g_num_mux_interfaces                 => g_TRIG_MUX_NUM_CORES,
      g_out_resolver                       => g_TRIG_MUX_OUT_RESOLVER,
      g_in_resolver                        => g_TRIG_MUX_IN_RESOLVER,
      g_with_input_sync                    => g_TRIG_MUX_WITH_INPUT_SYNC,
      g_with_output_sync                   => g_TRIG_MUX_WITH_OUTPUT_SYNC
    )
    port map (
      clk_i                                => clk_sys,
      rst_n_i                              => clk_sys_rstn,

      ref_clk_i                            => clk_trig_ref,
      ref_rst_n_i                          => clk_trig_ref_rstn,

      fs_clk_array_i                       => fs_clk_array_i,
      fs_rst_n_array_i                     => fs_rst_n_array_i,

      trig_in_i                            => trig_out,
      trig_out_o                           => trig_in,

      wb_slv_trigger_mux_i                 => trig_core_slave_in,
      wb_slv_trigger_mux_o                 => trig_core_slave_out,

      trig_rcv_intern_i                    => trig_rcv_intern_i,
      trig_pulse_transm_i                  => trig_pulse_transm_i,
      trig_pulse_rcv_o                     => trig_pulse_rcv_o
  );

  -- Top most index is always a placeholder
  gen_wishbone_trig_mux_idx : for i in 0 to g_TRIG_MUX_NUM_CORES-1 generate

    trig_core_slave_in(i) <= cbar_master_out(c_slv_trig_mux_ids(i));
    cbar_master_in(c_slv_trig_mux_ids(i)) <= trig_core_slave_out(i);

  end generate;

  -- Placeholder device
  cbar_master_in(c_slv_trig_mux_ids(c_slv_trig_mux_ids'left)) <= c_DUMMY_WB_MASTER_IN;

  ----------------------------------------------------------------------
  --                          User                                    --
  ----------------------------------------------------------------------

  -- Top most index is always a placeholder
  gen_wishbone_user_idx : for i in 0 to g_USER_NUM_CORES-1 generate

    user_wb_o(i) <= cbar_master_out(c_slv_user_ids(i));
    cbar_master_in(c_slv_user_ids(i)) <= user_wb_i(i);

  end generate;

  -- Placeholder device
  cbar_master_in(c_slv_user_ids(c_slv_user_ids'left)) <= c_DUMMY_WB_MASTER_IN;

end architecture top;
