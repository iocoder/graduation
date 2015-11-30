library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity graphics is
    Port ( CLK         : in  STD_LOGIC;
           CS          : in  STD_LOGIC;
           RW          : in  STD_LOGIC;
           A           : in  STD_LOGIC_VECTOR (13 downto 0);
           Din         : in  STD_LOGIC_VECTOR ( 7 downto 0);
           Dout        : out STD_LOGIC_VECTOR ( 7 downto 0);
           VRAM0Read   : out STD_LOGIC;
           VRAM1Read   : out STD_LOGIC;
           VRAM2Read   : out STD_LOGIC;
           VRAM3Read   : out STD_LOGIC;
           VRAM0Write  : out STD_LOGIC;
           VRAM1Write  : out STD_LOGIC;
           VRAM2Write  : out STD_LOGIC;
           VRAM3Write  : out STD_LOGIC;
           VRAMAddr    : out STD_LOGIC_VECTOR (11 downto 0);
           VRAM0DataIn : in  STD_LOGIC_VECTOR ( 7 downto 0);
           VRAM1DataIn : in  STD_LOGIC_VECTOR ( 7 downto 0);
           VRAM2DataIn : in  STD_LOGIC_VECTOR ( 7 downto 0);
           VRAM3DataIn : in  STD_LOGIC_VECTOR ( 7 downto 0);
           VRAMDataOut : out STD_LOGIC_VECTOR ( 7 downto 0);
           ROW_BASE    : out STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
           CURSOR_ROW  : out STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
           CURSOR_COL  : out STD_LOGIC_VECTOR ( 7 downto 0) := x"00");
end graphics;

architecture Behavioral of graphics is

signal LASTCS         : STD_LOGIC := '0';
signal ROW_BASE_REG   : STD_LOGIC_VECTOR (7 downto 0):=x"00";
signal CURSOR_ROW_REG : STD_LOGIC_VECTOR (7 downto 0):=x"00";
signal CURSOR_COL_REG : STD_LOGIC_VECTOR (7 downto 0):=x"00";

begin

process (CLK)
begin
    if (CLK = '1' and CLK'event ) then
        if (CS = '1' and LASTCS = '0') then
            VRAM0Read  <= CS and (NOT RW) and (NOT A(0)) and (NOT A(13));
            VRAM1Read  <= CS and (NOT RW) and (    A(0)) and (NOT A(13));
            VRAM2Read  <= CS and (NOT RW) and (NOT A(0)) and (    A(13));
            VRAM3Read  <= CS and (NOT RW) and (    A(0)) and (    A(13));
            VRAM0Write <= CS and (    RW) and (NOT A(0)) and (NOT A(13));
            VRAM1Write <= CS and (    RW) and (    A(0)) and (NOT A(13));
            VRAM2Write <= CS and (    RW) and (NOT A(0)) and (    A(13));
            VRAM3Write <= CS and (    RW) and (    A(0)) and (    A(13));
            VRAMAddr(11 downto 0) <= A(12 downto 1);
            VRAMDataOut <= Din;
            if (A = "00" & x"FFD") then
                ROW_BASE_REG <= Din;
            elsif (A = "00" & x"FFE") then
                CURSOR_ROW_REG <= Din;
            elsif (A = "00" & x"FFF") then
                CURSOR_COL_REG <= Din;
            end if;
        elsif (CS = '0') then
            VRAM0Read  <= '0';
            VRAM1Read  <= '0';
            VRAM2Read  <= '0';
            VRAM3Read  <= '0';
            VRAM0Write <= '0';
            VRAM1Write <= '0';
            VRAM2Write <= '0';
            VRAM3Write <= '0';
        end if;
        Dout <= VRAM0DataIn or VRAM1DataIn or VRAM2DataIn or VRAM3DataIn;
        ROW_BASE   <= ROW_BASE_REG;
        CURSOR_ROW <= CURSOR_ROW_REG;
        CURSOR_COL <= CURSOR_COL_REG;
        LASTCS <= CS;
    end if;
end process;

end Behavioral;
