library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tlc_sim is
    Port (
        -- The crystal:
        CLK       : in    STD_LOGIC;
        -- LEDs:
        LED       : out   STD_LOGIC_VECTOR ( 7 downto 0);
        -- VGA Connector
        R0        : out   STD_LOGIC;
        R1        : out   STD_LOGIC;
        R2        : out   STD_LOGIC;
        G0        : out   STD_LOGIC;
        G1        : out   STD_LOGIC;
        G2        : out   STD_LOGIC;
        B0        : out   STD_LOGIC;
        B1        : out   STD_LOGIC;
        HS        : out   STD_LOGIC;
        VS        : out   STD_LOGIC;
         -- Memory Bus:
        ADDR0     : out   STD_LOGIC;
        ADDR1     : out   STD_LOGIC;
        ADDR2     : out   STD_LOGIC;
        ADDR3     : out   STD_LOGIC;
        ADDR4     : out   STD_LOGIC;
        ADDR5     : out   STD_LOGIC;
        ADDR6     : out   STD_LOGIC;
        ADDR7     : out   STD_LOGIC;
        ADDR8     : out   STD_LOGIC;
        ADDR9     : out   STD_LOGIC;
        ADDR10    : out   STD_LOGIC;
        ADDR11    : out   STD_LOGIC;
        ADDR12    : out   STD_LOGIC;
        ADDR13    : out   STD_LOGIC;
        ADDR14    : out   STD_LOGIC;
        ADDR15    : out   STD_LOGIC;
        ADDR16    : out   STD_LOGIC;
        ADDR17    : out   STD_LOGIC;
        ADDR18    : out   STD_LOGIC;
        ADDR19    : out   STD_LOGIC;
        ADDR20    : out   STD_LOGIC;
        ADDR21    : out   STD_LOGIC;
        ADDR22    : out   STD_LOGIC;
        ADDR23    : out   STD_LOGIC;
        DataIn0   : in    STD_LOGIC;
        DataIn1   : in    STD_LOGIC;
        DataIn2   : in    STD_LOGIC;
        DataIn3   : in    STD_LOGIC;
        DataIn4   : in    STD_LOGIC;
        DataIn5   : in    STD_LOGIC;
        DataIn6   : in    STD_LOGIC;
        DataIn7   : in    STD_LOGIC;
        DataIn8   : in    STD_LOGIC;
        DataIn9   : in    STD_LOGIC;
        DataIn10  : in    STD_LOGIC;
        DataIn11  : in    STD_LOGIC;
        DataIn12  : in    STD_LOGIC;
        DataIn13  : in    STD_LOGIC;
        DataIn14  : in    STD_LOGIC;
        DataIn15  : in    STD_LOGIC;
        DataOut0  : out   STD_LOGIC;
        DataOut1  : out   STD_LOGIC;
        DataOut2  : out   STD_LOGIC;
        DataOut3  : out   STD_LOGIC;
        DataOut4  : out   STD_LOGIC;
        DataOut5  : out   STD_LOGIC;
        DataOut6  : out   STD_LOGIC;
        DataOut7  : out   STD_LOGIC;
        DataOut8  : out   STD_LOGIC;
        DataOut9  : out   STD_LOGIC;
        DataOut10 : out   STD_LOGIC;
        DataOut11 : out   STD_LOGIC;
        DataOut12 : out   STD_LOGIC;
        DataOut13 : out   STD_LOGIC;
        DataOut14 : out   STD_LOGIC;
        DataOut15 : out   STD_LOGIC;
        OE        : out   STD_LOGIC := '1';
        WE        : out   STD_LOGIC := '1';
        MT_ADV    : out   STD_LOGIC := '0';
        MT_CLK    : out   STD_LOGIC := '0';
        MT_UB     : out   STD_LOGIC := '1';
        MT_LB     : out   STD_LOGIC := '1';
        MT_CE     : out   STD_LOGIC := '1';
        MT_CRE    : out   STD_LOGIC := '0';
        MT_WAIT   : in    STD_LOGIC;
        ST_STS    : in    STD_LOGIC;
        RP        : out   STD_LOGIC := '1';
        ST_CE     : out   STD_LOGIC := '1';
        -- PS/2 port:
        PS2CLK    : in    STD_LOGIC;
        PS2DATA   : in    STD_LOGIC
    );
end entity;

architecture Structural of tlc_sim is

component TLC is
    Port (
        -- The crystal:
        CLK     : in    STD_LOGIC;
        -- LEDs:
        LED     : out   STD_LOGIC_VECTOR ( 7 downto 0);
        -- VGA Connector
        R       : out   STD_LOGIC_VECTOR ( 2 downto 0);
        G       : out   STD_LOGIC_VECTOR ( 2 downto 0);
        B       : out   STD_LOGIC_VECTOR ( 1 downto 0);
        HS      : out   STD_LOGIC;
        VS      : out   STD_LOGIC;
        -- Memory Bus:
        ADDR    : out   STD_LOGIC_VECTOR (23 downto 0);
        DATA    : inout STD_LOGIC_VECTOR (15 downto 0);
        OE      : out   STD_LOGIC := '1';
        WE      : out   STD_LOGIC := '1';
        MT_ADV  : out   STD_LOGIC := '0';
        MT_CLK  : out   STD_LOGIC := '0';
        MT_UB   : out   STD_LOGIC := '1';
        MT_LB   : out   STD_LOGIC := '1';
        MT_CE   : out   STD_LOGIC := '1';
        MT_CRE  : out   STD_LOGIC := '0';
        MT_WAIT : in    STD_LOGIC;
        ST_STS  : in    STD_LOGIC;
        RP      : out   STD_LOGIC := '1';
        ST_CE   : out   STD_LOGIC := '1';
        -- PS/2 port:
        PS2CLK  : in    STD_LOGIC;
        PS2DATA : in    STD_LOGIC

    );
end component;

signal R       : STD_LOGIC_VECTOR ( 2 downto 0);
signal G       : STD_LOGIC_VECTOR ( 2 downto 0);
signal B       : STD_LOGIC_VECTOR ( 1 downto 0);

signal ADDR    : STD_LOGIC_VECTOR (23 downto 0);
signal DATA    : STD_LOGIC_VECTOR (15 downto 0);
signal DataIn  : STD_LOGIC_VECTOR (15 downto 0);
signal DataOut : STD_LOGIC_VECTOR (15 downto 0);

signal myCLK : STD_LOGIC;

begin

-- array work around
R0 <= R(0);
R1 <= R(1);
R2 <= R(2);
G0 <= G(0);
G1 <= G(1);
G2 <= G(2);
B0 <= B(0);
B1 <= B(1);

ADDR0  <= ADDR( 0);
ADDR1  <= ADDR( 1);
ADDR2  <= ADDR( 2);
ADDR3  <= ADDR( 3);
ADDR4  <= ADDR( 4);
ADDR5  <= ADDR( 5);
ADDR6  <= ADDR( 6);
ADDR7  <= ADDR( 7);
ADDR8  <= ADDR( 8);
ADDR9  <= ADDR( 9);
ADDR10 <= ADDR(10);
ADDR11 <= ADDR(11);
ADDR12 <= ADDR(12);
ADDR13 <= ADDR(13);
ADDR14 <= ADDR(14);
ADDR15 <= ADDR(15);
ADDR16 <= ADDR(16);
ADDR17 <= ADDR(17);
ADDR18 <= ADDR(18);
ADDR19 <= ADDR(19);
ADDR20 <= ADDR(20);
ADDR21 <= ADDR(21);
ADDR22 <= ADDR(22);
ADDR23 <= ADDR(23);

DataIn( 0) <= DataIn0;
DataIn( 1) <= DataIn1;
DataIn( 2) <= DataIn2;
DataIn( 3) <= DataIn3;
DataIn( 4) <= DataIn4;
DataIn( 5) <= DataIn5;
DataIn( 6) <= DataIn6;
DataIn( 7) <= DataIn7;
DataIn( 8) <= DataIn8;
DataIn( 9) <= DataIn9;
DataIn(10) <= DataIn10;
DataIn(11) <= DataIn11;
DataIn(12) <= DataIn12;
DataIn(13) <= DataIn13;
DataIn(14) <= DataIn14;
DataIn(15) <= DataIn15;

DataOut0  <= DataOut( 0);
DataOut1  <= DataOut( 1);
DataOut2  <= DataOut( 2);
DataOut3  <= DataOut( 3);
DataOut4  <= DataOut( 4);
DataOut5  <= DataOut( 5);
DataOut6  <= DataOut( 6);
DataOut7  <= DataOut( 7);
DataOut8  <= DataOut( 8);
DataOut9  <= DataOut( 9);
DataOut10 <= DataOut(10);
DataOut11 <= DataOut(11);
DataOut12 <= DataOut(12);
DataOut13 <= DataOut(13);
DataOut14 <= DataOut(14);
DataOut15 <= DataOut(15);

-- memory data bus
DATA <= DataIn;
DataOut <= DATA;

U: TLC port map (myCLK, LED, R, G, B, HS, VS,
                 ADDR, DATA, OE, WE,
                 MT_ADV, MT_CLK, MT_UB, MT_LB, MT_CE, MT_CRE, MT_WAIT,
                 ST_STS, RP, ST_CE,
                 PS2CLK, PS2DATA);

process
begin

    while true loop
        myCLK <= '1';
        wait for 10 ns;
        myCLK <= '0';
        wait for 10 ns;
    end loop;

end process;

end architecture;
