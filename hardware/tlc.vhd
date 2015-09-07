library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TLC is
    Port (
        -- The crystal:
        CLK     : in    STD_LOGIC;
        -- LEDs:
        LED     : out   STD_LOGIC_VECTOR ( 7 downto 0);
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

-- component cpu is
--     Port (
--         CLK  : in  STD_LOGIC;
--         IRQ  : in  STD_LOGIC;
--         NMI  : in  STD_LOGIC;
--         MEME : out STD_LOGIC;
--         RW   : out STD_LOGIC;
--         ADDR : out STD_LOGIC_VECTOR (15 downto 0);
--         Din  : in  STD_LOGIC_VECTOR ( 7 downto 0);
--         Dout : out STD_LOGIC_VECTOR ( 7 downto 0);
--         IAK  : out STD_LOGIC;
--         NAK  : out STD_LOGIC
--     );
-- end component;

component memif is
    Port (
        CLK      : in    STD_LOGIC;
        LED      : out   STD_LOGIC_VECTOR ( 7 downto 0);
        -- Interface
        A        : in    STD_LOGIC_VECTOR (23 downto 0);
        Din      : in    STD_LOGIC_VECTOR (15 downto 0);
        Dout     : out   STD_LOGIC_VECTOR ( 7 downto 0);
        CE       : in    STD_LOGIC; -- chip enable
        SEL      : in    STD_LOGIC; -- 0: RAM, 1: ROM
        RW       : in    STD_LOGIC; -- 0: read, 1: write
        PRG_EN   : in    STD_LOGIC; -- 0: disable ROM programming, 1: enable
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

component decoder is
    Port (
        EN : in  STD_LOGIC;
        I  : in  STD_LOGIC_VECTOR (2 downto 0);
        O  : out STD_LOGIC_VECTOR (7 downto 0)
    );
end component;

component vga is
    Port (
        -- 50MHz clock input
        CLK : in  STD_LOGIC;
        -- System Bus
        CS  : in STD_LOGIC;
        WR  : in STD_LOGIC;
        A   : in STD_LOGIC_VECTOR (13 downto 0);
        D   : in STD_LOGIC_VECTOR (7 downto 0);
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

signal MEME     : STD_LOGIC;
signal RW       : STD_LOGIC;
signal CPUADDR  : STD_LOGIC_VECTOR (15 downto 0);
signal RAMADDR  : STD_LOGIC_VECTOR (23 downto 0);
signal VGAADDR  : STD_LOGIC_VECTOR (13 downto 0);
signal DECADDR  : STD_LOGIC_VECTOR ( 2 downto 0);
signal DECOUT   : STD_LOGIC_VECTOR ( 7 downto 0);
signal RAMToCPU : STD_LOGIC_VECTOR ( 7 downto 0);
signal KBDToCPU : STD_LOGIC_VECTOR ( 7 downto 0);
signal MemToCPU : STD_LOGIC_VECTOR ( 7 downto 0);
signal CPUToMem : STD_LOGIC_VECTOR ( 7 downto 0);
signal RAMEn    : STD_LOGIC;
signal RAMDin   : STD_LOGIC_VECTOR (15 downto 0);
signal TMP      : STD_LOGIC_VECTOR ( 7 downto 0);

signal NMI      : STD_LOGIC;
signal NAK      : STD_LOGIC;
signal IRQ      : STD_LOGIC;
signal IAK      : STD_LOGIC;


begin

-- Decoder Address:
DECADDR( 0) <= CPUADDR(13);
DECADDR( 1) <= CPUADDR(14);
DECADDR( 2) <= CPUADDR(15);

-- VGA Address:
VGAADDR( 0) <= CPUADDR( 0);
VGAADDR( 1) <= CPUADDR( 1);
VGAADDR( 2) <= CPUADDR( 2);
VGAADDR( 3) <= CPUADDR( 3);
VGAADDR( 4) <= CPUADDR( 4);
VGAADDR( 5) <= CPUADDR( 5);
VGAADDR( 6) <= CPUADDR( 6);
VGAADDR( 7) <= CPUADDR( 7);
VGAADDR( 8) <= CPUADDR( 8);
VGAADDR( 9) <= CPUADDR( 9);
VGAADDR(10) <= CPUADDR(10);
VGAADDR(11) <= CPUADDR(11);
VGAADDR(12) <= CPUADDR(12);
VGAADDR(13) <= '0';

-- RAM/RM Enable
RAMEn <= DECOUT(0) OR DECOUT(1) OR DECOUT(3) OR
         DECOUT(4) OR DECOUT(5) OR DECOUT(6) OR DECOUT(7);

-- RAM Address:
RAMADDR <= "000000000" & CPUADDR(14 downto 0);
RAMDin <= x"00" & CPUToMem;

-- Data to CPU
MemToCPU <= RAMToCPU OR KBDToCPU;

-- Components
-- U0: cpu     port map (
--     CLK, IRQ, NMI, MEME, RW, CPUADDR,
--     MemToCPU, CPUToMem, IAK, NAK
-- );
U1: decoder port map (MEME, DECADDR, DECOUT);
U2: memif   port map (
    CLK, TMP, RAMADDR, RAMDin, RAMToCPU, RAMEn, CPUADDR(15), RW, '0',
    ADDR, DATA, OE, WE,
    MT_ADV, MT_CLK, MT_UB, MT_LB, MT_CE, MT_CRE, MT_WAIT,
    ST_STS, RP, ST_CE
);
U3: vga     port map (CLK, DECOUT(3), RW, VGAADDR, CPUToMem, R, G, B, HS, VS);
U4: kbdctl  port map (
    CLK, PS2CLK, PS2DATA, LED,
    DECOUT(2), RW, KBDToCPU, NMI, NAK
);

end Structural;
