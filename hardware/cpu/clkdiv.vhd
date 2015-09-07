library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.cpu_pkg.all;

entity clkdiv is
    Port (
        CLK50MHz : in  STD_LOGIC;
        -- CPU interface
        CLK2MHz  : out STD_LOGIC;
        CLK1MHz  : out STD_LOGIC
    );
end entity;

architecture Behavioral of clkdiv is

signal oCLK1MHz    : STD_LOGIC := '0';
signal oCLK2MHz    : STD_LOGIC := '0';

signal counter1MHz : integer := 23;
signal counter2MHz : integer := 11;

begin

process (CLK50MHz)
begin

    if ( CLK50MHz = '1' and CLK50MHz'event ) then
        if (counter2MHz = 11) then
            oCLK2MHz    <= NOT oCLK2MHz;
            counter2MHz <= 0;
        else
            counter2MHz <= counter2MHz + 1;
        end if;
    end if;

    if ( CLK50MHz = '1' and CLK50MHz'event ) then
        if (counter1MHz = 23) then
            oCLK1MHz    <= NOT oCLK1MHz;
            counter1MHz <= 0;
        else
            counter1MHz <= counter1MHz + 1;
        end if;
    end if;

end process;

CLK2MHz <= oCLK2MHz;
CLK1MHz <= oCLK1MHz;

end Behavioral;
