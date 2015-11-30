library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pit is
    Port (
        CLK      : in    STD_LOGIC;
        IRQ      : out   STD_LOGIC := '0';
        IAK      : in    STD_LOGIC;
        CS       : in    STD_LOGIC;
        RW       : in    STD_LOGIC; -- 0: read, 1: write
        Din      : in    STD_LOGIC_VECTOR (31 downto 0);
        Dout     : out   STD_LOGIC_VECTOR (31 downto 0);
        DTYPE    : in    STD_LOGIC_VECTOR ( 2 downto 0);
        RDY      : out   STD_LOGIC := '1');
end pit;

architecture Behavioral of pit is

signal count : integer range 0 to 1000000000 := 0;
signal cur   : integer range 0 to 1000000000 := 0;
signal irqen : boolean := false;

begin

process (CLK)

begin

    if ( CLK = '1' and CLK'event ) then

        -- update counter
        if (cur = count) then
            cur <= 0;
        else
            cur <= cur + 1;
        end if;

        -- interrupt pin
        if (count = 0) then
            IRQ <= '0';
        elsif (cur = count and irqen) then
            IRQ <= '1';
        elsif (IAK = '1') then
            IRQ <= '0';
        end if;

        -- bus interface
        if (CS = '1') then
            if (RW = '1') then
                count <= to_integer(unsigned(Din));
                irqen <= true;
            else
                Dout  <= std_logic_vector(to_unsigned(cur, 32));
            end if;
        else
            Dout <= x"00000000";
        end if;

    end if;

end process;

end Behavioral;
