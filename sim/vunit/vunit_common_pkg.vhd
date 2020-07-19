
library ieee;
  use ieee.std_logic_1164.all;

library vunit_lib;
  context vunit_lib.vunit_context;

package VUNIT_COMMON_PKG is

  procedure clk_gen(signal clk : out std_logic; constant PERIOD : time);

  procedure main(
    signal sl_start : out std_logic;
    signal sl_clk : in std_logic;
    signal sl_stimuli_done : in std_logic;
    signal sl_data_check_done : in std_logic;
    signal runner : inout runner_sync_t;
    constant runner_cfg : in string);

  function hex_to_slv (str_hex : string) return std_logic_vector;

end package VUNIT_COMMON_PKG;

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

  procedure main(
    signal sl_start : out std_logic;
    signal sl_clk : in std_logic;
    signal sl_stimuli_done : in std_logic;
    signal sl_data_check_done : in std_logic;
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

  function hex_to_slv (str_hex : string) return std_logic_vector is
    variable v_hex : std_logic_vector(3 downto 0);
    variable v_slv : std_logic_vector(str_hex'LENGTH*4 - 1 downto 0);
  begin
    for i in str_hex'RANGE loop

      case str_hex(str_hex'LENGTH - i+1) is

        when '0' =>
          v_hex := x"0";
        when '1' =>
          v_hex := x"1";
        when '2' =>
          v_hex := x"2";
        when '3' =>
          v_hex := x"3";
        when '4' =>
          v_hex := x"4";
        when '5' =>
          v_hex := x"5";
        when '6' =>
          v_hex := x"6";
        when '7' =>
          v_hex := x"7";
        when '8' =>
          v_hex := x"8";
        when '9' =>
          v_hex := x"9";
        when 'a' =>
          v_hex := x"a";
        when 'A' =>
          v_hex := x"a";
        when 'b' =>
          v_hex := x"b";
        when 'B' =>
          v_hex := x"b";
        when 'c' =>
          v_hex := x"c";
        when 'C' =>
          v_hex := x"c";
        when 'd' =>
          v_hex := x"d";
        when 'D' =>
          v_hex := x"d";
        when 'e' =>
          v_hex := x"e";
        when 'E' =>
          v_hex := x"e";
        when 'f' =>
          v_hex := x"f";
        when 'F' =>
          v_hex := x"f";
        when others =>
          report "hex_to_slv: illegal char" severity ERROR;

      end case;

      v_slv(i * 4 - 1 downto (i - 1) * 4) := v_hex;
    end loop;
    return v_slv;
  end function;

end package body;
