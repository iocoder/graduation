library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity graphics is
    Port ( CLK        : in  STD_LOGIC;
           CS         : in  STD_LOGIC;
           WR         : in  STD_LOGIC;
           A          : in  STD_LOGIC_VECTOR (13 downto 0);
           D          : in  STD_LOGIC_VECTOR ( 7 downto 0);
           VRAM0Write : out STD_LOGIC;
           VRAM1Write : out STD_LOGIC;
           VRAM2Write : out STD_LOGIC;
           VRAM3Write : out STD_LOGIC;
           VRAMAddr   : out STD_LOGIC_VECTOR (11 downto 0);
           VRAMData   : out STD_LOGIC_VECTOR ( 7 downto 0);
           CURSOR_ROW : out STD_LOGIC_VECTOR ( 7 downto 0):=x"01";
           CURSOR_COL : out STD_LOGIC_VECTOR ( 7 downto 0):=x"01");
end graphics;

architecture Behavioral of graphics is

signal LASTCS : STD_LOGIC := '0';

begin

process (CLK)
begin
    if (CLK = '1' and CLK'event ) then
        if (CS = '1' and LASTCS = '0') then
            VRAM0Write <= CS and WR and (NOT A(0)) and (NOT A(13));
            VRAM1Write <= CS and WR and (    A(0)) and (NOT A(13));
            VRAM2Write <= CS and WR and (NOT A(0)) and (    A(13));
            VRAM3Write <= CS and WR and (    A(0)) and (    A(13));
            VRAMAddr(11 downto 0) <= A(12 downto 1);
            VRAMData <= D;
            if (A = "00" & x"FFE") then
                CURSOR_ROW <= D;
            elsif (A = "00" & x"FFF") then
                CURSOR_COL <= D;
            end if;
        elsif (CS = '0') then
            VRAM0Write <= '0';
            VRAM1Write <= '0';
            VRAM2Write <= '0';
            VRAM3Write <= '0';
        end if;
        LASTCS <= CS;
    end if;
end process;

end Behavioral;
