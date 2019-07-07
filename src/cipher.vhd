-- cipher module, as described in: "FIPS 197, 5.1 Cipher"

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;

entity cipher is
  port (
    isl_clk   : in std_logic;
    isl_valid : in std_logic;
    ia_data : in t_state;
    ia_key  : in t_state;
    oa_data : out t_state;
    osl_valid : out std_logic
  );
end entity cipher;

architecture rtl of cipher is
  -- states
  signal slv_stage : std_logic_vector(1 to 9) := (others => '0');
  signal sl_valid_out : std_logic := '0';
  signal sl_last_round : std_logic := '0';

  -- data container
  signal a_key_in,
         a_data_in,
         a_data_added,
         a_data_sbox,
         a_data_srows,
         a_data_mcols : t_state := (others => (others => (others => '0')));

  -- keys
  signal a_round_keys : t_state;
  signal int_round_cnt : integer range 0 to 13 := 0;
begin
  i_key_exp : entity work.key_exp
  port map(
    isl_clk       => isl_clk,
    isl_next_key  => slv_stage(9),
    isl_valid     => isl_valid,
    ia_data       => ia_key,
    oa_data       => a_round_keys
  );

  process(isl_clk)
    variable new_col : integer range 0 to 3 := 0;
  begin
    if rising_edge(isl_clk) then
      -- start new round when new input came or when the last round is finished
      slv_stage(1) <= isl_valid or slv_stage(9);
      slv_stage(2 to 8) <= slv_stage(1 to 7);
      slv_stage(9) <= slv_stage(8) and not sl_last_round;

      -- keep last round and valid signal only high for one cycle
      if sl_last_round = '1' then
        sl_last_round <= '0';
      end if;
      sl_valid_out <= sl_last_round;

      -- initial add key
      if isl_valid = '1' then
        int_round_cnt <= 0;

        a_data_added <= xor_array(ia_key, ia_data);
      end if;

      -- substitute bytes
      if slv_stage(6) = '1' then
        for row in 0 to C_STATE_ROWS-1 loop
          for col in 0 to C_STATE_COLS-1 loop
            a_data_sbox(row, col) <= C_SBOX(to_integer(a_data_added(row, col)));
          end loop;
        end loop;
      end if;

      -- shift rows
      if slv_stage(7) = '1' then
        for row in 0 to C_STATE_ROWS-1 loop
          for col in 0 to C_STATE_COLS-1 loop
            new_col := (col - row) mod C_STATE_COLS;
            a_data_srows(row, new_col) <= a_data_sbox(row, col);
          end loop;
        end loop;

        -- if round 9 is finished, skip the mix columns step
        if int_round_cnt < 9 then
          int_round_cnt <= int_round_cnt + 1;
        else
          sl_last_round <= '1';
        end if;
      end if;

      -- mix columns
      if slv_stage(8) = '1' then
        for col in 0 to C_STATE_COLS-1 loop
          a_data_mcols(0, col) <= double(a_data_srows(0, col)) xor
                                  triple(a_data_srows(1, col)) xor
                                  a_data_srows(2, col) xor
                                  a_data_srows(3, col);
          a_data_mcols(1, col) <= a_data_srows(0, col) xor
                                  double(a_data_srows(1, col)) xor
                                  triple(a_data_srows(2, col)) xor
                                  a_data_srows(3, col);
          a_data_mcols(2, col) <= a_data_srows(0, col) xor
                                  a_data_srows(1, col) xor
                                  double(a_data_srows(2, col)) xor
                                  triple(a_data_srows(3, col));
          a_data_mcols(3, col) <= triple(a_data_srows(0, col)) xor
                                  a_data_srows(1, col) xor
                                  a_data_srows(2, col) xor
                                  double(a_data_srows(3, col));
        end loop;
      end if;

      -- TODO: merge the following two steps
      -- add key
      if slv_stage(9) = '1' then
        a_data_added <= xor_array(a_round_keys, a_data_mcols);
      end if;

      -- final add key
      if sl_last_round = '1' then
        a_data_added <= xor_array(a_round_keys, a_data_srows);
      end if;
    end if;
  end process;

  oa_data <= a_data_added;
  osl_valid <= sl_valid_out;
end architecture rtl;
