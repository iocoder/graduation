library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity dac is
    Port (DE    : in  STD_LOGIC;
          MODE  : in  STD_LOGIC;
          COLOR : in  STD_LOGIC_VECTOR (5 downto 0);
          R     : out STD_LOGIC_VECTOR (2 downto 0);
          G     : out STD_LOGIC_VECTOR (2 downto 0);
          B     : out STD_LOGIC_VECTOR (1 downto 0));
end dac;

architecture Behavioral of dac is

type vga_palette_t is array (0 to 15) of STD_LOGIC_VECTOR (7 downto 0);
signal vga_palette : vga_palette_t := (
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

type ppu_palette_t is array (0 to 63) of STD_LOGIC_VECTOR (7 downto 0);
signal ppu_palette : ppu_palette_t := (
    "01101101",
    "00100010",
    "00000010",
    "01000010",
    "10000001",
    "10100000",
    "10100000",
    "01100000",
    "01000100",
    "00001000",
    "00001000",
    "00000100",
    "00000101",
    "00000000",
    "00000000",
    "00000000",
    "10110110",
    "00001111",
    "00100111",
    "10000011",
    "10100010",
    "11100001",
    "11000100",
    "11001000",
    "10001100",
    "00010000",
    "00010100",
    "00010000",
    "00010010",
    "00000000",
    "00000000",
    "00000000",
    "11111111",
    "00110111",
    "01010011",
    "11010011",
    "11101111",
    "11101110",
    "11101101",
    "11110000",
    "11110100",
    "10011000",
    "01011001",
    "01011110",
    "00011111",
    "01101101",
    "00000000",
    "00000000",
    "11111111",
    "10111111",
    "11011011",
    "11011011",
    "11111011",
    "11111011",
    "11110110",
    "11111010",
    "11111110",
    "11111110",
    "10111110",
    "10111111",
    "10011111",
    "11011011",
    "00000000",
    "00000000"
);

begin

B(0) <= '0'                                           when DE   = '0' else
        vga_palette(conv_integer(unsigned(COLOR)))(0) when MODE = '0' else
        ppu_palette(conv_integer(unsigned(COLOR)))(0);

B(1) <= '0'                                           when DE   = '0' else
        vga_palette(conv_integer(unsigned(COLOR)))(1) when MODE = '0' else
        ppu_palette(conv_integer(unsigned(COLOR)))(1);

G(0) <= '0'                                           when DE   = '0' else
        vga_palette(conv_integer(unsigned(COLOR)))(2) when MODE = '0' else
        ppu_palette(conv_integer(unsigned(COLOR)))(2);

G(1) <= '0'                                           when DE   = '0' else
        vga_palette(conv_integer(unsigned(COLOR)))(3) when MODE = '0' else
        ppu_palette(conv_integer(unsigned(COLOR)))(3);

G(2) <= '0'                                           when DE   = '0' else
        vga_palette(conv_integer(unsigned(COLOR)))(4) when MODE = '0' else
        ppu_palette(conv_integer(unsigned(COLOR)))(4);

R(0) <= '0'                                           when DE   = '0' else
        vga_palette(conv_integer(unsigned(COLOR)))(5) when MODE = '0' else
        ppu_palette(conv_integer(unsigned(COLOR)))(5);

R(1) <= '0'                                           when DE   = '0' else
        vga_palette(conv_integer(unsigned(COLOR)))(6) when MODE = '0' else
        ppu_palette(conv_integer(unsigned(COLOR)))(6);

R(2) <= '0'                                           when DE   = '0' else
        vga_palette(conv_integer(unsigned(COLOR)))(7) when MODE = '0' else
        ppu_palette(conv_integer(unsigned(COLOR)))(7);

end Behavioral;
