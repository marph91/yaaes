-- AES block cipher modes, as described in: "NIST SP 800-38A"

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity AES is
  generic (
    -- bitwidth of the input/output interface (8, 32 or 128 bit)
    G_BITWIDTH_IF  : integer range 8 to 128   := 32;

    -- one of the AES operation modes (ECB, CBC, CFB or OFB)
    G_MODE         : t_mode                   := ECB;

    -- encryption or decryption mode
    G_ENCRYPTION   : integer range 0 to 1     := 1;

    -- bitwidth of the key, i. e. AES-128 or AES-256
    G_BITWIDTH_KEY : integer range 128 to 256 := 256
  );
  port (
    isl_clk         : in    std_logic;
    isl_valid       : in    std_logic;
    islv_plaintext  : in    std_logic_vector(G_BITWIDTH_IF - 1 downto 0);
    isl_new_key_iv  : in    std_logic;
    oslv_ciphertext : out   std_logic_vector(G_BITWIDTH_IF - 1 downto 0);
    osl_valid       : out   std_logic
  );
end entity AES;

architecture RTL of AES is

  constant C_KEY_WORDS   : integer := G_BITWIDTH_KEY / 32;

  constant C_BITWIDTH_IV : integer range 0 to 128 := calculate_bw_iv(G_MODE);

  signal sl_valid_conv       : std_logic := '0';
  signal sl_valid_cipher_out : std_logic := '0';
  signal slv_data_out        : std_logic_vector(G_BITWIDTH_IF - 1 downto 0) := (others => '0');
  signal a_data_conv         : st_state;
  signal a_iv_conv           : st_state;
  signal a_data_cipher_in    : st_state;
  signal a_data_cipher_out   : st_state;
  signal a_data_out          : st_state;

  signal a_key_cipher_in     : t_key(0 to C_KEY_WORDS - 1) := (others => (others => (others => '0')));
  signal a_key_conv          : t_key(0 to C_KEY_WORDS - 1) := (others => (others => (others => '0')));

  signal sl_new_key_iv       : std_logic := '0';

begin

  i_input_conversion : entity aes_lib.INPUT_CONVERSION
    generic map (
      G_BITWIDTH_IF  => G_BITWIDTH_IF,
      G_BITWIDTH_KEY => G_BITWIDTH_KEY,
      G_BITWIDTH_IV  => C_BITWIDTH_IV
    )
    port map (
      isl_clk        => isl_clk,
      isl_valid      => isl_valid,
      islv_data      => islv_plaintext,
      isl_new_key_iv => isl_new_key_iv,
      oa_iv          => a_iv_conv,
      oa_key         => a_key_conv,
      oa_data        => a_data_conv,
      osl_valid      => sl_valid_conv
    );

  i_cipher : entity aes_lib.CIPHER
    generic map (
      G_KEY_WORDS => C_KEY_WORDS
    )
    port map (
      isl_clk   => isl_clk,
      isl_valid => sl_valid_conv,
      ia_data   => a_data_cipher_in,
      ia_key    => a_key_cipher_in,
      oa_data   => a_data_cipher_out,
      osl_valid => sl_valid_cipher_out
    );

  i_output_conversion : entity aes_lib.OUTPUT_CONVERSION
    generic map (
      G_BITWIDTH => G_BITWIDTH_IF
    )
    port map (
      isl_clk   => isl_clk,
      isl_valid => sl_valid_cipher_out,
      ia_data   => a_data_out,
      oslv_data => slv_data_out,
      osl_valid => osl_valid
    );

  assert G_BITWIDTH_IF = 8 or
    G_BITWIDTH_IF = 32 or
    G_BITWIDTH_IF = 128 report "unsupported bitwidth " & integer'IMAGE(G_BITWIDTH_IF) severity failure;

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

  GEN_ENCRYPTION : if G_ENCRYPTION = 1 generate

    GEN_ECB : if G_MODE = ECB generate
      a_data_cipher_in <= a_data_conv;
      a_key_cipher_in  <= a_key_conv;
      a_data_out       <= a_data_cipher_out;
      oslv_ciphertext  <= slv_data_out;
    end generate GEN_ECB;

    GEN_CBC : if G_MODE = CBC generate
      a_data_cipher_in <= xor_array(a_data_cipher_out, a_data_conv) when sl_new_key_iv = '0'
                          else
                          xor_array(a_iv_conv, a_data_conv);
      a_key_cipher_in  <= a_key_conv;
      a_data_out       <= a_data_cipher_out;
      oslv_ciphertext  <= slv_data_out;
    end generate GEN_CBC;

    GEN_CFB : if G_MODE = CFB generate

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

    GEN_OFB : if G_MODE = OFB generate
      a_data_cipher_in <= a_data_cipher_out when sl_new_key_iv = '0' else
                          a_iv_conv;
      a_key_cipher_in  <= a_key_conv;
      a_data_out       <= xor_array(a_data_cipher_out, a_data_conv);
      oslv_ciphertext  <= slv_data_out;
    end generate GEN_OFB;

    GEN_CTR : if G_MODE = CTR generate
      -- TODO: add counter mode, as described in: "NIST SP 800-38A"
    end generate GEN_CTR;

  end generate GEN_ENCRYPTION;

  GEN_DECRYPTION : if G_ENCRYPTION = 0 generate
    -- TODO: add decryption, respectively inverse cipher, as described in: "NIST FIPS 197, 5.3 Inverse Cipher"

    GEN_CFB : if G_MODE = CFB generate
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

    GEN_OFB : if G_MODE = OFB generate
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
