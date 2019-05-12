library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;

entity cipher is
  port (
    isl_clk   : in std_logic;
    isl_valid : in std_logic;
    islv_data : in std_logic_vector(127 downto 0);
    islv_key  : in std_logic_vector(127 downto 0);
    oslv_data : out std_logic_vector(127 downto 0);
    osl_valid : out std_logic
  );
end entity cipher;

architecture rtl of cipher is
  -- states
  signal isl_valid_d1,
         isl_valid_d2,
         isl_valid_d3,
         isl_valid_d4,
         isl_valid_d5,
         isl_valid_d6,
         isl_valid_d7,
         isl_valid_d8,
         isl_valid_d9,
         isl_valid_d10 : std_logic := '0';
  signal sl_valid_out : std_logic := '0';
  signal sl_last_round : std_logic := '0';

  -- data container
  signal a_key_in,
         a_data_mod,
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
    isl_next_key  => isl_valid_d10,
    isl_valid     => isl_valid,
    ia_data       => a_key_in,
    oa_data       => a_round_keys
  );

  -- convert input and output (slv <-> array) and revert the vectors bytewise
  -- TODO: is there a better way for the conversion?
  gen_rows : for row in 0 to C_STATE_ROWS-1 generate
    gen_cols : for col in 0 to C_STATE_COLS-1 generate
      a_data_in(C_STATE_ROWS-1-row, C_STATE_COLS-1-col) <= unsigned(islv_data((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8));
      a_key_in(C_STATE_ROWS-1-row, C_STATE_COLS-1-col) <= unsigned(islv_key((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8));
      oslv_data((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8) <= std_logic_vector(a_data_added(C_STATE_ROWS-1-row, C_STATE_COLS-1-col));
    end generate;
  end generate;

  process(isl_clk)
    variable new_col : integer range 0 to 3 := 0;
  begin
    if rising_edge(isl_clk) then
      -- cipher, as described in: "FIPS 197, 5.1 Cipher"

      -- start new round when new input came or when the last round is finished
      isl_valid_d1 <= isl_valid;
      isl_valid_d2 <= '1' when isl_valid_d1 = '1' or isl_valid_d10 = '1' else '0';
      isl_valid_d3 <= isl_valid_d2;
      isl_valid_d4 <= isl_valid_d3;
      isl_valid_d5 <= isl_valid_d4;
      isl_valid_d6 <= isl_valid_d5;
      isl_valid_d7 <= isl_valid_d6;
      isl_valid_d8 <= isl_valid_d7;
      isl_valid_d9 <= isl_valid_d8;
      isl_valid_d10 <= '1' when isl_valid_d9 = '1' and sl_last_round = '0' else '0';

      -- keep last round and valid signal only high for one cycle
      if sl_last_round = '1' then
        sl_last_round <= '0';
      end if;
      sl_valid_out <= sl_last_round;

      -- input modification
      if isl_valid = '1' then
        int_round_cnt <= 0;
        for row in 0 to C_STATE_ROWS-1 loop
          for col in 0 to C_STATE_COLS-1 loop
            a_data_mod(row, col) <= a_data_in(row, col);
          end loop;
        end loop;
      end if;
      
      -- initial add key
      if isl_valid_d1 = '1' then
        for row in 0 to C_STATE_ROWS-1 loop
          for col in 0 to C_STATE_COLS-1 loop
            a_data_added(row, col) <= a_key_in(row, col) xor a_data_mod(row, col);
          end loop;
        end loop;
      end if;

      -- substitute bytes
      if isl_valid_d7 = '1' then
        for row in 0 to C_STATE_ROWS-1 loop
          for col in 0 to C_STATE_COLS-1 loop
            a_data_sbox(row, col) <= C_SBOX(to_integer(a_data_added(row, col)));
          end loop;
        end loop;
      end if;

      -- shift rows
      if isl_valid_d8 = '1' then
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
      if isl_valid_d9 = '1' then
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

      -- add key
      if isl_valid_d10 = '1' then
        for row in 0 to C_STATE_ROWS-1 loop
          for col in 0 to C_STATE_COLS-1 loop
            a_data_added(row, col) <= a_round_keys(row, col) xor a_data_mcols(row, col);
          end loop;
        end loop;
      end if;

      -- final add key
      if sl_last_round = '1' then
        for row in 0 to C_STATE_ROWS-1 loop
          for col in 0 to C_STATE_COLS-1 loop
            a_data_added(row, col) <= a_round_keys(row, col) xor a_data_srows(row, col);
          end loop;
        end loop;
      end if;
    end if;
  end process;

  osl_valid <= sl_valid_out;
end architecture rtl;
