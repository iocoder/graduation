library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;
use work.cpu_pkg.all;

entity cachearray is
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
end entity;

architecture Behavioral of cachearray is

type cache_v_t    is array (0 to 1023) of std_logic;
type cache_data_t is array (0 to 1023) of std_logic_vector(31 downto 0);
type cache_tag_t  is array (0 to 1023) of std_logic_vector(19 downto 0);

signal cache_arr_v    : cache_v_t := (others => '0');
signal cache_arr_data : cache_data_t;
signal cache_arr_tag  : cache_tag_t;

attribute ram_style: string;
attribute ram_style of cache_arr_v    : signal is "block";
attribute ram_style of cache_arr_data : signal is "block";
attribute ram_style of cache_arr_tag  : signal is "block";

begin

process (CLK)
begin

    if ( CLK = '0' and CLK'event ) then
        if (RW = '1') then
            cache_arr_v(conv_integer(WR_ADDR))    <= Vin;
            cache_arr_data(conv_integer(WR_ADDR)) <= Din;
            cache_arr_tag(conv_integer(WR_ADDR))  <= TAGin;
        else
            Vout   <= cache_arr_v(conv_integer(RD_ADDR));
            Dout   <= cache_arr_data(conv_integer(RD_ADDR));
            TAGout <= cache_arr_tag(conv_integer(RD_ADDR));
        end if;

    end if;

end process;

end Behavioral;
