library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;

library vunit_lib;
  context vunit_lib.vunit_context;

entity tb_aes is
  generic (
    runner_cfg    : string;
    C_MODE        : string;
    C_PLAINTEXT1  : string;
    C_KEY1        : string;
    C_IV1         : string;
    C_CIPHERTEXT1 : string;
    C_PLAINTEXT2  : string;
    C_KEY2        : string;
    C_IV2         : string;
    C_CIPHERTEXT2 : string
  );
end entity tb_aes;

architecture rtl of tb_aes is
  constant C_CLK_PERIOD : time := 10 ns;

  signal sl_clk : std_logic := '0';
  signal sl_valid_in : std_logic := '0';

  signal slv_data_in : std_logic_vector(127 downto 0) := x"340737e0a29831318d305a88a8f64332";
  signal slv_key_in : std_logic_vector(127 downto 0) := x"3c88a6164f15d215cff7ae7e09ab282b";
  signal slv_iv_in : std_logic_vector(127 downto 0) := x"00000000000000000000000000000000";
  signal slv_data_out : std_logic_vector(127 downto 0);
  signal sl_valid_out : std_logic;

  signal sl_start,
         sl_data_check_done,
         sl_stimuli_done : std_logic := '0';

  function hex_to_slv(str_i : string) return std_logic_vector is
    variable v_hex : std_logic_vector(3 downto 0) := (others => '0');
    variable v_slv : std_logic_vector(str_i'LENGTH*4 - 1 downto 0) := (others => '0');
  begin
    for i in str_i'RANGE loop
      case str_i(str_i'LENGTH - i+1) is
        when '0' => v_hex := x"0";
        when '1' => v_hex := x"1";
        when '2' => v_hex := x"2";
        when '3' => v_hex := x"3";
        when '4' => v_hex := x"4";
        when '5' => v_hex := x"5";
        when '6' => v_hex := x"6";
        when '7' => v_hex := x"7";
        when '8' => v_hex := x"8";
        when '9' => v_hex := x"9";
        when 'a' => v_hex := x"a";
        when 'A' => v_hex := x"a";
        when 'b' => v_hex := x"b";
        when 'B' => v_hex := x"b";
        when 'c' => v_hex := x"c";
        when 'C' => v_hex := x"c";
        when 'd' => v_hex := x"d";
        when 'D' => v_hex := x"d";
        when 'e' => v_hex := x"e";
        when 'E' => v_hex := x"e";
        when 'f' => v_hex := x"f";
        when 'F' => v_hex := x"f";
        when others => report "hexstr_to_slv: illegal char" severity ERROR;
      end case;
      v_slv(i*4-1 downto 0 + (i-1)*4) := v_hex;
    end loop;
    return v_slv;
  end function hex_to_slv;

begin
  dut_aes: entity work.aes
  generic map (
    C_MODE => C_MODE
  )
	port map (
    isl_clk   => sl_clk,
    isl_valid => sl_valid_in,
    islv_plaintext => slv_data_in,
    islv_key  => slv_key_in,
    islv_iv   => slv_iv_in,
    oslv_ciphertext => slv_data_out,
    osl_valid => sl_valid_out
  );
  
  clk_proc : process
	begin
		sl_clk <= '1';
		wait for C_CLK_PERIOD / 2;
		sl_clk <= '0';
		wait for C_CLK_PERIOD / 2;
  end process;
  
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
    slv_data_in <= hex_to_slv(C_PLAINTEXT1);
    slv_key_in <= hex_to_slv(C_KEY1);
    slv_iv_in <= hex_to_slv(C_IV1);
    wait until rising_edge(sl_clk);
    sl_valid_in <= '0';
    wait until rising_edge(sl_clk) and sl_valid_out = '1';

    sl_valid_in <= '1';
    slv_data_in <= hex_to_slv(C_PLAINTEXT2);
    slv_key_in <= hex_to_slv(C_KEY2);
    slv_iv_in <= hex_to_slv(C_IV2);
    wait until rising_edge(sl_clk);
    sl_valid_in <= '0';

    sl_stimuli_done <= '1';
  end process;

  data_check_proc : process
  begin
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_data_check_done <= '0';

    wait until rising_edge(sl_clk) and sl_valid_out = '1';
    CHECK_EQUAL(slv_data_out, hex_to_slv(C_CIPHERTEXT1));

    wait until rising_edge(sl_clk) and sl_valid_out = '1';
    CHECK_EQUAL(slv_data_out, hex_to_slv(C_CIPHERTEXT2));

    report ("Done checking");
    sl_data_check_done <= '1';
  end process;
end architecture rtl;