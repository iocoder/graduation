library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cu is
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
end cu;

architecture Structural of cu is

component microcode is
    Port ( CLK     : in  STD_LOGIC;
           ADDRESS : in  STD_LOGIC_VECTOR (10 downto 0);
           DATA    : out STD_LOGIC_VECTOR (15 downto 0)
    );
end component;

component lookup is
    Port ( CLK     : in  STD_LOGIC;
           ADDRESS : in  STD_LOGIC_VECTOR ( 7 downto 0);
           DATA    : out STD_LOGIC_VECTOR (15 downto 0)
    );
end component;

component not1x1 is
    Port (
        A : in  STD_LOGIC;
        B : out STD_LOGIC
    );
end component;

component and2x1 is
    Port (
        A : in  STD_LOGIC;
        B : in  STD_LOGIC;
        C : out STD_LOGIC
    );
end component;

component mux8x1 is
    Port ( EN   : in  STD_LOGIC;
           I0   : in  STD_LOGIC;
           I1   : in  STD_LOGIC;
           I2   : in  STD_LOGIC;
           I3   : in  STD_LOGIC;
           I4   : in  STD_LOGIC;
           I5   : in  STD_LOGIC;
           I6   : in  STD_LOGIC;
           I7   : in  STD_LOGIC;
           C0   : in  STD_LOGIC;
           C1   : in  STD_LOGIC;
           C2   : in  STD_LOGIC;
           O    : out STD_LOGIC
    );
end component;

component cu_logic is
    Port (
        CLK  : in    STD_LOGIC;
        SEQ  : inout STD_LOGIC_VECTOR (10 downto 0);
        MIR  : in    STD_LOGIC_VECTOR (15 downto 0);
        LUR  : in    STD_LOGIC_VECTOR (15 downto 0);
        M    : in    STD_LOGIC
    );
end component;

component cu_output is
    Port (
        SEQ  : in  STD_LOGIC_VECTOR (10 downto 0);
        MIR  : in  STD_LOGIC_VECTOR (15 downto 0);
        LUR  : in  STD_LOGIC_VECTOR (15 downto 0);
        M    : in  STD_LOGIC;
        SRC  : out STD_LOGIC_VECTOR (4 downto 0);
        DEST : out STD_LOGIC_VECTOR (4 downto 0)
    );
end component;

signal SEQ : STD_LOGIC_VECTOR (10 downto 0) := "00000000000"; -- sequencer
signal MIR : STD_LOGIC_VECTOR (15 downto 0) := x"0000"; -- microinstruction
signal LUR : STD_LOGIC_VECTOR (15 downto 0) := x"0000"; -- lookup reg
signal NI  : STD_LOGIC; -- inverse of I input.
signal INT : STD_LOGIC; -- NI AND IRQ
signal M   : STD_LOGIC; -- multiplexor output

begin

-- ROM fetches the micro-instruction and LUR on rising edge.
-- the multiplexor is combinatorial circuit.
-- We decode MIR and calculate the new value of SEQ on falling edge.
-- The cpu decodes SRC and DEST on rising edge.

C1: microcode port map (CLK, SEQ, MIR);
C2: lookup    port map (CLK, IR,  LUR);
C3: not1x1    port map (I, NI);
C4: and2x1    port map (IRQ, NI, INT);
C5: mux8x1    port map (MIR(1),'1',C,Z,N,V,NMI,INT,'0',MIR(2),MIR(3),MIR(4),M);
C6: cu_logic  port map (CLK, SEQ, MIR, LUR, M);
C7: cu_output port map (SEQ, MIR, LUR, M, SRC, DEST);

end Structural;
