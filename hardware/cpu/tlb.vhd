library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;
use work.cpu_pkg.all;

entity tlb is
    Port (
        CLK              : in  STD_LOGIC;
        -- CPU interface
        cpu_iMEME        : in  STD_LOGIC;
        cpu_iRW          : in  STD_LOGIC;
        cpu_iADDR        : in  STD_LOGIC_VECTOR (19 downto 0);
        cpu_dMEME        : in  STD_LOGIC;
        cpu_dRW          : in  STD_LOGIC;
        cpu_dADDR        : in  STD_LOGIC_VECTOR (19 downto 0);
        -- Cache interface:
        cache_iMEME      : out STD_LOGIC;
        cache_iADDR      : out STD_LOGIC_VECTOR (19 downto 0);
        cache_iCacheable : out STD_LOGIC;
        cache_dMEME      : out STD_LOGIC;
        cache_dADDR      : out STD_LOGIC_VECTOR (19 downto 0);
        cache_dCacheable : out STD_LOGIC
    );
end entity;

architecture Behavioral of tlb is

constant TLB_SIZE : integer := 64;

type frame_t is array (0 to TLB_SIZE-1) of std_logic_vector(19 downto 0);
type page_t  is array (0 to TLB_SIZE-1) of std_logic_vector(19 downto 0);
type v_t     is array (0 to TLB_SIZE-1) of std_logic;

signal tlb_frame : frame_t;
signal tlb_page  : page_t;
signal tlb_v     : v_t := (others => '0');

begin

process(CLK)

variable paddr        : STD_LOGIC_VECTOR (19 downto 0);
variable miss         : STD_LOGIC;
variable valid        : STD_LOGIC;
variable dirty        : STD_LOGIC;
variable cacheable    : STD_LOGIC;
variable pass_instr   : boolean := false;

procedure translate(vaddr     : in  STD_LOGIC_VECTOR (19 downto 0);
                    paddr     : out STD_LOGIC_VECTOR (19 downto 0);
                    miss      : out STD_LOGIC;
                    valid     : out STD_LOGIC;
                    dirty     : out STD_LOGIC;
                    cacheable : out STD_LOGIC) is
variable found : boolean := false;
begin
    if (vaddr(19 downto 17) = "100") then
        -- kseg0 [0x80000000-0x9FFFFFFF]
        paddr     := "000" & vaddr(16 downto 0);
        miss      := '0';
        valid     := '1';
        dirty     := '1';
        cacheable := '1';
    elsif (vaddr(19 downto 17) = "101") then
        -- kseg1 [0xA0000000-0xBFFFFFFF]
        paddr     := "000" & vaddr(16 downto 0);
        miss      := '0';
        valid     := '1';
        dirty     := '1';
        cacheable := '0';
    else
        -- kuseg [0x00000000-0x7FFFFFFF]
        -- kseg2 [0xC0000000-0xFFFFFFFF]
        for i in 0 to TLB_SIZE-1 loop
            if (tlb_page(i)=cpu_iADDR) then
                found     := true;
                paddr     := tlb_frame(i);
                miss      := '0';
                valid     := tlb_v(i);
                dirty     := '1';
                cacheable := '1';
            end if;
        end loop;

        if (found = false) then
            paddr     := x"00000";
            miss      := '1';
            valid     := '0';
            dirty     := '0';
            cacheable := '0';
        end if;
    end if;
end translate;

begin

    if ( CLK = '0' and CLK'event ) then
        -----------------------
        -- data memory cycle --
        -----------------------
        if (cpu_dMEME = '1') then
            -- translate address
            translate(cpu_dADDR, paddr, miss, valid, dirty, cacheable);
            if (miss='1' or valid='0') then
                -- data tlb miss
            else
                -- tlb hit
                cache_dMEME <= '1';
                cache_dADDR <= paddr;
            end if;
        else
            cache_dMEME <= '0';
            cache_dADDR <= x"00000";
        end if;
        ------------------------------
        -- instruction memory cycle --
        ------------------------------
        if (cpu_iMEME = '1' and not pass_instr) then
            -- translate address
            translate(cpu_iADDR, paddr, miss, valid, dirty, cacheable);
            if (miss='1' or valid='0') then
                -- instruction tlb miss
            else
                -- tlb hit
                cache_iMEME <= '1';
                cache_iADDR <= paddr;
            end if;
        else
            cache_iMEME <= '0';
            cache_iADDR <= x"00000";
        end if;
    end if;

end process;

end Behavioral;
