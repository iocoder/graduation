library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clkgen is
    Port (CLK       : in  STD_LOGIC;
          CLK_56MHz : out STD_LOGIC;
          CLK_50MHz : out STD_LOGIC;
          CLK_28MHz : out STD_LOGIC;
          CLK_25MHz : out STD_LOGIC);
end clkgen;

architecture Behavioral of clkgen is

signal oCLK_56MHz : STD_LOGIC := '0';
signal oCLK_50MHz : STD_LOGIC := '0';
signal oCLK_28MHz : STD_LOGIC := '0';
signal oCLK_25MHz : STD_LOGIC := '0';

begin

-- generate 50MHz clock
oCLK_50MHz <= CLK;

-- generate 25MHz clock
process(oCLK_50MHz)
begin
    if (oCLK_50MHz = '1' and oCLK_50MHz'event ) then
        oCLK_25MHz <= NOT oCLK_25MHz;
    end if;
end process;

-- generate 56MHz clock
oCLK_56MHz <= oCLK_50MHz; -- just for simulation

-- generate 28MHz clock
process(oCLK_56MHz)
begin
    if (oCLK_56MHz = '1' and oCLK_56MHz'event ) then
        oCLK_28MHz <= NOT oCLK_28MHz;
    end if;
end process;

-- connect generated clock frequencies to outputs
CLK_56MHz <= oCLK_56MHz;
CLK_50MHz <= oCLK_50MHz;
CLK_28MHz <= oCLK_28MHz;
CLK_25MHz <= oCLK_25MHz;

end Behavioral;
