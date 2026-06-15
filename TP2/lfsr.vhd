library ieee;
use ieee.std_logic_1164.all;

-- 8-bit Fibonacci LFSR
entity lfsr is
    -- Important: The all-zero state is invalid and will lock the LFSR forever.
    -- Always choose a non-zero seed
    generic (INIT : std_logic_vector(7 downto 0));
    port (
        clk         : in std_logic; -- Rising-edge system clock
        rst         : in std_logic; -- Active-high synchronous reset
        enable      : in std_logic; -- Advances the LFSR on rising edge when high
        -- (combinational outputs)
        state_out   : out std_logic_vector(7 downto 0); -- 8-bit LFSR state
        bit_out     : out std_logic -- key bit
    );
end entity;

-- The LFSR generates a pseudorandom key bit stream.
architecture rtl of lfsr is
    signal state    : std_logic_vector(7 downto 0);
    signal feedback : std_logic;
begin
    feedback <= state(7) xor state(5) xor state(4) xor state(3);

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= INIT;
            elsif enable = '1' then
                -- An 8-bit Fibonacci LFSR advances by
                -- shifting and inserting a feedback bit
                state <= state (6 downto 0) & feedback;
            end if;
        end if;
    end process;

    bit_out <= state(7);
    state_out <= state;
end architecture;
