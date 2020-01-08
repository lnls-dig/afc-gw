library ieee;
use ieee.std_logic_1164.all;

library work;
use work.wishbone_pkg.all;

package afc_base_pkg is

  --------------------------------------------------------------------
  -- Constants
  --------------------------------------------------------------------
  constant c_NUM_TRIG                        : natural := 8;

  --------------------------------------------------------------------
  -- SDB Devices Structures
  --------------------------------------------------------------------

  -- AFC MGMT
  constant c_dummy_sdb_bridge : t_sdb_record := ((511 downto 8 => '0'), (7 downto 0 => x"02"));

end afc_base_regs_pkg;
