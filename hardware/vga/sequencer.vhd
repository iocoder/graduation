library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sequencer is
    Port (CLK        : in  STD_LOGIC;
          SE         : in  STD_LOGIC;
          ROW_BASE   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_ROW : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_COL : in  STD_LOGIC_VECTOR ( 7 downto 0);
          X          : in  STD_LOGIC_VECTOR (15 downto 0);
          Y          : in  STD_LOGIC_VECTOR (15 downto 0);
          VRAM0Read  : out STD_LOGIC := '0';
          VRAM0Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM0Data  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          VRAM1Read  : out STD_LOGIC := '0';
          VRAM1Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM1Data  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          VRAM2Read  : out STD_LOGIC := '0';
          VRAM2Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM2Data  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          VRAM3Read  : out STD_LOGIC := '0';
          VRAM3Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM3Data  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          Color      : out STD_LOGIC_VECTOR ( 3 downto 0) := "0000");
end sequencer;

architecture Dataflow of sequencer is

signal row_base_i : integer range 0 to 10240;
signal row_indx   : integer range 0 to 10240;
signal row        : integer range 0 to 10240;
signal col        : integer range 0 to 10240;
signal addr       : integer range 0 to 10240;

signal fg         : std_logic_vector (3 downto 0);
signal bg         : std_logic_vector (3 downto 0);
signal tcolor     : std_logic_vector (3 downto 0);
signal xcolor     : std_logic_vector (3 downto 0);

signal font_index : integer range 0 to 255;
signal font_row   : integer range 0 to 15;
signal font_addr  : integer range 0 to 4095;

signal fg_or_bg   : STD_LOGIC;

signal cursor_vis : boolean := true;
signal cursor_ctr : integer range 0 to 20000000 := 0;

begin

-- character place on screen:
row_base_i <= conv_integer(unsigned(ROW_BASE));
row_indx   <= conv_integer(unsigned(Y))/16;  -- row = y/16;
row <= row_base_i + row_indx when row_base_i + row_indx < 25 else
       row_base_i + row_indx - 25;
col  <= conv_integer(unsigned(X))/8;   -- col = x/8;
addr <= row*80+col; -- the address of the character in VRAM0.

-- setup VRAM0 and VRAM1 signals:
VRAM0Read <= SE;
VRAM0Addr <= conv_std_logic_vector( addr, VRAM0Addr'length );
VRAM1Read <= SE;
VRAM1Addr <= conv_std_logic_vector( addr, VRAM1Addr'length );

-- VRAM0Data contains the character, VRAM1Data contains colors
fg(0) <= VRAM1Data(0);
fg(1) <= VRAM1Data(1);
fg(2) <= VRAM1Data(2);
fg(3) <= VRAM1Data(3);
bg(0) <= VRAM1Data(4);
bg(1) <= VRAM1Data(5);
bg(2) <= VRAM1Data(6);
bg(3) <= VRAM1Data(7);

-- Font parameters:
font_index <= conv_integer(unsigned(VRAM0Data));
font_row   <= conv_integer(unsigned(Y)) mod 16;
font_addr  <= font_index*8+font_row/2;

-- Setup VRAM2 signals:
VRAM2Read <= SE when (conv_integer(unsigned(Y)) mod 2) = 0 else '0';
VRAM3Read <= SE when (conv_integer(unsigned(Y)) mod 2) = 1 else '0';
VRAM2Addr <= conv_std_logic_vector(font_addr, VRAM2Addr'length);
VRAM3Addr <= conv_std_logic_vector(font_addr, VRAM3Addr'length);

-- VRAM2Data contains a font row.
fg_or_bg <= VRAM2Data(7-(conv_integer(unsigned(X)) mod 8)) or
            VRAM3Data(7-(conv_integer(unsigned(X)) mod 8));

-- select color:
with fg_or_bg select tcolor <= fg when '1',
                               bg when others;

-- apply cursor
xcolor <= fg when (row_indx = conv_integer(cursor_row) and
                   col = conv_integer(cursor_col) and
                   cursor_vis and
                   font_row > 13) else tcolor;

-- fetch color and update cursor counter
process(CLK)
begin
    if (CLK='1' and CLK'event) then
        color <= xcolor;
        if (cursor_ctr = 14000000) then
            cursor_ctr <= 0;
            cursor_vis <= NOT cursor_vis;
        else
            cursor_ctr <= cursor_ctr + 1;
        end if;
    end if;
end process;

end Dataflow;
