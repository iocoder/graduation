----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:58:47 06/30/2014 
-- Design Name: 
-- Module Name:    clock_25M - Behavioral 
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

entity clock_25M is
    Port ( clk_50M : in  STD_LOGIC;
           clk_25M : out  STD_LOGIC);
end clock_25M;

architecture Behavioral of clock_25M is

signal counter : STD_LOGIC := '0';

begin

	process (clk_50M)
	begin
	
		if (clk_50M = '1' and clk_50M'event) then
			if (counter = '0') then
				clk_25M <= '1';
				counter <= '1';
			else
				clk_25M <= '0';
				counter <= '0';
			end if;
		end if;
	
	end process;
	
end Behavioral;
