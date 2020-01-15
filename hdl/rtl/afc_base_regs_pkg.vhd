library ieee;
use ieee.std_logic_1164.all;

library work;
use work.wishbone_pkg.all;

package afc_base_regs_pkg is

  -- Components
  component afc_base_regs
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(6 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- SRAM bus metadata
    metadata_addr_o      : out   std_logic_vector(5 downto 2);
    metadata_data_i      : in    std_logic_vector(31 downto 0);
    metadata_data_o      : out   std_logic_vector(31 downto 0);
    metadata_wr_o        : out   std_logic;

    -- presence lines for the fmcs
    csr_fmc_presence_i   : in    std_logic_vector(31 downto 0);

    -- status of the ddr3 controller
    -- Set when calibration is done.
    csr_ddr_status_calib_done_i : in    std_logic;

    -- pcb revision
    csr_pcb_rev_id_i     : in    std_logic_vector(3 downto 0)
  );
  end component;

  --------------------------------------------------------------------
  -- SDB Devices Structures
  --------------------------------------------------------------------

  -- AFC MGMT
  constant c_xwb_afc_base_regs_sdb : t_sdb_device := (
    abi_class     => x"0000",                   -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"00",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"4",                      -- 32-bit port granularity (0100)
    sdb_component => (
    addr_first    => x"0000000000000000",
    addr_last     => x"00000000000000FF",
    product => (
    vendor_id     => x"1000000000001215",       -- LNLS
    device_id     => x"af1a1c3e",
    version       => x"00000001",
    date          => x"20200107",
    name          => "LNLS_AFC_BASE_REGS ")));

end afc_base_regs_pkg;
