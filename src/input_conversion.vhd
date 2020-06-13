
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity INPUT_CONVERSION is
  generic (
    C_BITWIDTH_IF   : integer range 8 to 128   := 128;
    C_BITWIDTH_KEY  : integer range 128 to 256 := 128;
    C_BITWIDTH_IV   : integer range 0 to 128   := 128
  );
  port (
    ISL_CLK         : in    std_logic;
    ISL_VALID       : in    std_logic;
    ISLV_DATA       : in    std_logic_vector(C_BITWIDTH_IF - 1 downto 0);
    ISL_NEW_KEY_IV  : in    std_logic;
    OA_IV           : out   t_state;
    OA_KEY          : out   t_key(0 to C_BITWIDTH_KEY / 32 - 1);
    OA_DATA         : out   t_state;
    OSL_VALID       : out   std_logic
  );
end entity INPUT_CONVERSION;

architecture RTL of INPUT_CONVERSION is

  constant c_key_datums    : integer := C_BITWIDTH_KEY / C_BITWIDTH_IF;
  constant c_key_iv_datums : integer := c_key_datums + C_BITWIDTH_IV / C_BITWIDTH_IF;
  constant c_total_datums  : integer := c_key_iv_datums + 128 / C_BITWIDTH_IF;
  signal int_input_cnt            : integer range 0 to c_total_datums := 0;

  signal sl_output_valid          : std_logic := '0';

  signal slv_data,         slv_iv : std_logic_vector(127 downto 0) := (others => '0');
  signal slv_key                  : std_logic_vector(C_BITWIDTH_KEY - 1 downto 0) := (others => '0');

begin

  PROC_INPUT_CONVERSION : process (isl_clk) is
  begin

    if (isl_clk'event and isl_clk = '1') then
      if (isl_new_key_iv = '1') then
        int_input_cnt <= 0;
      end if;

      if (isl_valid = '1') then
        int_input_cnt <= int_input_cnt + 1;
        if (int_input_cnt < c_key_datums) then
          slv_key <= slv_key(slv_key'HIGH - C_BITWIDTH_IF downto slv_key'LOW) & islv_data;
        elsif (int_input_cnt < c_key_iv_datums) then
          slv_iv <= slv_iv(slv_iv'HIGH - C_BITWIDTH_IF downto slv_iv'LOW) & islv_data;
        elsif (int_input_cnt < c_total_datums) then
          slv_data <= slv_data(slv_data'HIGH - C_BITWIDTH_IF downto slv_data'LOW) & islv_data;
        end if;
      end if;

      if (int_input_cnt < c_total_datums) then
        sl_output_valid <= '0';
      else
        int_input_cnt   <= c_key_iv_datums;
        sl_output_valid <= '1';
      end if;
    end if;

  end process PROC_INPUT_CONVERSION;

  oa_data   <= transpose(slv_to_state_array(slv_data));
  oa_key    <= slv_to_key_array(slv_key); -- don't transpose key, since it's needed like this by the key expansion
  oa_iv     <= transpose(slv_to_state_array(slv_iv));
  osl_valid <= sl_output_valid;

end architecture RTL;
