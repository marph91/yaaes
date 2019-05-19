library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;
  use work.vunit_common_pkg.all;

library vunit_lib;
  context vunit_lib.vunit_context;

entity tb_output_conversion is
  generic (
    runner_cfg    : string;
    C_BITWIDTH    : integer
  );
end entity tb_output_conversion;

architecture rtl of tb_output_conversion is
  constant C_CLK_PERIOD : time := 10 ns;

  signal sl_clk : std_logic := '0';

  signal sl_valid_in : std_logic := '0';
  signal a_data_in : t_state;
  signal slv_data_out : std_logic_vector(C_BITWIDTH-1 downto 0);
  signal sl_valid_out : std_logic;

  signal a_data_ref : t_state := ((x"00", x"04", x"08", x"0C"),
                                  (x"01", x"05", x"09", x"0D"),
                                  (x"02", x"06", x"0A", x"0E"),
                                  (x"03", x"07", x"0B", x"0F"));

  signal sl_start,
         sl_data_check_done,
         sl_stimuli_done : std_logic := '0';

begin
  dut_output_conversion: entity work.output_conversion
  generic map (
    C_BITWIDTH => C_BITWIDTH
  )
	port map (
    isl_clk => sl_clk,
    isl_valid => sl_valid_in,
    ia_data => a_data_in,
    oslv_data => slv_data_out,
    osl_valid => sl_valid_out
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
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_stimuli_done <= '0';

    sl_valid_in <= '1';
    a_data_in <= a_data_ref;
    wait until rising_edge(sl_clk);
    sl_valid_in <= '0';

    sl_stimuli_done <= '1';
  end process;

  data_check_proc : process
    variable slv_input_byte : std_logic_vector(7 downto 0);
    variable slv_input_byte_ref : std_logic_vector(7 downto 0);
  begin
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_data_check_done <= '0';

    if C_BITWIDTH = 8 then
      for col in 0 to C_STATE_COLS-1 loop
        for row in 0 to C_STATE_ROWS-1 loop
          wait until rising_edge(sl_clk) and sl_valid_out = '1';

          slv_input_byte := slv_data_out(C_BITWIDTH-1 downto 0);
          slv_input_byte_ref := std_logic_vector(a_data_ref(row, col));
          CHECK_EQUAL(slv_input_byte, slv_input_byte_ref);
        end loop;
      end loop;
    else
      wait until rising_edge(sl_clk) and sl_valid_out = '1';

      for col in 0 to C_STATE_COLS-1 loop
        for row in 0 to C_STATE_ROWS-1 loop
          slv_input_byte := slv_data_out((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8);
          slv_input_byte_ref := std_logic_vector(a_data_ref(C_STATE_ROWS-1-row, C_STATE_COLS-1-col));
          CHECK_EQUAL(slv_input_byte, slv_input_byte_ref);
        end loop;
      end loop;
    end if;

    wait until rising_edge(sl_clk);
    CHECK_EQUAL(sl_valid_out, '0');

    report ("Done checking");
    sl_data_check_done <= '1';
  end process;
end architecture rtl;