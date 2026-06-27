library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pipeline is
end entity;

architecture sim of tb_pipeline is
    constant CLK_PERIOD : time := 10 ns;

    signal clk, rst, start : std_logic := '0';
    signal ctrl1_busy, ctrl1_done, ctrl2_busy, ctrl2_done, line, ram_we, crc_error : std_logic;
    signal rom_addr, ram_addr : std_logic_vector(5 downto 0);
    signal rom_data, ram_din : std_logic_vector(7 downto 0);
begin
    clk <= not clk after CLK_PERIOD / 2;

    rom: entity work.rom_64x8 port map (addr => rom_addr, data => rom_data);
    ram: entity work.ram_57x8
        port map (clk => clk, we => ram_we, addr => ram_addr, din => ram_din);
    controler1: entity work.controler1
    port map (
        clk => clk, rst => rst,
        start => start, busy => ctrl1_busy, done => ctrl1_done,
        rom_data => rom_data, rom_addr => rom_addr,
        tx_line => line
    );
    controler2: entity work.controler2
    port map (
        clk => clk, rst => rst, rx_line => line,
        busy => ctrl2_busy, done => ctrl2_done,
        ram_we => ram_we, ram_addr => ram_addr, ram_din => ram_din,
        crc_error_seen => crc_error
    );

    stim: process
    begin
        rst <= '1'; wait until falling_edge(clk); wait until falling_edge(clk);
        rst <= '0';
        wait until rising_edge(clk); start <= '1';
        wait until rising_edge(clk); start <= '0';

        -- The testbench stops the simulation after done is observed
        wait until falling_edge(ctrl2_done);
        wait until falling_edge(clk);
        assert false report "Simulation finished successfully" severity failure;
    end process;
end architecture;
