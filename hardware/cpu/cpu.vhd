library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cpu is
    Port (
        CLK  : in  STD_LOGIC;
        IRQ  : in  STD_LOGIC;
        NMI  : in  STD_LOGIC;
        MEME : out STD_LOGIC;
        RW   : out STD_LOGIC;
        ADDR : out STD_LOGIC_VECTOR (15 downto 0);
        Din  : in  STD_LOGIC_VECTOR ( 7 downto 0);
        Dout : out STD_LOGIC_VECTOR ( 7 downto 0);
        IAK  : out STD_LOGIC;
        NAK  : out STD_LOGIC
    );
end cpu;

architecture Structural of cpu is

component cu is
    Port (
        CLK  : in  STD_LOGIC;
        C    : in  STD_LOGIC;
        Z    : in  STD_LOGIC;
        N    : in  STD_LOGIC;
        V    : in  STD_LOGIC;
        I    : in  STD_LOGIC;
        IRQ  : in  STD_LOGIC;
        NMI  : in  STD_LOGIC;
        IR   : in  STD_LOGIC_VECTOR (7 downto 0);
        SRC  : out STD_LOGIC_VECTOR (4 downto 0);
        DEST : out STD_LOGIC_VECTOR (4 downto 0)
    );
end component;

component alu is
    Port (
        AXL : in  STD_LOGIC_VECTOR (7 downto 0);
        AXH : in  STD_LOGIC_VECTOR (7 downto 0);
        AY  : in  STD_LOGIC_VECTOR (7 downto 0);
        AOP : in  STD_LOGIC_VECTOR (7 downto 0);
        Cin : in  STD_LOGIC;
        REP : in  STD_LOGIC;
        AZL : out STD_LOGIC_VECTOR (7 downto 0);
        AZH : out STD_LOGIC_VECTOR (7 downto 0);
        C   : out STD_LOGIC;
        Z   : out STD_LOGIC;
        N   : out STD_LOGIC;
        V   : out STD_LOGIC
    );
end component;

component regs is
    Port (
        CLK     : in  STD_LOGIC;
        -- input from CPU
        DATAIN  : in  STD_LOGIC_VECTOR (7 downto 0);
        -- input from control unit
        SRC     : in  STD_LOGIC_VECTOR (4 downto 0);
        DEST    : in  STD_LOGIC_VECTOR (4 downto 0);
        -- input from ALU
        ALU_AZL : in  STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_AZH : in  STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_C   : in  STD_LOGIC                     := '0';
        ALU_Z   : in  STD_LOGIC                     := '0';
        ALU_N   : in  STD_LOGIC                     := '0';
        ALU_V   : in  STD_LOGIC                     := '0';
        -- output to the CPU
        MEME    : out STD_LOGIC                     := '0';
        RW      : out STD_LOGIC                     := '0';
        ABL     : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ABH     : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        DATAOUT : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        IAK     : out STD_LOGIC                     := '0';
        NAK     : out STD_LOGIC                     := '0';
        -- output to control unit
        CU_C    : out STD_LOGIC                     := '0';
        CU_Z    : out STD_LOGIC                     := '0';
        CU_N    : out STD_LOGIC                     := '0';
        CU_V    : out STD_LOGIC                     := '0';
        CU_I    : out STD_LOGIC                     := '0';
        CU_IR   : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        -- output to ALU
        ALU_AXL : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_AXH : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_AY  : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_AOP : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_Cin : out STD_LOGIC                     := '0';
        ALU_REP : out STD_LOGIC                     := '0'
    );
end component;

-- ALU signals:
signal ALU_AXL : STD_LOGIC_VECTOR (7 downto 0);
signal ALU_AXH : STD_LOGIC_VECTOR (7 downto 0);
signal ALU_AY  : STD_LOGIC_VECTOR (7 downto 0);
signal ALU_AOP : STD_LOGIC_VECTOR (7 downto 0);
signal ALU_Cin : STD_LOGIC;
signal ALU_REP : STD_LOGIC;
signal ALU_AZL : STD_LOGIC_VECTOR (7 downto 0);
signal ALU_AZH : STD_LOGIC_VECTOR (7 downto 0);
signal ALU_C   : STD_LOGIC;
signal ALU_Z   : STD_LOGIC;
signal ALU_N   : STD_LOGIC;
signal ALU_V   : STD_LOGIC;
-- control unit signals
signal CU_C    : STD_LOGIC;
signal CU_Z    : STD_LOGIC;
signal CU_N    : STD_LOGIC;
signal CU_V    : STD_LOGIC;
signal CU_I    : STD_LOGIC;
signal CU_IR   : STD_LOGIC_VECTOR (7 downto 0);
signal SRC     : STD_LOGIC_VECTOR (4 downto 0);
signal DEST    : STD_LOGIC_VECTOR (4 downto 0);

begin

-- Control Unit:
C0: cu port map (
    CLK, CU_C, CU_Z, CU_N, CU_V, CU_I,
    IRQ, NMI, CU_IR, SRC, DEST
);

-- ALU:
C1: alu port map (
    ALU_AXL, ALU_AXH, ALU_AY, ALU_AOP, ALU_Cin, ALU_REP,
    ALU_AZL, ALU_AZH, ALU_C, ALU_Z, ALU_N, ALU_V
);

-- Registers:
C2: regs port map (
    CLK, Din, SRC, DEST, ALU_AZL, ALU_AZH, ALU_C, ALU_Z, ALU_N, ALU_V,
    MEME, RW, ADDR(7 downto 0), ADDR(15 downto 8), Dout, IAK, NAK,
    CU_C, CU_Z, CU_N, CU_V, CU_I, CU_IR,
    ALU_AXL, ALU_AXH, ALU_AY, ALU_AOP, ALU_Cin, ALU_REP
);

end Structural;
