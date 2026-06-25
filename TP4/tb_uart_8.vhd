library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_8 is
end entity;

architecture sim of tb_uart_8 is
    constant CLK_PERIOD : time := 10 ns;

    signal clk, tx_start, inject_active : std_logic := '0';
    signal rst, tx_busy, tx_line, rx_line, rx_valid, crc_error : std_logic;
    signal tx_data, rx_data : std_logic_vector(7 downto 0) := (others => '0');
begin
    clk <= not clk after CLK_PERIOD / 2;
    -- loop tx_line back into rx_line and inject CRC fault
    rx_line <= tx_line xor inject_active;

    uart: entity work.uart_8
    port map (
        clk => clk, rst => rst,
        tx_start => tx_start, tx_data => tx_data, tx_busy => tx_busy,
        tx_line => tx_line, rx_line => rx_line,
        rx_data => rx_data, rx_valid => rx_valid, crc_error => crc_error
    );

    stim: process
    begin
        rst <= '1'; wait for 20 ns;
        rst <= '0'; wait for 20 ns;
        -- Two transmissions are performed:
        -- • A correct frame to validate data and CRC behavior.
        wait until rising_edge(clk); tx_start <= '1';
        tx_data <= "10100101";
        wait until rising_edge(clk); tx_start <= '0';
        wait for CLK_PERIOD * 11; tx_start <= '1';
        wait for 1 ns; assert rx_data = tx_data
            report "rx_data did not match the first payload"
            severity error;
        assert crc_error = '0'
            report "crc_error was not only asserted for the corrupted frame (was earlier)"
            severity error;
        assert rx_valid = '1' severity error;
        -- • A second frame where the CRC bit is inverted on the wire to force an error.
        tx_data <= "00111100";
        wait until rising_edge(clk); tx_start <= '0';
        wait for CLK_PERIOD * 9; inject_active <= '1';
        wait until rising_edge(clk); inject_active <= '0';
        wait until rising_edge(clk); wait for 1 ns;
        assert rx_data = tx_data
            report "rx_data did not match the second payload"
            severity error;
        assert crc_error = '1'
            report "crc_error was not asserted for the corrupted frame"
            severity error;
        assert rx_valid = '0' severity error;

        wait for 20 ns; assert false
            report "Simulation finished successfully" severity failure;
    end process;
end architecture;
