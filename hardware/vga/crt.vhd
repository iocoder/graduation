library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity crt is
    Port (CLK  : in  STD_LOGIC;
          MODE : in  STD_LOGIC;
          HS   : out STD_LOGIC := '0';
          VS   : out STD_LOGIC := '0';
          SE   : out STD_LOGIC := '0';
          DE   : out STD_LOGIC := '0';
          X    : out STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
          Y    : out STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
          B9   : out STD_LOGIC := '0');
end crt;

architecture Behavioral of crt is

signal hcounter : integer range 0 to 1024 := 0;
signal vcounter : integer range 0 to 1024 := 0;

signal vblank : STD_LOGIC := '1';

signal cur_x    : integer range 0 to 10240 := 0;
signal cur_y    : integer range 0 to 10240 := 0;
signal colindx  : integer range -1 to 16   := 0;

signal HORIZ_TOTAL      : integer;  -- horizontal cycle in pixels
signal HORIZ_PULSEWIDTH : integer;  -- pulse width in pixels
signal HORIZ_BACKPORCH  : integer;  -- back porch in pixels
signal HORIZ_ACTIVE     : integer;  -- active time in pixels
signal HORIZ_FRONTPORCH : integer;  -- front porch in pixels
signal VERTI_TOTAL      : integer;  -- vertical cycle in lines
signal VERTI_PULSEWIDTH : integer;  -- pulse width in lines
signal VERTI_BACKPORCH  : integer;  -- back porch in lines
signal VERTI_ACTIVE     : integer;  -- active time in lines
signal VERTI_FRONTPORCH : integer;  -- front porch in lines

signal enable_spacing   : boolean;

begin

process (CLK)
begin

    if (CLK = '1' and CLK'event) then
        -- next pixel:
        if (hcounter < HORIZ_PULSEWIDTH) then
            -- HS low pulse
            HS <= '0';
        elsif (hcounter < HORIZ_PULSEWIDTH+HORIZ_BACKPORCH) then
            -- Back porch
            HS <= '1';
            if (hcounter = HORIZ_PULSEWIDTH+HORIZ_BACKPORCH-1 and
                vblank = '0') then
                -- end of back porch cycle
                SE      <= '1';
                cur_x   <= cur_x + 1;
                colindx <= 0;
            end if;
        elsif (hcounter < HORIZ_PULSEWIDTH+HORIZ_BACKPORCH+HORIZ_ACTIVE) then
            -- Display time
            if (vblank = '0') then
                DE    <= '1';
                SE    <= '1';
                if (colindx = 7 and enable_spacing) then
                    B9      <= '1';
                    colindx <= -1;
                else
                    B9      <= '0';
                    X       <= conv_std_logic_vector(cur_x, 16);
                    cur_x   <= cur_x + 1;
                    colindx <= colindx + 1;
                end if;
            end if;
            if (hcounter=HORIZ_PULSEWIDTH+HORIZ_BACKPORCH+HORIZ_ACTIVE-1) then
                SE    <= '0';
                X     <= "0000000000000000";
                cur_x <= 0;
            end if;
        else
            -- Front porch
            -- Display disabled:
            DE    <= '0';
        end if;

        -- increase hcounter
        if (hcounter = HORIZ_TOTAL-1) then
            hcounter <= 0; -- the new value
        else
            hcounter <= hcounter + 1; -- the new value
        end if;

        -- New line?
        if (hcounter = 0) then
            -- next line:
            if (vcounter < VERTI_PULSEWIDTH) then
                -- VS low pulse
                VS <= '0';
            elsif (vcounter < VERTI_PULSEWIDTH+VERTI_BACKPORCH) then
                -- Back porch
                VS <= '1';
            elsif (vcounter<VERTI_PULSEWIDTH+VERTI_BACKPORCH+VERTI_ACTIVE) then
                -- Display time
                vblank <= '0';
                Y      <= conv_std_logic_vector(cur_y, 16);
                cur_y  <= cur_y + 1;
            else
                -- Front porch
                -- Display disabled:
                vblank <= '1';
                cur_y  <= 0;
                Y      <= "0000000000000000";
            end if;

            -- increase vcounter
            if (vcounter = VERTI_TOTAL-1) then
                vcounter <= 0;
            else
                vcounter <= vcounter + 1;
            end if;

        end if;

    end if;

end process;

process (MODE)
begin

    if (MODE = '0') then
        -- 720x400@70Hz
        HORIZ_TOTAL      <= 900;  -- horizontal cycle in pixels
        HORIZ_PULSEWIDTH <= 108;  -- pulse width in pixels
        HORIZ_BACKPORCH  <= 51;   -- back porch in pixels
        HORIZ_ACTIVE     <= 720;  -- active time in pixels
        HORIZ_FRONTPORCH <= 21;   -- front porch in pixels
        VERTI_TOTAL      <= 449;  -- vertical cycle in lines
        VERTI_PULSEWIDTH <= 2;    -- pulse width in lines
        VERTI_BACKPORCH  <= 32;   -- back porch in lines
        VERTI_ACTIVE     <= 400;  -- active time in lines
        VERTI_FRONTPORCH <= 15;   -- front porch in lines
        enable_spacing   <= true; -- char is 9-column wide.
    else
        -- 640x480@60Hz
        HORIZ_TOTAL      <= 800;  -- horizontal cycle in pixels
        HORIZ_PULSEWIDTH <= 96;   -- pulse width in pixels
        HORIZ_BACKPORCH  <= 48;   -- back porch in pixels
        HORIZ_ACTIVE     <= 640;  -- active time in pixels
        HORIZ_FRONTPORCH <= 16;   -- front porch in pixels
        VERTI_TOTAL      <= 521;  -- vertical cycle in lines
        VERTI_PULSEWIDTH <= 2;    -- pulse width in lines
        VERTI_BACKPORCH  <= 29;   -- back porch in lines
        VERTI_ACTIVE     <= 480;  -- active time in lines
        VERTI_FRONTPORCH <= 10;   -- front porch in lines
        enable_spacing   <= false; -- char is 8-column wide.
    end if;

end process;

end Behavioral;
