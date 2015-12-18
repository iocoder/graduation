library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pic is
    Port (
        CLK      : in    STD_LOGIC;
        IRQ_in   : in    STD_LOGIC_VECTOR (7 downto 0);
        IAK_out  : out   STD_LOGIC_VECTOR (7 downto 0);
        IRQ_out  : out   STD_LOGIC := '0';
        IAK_in   : in    STD_LOGIC;
        CS       : in    STD_LOGIC;
        RW       : in    STD_LOGIC; -- 0: read, 1: write
        Din      : in    STD_LOGIC_VECTOR (31 downto 0);
        Dout     : out   STD_LOGIC_VECTOR (31 downto 0);
        DTYPE    : in    STD_LOGIC_VECTOR ( 2 downto 0);
        RDY      : out   STD_LOGIC := '1'
    );
end pic;

architecture Behavioral of pic is

signal enable_back    : std_logic := '0';
signal enable_forward : std_logic := '1';
signal int_device     : std_logic_vector (31 downto 0);

begin

process (CLK)

begin

    if ( CLK = '1' and CLK'event ) then

        if (enable_back = enable_forward) then
            if (IAK_in = '1') then
                -- disable PIC
                enable_back <= not enable_back;
                -- select the interrupting device and handle IAK
                if (IRQ_in(0) = '1') then
                    int_device <= x"00000000";
                    IAK_out    <=  "00000001";
                elsif (IRQ_in(1) = '1') then
                    int_device <= x"00000001";
                    IAK_out    <=  "00000010";
                elsif (IRQ_in(2) = '1') then
                    int_device <= x"00000002";
                    IAK_out    <=  "00000100";
                elsif (IRQ_in(3) = '1') then
                    int_device <= x"00000003";
                    IAK_out    <=  "00001000";
                elsif (IRQ_in(4) = '1') then
                    int_device <= x"00000004";
                    IAK_out    <=  "00010000";
                elsif (IRQ_in(5) = '1') then
                    int_device <= x"00000005";
                    IAK_out    <=  "00100000";
                elsif (IRQ_in(6) = '1') then
                    int_device <= x"00000006";
                    IAK_out    <=  "01000000";
                else
                    int_device <= x"00000007";
                    IAK_out    <=  "10000000";
                end if;
                -- stop IRQ request
                IRQ_out <= '0';
            elsif (IRQ_in = x"00") then
                -- no pending IRQ request
                IRQ_out <= '0';
            else
                -- an IRQ is pending
                IRQ_out <= '1';
            end if;
        else
            -- stop IAK
            IAK_out <= "00000000";
        end if;

        -- bus interface
        if (CS = '1') then
            if (RW = '1') then
                if (Din(0) = '1') then
                    -- enable
                    enable_forward <= enable_back;
                else
                    -- disable
                    enable_forward <= not enable_back;
                end if;
            else
                Dout  <= int_device;
            end if;
        else
            Dout <= x"00000000";
        end if;

    end if;

end process;

end Behavioral;
