library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use std.textio.all;
use work.txt_util.all;

entity dvga is
    Port (
        CLK      : in  STD_LOGIC; -- 50MHz clock input
        -- System Bus
        CS       : in STD_LOGIC;
        WR       : in STD_LOGIC;
        A        : in STD_LOGIC_VECTOR (13 downto 0);
        D        : in STD_LOGIC_VECTOR (7 downto 0);
        -- Debugging
        Finished : in STD_LOGIC
    );
end dvga;

architecture Structural of dvga is

type vram_t is array (0 to 8192) of STD_LOGIC_VECTOR (7 downto 0);
signal vram : vram_t := (others => x"00");

file l_file: TEXT open write_mode is "vga.s";

begin

process (clk)
begin

    if ( clk = '0' and clk'event ) then
        if (Finished = '0') then
            if (CS = '1' and WR = '1') then
                vram(conv_integer(unsigned(A(10 downto 0)))) <= D;
            end if;
        else
            print(l_file, ".text");
            print(l_file, ".global __start");
            print(l_file, "__start:");
            print(l_file, "lui $3, 1");
            print(l_file, "ori $3, 0x8000");
            for i in 0 to 80*30*2-1 loop
                print(l_file, "lui $2, 0");
                print(l_file, "ori $2, " & str(conv_integer(vram(i))));
                print(l_file, "sw  $2, " & str(i*4) & "($3)");
            end loop;
            print(l_file, "j .");
        end if;
    end if;

end process;

end Structural;
