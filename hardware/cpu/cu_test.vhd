library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cu_test is
end entity;

architecture Structural of cu_test is

component cu is
    Port ( CLK  : in  STD_LOGIC;
           C    : in  STD_LOGIC;
           Z    : in  STD_LOGIC;
           N    : in  STD_LOGIC;
           V    : in  STD_LOGIC;
           I    : in  STD_LOGIC;
           IRQ  : in  STD_LOGIC;
           NMI  : in  STD_LOGIC;
           IR   : in  STD_LOGIC_VECTOR (7 downto 0);
           SRC  : out STD_LOGIC_VECTOR (4 downto 0);
           DEST : out STD_LOGIC_VECTOR (4 downto 0)
    );
end component;

signal CLK  : STD_LOGIC := '0';
signal C    : STD_LOGIC := '0';
signal Z    : STD_LOGIC := '0';
signal N    : STD_LOGIC := '0';
signal V    : STD_LOGIC := '0';
signal I    : STD_LOGIC := '0';
signal IRQ  : STD_LOGIC := '0';
signal NMI  : STD_LOGIC := '0';
signal IR   : STD_LOGIC_VECTOR (7 downto 0) := x"00";
signal SRC  : STD_LOGIC_VECTOR (4 downto 0);
signal DEST : STD_LOGIC_VECTOR (4 downto 0);
-- internal signals
signal SEQ  : STD_LOGIC_VECTOR (10 downto 0);
signal MIR  : STD_LOGIC_VECTOR (15 downto 0);
signal LUR  : STD_LOGIC_VECTOR (15 downto 0);
signal M    : STD_LOGIC;

begin

L: cu port map (CLK, C, Z, N, V, I, IRQ, NMI, IR, SRC, DEST);

SEQ <= work.cu_test_pkg.SEQ;
MIR <= work.cu_test_pkg.MIR;
LUR <= work.cu_test_pkg.LUR;
M   <= work.cu_test_pkg.M;

process
begin

    for i in 0 to 50 loop

        CLK <= '0';
        wait for 10 ns;
        CLK <= '1';
        wait for 10 ns;

    end loop;

end process;

end architecture;
