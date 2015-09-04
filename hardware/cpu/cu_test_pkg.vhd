library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package cu_test_pkg is
    -- internal signals of cu
    signal SEQ  : STD_LOGIC_VECTOR (10 downto 0);
    signal MIR  : STD_LOGIC_VECTOR (15 downto 0);
    signal LUR  : STD_LOGIC_VECTOR (15 downto 0);
    signal M    : STD_LOGIC;
end package;
