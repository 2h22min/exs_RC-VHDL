library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controler2 is
    port (
        clk         : in std_logic; -- System clock
        rst         : in std_logic; -- Active-high synchronous reset
        rx_line     : in std_logic; -- UART serial input
        busy        : out std_logic; -- High while receiving/processing samples
        done        : out std_logic; -- High after final sample processed
        ram_we      : out std_logic; -- RAM write enable for averaged data
        ram_addr    : out std_logic_vector(5 downto 0); -- RAM address (0 to 56)
        ram_din     : out std_logic_vector(7 downto 0); -- Averaged output data
        crc_error_seen : out std_logic -- Latched if any UART CRC error occurs.
    );
end entity controler2;

architecture rtl of controler2 is
    type state_t is (IDLE, DEC, S_SUM, S_DONE);
    signal state                    : state_t;
    type sr_type is array (7 downto 0) of std_logic_vector(7 downto 0);
    signal window_buffer            : sr_type := (others => (others => '0'));
    signal n_in_buffer              : integer range 0 to 8;
    signal sum                      : unsigned(10 downto 0) := (others => '0');

    signal dec_enable, dec_din, dec_out : std_logic;
    signal byte_shift, dec_byte, tx_data, rx_data : std_logic_vector(7 downto 0); -- hold byte(s)
    signal dec_cyc  : integer range 0 to 8;
    
    signal tx_start, rx_valid : std_logic;
begin
    decrypter: entity work.stream_cipher
    port map(
        clk => clk,
        rst => rst,
        enable => dec_enable,
        din => dec_din,
        dout => dec_out
    );
    uart: entity work.uart_8
    port map (
        clk => clk, rst => rst,
        tx_start => tx_start, tx_data => tx_data,
        rx_line => rx_line, rx_data => rx_data,
        rx_valid => rx_valid,
        crc_error => crc_error_seen
    );

    dec_din <= byte_shift(0); -- cipher decrypts from LSB
    -- After 8 decrypted samples are available, begin to
    -- write one averaged value per cycle to RAM.
    -- Rolling average is computed as a
    -- running sum divided by 8 (right shift by 3)
    ram_din <= std_logic_vector(resize(sum srl 3, 8));
    
    process (clk)
        variable sum_next   : unsigned(10 downto 0);
        variable new_sample, old_sample : std_logic_vector(7 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ram_addr <= (others => '0');
                state <= IDLE;
                dec_enable <= '0';
                busy <= '0';
                done <= '0';
                sum <= (others => '0');
                sum_next := (others => '0');
            else
                case state is
                    when IDLE =>
                        if rx_valid = '1' then
                            state <= DEC;
                            busy <= '1';
                            byte_shift <= rx_data; -- capture rx byte
                            dec_enable <= '1'; -- start decryption of byte
                        end if;
                        if ram_we = '1' then
                            -- Advance the RAM address when writing
                            ram_addr <= std_logic_vector(unsigned(ram_addr) + 1);
                            ram_we <= '0'; -- disable until next decrypted byte
                        end if;

                    when DEC =>
                        dec_byte <= dec_out & dec_byte(7 downto 1);
                        if dec_cyc = 7 then -- disables cipher after 8 cycles
                            dec_enable <= '0';
                        end if;
                        if dec_cyc < 8 then
                            byte_shift <= byte_shift srl 1;
                            dec_cyc <= dec_cyc + 1;
                        else -- flush cycle to capture final bit
                            dec_cyc <= 0;
                            state <= S_SUM;
                        end if;

                    when S_SUM =>
                        new_sample := dec_byte;
                        old_sample := window_buffer(7);
                        window_buffer <= window_buffer(6 downto 0) & dec_byte;
                        -- Update running sum
                        sum_next := sum + resize(unsigned(new_sample), 11) - resize(unsigned(old_sample), 11);
                        sum <= sum_next;
                        if n_in_buffer = 7 then
                            ram_we <= '1'; -- when buffer is full, write to RAM
                        else
                            n_in_buffer <= n_in_buffer + 1;
                        end if;
                        if unsigned(ram_addr) = 56 then -- last write
                            state <= S_DONE;
                            done <= '1';
                        else
                            state <= IDLE;
                        end if;

                    when S_DONE => -- finished processing
                        state <= IDLE;
                        busy <= '0';
                        done <= '0';
                        
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
