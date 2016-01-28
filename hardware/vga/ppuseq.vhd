library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ppuseq is
    Port (CLK        : in  STD_LOGIC;
          SE         : in  STD_LOGIC;
          ROW_BASE   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_ROW : in  STD_LOGIC_VECTOR ( 7 downto 0);
          CURSOR_COL : in  STD_LOGIC_VECTOR ( 7 downto 0);
          PPU_CTRL   : in  STD_LOGIC_VECTOR (15 downto 0);
          PPU_HSCR   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          PPU_VSCR   : in  STD_LOGIC_VECTOR ( 7 downto 0);
          X          : in  STD_LOGIC_VECTOR (15 downto 0);
          Y          : in  STD_LOGIC_VECTOR (15 downto 0);
          B9         : in  STD_LOGIC := '0';
          VRAM0Read  : out STD_LOGIC := '0';
          VRAM0Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM0Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM1Read  : out STD_LOGIC := '0';
          VRAM1Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM1Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM2Read  : out STD_LOGIC := '0';
          VRAM2Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM2Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM3Read  : out STD_LOGIC := '0';
          VRAM3Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM3Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          VRAM4Read  : out STD_LOGIC := '0';
          VRAM4Addr  : out STD_LOGIC_VECTOR (10 downto 0);
          VRAM4Data  : in  STD_LOGIC_VECTOR ( 8 downto 0);
          PalRD      : in  STD_LOGIC;
          PalWR      : in  STD_LOGIC;
          PalAddr    : in  STD_LOGIC_VECTOR ( 4 downto 0);
          PalDataIn  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          PalDataOut : out STD_LOGIC_VECTOR ( 7 downto 0);
          Color      : out STD_LOGIC_VECTOR ( 5 downto 0) := "000000");
end ppuseq;

architecture Dataflow of ppuseq is

signal  phase   : integer := 0;
signal  counter : integer := 0;

signal  V       : STD_LOGIC := '0';               -- vert. nametable
signal  H       : STD_LOGIC := '0';               -- hori. nametable
signal  VT      : STD_LOGIC_VECTOR ( 4 downto 0); -- vert. tile index
signal  HT      : STD_LOGIC_VECTOR ( 4 downto 0); -- hori. tile index
signal  FV      : STD_LOGIC_VECTOR ( 2 downto 0); -- vert. pixel index
signal  FH      : STD_LOGIC_VECTOR ( 2 downto 0); -- hori. pixel index

signal  PatAddr : STD_LOGIC_VECTOR (12 downto 0) := "0" & x"000";
signal  PatRead : STD_LOGIC := '0';
signal  PatData : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";

type palette_t is array (0 to 15) of STD_LOGIC_VECTOR (5 downto 0);
signal  PatPal  : palette_t := (others => "000000"); -- pattern palette
signal  SprPal  : palette_t := (others => "000000"); -- sprite palette

signal lastPalRD : STD_LOGIC := '0';
signal lastPalWR : STD_LOGIC := '0';

begin

VRAM0Addr <= PatAddr(10 downto 0);
VRAM1Addr <= PatAddr(10 downto 0);
VRAM2Addr <= PatAddr(10 downto 0);
VRAM3Addr <= PatAddr(10 downto 0);

VRAM0Read <= PatRead and (NOT PatAddr(11)) and (NOT PatAddr(12));
VRAM1Read <= PatRead and (    PatAddr(11)) and (NOT PatAddr(12));
VRAM2Read <= PatRead and (NOT PatAddr(11)) and (    PatAddr(12));
VRAM3Read <= PatRead and (    PatAddr(11)) and (    PatAddr(12));

PatData   <= VRAM0Data or VRAM1Data or VRAM2Data or VRAM3Data;

process (CLK)

variable  tcolor  : STD_LOGIC_VECTOR ( 3 downto 0) := "0000";
variable  ashift  : STD_LOGIC_VECTOR ( 2 downto 0) := "000";

begin

    if (CLK = '1' and CLK'event ) then
        if (SE = '0') then
            phase   <= 0;
            counter <= 0;
            if (phase /= 0) then
                color <= "111111";
            else
                color <= "000000";
            end if;
        else
            if (phase = 0) then
                -- here we introduce little delay so that next line
                -- is drawn in the middle of screen.
                color   <= "111111";
                if (counter < 131) then
                    counter <= counter + 1;
                else
                    counter <= 0;
                    phase   <= 1;
                    -- beginning of a new row. Is this the first scanline?
                    if (Y = x"0000") then
                        -- first line on screen, reset horizontal and vertical
                        H  <= PPU_CTRL(0);
                        HT <= PPU_HSCR(7 downto 3);
                        FH <= PPU_HSCR(2 downto 0);
                        V  <= PPU_CTRL(1);
                        VT <= PPU_VSCR(7 downto 3);
                        FV <= PPU_VSCR(2 downto 0);
                    else
                        -- next line, reset horizontal counters
                        H  <= PPU_CTRL(0);
                        HT <= PPU_HSCR(7 downto 3);
                        FH <= PPU_HSCR(2 downto 0);
                    end if;
                end if;
            elsif (phase = 1) then
                -- first step: load pattern index from nametab
                VRAM4Read <= '1';
                VRAM4Addr <= H & VT & HT;
                -- go to next step
                phase <= 2;
            elsif (phase = 2) then
                -- second step:
                -- (a) load lowest bit of color
                PatAddr <= PPU_CTRL(4) & VRAM4Data(7 downto 0) & "0" & FV;
                PatRead <= '1';
                -- (b) load associated attribute
                VRAM4Addr <= H & "1111" & VT(4 downto 2) & HT(4 downto 2);
                -- go to next step
                phase <= 3;
            elsif (phase = 3) then
                -- third step:
                -- (a) read the lowest bit of color we have loaded:
                tcolor(0) := PatData(7-conv_integer(unsigned(FH)));
                -- (b) read highest two bits of color from attribute:
                ashift    := VT(1)&HT(1)&"0";
                tcolor(2) := VRAM4Data(conv_integer(unsigned(ashift))+0);
                tcolor(3) := VRAM4Data(conv_integer(unsigned(ashift))+1);
                -- (c) load second order bit of color
                PatAddr(3) <= '1';
                -- (d) no more reads from nametab
                VRAM4Read <= '0';
                -- go to next step
                phase <= 4;
            elsif (phase = 4) then
                -- fourth step:
                -- (a) read second order bit of color we have loaded
                tcolor(1) := PatData(7-conv_integer(unsigned(FH)));
                -- (b) output color
                if (tcolor(1) = '0' and tcolor(0) = '0') then
                    -- background color
                    color <= PatPal(0);
                else
                    color <= PatPal(conv_integer(unsigned(tcolor)));
                end if;
                -- (c) no more reads from pattern table
                PatRead <= '0';
                -- prepare next column:
                if (FH /= "111") then
                    -- next pixel inside the tile
                    FH <= conv_std_logic_vector(
                            conv_integer(unsigned(FH))+1,3);
                else
                    -- next tile
                    FH <= "000";
                    if (HT /= "11111") then
                        -- next tile inside window
                        HT <= conv_std_logic_vector(
                                conv_integer(unsigned(HT))+1,5);
                    else
                        -- next window
                        HT <= "00000";
                        H  <= NOT H;
                    end if;
                end if;
                -- move to next state
                if (counter < 255) then
                    counter <= counter + 1;
                    phase   <= 1;
                else
                    phase   <= 5;
                end if;
            elsif (phase = 5) then
                phase <= 6;
            elsif (phase = 6) then
                phase <= 7;
            elsif (phase = 7) then
                phase <= 8;
                -- next row:
                if (Y(0) = '1') then
                    if (FV /= "111") then
                        -- next pixel inside the tile
                        FV <= conv_std_logic_vector(
                                conv_integer(unsigned(FV))+1,3);
                    else
                        -- next tile
                        FV <= "000";
                        if (VT /= "11111") then
                            -- next tile inside window
                            VT <= conv_std_logic_vector(
                                    conv_integer(unsigned(VT))+1,5);
                        else
                            -- next window
                            VT <= "00000";
                            V  <= NOT V;
                        end if;
                    end if;
                end if;
            else
                color <= "111111";
            end if;
        end if;
    end if;

end process;


process (CLK)
begin

    if (CLK = '0' and CLK'event ) then
        if (lastPalRD /= PalRD and PalRD='1') then
            -- read
            if (PalAddr(4) = '0') then
                PalDataOut(5 downto 0) <= PatPal(
                    conv_integer(unsigned(PalAddr(3 downto 0))));
            else
                PalDataOut(5 downto 0) <= SprPal(
                    conv_integer(unsigned(PalAddr(3 downto 0))));
            end if;
        end if;
        if (lastPalWR /= PalWR and PalWR='1') then
            -- write
            if (PalAddr(4) = '0') then
                PatPal(conv_integer(unsigned(PalAddr(3 downto 0))))
                    <= PalDataIn(5 downto 0);
            else
                SprPal(conv_integer(unsigned(PalAddr(3 downto 0))))
                    <= PalDataIn(5 downto 0);
            end if;
        end if;
        lastPalRD <= PalRD;
        lastPalWR <= PalWR;
    end if;
end process;

end Dataflow;
