library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity add_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end add_unit;

architecture Dataflow of add_unit is

signal T : integer range 0 to 66000;
signal U : STD_LOGIC_VECTOR (15 downto 0);

begin

    -- calculate U = A+B+Cin
    with Cin select
        T <= conv_integer(unsigned(A))+conv_integer(unsigned(B))   when '0',
             conv_integer(unsigned(A))+conv_integer(unsigned(B))+1 when others;
    U <= conv_std_logic_vector(T, 16);

    -- Output R
    with CS select
        R <= U       when '1',
             x"0000" when others;

    -- output C
    C <= (U( 8) OR U( 9) OR U(10) OR U(11) OR
          U(12) OR U(13) OR U(14) OR U(15)) AND CS;

    -- output Z
    Z <= (NOT(U(0) OR U(1) OR U(2) OR U(3) OR
              U(4) OR U(5) OR U(6) OR U(7))) AND CS;

    -- output N
    N <= U(7) AND CS;

    -- output V
    V <= (((    A(7)) AND (    B(7)) AND (NOT U(7))) OR
          ((NOT A(7)) AND (NOT B(7)) AND (    U(7)))) AND CS;

end Dataflow;
