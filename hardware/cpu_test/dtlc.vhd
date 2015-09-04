library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity dtlc is

end entity;

architecture Structural of dtlc is

component dvga is
    Port (
        CLK      : in  STD_LOGIC; -- 50MHz clock input
        -- System Bus
        CS       : in STD_LOGIC;
        WR       : in STD_LOGIC;
        A        : in STD_LOGIC_VECTOR (13 downto 0);
        D        : in STD_LOGIC_VECTOR (7 downto 0);
        -- Debugging
        Finished : in  STD_LOGIC
    );
end component;

component dmemif is
    Port (
        CLK      : in    STD_LOGIC;
        -- Interface
        A        : in    STD_LOGIC_VECTOR (21 downto 0);
        Din      : in    STD_LOGIC_VECTOR (31 downto 0);
        Dout     : out   STD_LOGIC_VECTOR (31 downto 0);
        DTYPE    : in    STD_LOGIC_VECTOR (2  downto 0);
        RAM_CS   : in    STD_LOGIC; -- RAM chip enable
        ROM_CS   : in    STD_LOGIC; -- ROM chip enable
        RW       : in    STD_LOGIC; -- 0: read, 1: write
        -- Debugging
        Finished : in    STD_LOGIC
    );
end component;

-- Global Clock Signal
signal CLK          : STD_LOGIC := '0';

-- System bus:
signal EN           : STD_LOGIC := '0';
signal RW           : STD_LOGIC := '0';
signal Address      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal DataCPUToMem : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal DataMemToCPU : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal DataRAMToCPU : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal DataKBDToCPU : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal DTYPE        : STD_LOGIC_VECTOR ( 2 downto 0) := "000";
signal RAM_CS       : STD_LOGIC := '0';
signal ROM_CS       : STD_LOGIC := '0';
signal VGA_CS       : STD_LOGIC := '0';
signal KBD_CS       : STD_LOGIC := '0';

-- Debugging
signal Finished     : STD_LOGIC := '0';
signal CHAR         : STD_LOGIC_VECTOR (7 downto 0);
signal ATTR         : STD_LOGIC_VECTOR (7 downto 0);

begin

-- Combinational logic

DataMemToCPU <= DataRAMToCPU OR DataKBDToCPU;
ROM_CS <= '1' when Address(31 downto 16) = x"0000" else '0';
RAM_CS <= '1' when Address(31 downto 16) = x"0001" else '0';
VGA_CS <= '1' when Address(31 downto 15) = x"0001"&"1" else '0';
KBD_CS <= '1' when Address(31 downto 20) = x"FFF" else '0';

-- Blocks

U1: dmemif port map (CLK,
                     x"00" & Address(15 downto 2),
                     DataCPUToMem(31 downto 0),
                     DataRAMToCPU(31 downto 0),
                     DTYPE, RAM_CS, ROM_CS, RW, Finished);

U2: dvga port map (CLK, VGA_CS, RW,
                   Address(15 downto 2), DataCPUToMem(7 downto 0), Finished);

-- Generate clock signal

process
begin

    wait for 65536ns; -- until rom is loaded

    for i in 0 to 100000/20-2 - 3300 loop

        CLK <= '0';
        wait for 10 ns;
        CLK <= '1';
        wait for 10 ns;

        if (i = 10) then
            EN <= '1';
            RW <= '1';
            Address <= x"00010000";
            DataCPUToMem <= x"00000041";
            DTYPE <= "100";
        elsif (i = 20) then
            EN <= '1';
            RW <= '1';
            Address <= x"00010004";
            DataCPUToMem <= x"0000001F";
            DTYPE <= "100";
        elsif (i = 30) then
            EN <= '1';
            RW <= '0';
            Address <= x"00010000";
            DTYPE <= "001";
        elsif (i = 39) then
            DataCPUToMem <= DataMemToCPU;
        elsif (i = 40) then
            EN <= '1';
            RW <= '1';
            Address <= x"00018000";
            DTYPE <= "100";
        elsif (i = 50) then
            EN <= '1';
            RW <= '0';
            Address <= x"00010004";
            DTYPE <= "001";
        elsif (i = 59) then
            DataCPUToMem <= DataMemToCPU;
        elsif (i = 60) then
            EN <= '1';
            RW <= '1';
            Address <= x"00018004";
            DTYPE <= "100";
        elsif (i = 70) then
            EN <= '0';
        end if;

    end loop;

    Finished <= '1';

    CLK <= '0';
    wait for 10 ns;
    CLK <= '1';
    wait for 10 ns;

    Finished <= '0';

end process;

end Structural;
