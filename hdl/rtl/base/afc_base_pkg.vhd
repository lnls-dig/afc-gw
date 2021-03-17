library ieee;
use ieee.std_logic_1164.all;

library work;
-- Wishbone definitions
use work.wishbone_pkg.all;
-- IP cores constants
use work.ipcores_pkg.all;
-- Trigger Common Modules
use work.trigger_common_pkg.all;
-- AXI cores
use work.pcie_cntr_axi_pkg.all;

package afc_base_pkg is

  --------------------------------------------------------------------
  -- Constants
  --------------------------------------------------------------------
  constant c_NUM_TRIG                        : natural := 8;

  --------------------------------------------------------------------
  -- SDB Devices Structures
  --------------------------------------------------------------------

  constant c_dummy_sdb_bridge : t_sdb_record := (511 downto 8 => '0') & x"02";

  --------------------------------------------------------------------
  -- Components
  --------------------------------------------------------------------
  component afc_base
  generic (
    -- system PLL parameters
    g_DIVCLK_DIVIDE                          : integer := 5;
    g_CLKBOUT_MULT_F                         : integer := 48;
    g_CLK0_DIVIDE_F                          : integer := 12;
    g_CLK1_DIVIDE                            : integer := 6;
    g_CLK2_DIVIDE                            : integer := 4;
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

    clk_300mhz_o                             : out std_logic;
    rst_300mhz_n_o                           : out std_logic;

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
  end component;

end afc_base_pkg;
