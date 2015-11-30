library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vga is
    Port ( CLK  : in  STD_LOGIC; -- 50MHz clock input
           -- System Bus
           CS   : in  STD_LOGIC;
           RW   : in  STD_LOGIC;
           A    : in  STD_LOGIC_VECTOR (13 downto 0);
           Din  : in  STD_LOGIC_VECTOR (7 downto 0);
           Dout : out STD_LOGIC_VECTOR (7 downto 0);
           RDY  : out STD_LOGIC := '0';
           -- VGA Port
           R    : out STD_LOGIC_VECTOR (2 downto 0);
           G    : out STD_LOGIC_VECTOR (2 downto 0);
           B    : out STD_LOGIC_VECTOR (1 downto 0);
           HS   : out STD_LOGIC;
           VS   : out STD_LOGIC);
end vga;

architecture Structural of vga is

component clkgen is
    Port (CLK       : in  STD_LOGIC;
          CLK_56MHz : out STD_LOGIC;
          CLK_50MHz : out STD_LOGIC;
          CLK_28MHz : out STD_LOGIC;
          CLK_25MHz : out STD_LOGIC);
end component;

component graphics is
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
           ROW_BASE    : out STD_LOGIC_VECTOR ( 7 downto 0);
           CURSOR_ROW  : out STD_LOGIC_VECTOR ( 7 downto 0);
           CURSOR_COL  : out STD_LOGIC_VECTOR ( 7 downto 0));
end component;

component vgaram0 is
    Port (CLK           : in  STD_LOGIC;
          -- sequencer port:
          SeqReadEnable : in  STD_LOGIC;
          SeqAddr       : in  STD_LOGIC_VECTOR (11 downto 0);
          SeqDataOut    : out STD_LOGIC_VECTOR ( 7 downto 0) := "00000000";
          -- GU port:
          GUReadEnable  : in  STD_LOGIC;
          GUWriteEnable : in  STD_LOGIC;
          GUAddr        : in  STD_LOGIC_VECTOR (11 downto 0);
          GUDataIn      : in  STD_LOGIC_VECTOR ( 7 downto 0);
          GUDataOut     : out STD_LOGIC_VECTOR ( 7 downto 0));
end component;

component vgaram1 is
    Port (CLK           : in  STD_LOGIC;
          -- sequencer port:
          SeqReadEnable : in  STD_LOGIC;
          SeqAddr       : in  STD_LOGIC_VECTOR (11 downto 0);
          SeqDataOut    : out STD_LOGIC_VECTOR ( 7 downto 0) := "00000000";
          -- GU port:
          GUReadEnable  : in  STD_LOGIC;
          GUWriteEnable : in  STD_LOGIC;
          GUAddr        : in  STD_LOGIC_VECTOR (11 downto 0);
          GUDataIn      : in  STD_LOGIC_VECTOR ( 7 downto 0);
          GUDataOut     : out STD_LOGIC_VECTOR ( 7 downto 0));
end component;

component vgaram2 is
    Port (CLK           : in  STD_LOGIC;
          -- sequencer port:
          SeqReadEnable : in  STD_LOGIC;
          SeqAddr       : in  STD_LOGIC_VECTOR (11 downto 0);
          SeqDataOut    : out STD_LOGIC_VECTOR ( 7 downto 0) := "00000000";
          -- GU port:
          GUReadEnable  : in  STD_LOGIC;
          GUWriteEnable : in  STD_LOGIC;
          GUAddr        : in  STD_LOGIC_VECTOR (11 downto 0);
          GUDataIn      : in  STD_LOGIC_VECTOR ( 7 downto 0);
          GUDataOut     : out STD_LOGIC_VECTOR ( 7 downto 0));
end component;

component vgaram3 is
    Port (CLK           : in  STD_LOGIC;
          -- sequencer port:
          SeqReadEnable : in  STD_LOGIC;
          SeqAddr       : in  STD_LOGIC_VECTOR (11 downto 0);
          SeqDataOut    : out STD_LOGIC_VECTOR ( 7 downto 0) := "00000000";
          -- GU port:
          GUReadEnable  : in  STD_LOGIC;
          GUWriteEnable : in  STD_LOGIC;
          GUAddr        : in  STD_LOGIC_VECTOR (11 downto 0);
          GUDataIn      : in  STD_LOGIC_VECTOR ( 7 downto 0);
          GUDataOut     : out STD_LOGIC_VECTOR ( 7 downto 0));
end component;

component sequencer is
    Port (CLK        : in  STD_LOGIC;
          SE         : in  STD_LOGIC;
          ROW_BASE   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_ROW : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_COL : in  STD_LOGIC_VECTOR ( 7 downto 0);
          X          : in  STD_LOGIC_VECTOR (15 downto 0);
          Y          : in  STD_LOGIC_VECTOR (15 downto 0);
          VRAM0Read  : out STD_LOGIC;
          VRAM0Addr  : out STD_LOGIC_VECTOR (11 downto 0);
          VRAM0Data  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          VRAM1Read  : out STD_LOGIC;
          VRAM1Addr  : out STD_LOGIC_VECTOR (11 downto 0);
          VRAM1Data  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          VRAM2Read  : out STD_LOGIC;
          VRAM2Addr  : out STD_LOGIC_VECTOR (11 downto 0);
          VRAM2Data  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          VRAM3Read  : out STD_LOGIC;
          VRAM3Addr  : out STD_LOGIC_VECTOR (11 downto 0);
          VRAM3Data  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          Color      : out STD_LOGIC_VECTOR ( 3 downto 0));
end component;

component dac is
    Port (DE    : in  STD_LOGIC;
          COLOR : in  STD_LOGIC_VECTOR (3 downto 0);
          R     : out STD_LOGIC_VECTOR (2 downto 0);
          G     : out STD_LOGIC_VECTOR (2 downto 0);
          B     : out STD_LOGIC_VECTOR (1 downto 0));
end component;

component crt is
    Port (CLK : in  STD_LOGIC;
          HS  : out STD_LOGIC := '0';
          VS  : out STD_LOGIC := '0';
          SE  : out STD_LOGIC := '0';
          DE  : out STD_LOGIC := '0';
          X   : out STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
          Y   : out STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000");
end component;

signal CLK_56MHz       : STD_LOGIC;
signal CLK_50MHz       : STD_LOGIC;
signal CLK_28MHz       : STD_LOGIC;
signal CLK_25MHz       : STD_LOGIC;

signal VRAM0Read       : STD_LOGIC;
signal VRAM1Read       : STD_LOGIC;
signal VRAM2Read       : STD_LOGIC;
signal VRAM3Read       : STD_LOGIC;

signal VRAM0Write      : STD_LOGIC;
signal VRAM1Write      : STD_LOGIC;
signal VRAM2Write      : STD_LOGIC;
signal VRAM3Write      : STD_LOGIC;

signal VRAMAddrFromGU  : STD_LOGIC_VECTOR (11 downto 0);
signal VRAM0DataToGU   : STD_LOGIC_VECTOR ( 7 downto 0);
signal VRAM1DataToGU   : STD_LOGIC_VECTOR ( 7 downto 0);
signal VRAM2DataToGU   : STD_LOGIC_VECTOR ( 7 downto 0);
signal VRAM3DataToGU   : STD_LOGIC_VECTOR ( 7 downto 0);
signal VRAMDataFromGU  : STD_LOGIC_VECTOR ( 7 downto 0);

signal ROW_BASE        : STD_LOGIC_VECTOR ( 7 downto 0);
signal CURSOR_ROW      : STD_LOGIC_VECTOR ( 7 downto 0);
signal CURSOR_COL      : STD_LOGIC_VECTOR ( 7 downto 0);

signal SE              : STD_LOGIC;
signal DE              : STD_LOGIC;
signal X               : STD_LOGIC_VECTOR (15 downto 0);
signal Y               : STD_LOGIC_VECTOR (15 downto 0);
signal COLOR           : STD_LOGIC_VECTOR ( 3 downto 0);

signal VRAM0ReadEnable : STD_LOGIC;
signal VRAM0ReadAddr   : STD_LOGIC_VECTOR (11 downto 0);
signal VRAM0ReadData   : STD_LOGIC_VECTOR ( 7 downto 0);

signal VRAM1ReadEnable : STD_LOGIC;
signal VRAM1ReadAddr   : STD_LOGIC_VECTOR (11 downto 0);
signal VRAM1ReadData   : STD_LOGIC_VECTOR ( 7 downto 0);

signal VRAM2ReadEnable : STD_LOGIC;
signal VRAM2ReadAddr   : STD_LOGIC_VECTOR (11 downto 0);
signal VRAM2ReadData   : STD_LOGIC_VECTOR ( 7 downto 0);

signal VRAM3ReadEnable : STD_LOGIC;
signal VRAM3ReadAddr   : STD_LOGIC_VECTOR (11 downto 0);
signal VRAM3ReadData   : STD_LOGIC_VECTOR ( 7 downto 0);

begin

u0: clkgen    port map (CLK, CLK_56MHz, CLK_50MHz, CLK_28MHz, CLK_25MHz);
u1: graphics  port map (CLK_50MHz, CS, RW, A, Din, Dout,
                        VRAM0Read, VRAM1Read, VRAM2Read, VRAM3Read,
                        VRAM0Write, VRAM1Write, VRAM2Write, VRAM3Write,
                        VRAMAddrFromGU, VRAM0DataToGU, VRAM1DataToGU,
                        VRAM2DataToGU, VRAM3DataToGU, VRAMDataFromGU,
                        ROW_BASE, CURSOR_ROW, CURSOR_COL);
u2: vgaram0   port map (CLK_56MHz,
                        VRAM0ReadEnable, VRAM0ReadAddr, VRAM0ReadData,
                        VRAM0Read, VRAM0Write,
                        VRAMAddrFromGU, VRAMDataFromGU, VRAM0DataToGU);
u3: vgaram1   port map (CLK_56MHz,
                        VRAM1ReadEnable, VRAM1ReadAddr, VRAM1ReadData,
                        VRAM1Read, VRAM1Write,
                        VRAMAddrFromGU, VRAMDataFromGU, VRAM1DataToGU);
u4: vgaram2   port map (CLK_56MHz,
                        VRAM2ReadEnable, VRAM2ReadAddr, VRAM2ReadData,
                        VRAM2Read, VRAM2Write,
                        VRAMAddrFromGU, VRAMDataFromGU, VRAM2DataToGU);
u5: vgaram3   port map (CLK_56MHz,
                        VRAM3ReadEnable, VRAM3ReadAddr, VRAM3ReadData,
                        VRAM3Read, VRAM3Write,
                        VRAMAddrFromGU, VRAMDataFromGU, VRAM3DataToGU);
u6: sequencer port map (CLK_28MHz, SE,
                        ROW_BASE, CURSOR_ROW, CURSOR_COL, X, Y,
                        VRAM0ReadEnable, VRAM0ReadAddr, VRAM0ReadData,
                        VRAM1ReadEnable, VRAM1ReadAddr, VRAM1ReadData,
                        VRAM2ReadEnable, VRAM2ReadAddr, VRAM2ReadData,
                        VRAM3ReadEnable, VRAM3ReadAddr, VRAM3ReadData,
                        COLOR);
u7: dac       port map (DE, COLOR, R, G, B);
u8: crt       port map (CLK_28MHz, HS, VS, SE, DE, X, Y);

end Structural;
