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
        DTYPE  : out STD_LOGIC_VECTOR ( 2 downto 0)
    );
end entity;

architecture Structual of cpu is

component clkdiv is
    Port (
        CLK50MHz : in  STD_LOGIC;
        -- CPU interface
        CLK2MHz  : out STD_LOGIC;
        CLK1MHz  : out STD_LOGIC
    );
end component;

component pipeline is
    Port (
        CLK    : in  STD_LOGIC;
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

component cache is
    Port (
        CLK50MHz : in  STD_LOGIC;
        CLK2MHz  : in  STD_LOGIC;
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
        DTYPE    : out STD_LOGIC_VECTOR ( 2 downto 0)
    );
end component;

signal CLK2MHz  : STD_LOGIC;
signal CLK1MHz  : STD_LOGIC;
signal iMEME    : STD_LOGIC;
signal iRW      : STD_LOGIC;
signal iADDR    : STD_LOGIC_VECTOR (31 downto 0);
signal iDin     : STD_LOGIC_VECTOR (31 downto 0);
signal iDout    : STD_LOGIC_VECTOR (31 downto 0);
signal iDTYPE   : STD_LOGIC_VECTOR ( 2 downto 0);
signal dMEME    : STD_LOGIC;
signal dRW      : STD_LOGIC;
signal dADDR    : STD_LOGIC_VECTOR (31 downto 0);
signal dDin     : STD_LOGIC_VECTOR (31 downto 0);
signal dDout    : STD_LOGIC_VECTOR (31 downto 0);
signal dDTYPE   : STD_LOGIC_VECTOR ( 2 downto 0);

begin

U1: clkdiv   port map (CLK, CLK2MHz, CLK1MHz);

U2: pipeline port map (CLK1MHz, IRQ, NMI, IAK, NAK,
                       iMEME, iRW, iADDR, iDin, iDout, iDTYPE,
                       dMEME, dRW, dADDR, dDin, dDout, dDTYPE);

U3: cache    port map (CLK, CLK2MHz,
                       iMEME, iRW, iADDR, iDout, iDin, iDTYPE,
                       dMEME, dRW, dADDR, dDout, dDin, dDTYPE,
                       MEME, RW, ADDR, Din, Dout, DTYPE);

end Structual;
