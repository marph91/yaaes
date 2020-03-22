library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity input_conversion is
  generic (
    C_BITWIDTH_IF   : integer range 8 to 128 := 128;
    C_BITWIDTH_KEY  : integer range 8 to 128 := 128
  );
  port (
    isl_clk         : in std_logic;
    isl_valid       : in std_logic;
    islv_data_key   : in std_logic_vector(C_BITWIDTH_IF-1 downto 0);
    isl_chain       : in std_logic;
    islv_iv         : in std_logic_vector(C_BITWIDTH_IF-1 downto 0);
    oa_iv           : out t_state;
    oa_key          : out t_state;
    oa_data         : out t_state;
    osl_valid       : out std_logic
  );
end entity input_conversion;

architecture rtl of input_conversion is
  constant C_KEY_DATUMS : integer := C_BITWIDTH_KEY / C_BITWIDTH_IF;
  constant C_TOTAL_DATUMS : integer := (C_BITWIDTH_KEY + 128) / C_BITWIDTH_IF;
  signal int_input_cnt : integer range 0 to C_TOTAL_DATUMS := 0;

  signal sl_output_valid : std_logic := '0';

  signal slv_data,
         slv_key,
         slv_iv : std_logic_vector(127 downto 0);
begin
  process (isl_clk)
  begin
    if rising_edge(isl_clk) then
      sl_output_valid <= '0';

      if isl_valid = '1' then
        int_input_cnt <= int_input_cnt + 1;
        if int_input_cnt < C_KEY_DATUMS then
          slv_key <= slv_key(slv_key'HIGH-C_BITWIDTH_IF downto slv_key'LOW) & islv_data_key;
        elsif int_input_cnt < C_TOTAL_DATUMS then
          slv_data <= slv_data(slv_data'HIGH-C_BITWIDTH_IF downto slv_data'LOW) & islv_data_key;
          slv_iv <= slv_iv(slv_iv'HIGH-C_BITWIDTH_IF downto slv_iv'LOW) & islv_iv;
        end if;
      end if;

      if int_input_cnt < C_TOTAL_DATUMS then
        sl_output_valid <= '0';
      else
        int_input_cnt <= C_KEY_DATUMS;
        sl_output_valid <= '1';
      end if;
    end if;
  end process;

  oa_data <= transpose(slv_to_array(slv_data));
  oa_key <= slv_to_array(slv_key); -- don't transpose key, since it's needed like this by the key expansion
  oa_iv <= transpose(slv_to_array(slv_iv));
  osl_valid <= sl_output_valid;
end architecture rtl;