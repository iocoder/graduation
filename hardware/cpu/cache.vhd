library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;
use work.cpu_pkg.all;

entity cache is
    Port (
        CLK      : in  STD_LOGIC;
        CACHE_EN : in  STD_LOGIC;
        STALL    : out STD_LOGIC;
        -- CPU interface
        iMEME    : in  STD_LOGIC;
        iRW      : in  STD_LOGIC;
        iADDR    : in  STD_LOGIC_VECTOR (31 downto 0);
        iDin     : in  STD_LOGIC_VECTOR (31 downto 0);
        iDout    : out STD_LOGIC_VECTOR (31 downto 0);
        iDTYPE   : in  STD_LOGIC_VECTOR ( 2 downto 0);
        dMEME    : in  STD_LOGIC;
        dRW      : in  STD_LOGIC;
        dADDR    : in  STD_LOGIC_VECTOR (31 downto 0);
        dDin     : in  STD_LOGIC_VECTOR (31 downto 0);
        dDout    : out STD_LOGIC_VECTOR (31 downto 0);
        dDTYPE   : in  STD_LOGIC_VECTOR ( 2 downto 0);
        -- system bus interface
        MEME     : out STD_LOGIC := '0';
        RW       : out STD_LOGIC := '0';
        ADDR     : out STD_LOGIC_VECTOR (31 downto 0);
        Din      : in  STD_LOGIC_VECTOR (31 downto 0);
        Dout     : out STD_LOGIC_VECTOR (31 downto 0);
        DTYPE    : out STD_LOGIC_VECTOR ( 2 downto 0);
        RDY      : in  STD_LOGIC
    );
end entity;

architecture Behavioral of cache is

component cachearray is
    Port (
        CLK      : in  STD_LOGIC;
        -- bus interface
        RW       : in  STD_LOGIC;
        RD_ADDR  : in  STD_LOGIC_VECTOR (9 downto 0);
        WR_ADDR  : in  STD_LOGIC_VECTOR (9 downto 0);
        -- inputs
        Vin      : in  STD_LOGIC;
        Din      : in  STD_LOGIC_VECTOR (31 downto 0);
        TAGin    : in  STD_LOGIC_VECTOR (19 downto 0);
        -- outputs
        Vout     : out STD_LOGIC;
        Dout     : out STD_LOGIC_VECTOR (31 downto 0);
        TAGout   : out STD_LOGIC_VECTOR (19 downto 0)
    );
end component;

-- stall signal
signal STALLout : STD_LOGIC := '0';

-- phase
signal phase    : integer range 0 to 15 := 0;

--------------------------------------------------------------------------------
--                               R/W BUFFER                                   --
--------------------------------------------------------------------------------

constant BUFFER_SIZE : integer := 10;

signal buf_head  : integer range 0 to 100 := 0;
signal buf_tail  : integer range 0 to 100 := 0;
signal buf_cycle : integer range 0 to 100 := 0;

type buf_entry_t is record
    USED  : BOOLEAN;
    RW    : STD_LOGIC;
    ADDR  : STD_LOGIC_VECTOR (31 downto 0);
    DATA  : STD_LOGIC_VECTOR (31 downto 0);
    DTYPE : STD_LOGIC_VECTOR ( 2 downto 0);
    DSRC  : STD_LOGIC; -- instruction cache or data cache
end record buf_entry_t;

type buf_t is array (0 to BUFFER_SIZE-1) of buf_entry_t;

signal buf0 : buf_entry_t := (USED => false, RW => '0',
                              ADDR => x"00000000", DATA => x"00000000",
                              DTYPE => "000", DSRC => '0');
signal buf1 : buf_entry_t := (USED => false, RW => '0',
                              ADDR => x"00000000", DATA => x"00000000",
                              DTYPE => "000", DSRC => '0');
signal cur_buf : buf_entry_t;

--------------------------------------------------------------------------------
--                            CACHE PARAMETERS                                --
--------------------------------------------------------------------------------

-- +-------+-------+--------+
-- |  TAG  | INDEX | OFFSET |
-- +-------+-------+--------+
--    20       10      2

constant CACHE_LINES : integer range 0 to 100000 := 1024;
constant OFFSET_BITS : integer range 0 to 100000 := 2;
constant INDEX_BITS  : integer range 0 to 100000 := 10;
constant INDEX_LOW   : integer range 0 to 100000 := 2;
constant INDEX_HIGH  : integer range 0 to 100000 := 11;
constant TAG_BITS    : integer range 0 to 100000 := 20;
constant TAG_LOW     : integer range 0 to 100000 := 12;
constant TAG_HIGH    : integer range 0 to 100000 := 31;

-- icache interface
signal icache_rw        : std_logic := '0';
signal icache_rd_v      : std_logic;
signal icache_rd_data   : std_logic_vector(31 downto 0);
signal icache_rd_tag    : std_logic_vector(TAG_BITS-1 downto 0);
signal icache_wr_index  : std_logic_vector(INDEX_BITS-1 downto 0);
signal icache_wr_v      : std_logic;
signal icache_wr_data   : std_logic_vector(31 downto 0);
signal icache_wr_tag    : std_logic_vector(TAG_BITS-1 downto 0);

-- dcache interface
signal dcache_rw        : std_logic := '0';
signal dcache_rd_v      : std_logic;
signal dcache_rd_data   : std_logic_vector(31 downto 0);
signal dcache_rd_tag    : std_logic_vector(TAG_BITS-1 downto 0);
signal dcache_wr_index  : std_logic_vector(INDEX_BITS-1 downto 0);
signal dcache_wr_v      : std_logic;
signal dcache_wr_data   : std_logic_vector(31 downto 0);
signal dcache_wr_tag    : std_logic_vector(TAG_BITS-1 downto 0);

-- detect cache hits
signal icache_hit : boolean;
signal dcache_hit : boolean;

begin

--------------------------------------------------------------------------------
--                            CACHE ARRAYS                                    --
--------------------------------------------------------------------------------

C1: cachearray port map (
    CLK, icache_rw, iADDR(INDEX_HIGH downto INDEX_LOW), icache_wr_index,
    icache_wr_v, icache_wr_data, icache_wr_tag,
    icache_rd_v, icache_rd_data, icache_rd_tag
);

C2: cachearray port map (
    CLK, dcache_rw, dADDR(INDEX_HIGH downto INDEX_LOW), dcache_wr_index,
    dcache_wr_v, dcache_wr_data, dcache_wr_tag,
    dcache_rd_v, dcache_rd_data, dcache_rd_tag
);


-- detect cache hits
icache_hit <= icache_rd_v = '1' and
              icache_rd_tag = iADDR(TAG_HIGH downto TAG_LOW);
dcache_hit <= dcache_rd_v = '1' and
              dcache_rd_tag = dADDR(TAG_HIGH downto TAG_LOW);

--------------------------------------------------------------------------------
--                        FINITE STATE MACHINE                                --
--------------------------------------------------------------------------------

-- Synchronization note:
--
-- pipeline cycle begins with rising edge of even cache cycles:
--   _   _   _   _   _   _
--  | |_| |_| |_| |_| |_| |_
--  +       +       +       +   pipeline cycles
--  ^   ^   ^   ^   ^   ^   ^   cache array cycles
--  001111000011110000111100    phase variable
--
-- if a cache miss occurs, phase will be updated from 1 to 2
-- instead of going back to 0, and STALLout will be set to 1.
--
process(CLK)

variable buf_empty  : boolean := true;

function extract(dtype : in STD_LOGIC_VECTOR (2  downto 0);
                 addr  : in STD_LOGIC_VECTOR (31 downto 0);
                 word  : in STD_LOGIC_VECTOR (31 downto 0))
                 return STD_LOGIC_VECTOR is
variable retval : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
begin
    if (dtype = "001") then
        if (addr(1 downto 0) = "00") then
            retval := x"000000" & word(7 downto 0);
        elsif (addr(1 downto 0) = "01") then
            retval := x"000000" & word(15 downto 8);
        elsif (addr(1 downto 0) = "10") then
            retval := x"000000" & word(23 downto 16);
        else
            retval := x"000000" & word(31 downto 24);
        end if;
    elsif (dtype = "010") then
        if (addr(1) = '0') then
            retval := x"0000" & word(15 downto 0);
        elsif (addr(1) = '1') then
            retval := x"0000" & word(31 downto 16);
        end if;
    else
        retval := word;
    end if;
    return retval;
end extract;

function merge(dtype : in STD_LOGIC_VECTOR (2  downto 0);
               addr  : in STD_LOGIC_VECTOR (31 downto 0);
               orig  : in STD_LOGIC_VECTOR (31 downto 0);
               word  : in STD_LOGIC_VECTOR (31 downto 0))
                 return STD_LOGIC_VECTOR is
variable retval : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
begin
    if (dtype = "001") then
        if (addr(1 downto 0) = "00") then
            retval:=orig(31 downto 8)&word(7 downto 0);
        elsif (addr(1 downto 0) = "01") then
            retval:=orig(31 downto 16)&word(7 downto 0)&orig(7 downto 0);
        elsif (addr(1 downto 0) = "10") then
            retval:=orig(31 downto 24)&word(7 downto 0)&orig(15 downto 0);
        else
            retval:=word(7 downto 0)&orig(23 downto 0);
        end if;
    elsif (dtype = "010") then
        if (addr(1) = '0') then
            retval := orig(31 downto 16) & word(15 downto 0);
        elsif (addr(1) = '1') then
            retval := word(15 downto 0) & orig(15 downto 0);
        end if;
    else
        retval := word;
    end if;
    return retval;
end merge;

function cacheable(addr : in STD_LOGIC_VECTOR (31 downto 0))
                   return STD_LOGIC is
begin
    if (addr(31 downto 24) = x"1E") then
        return '0';
    else
        return '1';
    end if;
end cacheable;

begin

    -- TODO: set cachearray clock to rising edge.

    if ( CLK='0' and CLK'event and CACHE_EN = '1' ) then
        -- execute fsm
        if (phase = 0) then
            -------------------
            -- initial delay --
            -------------------
            -- wait until address is resolved and cache array is queried
            phase <= 1;
        elsif (phase = 1) then
            -------------------------------
            -- cache hit/miss processing --
            -------------------------------
            -- detect cache misses:
            buf_empty := true;
            if (iMEME = '1') then
                if (iRW = '1' or not icache_hit) then
                    -- icache miss
                    buf0.USED  <= true;
                    buf_empty := false;
                else
                    iDout <= icache_rd_data;
                end if;
            end if;
            if (dMEME = '1') then
                if (dRW = '1' or not dcache_hit) then
                    -- dcache miss
                    buf1.USED  <= true;
                    buf_empty := false;
                else
                    dDout <= extract(dDTYPE, dADDR, dcache_rd_data);
                end if;
            end if;

            -- determine next phase
            if (buf_empty) then
                -- no cache misses.
                phase <= 0;
            else
                -- there is at least one cache miss
                phase <= 2;
                STALLout <= '1';
            end if;

        elsif (phase = 2) then

            -- icache miss or write through
            buf0.RW    <= iRW;
            buf0.ADDR  <= iADDR;
            buf0.DATA  <= iDin;
            buf0.DTYPE <= iDTYPE;
            buf0.DSRC  <= '0';

            -- dcache miss or write through
            buf1.RW    <= dRW;
            buf1.ADDR  <= dADDR;
            buf1.DATA  <= dDin;
            buf1.DTYPE <= dDTYPE;
            buf1.DSRC  <= '1';

            -- reset buffer head
            buf_head   <= 0;
            buf_cycle  <= 0;

            -- jump to next phase
            phase <= 3;

        elsif (phase = 3) then

            -- note: removing this state corrupts the design cuz
            -- CLK25 and CLK50 of pipeline become no longer synced.
            phase <= 4;

        elsif (phase = 4) then
            -----------------------
            -- buffer processing --
            -----------------------
            if (buf_cycle = 0) then
                -- setup memory interface
                if (buf_head = 0) then
                    if (buf0.used) then
                        MEME   <= '1';
                        RW     <= buf0.RW;
                        Dout   <= buf0.DATA;
                        if (buf0.RW = '0') then
                            DTYPE  <= "100";
                            ADDR   <= buf0.ADDR(31 downto 2) & "00";
                        else
                            ADDR   <= buf0.ADDR;
                            DTYPE  <= buf0.DTYPE;
                        end if;
                        buf0.used <= FALSE;
                        cur_buf   <= buf0;
                        buf_cycle <= buf_cycle + 1;
                    else
                        buf_cycle <= 27;
                    end if;
                else
                    if (buf1.used) then
                        MEME   <= '1';
                        RW     <= buf1.RW;
                        Dout   <= buf1.DATA;
                        if (buf1.RW='0' and cacheable(buf1.ADDR)='1') then
                            DTYPE  <= "100";
                            ADDR   <= buf1.ADDR(31 downto 2) & "00";
                        else
                            ADDR   <= buf1.ADDR;
                            DTYPE  <= buf1.DTYPE;
                        end if;
                        buf1.used <= FALSE;
                        cur_buf   <= buf1;
                        buf_cycle <= buf_cycle + 1;
                    else
                        buf_cycle <= 27;
                    end if;
                end if;
            elsif (buf_cycle < 25) then
                if (buf_cycle > 3 and RDY = '1') then
                    buf_cycle <= 25;
                else
                    buf_cycle <= buf_cycle + 1;
                end if;
            elsif (buf_cycle = 25) then
                -- read in data if read operation
                if (cur_buf.RW = '0') then
                    -- read operation
                    if (cur_buf.DSRC = '0') then
                        -- IMEM read
                        iDout <= Din;
                        icache_rw <= cacheable(cur_buf.ADDR);
                        icache_wr_index <=
                            cur_buf.ADDR(INDEX_HIGH downto INDEX_LOW);
                        icache_wr_v <= '1';
                        icache_wr_data <= Din;
                        icache_wr_tag <=
                            cur_buf.ADDR(TAG_HIGH downto TAG_LOW);
                    else
                        -- DMEM read
                        if (cacheable(cur_buf.ADDR) = '1') then
                            dDout <= extract(dDTYPE, dADDR, Din);
                        else
                            dDout <= Din;
                        end if;
                        dcache_rw <= cacheable(cur_buf.ADDR);
                        dcache_wr_index <=
                            cur_buf.ADDR(INDEX_HIGH downto INDEX_LOW);
                        dcache_wr_v <= '1';
                        dcache_wr_data <= Din;
                        dcache_wr_tag <=
                            cur_buf.ADDR(TAG_HIGH downto TAG_LOW);
                    end if;
                elsif (cur_buf.DTYPE = "100") then
                    -- write word operation
                    if (cur_buf.DSRC = '0') then
                        -- IMEM write word
                    else
                        -- DMEM write word
                        dcache_rw <= cacheable(cur_buf.ADDR);
                        dcache_wr_index <=
                            cur_buf.ADDR(INDEX_HIGH downto INDEX_LOW);
                        dcache_wr_v <= '1';
                        dcache_wr_data <= cur_buf.DATA;
                        dcache_wr_tag <=
                            cur_buf.ADDR(TAG_HIGH downto TAG_LOW);
                    end if;
                else
                    -- write byte/half operation
                    if (cur_buf.DSRC = '0') then
                    else
                        -- DMEM write byte/half
                        if (dcache_hit) then
                            -- found in cache, do merge
                            dcache_rw <= cacheable(cur_buf.ADDR);
                            dcache_wr_index <=
                                cur_buf.ADDR(INDEX_HIGH downto INDEX_LOW);
                            dcache_wr_v <= '1';
                            dcache_wr_data <= merge(cur_buf.DTYPE,
                                                    cur_buf.ADDR,
                                                    dcache_rd_data,
                                                    cur_buf.DATA);
                            dcache_wr_tag <=
                                cur_buf.ADDR(TAG_HIGH downto TAG_LOW);
                        end if;
                    end if;
                end if;
                buf_cycle <= buf_cycle + 1;
            elsif (buf_cycle = 26) then
                buf_cycle <= buf_cycle + 1;
            elsif (buf_cycle = 27) then
                icache_rw <= '0';
                dcache_rw <= '0';
                MEME   <= '0';
                RW     <= '0';
                ADDR   <= x"00000000";
                Dout   <= x"00000000";
                DTYPE  <= "000";
                if (buf_head = 1) then
                    phase    <= 0;
                    STALLout <= '0';
                else
                    buf_head <= buf_head + 1;
                end if;
                buf_cycle <= 0;
            end if;
        elsif (phase = 5) then
            phase <= 0;
        end if;

    end if;

end process;

-- stall
STALL <= STALLout;

end Behavioral;
