-- AES block cipher modes, as described in: "NIST SP 800-38A"

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity AES is
  generic (
    -- bitwidth of the input/output interface (8, 32 or 128 bit)
    C_BITWIDTH_IF  : integer range 8 to 128   := 32;

    -- one of the AES operation modes (ECB, CBC, CFB or OFB)
    C_MODE         : t_mode                   := ECB;

    -- encryption or decryption mode
    C_ENCRYPTION   : integer range 0 to 1     := 1;

    -- bitwidth of the key, i. e. AES-128 or AES-256
    C_BITWIDTH_KEY : integer range 128 to 256 := 256
  );
  port (
    ISL_CLK         : in    std_logic;
    ISL_VALID       : in    std_logic;
    ISLV_PLAINTEXT  : in    std_logic_vector(C_BITWIDTH_IF - 1 downto 0);
    ISL_NEW_KEY_IV  : in    std_logic;
    OSLV_CIPHERTEXT : out   std_logic_vector(C_BITWIDTH_IF - 1 downto 0);
    OSL_VALID       : out   std_logic
  );
end entity AES;

architecture RTL of AES is

  constant c_key_words   : integer := C_BITWIDTH_KEY / 32;

  constant c_bitwidth_iv : integer range 0 to 128 := calculate_bw_iv(C_MODE);

  signal sl_valid_conv       : std_logic := '0';
  signal sl_valid_cipher_out : std_logic := '0';
  signal slv_data_out        : std_logic_vector(C_BITWIDTH_IF - 1 downto 0) := (others => '0');
  signal a_data_conv         : t_state;
  signal a_iv_conv           : t_state;
  signal a_data_cipher_in    : t_state;
  signal a_data_cipher_out   : t_state;
  signal a_data_out          : t_state;

  signal a_key_cipher_in     : t_key(0 to c_key_words - 1) := (others => (others => (others => '0')));
  signal a_key_conv          : t_key(0 to c_key_words - 1) := (others => (others => (others => '0')));

  signal sl_new_key_iv       : std_logic := '0';

begin

  i_input_conversion : entity aes_lib.INPUT_CONVERSION
    generic map (
      C_BITWIDTH_IF  => C_BITWIDTH_IF,
      C_BITWIDTH_KEY => C_BITWIDTH_KEY,
      C_BITWIDTH_IV  => C_BITWIDTH_IV
    )
    port map (
      ISL_CLK        => isl_clk,
      ISL_VALID      => isl_valid,
      ISLV_DATA      => islv_plaintext,
      ISL_NEW_KEY_IV => isl_new_key_iv,
      OA_IV          => a_iv_conv,
      OA_KEY         => a_key_conv,
      OA_DATA        => a_data_conv,
      OSL_VALID      => sl_valid_conv
    );

  i_cipher : entity aes_lib.CIPHER
    generic map (
      C_KEY_WORDS => C_KEY_WORDS
    )
    port map (
      ISL_CLK   => isl_clk,
      ISL_VALID => sl_valid_conv,
      IA_DATA   => a_data_cipher_in,
      IA_KEY    => a_key_cipher_in,
      OA_DATA   => a_data_cipher_out,
      OSL_VALID => sl_valid_cipher_out
    );

  i_output_conversion : entity aes_lib.OUTPUT_CONVERSION
    generic map (
      C_BITWIDTH => C_BITWIDTH_IF
    )
    port map (
      ISL_CLK   => isl_clk,
      ISL_VALID => sl_valid_cipher_out,
      IA_DATA   => a_data_out,
      OSLV_DATA => slv_data_out,
      OSL_VALID => osl_valid
    );

  assert C_BITWIDTH_IF = 8 or
    C_BITWIDTH_IF = 32 or
    C_BITWIDTH_IF = 128 report "unsupported bitwidth " & integer'IMAGE(C_BITWIDTH_IF) severity failure;

  PROC_CHAIN : process (isl_clk) is
  begin

    if (isl_clk'event and isl_clk = '1') then
      if (isl_new_key_iv = '1') then
        sl_new_key_iv <= '1';
      end if;
      if (sl_valid_conv = '1') then
        sl_new_key_iv <= '0';
      end if;
    end if;

  end process PROC_CHAIN;

  GEN_ENCRYPTION : if C_ENCRYPTION = 1 generate

    GEN_ECB : if C_MODE = ECB generate
      a_data_cipher_in <= a_data_conv;
      a_key_cipher_in  <= a_key_conv;
      a_data_out       <= a_data_cipher_out;
      oslv_ciphertext  <= slv_data_out;
    end generate GEN_ECB;

    GEN_CBC : if C_MODE = CBC generate
      a_data_cipher_in <= xor_array(a_data_cipher_out, a_data_conv) when sl_new_key_iv = '0'
                          else
                          xor_array(a_iv_conv, a_data_conv);
      a_key_cipher_in  <= a_key_conv;
      a_data_out       <= a_data_cipher_out;
      oslv_ciphertext  <= slv_data_out;
    end generate GEN_CBC;

    GEN_CFB : if C_MODE = CFB generate

      PROC_CIPHER_IN : process (isl_clk) is
      begin

        -- save the cipher input, because it gets modified as soon as there
        -- is new input (a_data_conv)
        if (sl_valid_cipher_out = '1' and sl_new_key_iv = '0') then
          a_data_cipher_in <= a_data_out;
        elsif (sl_new_key_iv = '1') then
          a_data_cipher_in <= a_iv_conv;
        end if;

      end process PROC_CIPHER_IN;

      a_key_cipher_in <= a_key_conv;
      a_data_out      <= xor_array(a_data_cipher_out, a_data_conv);
      oslv_ciphertext <= slv_data_out;
    end generate GEN_CFB;

    GEN_OFB : if C_MODE = OFB generate
      a_data_cipher_in <= a_data_cipher_out when sl_new_key_iv = '0' else
                          a_iv_conv;
      a_key_cipher_in  <= a_key_conv;
      a_data_out       <= xor_array(a_data_cipher_out, a_data_conv);
      oslv_ciphertext  <= slv_data_out;
    end generate GEN_OFB;

    GEN_CTR : if C_MODE = CTR generate
      -- TODO: add counter mode, as described in: "NIST SP 800-38A"
    end generate GEN_CTR;

  end generate GEN_ENCRYPTION;

  GEN_DECRYPTION : if C_ENCRYPTION = 0 generate
    -- TODO: add decryption, respectively inverse cipher, as described in: "NIST FIPS 197, 5.3 Inverse Cipher"

    GEN_CFB : if C_MODE = CFB generate
      -- ciphertext -> plaintext
      -- plaintext -> ciphertext
      PROC_CIPHER_IN : process (isl_clk) is
      begin

        -- save the cipher input, because it gets modified as soon as there
        -- is new input (a_data_conv)
        if (sl_valid_cipher_out = '1' and sl_new_key_iv = '0') then
          a_data_cipher_in <= a_data_conv;
        elsif (sl_new_key_iv = '1') then
          a_data_cipher_in <= a_iv_conv;
        end if;

      end process PROC_CIPHER_IN;

      a_key_cipher_in <= a_key_conv;
      a_data_out      <= xor_array(a_data_cipher_out, a_data_conv);
      oslv_ciphertext <= slv_data_out;
    end generate GEN_CFB;

    GEN_OFB : if C_MODE = OFB generate
      -- ciphertext -> plaintext
      -- plaintext -> ciphertext
      a_data_cipher_in <= a_data_cipher_out when sl_new_key_iv = '0' else
                          a_iv_conv;
      a_key_cipher_in  <= a_key_conv;
      a_data_out       <= xor_array(a_data_cipher_out, a_data_conv);
      oslv_ciphertext  <= slv_data_out;
    end generate GEN_OFB;

  end generate GEN_DECRYPTION;

end architecture RTL;
