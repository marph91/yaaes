library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_cipher is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_cipher is
begin
  main : process
    variable output_mix_columns : st_state;
    variable test_vector : st_state;
    variable reference_vector : st_state;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      if run("multiply_example_vectors") then
        -- example vectors from FIPS 197,  4.2.1 Multiplication by x
        -- TODO: figure out when to use x"" and 16##
        CHECK_EQUAL(multiply_polynomial(x"57", x"02"), 16#ae#);
        CHECK_EQUAL(multiply_polynomial(x"57", x"04"), 16#47#);
        CHECK_EQUAL(multiply_polynomial(x"57", x"08"), 16#8e#);
        CHECK_EQUAL(multiply_polynomial(x"57", x"10"), 16#07#);
        CHECK_EQUAL(multiply_polynomial(x"57", x"13"), 16#fe#);
        CHECK_EQUAL(x"57" xor
                    multiply_polynomial(x"57", x"02") xor
                    multiply_polynomial(x"57", x"10"), 16#fe#);

      elsif run("mix_column_example_vectors") then
        -- test vectors taken from https://en.wikipedia.org/wiki/Rijndael_MixColumns
        test_vector := (
          (x"db", x"f2", x"01", x"c6"),
          (x"13", x"0a", x"01", x"c6"),
          (x"53", x"22", x"01", x"c6"),
          (x"45", x"5c", x"01", x"c6")
        );
        reference_vector := (
          (x"8e", x"9f", x"01", x"c6"),
          (x"4d", x"dc", x"01", x"c6"),
          (x"a1", x"58", x"01", x"c6"),
          (x"bc", x"9d", x"01", x"c6")
        );

        -- compare with reference vector
        output_mix_columns := mix_columns(test_vector);
        for row in 0 to C_STATE_ROWS - 1 loop
          for col in 0 to C_STATE_COLS - 1 loop
            CHECK_EQUAL(output_mix_columns(row, col), reference_vector(row, col),
                        "row: " & to_string(row) & " col: " & to_string(col));
          end loop;
        end loop;

        -- check if the inverse operation works
        output_mix_columns := inv_mix_columns(output_mix_columns);
        for row in 0 to C_STATE_ROWS - 1 loop
          for col in 0 to C_STATE_COLS - 1 loop
            CHECK_EQUAL(output_mix_columns(row, col), test_vector(row, col),
                        "row: " & to_string(row) & " col: " & to_string(col));
          end loop;
        end loop;

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;
end architecture;