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

signal  PatAddr1 : STD_LOGIC_VECTOR (12 downto 0) := "0" & x"000";
signal  PatAddr2 : STD_LOGIC_VECTOR (12 downto 0) := "0" & x"000";
signal  PatAddr  : STD_LOGIC_VECTOR (12 downto 0) := "0" & x"000";
signal  PatRead  : STD_LOGIC := '0';
signal  PatData  : STD_LOGIC_VECTOR (15 downto 0) := x"0000";

-- sprites
type sprites_t is array (0 to 255) of STD_LOGIC_VECTOR (7 downto 0);
signal  sprites : sprites_t := (others => x"00");
signal sprindex : integer := 0;
signal sprdata  : STD_LOGIC_VECTOR (7 downto 0) := x"00";

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

PatAddr <= PatAddr1 when phase = 2 else PatAddr2;

VRAM0Addr <= PatAddr(11 downto 4) & PatAddr(2 downto 0);
VRAM1Addr <= PatAddr(11 downto 4) & PatAddr(2 downto 0);
VRAM2Addr <= PatAddr(11 downto 4) & PatAddr(2 downto 0);
VRAM3Addr <= PatAddr(11 downto 4) & PatAddr(2 downto 0);

VRAM0Read <= (NOT PatAddr(12));
VRAM1Read <= (NOT PatAddr(12));
VRAM2Read <= (    PatAddr(12));
VRAM3Read <= (    PatAddr(12));

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
variable  offset  : integer := 0;
variable  sprindx : integer := 0;

variable  V       : STD_LOGIC := '0';               -- vert. nametable
variable  H       : STD_LOGIC := '0';               -- hori. nametable
variable  VT      : STD_LOGIC_VECTOR ( 4 downto 0); -- vert. tile index
variable  HT      : STD_LOGIC_VECTOR ( 4 downto 0); -- hori. tile index
variable  FV      : STD_LOGIC_VECTOR ( 2 downto 0); -- vert. pixel index
variable  FH      : STD_LOGIC_VECTOR ( 2 downto 0); -- hori. pixel index

begin

    if (CLK = '1' and CLK'event ) then
        -- sprite processing
        if (SE = '0' or phase = 0 or phase = 4) then
            -- make use of hblank time by loading
            if (n < 64 and m < 8) then
                if (sstate = 0) then
                    -- current sprite in range?
                    spr_y := conv_integer(unsigned(sprdata))+1;
                    if (PPU_CTRL(5) = '0') then
                        max_y := spr_y + 8;
                    else
                        max_y := spr_y + 16;
                    end if;
                    if (cur_y >= spr_y and cur_y < max_y) then
                        -- in range
                        row := cur_y-spr_y;
                        sstate := 1;
                        sprindex <= sprindex + 2;
                    else
                        -- skip
                        n := n + 1;
                        sprindex <= sprindex + 4;
                    end if;
                elsif (sstate = 1) then
                    -- store sprite attributes
                    sprcache(m)(15 downto 8) <= sprdata;
                    if (sprdata(7) = '1') then
                        if (PPU_CTRL(5) = '0') then
                            row := 7 - row;
                        else
                            row := 15 - row;
                        end if;
                    end if;
                    sprindex <= sprindex + 1;
                    sstate := 2;
                elsif (sstate = 2) then
                    -- store sprite X
                    if (m = 0) then
                        spr0x:=conv_integer(unsigned(sprdata));
                    elsif (m = 1) then
                        spr1x:=conv_integer(unsigned(sprdata));
                    elsif (m = 2) then
                        spr2x:=conv_integer(unsigned(sprdata));
                    elsif (m = 3) then
                        spr3x:=conv_integer(unsigned(sprdata));
                    elsif (m = 4) then
                        spr4x:=conv_integer(unsigned(sprdata));
                    elsif (m = 5) then
                        spr5x:=conv_integer(unsigned(sprdata));
                    elsif (m = 6) then
                        spr6x:=conv_integer(unsigned(sprdata));
                    elsif (m = 7) then
                        spr7x:=conv_integer(unsigned(sprdata));
                    end if;
                    sprcache(m)(7 downto 0) <= sprdata;
                    sprindex <= sprindex - 2;
                    sstate := 3;
                elsif (sstate = 3) then
                    --load color bit 0
                    if (PPU_CTRL(5) = '0') then
                        PatAddr2 <= PPU_CTRL(3) &
                                    sprdata &
                                    "0" &
                                    conv_std_logic_vector(row,3);
                    elsif (row < 8) then
                        PatAddr2 <= sprdata(0) &
                                    sprdata(7 downto 1) & "0" &
                                    "0" &
                                    conv_std_logic_vector(row,3);
                    else
                        PatAddr2 <= sprdata(0) &
                                    sprdata(7 downto 1) & "1" &
                                    "0" &
                                    conv_std_logic_vector(row-8,3);
                    end if;
                    PatRead <= '1';
                    sprindex <= sprindex + 1;
                    sstate := 4;
                elsif (sstate = 4) then
                    sstate := 5;
                elsif (sstate = 5) then
                    -- read color bit 0
                    if (sprdata(6) = '0') then
                        sprcache(m)(16) <= PatData(7);
                        sprcache(m)(17) <= PatData(6);
                        sprcache(m)(18) <= PatData(5);
                        sprcache(m)(19) <= PatData(4);
                        sprcache(m)(20) <= PatData(3);
                        sprcache(m)(21) <= PatData(2);
                        sprcache(m)(22) <= PatData(1);
                        sprcache(m)(23) <= PatData(0);
                        sprcache(m)(24) <= PatData(15);
                        sprcache(m)(25) <= PatData(14);
                        sprcache(m)(26) <= PatData(13);
                        sprcache(m)(27) <= PatData(12);
                        sprcache(m)(28) <= PatData(11);
                        sprcache(m)(29) <= PatData(10);
                        sprcache(m)(30) <= PatData(9);
                        sprcache(m)(31) <= PatData(8);
                    else
                        sprcache(m)(31 downto 16) <= PatData;
                    end if;
                    -- next sprite
                    m := m + 1;
                    n := n + 1;
                    sprindex <= sprindex + 2;
                    sstate := 0;
                end if;
            end if;
        end if;
        -- rendering
        if (SE = '0') then
            -- reset state machine counters
            phase   <= 0;
            counter <= 0;
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
                PatAddr1 <= PPU_CTRL(4) & VRAM4Data(7 downto 0) & "0" & FV;
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
                -- find matching sprite, if any
                if (counter >= spr0x and counter < (spr0x+8)) then
                    sprindx := 0;
                elsif (counter >= spr1x and counter < (spr1x+8)) then
                    sprindx := 1;
                elsif (counter >= spr2x and counter < (spr2x+8)) then
                    sprindx := 2;
                elsif (counter >= spr3x and counter < (spr3x+8)) then
                    sprindx := 3;
                elsif (counter >= spr4x and counter < (spr4x+8)) then
                    sprindx := 4;
                elsif (counter >= spr5x and counter < (spr5x+8)) then
                    sprindx := 5;
                elsif (counter >= spr6x and counter < (spr6x+8)) then
                    sprindx := 6;
                elsif (counter >= spr7x and counter < (spr7x+8)) then
                    sprindx := 7;
                else
                    sprindx := 8;
                end if;
                -- go to next step
                phase <= 2;
            elsif (phase = 2) then
                -- read tile color
                tcolor(0) := PatData( 7-conv_integer(unsigned(bshift)));
                tcolor(1) := PatData(15-conv_integer(unsigned(bshift)));
                tcolor(2) := VRAM4Data(conv_integer(unsigned(ashift))+0);
                tcolor(3) := VRAM4Data(conv_integer(unsigned(ashift))+1);
                -- continue sprite evaluation
                if (sprindx < 8) then
                    offset  := counter -
                        conv_integer(unsigned(sprcache(sprindx)(7 downto 0)));
                    scolor(0) := sprcache(sprindx)(16+offset);
                    scolor(1) := sprcache(sprindx)(24+offset);
                    scolor(2) := sprcache(sprindx)(8);
                    scolor(3) := sprcache(sprindx)(9);
                else
                    scolor := "0000";
                end if;
                -- output color
                if (scolor(0) = '1' or scolor(1) = '1') then
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
                    phase   <= 3;
                end if;
            elsif (phase = 3) then
                phase <= 4;
                -- reset sprite cache
                n       := 0;
                m       := 0;
                sstate  := 0;
                cur_y   := conv_integer(unsigned(Y(9 downto 1)));
                spr0x   := 255;
                spr1x   := 255;
                spr2x   := 255;
                spr3x   := 255;
                spr4x   := 255;
                spr5x   := 255;
                spr6x   := 255;
                spr7x   := 255;
                sprindex <= 0;
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
        sprdata    <= sprites(sprindex);
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
