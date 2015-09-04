library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity regs is
    Port (
        CLK     : in  STD_LOGIC;
        -- input from CPU
        DATAIN  : in  STD_LOGIC_VECTOR (7 downto 0);
        -- input from control unit
        SRC     : in  STD_LOGIC_VECTOR (4 downto 0);
        DEST    : in  STD_LOGIC_VECTOR (4 downto 0);
        -- input from ALU
        ALU_AZL : in  STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_AZH : in  STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_C   : in  STD_LOGIC                     := '0';
        ALU_Z   : in  STD_LOGIC                     := '0';
        ALU_N   : in  STD_LOGIC                     := '0';
        ALU_V   : in  STD_LOGIC                     := '0';
        -- output to the CPU
        MEME    : out STD_LOGIC                     := '0';
        RW      : out STD_LOGIC                     := '0';
        ABL     : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ABH     : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        DATAOUT : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        IAK     : out STD_LOGIC                     := '0';
        NAK     : out STD_LOGIC                     := '0';
        -- output to control unit
        CU_C    : out STD_LOGIC                     := '0';
        CU_Z    : out STD_LOGIC                     := '0';
        CU_N    : out STD_LOGIC                     := '0';
        CU_V    : out STD_LOGIC                     := '0';
        CU_I    : out STD_LOGIC                     := '0';
        CU_IR   : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        -- output to ALU
        ALU_AXL : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_AXH : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_AY  : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_AOP : out STD_LOGIC_VECTOR (7 downto 0) := x"00";
        ALU_Cin : out STD_LOGIC                     := '0';
        ALU_REP : out STD_LOGIC                     := '0'
    );
end regs;

architecture Behavioral of regs is

-- registers:
signal PCL : STD_LOGIC_VECTOR (7 downto 0);
signal PCH : STD_LOGIC_VECTOR (7 downto 0);
signal A   : STD_LOGIC_VECTOR (7 downto 0);
signal X   : STD_LOGIC_VECTOR (7 downto 0);
signal Y   : STD_LOGIC_VECTOR (7 downto 0);
signal S   : STD_LOGIC_VECTOR (7 downto 0);
signal P   : STD_LOGIC_VECTOR (7 downto 0);
signal T   : STD_LOGIC_VECTOR (7 downto 0);
signal U   : STD_LOGIC_VECTOR (7 downto 0);

begin
process (CLK)
    variable IMM : STD_LOGIC_VECTOR (7 downto 0) := x"00";
begin
    if (CLK = '1' and CLK'event) then
        case conv_integer(unsigned(SRC)) is
            when  0 => -- none
            when  1 => IMM    := DATAIN;
            when  2 => IMM    := PCL;
            when  3 => IMM    := PCH;
            when  4 => IMM    := A;
            when  5 => IMM    := X;
            when  6 => IMM    := Y;
            when  7 => IMM    := S;
            when  8 => IMM    := P;
            when  9 => IMM    := T;
            when 10 => IMM    := U;
            when 11 => IMM(0) := ALU_C;
            when 12 => IMM(0) := ALU_Z;
            when 13 => IMM(0) := ALU_N;
            when 14 => IMM(0) := ALU_V;
            when 15 => IMM    := ALU_AZL;
            when 16 => IMM    := ALU_AZH;
            when 17 => IMM    := x"00";
            when 18 => IMM    := x"01";
            when 19 => IMM    := x"02";
            when 20 => IMM    := x"04";
            when 21 => IMM    := x"08";
            when 22 => IMM    := x"10";
            when 23 => IMM    := x"20";
            when 24 => IMM    := x"40";
            when 25 => IMM    := x"80";
            when 26 => IMM    := x"FA";
            when 27 => IMM    := x"FB";
            when 28 => IMM    := x"FC";
            when 29 => IMM    := x"FD";
            when 30 => IMM    := x"FE";
            when 31 => IMM    := x"FF";
            when others =>
        end case;
        case conv_integer(unsigned(DEST)) is
            when  0 => -- none
            when  1 => DATAOUT <= IMM;
            when  2 => PCL     <= IMM;
            when  3 => PCH     <= IMM;
            when  4 => A       <= IMM;
            when  5 => X       <= IMM;
            when  6 => Y       <= IMM;
            when  7 => S       <= IMM;
            when  8 => P       <= IMM;
            when  9 => T       <= IMM;
            when 10 => U       <= IMM;
            when 11 => P(0)    <= IMM(0);
            when 12 => P(1)    <= IMM(0);
            when 13 => P(7)    <= IMM(0);
            when 14 => P(6)    <= IMM(0);
            when 15 => ALU_AXL <= IMM;
            when 16 => ALU_AXH <= IMM;
            when 17 => ALU_AY  <= IMM;
            when 18 => ALU_AOP <= IMM;
            when 19 => CU_IR   <= IMM;
            when 20 => ABL     <= IMM;
            when 21 => ABH     <= IMM;
            when 22 => -- none
            when 23 => IAK     <= IMM(0);
            when 24 => NAK     <= IMM(0);
            when 25 => ALU_Cin <= IMM(0);
            when 26 => ALU_REP <= IMM(0);
            when 27 => P(2)    <= IMM(0);
            when 28 => P(3)    <= IMM(0);
            when 29 => -- none
            when 30 => -- none
            when 31 => -- none
            when others =>
        end case;
        -- manage cpu memory bus signals:
        if ((conv_integer(unsigned(SRC)))  = 1) then
            MEME <= '1';
            RW   <= '0';
        elsif ((conv_integer(unsigned(DEST))) = 1) then
            MEME <= '1';
            RW   <= '1';
        else
            MEME <= '0';
            RW   <= '0';
        end if;
        -- manage outputs to control unit
        if ((conv_integer(unsigned(DEST))) = 8) then
            CU_C <= IMM(0);
            CU_Z <= IMM(1);
            CU_I <= IMM(2);
            CU_V <= IMM(6);
            CU_N <= IMM(7);
        elsif ((conv_integer(unsigned(DEST))) = 11) then
            CU_C <= IMM(0);
        elsif ((conv_integer(unsigned(DEST))) = 12) then
            CU_Z <= IMM(0);
        elsif ((conv_integer(unsigned(DEST))) = 13) then
            CU_N <= IMM(0);
        elsif ((conv_integer(unsigned(DEST))) = 14) then
            CU_V <= IMM(0);
        elsif ((conv_integer(unsigned(DEST))) = 27) then
            CU_I <= IMM(0);
        else
            -- nothing to do here
        end if;
    end if;
end process;

end architecture;
