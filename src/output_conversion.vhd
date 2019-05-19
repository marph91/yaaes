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
    oslv_data       : out std_logic_vector(C_BITWIDTH-1 downto 0);
    osl_valid       : out std_logic
  );
end entity output_conversion;

architecture rtl of output_conversion is
  -- TODO: enable bitwidth /= 128, i. e. 8, 16, 32
  signal int_row : integer range 0 to 3 := 0;
  signal int_col : integer range 0 to 3 := 0;
  signal sl_output_valid,
         sl_output_valid_d1 : std_logic := '0';
begin
  gen_8 : if C_BITWIDTH = 8 generate
    process (isl_clk)
    begin
      if rising_edge(isl_clk) then
        sl_output_valid_d1 <= sl_output_valid;

        if isl_valid = '1' then
          sl_output_valid <= '1';
        end if;
        
        if sl_output_valid = '1' then
          oslv_data <= std_logic_vector(ia_data(int_row, int_col));

          if int_row < 3 then
            int_row <= int_row+1;
          else
            int_row <= 0;
            if int_col < 3 then
              int_col <= int_col+1;
            else
              int_col <= 0;
              sl_output_valid <= '0';
            end if;
          end if;
        end if;
      end if;
    end process;

    osl_valid <= sl_output_valid_d1;
  end generate;

  gen_128 : if C_BITWIDTH = 128 generate
    osl_valid <= isl_valid;
    gen_rows : for row in 0 to C_STATE_ROWS-1 generate
      gen_cols : for col in 0 to C_STATE_COLS-1 generate
        oslv_data((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8) <= std_logic_vector(ia_data(C_STATE_ROWS-1-row, C_STATE_COLS-1-col));
      end generate;
    end generate;
  end generate;
end architecture rtl;