library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;
use work.cpu_pkg.all;

entity cache is
    Port (
        CLK50MHz : in  STD_LOGIC;
        CLK2MHz  : in  STD_LOGIC;
        nRDY     : out STD_LOGIC := '0';
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
        MPULSE   : out STD_LOGIC := '0';
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

signal phase         : integer := 0;

--------------------------------------------------------------------------------
--                           MEMORY I/O BUFFER                                --
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
--                           INSTRUCTION CACHE                                --
--------------------------------------------------------------------------------

-- +-------+-------+--------+
-- |  TAG  | INDEX | OFFSET |
-- +-------+-------+--------+
--    22       8       2

constant ICACHE_LINES : integer range 0 to 100000 := 256;
constant IOFFSET_BITS : integer range 0 to 100000 := 2;
constant IINDEX_BITS  : integer range 0 to 100000 := 8;
constant IINDEX_LOW   : integer range 0 to 100000 := 2;
constant IINDEX_HIGH  : integer range 0 to 100000 := 9;
constant ITAG_BITS    : integer range 0 to 100000 := 22;
constant ITAG_LOW     : integer range 0 to 100000 := 10;
constant ITAG_HIGH    : integer range 0 to 100000 := 31;

type icache_v_t    is array (0 to ICACHE_LINES-1) of
                            boolean;
type icache_data_t is array (0 to ICACHE_LINES-1) of
                            std_logic_vector(31 downto 0);
type icache_tag_t  is array (0 to ICACHE_LINES-1) of
                            std_logic_vector(ITAG_BITS-1 downto 0);

signal icache_arr_v    : icache_v_t := (others => false);
signal icache_arr_data : icache_data_t;
signal icache_arr_tag  : icache_tag_t;

signal icache_wr_enable : boolean := false;
signal icache_wr_index  : integer range 0 to 100000;
signal icache_wr_v      : boolean;
signal icache_wr_data   : std_logic_vector(31 downto 0);
signal icache_wr_tag    : std_logic_vector(ITAG_BITS-1 downto 0);

--------------------------------------------------------------------------------
--                              DATA CACHE                                    --
--------------------------------------------------------------------------------

-- +-------+-------+--------+
-- |  TAG  | INDEX | OFFSET |
-- +-------+-------+--------+
--    22       8       2

constant DCACHE_LINES : integer range 0 to 100000 := 256;
constant DOFFSET_BITS : integer range 0 to 100000 := 2;
constant DINDEX_BITS  : integer range 0 to 100000 := 8;
constant DINDEX_LOW   : integer range 0 to 100000 := 2;
constant DINDEX_HIGH  : integer range 0 to 100000 := 9;
constant DTAG_BITS    : integer range 0 to 100000 := 22;
constant DTAG_LOW     : integer range 0 to 100000 := 10;
constant DTAG_HIGH    : integer range 0 to 100000 := 31;

type dcache_v_t    is array (0 to DCACHE_LINES-1) of
                            boolean;
type dcache_data_t is array (0 to DCACHE_LINES-1) of
                            std_logic_vector(31 downto 0);
type dcache_tag_t  is array (0 to DCACHE_LINES-1) of
                            std_logic_vector(DTAG_BITS-1 downto 0);

signal dcache_arr_v    : dcache_v_t := (others => false);
signal dcache_arr_data : dcache_data_t;
signal dcache_arr_tag  : dcache_tag_t;

signal dcache_wr_enable : boolean := false;
signal dcache_wr_index  : integer range 0 to 100000;
signal dcache_wr_v      : boolean;
signal dcache_wr_data   : std_logic_vector(31 downto 0);
signal dcache_wr_tag    : std_logic_vector(DTAG_BITS-1 downto 0);

attribute ram_style: string;
attribute ram_style of icache_arr_v    : signal is "distributed";
attribute ram_style of icache_arr_data : signal is "distributed";
attribute ram_style of icache_arr_tag  : signal is "distributed";
attribute ram_style of dcache_arr_v    : signal is "distributed";
attribute ram_style of dcache_arr_data : signal is "distributed";
attribute ram_style of dcache_arr_tag  : signal is "distributed";

--------------------------------------------------------------------------------
--                         FINITE STATE MACHINE                              --
--------------------------------------------------------------------------------

signal icache_idx   : std_logic_vector(IINDEX_BITS-1 downto 0);
signal icache_index : integer range 0 to 255 := 0;
signal icache_tag   : std_logic_vector(ITAG_BITS-1 downto 0);
signal icache_hit   : boolean := FALSE;
signal icache_data  : std_logic_vector(31 downto 0);

signal dcache_idx   : std_logic_vector(DINDEX_BITS-1 downto 0);
signal dcache_index : integer range 0 to 255 := 0;
signal dcache_tag   : std_logic_vector(DTAG_BITS-1 downto 0);
signal dcache_hit   : boolean := FALSE;
signal dcache_data  : std_logic_vector(31 downto 0);

begin

-- icache hit signals
icache_idx   <= iADDR(IINDEX_HIGH downto IINDEX_LOW);
icache_index <= conv_integer(icache_idx);
icache_tag   <= iADDR(ITAG_HIGH downto ITAG_LOW);
icache_hit   <= icache_arr_v(icache_index) and
                icache_arr_tag(icache_index) = icache_tag;
icache_data  <= icache_arr_data(icache_index);

-- dcache hit signals
dcache_idx   <= dADDR(DINDEX_HIGH downto DINDEX_LOW);
dcache_index <= conv_integer(dcache_idx);
dcache_tag   <= dADDR(DTAG_HIGH downto DTAG_LOW);
dcache_hit   <= dcache_arr_v(dcache_index) and
                dcache_arr_tag(dcache_index) = dcache_tag;
dcache_data  <= dcache_arr_data(dcache_index);

process (CLK50MHz)
begin

    if ( CLK50MHz = '1' and CLK50MHz'event ) then
        if (dcache_wr_enable) then
            dcache_arr_v(dcache_wr_index) <= dcache_wr_v;
            dcache_arr_data(dcache_wr_index) <= dcache_wr_data;
            dcache_arr_tag(dcache_wr_index) <= dcache_wr_tag;
        end if;


        if (icache_wr_enable) then
            icache_arr_v(icache_wr_index) <= icache_wr_v;
            icache_arr_data(icache_wr_index) <= icache_wr_data;
            icache_arr_tag(icache_wr_index) <= icache_wr_tag;
        end if;
    end if;

end process;


process (CLK50MHz)

begin

    if ( CLK50MHz = '0' and CLK50MHz'event ) then

        -- state machine
        if (phase = 0) then

            if (iMEME = '1') then
                if (iRW = '0' and icache_hit) then
                    -- icache hit and read
                    iDout <= icache_data;
                else
                    -- icache miss or write through
                    buf0.USED  <= true;
                    buf0.RW    <= iRW;
                    buf0.ADDR  <= iADDR;
                    buf0.DATA  <= iDin;
                    buf0.DTYPE <= iDTYPE;
                    buf0.DSRC  <= '0';
                    nRDY       <= '1';
                    buf_head   <= 0;
                    buf_cycle  <= 0;
                    phase      <= 1;

                end if;
            end if;

            if (dMEME = '1') then
                if (dRW = '0' and dcache_hit) then
                    -- dcache hit and read
                    if (dDTYPE = "001") then
                        if (dADDR(1 downto 0) = "00") then
                            dDout <= x"000000" & dcache_data(7 downto 0);
                        elsif (dADDR(1 downto 0) = "01") then
                            dDout <= x"000000" & dcache_data(15 downto 8);
                        elsif (dADDR(1 downto 0) = "10") then
                            dDout <= x"000000" & dcache_data(23 downto 16);
                        else
                            dDout <= x"000000" & dcache_data(31 downto 24);
                        end if;
                    elsif (dDTYPE = "010") then
                        if (dADDR(0) = '0') then
                            dDout <= x"0000" & dcache_data(15 downto 0);
                        elsif (dADDR(0) = '1') then
                            dDout <= x"0000" & dcache_data(31 downto 16);
                        end if;
                    else
                        dDout <= dcache_data;
                    end if;
                else
                    -- dcache miss or write through
                    buf1.USED  <= true;
                    buf1.RW    <= dRW;
                    buf1.ADDR  <= dADDR;
                    buf1.DATA  <= dDin;
                    buf1.DTYPE <= dDTYPE;
                    buf1.DSRC  <= '1';
                    nRDY       <= '1';
                    buf_head   <= 0;
                    buf_cycle  <= 0;
                    phase      <= 1;

                end if;
            end if;

        else
            -- process buffers
            if (buf_cycle = 0) then
                -- setup memory interface
                if (buf_head = 0) then
                    if (buf0.used) then
                        MPULSE <= '1';
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
                        MPULSE <= '1';
                        MEME   <= '1';
                        RW     <= buf1.RW;
                        Dout   <= buf1.DATA;
                        if (buf1.RW = '0') then
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
                MPULSE <= '0';
                --if (RDY = '1') then
                --    buf_cycle <= 25;
                --else
                    buf_cycle <= buf_cycle + 1;
                --end if;
            elsif (buf_cycle = 25) then
                -- read in data if read operation
                if (cur_buf.RW = '0') then
                    -- read operation
                    if (cur_buf.DSRC = '0') then
                        -- IMEM read
                        iDout <= Din;
                        icache_wr_enable <= true;
                        icache_wr_index <= conv_integer(
                            cur_buf.ADDR(IINDEX_HIGH downto IINDEX_LOW));
                        icache_wr_v <= true;
                        icache_wr_data <= Din;
                        icache_wr_tag <=
                            cur_buf.ADDR(ITAG_HIGH downto ITAG_LOW);
                    else
                        -- DMEM read
                        if (dDTYPE = "001") then
                            if (dADDR(1 downto 0) = "00") then
                                dDout <= x"000000" & Din(7 downto 0);
                            elsif (dADDR(1 downto 0) = "01") then
                                dDout <= x"000000" & Din(15 downto 8);
                            elsif (dADDR(1 downto 0) = "10") then
                                dDout <= x"000000" & Din(23 downto 16);
                            else
                                dDout <= x"000000" & Din(31 downto 24);
                            end if;
                        elsif (dDTYPE = "010") then
                            if (dADDR(0) = '0') then
                                dDout <= x"0000" & Din(15 downto 0);
                            elsif (dADDR(0) = '1') then
                                dDout <= x"0000" & Din(31 downto 16);
                            end if;
                        else
                            dDout <= Din;
                        end if;
                        dcache_wr_enable <= true;
                        dcache_wr_index <= conv_integer(
                            cur_buf.ADDR(DINDEX_HIGH downto DINDEX_LOW));
                        dcache_wr_v <= true;
                        dcache_wr_data <= Din;
                        dcache_wr_tag <=
                            cur_buf.ADDR(DTAG_HIGH downto DTAG_LOW);
                    end if;
                elsif (cur_buf.DTYPE = "100") then
                    -- write word operation
                    if (cur_buf.DSRC = '0') then
                        -- IMEM write word
--                     icache_index := conv_integer(
--                         cur_buf.ADDR(IINDEX_HIGH downto IINDEX_LOW));
--                     icache_tag   :=
--                         cur_buf.ADDR(ITAG_HIGH   downto ITAG_LOW);
--                     icache_arr_v(icache_index)    <= true;
--                     icache_arr_data(icache_index) <= cur_buf.DATA;
--                     icache_arr_tag(icache_index)  <= icache_tag;
                    else
                        -- DMEM write word
                        dcache_wr_enable <= true;
                        dcache_wr_index <= conv_integer(
                            cur_buf.ADDR(DINDEX_HIGH downto DINDEX_LOW));
                        dcache_wr_v <= true;
                        dcache_wr_data <= cur_buf.DATA;
                        dcache_wr_tag <=
                            cur_buf.ADDR(DTAG_HIGH downto DTAG_LOW);
                    end if;
                else
                    -- write byte/half operation
                    if (cur_buf.DSRC = '0') then
                        -- IMEM write byte/half
--                     icache_index := conv_integer(
--                         cur_buf.ADDR(IINDEX_HIGH downto IINDEX_LOW));
--                     icache_arr_v(icache_index)    <= false;
                    else
                        -- DMEM write byte/half
                        dcache_wr_enable <= true;
                        dcache_wr_index <= conv_integer(
                            cur_buf.ADDR(DINDEX_HIGH downto DINDEX_LOW));
                        dcache_wr_v <= false;
                    end if;
                end if;
                buf_cycle <= buf_cycle + 1;
            elsif (buf_cycle = 26) then
                buf_cycle <= buf_cycle + 1;
            elsif (buf_cycle = 27) then
                icache_wr_enable <= false;
                dcache_wr_enable <= false;
                MEME   <= '0';
                RW     <= '0';
                ADDR   <= x"00000000";
                Dout   <= x"00000000";
                DTYPE  <= "000";
                if (buf_head = 1) then
                    nRDY     <= '0';
                    phase    <= 0;
                else
                    buf_head <= buf_head + 1;
                end if;
                buf_cycle <= 0;
            end if;
        end if;

    end if;

end process;

end Behavioral;
