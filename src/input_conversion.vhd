library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity input_conversion is
  generic (
    C_BITWIDTH : integer range 8 to 128 := 128
  );
  port (
    isl_clk         : in std_logic;
    isl_valid       : in std_logic;
    islv_data       : in std_logic_vector(C_BITWIDTH-1 downto 0);
    isl_chain       : in std_logic;
    islv_key        : in std_logic_vector(C_BITWIDTH-1 downto 0);
    islv_iv         : in std_logic_vector(C_BITWIDTH-1 downto 0);
    oa_iv           : out t_state;
    oa_key          : out t_state;
    oa_data         : out t_state;
    osl_valid       : out std_logic
  );
end entity input_conversion;

architecture rtl of input_conversion is
  signal int_row : integer range 0 to C_STATE_ROWS-1 := 0;
  signal int_col : integer range 0 to C_STATE_COLS-1 := 0;
  signal sl_output_valid : std_logic := '0';

  signal slv_data,
         slv_key,
         slv_iv : std_logic_vector(127 downto 0);
begin
  process (isl_clk)
  begin
    if rising_edge(isl_clk) then
      if isl_valid = '1' then
        slv_data <= slv_data(slv_data'HIGH-C_BITWIDTH downto slv_data'LOW) & islv_data;
        if isl_chain = '0' then
          slv_key <= slv_key(slv_key'HIGH-C_BITWIDTH downto slv_key'LOW) & islv_key;
          slv_iv <= slv_iv(slv_iv'HIGH-C_BITWIDTH downto slv_iv'LOW) & islv_iv;
        end if;

        if int_row < C_STATE_ROWS-1 and C_BITWIDTH = 8 then
          int_row <= int_row+1;
        else
          int_row <= 0;
          if int_col < C_STATE_COLS-1 and C_BITWIDTH /= 128 then
            int_col <= int_col+1;
          else
            int_col <= 0;
            sl_output_valid <= '1';
          end if;
        end if;
      end if;

      if sl_output_valid = '1' then
        sl_output_valid <= '0';
      end if;
    end if;
  end process;

  oa_data <= slv_to_array(slv_data);
  oa_key <= slv_to_array(slv_key);
  oa_iv <= slv_to_array(slv_iv);
  osl_valid <= sl_output_valid;
end architecture rtl;