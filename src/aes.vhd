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
  -- TODO: enable bitwidth /= 128, i. e. 8, 16, 32
  signal sl_valid_in,
         sl_valid_out : std_logic := '0';
  signal slv_data_in,
         slv_key_in,
         slv_data_out : std_logic_vector(127 downto 0) := (others => '0');
  
  signal a_key_in,
         a_data_in,
         a_data_out : t_state := (others => (others => (others => '0')));
  
  signal slv_next_iv : std_logic_vector(127 downto 0) := (others => '0');
  
  signal sl_chain : std_logic := '0';

begin
  i_cipher : entity work.cipher
  port map(
    isl_clk   => isl_clk,
    isl_valid => isl_valid,
    ia_data => a_data_in,
    ia_key  => a_key_in,
    oa_data => a_data_out,
    osl_valid => osl_valid
  );

  -- convert input and output (slv <-> array) and revert the vectors bytewise
  -- TODO: is there a better way for the conversion?
  gen_rows : for row in 0 to C_STATE_ROWS-1 generate
    gen_cols : for col in 0 to C_STATE_COLS-1 generate
      a_data_in(C_STATE_ROWS-1-row, C_STATE_COLS-1-col) <= unsigned(slv_data_in((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8));
      a_key_in(C_STATE_ROWS-1-row, C_STATE_COLS-1-col) <= unsigned(slv_key_in((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8));
      slv_data_out((row+C_STATE_ROWS*col + 1) * 8 - 1 downto (row+C_STATE_ROWS*col) * 8) <= std_logic_vector(a_data_out(C_STATE_ROWS-1-row, C_STATE_COLS-1-col));
    end generate;
  end generate;
  
  gen_encryption : if C_ENCRYPTION = '1' generate
    gen_ecb : if C_MODE = "ECB" generate
      slv_data_in <= islv_plaintext;
      slv_key_in <= islv_key;
      oslv_ciphertext <= slv_data_out;
    end generate;

    gen_cbc : if C_MODE = "CBC" generate
      slv_data_in <= slv_data_out xor islv_plaintext when sl_chain = '1'
                     else islv_iv xor islv_plaintext;
      slv_key_in <= islv_key;
      oslv_ciphertext <= slv_data_out;
    end generate;

    gen_cfb : if C_MODE = "CFB" generate
      slv_data_in <= slv_next_iv when sl_chain = '1' else islv_iv;
      slv_key_in <= islv_key;
      slv_next_iv <= slv_data_out xor islv_plaintext;
      oslv_ciphertext <= slv_data_out xor islv_plaintext;
    end generate;

    gen_ofb : if C_MODE = "OFB" generate
      slv_data_in <= slv_data_out when sl_chain = '1' else islv_iv;
      slv_key_in <= islv_key;
      oslv_ciphertext <= slv_data_out xor islv_plaintext;
    end generate;

    gen_ctr : if C_MODE = "OFB" generate
      -- TODO: add counter mode, as described in: "NIST SP 800-38A"
    end generate;
  end generate;

  gen_decryption : if C_ENCRYPTION = '0' generate
    -- TODO: add decryption, respectively inverse cipher, as described in: "NIST FIPS 197, 5.3 Inverse Cipher"
  end generate;
end architecture rtl;