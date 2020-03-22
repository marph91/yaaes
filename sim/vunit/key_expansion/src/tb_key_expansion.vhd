-- test whether the key expansion module works correctly
-- input data -> key expansion -> output data
-- output data == reference vectors?

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;
  use aes_lib.vunit_common_pkg.all;

library vunit_lib;
  context vunit_lib.vunit_context;

entity tb_key_expansion is
  generic (
    runner_cfg    : string;
    C_BITWIDTH    : integer;

    C_KEY_WORDS   : integer
  );
end entity tb_key_expansion;

architecture rtl of tb_key_expansion is
  constant C_CLK_PERIOD : time := 10 ns;

  signal sl_clk : std_logic := '0';
  signal sl_valid_in,
         sl_next_key : std_logic := '0';

  signal a_key_in : t_key(0 to C_KEY_WORDS-1);
  signal a_key_ref : t_state;
  signal a_key_out : t_state;

  signal sl_start,
         sl_data_check_done,
         sl_stimuli_done : std_logic := '0';

begin
  dut_key_expansion: entity aes_lib.key_expansion
  generic map(
    C_KEY_WORDS => C_KEY_WORDS
  )
	port map (
    isl_clk => sl_clk,
    isl_valid => sl_valid_in,
    isl_next_key => sl_next_key,
    ia_data => a_key_in,
    oa_data => a_key_out
  );

  clk_gen(sl_clk, C_CLK_PERIOD);

  proc_main: process
    procedure run_test is
    begin
      wait until rising_edge(sl_clk);
      sl_start <= '1';
      wait until rising_edge(sl_clk);
      sl_start <= '0';
      wait until rising_edge(sl_clk);

      wait until rising_edge(sl_clk) and
                 sl_stimuli_done = '1' and
                 sl_data_check_done = '1';
    end procedure;

  begin
    test_runner_setup(runner, runner_cfg);
    run_test;
    test_runner_cleanup(runner);
    wait;
  end process;

  proc_assign_data: if C_KEY_WORDS = 4 generate
    a_key_in <= ((x"2b", x"7e", x"15", x"16"),
                 (x"28", x"ae", x"d2", x"a6"),
                 (x"ab", x"f7", x"15", x"88"),
                 (x"09", x"cf", x"4f", x"3c"));
    a_key_ref <= ((x"d0", x"14", x"f9", x"a8"),
                  (x"c9", x"ee", x"25", x"89"),
                  (x"e1", x"3f", x"0c", x"c8"),
                  (x"b6", x"63", x"0c", x"a6"));
  else generate
    a_key_in <= ((x"60", x"3d", x"eb", x"10"),
                 (x"15", x"ca", x"71", x"be"),
                 (x"2b", x"73", x"ae", x"f0"),
                 (x"85", x"7d", x"77", x"81"),
                 (x"1f", x"35", x"2c", x"07"),
                 (x"3b", x"61", x"08", x"d7"),
                 (x"2d", x"98", x"10", x"a3"),
                 (x"09", x"14", x"df", x"f4"));
    a_key_ref <= ((x"fe", x"48", x"90", x"d1"),
                  (x"e6", x"18", x"8d", x"0b"),
                  (x"04", x"6d", x"f3", x"44"),
                  (x"70", x"6c", x"63", x"1e"));
  end generate;
  
  stimuli_proc : process
  begin
    sl_stimuli_done <= '0';
    wait until rising_edge(sl_clk);

    sl_valid_in <= '1';
    wait until rising_edge(sl_clk);

    sl_valid_in <= '0';
    sl_stimuli_done <= '1';
    wait;
  end process;

  data_check_proc : process
  begin
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_data_check_done <= '0';

    -- TODO: make the key expansion more robust against a wrong next key impulse
    for j in 0 to 3 loop
      wait until rising_edge(sl_clk);
    end loop;

    -- AES-128: 10 rounds -> i. e. "isl_valid" + 9 times "sl_next_key"
    -- AES-192: 12 rounds
    -- AES-256: 14 rounds
    for i in 0 to 6+C_KEY_WORDS-2 loop
      wait until rising_edge(sl_clk);
      sl_next_key <= '1';
      wait until rising_edge(sl_clk);
      sl_next_key <= '0';

      for j in 0 to 7 loop
        wait until rising_edge(sl_clk);
      end loop;
    end loop;

    for col in 0 to C_STATE_COLS-1 loop
      for row in 0 to C_STATE_ROWS-1 loop
        CHECK_EQUAL(a_key_out(col, row), a_key_ref(col, row));
      end loop;
    end loop;

    report ("Done checking");
    sl_data_check_done <= '1';
    wait;
  end process;
end architecture rtl;