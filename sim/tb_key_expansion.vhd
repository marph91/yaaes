library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.aes_pkg.all;

entity tb_key_exp is
end entity tb_key_exp;

architecture rtl of tb_key_exp is
  constant C_CLK_PERIOD : time := 10 ns;

  signal sl_clk : std_logic := '0';
  signal sl_valid_in,
         sl_next_key : std_logic := '0';
  signal a_key_in : t_state := (others => (others => (others => '0')));
  signal a_data_out : t_state;
begin
  dut_aes: entity work.key_exp
	port map (
    isl_clk => sl_clk,
    isl_valid => sl_valid_in,
    isl_next_key => sl_next_key,
    ia_data => a_key_in,
    oa_data => a_data_out
  );
  
  clk_proc : process
	begin
		sl_clk <= '1';
		wait for C_CLK_PERIOD / 2;
		sl_clk <= '0';
		wait for C_CLK_PERIOD / 2;
	end process;

  stimuli_proc : process
  begin
    wait until rising_edge(sl_clk);
    wait until rising_edge(sl_clk);

    a_key_in <= ((x"2b", x"28", x"ab", x"09"),
                 (x"7e", x"ae", x"f7", x"cf"),
                 (x"15", x"d2", x"15", x"4f"),
                 (x"16", x"a6", x"88", x"3c"));
    sl_valid_in <= '1';
    sl_next_key <= '1';
    wait until rising_edge(sl_clk);

    sl_valid_in <= '0';

    for i in 0 to 10 loop
      wait until rising_edge(sl_clk);
      sl_next_key <= '1';
      wait until rising_edge(sl_clk);
      sl_next_key <= '0';
      
      for j in 0 to 6 loop
        wait until rising_edge(sl_clk);
      end loop;
    end loop;

    assert a_data_out = ((x"d0", x"c9", x"e1", x"b6"),
                         (x"14", x"ee", x"3f", x"63"),
                         (x"f9", x"25", x"0c", x"0c"),
                         (x"a8", x"89", x"c8", x"a6")) severity failure;
    wait;
  end process;
end architecture rtl;
