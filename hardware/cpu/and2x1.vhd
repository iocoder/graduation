library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity and2x1 is
    Port (
        A : in  STD_LOGIC;
        B : in  STD_LOGIC;
        C : out STD_LOGIC
    );
end and2x1;

architecture Structural of and2x1 is

begin

C <= A AND B;

end architecture;
