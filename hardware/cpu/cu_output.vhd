library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cu_output is
    Port (
        SEQ  : in  STD_LOGIC_VECTOR (10 downto 0);
        MIR  : in  STD_LOGIC_VECTOR (15 downto 0);
        LUR  : in  STD_LOGIC_VECTOR (15 downto 0);
        M    : in  STD_LOGIC;
        SRC  : out STD_LOGIC_VECTOR (4 downto 0);
        DEST : out STD_LOGIC_VECTOR (4 downto 0)
    );
end cu_output;

architecture Dataflow of cu_output is

begin

SRC (0) <= MIR( 2) AND (NOT MIR(0)) AND (NOT MIR(1));
SRC (1) <= MIR( 3) AND (NOT MIR(0)) AND (NOT MIR(1));
SRC (2) <= MIR( 4) AND (NOT MIR(0)) AND (NOT MIR(1));
SRC (3) <= MIR( 5) AND (NOT MIR(0)) AND (NOT MIR(1));
SRC (4) <= MIR( 6) AND (NOT MIR(0)) AND (NOT MIR(1));
DEST(0) <= MIR( 7) AND (NOT MIR(0)) AND (NOT MIR(1));
DEST(1) <= MIR( 8) AND (NOT MIR(0)) AND (NOT MIR(1));
DEST(2) <= MIR( 9) AND (NOT MIR(0)) AND (NOT MIR(1));
DEST(3) <= MIR(10) AND (NOT MIR(0)) AND (NOT MIR(1));
DEST(4) <= MIR(11) AND (NOT MIR(0)) AND (NOT MIR(1));

-- for testing
work.cu_test_pkg.SEQ <= SEQ;
work.cu_test_pkg.MIR <= MIR;
work.cu_test_pkg.LUR <= LUR;
work.cu_test_pkg.M   <= M;

end architecture;
