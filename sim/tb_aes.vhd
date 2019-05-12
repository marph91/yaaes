library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;

entity tb_aes is
end entity tb_aes;

architecture rtl of tb_aes is
  constant C_CLK_PERIOD : time := 10 ns;
  constant C_MODE : string := "ECB";

  signal sl_clk : std_logic := '0';
  signal sl_done : std_logic := '0';
  signal sl_valid_in : std_logic := '0';
  signal slv_data_in : std_logic_vector(127 downto 0) := (others => '0');
  signal slv_key_in : std_logic_vector(127 downto 0) := (others => '0');
  signal slv_iv_in : std_logic_vector(127 downto 0) := (others => 'U');
  signal slv_mode : std_logic_vector(3 downto 0) := (others => '0');
  signal slv_data_out : std_logic_vector(127 downto 0);
  signal sl_valid_out : std_logic;

  type test_vectors is array(natural range <>) of std_logic_vector(127 downto 0);
  type test_vectors_modes is array(natural range <>) of test_vectors(0 to 3);
  signal test_data_in : test_vectors(0 to 3);
  signal test_keys : test_vectors(0 to 3);
  signal test_data_out : test_vectors_modes(0 to 1);

begin
  dut_aes: entity work.aes
  generic map (
    C_MODE => C_MODE
  )
	port map (
    isl_clk         => sl_clk,
    isl_valid       => sl_valid_in,
    islv_plaintext => slv_data_in,
    islv_key        => slv_key_in,
    islv_iv         => slv_iv_in,
    oslv_ciphertext => slv_data_out,
    osl_valid       => sl_valid_out
  );
  
  clk_proc : process
	begin
    if sl_done = '0' then
      sl_clk <= '1';
      wait for C_CLK_PERIOD / 2;
      sl_clk <= '0';
      wait for C_CLK_PERIOD / 2;
    else
      wait;
    end if;
	end process;


  stimuli_proc : process
  begin
    sl_done <= '0';

    test_data_in <= (x"3243f6a8885a308d313198a2e0370734",
                     x"3243f6a8885a308d313198a2e0370734",
                     x"00112233445566778899aabbccddeeff",
                     x"4a03b12796dc526f371ac4b38e0503cb");
    test_keys <= (x"2b7e151628aed2a6abf7158809cf4f3c",
                  x"2b7e151628aed2a6abf7158809cf4f3c",
                  x"000102030405060708090a0b0c0d0e0f",
                  x"746522150f31617b80cb8d928b2f1a89");
    test_data_out <= ((x"3925841d02dc09fbdc118597196a0b32",
                       x"3925841d02dc09fbdc118597196a0b32",
                       x"69c4e0d86a7b0430d8cdb78070b4c55a",
                       x"808b3082f2b04efb6a9fd464c0a51406"),
                      (x"30a25d6a5c95dde2390758b150ff7038",
                       x"5d4e7cfb7d577ade3d5fd5641c45a808",
                       x"5738d3fc711c753c45ae2a838ba14aa7",
                       x"f8cb818433d28830d6316597c76b347c"));

    wait until rising_edge(sl_clk);
    wait until rising_edge(sl_clk);

    wait until rising_edge(sl_clk);
    for i in test_data_in'RANGE loop
      slv_data_in <= test_data_in(i);
      slv_key_in <= test_keys(i);
      slv_iv_in <= (0 => '1', others => '0');
      sl_valid_in <= '1';
      wait until rising_edge(sl_clk);

      sl_valid_in <= '0';

      wait until rising_edge(sl_clk) and sl_valid_out = '1';
      assert slv_data_out = test_data_out(0)(i) severity failure;
    end loop;

    sl_done <= '1';
    wait;
  end process;
end architecture rtl;
