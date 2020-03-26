-- key expansion module, as described in: "FIPS 197, 5.2 Key Expansion"

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity key_expansion is
  generic (
    C_KEY_WORDS    : integer := 4
  );
  port (
    isl_clk       : in std_logic;
    isl_next_key  : in std_logic;
    isl_valid     : in std_logic;
    ia_data       : in t_key(0 to C_KEY_WORDS-1);
    oa_data       : out t_state
  );
end entity key_expansion;

architecture rtl of key_expansion is
  signal sl_process : std_logic := '0';
  signal a_rcon : t_word := (others => (others => '0'));
  signal a_data_out : t_key(0 to C_KEY_WORDS-1) := (others => (others => (others => '0')));

  signal sl_short_round : std_logic := '0';
begin
  process(isl_clk)
    variable v_data_out : t_key(0 to C_KEY_WORDS-1);
    variable v_rot_word,
             v_sub_word,
             v_rcon_word : t_word;
    variable v_new_col : integer range 0 to C_STATE_COLS-1;
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
        sl_short_round <= not sl_short_round;
        if sl_short_round = '1' and C_KEY_WORDS = 8 then
          -- execute the short key expansion routine
          -- TODO: replace duplicated code

          -- substitute
          for col in 0 to 3 loop
            v_sub_word(col) := C_SBOX(to_integer(a_data_out(C_KEY_WORDS-1)(col)));
          end loop;

          -- xor last word
          -- oldest word is v_data_out(0), new words get appended
          v_data_out(0 to 3) := a_data_out(C_KEY_WORDS-4 to C_KEY_WORDS-1);
          for col in 0 to 3 loop
            v_data_out(0+C_KEY_WORDS-4)(col) := v_sub_word(col) xor a_data_out(0)(col);
            -- assign the following three words -> no sub, rot, ... needed
            v_data_out(1+C_KEY_WORDS-4)(col) := v_data_out(0+C_KEY_WORDS-4)(col) xor a_data_out(1)(col);
            v_data_out(2+C_KEY_WORDS-4)(col) := v_data_out(1+C_KEY_WORDS-4)(col) xor a_data_out(2)(col);
            v_data_out(3+C_KEY_WORDS-4)(col) := v_data_out(2+C_KEY_WORDS-4)(col) xor a_data_out(3)(col);

            a_data_out <= v_data_out;
          end loop;

        else
          -- execute the full key expansion routine

          -- rotate
          for col in 0 to C_STATE_COLS-1 loop
            -- avoid modulo by using unsigned overflow
            v_new_col := to_integer(to_unsigned(col, 2) - 1);
            v_rot_word(v_new_col) := a_data_out(C_KEY_WORDS-1)(col);
          end loop;

          -- substitute
          for col in 0 to 3 loop
            v_sub_word(col) := C_SBOX(to_integer(v_rot_word(col)));
          end loop;

          -- xor rcon
          for col in 0 to 3 loop
            v_rcon_word(col) := v_sub_word(col) xor a_rcon(col);
          end loop;

          -- calculate round constant for the next round, as defined in: "FIPS 197, 5.2 Key Expansion"
          a_rcon(0) <= double(a_rcon(0));

          -- xor last word
          -- oldest word is v_data_out(0), new words get appended
          v_data_out(0 to 3) := a_data_out(C_KEY_WORDS-4 to C_KEY_WORDS-1);
          for col in 0 to 3 loop
            v_data_out(0+C_KEY_WORDS-4)(col) := v_rcon_word(col) xor a_data_out(0)(col);
            -- assign the following three words -> no sub, rot, ... needed
            v_data_out(1+C_KEY_WORDS-4)(col) := v_data_out(0+C_KEY_WORDS-4)(col) xor a_data_out(1)(col);
            v_data_out(2+C_KEY_WORDS-4)(col) := v_data_out(1+C_KEY_WORDS-4)(col) xor a_data_out(2)(col);
            v_data_out(3+C_KEY_WORDS-4)(col) := v_data_out(2+C_KEY_WORDS-4)(col) xor a_data_out(3)(col);

            a_data_out <= v_data_out;
          end loop;
        end if;
      end if;
    end if;
  end process;

  oa_data <= type_key_to_state(a_data_out(0 to 3));
end architecture rtl;
