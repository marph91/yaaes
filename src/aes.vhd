library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.aes_pkg.all;

entity aes is
  generic (
    C_MODE : string := "ECB";
    C_ENCRYPTION : std_logic := '1';
    C_BITWIDTH : integer range 8 to 128 := 8
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
         sl_valid_cipher_out : std_logic := '0';
  signal slv_data_out : std_logic_vector(C_BITWIDTH-1 downto 0) := (others => '0');
  signal a_key_conv,
         a_data_conv,
         a_iv_conv,
         a_data_cipher_in,
         a_data_cipher_out,
         a_key_cipher_in,
         a_data_out : t_state := (others => (others => (others => '0')));
  
  signal sl_chain : std_logic := '0';

begin
  i_input_conversion : entity work.input_conversion
  generic map(
    C_BITWIDTH => C_BITWIDTH
  )
  port map(
    isl_clk   => isl_clk,
    isl_valid => isl_valid,
    islv_data => islv_plaintext,
    islv_key  => islv_key,
    islv_iv   => islv_iv,
    oa_iv     => a_iv_conv,
    oa_key    => a_key_conv,
    oa_data   => a_data_conv,
    osl_valid => sl_valid_conv
  );

  i_cipher : entity work.cipher
  port map(
    isl_clk   => isl_clk,
    isl_valid => sl_valid_conv,
    ia_data   => a_data_cipher_in,
    ia_key    => a_key_cipher_in,
    oa_data   => a_data_cipher_out,
    osl_valid => sl_valid_cipher_out
  );

  i_output_conversion : entity work.output_conversion
  generic map(
    C_BITWIDTH => C_BITWIDTH
  )
  port map(
    isl_clk   => isl_clk,
    isl_valid => sl_valid_cipher_out,
    ia_data   => a_data_out,
    oslv_data => slv_data_out,
    osl_valid => osl_valid
  );
  
  assert C_BITWIDTH = 8 or
         C_BITWIDTH = 32 or
         C_BITWIDTH = 128 report "unsupported bitwidth " & integer'IMAGE(C_BITWIDTH) severity failure;
  
  gen_encryption : if C_ENCRYPTION = '1' generate
    gen_ecb : if C_MODE = "ECB" generate
      a_data_cipher_in <= a_data_conv;
      a_key_cipher_in <= a_key_conv;
      a_data_out <= a_data_cipher_out;
      oslv_ciphertext <= slv_data_out;
    end generate;

    gen_cbc : if C_MODE = "CBC" generate
      a_data_cipher_in <= xor_array(a_data_cipher_out, a_data_conv) when sl_chain = '1'
                          else xor_array(a_iv_conv, a_data_conv);
      a_key_cipher_in <= a_key_conv;
      a_data_out <= a_data_cipher_out;
      oslv_ciphertext <= slv_data_out;
    end generate;

    gen_cfb : if C_MODE = "CFB" generate
      a_data_cipher_in <= a_data_out when sl_chain = '1' else a_iv_conv;
      a_key_cipher_in <= a_key_conv;
      a_data_out <= xor_array(a_data_cipher_out, a_data_conv);
      oslv_ciphertext <= slv_data_out;
    end generate;

    gen_ofb : if C_MODE = "OFB" generate
      a_data_cipher_in <= a_data_cipher_out when sl_chain = '1' else a_iv_conv;
      a_key_cipher_in <= a_key_conv;
      a_data_out <= xor_array(a_data_cipher_out, a_data_conv);
      oslv_ciphertext <= slv_data_out;
    end generate;

    gen_ctr : if C_MODE = "OFB" generate
      -- TODO: add counter mode, as described in: "NIST SP 800-38A"
    end generate;
  end generate;

  gen_decryption : if C_ENCRYPTION = '0' generate
    -- TODO: add decryption, respectively inverse cipher, as described in: "NIST FIPS 197, 5.3 Inverse Cipher"
  end generate;
end architecture rtl;