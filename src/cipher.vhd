-- cipher module, as described in: "FIPS 197, 5.1 Cipher"

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity CIPHER is
  generic (
    C_KEY_WORDS : integer := 4
  );
  port (
    ISL_CLK   : in    std_logic;
    ISL_VALID : in    std_logic;
    IA_DATA   : in    t_state;
    IA_KEY    : in    t_key(0 to C_KEY_WORDS - 1);
    OA_DATA   : out   t_state;
    OSL_VALID : out   std_logic
  );
end entity CIPHER;

architecture RTL of CIPHER is

  -- states
  signal slv_stage     : std_logic_vector(1 to 2) := (others => '0');
  signal sl_valid_out  : std_logic := '0';
  signal sl_last_round : std_logic := '0';
  signal sl_next_round : std_logic := '0';

  -- data container
  -- data format in key expansion: words are rows
  -- data format in cipher: words are columns
  -- conversion: transpose matrix
  signal a_data_in     : t_state;
  signal a_data_added  : t_state;
  signal a_data_srows  : t_state;

  -- keys
  signal a_round_keys  : t_state;
  signal int_round_cnt : integer range 0 to 13 := 0;

begin

  sl_next_round <= slv_stage(2) and not sl_last_round;

  i_key_expansion : entity aes_lib.KEY_EXPANSION
    generic map (
      C_KEY_WORDS   => C_KEY_WORDS
    )
    port map (
      ISL_CLK       => isl_clk,
      ISL_NEXT_KEY  => sl_next_round,
      ISL_VALID     => isl_valid,
      IA_DATA       => ia_key,
      OA_DATA       => a_round_keys
    );

  PROC_KEY_EXPANSION : process (isl_clk) is

    variable v_new_col    : integer range 0 to C_STATE_COLS - 1;
    variable v_data_sbox  : t_state;
    variable v_data_mcols : t_state;

  begin

    if (isl_clk'event and isl_clk = '1') then
      slv_stage <= (isl_valid or sl_next_round) & slv_stage(1);

      -- initial add key
      if (isl_valid = '1') then
        int_round_cnt <= 0;

        a_data_added <= xor_array(transpose(ia_key(0 to 3)), ia_data);
      end if;

      -- substitute bytes and shift rows
      if (slv_stage(1) = '1') then
        for row in 0 to C_STATE_ROWS - 1 loop
          for col in 0 to C_STATE_COLS - 1 loop
            -- substitute bytes
            v_data_sbox(row, col) := C_SBOX(to_integer(a_data_added(row, col)));

            -- shift rows
            -- avoid modulo by using unsigned overflow
            v_new_col := to_integer(to_unsigned(col, 2) - row);
            a_data_srows(row, v_new_col) <= v_data_sbox(row, col);
          end loop;
        end loop;

        -- if the second last round is finished, mix columns step could be skipped,
        -- but like this, the pipeline doesn't branch
        if (int_round_cnt < 6 + C_KEY_WORDS - 1) then
          int_round_cnt <= int_round_cnt + 1;
        else
          sl_last_round <= '1';
        end if;
      end if;

      -- mix columns and add key
      if (slv_stage(2) = '1') then
        for col in 0 to C_STATE_COLS - 1 loop
          v_data_mcols(0, col) := double(a_data_srows(0, col)) xor
                                  triple(a_data_srows(1, col)) xor
                                  a_data_srows(2, col) xor
                                  a_data_srows(3, col);
          v_data_mcols(1, col) := a_data_srows(0, col) xor
                                  double(a_data_srows(1, col)) xor
                                  triple(a_data_srows(2, col)) xor
                                  a_data_srows(3, col);
          v_data_mcols(2, col) := a_data_srows(0, col) xor
                                  a_data_srows(1, col) xor
                                  double(a_data_srows(2, col)) xor
                                  triple(a_data_srows(3, col));
          v_data_mcols(3, col) := triple(a_data_srows(0, col)) xor
                                  a_data_srows(1, col) xor
                                  a_data_srows(2, col) xor
                                  double(a_data_srows(3, col));
        end loop;

        -- add key
        if (sl_last_round = '0') then
          a_data_added <= xor_array(transpose(a_round_keys), v_data_mcols);
        else
          -- final add key
          a_data_added  <= xor_array(transpose(a_round_keys), a_data_srows);
          sl_last_round <= '0';
        end if;
      end if;

      sl_valid_out <= sl_last_round;
    end if;

  end process PROC_KEY_EXPANSION;

  oa_data   <= a_data_added;
  osl_valid <= sl_valid_out;

end architecture RTL;
