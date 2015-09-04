library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity memif is
    Port (
        CLK      : in    STD_LOGIC;
        LED      : out   STD_LOGIC_VECTOR ( 7 downto 0);
        -- Interface
        A        : in    STD_LOGIC_VECTOR (23 downto 0);
        Din      : in    STD_LOGIC_VECTOR (15 downto 0);
        Dout     : out   STD_LOGIC_VECTOR ( 7 downto 0);
        CE       : in    STD_LOGIC; -- chip enable
        SEL      : in    STD_LOGIC; -- 0: RAM, 1: ROM
        RW       : in    STD_LOGIC; -- 0: read, 1: write
        PRG_EN   : in    STD_LOGIC; -- 0: disable ROM programming, 1: enable
        -- External Memory Bus:
        ADDR     : out   STD_LOGIC_VECTOR (23 downto 0);
        DATA     : inout STD_LOGIC_VECTOR (15 downto 0);
        OE       : out   STD_LOGIC := '1'; -- active low
        WE       : out   STD_LOGIC := '1'; -- active low
        MT_ADV   : out   STD_LOGIC := '0'; -- active low
        MT_CLK   : out   STD_LOGIC := '0';
        MT_UB    : out   STD_LOGIC := '1'; -- active low
        MT_LB    : out   STD_LOGIC := '1'; -- active low
        MT_CE    : out   STD_LOGIC := '1'; -- active low
        MT_CRE   : out   STD_LOGIC := '0'; -- active high
        MT_WAIT  : in    STD_LOGIC;
        ST_STS   : in    STD_LOGIC;
        RP       : out   STD_LOGIC := '1'; -- active low
        ST_CE    : out   STD_LOGIC := '1'  -- active low
    );
end memif;

architecture Dataflow of memif is

signal RAM   : STD_LOGIC;
signal ROM   : STD_LOGIC;
signal READ  : STD_LOGIC;
signal WRITE : STD_LOGIC;

signal counter : integer range 0 to 100 := 0;
signal LAST_CE : STD_LOGIC := '0';

begin

-- Chip Enable:
RAM     <= CE AND (NOT SEL);
ROM     <= CE AND SEL;

-- Read and Write signals:
READ    <= CE AND (NOT RW);
WRITE   <= CE AND RW AND ((NOT SEL) OR PRG_EN);

-- Address bus:
ADDR    <= A; -- NOTE: ADDRESS(0) is unconnected.

-- Data bus:
Dout    <= DATA( 7 downto 0) when READ = '1' and A(0) = '0' else
           DATA(15 downto 8) when READ = '1' and A(0) = '1' else
           x"00";
DATA    <= Din(7 downto 0)&Din(7 downto 0) when WRITE='1' and RAM='1' else
           Din(15 downto 0) when WRITE = '1' and ROM = '1' else
           "ZZZZZZZZZZZZZZZZ";

-- Bus direction:
OE      <= NOT READ;
WE      <= NOT WRITE;

-- Chip Enable:
MT_CE   <= NOT RAM;
ST_CE   <= NOT ROM;

-- Which byte
MT_LB   <= NOT((NOT A(0)) AND RAM);
MT_UB   <= NOT((    A(0)) AND RAM);

process(CLK)
begin
    if (CLK = '1' and CLK'event) then
        if (RAM = '1' and WRITE = '1' and A = x"000010") then
            LED <= Din(7 downto 0);
        end if;
    end if;
end process;

end Dataflow;
