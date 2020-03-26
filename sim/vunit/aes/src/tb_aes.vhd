-- test whether the decryption and encryption modules work correctly independently
-- input data -> encryption/decryption -> output data
-- output data == python reference data?

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

library test_lib;
  use test_lib.vunit_common_pkg.all;

library vunit_lib;
  context vunit_lib.vunit_context;

entity tb_aes is
  generic (
    runner_cfg    : string;

    C_BITWIDTH_IF : integer;

    C_ENCRYPTION  : integer;
    C_MODE        : t_mode;
    C_PLAINTEXT1  : string;
    C_CIPHERTEXT1 : string;
    C_PLAINTEXT2  : string;
    C_CIPHERTEXT2 : string;
    C_KEY         : string;
    C_IV          : string;
    C_BITWIDTH_KEY: integer
  );
end entity tb_aes;

architecture rtl of tb_aes is
  constant C_CLK_PERIOD : time := 10 ns;

  constant C_BITWIDTH_IV : integer range 0 to 128 := calculate_bw_iv(C_MODE);

  signal sl_clk : std_logic := '0';
  signal sl_valid_in : std_logic := '0';
  signal sl_new_key_iv : std_logic := '0';

  signal slv_data_in : std_logic_vector(C_BITWIDTH_IF-1 downto 0) := (others => '0');
  signal slv_data_out : std_logic_vector(C_BITWIDTH_IF-1 downto 0);
  signal sl_valid_out : std_logic;

  signal sl_start,
         sl_data_check_done,
         sl_stimuli_done : std_logic := '0';

begin
  dut_aes: entity aes_lib.aes
  generic map (
    C_BITWIDTH_IF => C_BITWIDTH_IF,

    C_ENCRYPTION => C_ENCRYPTION,
    C_MODE => C_MODE,
    C_BITWIDTH_KEY => C_BITWIDTH_KEY
  )
	port map (
    isl_clk   => sl_clk,
    isl_valid => sl_valid_in,
    islv_plaintext => slv_data_in,
    isl_new_key_iv => sl_new_key_iv,
    oslv_ciphertext => slv_data_out,
    osl_valid => sl_valid_out
  );
  
  clk_gen(sl_clk, C_CLK_PERIOD);
  main(sl_start, sl_clk, sl_stimuli_done, sl_data_check_done, runner, runner_cfg);

  stimuli_proc : process
  begin
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_stimuli_done <= '0';

    sl_new_key_iv <= '1';
    wait until rising_edge(sl_clk);
    sl_new_key_iv <= '0';

    sl_valid_in <= '1';
    -- key
    for i in C_BITWIDTH_KEY / C_BITWIDTH_IF - 1 downto 0 loop
      slv_data_in <= hex_to_slv(C_KEY)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF);
      wait until rising_edge(sl_clk);
    end loop;

    -- iv
    for i in C_BITWIDTH_IV / C_BITWIDTH_IF - 1 downto 0 loop
      slv_data_in <= hex_to_slv(C_IV)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF);
      wait until rising_edge(sl_clk);
    end loop;

    -- actual data
    for i in 128 / C_BITWIDTH_IF - 1 downto 0 loop
      slv_data_in <= hex_to_slv(C_PLAINTEXT1)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF);
      wait until rising_edge(sl_clk);
    end loop;

    sl_valid_in <= '0';
    wait until rising_edge(sl_clk) and sl_valid_out = '1';
    wait until rising_edge(sl_clk) and sl_valid_out = '0';
    -- next input can be started only after the output is fully done

    sl_valid_in <= '1';
    for i in 128/C_BITWIDTH_IF-1 downto 0 loop
      slv_data_in <= hex_to_slv(C_PLAINTEXT2)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF);
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

    for i in 128/C_BITWIDTH_IF-1 downto 0 loop
      wait until rising_edge(sl_clk) and sl_valid_out = '1';
      CHECK_EQUAL(slv_data_out, hex_to_slv(C_CIPHERTEXT1)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF));
    end loop;

    for i in 128/C_BITWIDTH_IF-1 downto 0 loop
      wait until rising_edge(sl_clk) and sl_valid_out = '1';
      CHECK_EQUAL(slv_data_out, hex_to_slv(C_CIPHERTEXT2)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF));
    end loop;

    report ("Done checking");
    sl_data_check_done <= '1';
  end process;
end architecture rtl;