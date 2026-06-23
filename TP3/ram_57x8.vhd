library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_57x8 is
    port (
        clk     : in std_logic; -- System clock
        we      : in std_logic; -- Write enable (asserted when an average is valid)
        addr    : in std_logic_vector(5 downto 0); -- 6-bit write address (0 to 56)
        din     : in std_logic_vector(7 downto 0) -- 8-bit averaged output data
    );
end entity;

architecture rtl of ram_57x8 is
    type ram_t is array (0 to 56) of std_logic_vector(7 downto 0);
    signal ram : ram_t := (others => (others => '0'));
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(to_integer(unsigned(addr))) <= din;
            end if;
        end if;
    end process;
end architecture;
