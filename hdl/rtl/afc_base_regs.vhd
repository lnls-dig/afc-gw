-- Do not edit.  Generated on Tue Jan 07 14:49:28 2020 by lerwys
-- With Cheby 1.4.dev0 and these options:
--  --gen-hdl afc_base_regs.vhd -i afc_base_regs.cheby


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity afc_base_regs is
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

    -- global and application resets
    csr_resets_global_o  : out   std_logic;
    csr_resets_appl_o    : out   std_logic;

    -- presence lines for the fmcs
    csr_fmc_presence_i   : in    std_logic_vector(31 downto 0);

    -- status of the ddr3 controller
    -- Set when calibration is done.
    csr_ddr_status_calib_done_i : in    std_logic;

    -- pcb revision
    csr_pcb_rev_id_i     : in    std_logic_vector(3 downto 0)
  );
end afc_base_regs;

architecture syn of afc_base_regs is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal metadata_rack                  : std_logic;
  signal metadata_re                    : std_logic;
  signal csr_resets_global_reg          : std_logic;
  signal csr_resets_appl_reg            : std_logic;
  signal csr_resets_wreq                : std_logic;
  signal csr_resets_wack                : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(6 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
  signal metadata_wp                    : std_logic;
  signal metadata_we                    : std_logic;
begin

  -- WB decode signals
  wb_en <= wb_cyc_i and wb_stb_i;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_we_i)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_we_i) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_we_i)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_we_i) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';
  wb_err_o <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
        wr_sel_d0 <= wb_sel_i;
      end if;
    end if;
  end process;

  -- Interface metadata
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        metadata_rack <= '0';
      else
        metadata_rack <= metadata_re and not metadata_rack;
      end if;
    end if;
  end process;
  metadata_data_o <= wr_dat_d0;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        metadata_wp <= '0';
      else
        metadata_wp <= (wr_req_d0 or metadata_wp) and rd_req_int;
      end if;
    end if;
  end process;
  metadata_we <= (wr_req_d0 or metadata_wp) and not rd_req_int;
  process (wb_adr_i, wr_adr_d0, metadata_re) begin
    if metadata_re = '1' then
      metadata_addr_o <= wb_adr_i(5 downto 2);
    else
      metadata_addr_o <= wr_adr_d0(5 downto 2);
    end if;
  end process;

  -- Register csr_resets
  csr_resets_global_o <= csr_resets_global_reg;
  csr_resets_appl_o <= csr_resets_appl_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        csr_resets_global_reg <= '0';
        csr_resets_appl_reg <= '0';
        csr_resets_wack <= '0';
      else
        if csr_resets_wreq = '1' then
          csr_resets_global_reg <= wr_dat_d0(0);
          csr_resets_appl_reg <= wr_dat_d0(1);
        end if;
        csr_resets_wack <= csr_resets_wreq;
      end if;
    end if;
  end process;

  -- Register csr_fmc_presence

  -- Register csr_ddr_status

  -- Register csr_pcb_rev

  -- Process for write requests.
  process (wr_adr_d0, metadata_we, wr_req_d0, csr_resets_wack) begin
    metadata_wr_o <= '0';
    csr_resets_wreq <= '0';
    case wr_adr_d0(6 downto 6) is
    when "0" => 
      -- Submap metadata
      metadata_wr_o <= metadata_we;
      wr_ack_int <= metadata_we;
    when "1" => 
      case wr_adr_d0(5 downto 2) is
      when "0000" => 
        -- Reg csr_resets
        csr_resets_wreq <= wr_req_d0;
        wr_ack_int <= csr_resets_wack;
      when "0001" => 
        -- Reg csr_fmc_presence
        wr_ack_int <= wr_req_d0;
      when "0010" => 
        -- Reg csr_ddr_status
        wr_ack_int <= wr_req_d0;
      when "0011" => 
        -- Reg csr_pcb_rev
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, metadata_data_i, metadata_rack, rd_req_int, csr_resets_global_reg, csr_resets_appl_reg, csr_fmc_presence_i, csr_ddr_status_calib_done_i, csr_pcb_rev_id_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    metadata_re <= '0';
    case wb_adr_i(6 downto 6) is
    when "0" => 
      -- Submap metadata
      rd_dat_d0 <= metadata_data_i;
      rd_ack_d0 <= metadata_rack;
      metadata_re <= rd_req_int;
    when "1" => 
      case wb_adr_i(5 downto 2) is
      when "0000" => 
        -- Reg csr_resets
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= csr_resets_global_reg;
        rd_dat_d0(1) <= csr_resets_appl_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "0001" => 
        -- Reg csr_fmc_presence
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= csr_fmc_presence_i;
      when "0010" => 
        -- Reg csr_ddr_status
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= csr_ddr_status_calib_done_i;
        rd_dat_d0(31 downto 1) <= (others => '0');
      when "0011" => 
        -- Reg csr_pcb_rev
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(3 downto 0) <= csr_pcb_rev_id_i;
        rd_dat_d0(31 downto 4) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
