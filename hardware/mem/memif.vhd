library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity memif is
    Port (
        CLK      : in    STD_LOGIC;
        -- Interface
        RAM_CS   : in    STD_LOGIC; -- RAM chip enable
        ROM_CS   : in    STD_LOGIC; -- ROM chip enable
        RW       : in    STD_LOGIC; -- 0: read, 1: write
        A        : in    STD_LOGIC_VECTOR (23 downto 0);
        Din      : in    STD_LOGIC_VECTOR (31 downto 0);
        Dout     : out   STD_LOGIC_VECTOR (31 downto 0);
        DTYPE    : in    STD_LOGIC_VECTOR ( 2 downto 0);
        RDY      : out   STD_LOGIC := '1';
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

signal LAST_CS : BOOLEAN;

signal READ    : STD_LOGIC;
signal WRITE   : STD_LOGIC;

signal A16a    : STD_LOGIC_VECTOR (23 downto 0);
signal Din16a  : STD_LOGIC_VECTOR (15 downto 0);
signal Dout16a : STD_LOGIC_VECTOR (15 downto 0);
signal LB16a   : STD_LOGIC;
signal UB16a   : STD_LOGIC;
signal EN16a   : STD_LOGIC;

signal A16b    : STD_LOGIC_VECTOR (23 downto 0);
signal Din16b  : STD_LOGIC_VECTOR (15 downto 0);
signal Dout16b : STD_LOGIC_VECTOR (15 downto 0);
signal LB16b   : STD_LOGIC;
signal UB16b   : STD_LOGIC;
signal EN16b   : STD_LOGIC;

signal A16     : STD_LOGIC_VECTOR (23 downto 0) := x"000000";
signal Din16   : STD_LOGIC_VECTOR (15 downto 0) := x"0000";
signal Dout16  : STD_LOGIC_VECTOR (15 downto 0) := x"0000";
signal LB16    : STD_LOGIC := '0';
signal UB16    : STD_LOGIC := '0';
signal EN16    : STD_LOGIC := '0';

signal counter : integer range 0 to 100 := 0;

begin

-- Read and Write signals:
READ    <= (RAM_CS OR ROM_CS) AND EN16 AND (NOT RW);
WRITE   <= (RAM_CS          ) AND EN16 AND RW;

-- Address bus:
ADDR    <= A16; -- NOTE: ADDRESS(0) is unconnected.

-- Data bus:
Dout16  <= DATA (15 downto 0) when READ='1'  else "0000000000000000";
DATA    <= Din16(15 downto 0) when WRITE='1' else "ZZZZZZZZZZZZZZZZ";

-- Bus direction:
OE      <= NOT READ;
WE      <= NOT WRITE;

-- Chip Enable:
MT_CE   <= NOT (EN16 AND RAM_CS);
ST_CE   <= NOT (EN16 AND ROM_CS);

-- Which byte
MT_LB   <= NOT LB16;
MT_UB   <= NOT Ub16;

-- Dout signal
Dout    <= Dout16b & Dout16a when ((RAM_CS OR ROM_CS) AND (NOT RW))='1'
           else x"00000000";

-- 32-BIT bus interfacing
process (CLK)
begin

    if ( CLK = '1' and CLK'event ) then

        if ((NOT LAST_CS) and (RAM_CS = '1' OR ROM_CS = '1')) then
            -- startup of a new memory cycle
            counter <= 0;
            RDY <= '0';
            if (DTYPE(0) = '1') then
                -- BYTE
                A16a   <= A(23 downto 1) & "0";
                Din16a <= Din(7 downto 0) & Din(7 downto 0);
                LB16a  <= NOT A(0);
                UB16a  <= A(0);
                EN16a  <= '1';
                A16b   <= x"000000";
                Din16b <= x"0000";
                LB16b  <= '0';
                UB16b  <= '0';
                EN16b  <= '0';
            elsif (DTYPE(1) = '1') then
                -- HALF
                A16a   <= A(23 downto 1) & "0";
                Din16a <= Din(15 downto 0);
                LB16a  <= '1';
                UB16a  <= '1';
                EN16a  <= '1';
                A16b   <= x"000000";
                Din16b <= x"0000";
                LB16b  <= '0';
                UB16b  <= '0';
                EN16b  <= '0';
            elsif (DTYPE(2) = '1') then
                -- WORD
                A16a   <= A(23 downto 2) & "00";
                Din16a <= Din(15 downto 0);
                LB16a  <= '1';
                UB16a  <= '1';
                EN16a  <= '1';
                A16b   <= A(23 downto 2) & "10";
                Din16b <= Din(31 downto 16);
                LB16b  <= '1';
                UB16b  <= '1';
                EN16b  <= '1';
            end if;
        else
            -- increase counter
            if (counter < 7) then
                -- in phase 1
                A16     <= A16a;
                Din16   <= Din16a;
                LB16    <= LB16a;
                UB16    <= UB16a;
                EN16    <= EN16a;
                if (DTYPE(0) = '1') then
                    if (LB16a = '1') then
                        Dout16a <= x"00" & Dout16(7 downto 0);
                    else
                        Dout16a <= x"00" & Dout16(15 downto 8);
                    end if;
                else
                    Dout16a <= Dout16;
                end if;
                counter <= counter + 1;
            elsif (counter = 7) then
                -- before phase 2
                A16     <= x"000000";
                Din16   <= x"0000";
                LB16    <= '0';
                UB16    <= '0';
                EN16    <= '0';
                if (EN16b = '0') then
                    counter <= 14;
                else
                    counter <= counter + 1;
                end if;
            elsif (counter < 14) then
                -- in phase 2
                A16     <= A16b;
                Din16   <= Din16b;
                LB16    <= LB16b;
                UB16    <= UB16b;
                EN16    <= EN16b;
                Dout16b <= Dout16;
                counter <= counter + 1;
            else
                -- done
                A16     <= x"000000";
                Din16   <= x"0000";
                LB16    <= '0';
                UB16    <= '0';
                EN16    <= '0';
                RDY     <= '1';
            end if;
        end if;

        LAST_CS <= (RAM_CS = '1' OR ROM_CS = '1');

    end if;

end process;

end Dataflow;
