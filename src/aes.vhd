library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;

entity aes is
  generic (
    C_MODE : string := "ECB";
    C_ENCRYPTION : std_logic := '1'
  );
  port (
    isl_clk         : in std_logic;
    isl_valid       : in std_logic;
    islv_plaintext  : in std_logic_vector(127 downto 0);
    islv_key        : in std_logic_vector(127 downto 0);
    islv_iv         : in std_logic_vector(127 downto 0);
    oslv_ciphertext : out std_logic_vector(127 downto 0);
    osl_valid       : out std_logic
  );
end entity aes;

architecture rtl of aes is
  -- TODO: use record for cipher related signals
  signal sl_valid_in,
         sl_valid_out : std_logic := '0';
  signal slv_data_in,
         slv_key_in,
         slv_data_out : std_logic_vector(127 downto 0) := (others => '0');
  
  signal slv_next_iv : std_logic_vector(127 downto 0) := (others => '0');
  
  signal sl_chain : std_logic := '0';

begin
  i_cipher : entity work.cipher
  port map(
    isl_clk   => isl_clk,
    isl_valid => sl_valid_in,
    islv_data => slv_data_in,
    islv_key  => slv_key_in,
    oslv_data => slv_data_out,
    osl_valid => sl_valid_out
  );

  -- TODO: add decryption and counter mode, as described in: "NIST SP 800-38A"
  -- TODO: add inverse cipher, as described in: "NIST FIPS 197, 5.3 Inverse Cipher"

  process(isl_clk)
  begin
    if rising_edge(isl_clk) then
      if isl_valid = '1' then
        sl_chain <= '1';

        -- TODO: probably generate is the better option
        if C_MODE = "ECB" then
          slv_data_in <= islv_plaintext;
          slv_key_in <= islv_key;
        elsif C_MODE = "CBC" then
          slv_data_in <= slv_data_out xor islv_plaintext when sl_chain = '1'
                         else islv_iv xor islv_plaintext;
          slv_key_in <= islv_key;
        elsif C_MODE = "CFB" then
          slv_data_in <= slv_next_iv when sl_chain = '1' else islv_iv;
          slv_key_in <= islv_key;
        elsif C_MODE = "OFB" then
          slv_data_in <= slv_data_out when sl_chain = '1' else islv_iv;
          slv_key_in <= islv_key;
        end if;
      end if;
      sl_valid_in <= isl_valid;
      

      if sl_valid_out = '1' then
        -- TODO: generate
        if C_MODE = "ECB" then
          oslv_ciphertext <= slv_data_out;
        elsif C_MODE = "CBC" then
          oslv_ciphertext <= slv_data_out;
        elsif C_MODE = "CFB" then
          slv_next_iv <= slv_data_out xor islv_plaintext;
          oslv_ciphertext <= slv_data_out xor islv_plaintext;
        elsif C_MODE = "OFB" then
          oslv_ciphertext <= slv_data_out xor islv_plaintext;
        end if;
      end if;
      osl_valid <= sl_valid_out;
      
    end if;
  end process;
end architecture rtl;
