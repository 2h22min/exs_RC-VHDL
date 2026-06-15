library ieee;
use ieee.std_logic_1164.all;

entity stream_cipher is
    port (
        clk     : in std_logic; -- Rising-edge system clock
        rst     : in std_logic; -- Active-high synchronous reset
        enable  : in std_logic; -- When high, consumes a key bit and updates output
        din     : in std_logic; -- Serial input bit stream
        dout    : out std_logic; -- Registered output (combinational from reg)
        key_bit : out std_logic -- Current LFSR key bit (combinational)
    );
end entity;

architecture rtl of stream_cipher is
    -- Signals match DUT ports
    signal lfsr_state   : std_logic_vector(7 downto 0);
    signal lfsr_bit     : std_logic;
begin
    lfsr_inst : entity work.lfsr
        generic map (
            INIT => x"AE"
        )
        port map (
            clk => clk,
            rst => rst,
            enable => enable,
            state_out => lfsr_state,
            bit_out => lfsr_bit
        );
        
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                dout <= '0';
            elsif enable = '1' then -- The cipher output is registered
                -- The cipher XORs each input bit with the key bit
                dout <= din xor lfsr_bit;
                key_bit <= lfsr_bit;
            end if;
        end if;
    end process;

end architecture;
