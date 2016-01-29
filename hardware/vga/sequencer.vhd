library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sequencer is
    Port (CLK56      : in  STD_LOGIC;
          CLK28      : in  STD_LOGIC;
          SE         : in  STD_LOGIC;
          MODE       : in  STD_LOGIC;
          ROW_BASE   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_ROW : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_COL : in  STD_LOGIC_VECTOR ( 7 downto 0);
          PPU_CTRL   : in  STD_LOGIC_VECTOR (15 downto 0);
          PPU_HSCR   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          PPU_VSCR   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          X          : in  STD_LOGIC_VECTOR (15 downto 0);
          Y          : in  STD_LOGIC_VECTOR (15 downto 0);
          B9         : in  STD_LOGIC := '0';
          VRAM0Read  : out STD_LOGIC := '0';
          VRAM0Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM0Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM1Read  : out STD_LOGIC := '0';
          VRAM1Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM1Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM2Read  : out STD_LOGIC := '0';
          VRAM2Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM2Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM3Read  : out STD_LOGIC := '0';
          VRAM3Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM3Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM4Read  : out STD_LOGIC := '0';
          VRAM4Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM4Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          SprRD      : in  STD_LOGIC;
          SprWR      : in  STD_LOGIC;
          SprAddr    : in  STD_LOGIC_VECTOR ( 7 downto 0);
          SprDataIn  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          SprDataOut : out STD_LOGIC_VECTOR ( 7 downto 0);
          PalRD      : in  STD_LOGIC;
          PalWR      : in  STD_LOGIC;
          PalAddr    : in  STD_LOGIC_VECTOR ( 4 downto 0);
          PalDataIn  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          PalDataOut : out STD_LOGIC_VECTOR ( 7 downto 0);
          Color      : out STD_LOGIC_VECTOR ( 5 downto 0) := "000000");
end sequencer;

architecture Structural of sequencer is

component vgaseq is
    Port (CLK        : in  STD_LOGIC;
          SE         : in  STD_LOGIC;
          ROW_BASE   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_ROW : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_COL : in  STD_LOGIC_VECTOR ( 7 downto 0);
          X          : in  STD_LOGIC_VECTOR (15 downto 0);
          Y          : in  STD_LOGIC_VECTOR (15 downto 0);
          B9         : in  STD_LOGIC := '0';
          VRAM0Read  : out STD_LOGIC := '0';
          VRAM0Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM0Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM1Read  : out STD_LOGIC := '0';
          VRAM1Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM1Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM2Read  : out STD_LOGIC := '0';
          VRAM2Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM2Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM3Read  : out STD_LOGIC := '0';
          VRAM3Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM3Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          Color      : out STD_LOGIC_VECTOR ( 3 downto 0) := "0000");
end component;

component ppuseq is
    Port (CLK        : in  STD_LOGIC;
          SE         : in  STD_LOGIC;
          ROW_BASE   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_ROW : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_COL : in  STD_LOGIC_VECTOR ( 7 downto 0);
          PPU_CTRL   : in  STD_LOGIC_VECTOR (15 downto 0);
          PPU_HSCR   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          PPU_VSCR   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          X          : in  STD_LOGIC_VECTOR (15 downto 0);
          Y          : in  STD_LOGIC_VECTOR (15 downto 0);
          B9         : in  STD_LOGIC := '0';
          VRAM0Read  : out STD_LOGIC := '0';
          VRAM0Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM0Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM1Read  : out STD_LOGIC := '0';
          VRAM1Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM1Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM2Read  : out STD_LOGIC := '0';
          VRAM2Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM2Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM3Read  : out STD_LOGIC := '0';
          VRAM3Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM3Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM4Read  : out STD_LOGIC := '0';
          VRAM4Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM4Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          SprRD      : in  STD_LOGIC;
          SprWR      : in  STD_LOGIC;
          SprAddr    : in  STD_LOGIC_VECTOR ( 7 downto 0);
          SprDataIn  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          SprDataOut : out STD_LOGIC_VECTOR ( 7 downto 0);
          PalRD      : in  STD_LOGIC;
          PalWR      : in  STD_LOGIC;
          PalAddr    : in  STD_LOGIC_VECTOR ( 4 downto 0);
          PalDataIn  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          PalDataOut : out STD_LOGIC_VECTOR ( 7 downto 0);
          Color      : out STD_LOGIC_VECTOR ( 5 downto 0) := "000000");
end component;

signal VGA_VRAM0Read : STD_LOGIC;
signal VGA_VRAM0Addr : STD_LOGIC_VECTOR (10 downto 0);
signal VGA_VRAM1Read : STD_LOGIC;
signal VGA_VRAM1Addr : STD_LOGIC_VECTOR (10 downto 0);
signal VGA_VRAM2Read : STD_LOGIC;
signal VGA_VRAM2Addr : STD_LOGIC_VECTOR (10 downto 0);
signal VGA_VRAM3Read : STD_LOGIC;
signal VGA_VRAM3Addr : STD_LOGIC_VECTOR (10 downto 0);
signal VGA_Color     : STD_LOGIC_VECTOR ( 3 downto 0);

signal PPU_VRAM0Read : STD_LOGIC;
signal PPU_VRAM0Addr : STD_LOGIC_VECTOR (10 downto 0);
signal PPU_VRAM1Read : STD_LOGIC;
signal PPU_VRAM1Addr : STD_LOGIC_VECTOR (10 downto 0);
signal PPU_VRAM2Read : STD_LOGIC;
signal PPU_VRAM2Addr : STD_LOGIC_VECTOR (10 downto 0);
signal PPU_VRAM3Read : STD_LOGIC;
signal PPU_VRAM3Addr : STD_LOGIC_VECTOR (10 downto 0);
signal PPU_Color     : STD_LOGIC_VECTOR ( 5 downto 0);

begin

U1: vgaseq port map (CLK28, SE, ROW_BASE, CURSOR_ROW, CURSOR_COL, X, Y, B9,
                     VGA_VRAM0Read, VGA_VRAM0Addr, VRAM0Data,
                     VGA_VRAM1Read, VGA_VRAM1Addr, VRAM1Data,
                     VGA_VRAM2Read, VGA_VRAM2Addr, VRAM2Data,
                     VGA_VRAM3Read, VGA_VRAM3Addr, VRAM3Data,
                     VGA_Color);

U2: ppuseq port map (CLK28, SE, ROW_BASE, CURSOR_ROW, CURSOR_COL,
                     PPU_CTRL, PPU_HSCR, PPU_VSCR,
                     X, Y, B9,
                     PPU_VRAM0Read, PPU_VRAM0Addr, VRAM0Data,
                     PPU_VRAM1Read, PPU_VRAM1Addr, VRAM1Data,
                     PPU_VRAM2Read, PPU_VRAM2Addr, VRAM2Data,
                     PPU_VRAM3Read, PPU_VRAM3Addr, VRAM3Data,
                     VRAM4Read, VRAM4Addr, VRAM4Data,
                     SprRD, SprWR, SprAddr, SprDataIn, SprDataOut,
                     PalRD, PalWR, PalAddr, PalDataIn, PalDataOut,
                     PPU_Color);

VRAM0Read <= VGA_VRAM0Read when MODE = '0' else PPU_VRAM0Read;
VRAM0Addr <= VGA_VRAM0Addr when MODE = '0' else PPU_VRAM0Addr;
VRAM1Read <= VGA_VRAM1Read when MODE = '0' else PPU_VRAM1Read;
VRAM1Addr <= VGA_VRAM1Addr when MODE = '0' else PPU_VRAM1Addr;
VRAM2Read <= VGA_VRAM2Read when MODE = '0' else PPU_VRAM2Read;
VRAM2Addr <= VGA_VRAM2Addr when MODE = '0' else PPU_VRAM2Addr;
VRAM3Read <= VGA_VRAM3Read when MODE = '0' else PPU_VRAM3Read;
VRAM3Addr <= VGA_VRAM3Addr when MODE = '0' else PPU_VRAM3Addr;
Color     <= ("00" & VGA_Color) when MODE = '0' else PPU_Color;

end Structural;
