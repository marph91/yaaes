-- AES block cipher modes, as described in: "NIST SP 800-38A"

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity aes is
  generic (
    C_BITWIDTH_IF : integer range 8 to 128 := 8; -- bitwidth of the input/output interface

    C_MODE : t_mode := ECB;
    C_ENCRYPTION : integer range 0 to 1 := 1;
    C_BITWIDTH_KEY : integer := 128
  );
  port (
    isl_clk         : in std_logic;
    isl_valid       : in std_logic;
    islv_plaintext  : in std_logic_vector(C_BITWIDTH_IF-1 downto 0);
    isl_new_key     : in std_logic;
    islv_iv         : in std_logic_vector(C_BITWIDTH_IF-1 downto 0);
    oslv_ciphertext : out std_logic_vector(C_BITWIDTH_IF-1 downto 0);
    osl_valid       : out std_logic
  );
end entity aes;

architecture rtl of aes is
  constant C_KEY_WORDS : integer := C_BITWIDTH_KEY / 32;

  signal sl_valid_conv,
         sl_valid_cipher_out : std_logic := '0';
  signal slv_data_out : std_logic_vector(C_BITWIDTH_IF-1 downto 0) := (others => '0');
  signal a_key_conv,
         a_data_conv,
         a_iv_conv,
         a_data_cipher_in,
         a_data_cipher_out,
         a_key_cipher_in,
         a_data_out : t_state := (others => (others => (others => '0')));

  signal sl_chain : std_logic := '0';

begin
  i_input_conversion : entity aes_lib.input_conversion
  generic map(
    C_BITWIDTH_IF => C_BITWIDTH_IF
  )
  port map(
    isl_clk   => isl_clk,
    isl_valid => isl_valid,
    islv_data_key => islv_plaintext,
    isl_chain => sl_chain,
    islv_iv   => islv_iv,
    oa_iv     => a_iv_conv,
    oa_key    => a_key_conv,
    oa_data   => a_data_conv,
    osl_valid => sl_valid_conv
  );

  i_cipher : entity aes_lib.cipher
  generic map(
    C_KEY_WORDS => C_KEY_WORDS
  )
  port map(
    isl_clk   => isl_clk,
    isl_valid => sl_valid_conv,
    ia_data   => a_data_cipher_in,
    ia_key    => type_state_to_key(a_key_cipher_in),
    oa_data   => a_data_cipher_out,
    osl_valid => sl_valid_cipher_out
  );

  i_output_conversion : entity aes_lib.output_conversion
  generic map(
    C_BITWIDTH => C_BITWIDTH_IF
  )
  port map(
    isl_clk   => isl_clk,
    isl_valid => sl_valid_cipher_out,
    ia_data   => a_data_out,
    oslv_data => slv_data_out,
    osl_valid => osl_valid
  );
  
  assert C_BITWIDTH_IF = 8 or
         C_BITWIDTH_IF = 32 or
         C_BITWIDTH_IF = 128 report "unsupported bitwidth " & integer'IMAGE(C_BITWIDTH_IF) severity failure;
  
  proc_chain : process(isl_clk)
  begin
    if rising_edge(isl_clk) then
      if isl_new_key = '1' then
        sl_chain <= '0';
      end if;
      if sl_valid_conv = '1' then
        sl_chain <= '1';
      end if;
    end if;
  end process proc_chain;
  
  gen_encryption : if C_ENCRYPTION = 1 generate
    gen_ecb : if C_MODE = ECB generate
      a_data_cipher_in <= a_data_conv;
      a_key_cipher_in <= a_key_conv;
      a_data_out <= a_data_cipher_out;
      oslv_ciphertext <= slv_data_out;
    end generate;

    gen_cbc : if C_MODE = CBC generate
      a_data_cipher_in <= xor_array(a_data_cipher_out, a_data_conv) when sl_chain = '1'
                          else xor_array(a_iv_conv, a_data_conv);
      a_key_cipher_in <= a_key_conv;
      a_data_out <= a_data_cipher_out;
      oslv_ciphertext <= slv_data_out;
    end generate;

    gen_cfb : if C_MODE = CFB generate
      proc_cipher_in : process(isl_clk)
      begin
        -- save the cipher input, because it gets modified as soon as there
        -- is new input (a_data_conv)
        if sl_valid_cipher_out = '1' and sl_chain = '1' then
          a_data_cipher_in <= a_data_out;
        elsif sl_chain = '0' then
          a_data_cipher_in <= a_iv_conv;
        end if;
      end process;
      a_key_cipher_in <= a_key_conv;
      a_data_out <= xor_array(a_data_cipher_out, a_data_conv);
      oslv_ciphertext <= slv_data_out;
    end generate;

    gen_ofb : if C_MODE = OFB generate
      a_data_cipher_in <= a_data_cipher_out when sl_chain = '1' else a_iv_conv;
      a_key_cipher_in <= a_key_conv;
      a_data_out <= xor_array(a_data_cipher_out, a_data_conv);
      oslv_ciphertext <= slv_data_out;
    end generate;

    gen_ctr : if C_MODE = CTR generate
      -- TODO: add counter mode, as described in: "NIST SP 800-38A"
    end generate;
  end generate;

  gen_decryption : if C_ENCRYPTION = 0 generate
    -- TODO: add decryption, respectively inverse cipher, as described in: "NIST FIPS 197, 5.3 Inverse Cipher"
    gen_cfb : if C_MODE = CFB generate
      -- ciphertext -> plaintext
      -- plaintext -> ciphertext
      proc_cipher_in : process(isl_clk)
      begin
        -- save the cipher input, because it gets modified as soon as there
        -- is new input (a_data_conv)
        if sl_valid_cipher_out = '1' and sl_chain = '1' then
          a_data_cipher_in <= a_data_conv;
        elsif sl_chain = '0' then
          a_data_cipher_in <= a_iv_conv;
        end if;
      end process;
      a_key_cipher_in <= a_key_conv;
      a_data_out <= xor_array(a_data_cipher_out, a_data_conv);
      oslv_ciphertext <= slv_data_out;
    end generate;

    gen_ofb : if C_MODE = OFB generate
      -- ciphertext -> plaintext
      -- plaintext -> ciphertext
      a_data_cipher_in <= a_data_cipher_out when sl_chain = '1' else a_iv_conv;
      a_key_cipher_in <= a_key_conv;
      a_data_out <= xor_array(a_data_cipher_out, a_data_conv);
      oslv_ciphertext <= slv_data_out;
    end generate;
  end generate;
end architecture rtl;