-- test whether the decryption and encryption modules work correctly together
-- input data -> encryption -> decryption -> output data
-- output data == input data?

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;
  use aes_lib.vunit_common_pkg.all;

library vunit_lib;
  context vunit_lib.vunit_context;

entity tb_aes_selftest is
  generic (
    runner_cfg    : string;
    C_ENCRYPTION  : integer;
    C_BITWIDTH    : integer;
    C_MODE        : t_mode;
    C_PLAINTEXT1  : string;
    C_PLAINTEXT2  : string;
    C_KEY         : string;
    C_IV          : string
  );
end entity tb_aes_selftest;

architecture rtl of tb_aes_selftest is
  constant C_CLK_PERIOD : time := 10 ns;
  signal sl_clk : std_logic := '0';

  type t_module_inout is record
    sl_valid_in : std_logic;
    slv_data_in : std_logic_vector(C_BITWIDTH-1 downto 0);
    sl_new_key_in : std_logic;
    slv_key_in : std_logic_vector(C_BITWIDTH-1 downto 0);
    slv_iv_in : std_logic_vector(C_BITWIDTH-1 downto 0);
    slv_data_out : std_logic_vector(C_BITWIDTH-1 downto 0);
    sl_valid_out : std_logic;
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
    C_BITWIDTH_IF => C_BITWIDTH,
    C_ENCRYPTION => 1,
    C_MODE => C_MODE
  )
  port map (
    isl_clk=> sl_clk,
    isl_valid => r_encrypt.sl_valid_in,
    islv_plaintext => r_encrypt.slv_data_in,
    isl_new_key => r_encrypt.sl_new_key_in,
    islv_key => r_encrypt.slv_key_in,
    islv_iv => r_encrypt.slv_iv_in,
    oslv_ciphertext => r_encrypt.slv_data_out,
    osl_valid => r_encrypt.sl_valid_out
  );

  dut_aes_decrypt: entity aes_lib.aes
  generic map (
    C_BITWIDTH_IF => C_BITWIDTH,
    C_ENCRYPTION => 0,
    C_MODE => C_MODE
  )
	port map (
    isl_clk   => sl_clk,
    isl_valid => r_decrypt.sl_valid_in,
    islv_plaintext => r_decrypt.slv_data_in,
    isl_new_key => r_decrypt.sl_new_key_in,
    islv_key  => r_decrypt.slv_key_in,
    islv_iv   => r_decrypt.slv_iv_in,
    oslv_ciphertext => r_decrypt.slv_data_out,
    osl_valid => r_decrypt.sl_valid_out
  );
  
  clk_gen(sl_clk, C_CLK_PERIOD);
  main(sl_start, sl_clk, sl_stimuli_done, sl_data_check_done, runner, runner_cfg);

  stimuli_proc : process
  begin
    wait until rising_edge(sl_clk) and sl_start = '1';
    sl_stimuli_done <= '0';

    r_encrypt.sl_valid_in <= '1';
    r_encrypt.sl_new_key_in <= '1';
    for i in 128/C_BITWIDTH-1 downto 0 loop
      r_encrypt.slv_data_in <= hex_to_slv(C_PLAINTEXT1)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH);
      r_encrypt.slv_key_in <= hex_to_slv(C_KEY)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH);
      r_encrypt.slv_iv_in <= hex_to_slv(C_IV)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH);
      wait until rising_edge(sl_clk);
    end loop;
    r_encrypt.sl_new_key_in <= '0';
    r_encrypt.sl_valid_in <= '0';

    -- provide key and iv for decrypt module
    wait until rising_edge(sl_clk) and r_encrypt.sl_valid_out = '1';
    r_decrypt.sl_valid_in <= '1';
    r_decrypt.sl_new_key_in <= '1';
    for i in 128/C_BITWIDTH-1 downto 0 loop
      r_decrypt.slv_data_in <= r_encrypt.slv_data_out;
      r_decrypt.slv_key_in <= hex_to_slv(C_KEY)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH);
      r_decrypt.slv_iv_in <= hex_to_slv(C_IV)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH);
      wait until rising_edge(sl_clk);
    end loop;
    r_decrypt.sl_valid_in <= '0';
    r_decrypt.sl_new_key_in <= '0';

    wait until rising_edge(sl_clk) and r_decrypt.sl_valid_out = '1';
    wait until rising_edge(sl_clk) and r_decrypt.sl_valid_out = '0';
    -- next input can be started only after the output is fully done

    r_encrypt.sl_valid_in <= '1';
    for i in 128/C_BITWIDTH-1 downto 0 loop
      r_encrypt.slv_data_in <= hex_to_slv(C_PLAINTEXT2)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH);
      -- no new key and iv needed
      wait until rising_edge(sl_clk);
    end loop;
    r_encrypt.sl_valid_in <= '0';

    -- provide key and iv for decrypt module
    wait until rising_edge(sl_clk) and r_encrypt.sl_valid_out = '1';
    r_decrypt.sl_valid_in <= '1';
    for i in 128/C_BITWIDTH-1 downto 0 loop
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

    for i in 128/C_BITWIDTH-1 downto 0 loop
      wait until rising_edge(sl_clk) and r_decrypt.sl_valid_out = '1';
      slv_data_out_full((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH) <= r_decrypt.slv_data_out;
    end loop;
    wait until rising_edge(sl_clk);
    CHECK_EQUAL(slv_data_out_full, hex_to_slv(C_PLAINTEXT1));

    for i in 128/C_BITWIDTH-1 downto 0 loop
      wait until rising_edge(sl_clk) and r_decrypt.sl_valid_out = '1';
      slv_data_out_full((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH) <= r_decrypt.slv_data_out;
    end loop;
    wait until rising_edge(sl_clk);
    CHECK_EQUAL(slv_data_out_full, hex_to_slv(C_PLAINTEXT2));

    report ("Done checking");
    sl_data_check_done <= '1';
  end process;
end architecture rtl;