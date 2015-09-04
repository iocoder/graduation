library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity bit_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end bit_unit;

architecture Dataflow of bit_unit is

signal U : STD_LOGIC_VECTOR (15 downto 0) := x"0000";

begin

    -- U = A and B
    U <= A AND B;

    -- Output R
    with CS select
        R <= U       when '1',
             x"0000" when others;

    -- output C
    C <= '0';

    -- output Z
    Z <= (NOT(U(0) OR U(1) OR U(2) OR U(3) OR
              U(4) OR U(5) OR U(6) OR U(7))) AND CS;

    -- output N
    N <= A(7) AND CS;

    -- output V
    V <= A(6) AND CS;

end Dataflow;
