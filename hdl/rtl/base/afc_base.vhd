------------------------------------------------------------------------------
-- Title      : BSP for AFC
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2020-01-07
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: BSP for AFC
-------------------------------------------------------------------------------
-- Copyright (c) 2019 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2020-01-07  1.0      lucas.russo        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- Memory core generator
use work.gencores_pkg.all;
-- Custom Wishbone Modules
use work.ifc_wishbone_pkg.all;
-- Custom common cores
use work.ifc_common_pkg.all;
-- Custom generic cores
use work.ifc_generic_pkg.all;
-- Trigger definitions
use work.trigger_common_pkg.all;
-- Genrams
use work.genram_pkg.all;
-- IP cores constants
use work.ipcores_pkg.all;
-- AXI cores
use work.pcie_cntr_axi_pkg.all;
-- AFC regs package
use work.afc_base_regs_pkg.all;
-- AFC regs package
use work.afc_base_pkg.all;

entity afc_base is
generic (
  -- system PLL parameters
  g_DIVCLK_DIVIDE                          : integer := 5;
  g_CLKBOUT_MULT_F                         : integer := 48;
  g_CLK0_DIVIDE_F                          : integer := 12;
  g_CLK1_DIVIDE                            : integer := 6;
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

  -- LINK01 clock. From clock switch
  afc_link01_clk_p_i                       : in std_logic := '0';
  afc_link01_clk_n_i                       : in std_logic := '1';

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
  -- fmc0_prsnt_m2c_n_i                       : in std_logic := '0';

  ---- I2C interface for accessing FMC EEPROM. Connected to CPU
  --fmc1_scl_b                               : inout std_logic;
  --fmc1_sda_b                               : inout std_logic;

  -- Presence
  -- fmc1_prsnt_m2c_n_i                       : in std_logic := '0';

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

  clk_trig_ref_o                           : out std_logic;
  rst_trig_ref_n_o                         : out std_logic;

  clk_link01_p_o                           : out std_logic;
  clk_link01_n_o                           : out std_logic;

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
end entity afc_base;

architecture top of afc_base is

  -----------------------------------------------------------------------------
  -- Top crossbar layout
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- Master Top SDB layout. For future MSI support
  -----------------------------------------------------------------------------

  -- Number of masters
  constant c_top_masters                     : natural := 2;
  -- Master indexes
  constant c_top_ma_pcie_id                  : natural := 0;
  constant c_top_ma_rs232_syscon_id          : natural := 1;

  -- Master layout
  constant c_top_ma_layout_raw : t_sdb_record_array(c_top_masters-1 downto 0) :=
   (
     c_top_ma_pcie_id               => f_sdb_auto_msi(c_null_msi,    false),   -- no MSIs for PCIe
     c_top_ma_rs232_syscon_id       => f_sdb_auto_msi(c_null_msi,    false)    -- no MSIs for UART
   );

  constant c_top_ma_layout                   : t_sdb_record_array := f_sdb_auto_layout(c_top_ma_layout_raw);
  constant c_top_bridge_msi                  : t_sdb_msi          := f_xwb_msi_layout_sdb(c_top_ma_layout);

  -- Crossbar master/slave arrays
  signal cbar_top_bus_slave_in                : t_wishbone_slave_in_array  (c_top_masters-1 downto 0);
  signal cbar_top_bus_slave_out               : t_wishbone_slave_out_array (c_top_masters-1 downto 0);
  signal cbar_top_msi_master_in               : t_wishbone_master_in_array (c_top_masters-1 downto 0);
  signal cbar_top_msi_master_out              : t_wishbone_master_out_array(c_top_masters-1 downto 0);

  -----------------------------------------------------------------------------
  -- Master Device SDB layout. For future MSI support
  -----------------------------------------------------------------------------

  constant c_dev_masters                     : natural := 1;
  constant c_dev_top_id                      : natural := 0;

  constant c_dev_ma_layout_raw : t_sdb_record_array(c_dev_masters-1 downto 0) :=
    (
      c_dev_top_id                => f_sdb_auto_msi(c_top_bridge_msi, true)
    );

  constant c_dev_ma_layout                   : t_sdb_record_array := f_sdb_auto_layout(c_dev_ma_layout_raw);
  constant c_dev_bridge_msi                  : t_sdb_msi := f_xwb_msi_layout_sdb(c_dev_ma_layout);

  signal cbar_dev_bus_slave_in               : t_wishbone_slave_in_array  (c_dev_masters-1 downto 0);
  signal cbar_dev_bus_slave_out              : t_wishbone_slave_out_array (c_dev_masters-1 downto 0);
  signal cbar_dev_msi_master_in              : t_wishbone_master_in_array (c_dev_masters-1 downto 0);
  signal cbar_dev_msi_master_out             : t_wishbone_master_out_array(c_dev_masters-1 downto 0);

  -----------------------------------------------------------------------------
  -- Slave Device SDB layout.
  -----------------------------------------------------------------------------

  -- Number of slaves
  constant c_dev_slaves                      : natural := 7;

  -- Slaves indexes
  constant c_dev_slv_afc_base_id             : natural := 0;
  constant c_dev_slv_periph_id               : natural := 1;
  constant c_dev_slv_board_i2c_id            : natural := 2;
  constant c_dev_slv_vic_id                  : natural := 3;
  constant c_dev_slv_spi_id                  : natural := 4;
  constant c_dev_slv_afc_diag_id             : natural := 5;
  constant c_dev_slv_trig_iface_id           : natural := 6;

  -- General peripherals layout. UART, LEDs (GPIO), Buttons (GPIO) and Tics counter
  constant c_periph_bridge_sdb : t_sdb_bridge := f_xwb_bridge_manual_sdb(x"00000FFF", x"00000400");

  -- WB SDB (Self describing bus) layout
  constant c_dev_slv_layout_raw : t_sdb_record_array(c_dev_slaves-1 downto 0) :=
    (
     c_dev_slv_afc_base_id         => f_sdb_auto_device(c_xwb_afc_base_regs_sdb,    true),               -- AFC base registers control port
     c_dev_slv_periph_id           => f_sdb_auto_bridge(c_periph_bridge_sdb,        true),               -- General peripherals control port
     c_dev_slv_board_i2c_id        => f_sdb_auto_device(c_xwb_i2c_master_sdb,       g_WITH_BOARD_I2C),   -- Board I2C
     c_dev_slv_vic_id              => f_sdb_auto_device(c_xwb_vic_sdb,              g_WITH_VIC),         -- VIC
     c_dev_slv_spi_id              => f_sdb_auto_device(c_xwb_spi_sdb,              g_WITH_SPI),         -- Flash SPI
     c_dev_slv_afc_diag_id         => f_sdb_auto_device(c_xwb_afc_diag_sdb,         g_WITH_DIAG),        -- AFC Diagnostics
     c_dev_slv_trig_iface_id       => f_sdb_auto_device(c_xwb_trigger_iface_sdb,    g_WITH_TRIGGER)      -- Trigger Interface
    );

  -- Self Describing Bus ROM Address. It will be an addressed slave as well
  constant c_dev_layout                     : t_sdb_record_array := f_sdb_auto_layout(c_dev_ma_layout_raw, c_dev_slv_layout_raw);
  constant c_dev_sdb_address                : t_wishbone_address := f_sdb_auto_sdb   (c_dev_ma_layout_raw, c_dev_slv_layout_raw);
  constant c_dev_bridge_sdb                 : t_sdb_bridge       := f_xwb_bridge_layout_sdb(true, c_dev_layout, c_dev_sdb_address);
  constant c_dev_bridge_size                : unsigned(c_wishbone_address_width-1 downto 0) :=
    f_sdb_bus_end(true, c_dev_layout, c_dev_sdb_address, false)(c_wishbone_address_width-1 downto 0);

  -- Crossbar master/slave arrays
  signal cbar_dev_msi_slave_in               : t_wishbone_slave_in_array  (c_dev_slaves-1 downto 0) := (others => c_DUMMY_WB_SLAVE_IN);
  signal cbar_dev_msi_slave_out              : t_wishbone_slave_out_array (c_dev_slaves-1 downto 0);
  signal cbar_dev_bus_master_in              : t_wishbone_master_in_array (c_dev_slaves-1 downto 0);
  signal cbar_dev_bus_master_out             : t_wishbone_master_out_array(c_dev_slaves-1 downto 0);

  -----------------------------------------------------------------------------
  -- Slave Top SDB layout.
  -----------------------------------------------------------------------------

  -- Copied from upstream wishbone_pkg.vhd. Used until we merge it into our
  -- general-cores.
  function f_afc_sdb_embed_device(device : t_sdb_device; address : t_wishbone_address; enable : boolean := true)
    return t_sdb_record
  is
    variable v_empty : t_sdb_record := (others => '0');
  begin
    v_empty(7 downto 0) := x"f1";
    if enable then
      return f_sdb_embed_device(device, address);
    else
      return v_empty;
    end if;
  end f_afc_sdb_embed_device;

  function f_afc_sdb_embed_bridge(bridge : t_sdb_bridge; address : t_wishbone_address; enable : boolean := true)
    return t_sdb_record
  is
    constant c_zero  : t_wishbone_address := (others => '0');
    variable v_empty : t_sdb_record := (others => '0');
  begin
    v_empty(7 downto 0) := x"f2";
    if enable then
      return f_sdb_embed_bridge(bridge, address);
    else
      return v_empty;
    end if;
  end f_afc_sdb_embed_bridge;

  -- Number of slaves
  constant c_top_slaves                      : natural := 2;

  -- Slaves indexes
  constant c_top_dev_id                      : natural := 0; -- Top crossbar
  constant c_top_app_id                      : natural := 1; -- Application bus

  -- This could be extracted from the total SDB ROM SIZE
  constant c_top_bridge_offset               : t_wishbone_address := x"01000000";
  constant c_wishbone_addr_max_size          : t_wishbone_address := (others => '1');
  -- Application bridge occupies everything after the BSP. Fix a large space for the
  -- application. FIXME in infra-cores. We can't use the 3 MSB bits as AFC PCIe
  -- is 64-bit addressed, but it uses the 29 available address bits as 8-bit addressed,
  -- thus loosing the capability of addressing the 3 MSBs.
  constant c_app_bridge_size                 : t_wishbone_address := x"07FFFFFF";

  constant c_app_bridge_sdb                  : t_sdb_bridge := f_xwb_bridge_manual_sdb(c_app_bridge_size, g_APP_SDB_BRIDGE_ADDR);

  constant c_top_app_bridge_offset_raw       : t_wishbone_address :=
    std_logic_vector(unsigned(c_top_bridge_offset) + unsigned(c_dev_bridge_size) + 1);
  constant c_top_app_bridge_offset           : t_wishbone_address :=
    std_logic_vector(f_align_addr_offset(unsigned(c_top_app_bridge_offset_raw),
    unsigned(c_app_bridge_size),
    unsigned(c_top_bridge_offset) - 1)(c_wishbone_address_width-1 downto 0));

  -- WB SDB (Self describing bus) layout
  constant c_top_slv_layout_raw : t_sdb_record_array(c_top_slaves-1 downto 0) :=
    (
    -- We want this to be fixed at c_top_bridge_offset. So SDB ROM can be at address 0x0
     c_top_dev_id                  => f_sdb_embed_bridge(c_dev_bridge_sdb,          c_top_bridge_offset),
     c_top_app_id                  => f_afc_sdb_embed_bridge(c_app_bridge_sdb,      c_top_app_bridge_offset, g_WITH_APP_SDB_BRIDGE) -- Application bridge
    );

  -- Self Describing Bus ROM Address. It will be an addressed slave as well
  constant c_top_layout                      : t_sdb_record_array := c_top_ma_layout & c_top_slv_layout_raw;
  constant c_top_sdb_address                 : t_wishbone_address := x"00000000";
  constant c_top_bridge_sdb                  : t_sdb_bridge       := f_xwb_bridge_layout_sdb(true, c_top_layout, c_top_sdb_address);

  -- Crossbar master/slave arrays
  signal cbar_top_msi_slave_in               : t_wishbone_slave_in_array  (c_top_slaves-1 downto 0) := (others => c_DUMMY_WB_SLAVE_IN);
  signal cbar_top_msi_slave_out              : t_wishbone_slave_out_array (c_top_slaves-1 downto 0);
  signal cbar_top_bus_master_in              : t_wishbone_master_in_array (c_top_slaves-1 downto 0);
  signal cbar_top_bus_master_out             : t_wishbone_master_out_array(c_top_slaves-1 downto 0);

  -----------------------------------------------------------------------------
  -- BSP signals and constants
  -----------------------------------------------------------------------------

  -- GPIO num pinscalc
  constant c_leds_num_pins                   : natural := 3;
  constant c_with_leds_heartbeat             : t_boolean_array(c_leds_num_pins-1 downto 0) :=
                                                 (2 => false,  -- Red LED
                                                  1 => true,   -- Green LED
                                                  0 => false); -- Blue LED
  constant c_buttons_num_pins                : natural := 8;

  -- Number of reset clock cycles (FF)
  constant c_button_rst_width                : natural := 255;

  -- Number of top level clocks
  constant c_num_tlvl_clks                   : natural := 3; -- CLK_SYS and CLK_200 MHz and PCIE
  constant c_clk_sys_id                      : natural := 0;
  constant c_clk_200mhz_id                   : natural := 1;
  constant c_clk_pcie_id                     : natural := 2;

  -- Number of auxiliary clocks
  constant c_num_aux_clks                    : natural := 2; -- CLK_AUX, CLK_TCLKA (AUX_RAW)
  constant c_clk_aux_id                      : natural := 0;
  constant c_clk_aux_raw_id                  : natural := 1;

  -- Trigger constants
  constant c_TRIG_SYNC_EDGE                  : string := "positive";

  -- Metadata
  signal metadata_addr                       : std_logic_vector(5 downto 2);
  signal metadata_data                       : std_logic_vector(31 downto 0);

  -- PCIe signals
  signal wb_ma_pcie_rst                      : std_logic;
  signal wb_ma_pcie_rstn                     : std_logic;
  signal wb_ma_pcie_rstn_sync                : std_logic;

  -- DBE Peripheral signal
  signal gpio_leds_out_int                   : std_logic_vector(c_leds_num_pins-1 downto 0);
  signal gpio_leds_in_int                    : std_logic_vector(c_leds_num_pins-1 downto 0) := (others => '0');

  -- Clocks and resets signals
  signal locked                              : std_logic;
  signal uart_rstn                           : std_logic := '1';
  signal clk_sys_pcie_rstn                   : std_logic;
  signal clk_sys_pcie_rst                    : std_logic;
  signal clk_pcie_rstn                       : std_logic;
  signal clk_pcie_rst                        : std_logic;
  signal clk_sys_rstn                        : std_logic;
  signal clk_sys_rst                         : std_logic;
  signal clk_200mhz_rst                      : std_logic;
  signal clk_200mhz_rstn                     : std_logic;
  signal rst_button_sys_pp                   : std_logic;
  signal rst_button_sys                      : std_logic;
  signal rst_button_sys_n                    : std_logic;

  signal clk_aux                             : std_logic;
  signal clk_aux_raw                         : std_logic;
  signal clk_aux_locked                      : std_logic;
  signal clk_aux_rstn                        : std_logic;
  signal clk_aux_rst                         : std_logic;
  signal clk_aux_raw_rstn                    : std_logic;
  signal clk_aux_raw_rst                     : std_logic;

  signal clk_sys                             : std_logic;
  signal clk_200mhz                          : std_logic;
  signal clk_pcie                            : std_logic;

  -- "c_num_tlvl_clks" clocks
  signal reset_clks                          : std_logic_vector(c_num_tlvl_clks-1 downto 0);
  signal reset_rstn                          : std_logic_vector(c_num_tlvl_clks-1 downto 0);

  -- "c_num_aux_clks" clocks
  signal reset_aux_clks                      : std_logic_vector(c_num_aux_clks-1 downto 0);
  signal reset_aux_rstn                      : std_logic_vector(c_num_aux_clks-1 downto 0);

   -- Global Clock Single ended
  signal sys_clk_gen                         : std_logic;
  signal sys_clk_gen_bufg                    : std_logic;

  signal aux_clk_gen                         : std_logic;
  signal aux_clk_gen_bufg                    : std_logic;

  signal buttons_dummy                       : std_logic_vector(7 downto 0) := (others => '0');
  signal ddr_rdy                             : std_logic := '1';

  -- Connected to MMC
  signal fmc0_prsnt_m2c_n                    : std_logic := '0';
  signal fmc1_prsnt_m2c_n                    : std_logic := '0';

  signal board_i2c_scl_out                   : std_logic;
  signal board_i2c_sda_out                   : std_logic;
  signal board_i2c_scl_oen                   : std_logic;
  signal board_i2c_sda_oen                   : std_logic;

  signal fmc_presence                        : std_logic_vector(31 downto 0);

  signal irq_master                          : std_logic;

  constant num_interrupts                    : natural := 6 + g_NUM_USER_IRQ;
  signal irqs                                : std_logic_vector(num_interrupts - 1 downto 0);

  -- Trigger
  signal trig_ref_clk                        : std_logic;
  signal trig_ref_rstn                       : std_logic;

  -- AFC Si57x signals
  signal afc_si57x_scl_pad_oen               : std_logic;
  signal afc_si57x_sda_pad_oen               : std_logic;

  ---------------------------
  --      Components       --
  ---------------------------

  -- Clock generation
  component clk_gen is
  port(
    sys_clk_p_i                             : in std_logic;
    sys_clk_n_i                             : in std_logic;
    sys_clk_o                               : out std_logic;
    sys_clk_bufg_o                          : out std_logic
  );
  end component;

  component clk_gen_mgt is
  port(
    sys_clk_p_i                             : in std_logic;
    sys_clk_n_i                             : in std_logic;
    sys_clk_o                               : out std_logic;
    sys_clk_bufg_o                          : out std_logic
  );
  end component;

  -- Xilinx PLL
  component sys_pll is
  generic(
    -- 200 MHz input clock
    g_clkin_period                          : real := 5.000;
    g_divclk_divide                         : integer := 1;
    g_clkbout_mult_f                        : integer := 5;

    -- 100 MHz output clock
    g_clk0_divide_f                         : integer := 10;
    -- 200 MHz output clock
    g_clk1_divide                           : integer := 5;
    -- 200 MHz output clock
    g_clk2_divide                           : integer := 5
  );
  port(
    rst_i                                   : in std_logic := '0';
    clk_i                                   : in std_logic := '0';
    clk0_o                                  : out std_logic;
    clk1_o                                  : out std_logic;
    clk2_o                                  : out std_logic;
    locked_o                                : out std_logic
  );
  end component;

begin

  -----------------------------------------------------------------------------
  -- Main clock generation
  -----------------------------------------------------------------------------

  cmp_clk_gen : clk_gen
  port map (
    sys_clk_p_i                              => sys_clk_p_i,
    sys_clk_n_i                              => sys_clk_n_i,
    sys_clk_o                                => sys_clk_gen,
    sys_clk_bufg_o                           => sys_clk_gen_bufg
  );

   -- Obtain core locking and generate necessary clocks
  cmp_sys_pll_inst : sys_pll
  generic map (
    -- 125 MHz input clock
    g_clkin_period                           => 8.000,
    g_divclk_divide                          => g_DIVCLK_DIVIDE,
    g_clkbout_mult_f                         => g_CLKBOUT_MULT_F,

    -- 100 MHz output clock
    g_clk0_divide_f                          => g_CLK0_DIVIDE_F,
    -- 200 MHz output clock
    g_clk1_divide                            => g_CLK1_DIVIDE
  )
  port map (
    rst_i                                    => '0',
    clk_i                                    => sys_clk_gen_bufg,
    --clk_i                                    => sys_clk_gen,
    clk0_o                                   => clk_sys,      -- 100MHz locked clock
    clk1_o                                   => clk_200mhz,   -- 200MHz locked clock
    locked_o                                 => locked        -- '1' when the PLL has locked
  );

  -- Reset synchronization. Hold reset line until few locked cycles have passed.
  cmp_reset : gc_reset
  generic map(
    g_clocks                                 => c_num_tlvl_clks    -- CLK_SYS & CLK_200
  )
  port map(
    --free_clk_i                               => sys_clk_gen,
    free_clk_i                               => sys_clk_gen_bufg,
    locked_i                                 => locked,
    clks_i                                   => reset_clks,
    rstn_o                                   => reset_rstn
  );

  reset_clks(c_clk_sys_id)                   <= clk_sys;
  reset_clks(c_clk_200mhz_id)                <= clk_200mhz;
  reset_clks(c_clk_pcie_id)                  <= clk_pcie;

  -- Reset for PCIe core. Caution when resetting the PCIe core after the
  -- initialization. The PCIe core needs to retrain the link and the PCIe
  -- host (linux OS, likely) will not be able to do that automatically,
  -- probably.
  clk_sys_pcie_rstn                          <= reset_rstn(c_clk_sys_id) and rst_button_sys_n;
  clk_sys_pcie_rst                           <= not clk_sys_pcie_rstn;
  -- Reset for all other modules
  clk_sys_rstn                               <= reset_rstn(c_clk_sys_id) and rst_button_sys_n and
                                                   uart_rstn and wb_ma_pcie_rstn_sync;
  clk_sys_rst                                <= not clk_sys_rstn;
  -- Reset synchronous to clk200mhz
  clk_200mhz_rstn                            <= reset_rstn(c_clk_200mhz_id);
  clk_200mhz_rst                             <=  not(reset_rstn(c_clk_200mhz_id));
  -- Reset synchronous to clk_pcie
  clk_pcie_rstn                              <= reset_rstn(c_clk_pcie_id);
  clk_pcie_rst                               <=  not(reset_rstn(c_clk_pcie_id));

  -- Output assignments
  clk_sys_o                                  <= clk_sys;
  rst_sys_n_o                                <= clk_sys_rstn;

  clk_200mhz_o                               <= clk_200mhz;
  rst_200mhz_n_o                             <= clk_200mhz_rstn;

  clk_pcie_o                                 <= clk_pcie;
  rst_pcie_n_o                               <= clk_pcie_rstn;

  -- Generate button reset synchronous to each clock domain
  -- Detect button positive edge of clk_sys
  cmp_button_sys_ffs : gc_sync_ffs
  port map (
    clk_i                                    => clk_sys,
    rst_n_i                                  => '1',
    data_i                                   => sys_rst_button_n_i,
    npulse_o                                 => rst_button_sys_pp
  );

  -- Generate the reset signal based on positive edge
  -- of synched gc
  cmp_button_sys_rst : gc_extend_pulse
  generic map (
    g_width                                  => c_button_rst_width
  )
  port map(
    clk_i                                    => clk_sys,
    rst_n_i                                  => '1',
    pulse_i                                  => rst_button_sys_pp,
    extended_o                               => rst_button_sys
  );

  rst_button_sys_n                           <= not rst_button_sys;

  -----------------------------------------------------------------------------
  -- Auxiliary clock generation
  -----------------------------------------------------------------------------

  gen_with_aux_clk : if g_WITH_AUX_CLK generate

    cmp_aux_clk_gen : clk_gen_mgt
    port map (
      sys_clk_p_i                              => aux_clk_p_i,
      sys_clk_n_i                              => aux_clk_n_i,
      sys_clk_o                                => aux_clk_gen,
      sys_clk_bufg_o                           => aux_clk_gen_bufg
    );

     -- Auxiliary clock
    cmp_aux_sys_pll_inst : sys_pll
    generic map (
      -- RF*5/36 ~ 69.44 MHz input clock ~ 14.4 ns
      g_clkin_period                           => 14.400,
      g_divclk_divide                          => 1,
      g_clkbout_mult_f                         => 18,

      -- 125 MHz output clock
      g_clk0_divide_f                          => 10,
      -- 125 MHz output clock
      g_clk1_divide                            => 18
    )
    port map (
      rst_i                                    => '0',
      clk_i                                    => aux_clk_gen_bufg,
      --clk_i                                    => aux_clk_gen,
      clk0_o                                   => clk_aux,              -- 125MHz locked clock
      clk1_o                                   => clk_aux_raw,          -- ~64.44 MHz
      clk2_o                                   => open,
      locked_o                                 => clk_aux_locked        -- '1' when the PLL has locked
    );

    -- Reset synchronization. Hold reset line until few locked cycles have passed.
    cmp_aux_reset : gc_reset
    generic map(
      g_clocks                                 => c_num_aux_clks        -- CLK_AUX, CLK_AUX_RAW
    )
    port map(
      --free_clk_i                               => aux_clk_gen,
      free_clk_i                               => aux_clk_gen_bufg,
      locked_i                                 => clk_aux_locked,
      clks_i                                   => reset_aux_clks,
      rstn_o                                   => reset_aux_rstn
    );

    reset_aux_clks(c_clk_aux_id)               <= clk_aux;
    reset_aux_clks(c_clk_aux_raw_id)           <= clk_aux_raw;

  end generate;

  gen_without_aux_clk : if not g_WITH_AUX_CLK generate

    clk_aux                                    <= '0';
    clk_aux_raw                                <= '0';
    clk_aux_locked                             <= '0';

    reset_aux_rstn                             <= (others => '1');

  end generate;

  -- Auxiliary reset
  clk_aux_rstn                               <= reset_aux_rstn(c_clk_aux_id);
  clk_aux_rst                                <= not(reset_aux_rstn(c_clk_aux_id));

  clk_aux_raw_rstn                           <= reset_aux_rstn(c_clk_aux_raw_id);
  clk_aux_raw_rst                            <= not(reset_aux_rstn(c_clk_aux_raw_id));

  -- Output assignments
  clk_aux_o                                  <= clk_aux;
  rst_aux_n_o                                <= clk_aux_rstn;

  clk_aux_raw_o                              <= clk_aux_raw;
  rst_aux_raw_n_o                            <= clk_aux_raw_rstn;

  -----------------------------------------------------------------------------
  -- LINK01 clock
  -----------------------------------------------------------------------------

  clk_link01_p_o                             <= afc_link01_clk_p_i;
  clk_link01_n_o                             <= afc_link01_clk_n_i;

  -----------------------------------------------------------------------------
  -- PCIe Core
  -----------------------------------------------------------------------------

  cbar_top_msi_master_in(c_top_ma_pcie_id)           <= cc_DUMMY_MASTER_IN; -- PCIe does not accept MSI

  cmp_xwb_pcie_cntr : xwb_pcie_cntr
  generic map (
    g_ma_interface_mode                      => PIPELINED,
    g_ma_address_granularity                 => BYTE,
    g_simulation                             => "FALSE"
  )
  port map (
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

    -- Necessity signals
    ddr_clk_i                                => clk_200mhz,        --200 MHz DDR core clock (connect through BUFG or PLL)
    ddr_rst_i                                => clk_200mhz_rst,
    pcie_clk_p_i                             => pcie_clk_p_i,      --100 MHz PCIe Clock (connect directly to input pin)
    pcie_clk_n_i                             => pcie_clk_n_i,      --100 MHz PCIe Clock
    pcie_rst_n_i                             => clk_sys_pcie_rstn, -- PCIe core reset

    -- DDR memory controller interface --
    ddr_aximm_sl_aclk_o                      => ddr_aximm_sl_aclk_o,
    ddr_aximm_sl_aresetn_o                   => ddr_aximm_sl_aresetn_o,
    ddr_aximm_r_sl_i                         => ddr_aximm_r_sl_i,
    ddr_aximm_r_sl_o                         => ddr_aximm_r_sl_o,
    ddr_aximm_w_sl_i                         => ddr_aximm_w_sl_i,
    ddr_aximm_w_sl_o                         => ddr_aximm_w_sl_o,

    -- Wishbone interface --
    wb_clk_i                                 => clk_sys,
    -- Reset wishbone interface with the same reset as the other
    -- modules, including a reset coming from the PCIe itself.
    wb_rst_i                                 => clk_sys_rst,
    wb_ma_i                                  => cbar_top_bus_slave_out(c_top_ma_pcie_id),
    wb_ma_o                                  => cbar_top_bus_slave_in(c_top_ma_pcie_id),
    -- Additional exported signals for instantiation
    wb_ma_pcie_rst_o                         => wb_ma_pcie_rst,
    pcie_clk_o                               => clk_pcie,
    ddr_rdy_o                                => ddr_rdy
  );

  wb_ma_pcie_rstn                            <= not wb_ma_pcie_rst;

  cmp_pcie_reset_synch : reset_synch
  port map
  (
    clk_i                                    => clk_sys,
    arst_n_i                                 => wb_ma_pcie_rstn,
    rst_n_o                                  => wb_ma_pcie_rstn_sync
  );

  -----------------------------------------------------------------------------
  -- RS232 Core
  -----------------------------------------------------------------------------
  cbar_top_msi_master_in(c_top_ma_rs232_syscon_id)   <= cc_DUMMY_MASTER_IN; -- UART does not accept MSI

  gen_with_uart_master : if g_WITH_UART_MASTER generate

    cmp_xwb_rs232_syscon : xwb_rs232_syscon
    generic map (
      g_ma_interface_mode                    => PIPELINED,
      g_ma_address_granularity               => BYTE
    )
    port map(
      -- WISHBONE common
      wb_clk_i                               => clk_sys,
      wb_rstn_i                              => clk_sys_rstn,

      -- External ports
      rs232_rxd_i                            => uart_rxd_i,
      rs232_txd_o                            => uart_txd_o,

      -- Reset to FPGA logic
      rstn_o                                 => uart_rstn,

      -- WISHBONE master
      wb_master_i                            => cbar_top_bus_slave_out(c_top_ma_rs232_syscon_id),
      wb_master_o                            => cbar_top_bus_slave_in(c_top_ma_rs232_syscon_id)
    );

  end generate;

  gen_without_uart_master : if not g_WITH_UART_MASTER generate

    uart_txd_o <= '0';
    uart_rstn <= '1';
    cbar_top_bus_slave_in(c_top_ma_rs232_syscon_id) <= c_DUMMY_WB_SLAVE_IN;

  end generate;

  -----------------------------------------------------------------------------
  -- Top-Level Crossbar
  -----------------------------------------------------------------------------

  cmp_interconnect_top : xwb_sdb_crossbar
  generic map(
    g_num_masters                            => c_top_masters,
    g_num_slaves                             => c_top_slaves,
    g_registered                             => true,
    g_wraparound                             => true, -- Should be true for nested buses
    g_layout                                 => c_top_layout,
    g_sdb_addr                               => c_top_sdb_address
  )
  port map(
    clk_sys_i                                => clk_sys,
    rst_n_i                                  => clk_sys_rstn,
    -- Master connections (INTERCON is a slave)
    slave_i                                  => cbar_top_bus_slave_in,
    slave_o                                  => cbar_top_bus_slave_out,
    msi_slave_i                              => cbar_top_msi_slave_in,
    msi_slave_o                              => cbar_top_msi_slave_out,
    -- Slave connections (INTERCON is a master)
    master_i                                 => cbar_top_bus_master_in,
    master_o                                 => cbar_top_bus_master_out,
    msi_master_i                             => cbar_top_msi_master_in,
    msi_master_o                             => cbar_top_msi_master_out
  );

  -- Application WB connections
  app_wb_o <= cbar_top_bus_master_out(c_top_app_id);
  cbar_top_bus_master_in(c_top_app_id) <= app_wb_i;

  -----------------------------------------------------------------------------
  -- Device-Level Crossbar
  -----------------------------------------------------------------------------

  cmp_interconnect_dev : xwb_sdb_crossbar
  generic map(
    g_num_masters                            => c_dev_masters,
    g_num_slaves                             => c_dev_slaves,
    g_registered                             => true,
    g_wraparound                             => true, -- Should be true for nested buses
    g_layout                                 => c_dev_layout,
    g_sdb_addr                               => c_dev_sdb_address
  )
  port map(
    clk_sys_i                                => clk_sys,
    rst_n_i                                  => clk_sys_rstn,
    -- Master connections (INTERCON is a slave)
    slave_i                                  => cbar_dev_bus_slave_in,
    slave_o                                  => cbar_dev_bus_slave_out,
    msi_slave_i                              => cbar_dev_msi_slave_in,
    msi_slave_o                              => cbar_dev_msi_slave_out,
    -- Slave connections (INTERCON is a master)
    master_i                                 => cbar_dev_bus_master_in,
    master_o                                 => cbar_dev_bus_master_out,
    msi_master_i                             => cbar_dev_msi_master_in,
    msi_master_o                             => cbar_dev_msi_master_out
  );

  -----------------------------------------------------------------------------
  -- Regster stage for crossbars TOP to/from DEV
  -----------------------------------------------------------------------------

  cmp_top2dev_bus : xwb_register_link
  port map(
    clk_sys_i                                => clk_sys,
    rst_n_i                                  => clk_sys_rstn,
    slave_i                                  => cbar_top_bus_master_out(c_top_dev_id),
    slave_o                                  => cbar_top_bus_master_in(c_top_dev_id),
    master_i                                 => cbar_dev_bus_slave_out(c_dev_top_id),
    master_o                                 => cbar_dev_bus_slave_in(c_dev_top_id)
  );

  cmp_dev2top_msi : xwb_register_link
  port map(
    clk_sys_i                                => clk_sys,
    rst_n_i                                  => clk_sys_rstn,
    slave_i                                  => cbar_dev_msi_master_out(c_dev_top_id),
    slave_o                                  => cbar_dev_msi_master_in(c_dev_top_id),
    master_i                                 => cbar_top_msi_slave_out(c_top_dev_id),
    master_o                                 => cbar_top_msi_slave_in(c_top_dev_id)
  );

  -----------------------------------------------------------------------------
  -- Peripherals
  -----------------------------------------------------------------------------

  cmp_afc_base_regs: afc_base_regs
  port map (
    rst_n_i                                  => clk_sys_rstn,
    clk_i                                    => clk_sys,
    wb_cyc_i                                 => cbar_dev_bus_master_out(c_dev_slv_afc_base_id).cyc,
    wb_stb_i                                 => cbar_dev_bus_master_out(c_dev_slv_afc_base_id).stb,
    wb_adr_i                                 => cbar_dev_bus_master_out(c_dev_slv_afc_base_id).adr(6 downto 2),  -- Byte address from PCIe
    wb_sel_i                                 => cbar_dev_bus_master_out(c_dev_slv_afc_base_id).sel,
    wb_we_i                                  => cbar_dev_bus_master_out(c_dev_slv_afc_base_id).we,
    wb_dat_i                                 => cbar_dev_bus_master_out(c_dev_slv_afc_base_id).dat,
    wb_ack_o                                 => cbar_dev_bus_master_in(c_dev_slv_afc_base_id).ack,
    wb_err_o                                 => cbar_dev_bus_master_in(c_dev_slv_afc_base_id).err,
    wb_rty_o                                 => cbar_dev_bus_master_in(c_dev_slv_afc_base_id).rty,
    wb_stall_o                               => cbar_dev_bus_master_in(c_dev_slv_afc_base_id).stall,
    wb_dat_o                                 => cbar_dev_bus_master_in(c_dev_slv_afc_base_id).dat,

    -- a ROM containing the carrier metadata
    metadata_addr_o                          => metadata_addr,
    metadata_data_i                          => metadata_data,
    metadata_data_o                          => open,

    -- presence lines for the fmcs
    csr_fmc_presence_i                       => fmc_presence,

    csr_ddr_status_calib_done_i              => ddr_rdy,
    csr_pcb_rev_id_i                         => pcb_rev_id_i
  );

  fmc_presence (0) <= not fmc0_prsnt_m2c_n;
  fmc_presence (1) <= not fmc1_prsnt_m2c_n;
  fmc_presence (31 downto 2) <= (others => '0');

  --  Metadata
  p_metadata: process (clk_sys) is
  begin
    if rising_edge(clk_sys) then
      case metadata_addr is
        when x"0" =>
          -- Vendor ID
          -- echo CREOTECH | md5sum | cut -b -8
          metadata_data <= x"11173e00";
        when x"1" =>
          -- Device ID
          -- echo AFC | md5sum | cut -b -8
          metadata_data <= x"299311ac";
        when x"2" =>
          -- Version
          -- 3.1
          metadata_data <= x"00000310";
        when x"3" =>
          -- BOM
          metadata_data <= x"deadbeef";
        when x"4" | x"5" | x"6" | x"7" =>
          -- source id
          metadata_data <= x"00000000";
        when x"8" =>
          -- capability mask
          metadata_data <= x"00000000";

          if g_WITH_UART_MASTER then
            metadata_data(0) <= '1';
          end if;

          if g_WITH_DIAG then
            metadata_data(1) <= '1';
          end if;

          if g_WITH_TRIGGER then
            metadata_data(2) <= '1';
          end if;

          if g_WITH_SPI then
            metadata_data(3) <= '1';
          end if;

          if g_WITH_BOARD_I2C then
            metadata_data(4) <= '1';
          end if;

        when others =>
          metadata_data <= x"00000000";
      end case;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Peripherals Core
  -----------------------------------------------------------------------------

  cmp_xwb_dbe_periph : xwb_dbe_periph
  generic map(
    g_interface_mode                         => PIPELINED,
    g_address_granularity                    => BYTE,
    g_num_leds                               => c_leds_num_pins,
    g_with_led_heartbeat                     => c_with_leds_heartbeat,
    g_num_buttons                            => c_buttons_num_pins
  )
  port map(
    clk_sys_i                                => clk_sys,
    rst_n_i                                  => clk_sys_rstn,

    -- UART
    uart_rxd_i                               => '1',
    uart_txd_o                               => open,

    -- LEDs
    led_out_o                                => gpio_leds_out_int,
    led_in_i                                 => gpio_leds_in_int,
    led_oen_o                                => open,

    -- Buttons
    button_out_o                             => open,
    button_in_i                              => buttons_dummy,
    button_oen_o                             => open,

    -- Wishbone
    slave_i                                  => cbar_dev_bus_master_out(c_dev_slv_periph_id),
    slave_o                                  => cbar_dev_bus_master_in(c_dev_slv_periph_id)
  );

  -- LED Red, LED Green, LED Blue
  leds_o <= gpio_leds_out_int;

  -----------------------------------------------------------------------------
  -- Board I2C Core
  -----------------------------------------------------------------------------

  gen_with_board_i2c : if not g_WITH_BOARD_I2C generate

    cmp_board_i2c: xwb_i2c_master
    generic map (
      g_interface_mode                       => PIPELINED,
      g_address_granularity                  => BYTE,
      g_num_interfaces                       => 1
    )
    port map (
      clk_sys_i                              => clk_sys,
      rst_n_i                                => clk_sys_rstn,

      slave_i                                => cbar_dev_bus_master_out(c_dev_slv_board_i2c_id),
      slave_o                                => cbar_dev_bus_master_in(c_dev_slv_board_i2c_id),

      int_o                                  => irqs(0),

      scl_pad_i (0)                          => board_i2c_scl_b,
      scl_pad_o (0)                          => board_i2c_scl_out,
      scl_padoen_o (0)                       => board_i2c_scl_oen,
      sda_pad_i (0)                          => board_i2c_sda_b,
      sda_pad_o (0)                          => board_i2c_sda_out,
      sda_padoen_o (0)                       => board_i2c_sda_oen
    );

    board_i2c_scl_b <= board_i2c_scl_out when board_i2c_scl_oen = '0' else 'Z';
    board_i2c_sda_b <= board_i2c_sda_out when board_i2c_sda_oen = '0' else 'Z';

  end generate;

  gen_without_board_i2c : if not g_WITH_BOARD_I2C generate

    cbar_dev_bus_master_in(c_dev_slv_board_i2c_id) <= c_DUMMY_WB_MASTER_IN;
    board_i2c_scl_b <= 'Z';
    board_i2c_sda_b <= 'Z';

  end generate;

  -----------------------------------------------------------------------------
  -- IRQ Core
  -----------------------------------------------------------------------------

  gen_user_irq: if g_NUM_USER_IRQ > 0 generate
    irqs(irq_user_i'range) <= irq_user_i;
  end generate gen_user_irq;

  gen_vic: if g_WITH_VIC generate

    cmp_vic: xwb_vic
    generic map (
      g_interface_mode                       => PIPELINED,
      g_address_granularity                  => BYTE,
      g_num_interrupts                       => num_interrupts
    )
    port map (
      clk_sys_i                              => clk_sys,
      rst_n_i                                => clk_sys_rstn,

      slave_i                                => cbar_dev_bus_master_out(c_dev_slv_vic_id),
      slave_o                                => cbar_dev_bus_master_in(c_dev_slv_vic_id),

      irqs_i                                 => irqs,
      irq_master_o                           => irq_master
    );

  end generate;

  gen_no_vic: if not g_WITH_VIC generate

    cbar_dev_bus_master_in(c_dev_slv_vic_id) <= c_DUMMY_WB_MASTER_IN;

  end generate;

  irqs(2) <= '0';
  irqs(3) <= '0';
  irqs(4) <= '0';
  irqs(5) <= '0';

  -----------------------------------------------------------------------------
  -- Flash SPI
  -----------------------------------------------------------------------------

  gen_with_spi: if g_WITH_SPI generate

    cmp_spi: entity work.xwb_spi
    generic map (
      g_interface_mode                       => PIPELINED,
      g_address_granularity                  => BYTE,
      g_divider_len                          => open,
      g_max_char_len                         => open,
      g_num_slaves                           => 1
    )
    port map (
      clk_sys_i                              => clk_sys,
      rst_n_i                                => clk_sys_rstn,

      slave_i                                => cbar_dev_bus_master_out(c_dev_slv_spi_id),
      slave_o                                => cbar_dev_bus_master_in(c_dev_slv_spi_id),

      int_o                                  => irqs(1),

      pad_cs_o(0)                            => spi_cs_n_o,
      pad_sclk_o                             => spi_sclk_o,
      pad_mosi_o                             => spi_mosi_o,
      pad_miso_i                             => spi_miso_i
    );

  end generate;

  gen_without_spi: if not g_WITH_SPI generate

    cbar_dev_bus_master_in(c_dev_slv_spi_id) <= c_DUMMY_WB_MASTER_IN;

  end generate;

  -----------------------------------------------------------------------------
  -- AFC Diagnostics
  -----------------------------------------------------------------------------

  gen_afc_diag : if g_WITH_DIAG generate

    cmp_xwb_afc_diag : xwb_afc_diag
    generic map(
      g_interface_mode                          => PIPELINED,
      g_address_granularity                     => BYTE
    )
    port map(
      sys_clk_i                                 => clk_sys,
      sys_rst_n_i                               => clk_sys_rstn,

      -- Fast SPI clock. Same as Wishbone clock.
      spi_clk_i                                 => clk_sys,

      -----------------------------
      -- Wishbone Control Interface signals
      -----------------------------
      wb_slv_i                                  => cbar_dev_bus_master_out(c_dev_slv_afc_diag_id),
      wb_slv_o                                  => cbar_dev_bus_master_in(c_dev_slv_afc_diag_id),

      -----------------------------
      -- SPI interface
      -----------------------------

      spi_cs                                    => diag_spi_cs_i,
      spi_si                                    => diag_spi_si_i,
      spi_so                                    => diag_spi_so_o,
      spi_clk                                   => diag_spi_clk_i
    );

  end generate;

  gen_without_afc_diag : if not g_WITH_DIAG generate

    cbar_dev_bus_master_in(c_dev_slv_afc_diag_id) <= c_DUMMY_WB_MASTER_IN;

  end generate;

  -----------------------------------------------------------------------------
  -- Trigger
  -----------------------------------------------------------------------------

  gen_trigger_with_aux_clk : if g_WITH_AUX_CLK generate

    trig_ref_clk <= clk_aux;
    trig_ref_rstn <= clk_aux_rstn;

  end generate;

  gen_trigger_without_aux_clk : if not g_WITH_AUX_CLK generate

    trig_ref_clk <= clk_sys;
    trig_ref_rstn <= clk_sys_rstn;

  end generate;

  clk_trig_ref_o <= trig_ref_clk;
  rst_trig_ref_n_o <= trig_ref_rstn;

  gen_with_trigger: if g_WITH_TRIGGER generate

    cmp_wb_trigger_iface : xwb_trigger_iface
    generic map (
      g_interface_mode                       => PIPELINED,
      g_address_granularity                  => BYTE,
      g_sync_edge                            => c_TRIG_SYNC_EDGE,
      g_trig_num                             => c_NUM_TRIG
    )
    port map (
      clk_i                                  => clk_sys,
      rst_n_i                                => clk_sys_rstn,

      ref_clk_i                              => trig_ref_clk,
      ref_rst_n_i                            => trig_ref_rstn,

      -----------------------------
      -- Wishbone Control Interface signals
      -----------------------------
      wb_slv_i                               => cbar_dev_bus_master_out(c_dev_slv_trig_iface_id),
      wb_slv_o                               => cbar_dev_bus_master_in(c_dev_slv_trig_iface_id),

      -----------------------------
      -- To/From pads
      -----------------------------
      trig_b                                 => trig_b,
      trig_dir_o                             => trig_dir_o,

      -----------------------------
      -- User Signals
      -----------------------------
      trig_out_o                             => trig_out_o,
      trig_in_i                              => trig_in_i,

      trig_dbg_o                             => trig_dbg_o,
      dbg_data_sync_o                        => trig_dbg_data_sync_o,
      dbg_data_degliteched_o                 => trig_dbg_data_degliteched_o
    );

  end generate;

  gen_without_trigger : if not g_WITH_TRIGGER generate

    cbar_dev_bus_master_in(c_dev_slv_trig_iface_id) <= c_DUMMY_WB_MASTER_IN;

  end generate;

  ----------------------------------------------------------------------
  -- AFC Si57x
  ----------------------------------------------------------------------

  gen_with_afc_si57x: if g_WITH_AFC_SI57x generate

    cmp_afc_si57x_interface : si57x_interface
    generic map (
      g_SYS_CLOCK_FREQ                           => g_SYS_CLOCK_FREQ,
      g_I2C_FREQ                                 => g_AFC_SI57x_I2C_FREQ,
      g_INIT_OSC                                 => g_AFC_SI57x_INIT_OSC,
      g_INIT_RFREQ_VALUE                         => g_AFC_SI57x_INIT_RFREQ_VALUE,
      g_INIT_N1_VALUE                            => g_AFC_SI57x_INIT_N1_VALUE,
      g_INIT_HS_VALUE                            => g_AFC_SI57x_INIT_HS_VALUE
    )
    port map (
      ---------------------------------------------------------------------------
      -- clock and reset interface
      ---------------------------------------------------------------------------
      clk_sys_i                                  => clk_sys,
      rst_n_i                                    => clk_sys_rstn,

      ---------------------------------------------------------------------------
      -- Optional external RFFREQ interface
      ---------------------------------------------------------------------------
      ext_wr_i                                   => afc_si57x_ext_wr_i,
      ext_rfreq_value_i                          => afc_si57x_ext_rfreq_value_i,
      ext_n1_value_i                             => afc_si57x_ext_n1_value_i,
      ext_hs_value_i                             => afc_si57x_ext_hs_value_i,

      ---------------------------------------------------------------------------
      -- Status pins
      ---------------------------------------------------------------------------
      sta_reconfig_done_o                        => afc_si57x_sta_reconfig_done_o,

      ---------------------------------------------------------------------------
      -- I2C bus: output enable (active low)
      ---------------------------------------------------------------------------
      scl_pad_oen_o                              => afc_si57x_scl_pad_oen,
      sda_pad_oen_o                              => afc_si57x_sda_pad_oen,

      ---------------------------------------------------------------------------
      -- SI57x pins
      ---------------------------------------------------------------------------
      -- Optional OE control
      si57x_oe_i                                 => afc_si57x_oe_i,
      si57x_addr_i                               => afc_si57x_addr_i,
      si57x_oe_o                                 => afc_si57x_oe_o
    );

    -- No input reading
    afc_si57x_scl_b <= '0' when afc_si57x_scl_pad_oen = '0' else 'Z';
    afc_si57x_sda_b <= '0' when afc_si57x_sda_pad_oen = '0' else 'Z';

  end generate;

  gen_without_afc_si57x: if not g_WITH_AFC_SI57x generate

    afc_si57x_sta_reconfig_done_o <= '0';
    afc_si57x_oe_o <= '0';
    afc_si57x_scl_b <= 'Z';
    afc_si57x_sda_b <= 'Z';

  end generate;

end architecture;
