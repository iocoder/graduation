library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity aluout is
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
end aluout;

architecture Dataflow of aluout is

signal R : STD_LOGIC_VECTOR (15 downto 0);

begin

    R <= R0 OR R1 OR R2 OR R3 OR R4 OR R5 OR R6 OR R7;
    C <= C0 OR C1 OR C2 OR C3 OR C4 OR C5 OR C6 OR C7;
    Z <= Z0 OR Z1 OR Z2 OR Z3 OR Z4 OR Z5 OR Z6 OR Z7;
    N <= N0 OR N1 OR N2 OR N3 OR N4 OR N5 OR N6 OR N7;
    V <= V0 OR V1 OR V2 OR V3 OR V4 OR V5 OR V6 OR V7;

    AZL(0) <= R( 0);
    AZL(1) <= R( 1);
    AZL(2) <= R( 2);
    AZL(3) <= R( 3);
    AZL(4) <= R( 4);
    AZL(5) <= R( 5);
    AZL(6) <= R( 6);
    AZL(7) <= R( 7);
    AZH(0) <= R( 8);
    AZH(1) <= R( 9);
    AZH(2) <= R(10);
    AZH(3) <= R(11);
    AZH(4) <= R(12);
    AZH(5) <= R(13);
    AZH(6) <= R(14);
    AZH(7) <= R(15);

end Dataflow;
