-- test whether the input conversion module works correctly
-- input data -> input conversion -> output data
-- output data == reference data?

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

library test_lib;
  use test_lib.vunit_common_pkg.all;

library vunit_lib;
  context vunit_lib.vunit_context;

entity tb_input_conversion is
  generic (
    runner_cfg     : string;
    C_BITWIDTH_IF  : integer;
    C_BITWIDTH_KEY : integer;
    C_BITWIDTH_IV  : integer
  );
end entity tb_input_conversion;

architecture rtl of tb_input_conversion is
  constant C_CLK_PERIOD : time := 10 ns;

  signal sl_clk : std_logic := '0';

  signal slv_data_in : std_logic_vector(C_BITWIDTH_IF-1 downto 0);
  signal a_iv_out,
         a_data_out : t_state;
  signal a_key_out : t_key(0 to C_BITWIDTH_KEY/32-1);
  signal sl_valid_in,
         sl_valid_out : std_logic;
  signal sl_new_key_iv : std_logic := '0';

  signal a_data_ref : t_state := ((x"00", x"04", x"08", x"0C"),
                                  (x"01", x"05", x"09", x"0D"),
                                  (x"02", x"06", x"0A", x"0E"),
                                  (x"03", x"07", x"0B", x"0F"));
  signal a_data_ref2 : t_state := ((x"FF", x"EF", x"DF", x"CF"),
                                   (x"BF", x"AF", x"9F", x"8F"),
                                   (x"7F", x"6F", x"5F", x"4F"),
                                   (x"3F", x"2F", x"1F", x"0F"));
  signal slv_data_ref : std_logic_vector(127 downto 0);

  signal sl_start,
         sl_data_check_done,
         sl_stimuli_done : std_logic := '0';

begin
  dut_input_conversion: entity aes_lib.input_conversion
  generic map (
    C_BITWIDTH_IF  => C_BITWIDTH_IF,
    C_BITWIDTH_KEY => C_BITWIDTH_KEY,
    C_BITWIDTH_IV  => C_BITWIDTH_IV
  )
	port map (
    isl_clk       => sl_clk,
    isl_valid     => sl_valid_in,
    islv_data     => slv_data_in,
    isl_new_key_iv=> sl_new_key_iv,
    oa_iv         => a_iv_out,
    oa_key        => a_key_out,
    oa_data       => a_data_out,
    osl_valid     => sl_valid_out
  );
  
  clk_gen(sl_clk, C_CLK_PERIOD);
  main(sl_start, sl_clk, sl_stimuli_done, sl_data_check_done, runner, runner_cfg);

  stimuli_proc : process
  begin
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_stimuli_done <= '0';

    slv_data_ref <= array_to_slv(a_data_ref);
    wait until rising_edge(sl_clk);
    sl_valid_in <= '1';

    -- key
    for i in 0 to C_BITWIDTH_KEY / C_BITWIDTH_IF - 1 loop
      slv_data_in <= slv_data_ref(slv_data_ref'HIGH downto slv_data_ref'HIGH-C_BITWIDTH_IF+1);

      slv_data_ref <= slv_data_ref(slv_data_ref'HIGH-C_BITWIDTH_IF downto slv_data_ref'LOW)
                      & slv_data_ref(slv_data_ref'HIGH downto slv_data_ref'HIGH-C_BITWIDTH_IF+1);
      wait until rising_edge(sl_clk);
    end loop;

    -- initialization vector (iv)
    for i in 0 to C_BITWIDTH_IV / C_BITWIDTH_IF - 1 loop
      slv_data_in <= slv_data_ref(slv_data_ref'HIGH downto slv_data_ref'HIGH-C_BITWIDTH_IF+1);

      slv_data_ref <= slv_data_ref(slv_data_ref'HIGH-C_BITWIDTH_IF downto slv_data_ref'LOW)
                      & slv_data_ref(slv_data_ref'HIGH downto slv_data_ref'HIGH-C_BITWIDTH_IF+1);
      wait until rising_edge(sl_clk);
    end loop;

    -- actual data
    for i in 0 to 128 / C_BITWIDTH_IF - 1 loop
      slv_data_in <= slv_data_ref(slv_data_ref'HIGH downto slv_data_ref'HIGH-C_BITWIDTH_IF+1);

      slv_data_ref <= slv_data_ref(slv_data_ref'HIGH-C_BITWIDTH_IF downto slv_data_ref'LOW)
                      & slv_data_ref(slv_data_ref'HIGH downto slv_data_ref'HIGH-C_BITWIDTH_IF+1);
      wait until rising_edge(sl_clk);
    end loop;

    sl_valid_in <= '0';
    wait until rising_edge(sl_clk);

    -- wait some random cycles between the inputs
    wait until rising_edge(sl_clk);
    wait until rising_edge(sl_clk);

    slv_data_ref <= array_to_slv(a_data_ref2);
    wait until rising_edge(sl_clk);

    -- second data input
    sl_valid_in <= '1';
    for i in 0 to 128 / C_BITWIDTH_IF - 1 loop
      slv_data_in <= slv_data_ref(slv_data_ref'HIGH downto slv_data_ref'HIGH-C_BITWIDTH_IF+1);

      slv_data_ref <= slv_data_ref(slv_data_ref'HIGH-C_BITWIDTH_IF downto slv_data_ref'LOW)
                      & slv_data_ref(slv_data_ref'HIGH downto slv_data_ref'HIGH-C_BITWIDTH_IF+1);
      wait until rising_edge(sl_clk);
    end loop;

    sl_valid_in <= '0';

    sl_stimuli_done <= '1';
  end process;

  data_check_proc : process
  begin
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_data_check_done <= '0';

    -- result of first input inclusive data, key and iv
    wait until rising_edge(sl_clk) and sl_valid_out = '1';
    for row in 0 to 3 loop
      for col in 0 to 3 loop
        -- a_key_out should be one word per row
        -- a_data_out and a_iv_out should be transposed
        report "row: " & to_string(row) & ", col: " & to_string(col);
        CHECK_EQUAL(a_data_out(row, col), a_data_ref(col, row), "data");
        CHECK_EQUAL(a_key_out(row)(col), a_data_ref(row, col), "key");
        if C_BITWIDTH_IV /= 0 then
          CHECK_EQUAL(a_iv_out(row, col), a_data_ref(col, row), "iv");
        else
          CHECK_EQUAL(a_iv_out(row, col), 0, "iv");
        end if;
      end loop;
    end loop;

    wait until rising_edge(sl_clk);
    CHECK_EQUAL(sl_valid_out, '0', "output valid");

    -- result of the second input (only data)
    wait until rising_edge(sl_clk) and sl_valid_out = '1';
    for row in 0 to 3 loop
      for col in 0 to 3 loop
        report "row: " & to_string(row) & ", col: " & to_string(col);
        CHECK_EQUAL(a_data_out(row, col), a_data_ref2(col, row), "data");
      end loop;
    end loop;

    wait until rising_edge(sl_clk);
    CHECK_EQUAL(sl_valid_out, '0', "output valid");

    report ("Done checking");
    sl_data_check_done <= '1';
  end process;
end architecture rtl;