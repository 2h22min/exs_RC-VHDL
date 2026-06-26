library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pipeline is
end entity;

architecture sim of tb_pipeline is
    constant CLK_PERIOD : time := 10 ns;

    signal clk, rst, start, busy, done, ram_we, sr_enable, window_full : std_logic := '0';
    signal rom_addr, ram_addr : std_logic_vector(5 downto 0) := (others => '0');
    signal rom_data, ram_din, new_sample, old_sample : std_logic_vector(7 downto 0);
    signal average : unsigned(7 downto 0);
    signal rst, tx_busy, tx_line, rx_line, rx_valid, crc_error : std_logic;
begin
    clk <= not clk after CLK_PERIOD / 2;

    rom: entity work.rom_64x8 port map (addr => rom_addr, data => rom_data);
    ram: entity work.ram_57x8
        port map (clk => clk, we => ram_we, addr => ram_addr, din => ram_din);
    controler1: entity work.controler1
    port map (
        clk => clk, rst => rst,
        start => start, busy => busy, done => done,
        rom_data => rom_data, rom_addr => rom_addr,
        tx_line => tx_line
    );

    stim: process
    begin
        rst <= '1'; wait until falling_edge(clk); wait until falling_edge(clk);
        rst <= '0';
        wait until rising_edge(clk); start <= '1';
        wait until rising_edge(clk); start <= '0';

        wait until rising_edge(done);
        -- The testbench stops the simulation after done is observed
        wait until falling_edge(done);
        wait until falling_edge(clk);
        assert false report "Simulation finished successfully" severity failure;
    end process;
end architecture;
