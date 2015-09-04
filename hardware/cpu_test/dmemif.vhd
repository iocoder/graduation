library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity dmemif is
    Port (
        CLK      : in    STD_LOGIC;
        -- Interface
        A        : in    STD_LOGIC_VECTOR (21 downto 0);
        Din      : in    STD_LOGIC_VECTOR (31 downto 0);
        Dout     : out   STD_LOGIC_VECTOR (31 downto 0);
        DTYPE    : in    STD_LOGIC_VECTOR (2  downto 0);
        RAM_CS   : in    STD_LOGIC; -- RAM chip enable
        ROM_CS   : in    STD_LOGIC; -- ROM chip enable
        RW       : in    STD_LOGIC; -- 0: read, 1: write
        -- Debugging
        Finished : in    STD_LOGIC
    );
end entity;

architecture Dataflow of dmemif is

type mem_t is array (0 to 65535) of STD_LOGIC_VECTOR (7 downto 0);
signal ram : mem_t := (others => x"00");
signal rom : mem_t := (others => x"00");

begin

process(CLK)
type     RAMFileType is file of CHARACTER;
FILE     RAMFile   : RAMFileType;
begin
    if (CLK = '1' and CLK'event) then

        if (Finished = '1') then
            file_open(RAMFile, "ram.bin", WRITE_MODE);
            for i in 0 to 65535 loop
                write(RAMFile, character'val(conv_integer(ram(i))));
            end loop;
            file_close(RAMFile);
        elsif (RAM_CS = '1') then
            -- RAM
            if (RW = '0') then
                -- READ
                if (DTYPE(0) = '1') then
                    -- BYTE
                    Dout <= x"000000" & ram(conv_integer(A(13 downto 0)&"00"));
                elsif (DTYPE(1) = '1') then
                    -- HALF
                    Dout <= x"0000" & ram(conv_integer(A(13 downto 0)&"01"))
                                    & ram(conv_integer(A(13 downto 0)&"00"));
                else
                    -- WORD
                    Dout <= ram(conv_integer(A(13 downto 0)&"11"))
                         & ram(conv_integer(A(13 downto 0)&"10"))
                         & ram(conv_integer(A(13 downto 0)&"01"))
                         & ram(conv_integer(A(13 downto 0)&"00"));
                end if;
            else
                -- WRITE
                if (DTYPE(0) = '1') then
                    -- BYTE
                    ram(conv_integer(A(13 downto 0)&"00"))<=Din( 7 downto  0);
                elsif (DTYPE(1) = '1') then
                    -- HALF
                    ram(conv_integer(A(13 downto 0)&"00"))<=Din( 7 downto  0);
                    ram(conv_integer(A(13 downto 0)&"01"))<=Din(15 downto  8);
                else
                    -- WORD
                    ram(conv_integer(A(13 downto 0)&"00"))<=Din( 7 downto  0);
                    ram(conv_integer(A(13 downto 0)&"01"))<=Din(15 downto  8);
                    ram(conv_integer(A(13 downto 0)&"10"))<=Din(23 downto 16);
                    ram(conv_integer(A(13 downto 0)&"11"))<=Din(31 downto 24);
                end if;
            end if;
        elsif (ROM_CS = '1') then
            -- ROM
            if (RW = '0') then
                -- READ
                if (DTYPE(0) = '1') then
                    -- BYTE
                    Dout <= x"000000" & rom(conv_integer(A(13 downto 0)&"00"));
                elsif (DTYPE(1) = '1') then
                    -- HALF
                    Dout <= x"0000" & rom(conv_integer(A(13 downto 0)&"00"))
                                    & rom(conv_integer(A(13 downto 0)&"01"));
                else
                    -- WORD
                    Dout <= rom(conv_integer(A(13 downto 0)&"00"))
                          & rom(conv_integer(A(13 downto 0)&"01"))
                          & rom(conv_integer(A(13 downto 0)&"10"))
                          & rom(conv_integer(A(13 downto 0)&"11"));
                end if;
            end if;
        else
            -- OTHER
            Dout <= x"00000000";
        end if;

    end if;
end process;

process is
type     ROMFileType is file of CHARACTER;
FILE     ROMFile     : ROMFileType;
variable somebyte    : CHARACTER;
begin
    file_open(ROMFile, "rom.bin", READ_MODE);
    for i in 0 to 65535 loop
        if (not endfile(ROMFile)) then
            read (ROMFile, somebyte);
            rom(i) <= conv_std_logic_vector(character'pos(somebyte), 8);
        end if;
        wait for 1ns;
    end loop;
    wait;
end process;

end Dataflow;
