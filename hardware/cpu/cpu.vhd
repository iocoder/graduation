library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.cpu_pkg.all;

entity cpu is
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
end entity;

architecture Structual of cpu is

component clkdiv is
    Port (
        CLK      : in  STD_LOGIC;
        -- CPU interface
        CLK50MHz : out STD_LOGIC;
        CLK25MHz : out STD_LOGIC;
        CLK2MHz  : out STD_LOGIC;
        CLK1MHz  : out STD_LOGIC;
        CACHE_EN : out STD_LOGIC
    );
end component;

component pipeline is
    Port (
        CLK50  : in  STD_LOGIC;
        CLK    : in  STD_LOGIC;
        STALL  : in  STD_LOGIC;
        IRQ    : in  STD_LOGIC;
        NMI    : in  STD_LOGIC;
        IAK    : out STD_LOGIC;
        NAK    : out STD_LOGIC;
        -- instruction bus
        iMEME  : out STD_LOGIC;
        iRW    : out STD_LOGIC;
        iADDR  : out STD_LOGIC_VECTOR (31 downto 0);
        iDin   : in  STD_LOGIC_VECTOR (31 downto 0);
        iDout  : out STD_LOGIC_VECTOR (31 downto 0);
        iDTYPE : out STD_LOGIC_VECTOR ( 2 downto 0);
        -- data bus
        dMEME  : out STD_LOGIC;
        dRW    : out STD_LOGIC;
        dADDR  : out STD_LOGIC_VECTOR (31 downto 0);
        dDin   : in  STD_LOGIC_VECTOR (31 downto 0);
        dDout  : out STD_LOGIC_VECTOR (31 downto 0);
        dDTYPE : out STD_LOGIC_VECTOR ( 2 downto 0)
    );
end component;

component tlb is
    Port (
        CLK              : in  STD_LOGIC;
        -- CPU interface
        cpu_iMEME        : in  STD_LOGIC;
        cpu_iRW          : in  STD_LOGIC;
        cpu_iADDR        : in  STD_LOGIC_VECTOR (19 downto 0);
        cpu_dMEME        : in  STD_LOGIC;
        cpu_dRW          : in  STD_LOGIC;
        cpu_dADDR        : in  STD_LOGIC_VECTOR (19 downto 0);
        -- Cache interface:
        cache_iMEME      : out STD_LOGIC;
        cache_iADDR      : out STD_LOGIC_VECTOR (19 downto 0);
        cache_iCacheable : out STD_LOGIC;
        cache_dMEME      : out STD_LOGIC;
        cache_dADDR      : out STD_LOGIC_VECTOR (19 downto 0);
        cache_dCacheable : out STD_LOGIC
    );
end component;

component cache is
    Port (
        CLK      : in  STD_LOGIC;
        CACHE_EN : in  STD_LOGIC;
        STALL    : out STD_LOGIC;
        -- CPU interface
        iMEME    : in  STD_LOGIC;
        iRW      : in  STD_LOGIC;
        iADDR    : in  STD_LOGIC_VECTOR (31 downto 0);
        iDin     : in  STD_LOGIC_VECTOR (31 downto 0);
        iDout    : out STD_LOGIC_VECTOR (31 downto 0);
        iDTYPE   : in  STD_LOGIC_VECTOR ( 2 downto 0);
        dMEME    : in  STD_LOGIC;
        dRW      : in  STD_LOGIC;
        dADDR    : in  STD_LOGIC_VECTOR (31 downto 0);
        dDin     : in  STD_LOGIC_VECTOR (31 downto 0);
        dDout    : out STD_LOGIC_VECTOR (31 downto 0);
        dDTYPE   : in  STD_LOGIC_VECTOR ( 2 downto 0);
        -- system bus interface
        MEME     : out STD_LOGIC;
        RW       : out STD_LOGIC;
        ADDR     : out STD_LOGIC_VECTOR (31 downto 0);
        Din      : in  STD_LOGIC_VECTOR (31 downto 0);
        Dout     : out STD_LOGIC_VECTOR (31 downto 0);
        DTYPE    : out STD_LOGIC_VECTOR ( 2 downto 0);
        RDY      : in  STD_LOGIC
    );
end component;

signal CLK50MHz   : STD_LOGIC;
signal CLK25MHz   : STD_LOGIC;
signal CLK2MHz    : STD_LOGIC;
signal CLK1MHz    : STD_LOGIC;
signal CACHE_EN   : STD_LOGIC;
signal STALL      : STD_LOGIC;
signal cpu_iMEME  : STD_LOGIC;
signal cpu_iADDR  : STD_LOGIC_VECTOR (31 downto 0);
signal cpu_dMEME  : STD_LOGIC;
signal cpu_dADDR  : STD_LOGIC_VECTOR (31 downto 0);
signal iMEME      : STD_LOGIC;
signal iRW        : STD_LOGIC;
signal iCacheable : STD_LOGIC;
signal iADDR      : STD_LOGIC_VECTOR (31 downto 0);
signal iDin       : STD_LOGIC_VECTOR (31 downto 0);
signal iDout      : STD_LOGIC_VECTOR (31 downto 0);
signal iDTYPE     : STD_LOGIC_VECTOR ( 2 downto 0);
signal dMEME      : STD_LOGIC;
signal dRW        : STD_LOGIC;
signal dCacheable : STD_LOGIC;
signal dADDR      : STD_LOGIC_VECTOR (31 downto 0);
signal dDin       : STD_LOGIC_VECTOR (31 downto 0);
signal dDout      : STD_LOGIC_VECTOR (31 downto 0);
signal dDTYPE     : STD_LOGIC_VECTOR ( 2 downto 0);

begin

iADDR(11 downto 0) <= cpu_iADDR(11 downto 0);
dADDR(11 downto 0) <= cpu_dADDR(11 downto 0);

U1: clkdiv   port map (CLK, CLK50MHz, CLK25MHz, CLK2MHz, CLK1MHz, CACHE_EN);
U2: pipeline port map (CLK50MHz, CLK25MHz, STALL, IRQ, NMI, IAK, NAK,
                       cpu_iMEME, iRW, cpu_iADDR, iDin, iDout, iDTYPE,
                       cpu_dMEME, dRW, cpu_dADDR, dDin, dDout, dDTYPE);
U3: tlb      port map (CLK50MHz,
                       cpu_iMEME, iRW, cpu_iADDR(31 downto 12),
                       cpu_dMEME, dRW, cpu_dADDR(31 downto 12),
                       iMEME, iADDR(31 downto 12), iCacheable,
                       dMEME, dADDR(31 downto 12), dCacheable);
U4: cache    port map (CLK50MHz, CACHE_EN, STALL,
                       iMEME, iRW, iADDR, iDout, iDin, iDTYPE,
                       dMEME, dRW, dADDR, dDout, dDin, dDTYPE,
                       MEME, RW, ADDR, Din, Dout, DTYPE, RDY);

end Structual;
