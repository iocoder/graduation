library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tlc_test is
end entity;

architecture Structural of tlc_test is

component TLC is
    Port (
        -- The crystal:
        CLK : in  STD_LOGIC;
        -- VGA Connector
        R   : out STD_LOGIC_VECTOR (2 downto 0);
        G   : out STD_LOGIC_VECTOR (2 downto 0);
        B   : out STD_LOGIC_VECTOR (1 downto 0);
        HS  : out STD_LOGIC;
        VS  : out STD_LOGIC
    );
end component;

signal CLK       : STD_LOGIC := '0';
signal VGAFIRST  : STD_LOGIC_VECTOR (7 downto 0);

begin

L: TLC port map (CLK);
VGAFIRST <= work.tlc_test_pkg.VGA_FIRST;

process
begin

    for i in 0 to 100000 loop

        CLK <= '0';
        wait for 10 ns;
        CLK <= '1';
        wait for 10 ns;

    end loop;

end process;

end architecture;
