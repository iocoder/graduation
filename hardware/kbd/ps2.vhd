library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ps2 is
    Port (
        -- Crystal:
        CLK     : in  STD_LOGIC;
        -- Inputs from PS/2 keyboard:
        PS2CLK  : in  STD_LOGIC;
        PS2DATA : in  STD_LOGIC;
        -- Outputs
        SENSE   : out STD_LOGIC;
        PACKET  : out STD_LOGIC_VECTOR (7 downto 0) := x"00"
    );
end entity;

architecture Behavioral of ps2 is

signal LAST_CLK   : STD_LOGIC := '0';
signal SENSE_VAL  : STD_LOGIC := '0';
signal PACKET_VAL : STD_LOGIC_VECTOR (7 downto 0) := x"00";
signal counter    : integer range 0 to 15 := 0;
signal waiting    : integer range 0 to 1000000 := 0;

begin

    process (CLK)
    begin
        if (CLK = '1' and CLK'event) then
            if (PS2CLK = '0' and LAST_CLK = '1') then
                if (counter = 0) then
                    -- zero starting bit
                    counter <= counter + 1;
                elsif (counter < 9) then
                    -- packer data
                    PACKET_VAL(counter-1) <= PS2DATA;
                    counter   <= counter + 1;
                elsif (counter = 9) then
                    -- parity
                    SENSE     <= '1';
                    PACKET    <= PACKET_VAL;
                    counter   <= 10;
                elsif (counter = 10) then
                    -- stopping bit.
                    SENSE     <= '0';
                    counter   <= 0;
                elsif (counter = 11) then
                    -- wait for both CLK and DATA to be high.
                    if (PS2CLK = '1' and PS2DATA = '1') then
                        if (waiting = 10000) then
                            waiting <= 0;
                            counter <= 0;
                        else
                            waiting <= waiting+1;
                        end if;
                    else
                        waiting <= 0;
                    end if;
                end if;
            end if;
            LAST_CLK <= PS2CLK;
        end if;
    end process;

end architecture;
