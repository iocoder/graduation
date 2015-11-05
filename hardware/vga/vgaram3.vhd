library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vgaram3 is
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
          GUDataOut     : out STD_LOGIC_VECTOR ( 7 downto 0) := "00000000");
end vgaram3;

architecture Behavioral of vgaram3 is

begin

SeqDataOut <= x"00";
GUDataOut  <= x"00";

end Behavioral;
