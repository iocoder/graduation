library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity graphics is
    Port ( CS : in  STD_LOGIC;
			  WR : in  STD_LOGIC;
           A  : in  STD_LOGIC_VECTOR (13 downto 0);
           D  : in  STD_LOGIC_VECTOR (7 downto 0);
           VRAM0Write : out  STD_LOGIC;
           VRAM1Write : out  STD_LOGIC;
           VRAM2Write : out  STD_LOGIC;
           VRAM3Write : out  STD_LOGIC;
           VRAMAddr   : out  STD_LOGIC_VECTOR (11 downto 0);
           VRAMData   : out  STD_LOGIC_VECTOR (7 downto 0));
end graphics;

architecture Dataflow of graphics is

begin

	VRAM0Write <= CS and WR and (NOT A(0)) and (NOT A(13));
	VRAM1Write <= CS and WR and (    A(0)) and (NOT A(13));
	VRAM2Write <= CS and WR and (NOT A(0)) and (    A(13));
	VRAM3Write <= CS and WR and (    A(0)) and (    A(13));

	VRAMAddr( 0) <= A( 1);
	VRAMAddr( 1) <= A( 2);
	VRAMAddr( 2) <= A( 3);
	VRAMAddr( 3) <= A( 4);
	VRAMAddr( 4) <= A( 5);
	VRAMAddr( 5) <= A( 6);
	VRAMAddr( 6) <= A( 7);
	VRAMAddr( 7) <= A( 8);
	VRAMAddr( 8) <= A( 9);
	VRAMAddr( 9) <= A(10);
	VRAMAddr(10) <= A(11);
	VRAMAddr(11) <= A(12);
	
	VRAMData <= D;

end Dataflow;
