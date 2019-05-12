library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;

entity output_conversion is
  generic (
    C_BITWIDTH : integer range 8 to 128 := 128
  );
  port (
    isl_clk         : in std_logic;
    isl_valid       : in std_logic;
    ia_data         : in t_state;
    oslv_data       : out std_logic_vector(127 downto 0);
    osl_valid       : out std_logic
  );
end entity output_conversion;

architecture rtl of output_conversion is
  -- TODO: enable bitwidth /= 128, i. e. 8, 16, 32
begin
  osl_valid <= isl_valid;
  gen_rows : for row in 0 to C_STATE_ROWS-1 generate
    gen_cols : for col in 0 to C_STATE_COLS-1 generate
      oslv_data((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8) <= std_logic_vector(ia_data(C_STATE_ROWS-1-row, C_STATE_COLS-1-col));
    end generate;
  end generate;
end architecture rtl;