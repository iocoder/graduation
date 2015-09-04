library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity alu_tlc is
    port (
        CLK : in  STD_LOGIC;
        SW  : in  STD_LOGIC_VECTOR (7 downto 0);
        BTN : in  STD_LOGIC;
        LED : out STD_LOGIC_VECTOR (7 downto 0) := x"00"
    );
end alu_tlc;

architecture Behavioral of alu_tlc is

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

signal counter : integer range 0 to 26000000 := 0;
signal step    : integer range 0 to 100 := 0;

begin

k: alu port map (AXL, AXH, AY, AOP, Cin, REP, AZL, AZH, C, Z, N, V);

process (CLK)
begin
    if (CLK = '1' and CLK'event) then

        if (BTN = '1' and counter = 250000) then

            if (step = 0) then
                AXL  <= SW;
                step <= 1;
            elsif (step = 1) then
                AXH  <= SW;
                step <= 2;
            elsif (step = 2) then
                AY   <= SW;
                step <= 3;
            elsif (step = 3) then
                AOP  <= SW;
                step <= 4;
            elsif (step = 4) then
                Cin  <= SW(0);
                REP  <= SW(1);
                step <= 5;
            end if;
            counter <= counter+1;
        elsif (BTN = '1' and counter = 250001) then
            if (step = 1) then
                LED <= x"01";
            elsif (step = 2) then
                LED <= x"02";
            elsif (step = 3) then
                LED <= x"03";
            elsif (step = 4) then
                LED <= x"04";
            elsif (step = 5) then
                LED  <= AZL;
                step <= 0;
            end if;
        elsif (BTN = '0') then
            counter <= 0;
        else
            if counter = 24999999 then
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
        end if;

    end if;

end process;

end Behavioral;
