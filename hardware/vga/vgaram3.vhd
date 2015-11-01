library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vgaram3 is
    Port (CLK         : in  STD_LOGIC;
          ReadEnable  : in  STD_LOGIC;
          ReadAddr    : in  STD_LOGIC_VECTOR (11 downto 0);
          ReadData    : out STD_LOGIC_VECTOR (7 downto 0) := "00000000";
          WriteEnable : in  STD_LOGIC;
          WriteAddr   : in  STD_LOGIC_VECTOR (11 downto 0);
          WriteData   : in  STD_LOGIC_VECTOR (7 downto 0));
end vgaram3;

architecture Behavioral of vgaram3 is

begin

ReadData <= x"00";

end Behavioral;
