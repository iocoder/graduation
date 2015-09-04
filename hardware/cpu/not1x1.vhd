library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity not1x1 is
    Port (
        A : in  STD_LOGIC;
        B : out STD_LOGIC
    );
end not1x1;

architecture Structural of not1x1 is

begin

B <= NOT A;

end architecture;
