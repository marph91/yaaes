-- test whether the decryption and encryption modules work correctly together
-- input data -> encryption -> decryption -> output data
-- output data == input data?

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

library test_lib;
  use test_lib.vunit_common_pkg.all;

library vunit_lib;
  context vunit_lib.vunit_context;

entity tb_aes_selftest is
  generic (
    runner_cfg    : string;

    C_BITWIDTH_IF : integer;

    C_MODE        : t_mode;
    C_PLAINTEXT1  : string;
    C_PLAINTEXT2  : string;
    C_KEY         : string;
    C_IV          : string;
    C_BITWIDTH_KEY: integer
  );
end entity tb_aes_selftest;

architecture rtl of tb_aes_selftest is
  constant C_CLK_PERIOD : time := 10 ns;
  signal sl_clk : std_logic := '0';

  constant C_BITWIDTH_IV : integer range 0 to 128 := calculate_bw_iv(C_MODE);

  type t_module_inout is record
    sl_valid_in   : std_logic;
    slv_data_in   : std_logic_vector(C_BITWIDTH_IF-1 downto 0);
    sl_new_key_iv : std_logic;
    slv_data_out  : std_logic_vector(C_BITWIDTH_IF-1 downto 0);
    sl_valid_out  : std_logic;
  end record t_module_inout;
  signal r_encrypt,
         r_decrypt : t_module_inout;
  signal slv_data_out_full : std_logic_vector(128-1 downto 0);

  signal sl_start,
         sl_data_check_done,
         sl_stimuli_done : std_logic := '0';

begin
  dut_aes_encrypt: entity aes_lib.aes
  generic map (
    C_BITWIDTH_IF => C_BITWIDTH_IF,

    C_ENCRYPTION => 1,
    C_MODE => C_MODE,
    C_BITWIDTH_KEY => C_BITWIDTH_KEY
  )
  port map (
    isl_clk=> sl_clk,
    isl_valid => r_encrypt.sl_valid_in,
    islv_plaintext => r_encrypt.slv_data_in,
    isl_new_key_iv => r_encrypt.sl_new_key_iv,
    oslv_ciphertext => r_encrypt.slv_data_out,
    osl_valid => r_encrypt.sl_valid_out
  );

  dut_aes_decrypt: entity aes_lib.aes
  generic map (
    C_BITWIDTH_IF => C_BITWIDTH_IF,

    C_ENCRYPTION => 0,
    C_MODE => C_MODE,
    C_BITWIDTH_KEY => C_BITWIDTH_KEY
  )
	port map (
    isl_clk   => sl_clk,
    isl_valid => r_decrypt.sl_valid_in,
    islv_plaintext => r_decrypt.slv_data_in,
    isl_new_key_iv => r_decrypt.sl_new_key_iv,
    oslv_ciphertext => r_decrypt.slv_data_out,
    osl_valid => r_decrypt.sl_valid_out
  );
  
  clk_gen(sl_clk, C_CLK_PERIOD);
  main(sl_start, sl_clk, sl_stimuli_done, sl_data_check_done, runner, runner_cfg);

  stimuli_proc : process
  begin
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_stimuli_done <= '0';

    r_encrypt.sl_new_key_iv <= '1';
    r_decrypt.sl_new_key_iv <= '1';
    wait until rising_edge(sl_clk);
    r_encrypt.sl_new_key_iv <= '0';
    r_decrypt.sl_new_key_iv <= '0';

    -- provide keys for encrypt and decrypt module
    r_encrypt.sl_valid_in <= '1';
    r_decrypt.sl_valid_in <= '1';
    for i in C_BITWIDTH_KEY / C_BITWIDTH_IF - 1 downto 0 loop
      r_encrypt.slv_data_in <= hex_to_slv(C_KEY)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF);
      r_decrypt.slv_data_in <= hex_to_slv(C_KEY)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF);
      wait until rising_edge(sl_clk);
    end loop;

    -- provide iv for encrypt and decrypt module
    for i in C_BITWIDTH_IV / C_BITWIDTH_IF - 1 downto 0 loop
      r_encrypt.slv_data_in <= hex_to_slv(C_IV)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF);
      r_decrypt.slv_data_in <= hex_to_slv(C_IV)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF);
      wait until rising_edge(sl_clk);
    end loop;
    r_decrypt.sl_valid_in <= '0';

    -- provide data for encrypt module
    for i in 128 / C_BITWIDTH_IF - 1 downto 0 loop
      r_encrypt.slv_data_in <= hex_to_slv(C_PLAINTEXT1)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF);
      wait until rising_edge(sl_clk);
    end loop;
    r_encrypt.sl_valid_in <= '0';

    -- provide data for decrypt module
    wait until rising_edge(sl_clk) and r_encrypt.sl_valid_out = '1';
    r_decrypt.sl_valid_in <= '1';

    for i in 128 / C_BITWIDTH_IF - 1 downto 0 loop
      r_decrypt.slv_data_in <= r_encrypt.slv_data_out;
      wait until rising_edge(sl_clk);
    end loop;
    r_decrypt.sl_valid_in <= '0';

    -- next input can be started only after the output is fully done
    wait until rising_edge(sl_clk) and r_decrypt.sl_valid_out = '1';
    wait until rising_edge(sl_clk) and r_decrypt.sl_valid_out = '0';

    r_encrypt.sl_valid_in <= '1';
    for i in 128 / C_BITWIDTH_IF-1 downto 0 loop
      r_encrypt.slv_data_in <= hex_to_slv(C_PLAINTEXT2)((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF);
      -- no new key and iv needed
      wait until rising_edge(sl_clk);
    end loop;
    r_encrypt.sl_valid_in <= '0';

    wait until rising_edge(sl_clk) and r_encrypt.sl_valid_out = '1';
    r_decrypt.sl_valid_in <= '1';
    for i in 128 / C_BITWIDTH_IF-1 downto 0 loop
      r_decrypt.slv_data_in <= r_encrypt.slv_data_out;
      -- no new key and iv needed
      wait until rising_edge(sl_clk);
    end loop;
    r_decrypt.sl_valid_in <= '0';

    sl_stimuli_done <= '1';
  end process;

  data_check_proc : process
  begin
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_data_check_done <= '0';

    for i in 128 / C_BITWIDTH_IF - 1 downto 0 loop
      wait until rising_edge(sl_clk) and r_decrypt.sl_valid_out = '1';
      slv_data_out_full((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF) <= r_decrypt.slv_data_out;
    end loop;
    wait until rising_edge(sl_clk);
    CHECK_EQUAL(slv_data_out_full, hex_to_slv(C_PLAINTEXT1));

    for i in 128 / C_BITWIDTH_IF - 1 downto 0 loop
      wait until rising_edge(sl_clk) and r_decrypt.sl_valid_out = '1';
      slv_data_out_full((i+1)*C_BITWIDTH_IF-1 downto i*C_BITWIDTH_IF) <= r_decrypt.slv_data_out;
    end loop;
    wait until rising_edge(sl_clk);
    CHECK_EQUAL(slv_data_out_full, hex_to_slv(C_PLAINTEXT2));

    report ("Done checking");
    sl_data_check_done <= '1';
  end process;
end architecture rtl;