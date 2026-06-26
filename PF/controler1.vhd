library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controler1 is
    port (
        clk         : in std_logic; -- System clock
        rst         : in std_logic; -- Active-high synchronous reset
        start       : in std_logic; -- Pulse to begin streaming
        rom_data    : in std_logic_vector(7 downto 0); -- Byte from ROM
        busy        : out std_logic; -- High while streaming samples
        done        : out std_logic; -- High after 64 bytes transmitted
        rom_addr    : out std_logic_vector(5 downto 0); -- Current ROM address
        tx_line     : out std_logic -- UART serial output
    );
end entity controler1;
--  controler1 reads ROM, encrypts each byte, and sends via UART_8
architecture rtl of controler1 is
    type state_t is (IDLE, S_START, NXT_BYTE, ENC, CRC, STOP, S_DONE);
    signal state            : state_t;

    signal enc_enable, enc_din, enc_out : std_logic := '0';
    signal byte_shift : std_logic_vector(7 downto 0); -- hold byte(s)
    signal enc_cyc  : integer range 0 to 7;
    
    signal tx_start, rx_line, rx_valid : std_logic;
    signal enc_byte : std_logic_vector(7 downto 0);
begin
    encrypter: entity work.stream_cipher
    port map(
        clk => clk,
        rst => rst,
        enable => enc_enable,
        din => enc_din,
        dout => enc_out
    );
    uart: entity work.uart_8
    port map (
        clk => clk, rst => rst, tx_start => tx_start,
        rx_data => enc_byte, tx_data => enc_byte, -- R/T encrypted byte
        -- tx_busy => tx_busy,
        tx_line => tx_line, rx_line => rx_line, rx_valid => rx_valid
    );

    enc_din <= byte_shift(0); -- cipher encrypts from LSB

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rom_addr <= (others => '0');
                state <= IDLE;
                busy <= '0';
                done <= '0';
            else
                case state is
                    when IDLE =>
                        if start = '1' then
                            state <= NXT_BYTE;
                            busy <= '1';
                        end if;

                    when NXT_BYTE =>
                        state <= ENC;
                        byte_shift <= rom_data; -- capture rom data byte
                        enc_enable <= '1'; -- start encryption of byte
                        rx_line <= '0'; -- start UART receival of encrypted (1-cycle offset)

                    when ENC =>
                        rx_line <= enc_out; -- UART receives encrypted byte
                        if enc_cyc = 7 then
                            enc_enable <= '0';
                            enc_cyc <= 0;
                            state <= CRC;
                        else
                            byte_shift <= byte_shift srl 1;
                            enc_cyc <= enc_cyc + 1;
                        end if;

                    when CRC => -- wait crc bit
                        rx_line <= '1'; -- emit stop bit
                        state <= STOP;
                        
                    when STOP =>
                        if unsigned(rom_addr) = 63 then -- last read
                            state <= S_DONE;
                            done <= '1';
                        else
                            state <= S_START;
                            -- Controller advances the ROM address
                            rom_addr <= std_logic_vector(unsigned(rom_addr) + 1);
                        end if;
                        tx_start <= '1'; -- trigger transmission
                        -- 1 cycle before this encrypted byte is looped back
                        -- into TX, so it's sampled as soon as available
                        -- after the low start bit is emitted
                        
                    when S_START => -- sync with TX start of previous byte
                        state <= NXT_BYTE;

                    when S_DONE => -- finished processing
                        tx_start <= '0';
                        state <= IDLE;
                        busy <= '0';
                        done <= '0';
                        
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
