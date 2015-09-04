library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library WORK;
use WORK.LOOKUP_PKG.ROM;

entity lookup is
    Port ( CLK     : in  STD_LOGIC;
           ADDRESS : in  STD_LOGIC_VECTOR ( 7 downto 0);
           DATA    : out STD_LOGIC_VECTOR (15 downto 0) := x"0000"
    );
end lookup;

architecture Behavioral of lookup is

begin

process (clk)
begin

    if (clk = '1' and clk'event) then

        DATA <= ROM(conv_integer(unsigned(ADDRESS)));

    end if;

end process;

end Behavioral;
