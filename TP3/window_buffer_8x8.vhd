library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- A window buffer stores the last 8 samples read
entity window_buffer_8x8 is
    port (
        clk     : in std_logic;
        enable  : in std_logic;
        sr_in   : in std_logic_vector(7 downto 0);
        sr_out  : out std_logic_vector(7 downto 0);
        full    : out std_logic
    );
end entity window_buffer_8x8;

-- The window is a shift register of 8 samples
-- based on: https://vhdlwhiz.com/shift-register/
architecture slicing of window_buffer_8x8 is
    type sr_type is array (7 downto 0)
        of std_logic_vector(7 downto 0);
    signal sr : sr_type := (others => (others => '0'));
    signal n_stored : integer range 0 to 8;
begin
    full <= '1' when n_stored = 8 else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                sr <= sr(sr'high - 1 downto sr'low) & sr_in;
                sr_out <= sr(sr'high);

                if n_stored < 8 then
                    n_stored <= n_stored + 1;
                end if;
            end if;
        end if;
    end process;
end architecture slicing;
