library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vgaram0 is
    Port ( CLK         : in STD_LOGIC;

			  ReadEnable  : in STD_LOGIC;
	        ReadAddr    : in STD_LOGIC_VECTOR (11 downto 0);
           ReadData    : out STD_LOGIC_VECTOR (7 downto 0) := "00000000";

			  WriteEnable : in STD_LOGIC;
           WriteAddr   : in  STD_LOGIC_VECTOR (11 downto 0);
           WriteData   : in  STD_LOGIC_VECTOR (7 downto 0));
end vgaram0;

architecture Behavioral of vgaram0 is

type ram_t is array (0 to 4095) of STD_LOGIC_VECTOR (7 downto 0);
signal ram : ram_t := (
	others => x"00"
);

begin

	process (clk)
	begin

		if (clk = '0' and clk'event) then
			if (WriteEnable = '1') then
				ram(conv_integer(unsigned(WriteAddr))) <= WriteData;
			end if;

			if (ReadEnable = '1') then
				ReadData <= ram(conv_integer(unsigned(ReadAddr)));
			else
				ReadData <= "00000000";
			end if;
		end if;

	end process;

        -- testing purposes:
        work.tlc_test_pkg.VGA_FIRST <= ram(0);

end Behavioral;
