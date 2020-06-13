-- test whether the output conversion module works correctly
-- input data -> output conversion -> output data
-- output data == reference data?

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity OUTPUT_CONVERSION is
  generic (
    C_BITWIDTH : integer range 8 to 128 := 128
  );
  port (
    ISL_CLK         : in    std_logic;
    ISL_VALID       : in    std_logic;
    IA_DATA         : in    t_state;
    OSLV_DATA       : out   std_logic_vector(C_BITWIDTH - 1 downto 0);
    OSL_VALID       : out   std_logic
  );
end entity OUTPUT_CONVERSION;

architecture RTL of OUTPUT_CONVERSION is

  constant c_total_datums : integer := 128 / C_BITWIDTH;
  signal int_output_cnt     : integer range 0 to c_total_datums := 0;

  signal sl_output_valid    : std_logic := '0';
  signal sl_output_valid_d1 : std_logic := '0';

  signal slv_data           : std_logic_vector(127 downto 0);

begin

  PROC_OUTPUT_CONVERSION : process (isl_clk) is
  begin

    if (isl_clk'event and isl_clk = '1') then
      sl_output_valid_d1 <= sl_output_valid;

      if (isl_valid = '1') then
        sl_output_valid <= '1';
        slv_data        <= array_to_slv(transpose(ia_data));
      end if;

      if (sl_output_valid = '1') then
        if (int_output_cnt < c_total_datums - 1) then
          int_output_cnt <= int_output_cnt + 1;
        else
          sl_output_valid <= '0';
          int_output_cnt  <= 0;
        end if;

        oslv_data <= slv_data(slv_data'HIGH downto slv_data'HIGH - C_BITWIDTH + 1);
        slv_data  <= slv_data(slv_data'HIGH - C_BITWIDTH downto slv_data'LOW) &
                     slv_data(slv_data'HIGH downto slv_data'HIGH - C_BITWIDTH + 1);
      end if;
    end if;

  end process PROC_OUTPUT_CONVERSION;

  osl_valid <= sl_output_valid_d1;

end architecture RTL;
