-- key expansion module, as described in: "FIPS 197, 5.2 Key Expansion"

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity key_expansion is
  port (
    isl_clk       : in std_logic;
    isl_next_key  : in std_logic;
    isl_valid     : in std_logic;
    ia_data       : in t_state;
    oa_data       : out t_state
  );
end entity key_expansion;

architecture rtl of key_expansion is
  signal sl_process : std_logic := '0';
  signal a_rcon : t_word := (others => (others => '0'));
  signal a_data_out : t_state := (others => (others => (others => '0')));
begin
  process(isl_clk)
    variable v_data_out : t_state;
    variable v_rot_word,
             v_sub_word,
             v_rcon_word : t_word;
    variable v_new_row : integer range 0 to C_STATE_ROWS-1;
  begin
    if rising_edge(isl_clk) then
      sl_process <= isl_valid or isl_next_key;

      -- first key is the input
      if isl_valid = '1' then
        a_rcon(0) <= x"01";
        a_data_out <= ia_data;
      end if;

      -- process all the steps
      if sl_process = '1' then
        -- rotate
        for row in ia_data'RANGE loop
          -- avoid modulo by using unsigned overflow
          v_new_row := to_integer(to_unsigned(row, 2) - 1);
          v_rot_word(v_new_row) := a_data_out(row, C_STATE_COLS-1);
        end loop;

        -- substitute
        for col in ia_data'RANGE loop
          v_sub_word(col) := C_SBOX(to_integer(v_rot_word(col)));
        end loop;

        -- xor rcon
        for col in ia_data'RANGE loop
          v_rcon_word(col) := v_sub_word(col) xor a_rcon(col);
        end loop;

        -- calculate round constant for the next round, as defined in: "FIPS 197, 5.2 Key Expansion"
        a_rcon(0) <= double(a_rcon(0));

        -- xor last word
        for row in ia_data'RANGE loop
          v_data_out(row, 0) := a_data_out(row, 0) xor v_rcon_word(row);
          -- assign the following three words -> no sub, rot, ... needed
          v_data_out(row, 1) := v_data_out(row, 0) xor a_data_out(row, 1);
          v_data_out(row, 2) := v_data_out(row, 1) xor a_data_out(row, 2);
          v_data_out(row, 3) := v_data_out(row, 2) xor a_data_out(row, 3);

          a_data_out <= v_data_out;
        end loop;
      end if;
    end if;
  end process;

  oa_data <= a_data_out;
end architecture rtl;
