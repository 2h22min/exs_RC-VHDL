library ieee;
use ieee.std_logic_1164.all;

entity seq_detector is
    port (
        clk     : in std_logic ;
        rst     : in std_logic ;
        din     : in std_logic ;
        detect  : out std_logic
    ) ;
end entity;

architecture rtl of seq_detector is
    -- Moore FSM for 8-bit target pattern : 11011011
    type state_t is (S0, S1, S11, S110, S1101, S11011, S110110, S1101101, S11011011) ;
    signal state , next_state : state_t ;
begin
    -- Synchronous state register
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                --  synchronous reset
                state <= S0;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    -- next_state and detect logic
    process (state, din)
    begin
        next_state <= S0;
        detect <= '0';

        case state is

            when S0 =>
                if din = '1' then
                    next_state <= S1;
                else
                    next_state <= S0;
                end if;
                
            when S1 =>
                if din = '1' then
                    next_state <= S11;
                else
                    next_state <= S0;
                end if;
                
            when S11 =>
                if din = '0' then
                    next_state <= S110;
                else
                    next_state <= S11;
                end if;
                
            when S110 =>
                if din = '1' then
                    next_state <= S1101;
                else
                    next_state <= S0;
                end if;
                
            when S1101 =>
                if din = '1' then
                    next_state <= S11011;
                else
                    next_state <= S0;
                end if;
                
            when S11011 =>
                if din = '0' then
                    next_state <= S110110;
                else
                    next_state <= S11;
                end if;
                
            when S110110 =>
                if din = '1' then
                    next_state <= S1101101;
                else
                    next_state <= S0;
                end if;
                
            when S1101101 =>
                if din = '1' then
                    next_state <= S11011011;
                else
                    next_state <= S0;
                end if;
                
            when S11011011 =>
                detect <= '1';
                if din = '0' then
                    next_state <= S110110;
                else
                    next_state <= S11;
                end if;

        end case;
    end process;
end architecture;
