library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vgaram0 is
    Port (CLK           : in  STD_LOGIC;
          -- sequencer port:
          SeqReadEnable : in  STD_LOGIC;
          SeqAddr       : in  STD_LOGIC_VECTOR (11 downto 0);
          SeqDataOut    : out STD_LOGIC_VECTOR ( 7 downto 0) := "00000000";
          -- GU port:
          GUReadEnable  : in  STD_LOGIC;
          GUWriteEnable : in  STD_LOGIC;
          GUAddr        : in  STD_LOGIC_VECTOR (11 downto 0);
          GUDataIn      : in  STD_LOGIC_VECTOR ( 7 downto 0);
          GUDataOut     : out STD_LOGIC_VECTOR ( 7 downto 0));
end vgaram0;

architecture Behavioral of vgaram0 is

type ram_t is array (0 to 2047) of STD_LOGIC_VECTOR (7 downto 0);
signal ram : ram_t := (others => x"00");

begin

process (clk)
begin

    if (clk = '0' and clk'event) then
        if (GUWriteEnable = '1') then
            ram(conv_integer(unsigned(GUAddr))) <= GUDataIn;
        end if;
        if (GUReadEnable = '1') then
            SeqDataOut <= "00000000";
            GUDataOut  <= ram(conv_integer(unsigned(GUAddr)));
        elsif (SeqReadEnable = '1') then
            SeqDataOut <= ram(conv_integer(unsigned(SeqAddr)));
            GUDataOut  <= "00000000";
        else
            SeqDataOut <= "00000000";
            GUDataOut  <= "00000000";
        end if;
    end if;

end process;

end Behavioral;
