library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.cpu_pkg.all;

entity cache is
    Port (
        CLK50MHz : in  STD_LOGIC;
        CLK2MHz  : in  STD_LOGIC;
        -- CPU interface
        iMEME    : in  STD_LOGIC;
        iRW      : in  STD_LOGIC;
        iADDR    : in  STD_LOGIC_VECTOR (31 downto 0);
        iDin     : in  STD_LOGIC_VECTOR (31 downto 0);
        iDout    : out STD_LOGIC_VECTOR (31 downto 0);
        iDTYPE   : in  STD_LOGIC_VECTOR ( 2 downto 0);
        dMEME    : in  STD_LOGIC;
        dRW      : in  STD_LOGIC;
        dADDR    : in  STD_LOGIC_VECTOR (31 downto 0);
        dDin     : in  STD_LOGIC_VECTOR (31 downto 0);
        dDout    : out STD_LOGIC_VECTOR (31 downto 0);
        dDTYPE   : in  STD_LOGIC_VECTOR ( 2 downto 0);
        -- system bus interface
        MPULSE   : out STD_LOGIC := '0';
        MEME     : out STD_LOGIC := '0';
        RW       : out STD_LOGIC := '0';
        ADDR     : out STD_LOGIC_VECTOR (31 downto 0);
        Din      : in  STD_LOGIC_VECTOR (31 downto 0);
        Dout     : out STD_LOGIC_VECTOR (31 downto 0);
        DTYPE    : out STD_LOGIC_VECTOR ( 2 downto 0)
    );
end entity;

architecture Behavioral of cache is

signal phase         : integer := 1;
signal instr_reg     : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal data_reg      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal phase_counter : integer range 0 to 1000 := 24;

begin

process (CLK50MHz)
begin

    if ( CLK50MHz = '1' and CLK50MHz'event ) then

        if (phase_counter = 24) then
            -- begin new phase
            phase_counter <= 0;
            if (phase = 1) then
                -- ENTER PHASE 0: iMEM
                phase <= 0;
            else
                -- ENTER PHASE 1: dMEM
                phase <= 1;
            end if;
        else
            phase_counter <= phase_counter + 1;
            if (phase = 0) then
                -- PHASE 0: iMEM
                instr_reg <= Din;
            else
                -- PHASE 1: dMEM
                data_reg <= Din;
            end if;
        end if;

    end if;

end process;

MPULSE <= iMEME  when phase_counter = 0 and phase = 0 else
          dMEME  when phase_counter = 0 and phase = 1 else
          '0';
MEME   <= iMEME  when phase = 0 else dMEME;
RW     <= iRW    when phase = 0 else dRW;
ADDR   <= iADDR  when phase = 0 else dADDR;
Dout   <= iDin   when phase = 0 else dDin;
DTYPE  <= iDTYPE when phase = 0 else dDTYPE;
iDout  <= instr_reg;
dDout  <= data_reg;

end Behavioral;
