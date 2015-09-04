library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cu_logic is
    Port (
        CLK  : in    STD_LOGIC;
        SEQ  : inout STD_LOGIC_VECTOR (10 downto 0) := "00000000000";
        MIR  : in    STD_LOGIC_VECTOR (15 downto 0);
        LUR  : in    STD_LOGIC_VECTOR (15 downto 0);
        M    : in    STD_LOGIC
    );
end cu_logic;

architecture Behavioral of cu_logic is

begin

process (CLK)
    variable SHIFT : STD_LOGIC_VECTOR ( 2 downto 0);
    variable NSEQ  : integer range 0 to 4096;
begin
    if (CLK = '0' and CLK'event) then
        -- decode MIR based on its type:
        if (MIR(1) = '0' and MIR(0) = '1') then
            -- lookup
            SHIFT(0) := MIR(2);
            SHIFT(1) := MIR(3);
            SHIFT(2) := MIR(4);
            NSEQ := conv_integer(unsigned(LUR))+conv_integer(unsigned(SHIFT));
            SEQ  <= conv_std_logic_vector(NSEQ, SEQ'length);
        elsif (MIR(1) = '1' and MIR(0) = M) then
            -- <If condition> matches
            SEQ( 0) <= MIR( 5);
            SEQ( 1) <= MIR( 6);
            SEQ( 2) <= MIR( 7);
            SEQ( 3) <= MIR( 8);
            SEQ( 4) <= MIR( 9);
            SEQ( 5) <= MIR(10);
            SEQ( 6) <= MIR(11);
            SEQ( 7) <= MIR(12);
            SEQ( 8) <= MIR(13);
            SEQ( 9) <= MIR(14);
            SEQ(10) <= MIR(15);
        else
            -- just increase the sequencer by 1
            NSEQ := conv_integer(unsigned(SEQ))+1;
            SEQ  <= conv_std_logic_vector(NSEQ, SEQ'length);
        end if;
    end if;
end process;

end architecture;
