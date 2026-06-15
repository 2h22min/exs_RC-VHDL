library ieee;
use ieee.std_logic_1164.all;

entity tb_rolling_average is
end entity;

architecture sim of tb_rolling_average is
    constant CLK_PERIOD : time := 10 ns;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal start    : std_logic := '0';
    signal busy     : std_logic := '0';
    signal done     : std_logic := '0';
    signal ram_we   : std_logic := '0';
    signal rom_addr : std_logic_vector(5 downto 0) := "000000";
    signal ram_addr : std_logic_vector(5 downto 0) := "000000";
    signal rom_data : std_logic_vector(7 downto 0);
    signal ram_din  : std_logic_vector(7 downto 0);
begin
    clk <= not clk after CLK_PERIOD / 2;

    rom: entity work.rom_64x8 port map (addr => rom_addr, data => rom_data);
    ram: entity work.ram_57x8
        port map (clk => clk, we => ram_we, addr => ram_addr, din => ram_din);
    controller: entity work.controller
    port map (
        clk => clk, rst => rst,
        start => start, busy => busy, done => done,
        rom_data => rom_data, rom_addr => rom_addr,
        ram_we => ram_we, ram_addr => ram_addr, ram_din => ram_din
    );

    stim: process
    begin
        rst <= '1'; wait until falling_edge(clk); wait until falling_edge(clk);
        rst <= '0';
        
        -- (WIP)
        
        -- Controller streams 64 samples and writes 57 outputs.
        -- The system introduces a warm-up latency of 7 samples before the first output is written.
        -- It computes the expected rolling average in the testbench and asserts that:
        -- • ram we is only asserted after the window is full.
        -- • ram din matches the expected average.
        -- • ram addr increments correctly from 0 to 56.
        -- Use clear assertion messages to identify mismatches.
    end process;

    process (done)
    begin
        -- The testbench stops the simulation after done is observed
        if done = '1' then
            wait until falling_edge(done); wait until falling_edge(clk);
            assert false report "Simulation finished successfully" severity failure;
        end if;
    end process;
end architecture;
