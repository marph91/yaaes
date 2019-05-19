library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;
  use work.vunit_common_pkg.all;

library vunit_lib;
  context vunit_lib.vunit_context;

entity tb_key_expansion is
  generic (
    runner_cfg    : string;
    C_BITWIDTH    : integer
  );
end entity tb_key_expansion;

architecture rtl of tb_key_expansion is
  constant C_CLK_PERIOD : time := 10 ns;

  signal sl_clk : std_logic := '0';
  signal sl_valid_in,
         sl_next_key : std_logic := '0';
  signal a_key_in : t_state := (others => (others => (others => '0')));
  signal a_key_out : t_state;

  signal a_key_ref : t_state := ((x"d0", x"c9", x"e1", x"b6"),
                                 (x"14", x"ee", x"3f", x"63"),
                                 (x"f9", x"25", x"0c", x"0c"),
                                 (x"a8", x"89", x"c8", x"a6"));

  signal sl_start,
         sl_data_check_done,
         sl_stimuli_done : std_logic := '0';

begin
  dut_key_expansion: entity work.key_exp
	port map (
    isl_clk => sl_clk,
    isl_valid => sl_valid_in,
    isl_next_key => sl_next_key,
    ia_data => a_key_in,
    oa_data => a_key_out
  );
  
  clk_gen(sl_clk, C_CLK_PERIOD);
  
  main : process
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

  stimuli_proc : process
  begin
    sl_stimuli_done <= '0';
    wait until rising_edge(sl_clk);

    a_key_in <= ((x"2b", x"28", x"ab", x"09"),
                 (x"7e", x"ae", x"f7", x"cf"),
                 (x"15", x"d2", x"15", x"4f"),
                 (x"16", x"a6", x"88", x"3c"));
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

    for i in 0 to 8 loop
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