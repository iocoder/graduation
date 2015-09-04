library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity shr_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end shr_unit;

architecture Dataflow of shr_unit is

signal U : STD_LOGIC_VECTOR (15 downto 0) := x"0000";

begin

    -- Shift right by one bit
    U(0) <= A(1);
    U(1) <= A(2);
    U(2) <= A(3);
    U(3) <= A(4);
    U(4) <= A(5);
    U(5) <= A(6);
    U(6) <= A(7);
    U(7) <= Cin;

    -- Output R
    with CS select
        R <= U       when '1',
             x"0000" when others;

    -- output C
    C <= A(0) AND CS;

    -- output Z
    Z <= (NOT(U(0) OR U(1) OR U(2) OR U(3) OR
              U(4) OR U(5) OR U(6) OR U(7))) AND CS;

    -- output N
    N <= U(7) AND CS;

    -- output V
    V <= '0';

end Dataflow;
