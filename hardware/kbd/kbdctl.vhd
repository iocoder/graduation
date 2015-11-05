library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity kbdctl is
    Port (
        -- Crystal:
        CLK     : in  STD_LOGIC;
        -- Inputs from PS/2 keyboard:
        PS2CLK  : in  STD_LOGIC;
        PS2DATA : in  STD_LOGIC;
        -- Output:
        LED     : out STD_LOGIC_VECTOR (7 downto 0);
        -- System bus interface:
        EN      : in  STD_LOGIC;
        RW      : in  STD_LOGIC;
        DATA    : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        RDY     : out STD_LOGIC := '0';
        -- Interrupt Logic:
        INT     : out STD_LOGIC := '0';
        IAK     : in  STD_LOGIC
    );
end entity;

architecture Behavioral of kbdctl is

component debouncer is
    Port (
        CLK  : in  STD_LOGIC;
        Din  : in  STD_LOGIC;
        Dout : out STD_LOGIC := '0'
    );
end component;

component ps2 is
    Port (
        -- Crystal:
        CLK     : in  STD_LOGIC;
        -- Inputs from PS/2 keyboard:
        PS2CLK  : in  STD_LOGIC;
        PS2DATA : in  STD_LOGIC;
        -- Outputs
        SENSE   : out STD_LOGIC;
        PACKET  : out STD_LOGIC_VECTOR (7 downto 0)
    );
end component;


signal PS2CLKD   : STD_LOGIC;
signal SENSE     : STD_LOGIC := '0';
signal LASTSENSE : STD_LOGIC := '0';
signal LASTEN    : STD_LOGIC := '0';
signal PACKET    : STD_LOGIC_VECTOR (7 downto 0) := x"00";
signal IOPORT    : STD_LOGIC_VECTOR (7 downto 0) := x"00";

begin

D: debouncer port map (CLK, PS2CLK, PS2CLKD);
K: ps2       port map (CLK, PS2CLKD, PS2DATA, SENSE, PACKET);

LED  <= PACKET;

process (CLK)
begin
    if (CLK = '1' and CLK'event ) then
        if (SENSE = '1') then
            LASTSENSE <= '1';
        else
            LASTSENSE <= '0';
        end if;

        if (EN = '1') then
            LASTEN <= '1';
        else
            LASTEN <= '0';
        end if;

        if (SENSE = '1' and LASTSENSE = '0') then
            -- a scancode has arrived
            IOPORT <= PACKET;        -- save a copy of the scancode
            if (EN = '1') then
                DATA <= PACKET;
            end if;
        elsif (EN = '1' and LASTEN = '0') then
            -- data cycle started
            DATA   <= IOPORT;        -- output IOPORT register
        elsif (EN = '0' and LASTEN = '1') then
            -- data cycle ended
            DATA   <= x"00";
            IOPORT <= x"00";         -- invalidate buffer
        end if;
    end if;
end process;

end architecture;
