library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity aluin is
    Port ( AXL : in  STD_LOGIC_VECTOR ( 7 downto 0);
           AXH : in  STD_LOGIC_VECTOR ( 7 downto 0);
           AY  : in  STD_LOGIC_VECTOR ( 7 downto 0);
           REP : in  STD_LOGIC;
           A   : out STD_LOGIC_VECTOR (15 downto 0);
           B   : out STD_LOGIC_VECTOR (15 downto 0));
end aluin;

architecture Dataflow of aluin is

begin

    -- A side:
    A( 0) <= AXL(0);
    A( 1) <= AXL(1);
    A( 2) <= AXL(2);
    A( 3) <= AXL(3);
    A( 4) <= AXL(4);
    A( 5) <= AXL(5);
    A( 6) <= AXL(6);
    A( 7) <= AXL(7);
    A( 8) <= AXH(0);
    A( 9) <= AXH(1);
    A(10) <= AXH(2);
    A(11) <= AXH(3);
    A(12) <= AXH(4);
    A(13) <= AXH(5);
    A(14) <= AXH(6);
    A(15) <= AXH(7);

    -- B side:
    B( 0) <= AY(0);
    B( 1) <= AY(1);
    B( 2) <= AY(2);
    B( 3) <= AY(3);
    B( 4) <= AY(4);
    B( 5) <= AY(5);
    B( 6) <= AY(6);
    B( 7) <= AY(7);
    B( 8) <= AY(7) AND REP;
    B( 9) <= AY(7) AND REP;
    B(10) <= AY(7) AND REP;
    B(11) <= AY(7) AND REP;
    B(12) <= AY(7) AND REP;
    B(13) <= AY(7) AND REP;
    B(14) <= AY(7) AND REP;
    B(15) <= AY(7) AND REP;

end Dataflow;
