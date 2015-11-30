library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.cpu_pkg.all;

entity clkdiv is
    Port (
        CLK       : in  STD_LOGIC;
        -- CPU interface
        CLK50MHz  : out STD_LOGIC := '0';
        CLK25MHz  : out STD_LOGIC := '0';
        CLK2MHz   : out STD_LOGIC := '0';
        CLK1MHz   : out STD_LOGIC := '0';
        CACHE_EN  : out STD_LOGIC := '0'
    );
end entity;

architecture Behavioral of clkdiv is

signal oCLK1MHz     : STD_LOGIC := '0';
signal oCLK2MHz     : STD_LOGIC := '0';
signal oCLK12_5MHz  : STD_LOGIC := '0';
signal oCLK6_25MHz  : STD_LOGIC := '0';
signal oCLK3_150MHz : STD_LOGIC := '0';
signal oCLK1_5MHz   : STD_LOGIC := '0';
signal oCLK25MHz    : STD_LOGIC := '0';
signal oCLK50MHz    : STD_LOGIC := '0';

signal counter1MHz  : integer := 24;
signal counter2MHz  : integer := 11;

signal delay        : integer := 3;

begin

process (CLK)
begin
    if ( CLK = '1' and CLK'event ) then
        if (delay /= 0) then
            delay <= delay - 1;
        end if;
    end if;
end process;

oCLK50MHz <= CLK when delay = 0 else '0';
CACHE_EN  <= '1' when delay = 0 else '0';

process (oCLK50MHz)
begin

    if ( oCLK50MHz = '1' and oCLK50MHz'event ) then
        oCLK25MHz    <= NOT oCLK25MHz;
    end if;

    if ( oCLK25MHz = '1' and oCLK25MHz'event ) then
        oCLK12_5MHz  <= NOT oCLK12_5MHz;
    end if;

    if ( oCLK12_5MHz = '1' and oCLK12_5MHz'event ) then
        oCLK6_25MHz  <= NOT oCLK6_25MHz;
    end if;

    if ( oCLK6_25MHz = '1' and oCLK6_25MHz'event ) then
        oCLK3_150MHz  <= NOT oCLK3_150MHz;
    end if;

    if ( oCLK3_150MHz = '1' and oCLK3_150MHz'event ) then
        oCLK1_5MHz  <= NOT oCLK1_5MHz;
    end if;

    if ( oCLK50MHz = '1' and oCLK50MHz'event ) then
        if (counter2MHz = 11) then
            oCLK2MHz    <= NOT oCLK2MHz;
            counter2MHz <= 0;
        else
            counter2MHz <= counter2MHz + 1;
        end if;
    end if;

    if ( oCLK2MHz = '1' and oCLK2MHz'event ) then
        oCLK1MHz  <= NOT oCLK1MHz;
    end if;

end process;

CLK50MHz <= oCLK6_25MHz;
CLK25MHz <= oCLK3_150MHz;
CLK2MHz  <= oCLK2MHz;
CLK1MHz  <= oCLK1MHz;

end Behavioral;
