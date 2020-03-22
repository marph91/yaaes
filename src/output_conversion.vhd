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
  constant C_TOTAL_DATUMS : integer := 128 / C_BITWIDTH;
  signal int_output_cnt : integer range 0 to C_TOTAL_DATUMS := 0;

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
        slv_data <= array_to_slv(transpose(ia_data));
      end if;

      if sl_output_valid = '1' then
        if int_output_cnt < C_TOTAL_DATUMS - 1 then
          int_output_cnt <= int_output_cnt + 1;
        else
          sl_output_valid <= '0';
          int_output_cnt <= 0;
        end if;
        
        oslv_data <= slv_data(slv_data'HIGH downto slv_data'HIGH-C_BITWIDTH+1);
        slv_data <= slv_data(slv_data'HIGH-C_BITWIDTH downto slv_data'LOW) &
                    slv_data(slv_data'HIGH downto slv_data'HIGH-C_BITWIDTH+1);
      end if;
    end if;
  end process;

  osl_valid <= sl_output_valid_d1;
end architecture rtl;