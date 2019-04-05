------------------------------------------------------------------------------
-- Title      : Top generic AFC design with PCIe + LEDs
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2019-04-05
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: Example design for AFCv3 with PCIe + LEDs
-------------------------------------------------------------------------------
-- Copyright (c) 2019 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2019-04-05  1.0      lucas.russo        Created
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
-- Genrams
use work.genram_pkg.all;
-- IP cores constants
use work.ipcores_pkg.all;
-- Meta Package
use work.synthesis_descriptor_pkg.all;
-- AXI cores
use work.pcie_cntr_axi_pkg.all;

entity afc_pcie_leds is
port(
  -----------------------------------------
  -- Clocking pins
  -----------------------------------------
  sys_clk_p_i                              : in std_logic;
  sys_clk_n_i                              : in std_logic;

  -----------------------------------------
  -- Reset Button
  -----------------------------------------
  sys_rst_button_n_i                       : in std_logic;

  -----------------------------
  -- ADN4604ASVZ
  -----------------------------
  adn4604_vadj2_clk_updt_n_o               : out std_logic;

  -----------------------------------------
  -- PCIe pins
  -----------------------------------------

  -- DDR3 memory pins
  ddr3_dq_b                                 : inout std_logic_vector(c_ddr_dq_width-1 downto 0);
  ddr3_dqs_p_b                              : inout std_logic_vector(c_ddr_dqs_width-1 downto 0);
  ddr3_dqs_n_b                              : inout std_logic_vector(c_ddr_dqs_width-1 downto 0);
  ddr3_addr_o                               : out   std_logic_vector(c_ddr_row_width-1 downto 0);
  ddr3_ba_o                                 : out   std_logic_vector(c_ddr_bank_width-1 downto 0);
  ddr3_cs_n_o                               : out   std_logic_vector(0 downto 0);
  ddr3_ras_n_o                              : out   std_logic;
  ddr3_cas_n_o                              : out   std_logic;
  ddr3_we_n_o                               : out   std_logic;
  ddr3_reset_n_o                            : out   std_logic;
  ddr3_ck_p_o                               : out   std_logic_vector(c_ddr_ck_width-1 downto 0);
  ddr3_ck_n_o                               : out   std_logic_vector(c_ddr_ck_width-1 downto 0);
  ddr3_cke_o                                : out   std_logic_vector(c_ddr_cke_width-1 downto 0);
  ddr3_dm_o                                 : out   std_logic_vector(c_ddr_dm_width-1 downto 0);
  ddr3_odt_o                                : out   std_logic_vector(c_ddr_odt_width-1 downto 0);

  -- PCIe transceivers
  pci_exp_rxp_i                            : in  std_logic_vector(c_pcielanes - 1 downto 0);
  pci_exp_rxn_i                            : in  std_logic_vector(c_pcielanes - 1 downto 0);
  pci_exp_txp_o                            : out std_logic_vector(c_pcielanes - 1 downto 0);
  pci_exp_txn_o                            : out std_logic_vector(c_pcielanes - 1 downto 0);

  -- PCI clock and reset signals
  pcie_clk_p_i                             : in std_logic;
  pcie_clk_n_i                             : in std_logic;

  -----------------------------------------
  -- User LEDs
  -----------------------------------------
  leds_o                                   : out std_logic_vector(2 downto 0)
);
end afc_pcie_leds;

architecture rtl of afc_pcie_leds is

  -- Top crossbar layout
  -- Number of slaves
  constant c_slaves                        : natural := 1;
  -- Peripherals

  -- Slaves indexes
  constant c_slv_periph_id                 : natural := 0;
  -- These are not account in the number of slaves as these are special
  constant c_slv_sdb_repo_url_id           : natural := 1;
  constant c_slv_sdb_top_syn_id            : natural := 2;
  constant c_slv_sdb_gen_cores_id          : natural := 3;
  constant c_slv_sdb_infra_cores_id        : natural := 4;

  -- Number of masters
  constant c_masters                       : natural := 1;  -- PCIe

  -- Master indexes
  constant c_ma_pcie_id                    : natural := 0;

  -- GPIO num pinscalc
  constant c_leds_num_pins                  : natural := 3;
  constant c_with_leds_heartbeat            : t_boolean_array(c_leds_num_pins-1 downto 0) :=
                                                (2 => false,  -- Red LED
                                                 1 => false,  -- Green LED
                                                 0 => false); -- Blue LED
  constant c_buttons_num_pins               : natural := 8;

  -- Number of reset clock cycles (FF)
  constant c_button_rst_width               : natural := 255;

  -- Number of top level clocks
  constant c_num_tlvl_clks                  : natural := 2; -- CLK_SYS and CLK_200 MHz
  constant c_clk_sys_id                     : natural := 0;
  constant c_clk_200mhz_id                  : natural := 1;

  -- General peripherals layout. UART, LEDs (GPIO), Buttons (GPIO) and Tics counter
  constant c_periph_bridge_sdb : t_sdb_bridge := f_xwb_bridge_manual_sdb(x"00000FFF", x"00000400");

  -- WB SDB (Self describing bus) layout
  constant c_layout : t_sdb_record_array(c_slaves+4-1 downto 0) :=
    (
     c_slv_periph_id           => f_sdb_embed_bridge(c_periph_bridge_sdb,        x"00100000"),   -- General peripherals control port
     c_slv_sdb_repo_url_id     => f_sdb_embed_repo_url(c_sdb_repo_url),
     c_slv_sdb_top_syn_id      => f_sdb_embed_synthesis(c_sdb_top_syn_info),
     c_slv_sdb_gen_cores_id    => f_sdb_embed_synthesis(c_sdb_general_cores_syn_info),
     c_slv_sdb_infra_cores_id  => f_sdb_embed_synthesis(c_sdb_infra_cores_syn_info)
    );

  -- Self Describing Bus ROM Address. It will be an addressed slave as well
  constant c_sdb_address                    : t_wishbone_address := x"00000000";

  -- Crossbar master/slave arrays
  signal cbar_slave_i                        : t_wishbone_slave_in_array (c_masters-1 downto 0);
  signal cbar_slave_o                        : t_wishbone_slave_out_array(c_masters-1 downto 0);
  signal cbar_master_i                       : t_wishbone_master_in_array(c_slaves-1 downto 0);
  signal cbar_master_o                       : t_wishbone_master_out_array(c_slaves-1 downto 0);

  -- PCIe signals
  signal wb_ma_pcie_rst                      : std_logic;
  signal wb_ma_pcie_rstn                     : std_logic;
  signal wb_ma_pcie_rstn_sync                : std_logic;

  -- DBE Peripheral signal
  signal gpio_leds_out_int                   : std_logic_vector(c_leds_num_pins-1 downto 0);
  signal gpio_leds_in_int                    : std_logic_vector(c_leds_num_pins-1 downto 0) := (others => '0');

  -- Clocks and resets signals
  signal locked                              : std_logic;
  signal clk_sys_pcie_rstn                   : std_logic;
  signal clk_sys_pcie_rst                    : std_logic;
  signal clk_sys_rstn                        : std_logic;
  signal clk_sys_rst                         : std_logic;
  signal clk_200mhz_rst                      : std_logic;
  signal clk_200mhz_rstn                     : std_logic;
  signal rst_button_sys_pp                   : std_logic;
  signal rst_button_sys                      : std_logic;
  signal rst_button_sys_n                    : std_logic;

  signal clk_sys                             : std_logic;
  signal clk_200mhz                         : std_logic;

  -- "c_num_tlvl_clks" clocks
  signal reset_clks                          : std_logic_vector(c_num_tlvl_clks-1 downto 0);
  signal reset_rstn                          : std_logic_vector(c_num_tlvl_clks-1 downto 0);

   -- Global Clock Single ended
  signal sys_clk_gen                         : std_logic;
  signal sys_clk_gen_bufg                    : std_logic;

  signal buttons_dummy                       : std_logic_vector(7 downto 0) := (others => '0');

  ---------------------------
  --      Components       --
  ---------------------------

  -- Clock generation
  component clk_gen is
  port(
    sys_clk_p_i                              : in std_logic;
    sys_clk_n_i                              : in std_logic;
    sys_clk_o                                : out std_logic;
    sys_clk_bufg_o                           : out std_logic
  );
  end component;

  -- Xilinx PLL
  component sys_pll is
  generic(
    -- 200 MHz input clock
    g_clkin_period                           : real := 5.000;
    g_divclk_divide                          : integer := 1;
    g_clkbout_mult_f                         : integer := 5;

    -- 100 MHz output clock
    g_clk0_divide_f                          : integer := 10;
    -- 200 MHz output clock
    g_clk1_divide                            : integer := 5;
    -- 200 MHz output clock
    g_clk2_divide                            : integer := 5
  );
  port(
    rst_i                                    : in std_logic := '0';
    clk_i                                    : in std_logic := '0';
    clk0_o                                   : out std_logic;
    clk1_o                                   : out std_logic;
    clk2_o                                   : out std_logic;
    locked_o                                 : out std_logic
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
    g_divclk_divide                          => 5,
    g_clkbout_mult_f                         => 48,

    -- 100 MHz output clock
    g_clk0_divide_f                          => 12,
    -- 200 MHz output clock
    g_clk1_divide                            => 6,
    -- 300 MHz output clock
    g_clk2_divide                            => 4
  )
  port map (
    rst_i                                    => '0',
    clk_i                                    => sys_clk_gen_bufg,
    clk0_o                                   => clk_sys,     -- 100MHz locked clock
    clk1_o                                   => clk_200mhz,  -- 200MHz locked clock
    clk2_o                                   => open,
    locked_o                                 => locked       -- '1' when the PLL has locked
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

  -- Reset for PCIe core. Caution when resetting the PCIe core after the
  -- initialization. The PCIe core needs to retrain the link and the PCIe
  -- host (linux OS, likely) will not be able to do that automatically,
  -- probably.
  clk_sys_pcie_rstn                          <= reset_rstn(c_clk_sys_id) and rst_button_sys_n;
  clk_sys_pcie_rst                           <= not clk_sys_pcie_rstn;
  -- Reset for all other modules
  clk_sys_rstn                               <= reset_rstn(c_clk_sys_id) and rst_button_sys_n and
                                                   wb_ma_pcie_rstn_sync;
  clk_sys_rst                                <= not clk_sys_rstn;
  -- Reset synchronous to clk200mhz
  clk_200mhz_rstn                           <= reset_rstn(c_clk_200mhz_id) and rst_button_sys_n;
  clk_200mhz_rst                            <=  not clk_200mhz_rstn;

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
  -- Top-Level Crossbar
  -----------------------------------------------------------------------------

  -- The top-most Wishbone B.4 crossbar
  cmp_interconnect : xwb_sdb_crossbar
  generic map(
    g_num_masters                            => c_masters,
    g_num_slaves                             => c_slaves,
    g_registered                             => true,
    g_wraparound                             => true, -- Should be true for nested buses
    g_layout                                 => c_layout,
    g_sdb_addr                               => c_sdb_address
  )
  port map(
    clk_sys_i                                => clk_sys,
    rst_n_i                                  => clk_sys_rstn,
    -- Master connections (INTERCON is a slave)
    slave_i                                  => cbar_slave_i,
    slave_o                                  => cbar_slave_o,
    -- Slave connections (INTERCON is a master)
    master_i                                 => cbar_master_i,
    master_o                                 => cbar_master_o
  );

  ----------------------------------
  --         PCIe Core            --
  ----------------------------------

  cmp_xwb_pcie_cntr : xwb_pcie_cntr
  generic map (
    g_ma_interface_mode                      => PIPELINED,
    g_ma_address_granularity                 => BYTE,
    g_simulation                             => "FALSE"
  )
  port map (
    -- DDR3 memory pins
    ddr3_dq_b                                 => ddr3_dq_b,
    ddr3_dqs_p_b                              => ddr3_dqs_p_b,
    ddr3_dqs_n_b                              => ddr3_dqs_n_b,
    ddr3_addr_o                               => ddr3_addr_o,
    ddr3_ba_o                                 => ddr3_ba_o,
    ddr3_cs_n_o                               => ddr3_cs_n_o,
    ddr3_ras_n_o                              => ddr3_ras_n_o,
    ddr3_cas_n_o                              => ddr3_cas_n_o,
    ddr3_we_n_o                               => ddr3_we_n_o,
    ddr3_reset_n_o                            => ddr3_reset_n_o,
    ddr3_ck_p_o                               => ddr3_ck_p_o,
    ddr3_ck_n_o                               => ddr3_ck_n_o,
    ddr3_cke_o                                => ddr3_cke_o,
    ddr3_dm_o                                 => ddr3_dm_o,
    ddr3_odt_o                                => ddr3_odt_o,

    -- PCIe transceivers
    pci_exp_rxp_i                             => pci_exp_rxp_i,
    pci_exp_rxn_i                             => pci_exp_rxn_i,
    pci_exp_txp_o                             => pci_exp_txp_o,
    pci_exp_txn_o                             => pci_exp_txn_o,

    -- Necessity signals
    ddr_clk_i                                 => clk_200mhz,        --200 MHz DDR core clock (connect through BUFG or PLL)
    ddr_rst_i                                 => clk_200mhz_rst,
    pcie_clk_p_i                              => pcie_clk_p_i,      --100 MHz PCIe Clock (connect directly to input pin)
    pcie_clk_n_i                              => pcie_clk_n_i,      --100 MHz PCIe Clock
    pcie_rst_n_i                              => clk_sys_pcie_rstn, -- PCIe core reset

    -- Wishbone interface --
    wb_clk_i                                  => clk_sys,
    -- Reset wishbone interface with the same reset as the other
    -- modules, including a reset coming from the PCIe itself.
    wb_rst_i                                 => clk_sys_rst,
    wb_ma_i                                  => cbar_slave_o(c_ma_pcie_id),
    wb_ma_o                                  => cbar_slave_i(c_ma_pcie_id),
    -- Additional exported signals for instantiation
    wb_ma_pcie_rst_o                         => wb_ma_pcie_rst
  );

  wb_ma_pcie_rstn                            <= not wb_ma_pcie_rst;

  cmp_pcie_reset_synch : reset_synch
  port map
  (
    clk_i                                    => clk_sys,
    arst_n_i                                 => wb_ma_pcie_rstn,
    rst_n_o                                  => wb_ma_pcie_rstn_sync
  );

  ----------------------------------------------------------------------
  --                      Peripherals Core                            --
  ----------------------------------------------------------------------

  cmp_xwb_dbe_periph : xwb_dbe_periph
  generic map(
    g_interface_mode                          => PIPELINED,
    g_address_granularity                     => BYTE,
    g_num_leds                                => c_leds_num_pins,
    g_with_led_heartbeat                      => c_with_leds_heartbeat,
    g_num_buttons                             => c_buttons_num_pins
  )
  port map(
    clk_sys_i                                 => clk_sys,
    rst_n_i                                   => clk_sys_rstn,

    -- UART
    uart_rxd_i                                => '1',
    uart_txd_o                                => open,

    -- LEDs
    led_out_o                                 => gpio_leds_out_int,
    led_in_i                                  => gpio_leds_in_int,
    led_oen_o                                 => open,

    -- Buttons
    button_out_o                              => open,
    button_in_i                               => buttons_dummy,
    button_oen_o                              => open,

    -- Wishbone
    slave_i                                   => cbar_master_o(c_slv_periph_id),
    slave_o                                   => cbar_master_i(c_slv_periph_id)
  );

  -- LED Red, LED Green, LED Blue
  leds_o <= gpio_leds_out_int;

end rtl;
