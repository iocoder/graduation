library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity add_test is
end add_test;

architecture Dataflow of add_test is

component add_unit is
    Port ( CS  : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (15 downto 0);
           B   : in  STD_LOGIC_VECTOR (15 downto 0);
           Cin : in  STD_LOGIC;
           R   : out STD_LOGIC_VECTOR (15 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end component;

signal CS  : STD_LOGIC := '0';
signal A   : STD_LOGIC_VECTOR (15 downto 0) := x"0000";
signal B   : STD_LOGIC_VECTOR (15 downto 0) := x"0000";
signal Cin : STD_LOGIC := '0';
signal R   : STD_LOGIC_VECTOR (15 downto 0);
signal C   : STD_LOGIC;
signal Z   : STD_LOGIC;
signal N   : STD_LOGIC;
signal V   : STD_LOGIC;

begin

k: add_unit port map (CS, A, B, Cin, R, C, Z, N, V);

process
begin

    CS  <= '1';
    A   <= x"0001";
    B   <= x"0010";
    Cin <= '0';
    wait for 100 ns;
    CS  <= '0';
    wait for 100 ns;
    CS  <= '1';
    wait;

end process;

end Dataflow;
