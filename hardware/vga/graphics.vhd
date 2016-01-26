library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity graphics is
    Port ( CLK         : in  STD_LOGIC;
           CS          : in  STD_LOGIC;
           RW          : in  STD_LOGIC;
           A           : in  STD_LOGIC_VECTOR (13 downto 0);
           Din         : in  STD_LOGIC_VECTOR (15 downto 0);
           Dout        : out STD_LOGIC_VECTOR (15 downto 0) := x"0000";
           VRAM0Read   : out STD_LOGIC;
           VRAM1Read   : out STD_LOGIC;
           VRAM2Read   : out STD_LOGIC;
           VRAM3Read   : out STD_LOGIC;
           VRAM0Write  : out STD_LOGIC;
           VRAM1Write  : out STD_LOGIC;
           VRAM2Write  : out STD_LOGIC;
           VRAM3Write  : out STD_LOGIC;
           VRAMAddr    : out STD_LOGIC_VECTOR (10 downto 0);
           VRAM0DataIn : in  STD_LOGIC_VECTOR ( 8 downto 0);
           VRAM1DataIn : in  STD_LOGIC_VECTOR ( 8 downto 0);
           VRAM2DataIn : in  STD_LOGIC_VECTOR ( 8 downto 0);
           VRAM3DataIn : in  STD_LOGIC_VECTOR ( 8 downto 0);
           VRAMDataOut : out STD_LOGIC_VECTOR ( 8 downto 0);
           ROW_BASE    : out STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
           CURSOR_ROW  : out STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
           CURSOR_COL  : out STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
           MODE        : out STD_LOGIC);
end graphics;

architecture Behavioral of graphics is

signal LASTCS         : STD_LOGIC := '0';
signal ROW_BASE_REG   : STD_LOGIC_VECTOR (7 downto 0):=x"00";
signal CURSOR_ROW_REG : STD_LOGIC_VECTOR (7 downto 0):=x"00";
signal CURSOR_COL_REG : STD_LOGIC_VECTOR (7 downto 0):=x"00";
signal MODE_REG       : STD_LOGIC := '0';

begin

process (CLK)
begin
    if (CLK = '1' and CLK'event ) then
        if (CS = '1') then
            if (A = "0" & x"FFC" & "0") then
                MODE_REG <= Din(0);
            elsif (A = "0" & x"FFD" & "0") then
                ROW_BASE_REG <= Din(7 downto 0);
            elsif (A = "0" & x"FFE" & "0") then
                CURSOR_ROW_REG <= Din(7 downto 0);
            elsif (A = "0" & x"FFF" & "0") then
                CURSOR_COL_REG <= Din(7 downto 0);
            else
                -- access to any other address
                if (LASTCS = '0') then
                    VRAM0Read  <= (NOT RW) and (NOT A(1)) and (NOT A(13));
                    VRAM1Read  <= (NOT RW) and (    A(1)) and (NOT A(13));
                    VRAM2Read  <= (NOT RW) and (NOT A(1)) and (    A(13));
                    VRAM3Read  <= (NOT RW) and (    A(1)) and (    A(13));
                    VRAM0Write <= (    RW) and (NOT A(1)) and (NOT A(13));
                    VRAM1Write <= (    RW) and (    A(1)) and (NOT A(13));
                    VRAM2Write <= (    RW) and (NOT A(1)) and (    A(13));
                    VRAM3Write <= (    RW) and (    A(1)) and (    A(13));
                    VRAMAddr(10 downto 0) <= A(12 downto 2);
                    VRAMDataOut <= Din(8 downto 0);
                end if;
            end if;
        else
            VRAM0Read  <= '0';
            VRAM1Read  <= '0';
            VRAM2Read  <= '0';
            VRAM3Read  <= '0';
            VRAM0Write <= '0';
            VRAM1Write <= '0';
            VRAM2Write <= '0';
            VRAM3Write <= '0';
        end if;
        Dout(8 downto 0) <= VRAM0DataIn or VRAM1DataIn or
                            VRAM2DataIn or VRAM3DataIn;
        LASTCS <= CS;
    end if;
end process;

ROW_BASE   <= ROW_BASE_REG;
CURSOR_ROW <= CURSOR_ROW_REG;
CURSOR_COL <= CURSOR_COL_REG;
MODE       <= MODE_REG;

end Behavioral;
