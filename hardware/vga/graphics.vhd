library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity graphics is
    Port ( CLK50       : in  STD_LOGIC;
           CLK12       : in  STD_LOGIC;
           CS          : in  STD_LOGIC;
           RW          : in  STD_LOGIC;
           A           : in  STD_LOGIC_VECTOR (13 downto 0);
           Din         : in  STD_LOGIC_VECTOR (15 downto 0);
           Dout        : out STD_LOGIC_VECTOR (15 downto 0) := x"0000";
           INT         : out STD_LOGIC := '0';
           IAK         : in  STD_LOGIC;
           VBLANK      : in  STD_LOGIC;
           VRAM0Read   : out STD_LOGIC;
           VRAM1Read   : out STD_LOGIC;
           VRAM2Read   : out STD_LOGIC;
           VRAM3Read   : out STD_LOGIC;
           VRAM4Read   : out STD_LOGIC;
           VRAM0Write  : out STD_LOGIC;
           VRAM1Write  : out STD_LOGIC;
           VRAM2Write  : out STD_LOGIC;
           VRAM3Write  : out STD_LOGIC;
           VRAM4Write  : out STD_LOGIC;
           VRAMAddr    : out STD_LOGIC_VECTOR (10 downto 0);
           VRAM0DataIn : in  STD_LOGIC_VECTOR ( 8 downto 0);
           VRAM1DataIn : in  STD_LOGIC_VECTOR ( 8 downto 0);
           VRAM2DataIn : in  STD_LOGIC_VECTOR ( 8 downto 0);
           VRAM3DataIn : in  STD_LOGIC_VECTOR ( 8 downto 0);
           VRAM4DataIn : in  STD_LOGIC_VECTOR ( 8 downto 0);
           VRAMDataOut : out STD_LOGIC_VECTOR ( 8 downto 0);
           SprRD       : out STD_LOGIC;
           SprWR       : out STD_LOGIC;
           SprAddr     : out STD_LOGIC_VECTOR ( 7 downto 0);
           SprDataIn   : in  STD_LOGIC_VECTOR ( 7 downto 0);
           SprDataOut  : out STD_LOGIC_VECTOR ( 7 downto 0);
           PalRD       : out STD_LOGIC;
           PalWR       : out STD_LOGIC;
           PalAddr     : out STD_LOGIC_VECTOR ( 4 downto 0);
           PalDataIn   : in  STD_LOGIC_VECTOR ( 7 downto 0);
           PalDataOut  : out STD_LOGIC_VECTOR ( 7 downto 0);
           ROW_BASE    : out STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
           CURSOR_ROW  : out STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
           CURSOR_COL  : out STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
           PPU_CTRL    : out STD_LOGIC_VECTOR (15 downto 0) := x"0000";
           PPU_HSCR    : out STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
           PPU_VSCR    : out STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
           MODE        : out STD_LOGIC);
end graphics;

architecture Behavioral of graphics is

signal LASTCS         : STD_LOGIC := '0';
signal LASTVBLANK     : STD_LOGIC := '0';
signal LASTVBLANK2    : STD_LOGIC := '0';

-- general registers
signal ROW_BASE_REG   : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal CURSOR_ROW_REG : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal CURSOR_COL_REG : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal MODE_REG       : STD_LOGIC := '0';

-- PPU registers
signal PPU_CTRL_REG   : STD_LOGIC_VECTOR (15 downto 0) := x"0000";
signal PPU_HSCR_REG   : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal PPU_VSCR_REG   : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal PPU_ADDR_REG   : STD_LOGIC_VECTOR (15 downto 0) := x"0000";
signal PPU_SMA_REG    : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal PPU_HIT_REG    : STD_LOGIC := '0';
signal PPU_VBLANK_REG : STD_LOGIC := '0';
signal PPU_FF         : STD_LOGIC := '0';

begin

process (CLK12)

    procedure ppu_mem_access(write : in STD_LOGIC;
                             data  : in STD_LOGIC_VECTOR(7 downto 0)) is
    begin
        case PPU_ADDR_REG(13 downto 12) is
            when "00" =>
                -- ram0 and ram1
                if (PPU_ADDR_REG(3) = '0') then
                    VRAM0Read   <= NOT write;
                    VRAM0Write  <= write;
                else
                    VRAM1Read   <= NOT write;
                    VRAM1Write  <= write;
                end if;
                VRAMAddr    <= PPU_ADDR_REG(11 downto 4) &
                               PPU_ADDR_REG( 2 downto 0);
                VRAMDataOut <= "0" & data;
            when "01" =>
                -- ram2 and ram3
                if (PPU_ADDR_REG(3) = '0') then
                    VRAM2Read   <= NOT write;
                    VRAM2Write  <= write;
                else
                    VRAM3Read   <= NOT write;
                    VRAM3Write  <= write;
                end if;
                VRAMAddr    <= PPU_ADDR_REG(11 downto 4) &
                               PPU_ADDR_REG( 2 downto 0);
                VRAMDataOut <= "0" & data;
            when "10" =>
                -- ram4 (namtabs)
                VRAM4Read   <= NOT write;
                VRAM4Write  <= write;
                VRAMAddr    <= PPU_ADDR_REG(10 downto 0);
                VRAMDataOut <= "0" & data;
            when "11" =>
                -- palette
                if (PPU_ADDR_REG(13 downto 8) = "111111") then
                    if (PPU_ADDR_REG(3 downto 0) = "0000") then
                        PalAddr <= "00000";
                    else
                        PalAddr <= PPU_ADDR_REG(4 downto 0);
                    end if;
                    if (write = '0') then
                        PalRD <= '1';
                    else
                        PalWR <= '1';
                        PalDataOut <= data;
                    end if;
                end if;
            when others =>
        end case;

        if (PPU_CTRL_REG(2) = '1') then
            -- vertical write
            PPU_ADDR_REG <=
                conv_std_logic_vector(conv_integer(PPU_ADDR_REG) + 32, 16);
        else
            PPU_ADDR_REG <=
                conv_std_logic_vector(conv_integer(PPU_ADDR_REG) + 1, 16);
        end if;
    end ppu_mem_access;

begin
    if (CLK12 = '0' and CLK12'event ) then
        if (CS = '1') then
            if (MODE_REG = '1' and RW='1' and LASTCS='0') then
                -- write
                case A(2 downto 0) is
                    when "000" =>
                        -- control 1
                        PPU_CTRL_REG( 7 downto 0) <= Din(7 downto 0);
                    when "001" =>
                        -- control 2
                        PPU_CTRL_REG(15 downto 8) <= Din(7 downto 0);
                    when "010" =>
                        -- status
                    when "011" =>
                        -- Sprite Memory Address
                        PPU_SMA_REG <= Din(7 downto 0);
                    when "100" =>
                        -- Sprite Memory Data
                        SprWR       <= '1';
                        SprAddr     <= PPU_SMA_REG;
                        SprDataOut  <= Din(7 downto 0);
                        PPU_SMA_REG <= conv_std_logic_vector(
                            conv_integer(
                                unsigned(PPU_SMA_REG))+1,8);
                    when "101" =>
                        -- scroll data
                        if (PPU_FF = '0') then
                            -- horizontal scroll
                            PPU_HSCR_REG <= Din(7 downto 0);
                        else
                            -- vertical scroll
                            PPU_VSCR_REG <= Din(7 downto 0);
                        end if;
                        PPU_FF <= NOT PPU_FF;
                    when "110" =>
                        -- address
                        if (PPU_FF = '0') then
                            PPU_ADDR_REG(13 downto 8) <= Din(5 downto 0);
                        else
                            PPU_ADDR_REG( 7 downto 0) <= Din(7 downto 0);
                        end if;
                        PPU_FF <= NOT PPU_FF;
                    when "111" =>
                        -- data
                        ppu_mem_access('1', Din(7 downto 0));
                    when others  =>
                end case;
            elsif (MODE_REG = '1' and RW='0' and LASTCS = '0') then
                -- read
                case A(2 downto 0) is
                    when "000" =>
                        -- control 1 - illegal read
                    when "001" =>
                        -- control 2 - illegal read
                    when "010" =>
                        -- status
                        Dout(6) <= PPU_HIT_REG;
                        Dout(7) <= PPU_VBLANK_REG;
                        PPU_VBLANK_REG <= '0';
                        PPU_FF <= '0';
                    when "011" =>
                        -- Sprite Memory Address - illegal read
                    when "100" =>
                        -- TODO: Sprite Memory Data
                    when "101" =>
                        -- scroll offset - illegal read
                    when "110" =>
                        -- address - illegal
                    when "111" =>
                        -- data
                        ppu_mem_access('0', x"00");
                    when others  =>
                end case;
            elsif (A = "0" & x"FFC" & "0") then
                MODE_REG <= Din(0);
            elsif (A = "0" & x"FFD" & "0") then
                ROW_BASE_REG <= Din(7 downto 0);
            elsif (A = "0" & x"FFE" & "0") then
                CURSOR_ROW_REG <= Din(7 downto 0);
            elsif (A = "0" & x"FFF" & "0") then
                CURSOR_COL_REG <= Din(7 downto 0);
            else
                -- access to any other address
                if (MODE_REG = '0' and LASTCS = '0') then
                    VRAM0Read  <= (NOT RW) and (NOT A(1)) and (NOT A(13));
                    VRAM1Read  <= (NOT RW) and (    A(1)) and (NOT A(13));
                    VRAM2Read  <= (NOT RW) and (NOT A(1)) and (    A(13));
                    VRAM3Read  <= (NOT RW) and (    A(1)) and (    A(13));
                    VRAM0Write <= (    RW) and (NOT A(1)) and (NOT A(13));
                    VRAM1Write <= (    RW) and (    A(1)) and (NOT A(13));
                    VRAM2Write <= (    RW) and (NOT A(1)) and (    A(13));
                    VRAM3Write <= (    RW) and (    A(1)) and (    A(13));
                    VRAMAddr(10 downto 0) <= A(12 downto 2);
                    VRAMDataOut <= Din(8 downto 0);
                end if;
                if (MODE_REG = '0' or (RW='0' and A(2 downto 0)="111")) then
                    Dout(8 downto 0) <= VRAM0DataIn or VRAM1DataIn or
                                        VRAM2DataIn or VRAM3DataIn or
                                        VRAM4DataIn;
                end if;
            end if;
        else
            VRAM0Read  <= '0';
            VRAM1Read  <= '0';
            VRAM2Read  <= '0';
            VRAM3Read  <= '0';
            VRAM4Read  <= '0';
            VRAM0Write <= '0';
            VRAM1Write <= '0';
            VRAM2Write <= '0';
            VRAM3Write <= '0';
            VRAM4Write <= '0';
            SprRD      <= '0';
            SprWR      <= '0';
            PalRD      <= '0';
            PalWR      <= '0';
            Dout       <= x"0000";
            SprAddr    <= x"00";
            SprDataOut <= x"00";
            PalAddr    <= "00000";
            PalDataOut <= x"00";
            if (VBLANK /= LASTVBLANK) then
                PPU_VBLANK_REG <= VBLANK;
            end if;
            LASTVBLANK <= VBLANK;
        end if;
        LASTCS <= CS;
    end if;
end process;

process (CLK50)
begin
    if (CLK50 = '0' and CLK50'event ) then
        LASTVBLANK2 <= VBLANK;
        if (IAK = '1') then
            INT <= '0';
        elsif (VBLANK /= LASTVBLANK2) then
            if (VBLANK = '1' and PPU_CTRL_REG(7) = '1') then
                -- generate interrupt
                INT <= '1';
            end if;
        end if;
    end if;
end process;

ROW_BASE   <= ROW_BASE_REG;
CURSOR_ROW <= CURSOR_ROW_REG;
CURSOR_COL <= CURSOR_COL_REG;
MODE       <= MODE_REG;
PPU_CTRL   <= PPU_CTRL_REG;
PPU_HSCR   <= PPU_HSCR_REG;
PPU_VSCR   <= PPU_VSCR_REG;

end Behavioral;
