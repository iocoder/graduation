library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity alu is
    Port ( AXL : in  STD_LOGIC_VECTOR (7 downto 0);
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
           V   : out STD_LOGIC);
end alu;

architecture Structural of alu is

component aluin is
    Port ( AXL : in  STD_LOGIC_VECTOR ( 7 downto 0);
           AXH : in  STD_LOGIC_VECTOR ( 7 downto 0);
           AY  : in  STD_LOGIC_VECTOR ( 7 downto 0);
           REP : in  STD_LOGIC;
           A   : out STD_LOGIC_VECTOR (15 downto 0);
           B   : out STD_LOGIC_VECTOR (15 downto 0));
end component;

component add_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end component;

component sub_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end component;

component shl_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end component;

component shr_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end component;

component bit_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end component;

component and_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end component;

component ora_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end component;

component eor_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end component;

component aluout is
    Port (R0, R1, R2, R3, R4, R5, R6, R7 : in STD_LOGIC_VECTOR (15 downto 0);
          C0, C1, C2, C3, C4, C5, C6, C7 : in STD_LOGIC;
          Z0, Z1, Z2, Z3, Z4, Z5, Z6, Z7 : in STD_LOGIC;
          N0, N1, N2, N3, N4, N5, N6, N7 : in STD_LOGIC;
          V0, V1, V2, V3, V4, V5, V6, V7 : in STD_LOGIC;
          AZL : out STD_LOGIC_VECTOR (7 downto 0);
          AZH : out STD_LOGIC_VECTOR (7 downto 0);
          C   : out STD_LOGIC;
          Z   : out STD_LOGIC;
          N   : out STD_LOGIC;
          V   : out STD_LOGIC);
end component;

signal A : STD_LOGIC_VECTOR (15 downto 0);
signal B : STD_LOGIC_VECTOR (15 downto 0);

signal R0, R1, R2, R3, R4, R5, R6, R7 : STD_LOGIC_VECTOR (15 downto 0);
signal C0, C1, C2, C3, C4, C5, C6, C7 : STD_LOGIC;
signal Z0, Z1, Z2, Z3, Z4, Z5, Z6, Z7 : STD_LOGIC;
signal N0, N1, N2, N3, N4, N5, N6, N7 : STD_LOGIC;
signal V0, V1, V2, V3, V4, V5, V6, V7 : STD_LOGIC;

begin

IM: aluin    port map (AXL, AXH, AY, REP, A, B);
M0: add_unit port map (AOP(0), A, B, Cin, R0, C0, Z0, N0, V0);
M1: sub_unit port map (AOP(1), A, B, Cin, R1, C1, Z1, N1, V1);
M2: shl_unit port map (AOP(2), A, B, Cin, R2, C2, Z2, N2, V2);
M3: shr_unit port map (AOP(3), A, B, Cin, R3, C3, Z3, N3, V3);
M4: bit_unit port map (AOP(4), A, B, Cin, R4, C4, Z4, N4, V4);
M5: and_unit port map (AOP(5), A, B, Cin, R5, C5, Z5, N5, V5);
M6: ora_unit port map (AOP(6), A, B, Cin, R6, C6, Z6, N6, V6);
M7: eor_unit port map (AOP(7), A, B, Cin, R7, C7, Z7, N7, V7);
OM: aluout   port map (R0, R1, R2, R3, R4, R5, R6, R7,
                       C0, C1, C2, C3, C4, C5, C6, C7,
                       Z0, Z1, Z2, Z3, Z4, Z5, Z6, Z7,
                       N0, N1, N2, N3, N4, N5, N6, N7,
                       V0, V1, V2, V3, V4, V5, V6, V7,
                       AZL, AZH, C, Z, N, V);

end Structural;
