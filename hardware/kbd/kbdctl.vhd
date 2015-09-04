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
        -- Outputs to LED:
        LED     : out STD_LOGIC_VECTOR (7 downto 0);
        -- System bus interface:
        EN      : in  STD_LOGIC;
        RW      : in  STD_LOGIC;
        DATA    : out STD_LOGIC_VECTOR (7 downto 0);
        -- Interrupt Logic:
        INT     : out STD_LOGIC;
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


signal PS2CLKD  : STD_LOGIC;
signal PS2DATAD : STD_LOGIC;
signal SENSE    : STD_LOGIC := '0';
signal PACKET   : STD_LOGIC_VECTOR (7 downto 0) := x"00";

begin

D: debouncer port map (CLK, PS2CLK, PS2CLKD);
K: ps2       port map (CLK, PS2CLKD, PS2DATA, SENSE, PACKET);

DATA <= PACKET when EN = '1' and RW = '0' else x"00";

process (SENSE, IAK)
begin
    if (SENSE = '1') then
        INT <= '1';
    elsif (IAK = '1') then
        INT <= '0';
    end if;
end process;

end architecture;
