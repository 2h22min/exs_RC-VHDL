library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_8 is
    port (
        clk         : in std_logic; -- One rising edge equals one bit time
        rst         : in std_logic; -- Active-high synchronous reset
        tx_start    : in std_logic; -- Pulse high to start transmitting tx_data
        tx_data     : in std_logic_vector(7 downto 0); -- 8-bit payload to transmit
        tx_busy     : out std_logic; -- High while TX is emitting a frame
        tx_line     : out std_logic; -- Serial line output (idle-high)
        rx_line     : in std_logic; -- Serial line input (idle-high)
        rx_data     : out std_logic_vector(7 downto 0); -- Received 8-bit payload
        rx_valid    : out std_logic; -- Pulses high when a frame is accepted
        crc_error   : out std_logic -- High for one cycle on CRC or stop-bit error
    );
end entity;

architecture rtl of uart_8 is
    -- TX and RX FSM states
    type state_t is (IDLE, START, DATA, CRC, STOP);
    signal tx_state, rx_state : state_t := IDLE;
    signal tx_shift : std_logic_vector(7 downto 0); -- holds tx_data captured
    signal rx_shift : std_logic_vector(7 downto 0); -- samples read bits
    signal tx_crc   : std_logic; -- XOR reduction of the payload computed at the start of transmission
    signal rx_crc   : std_logic; -- recomputed while sampling the data bits to compare
    signal tx_data_bit, rx_data_bit : integer range 0 to 7;
    
    function xor_reduce(v : std_logic_vector) return std_logic is
        variable r : std_logic := '0';
    begin
        for i in v'range loop
            r := r xor v(i);
        end loop;
        return r;
    end function;
begin
    with tx_state select
        tx_line <=  '1'                 when IDLE,
                    '0'                 when START, -- start bit
                    tx_shift(tx_data_bit)  when DATA, -- emits LSB first
                    tx_crc              when CRC, -- crc bit
                    '1'                 when STOP; -- stop bit
    tx_busy <= '0' when tx_state = IDLE else '1'; -- remains asserted during transmission sequence

    transmitter: process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                tx_state <= IDLE;
            else
                case tx_state is
                    when IDLE =>
                        if tx_start = '1' then -- trigger transmission
                            tx_state <= START;
                        end if;

                    when START =>
                        -- Capture tx data
                        tx_shift <= tx_data;
                        tx_crc <= xor_reduce(tx_data);

                        tx_state <= DATA;
                        tx_data_bit <= 0;

                    when DATA =>
                        -- Advance one state per clock through the 8 data bits
                        if tx_data_bit = 7 then
                            tx_data_bit <= 0;
                            tx_state <= CRC;
                        else
                            tx_data_bit <= tx_data_bit + 1;
                        end if;

                    when CRC =>
                        tx_state <= STOP;
                        
                    when STOP =>
                        tx_state <= IDLE;
                        
                end case;
            end if;
        end if;
    end process;
    
    receiver: process (clk)
        variable rx_line_crc  : std_logic; -- samples the CRC bit received
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rx_valid <= '0';
                crc_error <= '0';
                rx_state <= IDLE;
            else
                case rx_state is
                    when IDLE =>
                        if rx_line = '0' then -- watch for a low start bit
                            rx_state <= DATA;
                            rx_crc <= '0';
                        end if;
                        rx_valid <= '0';
                        crc_error <= '0';
                        
                    when DATA =>
                        -- Accumulate the XOR of the data bits
                        rx_crc <= rx_crc xor rx_line;
                        -- Sample one bit per clock
                        rx_shift <= rx_line & rx_shift(rx_shift'high downto rx_shift'low + 1);
                        if rx_data_bit = 7 then
                            rx_data_bit <= 0;
                            rx_state <= CRC;
                        else
                            rx_data_bit <= rx_data_bit + 1;
                        end if;

                    when CRC =>
                        rx_line_crc := rx_line; -- sample crc bit
                        rx_state <= STOP;
                        
                    when STOP =>
                        -- If the stop bit is high
                        if rx_line = '1' then
                            rx_valid <= '1'; -- frame accepted
                        end if;
                        if rx_crc /= rx_line_crc then -- computed CRC not match
                            crc_error <= '1'; -- pulse to flag the frame
                        end if;
                        rx_data <= rx_shift;
                        rx_state <= IDLE;
                        
                    when others =>
                        rx_state <= IDLE;
                        
                end case;
            end if;
        end if;
    end process;
end architecture;
