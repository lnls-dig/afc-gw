library ieee;
use ieee.std_logic_1164.all;

library work;
use work.wishbone_pkg.all;

package afc_base_regs_pkg is

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
