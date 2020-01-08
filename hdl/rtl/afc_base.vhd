--------------------------------------------------------------------------------
-- CERN BE-CO-HT
-- AFC
-- https://ohwr.org/projects/afc
--------------------------------------------------------------------------------
--
-- unit name:   afc_base
--
-- description: AFC carrier base.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2019
--------------------------------------------------------------------------------
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 2.0 (the "License"); you may not use this file except
-- in compliance with the License. You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-2.0.
-- Unless required by applicable law or agreed to in writing, software,
-- hardware and materials distributed under this License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
-- or implied. See the License for the afcific language governing permissions
-- and limitations under the License.
--------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Title      : BSP for AFC with PCIe + LEDs
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2020-01-07
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: BSP for AFC with PCIe + LEDs
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
-- Genrams
use work.genram_pkg.all;
-- IP cores constants
use work.ipcores_pkg.all;
-- Meta Package
use work.synthesis_descriptor_pkg.all;
-- AXI cores
use work.pcie_cntr_axi_pkg.all;
-- AFC regs package
use work.afc_base_regs_pkg.all;

entity afc_base is
generic (
  --  If true, instantiate a VIC/UART/DIAG/SPI.
  g_WITH_VIC                               : boolean := True;
  g_WITH_UART_MASTER                       : boolean := True;
  g_WITH_DIAG                              : boolean := True;
  g_WITH_TRIGGER                           : boolean := True;
  g_WITH_SPI                               : boolean := True;
  g_WITH_BOARD_I2C                         : boolean := True;
  --  Number of user interrupts
  g_NUM_USER_IRQ                           : natural := 1
);
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
  trig_dir_o                               : out   std_logic_vector(7 downto 0);
  trig_b                                   : inout std_logic_vector(7 downto 0);

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
  leds_o                                   : out std_logic_vector(2 downto 0)

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
  spi_miso_i                               : in  std_logic;

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

  clk_200mhz_o                             : out std_logic;
  rst_200mhz_n_o                           : out std_logic;

  clk_pcie_o                               : out std_logic;
  rst_pcie_n_o                             : out std_logic;

  --  Interrupts
  irq_user_i                               : in std_logic_vector(g_NUM_USER_IRQ + 5 downto 6) := (others => '0');

  --  The wishbone bus from the gennum/host to the application
  --  Addresses 0-0x1fff are not available (used by the carrier).
  --  This is a pipelined wishbone with byte granularity.
  app_wb_o                                 : out t_wishbone_master_out;
  app_wb_i                                 : in  t_wishbone_master_in
);
end entity afc_base;

architecture top of afc_base is

  -- Top crossbar layout
  -- Number of slaves
  constant c_slaves                          : natural := 5;
  -- Peripherals

  -- Slaves indexes
  constant c_slv_afc_base_id                 : natural := 0;
  constant c_slv_periph_id                   : natural := 1;
  constant c_slv_board_i2c_id                : natural := 2;
  constant c_slv_vic_id                      : natural := 3;
  constant c_slv_spi_id                      : natural := 4;
  -- These are not account in the number of slaves as these are special
  constant c_slv_sdb_repo_url_id             : natural := 5;
  constant c_slv_sdb_top_syn_id              : natural := 6;
  constant c_slv_sdb_gen_cores_id            : natural := 7;
  constant c_slv_sdb_infra_cores_id          : natural := 8;

  -- Number of masters
  constant c_masters                         : natural := 2;  -- PCIe and, possibly, RS232

  -- Master indexes
  constant c_ma_pcie_id                      : natural := 0;
  constant c_ma_rs232_syscon_id              : natural := 1;

  -- GPIO num pinscalc
  constant c_leds_num_pins                   : natural := 3;
  constant c_with_leds_heartbeat             : t_boolean_array(c_leds_num_pins-1 downto 0) :=
                                                 (2 => false,  -- Red LED
                                                  1 => false,  -- Green LED
                                                  0 => false); -- Blue LED
  constant c_buttons_num_pins                : natural := 8;

  -- Number of reset clock cycles (FF)
  constant c_button_rst_width                : natural := 255;

  -- Number of top level clocks
  constant c_num_tlvl_clks                   : natural := 3; -- CLK_SYS and CLK_200 MHz and PCIE
  constant c_clk_sys_id                      : natural := 0;
  constant c_clk_200mhz_id                   : natural := 1;
  constant c_clk_pcie_id                     : natural := 2;

  -- General peripherals layout. UART, LEDs (GPIO), Buttons (GPIO) and Tics counter
  constant c_periph_bridge_sdb : t_sdb_bridge := f_xwb_bridge_manual_sdb(x"00000FFF", x"00000400");

  -- WB SDB (Self describing bus) layout
  constant c_layout : t_sdb_record_array(c_slaves+4-1 downto 0) :=
    (
     c_slv_afc_base_id         => f_sdb_embed_device(c_xwb_afc_base_regs_sdb,    x"00001000"),   -- AFC base registers control port
     c_slv_periph_id           => f_sdb_embed_bridge(c_periph_bridge_sdb,        x"00002000"),   -- General peripherals control port
     c_slv_board_i2c_id        => f_sdb_embed_device(c_xwb_i2c_master_sdb,       x"00003000"),   -- Board I2C
     c_slv_vic_id              => f_sdb_embed_device(c_xwb_vic_sdb,              x"00004000"),   -- VIC
     c_slv_spi_id              => f_sdb_embed_device(c_xwb_spi_sdb,              x"00005000"),   -- Flash SPI
     c_slv_sdb_repo_url_id     => f_sdb_embed_repo_url(c_sdb_repo_url),
     c_slv_sdb_top_syn_id      => f_sdb_embed_synthesis(c_sdb_top_syn_info),
     c_slv_sdb_gen_cores_id    => f_sdb_embed_synthesis(c_sdb_general_cores_syn_info),
     c_slv_sdb_infra_cores_id  => f_sdb_embed_synthesis(c_sdb_infra_cores_syn_info)
    );

  -- Self Describing Bus ROM Address. It will be an addressed slave as well
  constant c_sdb_address                     : t_wishbone_address := x"00000000";

  -- Crossbar master/slave arrays
  signal cbar_slave_in                       : t_wishbone_slave_in_array (c_masters-1 downto 0);
  signal cbar_slave_out                      : t_wishbone_slave_out_array(c_masters-1 downto 0);
  signal cbar_master_in                      : t_wishbone_master_in_array(c_slaves-1 downto 0);
  signal cbar_master_out                     : t_wishbone_master_out_array(c_slaves-1 downto 0);

  -- Metadate
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
  signal clk_pcie                            : std_logic;
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
  signal clk_200mhz                          : std_logic;

  -- "c_num_tlvl_clks" clocks
  signal reset_clks                          : std_logic_vector(c_num_tlvl_clks-1 downto 0);
  signal reset_rstn                          : std_logic_vector(c_num_tlvl_clks-1 downto 0);

   -- Global Clock Single ended
  signal sys_clk_gen                         : std_logic;
  signal sys_clk_gen_bufg                    : std_logic;

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

begin

  -----------------------------------------------------------------------------
  -- Main clock generation
  -----------------------------------------------------------------------------

  cmp_clk_gen : entity work.clk_gen
  port map (
    sys_clk_p_i                              => sys_clk_p_i,
    sys_clk_n_i                              => sys_clk_n_i,
    sys_clk_o                                => sys_clk_gen,
    sys_clk_bufg_o                           => sys_clk_gen_bufg
  );

   -- Obtain core locking and generate necessary clocks
  cmp_sys_pll_inst : entity work.sys_pll
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

  cmp_aux_clk_gen : entity work.clk_gen_mgt
  port map (
    sys_clk_p_i                              => aux_clk_p_i,
    sys_clk_n_i                              => aux_clk_n_i,
    sys_clk_o                                => aux_clk_gen,
    sys_clk_bufg_o                           => aux_clk_gen_bufg
  );

   -- Auxiliary clock
  cmp_aux_sys_pll_inst : entity work.sys_pll
  generic map (
    -- RF*5/36 ~ 69.44 MHz input clock ~ 14.4 ns
    g_clkin_period                           => 14.400,
    g_divclk_divide                          => 1,
    g_clkbout_mult_f                         => 18,

    -- 125 MHz output clock
    g_clk0_divide_f                          => 10
  )
  port map (
    rst_i                                    => '0',
    clk_i                                    => aux_clk_gen_bufg,
    --clk_i                                    => aux_clk_gen,
    clk0_o                                   => clk_aux,              -- 125MHz locked clock
    clk1_o                                   => open,
    clk2_o                                   => open,
    locked_o                                 => clk_aux_locked        -- '1' when the PLL has locked
  );

  -- Reset synchronization. Hold reset line until few locked cycles have passed.
  cmp_aux_reset : gc_reset
  generic map(
    g_clocks                                 => c_num_aux_clks        -- CLK_AUX
  )
  port map(
    --free_clk_i                               => aux_clk_gen,
    free_clk_i                               => aux_clk_gen_bufg,
    locked_i                                 => clk_aux_locked,
    clks_i                                   => reset_aux_clks,
    rstn_o                                   => reset_aux_rstn
  );

  reset_aux_clks(c_clk_aux_id)               <= clk_aux;

  -- Auxiliary reset
  clk_aux_rstn                               <= reset_aux_rstn(c_clk_aux_id);
  clk_aux_rst                                <= not(reset_aux_rstn(c_clk_aux_id));

  -- Output assignments
  clk_aux_o                                  <= clk_aux;
  rst_aux_n_o                                <= clk_aux_rstn;

  -----------------------------------------------------------------------------
  -- PCIe Core
  -----------------------------------------------------------------------------

  cmp_xwb_pcie_cntr : xwb_pcie_cntr
  generic map (
    g_ma_interface_mode                       => PIPELINED,
    g_ma_address_granularity                  => BYTE,
    g_simulation                              => "FALSE"
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
    wb_ma_i                                  => cbar_slave_out(c_ma_pcie_id),
    wb_ma_o                                  => cbar_slave_in(c_ma_pcie_id),
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
      wb_master_i                            => cbar_slave_out(c_ma_rs232_syscon_id),
      wb_master_o                            => cbar_slave_in(c_ma_rs232_syscon_id)
    );

  end generate;

  gen_without_uart_master : if not g_WITH_UART_MASTER generate

    rs232_txd_o <= '0';
    uart_rstn <= '1';
    cbar_slave_out(c_ma_rs232_syscon_id) <= c_DUMMY_WB_MASTER_IN;

  end generate;

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
    slave_i                                  => cbar_slave_in,
    slave_o                                  => cbar_slave_out,
    -- Slave connections (INTERCON is a master)
    master_i                                 => cbar_master_in,
    master_o                                 => cbar_master_out
  );

  cmp_afc_base_regs: afc_base_regs
  port map (
    rst_n_i                                  => clk_sys_rstn,
    clk_i                                    => clk_sys,
    wb_cyc_i                                 => cbar_slave_in(c_slv_afc_base_id).cyc,
    wb_stb_i                                 => cbar_slave_in(c_slv_afc_base_id).stb,
    wb_adr_i                                 => cbar_slave_in(c_slv_afc_base_id).adr(3 downto 2),  -- Bytes address from PCIe
    wb_sel_i                                 => cbar_slave_in(c_slv_afc_base_id).sel,
    wb_we_i                                  => cbar_slave_in(c_slv_afc_base_id).we,
    wb_dat_i                                 => cbar_slave_in(c_slv_afc_base_id).dat,
    wb_ack_o                                 => cbar_slave_out(c_slv_afc_base_id).ack,
    wb_err_o                                 => cbar_slave_out(c_slv_afc_base_id).err,
    wb_rty_o                                 => cbar_slave_out(c_slv_afc_base_id).rty,
    wb_stall_o                               => cbar_slave_out(c_slv_afc_base_id).stall,
    wb_dat_o                                 => cbar_slave_out(c_slv_afc_base_id).dat,

    -- presence lines for the fmcs
    csr_fmc_presence_i                       => fmc_presence,

    csr_ddr_status_calib_done_i              => ddr_rdy,
    csr_pcb_rev_id_i                         => pcb_rev_id_i,

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
    slave_i                                  => cbar_master_out(c_slv_periph_id),
    slave_o                                  => cbar_master_in(c_slv_periph_id)
  );

  -- LED Red, LED Green, LED Blue
  leds_o <= gpio_leds_out_int;

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

      slave_i                                => cbar_master_out(c_slv_board_i2c_id),
      slave_o                                => cbar_master_in(c_slv_board_i2c_id),

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

    cbar_master_in(c_slv_board_i2c_id) <= (
        ack => '1',
        err => '0',
        rty => '0',
        stall => '0',
        dat => x"00000000");
    board_i2c_scl_b <= 'Z';
    board_i2c_sda_b <= 'Z';

  end generate;

  gen_user_irq: if g_NUM_USER_IRQ > 0 generate
    irqs(irq_user_i'range) <= irq_user_i;
  end generate gen_user_irq;

  gen_vic: if g_WITH_VIC generate

    cmp_vic: xwb_vic
    generic map (
      g_address_granularity                  => BYTE,
      g_num_interrupts                       => num_interrupts,
      g_FIXED_POLARITY                       => True,
      g_POLARITY                             => '1'
    )
    port map (
      clk_sys_i                              => clk_sys,
      rst_n_i                                => clk_sys_rstn,

      slave_i                                => cbar_master_out(c_slv_vic_id),
      slave_o                                => cbar_master_in(c_slv_vic_id),

      irqs_i                                 => irqs,
      irq_master_o                           => irq_master
    );

  end generate;

  gen_no_vic: if not g_WITH_VIC generate

    cbar_master_in(c_slv_vic_id) <= (
        ack => '1',
        err => '0',
        rty => '0',
        stall => '0',
        dat => x"00000000");
    irq_master <= '0';

  end generate;

  irqs(2) <= '0';
  irqs(3) <= '0';
  irqs(4) <= '0';
  irqs(5) <= '0';

  gen_spi: if g_WITH_SPI generate

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

      slave_i                                => cbar_master_out(c_slv_spi_id),
      slave_o                                => cbar_master_in(c_slv_spi_id),

      int_o                                  => irqs(1),

      pad_cs_o(0)                            => spi_cs_n_o,
      pad_sclk_o                             => spi_sclk_o,
      pad_mosi_o                             => spi_mosi_o,
      pad_miso_i                             => spi_miso_i
    );

  end generate;

  gen_without_spi: if not g_WITH_SPI generate

    cbar_master_in(c_slv_spi_id) <= (
        ack => '1',
        err => '0',
        rty => '0',
        stall => '0',
        dat => x"00000000");

  end generate;

end architecture;
