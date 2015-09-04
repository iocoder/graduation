library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity alu_test is
end alu_test;

architecture Behavioral of alu_test is

component alu is
    Port ( AXL : in  STD_LOGIC_VECTOR (7 downto 0);
           AXH : in  STD_LOGIC_VECTOR (7 downto 0);
           AY  : in  STD_LOGIC_VECTOR (7 downto 0);
           AOP : in  STD_LOGIC_VECTOR (7 downto 0);
           Cin : in  STD_LOGIC;
           REP : in  STD_LOGIC;
           AZL : out STD_LOGIC_VECTOR (7 downto 0);
           AZH : out STD_LOGIC_VECTOR (7 downto 0);
           C   : out STD_LOGIC;
           Z   : out STD_LOGIC;
           N   : out STD_LOGIC;
           V   : out STD_LOGIC);
end component;

signal AXL : STD_LOGIC_VECTOR (7 downto 0) := x"00";
signal AXH : STD_LOGIC_VECTOR (7 downto 0) := x"00";
signal AY  : STD_LOGIC_VECTOR (7 downto 0) := x"00";
signal AOP : STD_LOGIC_VECTOR (7 downto 0) := x"00";
signal Cin : STD_LOGIC := '0';
signal REP : STD_LOGIC := '0';
signal AZL : STD_LOGIC_VECTOR (7 downto 0);
signal AZH : STD_LOGIC_VECTOR (7 downto 0);
signal C   : STD_LOGIC;
signal Z   : STD_LOGIC;
signal N   : STD_LOGIC;
signal V   : STD_LOGIC;

begin

k: alu port map (AXL, AXH, AY, AOP, Cin, REP, AZL, AZH, C, Z, N, V);

process
begin

    AXL <= x"FC";
    AXH <= x"FF";
    AY  <= x"01";
    AOP <= x"00";
    Cin <= '0';
    REP <= '0';
    wait for 100 ns;
    AOP <= x"01"; -- add
    wait for 100 ns;
    AOP <= x"02"; -- sub
    wait for 100 ns;
    AOP <= x"04"; -- shl
    wait for 100 ns;
    AOP <= x"08"; -- shr
    wait for 100 ns;
    AOP <= x"10"; -- bit
    wait for 100 ns;
    AOP <= x"20"; -- and
    wait for 100 ns;
    AOP <= x"40"; -- ora
    wait for 100 ns;
    AOP <= x"80"; -- eor
    wait for 100 ns;
    AOP <= x"00";
    wait;

end process;

end Behavioral;
