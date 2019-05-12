library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;

entity key_exp is
  port (
    isl_clk       : in std_logic;
    isl_next_key  : in std_logic;
    isl_valid     : in std_logic;
    ia_data       : in t_state; -- initial key
    oa_data       : out t_state -- key expansion for next timestep
  );
end entity key_exp;

architecture rtl of key_exp is
  signal slv_stage : std_logic_vector(1 to 7) := (others => '0');
  signal a_sub_word,
         a_rot_word,
         a_rcon_word,
         a_rcon : t_word := (others => (others => '0'));
  signal a_data_out : t_state := (others => (others => (others => '0')));
begin
  process(isl_clk)
  begin
    if rising_edge(isl_clk) then
      -- key expansion, as described in: "FIPS 197, 5.2 Key Expansion"

      slv_stage <= (isl_valid or isl_next_key) & slv_stage(slv_stage'LOW to slv_stage'HIGH-1);

      -- first key is the input
      if isl_valid = '1' then
        a_rcon(0) <= x"01";
        a_data_out <= ia_data;
      end if;

      -- rotate
      if slv_stage(1) = '1' then
        for row in a_rot_word'RANGE loop
          a_rot_word((row-1) mod 4) <= a_data_out(row, 3);
        end loop;
      end if;

      -- substitute
      if slv_stage(2) = '1' then
        for col in a_rot_word'RANGE loop
          a_sub_word(col) <= C_SBOX(to_integer(a_rot_word(col)));
        end loop;
      end if;

      -- xor rcon
      if slv_stage(3) = '1' then
        for col in a_sub_word'RANGE loop
          a_rcon_word(col) <= a_sub_word(col) xor a_rcon(col);
        end loop;

        -- calculate round constant, as defined in: "FIPS 197, 5.2 Key Expansion"
        a_rcon(0) <= double(a_rcon(0));
      end if;

      -- xor last word
      if slv_stage(4) = '1' then
        for row in a_rot_word'RANGE loop
          a_data_out(row, 0) <= a_data_out(row, 0) xor a_rcon_word(row);
        end loop;
      end if;

      -- assign the following three words -> no sub, rot, ... needed
      if slv_stage(5) = '1' then
        for row in a_rot_word'RANGE loop
          a_data_out(row, 1) <= a_data_out(row, 0) xor a_data_out(row, 1);
        end loop;
      end if;

      if slv_stage(6) = '1' then
        for row in a_rot_word'RANGE loop
          a_data_out(row, 2) <= a_data_out(row, 1) xor a_data_out(row, 2);
        end loop;
      end if;

      if slv_stage(7) = '1' then
        for row in a_rot_word'RANGE loop
          a_data_out(row, 3) <= a_data_out(row, 2) xor a_data_out(row, 3);
        end loop;
      end if;
    end if;
  end process;

  oa_data <= a_data_out;
end architecture rtl;
