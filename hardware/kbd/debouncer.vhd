library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity debouncer is
    Port (
        CLK  : in  STD_LOGIC;
        Din  : in  STD_LOGIC;
        Dout : out STD_LOGIC := '0'
    );
end entity;

architecture Behavioral of debouncer is

signal counter: integer range 0 to 10000000 := 0;
signal last_d: STD_LOGIC := '0';

begin

process(CLK)
begin

    if (CLK = '1' and CLK'event) then

        if (Din /= last_d) then
            if (counter = 100) then
                counter <= 0;
                last_d  <= Din;
                Dout    <= Din;
            else
                counter <= counter + 1;
            end if;
        else
            counter <= 0;
        end if;

    end if;

end process;


end architecture;
