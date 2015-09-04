library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity decoder is
    Port ( EN : in  STD_LOGIC;
	        I  : in  STD_LOGIC_VECTOR (2 downto 0);
           O  : out STD_LOGIC_VECTOR (7 downto 0));
end decoder;

architecture Dataflow of decoder is

begin

	O <= "00000001" when I = "000" AND EN = '1' else
		  "00000010" when I = "001" AND EN = '1' else
		  "00000100" when I = "010" AND EN = '1' else
		  "00001000" when I = "011" AND EN = '1' else
		  "00010000" when I = "100" AND EN = '1' else
		  "00100000" when I = "101" AND EN = '1' else
		  "01000000" when I = "110" AND EN = '1' else
		  "10000000" when I = "111" AND EN = '1' else
		  "00000000";

end Dataflow;
