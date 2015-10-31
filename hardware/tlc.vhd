library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TLC is
    Port (
        -- The crystal:
        CLK     : in    STD_LOGIC;
        -- VGA Connector
        R       : out   STD_LOGIC_VECTOR ( 2 downto 0);
        G       : out   STD_LOGIC_VECTOR ( 2 downto 0);
        B       : out   STD_LOGIC_VECTOR ( 1 downto 0);
        HS      : out   STD_LOGIC;
        VS      : out   STD_LOGIC;
        -- Memory Bus:
        ADDR    : out   STD_LOGIC_VECTOR (23 downto 0);
        DATA    : inout STD_LOGIC_VECTOR (15 downto 0);
        OE      : out   STD_LOGIC := '1';
        WE      : out   STD_LOGIC := '1';
        MT_ADV  : out   STD_LOGIC := '0';
        MT_CLK  : out   STD_LOGIC := '0';
        MT_UB   : out   STD_LOGIC := '1';
        MT_LB   : out   STD_LOGIC := '1';
        MT_CE   : out   STD_LOGIC := '1';
        MT_CRE  : out   STD_LOGIC := '0';
        MT_WAIT : in    STD_LOGIC := '0';
        ST_STS  : in    STD_LOGIC := '0';
        RP      : out   STD_LOGIC := '1';
        ST_CE   : out   STD_LOGIC := '1';
        -- PS/2 port:
        PS2CLK  : in    STD_LOGIC := '0';
        PS2DATA : in    STD_LOGIC := '0'
    );
end TLC;

architecture Structural of TLC is

component cpu is
    Port (
        CLK    : in  STD_LOGIC;
        IRQ    : in  STD_LOGIC;
        NMI    : in  STD_LOGIC;
        IAK    : out STD_LOGIC;
        NAK    : out STD_LOGIC;
        -- system bus
        MEME   : out STD_LOGIC;
        RW     : out STD_LOGIC;
        ADDR   : out STD_LOGIC_VECTOR (31 downto 0);
        Din    : in  STD_LOGIC_VECTOR (31 downto 0);
        Dout   : out STD_LOGIC_VECTOR (31 downto 0);
        DTYPE  : out STD_LOGIC_VECTOR ( 2 downto 0);
        RDY    : in  STD_LOGIC
    );
end component;

component memif is
    Port (
        CLK      : in    STD_LOGIC;
        -- Interface
        RAM_CS   : in    STD_LOGIC; -- RAM chip enable
        ROM_CS   : in    STD_LOGIC; -- ROM chip enable
        RW       : in    STD_LOGIC; -- 0: read, 1: write
        A        : in    STD_LOGIC_VECTOR (23 downto 0);
        Din      : in    STD_LOGIC_VECTOR (31 downto 0);
        Dout     : out   STD_LOGIC_VECTOR (31 downto 0);
        DTYPE    : in    STD_LOGIC_VECTOR ( 2 downto 0);
        RDY      : out STD_LOGIC;
        -- External Memory Bus:
        ADDR     : out   STD_LOGIC_VECTOR (23 downto 0);
        DATA     : inout STD_LOGIC_VECTOR (15 downto 0);
        OE       : out   STD_LOGIC := '1'; -- active low
        WE       : out   STD_LOGIC := '1'; -- active low
        MT_ADV   : out   STD_LOGIC := '0'; -- active low
        MT_CLK   : out   STD_LOGIC := '0';
        MT_UB    : out   STD_LOGIC := '1'; -- active low
        MT_LB    : out   STD_LOGIC := '1'; -- active low
        MT_CE    : out   STD_LOGIC := '1'; -- active low
        MT_CRE   : out   STD_LOGIC := '0'; -- active high
        MT_WAIT  : in    STD_LOGIC;
        ST_STS   : in    STD_LOGIC;
        RP       : out   STD_LOGIC := '1'; -- active low
        ST_CE    : out   STD_LOGIC := '1'  -- active low
    );
end component;

component vga is
    Port (
        -- 50MHz clock input
        CLK : in  STD_LOGIC;
        -- System Bus
        CS  : in  STD_LOGIC;
        WR  : in  STD_LOGIC;
        A   : in  STD_LOGIC_VECTOR (13 downto 0);
        D   : in  STD_LOGIC_VECTOR (7 downto 0);
        RDY : out STD_LOGIC;
        -- VGA Port
        R   : out STD_LOGIC_VECTOR (2 downto 0);
        G   : out STD_LOGIC_VECTOR (2 downto 0);
        B   : out STD_LOGIC_VECTOR (1 downto 0);
        HS  : out STD_LOGIC;
        VS  : out STD_LOGIC
    );
end component;

component kbdctl is
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
end component;

-- CPU signals
signal IRQ          : STD_LOGIC := '0';
signal NMI          : STD_LOGIC := '0';
signal IAK          : STD_LOGIC := '0';
signal NAK          : STD_LOGIC := '0';

-- System bus:
signal MEME         : STD_LOGIC := '0';
signal RW           : STD_LOGIC := '0';
signal Address      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal RAMAddress   : STD_LOGIC_VECTOR (23 downto 0) := x"000000";
signal VGAAddress   : STD_LOGIC_VECTOR (13 downto 0) := "00" & x"000";
signal DataCPUToMem : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal DataMemToCPU : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal DataRAMToCPU : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal DataKBDToCPU : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal DTYPE        : STD_LOGIC_VECTOR ( 2 downto 0) := "000";
signal RAM_CS       : STD_LOGIC := '0';
signal ROM_CS       : STD_LOGIC := '0';
signal VGA_CS       : STD_LOGIC := '0';
signal KBD_CS       : STD_LOGIC := '0';
signal MEM_RDY      : STD_LOGIC := '0';
signal VGA_RDY      : STD_LOGIC := '0';
signal KBD_RDY      : STD_LOGIC := '0';
signal RDY          : STD_LOGIC := '0';

begin

-- memory decoding
DataMemToCPU <= DataRAMToCPU OR DataKBDToCPU;
ROM_CS <= MEME when Address(31 downto 16) = x"0000" else '0';
RAM_CS <= MEME when Address(31 downto 16) = x"0001" else '0';
VGA_CS <= MEME when Address(31 downto 15) = x"0001"&"1" else '0';
KBD_CS <= MEME when Address(31 downto 20) = x"FFF" else '0';
RDY    <= MEM_RDY when ROM_CS = '1' or RAM_CS = '1' else
          VGA_RDY when VGA_CS = '1' else
          KBD_RDY when KBD_CS = '1' else
          '0';
RAMAddress <= x"00" & Address(15 downto 0);
VGAAddress <= "0" & Address(14 downto 2);

-- subblocks
U1: cpu   port map (CLK, IRQ, NMI, IAK, NAK,
                    MEME, RW, Address, DataMemToCPU, DataCPUToMem, DTYPE, RDY);
U2: memif port map (CLK,
                    RAM_CS, ROM_CS, RW, RAMAddress, DataCPUToMem(31 downto 0),
                    DataRAMToCPU(31 downto 0), DTYPE, MEM_RDY,
                    ADDR, DATA, OE, WE,
                    MT_ADV, MT_CLK, MT_UB, MT_LB, MT_CE, MT_CRE, MT_WAIT,
                    ST_STS, RP, ST_CE);
U3: vga   port map (CLK, VGA_CS, RW, VGAAddress,
                    DataCPUToMem(7 downto 0), VGA_RDY,
                    R, G, B, HS, VS);

end Structural;
