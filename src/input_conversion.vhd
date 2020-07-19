
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity input_conversion is
  generic (
    G_BITWIDTH_IF  : integer range 8 to 128   := 128;
    G_BITWIDTH_KEY : integer range 128 to 256 := 128;
    G_BITWIDTH_IV  : integer range 0 to 128   := 128
  );
  port (
    isl_clk        : in    std_logic;
    isl_valid      : in    std_logic;
    islv_data      : in    std_logic_vector(G_BITWIDTH_IF - 1 downto 0);
    isl_new_key_iv : in    std_logic;
    oa_iv          : out   st_state;
    oa_key         : out   t_key(0 to G_BITWIDTH_KEY / 32 - 1);
    oa_data        : out   st_state;
    osl_valid      : out   std_logic
  );
end entity input_conversion;

architecture rtl of input_conversion is

  constant C_KEY_DATUMS    : integer := G_BITWIDTH_KEY / G_BITWIDTH_IF;
  constant C_KEY_IV_DATUMS : integer := C_KEY_DATUMS + G_BITWIDTH_IV / G_BITWIDTH_IF;
  constant C_TOTAL_DATUMS  : integer := C_KEY_IV_DATUMS + 128 / G_BITWIDTH_IF;
  signal   int_input_cnt   : integer range 0 to C_TOTAL_DATUMS := 0;

  signal sl_output_valid : std_logic := '0';

  signal slv_data : std_logic_vector(127 downto 0) := (others => '0');
  signal slv_iv   : std_logic_vector(127 downto 0) := (others => '0');
  signal slv_key  : std_logic_vector(G_BITWIDTH_KEY - 1 downto 0) := (others => '0');

begin

  proc_input_conversion : process (isl_clk) is
  begin

    if (isl_clk'event and isl_clk = '1') then
      if (isl_new_key_iv = '1') then
        int_input_cnt <= 0;
      end if;

      if (isl_valid = '1') then
        int_input_cnt <= int_input_cnt + 1;
        if (int_input_cnt < C_KEY_DATUMS) then
          slv_key <= slv_key(slv_key'HIGH - G_BITWIDTH_IF downto slv_key'LOW) & islv_data;
        elsif (int_input_cnt < C_KEY_IV_DATUMS) then
          slv_iv <= slv_iv(slv_iv'HIGH - G_BITWIDTH_IF downto slv_iv'LOW) & islv_data;
        elsif (int_input_cnt < C_TOTAL_DATUMS) then
          slv_data <= slv_data(slv_data'HIGH - G_BITWIDTH_IF downto slv_data'LOW) & islv_data;
        end if;
      end if;

      if (int_input_cnt < C_TOTAL_DATUMS) then
        sl_output_valid <= '0';
      else
        int_input_cnt   <= C_KEY_IV_DATUMS;
        sl_output_valid <= '1';
      end if;
    end if;

  end process proc_input_conversion;

  oa_data   <= transpose(slv_to_state_array(slv_data));
  oa_key    <= slv_to_key_array(slv_key); -- don't transpose key, since it's needed like this by the key expansion
  oa_iv     <= transpose(slv_to_state_array(slv_iv));
  osl_valid <= sl_output_valid;

end architecture rtl;
