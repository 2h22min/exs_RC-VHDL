library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_rolling_average is
end entity;

architecture sim of tb_rolling_average is
    constant CLK_PERIOD : time := 10 ns;
    constant RAM_DEPTH  : integer := 57;

    signal clk, rst, start, busy, done, ram_we, sr_enable, window_full : std_logic := '0';
    signal rom_addr, ram_addr : std_logic_vector(5 downto 0) := (others => '0');
    signal rom_data, ram_din, new_sample, old_sample : std_logic_vector(7 downto 0);
begin
    clk <= not clk after CLK_PERIOD / 2;

    rom: entity work.rom_64x8 port map (addr => rom_addr, data => rom_data);
    ram: entity work.ram_57x8
        port map (clk => clk, we => ram_we, addr => ram_addr, din => ram_din);
    controller: entity work.controller
    generic map (
        RAM_DEPTH => RAM_DEPTH
    )
    port map (
        clk => clk, rst => rst,
        start => start, busy => busy, done => done,
        rom_data => rom_data, rom_addr => rom_addr, -- streams 64 samples and
        ram_we => ram_we, ram_addr => ram_addr, ram_din => ram_din  -- writes 57 outputs
    );

    tb_window: entity work.window_buffer_8x8
        port map(
            clk => clk,
            enable => sr_enable,
            sr_in => new_sample,
            sr_out => old_sample,
            full => window_full
        );
    new_sample <= rom_data;

    stim: process
    begin
        rst <= '1'; wait until falling_edge(clk); wait until falling_edge(clk);
        rst <= '0';
        wait until rising_edge(clk); start <= '1';
        wait until rising_edge(clk); start <= '0';
        sr_enable <= '1';

        -- The testbench stops the simulation after done is observed
        wait until falling_edge(done);
        wait until falling_edge(clk);
        assert false report "Simulation finished successfully" severity failure;
    end process;

    process (rom_addr)
        variable n_streamed : integer range 0 to 64 := 0;
        variable sum, average : unsigned(10 downto 0) := (others => '0');
    begin
        if sr_enable = '1' then
            assert busy = '1' report "busy was not high while processing sample " & integer'image(n_streamed) severity error;
            n_streamed := n_streamed + 1;
            sum := sum + resize(unsigned(new_sample), 11) - resize(unsigned(old_sample), 11);
            if window_full = '1' then
                -- The system introduces a warm-up latency of 7 samples before the first output is written
                assert ram_we = '1'
                    report "ram_we was not high after the window became full"
                    severity error;
                assert n_streamed >= 8
                    report "window full before streaming 8 samples"
                    severity error;
                -- ram_addr increments correctly from 0 to 56
                assert to_integer(unsigned(ram_addr)) + 8 = n_streamed;

                -- Compute the expected rolling average
                average := sum srl 3;
                -- Verify written average matches expected
                assert (unsigned(ram_din) = resize(average, 8))
                    report "ram_din did not match expected average " & integer'image(to_integer(average))
                    severity error;
            end if;
        end if;
    end process;
end architecture;
