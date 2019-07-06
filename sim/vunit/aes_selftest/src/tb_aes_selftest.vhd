library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;
  use work.vunit_common_pkg.all;

library vunit_lib;
  context vunit_lib.vunit_context;

entity tb_aes_selftest is
  generic (
    runner_cfg    : string;
    C_ENCRYPTION  : integer;
    C_BITWIDTH    : integer;
    C_MODE        : string;
    C_PLAINTEXT1  : string;
    C_PLAINTEXT2  : string;
    C_KEY         : string;
    C_IV          : string
  );
end entity tb_aes_selftest;

architecture rtl of tb_aes_selftest is
  constant C_CLK_PERIOD : time := 10 ns;

  signal sl_clk : std_logic := '0';
  signal sl_valid_in : std_logic := '0';
  signal sl_new_key_in : std_logic := '0';

  signal slv_data_in : std_logic_vector(C_BITWIDTH-1 downto 0) := (others => '0');
  signal slv_key_in : std_logic_vector(C_BITWIDTH-1 downto 0) := (others => '0');
  signal slv_iv_in : std_logic_vector(C_BITWIDTH-1 downto 0) := (others => '0');
  signal slv_data_out : std_logic_vector(C_BITWIDTH-1 downto 0);
  signal sl_valid_out : std_logic;
  signal slv_data_out_encrypt : std_logic_vector(C_BITWIDTH-1 downto 0);
  signal sl_valid_out_encrypt : std_logic;
  signal slv_data_out_full : std_logic_vector(128-1 downto 0);

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
  dut_aes_encrypt: entity work.aes
  generic map (
    C_BITWIDTH => C_BITWIDTH,
    C_ENCRYPTION => 1,
    C_MODE => C_MODE
  )
	port map (
    isl_clk   => sl_clk,
    isl_valid => sl_valid_in,
    islv_plaintext => slv_data_in,
    isl_new_key => sl_new_key_in,
    islv_key  => slv_key_in,
    islv_iv   => slv_iv_in,
    oslv_ciphertext => slv_data_out_encrypt,
    osl_valid => sl_valid_out_encrypt
  );

  dut_aes_decrypt: entity work.aes
  generic map (
    C_BITWIDTH => C_BITWIDTH,
    C_ENCRYPTION => 0,
    C_MODE => C_MODE
  )
	port map (
    isl_clk   => sl_clk,
    isl_valid => sl_valid_out_encrypt,
    islv_plaintext => slv_data_out_encrypt,
    isl_new_key => sl_new_key_in,
    islv_key  => slv_key_in,
    islv_iv   => slv_iv_in,
    oslv_ciphertext => slv_data_out,
    osl_valid => sl_valid_out
  );
  
  clk_gen(sl_clk, C_CLK_PERIOD);
  main(sl_start, sl_clk, sl_stimuli_done, sl_data_check_done, runner, runner_cfg);

  stimuli_proc : process
  begin
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_stimuli_done <= '0';

    sl_valid_in <= '1';
    sl_new_key_in <= '1';
    for i in 128/C_BITWIDTH-1 downto 0 loop
      slv_data_in <= hex_to_slv(C_PLAINTEXT1)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH);
      slv_key_in <= hex_to_slv(C_KEY)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH);
      slv_iv_in <= hex_to_slv(C_IV)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH);
      wait until rising_edge(sl_clk);
    end loop;

    sl_new_key_in <= '0';
    sl_valid_in <= '0';
    wait until rising_edge(sl_clk) and sl_valid_out = '1';
    wait until rising_edge(sl_clk) and sl_valid_out = '0';
    -- next input can be started only after the output is fully done

    sl_valid_in <= '1';
    for i in 128/C_BITWIDTH-1 downto 0 loop
      slv_data_in <= hex_to_slv(C_PLAINTEXT2)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH);
      -- no new key and iv needed
      wait until rising_edge(sl_clk);
    end loop;

    sl_valid_in <= '0';

    sl_stimuli_done <= '1';
  end process;

  data_check_proc : process
  begin
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_data_check_done <= '0';

    for i in 128/C_BITWIDTH-1 downto 0 loop
      wait until rising_edge(sl_clk) and sl_valid_out = '1';
      slv_data_out_full((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH) <= slv_data_out;
    end loop;
    wait until rising_edge(sl_clk);
    CHECK_EQUAL(slv_data_out_full, hex_to_slv(C_PLAINTEXT1));

    for i in 128/C_BITWIDTH-1 downto 0 loop
      wait until rising_edge(sl_clk) and sl_valid_out = '1';
      slv_data_out_full((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH) <= slv_data_out;
    end loop;
    wait until rising_edge(sl_clk);
    CHECK_EQUAL(slv_data_out_full, hex_to_slv(C_PLAINTEXT2));

    report ("Done checking");
    sl_data_check_done <= '1';
  end process;
end architecture rtl;