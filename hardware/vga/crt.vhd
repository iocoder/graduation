----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:22:28 06/29/2014 
-- Design Name: 
-- Module Name:    crt - Behavioral 
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

entity crt is
    Port ( CLK : in  STD_LOGIC; -- 25 MHz input
           HS  : out STD_LOGIC := '0';
           VS  : out STD_LOGIC := '0';
			  SE  : out STD_LOGIC := '0';
			  DE  : out STD_LOGIC := '0';
           X   : out STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
           Y   : out STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000");
end crt;

architecture Behavioral of crt is

signal hcounter : integer range 0 to 1024 := 0;
signal vcounter : integer range 0 to 1024 := 0;

signal vblank : STD_LOGIC := '1';

signal cur_x : integer range 0 to 10240 := 0;
signal cur_y : integer range 0 to 10240 := 0;

begin

	process (CLK)
	begin
	
		if (CLK = '1' and CLK'event) then
		
			-- next pixel:
			if (hcounter < 96) then
				-- HS low pulse (96 clocks)
				HS <= '0';
			elsif (hcounter < 144) then
				-- Back porch (48 clocks)
				HS <= '1';
				if (hcounter = 143 and vblank = '0') then
					SE <= '1';
					cur_x <= cur_x + 1;
				end if;
			elsif (hcounter < 784) then
				-- Display time (640 clocks)
				if (vblank = '0') then
					DE    <= '1';
					SE    <= '1';
					X     <= conv_std_logic_vector(cur_x, 16);
					cur_x <= cur_x + 1;
				end if;
				if (hcounter = 783) then
					SE    <= '0';
					X     <= "0000000000000000";
					cur_x <= 0;			
				end if;
			else
				-- Front porch (16 clocks)
				-- Display disabled:
				DE    <= '0';
			end if;
			
			-- New line?
			if (hcounter = 0) then
			
				-- next line:
				if (vcounter < 2) then
					-- VS low pulse (2 lines)
					VS <= '0';
				elsif (vcounter < 31) then
					-- Back porch (29 lines)
					VS <= '1';
				elsif (vcounter < 511) then
					-- Display time (480 lines)
					vblank <= '0';
					Y      <= conv_std_logic_vector(cur_y, 16);
					cur_y  <= cur_y + 1;
				else
					-- Front porch (10 lines)
					-- Display disabled:
					vblank <= '1';
					cur_y  <= 0;
					Y      <= "0000000000000000";
				end if;
			
				-- increase vcounter
				if (vcounter = 520) then
					vcounter <= 0;
				else
					vcounter <= vcounter + 1;
				end if;
			
			end if;
			
			-- set the new value of hcounter (which will be
			-- used on next clock edge) according to the current
			-- value of hcounter:
			if (hcounter = 799) then
				hcounter <= 0; -- the new value
			else
				hcounter <= hcounter + 1; -- the new value
			end if;
			
		end if;
	
	end process;

end Behavioral;

