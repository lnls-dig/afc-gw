library ieee;
use ieee.std_logic_1164.all;

library work;
-- Wishbone definitions
use work.wishbone_pkg.all;
-- IP cores constants
use work.ipcores_pkg.all;
-- Trigger Common Modules
use work.trigger_common_pkg.all;
-- AFC base definitions
use work.afc_base_pkg.all;
-- Acq definitions
use work.acq_core_pkg.all;
-- AXI cores
use work.pcie_cntr_axi_pkg.all;

package afc_base_acq_pkg is

  --------------------------------------------------------------------
  -- Types
  --------------------------------------------------------------------

  type t_natural_array is array (natural range <>) of natural;
  type t_sdb_device_array is array (natural range <>) of t_sdb_device;

  --------------------------------------------------------------------
  -- Constants
  --------------------------------------------------------------------

  constant c_DUMMY_SDB_RECORD_ARRAY : t_sdb_record_array(0 downto 0) :=
  (
    0 => f_sdb_auto_device(cc_dummy_sdb_device, false)
  );

  --------------------------------------------------------------------
  -- Functions
  --------------------------------------------------------------------

  function f_gen_ramp(start : natural; finish : natural; increasing : boolean := true)
    return t_natural_array;

  function f_build_auto_device_array(sdb_device : t_sdb_device ; length : positive)
    return t_sdb_record_array;
  function f_build_auto_device_array(sdb_device_array : t_sdb_device_array ; length : positive)
    return t_sdb_record_array;

  --------------------------------------------------------------------
  -- Components
  --------------------------------------------------------------------
  component afc_base_acq
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
    g_USER_SDB_RECORD_ARRAY                    : t_sdb_device_array := c_DUMMY_SDB_RECORD_ARRAY;
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
  end component;

end afc_base_acq_pkg;

package body afc_base_acq_pkg is

  function f_gen_ramp(start : natural; finish : natural; increasing : boolean := true)
    return t_natural_array
  is
    variable res : t_natural_array(finish-start-1 downto 0);
    constant res_length : natural := res'length;
  begin

    if increasing then
      for i in 0 to res_length-1 loop
        res(i) := start + i;
      end loop;
    else
      for i in 0 to res_length-1 loop
        res(i) := start + res_length - 1 - i;
      end loop;
    end if;

    return res;
  end;

  function f_build_auto_device_array(sdb_device : t_sdb_device ; length : positive)
    return t_sdb_record_array
  is
    variable res : t_sdb_record_array(length-1 downto 0);
  begin

    -- Check if we contain only the placeholder element
    if res'length >= 2 then
      for i in 0 to res'length-2 loop
        res(i) := f_sdb_auto_device(sdb_device, true);
      end loop;
    end if;

    -- Last one is the placeholder
    res(res'left) := f_sdb_auto_device(c_DUMMY_SDB_DEVICE,  false);

    return res;
  end f_build_auto_device_array;

  function f_build_auto_device_array(sdb_device_array : t_sdb_device_array ; length : positive)
    return t_sdb_record_array
  is
    variable res : t_sdb_record_array(length-1 downto 0);
  begin

    -- Check if we contain only the placeholder element
    if res'length >= 2 then
      for i in 0 to res'length-2 loop
        res(i) := f_sdb_auto_device(sdb_device_array(i), true);
      end loop;
    end if;

    -- Last one is the placeholder
    res(res'left) := f_sdb_auto_device(c_DUMMY_SDB_DEVICE,  false);

    return res;
  end f_build_auto_device_array;

end afc_base_acq_pkg;
