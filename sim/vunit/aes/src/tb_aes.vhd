-- test whether the decryption and encryption modules work correctly independently
-- input data -> encryption/decryption -> output data
-- output data == python reference data?

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;
  use work.vunit_common_pkg.all;

library vunit_lib;
  context vunit_lib.vunit_context;

entity tb_aes is
  generic (
    runner_cfg    : string;
    C_ENCRYPTION  : integer;
    C_BITWIDTH    : integer;
    C_MODE        : t_mode;
    C_PLAINTEXT1  : string;
    C_CIPHERTEXT1 : string;
    C_PLAINTEXT2  : string;
    C_CIPHERTEXT2 : string;
    C_KEY         : string;
    C_IV          : string
  );
end entity tb_aes;

architecture rtl of tb_aes is
  constant C_CLK_PERIOD : time := 10 ns;

  signal sl_clk : std_logic := '0';
  signal sl_valid_in : std_logic := '0';
  signal sl_new_key_in : std_logic := '0';

  signal slv_data_in : std_logic_vector(C_BITWIDTH-1 downto 0) := (others => '0');
  signal slv_key_in : std_logic_vector(C_BITWIDTH-1 downto 0) := (others => '0');
  signal slv_iv_in : std_logic_vector(C_BITWIDTH-1 downto 0) := (others => '0');
  signal slv_data_out : std_logic_vector(C_BITWIDTH-1 downto 0);
  signal sl_valid_out : std_logic;

  signal sl_start,
         sl_data_check_done,
         sl_stimuli_done : std_logic := '0';

begin
  dut_aes: entity work.aes
  generic map (
    C_BITWIDTH => C_BITWIDTH,
    C_ENCRYPTION => C_ENCRYPTION,
    C_MODE => C_MODE
  )
	port map (
    isl_clk   => sl_clk,
    isl_valid => sl_valid_in,
    islv_plaintext => slv_data_in,
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
      CHECK_EQUAL(slv_data_out, hex_to_slv(C_CIPHERTEXT1)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH));
    end loop;

    for i in 128/C_BITWIDTH-1 downto 0 loop
      wait until rising_edge(sl_clk) and sl_valid_out = '1';
      CHECK_EQUAL(slv_data_out, hex_to_slv(C_CIPHERTEXT2)((i+1)*C_BITWIDTH-1 downto i*C_BITWIDTH));
    end loop;

    report ("Done checking");
    sl_data_check_done <= '1';
  end process;
end architecture rtl;