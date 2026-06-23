library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom_64x8 is
  port (
    addr : in  std_logic_vector(5 downto 0); -- 6-bit read address (0 to 63)
    data : out std_logic_vector(7 downto 0) -- 8-bit sample output (combinational)
  );
end entity rom_64x8;

architecture rtl of rom_64x8 is
  type rom_t is array (0 to 63) of std_logic_vector(7 downto 0);
  -- To make the effect of averaging visible, the ROM contains a square wave
  constant ROM : rom_t := (
    0  => x"00", 1  => x"00", 2  => x"00", 3  => x"00",
    4  => x"00", 5  => x"00", 6  => x"00", 7  => x"00",
    8  => x"3F", 9  => x"3F", 10 => x"3F", 11 => x"3F",
    12 => x"3F", 13 => x"3F", 14 => x"3F", 15 => x"3F",
    16 => x"00", 17 => x"00", 18 => x"00", 19 => x"00",
    20 => x"00", 21 => x"00", 22 => x"00", 23 => x"00",
    24 => x"3F", 25 => x"3F", 26 => x"3F", 27 => x"3F",
    28 => x"3F", 29 => x"3F", 30 => x"3F", 31 => x"3F",
    32 => x"00", 33 => x"00", 34 => x"00", 35 => x"00",
    36 => x"00", 37 => x"00", 38 => x"00", 39 => x"00",
    40 => x"3F", 41 => x"3F", 42 => x"3F", 43 => x"3F",
    44 => x"3F", 45 => x"3F", 46 => x"3F", 47 => x"3F",
    48 => x"00", 49 => x"00", 50 => x"00", 51 => x"00",
    52 => x"00", 53 => x"00", 54 => x"00", 55 => x"00",
    56 => x"3F", 57 => x"3F", 58 => x"3F", 59 => x"3F",
    60 => x"3F", 61 => x"3F", 62 => x"3F", 63 => x"3F"
  );
begin
  data <= ROM(to_integer(unsigned(addr)));
end architecture rtl;
