library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;

entity aes is
  generic (
    C_MODE : string := "ECB";
    C_ENCRYPTION : std_logic := '1';
    C_BITWIDTH : integer range 8 to 128 := 128
  );
  port (
    isl_clk         : in std_logic;
    isl_valid       : in std_logic;
    islv_plaintext  : in std_logic_vector(C_BITWIDTH-1 downto 0);
    islv_key        : in std_logic_vector(C_BITWIDTH-1 downto 0);
    islv_iv         : in std_logic_vector(C_BITWIDTH-1 downto 0);
    oslv_ciphertext : out std_logic_vector(C_BITWIDTH-1 downto 0);
    osl_valid       : out std_logic
  );
end entity aes;

architecture rtl of aes is
  -- TODO: use record for cipher related signals
  signal sl_valid_conv,
         sl_valid_cipher,
         sl_valid_out : std_logic := '0';
  signal slv_data_in,
         slv_key_in,
         slv_data_out : std_logic_vector(C_BITWIDTH-1 downto 0) := (others => '0');
  signal a_key_conv,
         a_data_conv,
         a_data_cipher,
         a_data_out : t_state := (others => (others => (others => '0')));
  
  signal slv_next_iv : std_logic_vector(C_BITWIDTH-1 downto 0) := (others => '0');
  
  signal sl_chain : std_logic := '0';

begin
  i_input_conversion : entity work.input_conversion
  generic map(
    C_BITWIDTH => C_BITWIDTH
  )
  port map(
    isl_clk   => isl_clk,
    isl_valid => isl_valid,
    islv_data => slv_data_in,
    islv_key  => slv_key_in,
    oa_key    => a_key_conv,
    oa_data   => a_data_conv,
    osl_valid => sl_valid_conv
  );

  i_cipher : entity work.cipher
  port map(
    isl_clk   => isl_clk,
    isl_valid => sl_valid_conv,
    ia_data   => a_data_conv,
    ia_key    => a_key_conv,
    oa_data   => a_data_cipher,
    osl_valid => sl_valid_cipher
  );

  i_output_conversion : entity work.output_conversion
  generic map(
    C_BITWIDTH => C_BITWIDTH
  )
  port map(
    isl_clk   => isl_clk,
    isl_valid => sl_valid_cipher,
    ia_data   => a_data_cipher,
    oslv_data => slv_data_out,
    osl_valid => osl_valid
  );
  
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