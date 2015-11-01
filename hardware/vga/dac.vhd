library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity dac is
    Port (DE    : in  STD_LOGIC;
          COLOR : in  STD_LOGIC_VECTOR (3 downto 0);
          R     : out STD_LOGIC_VECTOR (2 downto 0);
          G     : out STD_LOGIC_VECTOR (2 downto 0);
          B     : out STD_LOGIC_VECTOR (1 downto 0));
end dac;

architecture Behavioral of dac is

type palette_t is array (0 to 15) of STD_LOGIC_VECTOR (7 downto 0);
signal palette : palette_t := (
    -- RRRGGGBB
    "00000000", -- 0 BLACK
    "00000010", -- 1 BLUE
    "00010100", -- 2 GREEN
    "00010110", -- 3 CYAN
    "10100000", -- 4 RED
    "10100010", -- 5 VIOLET
    "10101000", -- 6 BROWN
    "10110110", -- 7 GRAY
    "01001001", -- 8 GRAY DARK
    "01001011", -- 9 LIGHT BLUE
    "01011101", -- A LIGHT GREEN
    "01011111", -- B LIGHT CYAN
    "11101001", -- C LIGHT RED
    "11101011", -- D LIGHT VIOLET
    "11111101", -- E YELLOW
    "11111111"  -- F WHITE
);

begin

B(0) <= palette(conv_integer(unsigned(COLOR)))(0) AND DE;
B(1) <= palette(conv_integer(unsigned(COLOR)))(1) AND DE;
G(0) <= palette(conv_integer(unsigned(COLOR)))(2) AND DE;
G(1) <= palette(conv_integer(unsigned(COLOR)))(3) AND DE;
G(2) <= palette(conv_integer(unsigned(COLOR)))(4) AND DE;
R(0) <= palette(conv_integer(unsigned(COLOR)))(5) AND DE;
R(1) <= palette(conv_integer(unsigned(COLOR)))(6) AND DE;
R(2) <= palette(conv_integer(unsigned(COLOR)))(7) AND DE;

end Behavioral;
