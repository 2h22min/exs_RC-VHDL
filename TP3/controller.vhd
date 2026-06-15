library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
    port (
        clk         : in std_logic; -- System clock
        rst         : in std_logic; -- Active-high synchronous reset
        start       : in std_logic; -- Pulse to begin processing (advancing rom_addr)
        rom_data    : in std_logic_vector(7 downto 0); -- 8-bit ROM sample input
        busy        : out std_logic; -- High while processing all samples
        done        : out std_logic; -- Pulses high when the run completes (last write)
        rom_addr    : out std_logic_vector(5 downto 0); -- Current ROM address
        ram_we      : out std_logic; -- RAM write enable
        ram_addr    : out std_logic_vector(5 downto 0); -- RAM write address
        ram_din     : out std_logic_vector(7 downto 0); -- Averaged output data
    );
end entity controller;

architecture rtl of controller is
    signal new_sample, old_sample   : std_logic_vector(7 downto 0);
    variable sum_next, sum, average : unsigned(10 downto 0) := 0; -- max sum of 8 8-bit samples needs 11 bits (3 left shifts)
begin
    window: entity work.window_buffer_8x8
        port map(
            clk => clk,
            enable => sr_enable,
            sr_in => new_sample,
            sr_out => old_sample,
            full => window_full
        );
    
    -- ram_we stays low until the window is full (warm-up latency)
    ram_we <= '1' when window_full = '1' else '0';
    
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                busy <= '0';
                sr_enable <= '0';
                
            elsif done = '1' then
                busy <= 0; -- finished processing
                done <= '0';
                
            elsif busy = '1' then -- Each cycle after start
                -- Read ROM sample and buffer in window
                new_sample <= rom_data;
                -- Controller advances the ROM address
                rom_addr <= std_logic_vector(unsigned(rom_addr) + 1);
                -- Update running sum
                sum := sum_next;
                sum_next := sum + resize(unsigned(new_sample), 11) - resize(unsigned(old_sample), 11);
                -- Once the window is full, writes the average to RAM
                if window_full = '1' then
                    -- After the first 8 samples, the controller writes one
                    -- averaged value per cycle to a RAM.
                    -- Rolling average is computed as an integer division by 8 (right shift by 3)
                    average := sum_next >> 3;
                    ram_din <= std_logic_vector(resize(average, 8));
                    -- Advance the RAM address
                    ram_addr <= std_logic_vector(unsigned(ram_addr) + 1);
                end if;
            else
                wait until rising_edge(start); -- trigger run
                busy <= '1';
                start <= '0';
                sr_enable <= '1';
            end if;
        end if;
    end process;
end architecture rtl;

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
    type sr_type is array (0 to 7)
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
