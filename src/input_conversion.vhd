library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;

entity input_conversion is
  generic (
    C_BITWIDTH : integer range 8 to 128 := 128
  );
  port (
    isl_clk         : in std_logic;
    isl_valid       : in std_logic;
    islv_data       : in std_logic_vector(127 downto 0);
    islv_key        : in std_logic_vector(127 downto 0);
    oa_key          : out t_state;
    oa_data         : out t_state;
    osl_valid       : out std_logic
  );
end entity input_conversion;

architecture rtl of input_conversion is
  -- TODO: enable bitwidth /= 128, i. e. 8, 16, 32
begin
  osl_valid <= isl_valid;
  gen_rows : for row in 0 to C_STATE_ROWS-1 generate
    gen_cols : for col in 0 to C_STATE_COLS-1 generate
      oa_data(C_STATE_ROWS-1-row, C_STATE_COLS-1-col) <= unsigned(islv_data((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8));
      oa_key(C_STATE_ROWS-1-row, C_STATE_COLS-1-col) <= unsigned(islv_key((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8));
    end generate;
  end generate;
end architecture rtl;