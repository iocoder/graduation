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
          SprRD      : in  STD_LOGIC;
          SprWR      : in  STD_LOGIC;
          SprAddr    : in  STD_LOGIC_VECTOR ( 7 downto 0);
          SprDataIn  : in  STD_LOGIC_VECTOR ( 7 downto 0);
          SprDataOut : out STD_LOGIC_VECTOR ( 7 downto 0);
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

signal  PatAddr : STD_LOGIC_VECTOR (12 downto 0) := "0" & x"000";
signal  PatRead : STD_LOGIC := '0';
signal  PatData : STD_LOGIC_VECTOR (15 downto 0) := x"0000";

-- sprites
type sprites_t is array (0 to 255) of STD_LOGIC_VECTOR (7 downto 0);
signal  sprites : sprites_t := (others => x"00");

type sprcache_t is array (0 to 7) of STD_LOGIC_VECTOR (31 downto 0);
signal  sprcache : sprcache_t := (others => x"00000000");

signal lastSprRD : STD_LOGIC := '0';
signal lastSprWR : STD_LOGIC := '0';

-- palette

type palette_t is array (0 to 15) of STD_LOGIC_VECTOR (5 downto 0);
signal  PatPal  : palette_t := (others => "000000"); -- pattern palette
signal  SprPal  : palette_t := (others => "000000"); -- sprite palette

signal lastPalRD : STD_LOGIC := '0';
signal lastPalWR : STD_LOGIC := '0';

attribute ram_style: string;
attribute ram_style of sprites : signal is "block";
-- attribute ram_style of sprcache : signal is "block";

begin

VRAM0Addr <= PatAddr(11 downto 4) & PatAddr(2 downto 0);
VRAM1Addr <= PatAddr(11 downto 4) & PatAddr(2 downto 0);
VRAM2Addr <= PatAddr(11 downto 4) & PatAddr(2 downto 0);
VRAM3Addr <= PatAddr(11 downto 4) & PatAddr(2 downto 0);

VRAM0Read <= PatRead and (NOT PatAddr(12));
VRAM1Read <= PatRead and (NOT PatAddr(12));
VRAM2Read <= PatRead and (    PatAddr(12));
VRAM3Read <= PatRead and (    PatAddr(12));

PatData( 7 downto 0) <= VRAM0Data or VRAM2Data;
PatData(15 downto 8) <= VRAM1Data or VRAM3Data;

process (CLK)

variable  tcolor  : STD_LOGIC_VECTOR ( 3 downto 0) := "0000";
variable  scolor  : STD_LOGIC_VECTOR ( 3 downto 0) := "0000";
variable  ashift  : STD_LOGIC_VECTOR ( 2 downto 0) := "000";
variable  bshift  : STD_LOGIC_VECTOR ( 2 downto 0) := "000";
variable  n       : integer := 0;
variable  m       : integer := 0;
variable  sstate  : integer := 0;
variable  cur_y   : integer := 0;
variable  spr_y   : integer := 0;
variable  max_y   : integer := 0;
variable  row     : integer := 0;
variable  cur_x   : integer := 0;
variable  spr0x   : integer := 0;
variable  spr1x   : integer := 0;
variable  spr2x   : integer := 0;
variable  spr3x   : integer := 0;
variable  spr4x   : integer := 0;
variable  spr5x   : integer := 0;
variable  spr6x   : integer := 0;
variable  spr7x   : integer := 0;
variable  sprindx : integer := 0;

variable  V       : STD_LOGIC := '0';               -- vert. nametable
variable  H       : STD_LOGIC := '0';               -- hori. nametable
variable  VT      : STD_LOGIC_VECTOR ( 4 downto 0); -- vert. tile index
variable  HT      : STD_LOGIC_VECTOR ( 4 downto 0); -- hori. tile index
variable  FV      : STD_LOGIC_VECTOR ( 2 downto 0); -- vert. pixel index
variable  FH      : STD_LOGIC_VECTOR ( 2 downto 0); -- hori. pixel index

begin

    if (CLK = '1' and CLK'event ) then
        if (SE = '0') then
            -- reset state machine counters
            phase   <= 0;
            counter <= 0;
            -- reset sprite cache
            n       := 0;
            m       := 0;
            sstate  := 0;
            cur_y   := conv_integer(unsigned(Y(9 downto 1)));
            sprcache(0)(7 downto 0) <= x"FF";
            sprcache(1)(7 downto 0) <= x"FF";
            sprcache(2)(7 downto 0) <= x"FF";
            sprcache(3)(7 downto 0) <= x"FF";
            sprcache(4)(7 downto 0) <= x"FF";
            sprcache(5)(7 downto 0) <= x"FF";
            sprcache(6)(7 downto 0) <= x"FF";
            sprcache(7)(7 downto 0) <= x"FF";
            spr0x   := 255;
            spr1x   := 255;
            spr2x   := 255;
            spr3x   := 255;
            spr4x   := 255;
            spr5x   := 255;
            spr6x   := 255;
            spr7x   := 255;
            -- reset color
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
                if (counter < 64) then
                    -- make use of this time by loading
                    -- current 8 sprites to sprite cache
--                 if (n < 64 and m < 8) then
--                     if (sstate = 0) then
--                         -- current sprite in range?
--                         spr_y := conv_integer(unsigned(sprites(n*4)))+1;
--                         if (PPU_CTRL(5) = '0') then
--                             max_y := spr_y + 8;
--                         else
--                             max_y := spr_y + 16;
--                         end if;
--                         if (cur_y >= spr_y and cur_y < max_y) then
--                             -- in range
--                             sstate := 1;
--                         else
--                             -- skip
--                             n := n + 1;
--                         end if;
--                     elsif (sstate = 1) then
--                         -- store sprite attributes
--                         sprcache(m)(15 downto 8) <= sprites(n*4+2);
--                         sstate := 2;
--                     elsif (sstate = 2) then
--                         -- store sprite X
--                         if (m = 0) then
--                             spr0x:=conv_integer(unsigned(sprites(n*4+3)));
--                         elsif (m = 1) then
--                             spr1x:=conv_integer(unsigned(sprites(n*4+3)));
--                         elsif (m = 2) then
--                             spr2x:=conv_integer(unsigned(sprites(n*4+3)));
--                         elsif (m = 3) then
--                             spr3x:=conv_integer(unsigned(sprites(n*4+3)));
--                         elsif (m = 4) then
--                             spr4x:=conv_integer(unsigned(sprites(n*4+3)));
--                         elsif (m = 5) then
--                             spr5x:=conv_integer(unsigned(sprites(n*4+3)));
--                         elsif (m = 6) then
--                             spr6x:=conv_integer(unsigned(sprites(n*4+3)));
--                         elsif (m = 7) then
--                             spr7x:=conv_integer(unsigned(sprites(n*4+3)));
--                         end if;
--                         sstate := 3;
--                     elsif (sstate = 3) then
--                         -- calculate row
--                         row := cur_y-spr_y;
--                         -- load color bit 0
-- --                             if (PPU_CTRL(5) = '0') then
-- --                                 PatAddr <= PPU_CTRL(3) &
-- --                                            sprites(n*4+1) &
-- --                                            "0" &
-- --                                            conv_std_logic_vector(row,3);
--                         if (row < 8) then
--                             PatAddr <= PPU_CTRL(3) &
--                                         sprites(n*4+1)(7 downto 1) & "0" &
--                                         "0" &
--                                         conv_std_logic_vector(row,3);
--                         else
--                             PatAddr <= PPU_CTRL(3) &
--                                         sprites(n*4+1)(7 downto 1) & "1" &
--                                         "0" &
--                                         conv_std_logic_vector(row-8,3);
--                         end if;
--                         PatRead <= '1';
--                         sstate := 4;
--                     elsif (sstate = 4) then
--                         -- read color bit 0
--                         if (sprites(n*4+2)(6) = '0') then
--                             sprcache(m)(16) <= PatData(7);
--                             sprcache(m)(17) <= PatData(6);
--                             sprcache(m)(18) <= PatData(5);
--                             sprcache(m)(19) <= PatData(4);
--                             sprcache(m)(20) <= PatData(3);
--                             sprcache(m)(21) <= PatData(2);
--                             sprcache(m)(22) <= PatData(1);
--                             sprcache(m)(23) <= PatData(0);
--                         else
--                             sprcache(m)(23 downto 16) <= PatData;
--                         end if;
--                         -- load color bit 1
--                         PatAddr(3) <= '1';
--                         sstate := 5;
--                     elsif (sstate = 5) then
--                         -- read color bit 1
--                         if (sprites(n*4+2)(6) = '0') then
--                             sprcache(m)(24) <= PatData(7);
--                             sprcache(m)(25) <= PatData(6);
--                             sprcache(m)(26) <= PatData(5);
--                             sprcache(m)(27) <= PatData(4);
--                             sprcache(m)(28) <= PatData(3);
--                             sprcache(m)(29) <= PatData(2);
--                             sprcache(m)(30) <= PatData(1);
--                             sprcache(m)(31) <= PatData(0);
--                         else
--                             sprcache(m)(31 downto 24) <= PatData;
--                         end if;
--                         PatRead <= '0';
--                         -- next sprite
--                         m := m + 1;
--                         n := n + 1;
--                         sstate := 0;
--                     end if;
--                 end if;
                    counter <= counter + 1;
                else
                    counter <= 0;
                    phase   <= 1;
                    -- beginning of a new row. Is this the first scanline?
                    if (Y = x"0000") then
                        -- first line on screen, reset vertical
                        V  := PPU_CTRL(1);
                        VT := PPU_VSCR(7 downto 3);
                        FV := PPU_VSCR(2 downto 0);
                    elsif (Y(0) = '0') then
                        if (FV /= "111") then
                            -- next pixel inside the tile
                            FV := conv_std_logic_vector(
                                    conv_integer(unsigned(FV))+1,3);
                        else
                            -- next tile
                            FV := "000";
                            if (VT /= "11101") then
                                -- next tile inside window
                                VT := conv_std_logic_vector(
                                        conv_integer(unsigned(VT))+1,5);
                            else
                                -- next window
                                VT := "00000";
                                V  := NOT V;
                            end if;
                        end if;
                    end if;
                    -- reset horizontal counters
                    H  := PPU_CTRL(0);
                    HT := PPU_HSCR(7 downto 3);
                    FH := PPU_HSCR(2 downto 0);
                    -- pipelining, read patIndex of first pixel
                    VRAM4Read <= '1';
                    PatRead   <= '1';
                    VRAM4Addr <= H & VT & HT;
                end if;
            elsif (phase = 1) then
                -- load lowest 2 bits of color
                PatAddr <= PPU_CTRL(4) & VRAM4Data(7 downto 0) & "0" & FV;
                -- load associated attribute
                VRAM4Addr <= H & "1111" & VT(4 downto 2) & HT(4 downto 2);
                -- early calculation for shifts
                bshift := FH;
                ashift := VT(1)&HT(1)&"0";
                -- prepare next column:
                if (FH /= "111") then
                    -- next pixel inside the tile
                    FH := conv_std_logic_vector(
                            conv_integer(unsigned(FH))+1,3);
                else
                    -- next tile
                    FH := "000";
                    if (HT /= "11111") then
                        -- next tile inside window
                        HT := conv_std_logic_vector(
                                conv_integer(unsigned(HT))+1,5);
                    else
                        -- next window
                        HT := "00000";
                        H  := NOT H;
                    end if;
                end if;


                -- (b) find matching sprite, if any
--             cur_x := counter;
--             sprindx := 8;
--             if (sprindx=8 and cur_x >= spr0x and cur_x < (spr0x+8)) then
--                 sprindx := 0;
--             end if;
--             if (sprindx=8 and cur_x >= spr1x and cur_x < (spr1x+8)) then
--                 sprindx := 1;
--             end if;
--             if (sprindx=8 and cur_x >= spr2x and cur_x < (spr2x+8)) then
--                 sprindx := 2;
--             end if;
--             if (sprindx=8 and cur_x >= spr3x and cur_x < (spr3x+8)) then
--                 sprindx := 3;
--             end if;
--             if (sprindx=8 and cur_x >= spr4x and cur_x < (spr4x+8)) then
--                 sprindx := 4;
--             end if;
--             if (sprindx=8 and cur_x >= spr5x and cur_x < (spr5x+8)) then
--                 sprindx := 5;
--             end if;
--             if (sprindx=8 and cur_x >= spr6x and cur_x < (spr6x+8)) then
--                 sprindx := 6;
--             end if;
--             if (sprindx=8 and cur_x >= spr7x and cur_x < (spr7x+8)) then
--                 sprindx := 7;
--             end if;
--             if (sprindx < 8) then
--                 scolor(0) := sprcache(sprindx)(16+(cur_x mod 8));
--                 scolor(1) := sprcache(sprindx)(24+(cur_x mod 8));
--                 scolor(2) := sprcache(sprindx)(8);
--                 scolor(3) := sprcache(sprindx)(9);
--             else
--                 scolor := "0000";
--             end if;

                -- go to next step
                phase <= 2;
            elsif (phase = 2) then
                -- read color
                tcolor(0) := PatData( 7-conv_integer(unsigned(bshift)));
                tcolor(1) := PatData(15-conv_integer(unsigned(bshift)));
                tcolor(2) := VRAM4Data(conv_integer(unsigned(ashift))+0);
                tcolor(3) := VRAM4Data(conv_integer(unsigned(ashift))+1);
                -- output color
                if (scolor(0) /= '0' or scolor(1) /= '0') then
                    -- sprite
                    color <= SprPal(conv_integer(unsigned(scolor)));
                elsif (tcolor(1) = '0' and tcolor(0) = '0') then
                    -- background color
                    color <= PatPal(0);
                else
                    color <= PatPal(conv_integer(unsigned(tcolor)));
                end if;
                -- load next pat index
                VRAM4Addr <= H & VT & HT;
                -- move to next state
                if (counter < 255) then
                    counter <= counter + 1;
                    phase   <= 1;
                else
                    phase   <= 5;
                end if;
            elsif (phase = 3) then
                phase <= 4;
            elsif (phase = 4) then
                phase <= 5;
            elsif (phase = 5) then
                phase <= 6;
            elsif (phase = 6) then
                phase <= 7;
            elsif (phase = 7) then
                phase <= 8;
            else
                VRAM4Read <= '0';
                PatRead   <= '0';
                color <= "111111";
            end if;
        end if;
    end if;

end process;

-- sprite access

process (CLK)
begin

    if (CLK = '0' and CLK'event ) then
        if (lastSprRD /= SprRD and SprRD='1') then
            -- read
            SprDataOut <= sprites(conv_integer(unsigned(SprAddr)));
        end if;
        if (lastSprWR /= SprWR and SprWR='1') then
            -- write
            sprites(conv_integer(unsigned(SprAddr))) <= SprDataIn;
        end if;
        lastSprRD <= SprRD;
        lastSprWR <= SprWR;
    end if;
end process;

-- palette access

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
