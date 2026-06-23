library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
    generic (RAM_DEPTH : integer);
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
        ram_din     : out std_logic_vector(7 downto 0) -- Averaged output data
    );
end entity controller;

architecture rtl of controller is
    type state_t is (Sidle, Sbusy, Sdone);
    signal state                    : state_t;
    signal new_sample, old_sample   : std_logic_vector(7 downto 0);
    signal sr_enable, window_full   : std_logic;
    signal sum                      : unsigned(10 downto 0) := (others => '0');
    -- max sum of 8 8-bit samples needs 11 bits (3 left shifts)
begin
    window: entity work.window_buffer_8x8
        port map(
            clk => clk,
            enable => sr_enable,
            sr_in => new_sample,
            sr_out => old_sample,
            full => window_full
        );
    sr_enable <= '1' when state = Sbusy else '0';
    -- ram_we stays low until the window is full (warm-up latency)
    ram_we <= '1' when window_full = '1' else '0';
    -- Read ROM sample and buffer in window
    new_sample <= rom_data;
    
    -- After the first 8 samples, the controller writes
    -- one averaged value per cycle to a RAM.
    -- Rolling average is computed as a
    -- running sum (updated each cycle) divided by 8 (right shift by 3)
    ram_din <= std_logic_vector(resize(sum srl 3, 8));
    
    process (clk)
        variable sum_next   : unsigned(10 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rom_addr <= (others => '0');
                ram_addr <= (others => '0');
                state <= Sidle;
                busy <= '0';
                done <= '0';
                sum <= (others => '0');
                sum_next := (others => '0');
            else
                case state is
                    when Sidle =>
                        if start = '1' then -- trigger run
                            state <= Sbusy;
                            busy <= '1';
                        end if;

                    when Sbusy => -- Each cycle after start
                        -- Update running sum
                        sum_next := sum + resize(unsigned(new_sample), 11) - resize(unsigned(old_sample), 11);
                        sum <= sum_next;
                        if unsigned(ram_addr) = RAM_DEPTH-1 then -- last write
                            state <= Sdone;
                            done <= '1';
                        else
                            -- Controller advances the ROM address
                            rom_addr <= std_logic_vector(unsigned(rom_addr) + 1);
                            -- and the RAM address when writing
                            if window_full = '1' then
                                ram_addr <= std_logic_vector(unsigned(ram_addr) + 1);
                            end if;
                        end if;

                    when Sdone => -- finished processing
                        state <= Sidle;
                        busy <= '0';
                        done <= '0';
                        
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
