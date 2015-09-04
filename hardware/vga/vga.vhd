----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:48:05 06/30/2014 
-- Design Name: 
-- Module Name:    vga - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga is
    Port ( CLK : in  STD_LOGIC; -- 50MHz clock input
			  -- System Bus
			  CS  : in STD_LOGIC;
           WR  : in STD_LOGIC;
           A   : in STD_LOGIC_VECTOR (13 downto 0);
           D   : in STD_LOGIC_VECTOR (7 downto 0);
			  -- VGA Port
			  R   : out STD_LOGIC_VECTOR (2 downto 0);
           G   : out STD_LOGIC_VECTOR (2 downto 0);
           B   : out STD_LOGIC_VECTOR (1 downto 0);
           HS  : out STD_LOGIC;
           VS  : out STD_LOGIC);
end vga;

architecture Structural of vga is

component clock_25M is
    Port ( clk_50M : in  STD_LOGIC;
           clk_25M : out  STD_LOGIC);
end component;

component graphics is
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
end component;

component vgaram0 is
    Port ( CLK         : in STD_LOGIC;
	 
	        ReadEnable  : in STD_LOGIC;
	        ReadAddr    : in STD_LOGIC_VECTOR (11 downto 0);
           ReadData    : out STD_LOGIC_VECTOR (7 downto 0);
			  
			  WriteEnable : in STD_LOGIC;
           WriteAddr   : in  STD_LOGIC_VECTOR (11 downto 0);
           WriteData   : in  STD_LOGIC_VECTOR (7 downto 0));
end component;

component vgaram1 is
    Port ( CLK         : in STD_LOGIC;
	 
	        ReadEnable  : in STD_LOGIC;
	        ReadAddr    : in STD_LOGIC_VECTOR (11 downto 0);
           ReadData    : out STD_LOGIC_VECTOR (7 downto 0);
			  
			  WriteEnable : in STD_LOGIC;
           WriteAddr   : in  STD_LOGIC_VECTOR (11 downto 0);
           WriteData   : in  STD_LOGIC_VECTOR (7 downto 0));
end component;

component vgaram2 is
    Port ( CLK         : in STD_LOGIC;
	 
	        ReadEnable  : in STD_LOGIC;
	        ReadAddr    : in STD_LOGIC_VECTOR (11 downto 0);
           ReadData    : out STD_LOGIC_VECTOR (7 downto 0);
			  
			  WriteEnable : in STD_LOGIC;
           WriteAddr   : in  STD_LOGIC_VECTOR (11 downto 0);
           WriteData   : in  STD_LOGIC_VECTOR (7 downto 0));
end component;

component vgaram3 is
    Port ( CLK         : in STD_LOGIC;
	 
	        ReadEnable  : in STD_LOGIC;
	        ReadAddr    : in STD_LOGIC_VECTOR (11 downto 0);
           ReadData    : out STD_LOGIC_VECTOR (7 downto 0);
			  
			  WriteEnable : in STD_LOGIC;
           WriteAddr   : in  STD_LOGIC_VECTOR (11 downto 0);
           WriteData   : in  STD_LOGIC_VECTOR (7 downto 0));
end component;

component sequencer is
    Port ( CLK       : in  STD_LOGIC;
	 
	        SE        : in  STD_LOGIC;
           X         : in  STD_LOGIC_VECTOR (15 downto 0);
           Y         : in  STD_LOGIC_VECTOR (15 downto 0);
			  
			  VRAM0Read : out  STD_LOGIC;
			  VRAM0Addr : out  STD_LOGIC_VECTOR (11 downto 0);
           VRAM0Data : in  STD_LOGIC_VECTOR  (7 downto 0);
			  
			  VRAM1Read : out  STD_LOGIC;
			  VRAM1Addr : out  STD_LOGIC_VECTOR (11 downto 0);
           VRAM1Data : in  STD_LOGIC_VECTOR  (7 downto 0);
			  
			  VRAM2Read : out  STD_LOGIC;
			  VRAM2Addr : out  STD_LOGIC_VECTOR (11 downto 0);
           VRAM2Data : in  STD_LOGIC_VECTOR  (7 downto 0);
			  
			  VRAM3Read : out  STD_LOGIC;
			  VRAM3Addr : out  STD_LOGIC_VECTOR (11 downto 0);
           VRAM3Data : in  STD_LOGIC_VECTOR  (7 downto 0);
			  
           Color     : out  STD_LOGIC_VECTOR (3 downto 0));
end component;

component dac is
    Port ( DE    : in  STD_LOGIC;
			  COLOR : in  STD_LOGIC_VECTOR (3 downto 0);
           R : out  STD_LOGIC_VECTOR (2 downto 0);
           G : out  STD_LOGIC_VECTOR (2 downto 0);
           B : out  STD_LOGIC_VECTOR (1 downto 0));
end component;

component crt is
    Port ( CLK : in  STD_LOGIC; -- 25 MHz input
           HS  : out STD_LOGIC := '0';
           VS  : out STD_LOGIC := '0';
			  SE  : out STD_LOGIC := '0';
			  DE  : out STD_LOGIC := '0';
           X   : out STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
           Y   : out STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000");
end component;

signal CLK_25M : STD_LOGIC;

signal VRAM0Write    : STD_LOGIC;
signal VRAM1Write    : STD_LOGIC;
signal VRAM2Write    : STD_LOGIC;
signal VRAM3Write    : STD_LOGIC;
signal VRAMWriteAddr : STD_LOGIC_VECTOR (11 downto 0);
signal VRAMWriteData : STD_LOGIC_VECTOR (7 downto 0);

signal SE      : STD_LOGIC;
signal DE      : STD_LOGIC;
signal X       : STD_LOGIC_VECTOR (15 downto 0);
signal Y       : STD_LOGIC_VECTOR (15 downto 0);
signal COLOR   : STD_LOGIC_VECTOR (3 downto 0);

signal VRAM0ReadEnable : STD_LOGIC;
signal VRAM0ReadAddr   : STD_LOGIC_VECTOR (11 downto 0);
signal VRAM0ReadData   : STD_LOGIC_VECTOR (7 downto 0);

signal VRAM1ReadEnable : STD_LOGIC;
signal VRAM1ReadAddr   : STD_LOGIC_VECTOR (11 downto 0);
signal VRAM1ReadData   : STD_LOGIC_VECTOR (7 downto 0);

signal VRAM2ReadEnable : STD_LOGIC;
signal VRAM2ReadAddr   : STD_LOGIC_VECTOR (11 downto 0);
signal VRAM2ReadData   : STD_LOGIC_VECTOR (7 downto 0);

signal VRAM3ReadEnable : STD_LOGIC;
signal VRAM3ReadAddr   : STD_LOGIC_VECTOR (11 downto 0);
signal VRAM3ReadData   : STD_LOGIC_VECTOR (7 downto 0);			  

begin

	u0: clock_25M port map (CLK, CLK_25M);
	u1: graphics  port map (CS, WR, A, D, VRAM0Write, VRAM1Write, VRAM2Write,
								   VRAM3Write, VRAMWriteAddr, VRAMWriteData);
	u2: vgaram0   port map (CLK, VRAM0ReadEnable, VRAM0ReadAddr, VRAM0ReadData,
	                        VRAM0Write, VRAMWriteAddr, VRAMWriteData);
	u3: vgaram1   port map (CLK, VRAM1ReadEnable, VRAM1ReadAddr, VRAM1ReadData,
	                        VRAM1Write, VRAMWriteAddr, VRAMWriteData);
	u4: vgaram2   port map (CLK, VRAM2ReadEnable, VRAM2ReadAddr, VRAM2ReadData,
	                        VRAM2Write, VRAMWriteAddr, VRAMWriteData);
	u5: vgaram3   port map (CLK, VRAM3ReadEnable, VRAM3ReadAddr, VRAM3ReadData,
	                        VRAM3Write, VRAMWriteAddr, VRAMWriteData);
	u6: sequencer port map (CLK_25M, SE, X, Y,
	                        VRAM0ReadEnable, VRAM0ReadAddr, VRAM0ReadData,
									VRAM1ReadEnable, VRAM1ReadAddr, VRAM1ReadData,
									VRAM2ReadEnable, VRAM2ReadAddr, VRAM2ReadData,
									VRAM3ReadEnable, VRAM3ReadAddr, VRAM3ReadData,
									COLOR);
	u7: dac       port map (DE, COLOR, R, G, B);
	u8: crt       port map (CLK_25M, HS, VS, SE, DE, X, Y);

end Structural;
