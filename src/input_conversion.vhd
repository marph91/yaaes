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
    islv_data       : in std_logic_vector(C_BITWIDTH-1 downto 0);
    islv_key        : in std_logic_vector(C_BITWIDTH-1 downto 0);
    islv_iv         : in std_logic_vector(C_BITWIDTH-1 downto 0);
    oa_iv           : out t_state;
    oa_key          : out t_state;
    oa_data         : out t_state;
    osl_valid       : out std_logic
  );
end entity input_conversion;

architecture rtl of input_conversion is
  -- TODO: enable bitwidth /= 128, i. e. 8, 16, 32
  -- row first on purpose
  signal int_row : integer range 0 to C_STATE_ROWS-1 := 0;
  signal int_col : integer range 0 to C_STATE_COLS-1 := 0;
  signal sl_output_valid : std_logic := '0';
begin
  gen_8 : if C_BITWIDTH = 8 generate
    process (isl_clk)
    begin
      if rising_edge(isl_clk) then
        if isl_valid = '1' then
          -- TODO: use shift register
          oa_data(int_row, int_col) <= unsigned(islv_data);
          oa_key(int_row, int_col) <= unsigned(islv_key);
          oa_iv(int_row, int_col) <= unsigned(islv_iv);

          if int_row < 3 then
            int_row <= int_row+1;
          else
            int_row <= 0;
            if int_col < 3 then
              int_col <= int_col+1;
            else
              int_col <= 0;
            end if;
          end if;
        end if;

        sl_output_valid <= '1' when (int_col = 3 and int_row = 3) else '0';
      end if;
    end process;

    osl_valid <= sl_output_valid;
  end generate;

  gen_128 : if C_BITWIDTH = 128 generate
    osl_valid <= isl_valid;
    gen_rows : for row in 0 to C_STATE_ROWS-1 generate
      gen_cols : for col in 0 to C_STATE_COLS-1 generate
        oa_data(C_STATE_ROWS-1-row, C_STATE_COLS-1-col) <= unsigned(islv_data((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8));
        oa_key(C_STATE_ROWS-1-row, C_STATE_COLS-1-col) <= unsigned(islv_key((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8));
        oa_iv(C_STATE_ROWS-1-row, C_STATE_COLS-1-col) <= unsigned(islv_iv((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8));
      end generate;
    end generate;
  end generate;
end architecture rtl;