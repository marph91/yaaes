-- test whether the output conversion module works correctly
-- input data -> output conversion -> output data
-- output data == reference data?

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

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
  signal int_row : integer range 0 to C_STATE_ROWS-1 := 0;
  signal int_col : integer range 0 to C_STATE_COLS-1 := 0;
  signal sl_output_valid,
         sl_output_valid_d1 : std_logic := '0';

  signal slv_data : std_logic_vector(127 downto 0);
begin
  process (isl_clk)
  begin
    if rising_edge(isl_clk) then
      sl_output_valid_d1 <= sl_output_valid;

      if isl_valid = '1' then
        sl_output_valid <= '1';
        slv_data <= array_to_slv(ia_data);
      end if;
      
      if sl_output_valid = '1' then
        oslv_data <= slv_data(slv_data'HIGH downto slv_data'HIGH-C_BITWIDTH+1);
        slv_data <= slv_data(slv_data'HIGH-C_BITWIDTH downto slv_data'LOW) &
                    slv_data(slv_data'HIGH downto slv_data'HIGH-C_BITWIDTH+1);

        -- TODO: use rows/cols per input instead of C_BITWIDTH
        if int_row < C_STATE_ROWS-1 and C_BITWIDTH = 8 then
          int_row <= int_row+1;
        else
          int_row <= 0;
          if int_col < C_STATE_COLS-1 and C_BITWIDTH /= 128 then
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
end architecture rtl;