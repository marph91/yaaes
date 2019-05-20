library ieee;
  use ieee.std_logic_1164.all;

library vunit_lib;
  context vunit_lib.vunit_context;

package vunit_common_pkg is
  procedure clk_gen(signal clk : out std_logic; constant PERIOD : time);

  procedure main(signal sl_start : out std_logic;
                 signal sl_clk,
                        sl_stimuli_done,
                        sl_data_check_done : in std_logic;
                 signal runner : inout runner_sync_t;
                 constant runner_cfg : in string);
end package vunit_common_pkg;

package body vunit_common_pkg is
  -- procedure for clock generation
  procedure clk_gen(signal clk : out std_logic; constant PERIOD : time) is
    constant HIGH_TIME : time := PERIOD / 2;
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;
  begin
    assert (HIGH_TIME /= 0 fs) report "clk: frequency is too high" severity FAILURE;
    loop
      clk <= '1';
      wait for HIGH_TIME;
      clk <= '0';
      wait for LOW_TIME;
    end loop;
  end procedure;

  procedure main(signal sl_start : out std_logic;
                 signal sl_clk,
                        sl_stimuli_done,
                        sl_data_check_done : in std_logic;
                 signal runner : inout runner_sync_t;
                 constant runner_cfg : in string) is
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
  end procedure;
end package body;