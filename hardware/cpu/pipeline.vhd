library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.cpu_pkg.all;

entity pipeline is
    Port (
        CLK50  : in  STD_LOGIC;
        CLK    : in  STD_LOGIC;
        STALL  : in  STD_LOGIC;
        IRQ    : in  STD_LOGIC;
        NMI    : in  STD_LOGIC;
        IAK    : out STD_LOGIC := '0';
        NAK    : out STD_LOGIC := '0';
        -- instruction bus
        iMEME  : out STD_LOGIC;
        iRW    : out STD_LOGIC;
        iADDR  : out STD_LOGIC_VECTOR (31 downto 0);
        iDin   : in  STD_LOGIC_VECTOR (31 downto 0);
        iDout  : out STD_LOGIC_VECTOR (31 downto 0);
        iDTYPE : out STD_LOGIC_VECTOR ( 2 downto 0);
        -- data bus
        dMEME  : out STD_LOGIC;
        dRW    : out STD_LOGIC;
        dADDR  : out STD_LOGIC_VECTOR (31 downto 0);
        dDin   : in  STD_LOGIC_VECTOR (31 downto 0);
        dDout  : out STD_LOGIC_VECTOR (31 downto 0);
        dDTYPE : out STD_LOGIC_VECTOR ( 2 downto 0)
    );
end entity;

architecture Behavioral of pipeline is

-- TYPES
type     regfile_t  is array (0 to 31) of STD_LOGIC_VECTOR (31 downto 0);

-- CONTROL SIGNALS
constant REG_DEST       : integer := 0;
constant ALU_SRC        : integer := 1;
constant MEM_TO_REG     : integer := 2;
constant REG_WRITE      : integer := 3;
constant MEM_READ       : integer := 4;
constant MEM_WRITE      : integer := 5;
constant BRANCH         : integer := 6;
constant CTRL_COUNT     : integer := 7;

-- FORMATS
constant R_FORMAT       : integer := 0;
constant I_FORMAT       : integer := 1;
constant J_FORMAT       : integer := 2;

-- ALU OPERATIONS
constant ALUOP_NOP      : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
constant ALUOP_EXP      : STD_LOGIC_VECTOR ( 7 downto 0) := x"01";
constant ALUOP_CPYPC    : STD_LOGIC_VECTOR ( 7 downto 0) := x"02";
constant ALUOP_LUI      : STD_LOGIC_VECTOR ( 7 downto 0) := x"03";
constant ALUOP_MFHI     : STD_LOGIC_VECTOR ( 7 downto 0) := x"10";
constant ALUOP_MTHI     : STD_LOGIC_VECTOR ( 7 downto 0) := x"11";
constant ALUOP_MFLO     : STD_LOGIC_VECTOR ( 7 downto 0) := x"12";
constant ALUOP_MTLO     : STD_LOGIC_VECTOR ( 7 downto 0) := x"13";
constant ALUOP_MULT     : STD_LOGIC_VECTOR ( 7 downto 0) := x"14";
constant ALUOP_MULTU    : STD_LOGIC_VECTOR ( 7 downto 0) := x"15";
constant ALUOP_DIV      : STD_LOGIC_VECTOR ( 7 downto 0) := x"16";
constant ALUOP_DIVU     : STD_LOGIC_VECTOR ( 7 downto 0) := x"17";
constant ALUOP_ADD      : STD_LOGIC_VECTOR ( 7 downto 0) := x"20";
constant ALUOP_ADDU     : STD_LOGIC_VECTOR ( 7 downto 0) := x"21";
constant ALUOP_SUB      : STD_LOGIC_VECTOR ( 7 downto 0) := x"22";
constant ALUOP_SUBU     : STD_LOGIC_VECTOR ( 7 downto 0) := x"23";
constant ALUOP_AND      : STD_LOGIC_VECTOR ( 7 downto 0) := x"24";
constant ALUOP_OR       : STD_LOGIC_VECTOR ( 7 downto 0) := x"25";
constant ALUOP_XOR      : STD_LOGIC_VECTOR ( 7 downto 0) := x"26";
constant ALUOP_NOR      : STD_LOGIC_VECTOR ( 7 downto 0) := x"27";
constant ALUOP_SLT      : STD_LOGIC_VECTOR ( 7 downto 0) := x"2A";
constant ALUOP_SLTU     : STD_LOGIC_VECTOR ( 7 downto 0) := x"2B";
constant ALUOP_SLL      : STD_LOGIC_VECTOR ( 7 downto 0) := x"30";
constant ALUOP_SRL      : STD_LOGIC_VECTOR ( 7 downto 0) := x"32";
constant ALUOP_SRA      : STD_LOGIC_VECTOR ( 7 downto 0) := x"33";
constant ALUOP_SLLV     : STD_LOGIC_VECTOR ( 7 downto 0) := x"34";
constant ALUOP_SRLV     : STD_LOGIC_VECTOR ( 7 downto 0) := x"36";
constant ALUOP_SRAV     : STD_LOGIC_VECTOR ( 7 downto 0) := x"37";

-- MEMORY OPERATIONS
constant MEMOP_BYTE     : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
constant MEMOP_HALF     : STD_LOGIC_VECTOR ( 7 downto 0) := x"01";
constant MEMOP_LEFT     : STD_LOGIC_VECTOR ( 7 downto 0) := x"02";
constant MEMOP_WORD     : STD_LOGIC_VECTOR ( 7 downto 0) := x"03";
constant MEMOP_BYTEU    : STD_LOGIC_VECTOR ( 7 downto 0) := x"04";
constant MEMOP_HALFU    : STD_LOGIC_VECTOR ( 7 downto 0) := x"05";
constant MEMOP_RIGHT    : STD_LOGIC_VECTOR ( 7 downto 0) := x"06";

-- PC SOURCE
constant PCSRC_PC4      : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
constant PCSRC_BRANCH   : STD_LOGIC_VECTOR ( 7 downto 0) := x"01";
constant PCSRC_JMP      : STD_LOGIC_VECTOR ( 7 downto 0) := x"02";
constant PCSRC_JR       : STD_LOGIC_VECTOR ( 7 downto 0) := x"03";
constant PCSRC_EXP      : STD_LOGIC_VECTOR ( 7 downto 0) := x"04";

-- EXCEPTION HANDLER
signal   exception      : STD_LOGIC := '0';

-- IF
signal   if_pc          : STD_LOGIC_VECTOR (31 downto 0) := x"BFBFFFFC";
signal   if_pc4         : STD_LOGIC_VECTOR (31 downto 0) := x"BFC00000";
signal   if_instr       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   if_exphndl     : STD_LOGIC := '0';
signal   if_exception   : STD_LOGIC := '0';

-- ID
signal   id_instr       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_opcode      : STD_LOGIC_VECTOR ( 5 downto 0) := "000000";
signal   id_rs          : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   id_rt          : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   id_rd          : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   id_ropcode     : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   id_shamt       : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   id_funct       : STD_LOGIC_VECTOR ( 5 downto 0) := "000000";
signal   id_is_jr       : STD_LOGIC := '0';
signal   id_is_jalr     : STD_LOGIC := '0';
signal   id_is_bltz     : STD_LOGIC := '0';
signal   id_is_bgez     : STD_LOGIC := '0';
signal   id_is_blzal    : STD_LOGIC := '0';
signal   id_is_bgzal    : STD_LOGIC := '0';
signal   id_is_j        : STD_LOGIC := '0';
signal   id_is_jal      : STD_LOGIC := '0';
signal   id_is_beq      : STD_LOGIC := '0';
signal   id_is_bne      : STD_LOGIC := '0';
signal   id_is_blez     : STD_LOGIC := '0';
signal   id_is_bgtz     : STD_LOGIC := '0';
signal   id_is_branch   : STD_LOGIC := '0';
signal   id_pc          : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_pc4         : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_imm32       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_shl         : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_val_of_rs   : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_val_of_rt   : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_cop0_regrd  : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_val1        : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_val2        : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_braddr      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_jmpaddr     : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_jraddr      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_is_equal    : STD_LOGIC := '0';
signal   id_is_zero     : STD_LOGIC := '0';
signal   id_is_lez      : STD_LOGIC := '0';
signal   id_is_gtz      : STD_LOGIC := '0';
signal   id_is_mfc0     : STD_LOGIC := '0';
signal   id_is_mtc0     : STD_LOGIC := '0';
signal   id_is_rfe      : STD_LOGIC := '0';
signal   id_is_cop0     : STD_LOGIC := '0';
signal   id_pc_src      : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   id_if_flush    : STD_LOGIC := '0';
signal   id_ctrlsig_in  : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   id_aluop       : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   id_memop       : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   id_ctrlsig     : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   id_stall       : STD_LOGIC := '0';
signal   id_ifclk       : STD_LOGIC := '1';
signal   id_pcclk       : STD_LOGIC := '1';
signal   id_exception   : STD_LOGIC := '0';
signal   id_regfile_p1  : STD_LOGIC := '0';
signal   id_regfile_p2  : STD_LOGIC := '0';
signal   id_regfile     : regfile_t := (others => x"00000000");
signal   id_regfile1    : regfile_t := (others => x"00000000");
signal   id_regfile2    : regfile_t := (others => x"00000000");
attribute ram_style: string;
attribute ram_style of id_regfile : signal is "block";
attribute ram_style of id_regfile1 : signal is "block";
attribute ram_style of id_regfile2 : signal is "block";

-- EX
signal   ex_hi          : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_lo          : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_op1         : STD_LOGIC_VECTOR (31 downto 0);
signal   ex_op2         : STD_LOGIC_VECTOR (31 downto 0);
signal   ex_mulres      : STD_LOGIC_VECTOR (63 downto 0);
signal   ex_busy        : integer := 0;
signal   ex_phase       : integer := 0;
signal   ex_instr       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_rs          : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   ex_rt          : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   ex_rd          : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   ex_shamt       : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   ex_pc4         : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_aluop       : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   ex_memop       : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   ex_ctrlsig     : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   ex_val_of_rs   : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_val_of_rt   : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_imm32       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_fu_mux1     : STD_LOGIC_VECTOR ( 1 downto 0) := "00";
signal   ex_fu_mux2     : STD_LOGIC_VECTOR ( 1 downto 0) := "00";
signal   ex_muxop1      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_muxop2      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_alu1        : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_alu2        : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_alu_output  : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_rk          : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   ex_is_mfc0     : STD_LOGIC := '0';
signal   ex_is_mtc0     : STD_LOGIC := '0';
signal   ex_exception   : STD_LOGIC := '0';

-- MEM
signal   mem_busy       : boolean := false;
signal   mem_phase      : integer := 0;
signal   mem_instr      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_pc4        : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_memop      : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   mem_ctrlsig    : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   mem_addr       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_data_in    : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_data_out   : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_tmp        : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_tmp2       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_rk         : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   mem_is_mfc0    : STD_LOGIC := '0';
signal   mem_is_mtc0    : STD_LOGIC := '0';
signal   mem_exception  : STD_LOGIC := '0';

-- WB
signal   wb_instr       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   wb_pc4         : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   wb_ctrlsig     : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   wb_mem_out     : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   wb_alu_out     : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   wb_value_of_rk : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   wb_rk          : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";
signal   wb_is_mfc0     : STD_LOGIC := '0';
signal   wb_is_mtc0     : STD_LOGIC := '0';
signal   wb_exception   : STD_LOGIC := '0';

-- coprocessor registers:
constant IEc            : integer := 0;
constant KUc            : integer := 1;
constant IEp            : integer := 2;
constant KUp            : integer := 3;
constant IEo            : integer := 4;
constant KUo            : integer := 5;

constant IR             : STD_LOGIC_VECTOR (4 downto 0) := "00000";

signal   SR             : STD_LOGIC_VECTOR (31 downto 0) := x"00000000"; -- 12
signal   CAUSE          : STD_LOGIC_VECTOR (31 downto 0) := x"00000000"; -- 13
signal   EPC            : STD_LOGIC_VECTOR (31 downto 0) := x"00000000"; -- 14

signal   CAUSE_tmp      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   EPC_tmp        : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";

signal   got_rising     : std_logic := '0';
signal   got_falling    : std_logic := '0';

signal   int_busy       : boolean := false;
signal   iSTALL         : STD_LOGIC;

begin

--       _   _   _   _   _
-- CLK _| |_| |_| |_| |_| |
--      ^   ^   ^   ^   ^    Rising : CPU starts new cycle.
--        +   +   +   +   +  Falling: exception handling, register transfers.
--                                    TLB has translated address and cache
--                                    has moved to phase 1

iSTALL <= '1' when STALL='1' or ex_busy = 1 or int_busy or mem_busy else '0';

--------------------------------------------------------------------------------
--                              EXCEPTIONS                                    --
--------------------------------------------------------------------------------

-- exception handler
process(CLK)
begin

    if (CLK = '1' and CLK'event and iSTALL='0') then
        got_rising <= not got_rising;
    end if;

    if (CLK = '0' and CLK'event) then
        if (got_falling /= got_rising or int_busy) then
            -- if exception conditions are satisfied, next cycle is
            -- an exception fetch, and all stages before and including the
            -- exception-source stage shall be flushed.
            if (int_busy) then
                int_busy <= false;
                -- store EPC and CAUSE
                if (id_is_jr='1' or id_is_jalr='1' or
                    is_branchregimm(id_opcode) or
                    is_jmp(id_opcode) or
                    is_branch(id_opcode)) then
                    -- branch instruction in ID stage
                    EPC <= id_pc;
                    CAUSE <= x"80000000";
                else
                    EPC <= if_pc;
                    CAUSE <= x"00000000";
                end if;
            elsif (if_exphndl = '1') then
                -- exception served
                if_exception <= '0';
                IAK <= '1';
                exception <= '1';
            elsif (exception='1') then
                -- deactivate interrupt ack
                IAK <= '0';
                exception <= '0';
            elsif (IRQ = '1' and SR(IEc) = '1' and if_exception='0') then
                -- IRQ happened!
                if_exception <= '1';
                int_busy <= true;
            end if;
            got_falling <= got_rising;
        end if;
    end if;

end process;

--------------------------------------------------------------------------------
--                               IF STAGE                                     --
--------------------------------------------------------------------------------

-- register transfer
process(CLK)

variable handle_exception : boolean := false;

begin
    if (CLK = '1' and CLK'event and iSTALL = '0') then

        handle_exception := false;

        if (if_exception='1' and
            id_instr=x"00000000" and
            ex_instr=x"00000000" and
            mem_instr=x"00000000") then
            -- IF STAGE EXCEPTION
            handle_exception := true;
        elsif (id_exception='1' and
               ex_instr=x"00000000" and
               mem_instr=x"00000000") then
            -- ID EXCEPTION
            handle_exception := true;
        elsif (ex_exception='1' and mem_instr=x"00000000") then
            -- EX EXCEPTION
            handle_exception := true;
        elsif (mem_exception='1') then
            -- MEM EXCEPTION
            handle_exception := true;
        end if;

        if (handle_exception) then
            if_pc        <= x"BFC00180";
            if_exphndl   <= '1';
        elsif (if_exception='1') then
            -- Don't Move (Phantogram)
        else
            -- normal operation
            if (id_pcclk = '1') then
                if (id_pc_src = PCSRC_PC4 or if_exphndl = '1') then
                    if_pc <= if_pc4;
                elsif (id_pc_src = PCSRC_BRANCH) then
                    if_pc <= id_braddr;
                elsif (id_pc_src = PCSRC_JMP) then
                    if_pc <= id_jmpaddr;
                elsif (id_pc_src = PCSRC_JR) then
                    if_pc <= id_jraddr;
                end if;
            end if;
            if_exphndl   <= '0';
        end if;
    end if;
end process;

-- add 4 to pc
if_pc4 <= alu_add(if_pc, x"00000004");

-- interface iMEM component
iMEME    <= '1';
iRW      <= '0';
iADDR    <= if_pc;
iDTYPE   <= "100";
if_instr <= iDin;
iDout    <= x"00000000";

--------------------------------------------------------------------------------
--                               ID STAGE                                     --
--------------------------------------------------------------------------------

-- register transfer
process(CLK)

variable id_next_instr  : STD_LOGIC_VECTOR (31 downto 0);
variable id_next_opcode : STD_LOGIC_VECTOR ( 5 downto 0);
variable id_next_funct  : STD_LOGIC_VECTOR ( 5 downto 0);

begin
    if (CLK = '1' and CLK'event and iSTALL = '0') then
        if (id_exception='1') then
            -- don't move
            id_next_instr := id_instr;
        elsif (if_exception='1') then
            -- flush ID
            id_instr      <= x"00000000";
            id_next_instr := x"00000000";
            id_pc         <= if_pc;
            id_pc4        <= if_pc4;
        else
            -- normal operation
            if (id_ifclk = '1') then
                id_instr      <= if_instr;
                id_next_instr := if_instr;
                id_pc         <= if_pc;
                id_pc4        <= if_pc4;
            else
                id_next_instr := id_instr;
            end if;
        end if;

        id_next_opcode := id_next_instr(31 downto 26);
        id_next_funct  := id_next_instr( 5 downto 0);

        if ((id_next_opcode="000000" and id_next_funct="001000") or
            (id_next_opcode="000000" and id_next_funct="001001") or
            is_branchregimm(id_next_opcode) or
            is_jmp(id_next_opcode) or
            is_branch(id_next_opcode)) then
            id_is_branch <= '1';
        else
            id_is_branch <= '0';
        end if;

    end if;
end process;

-- register file operation
process(CLK)

-- vals of rs & rt registers extracted from regfile (or by forwarding)
variable val_of_rs : STD_LOGIC_VECTOR(31 downto 0);
variable val_of_rt : STD_LOGIC_VECTOR(31 downto 0);

impure function read_cop0_reg(indx : in STD_LOGIC_VECTOR (4  downto 0))
                return STD_LOGIC_VECTOR is
    variable retval    : STD_LOGIC_VECTOR(31 downto 0);
    begin
        case indx is
            when "01100" => retval := SR;
            when "01101" => retval := CAUSE;
            when "01110" => retval := EPC;
            when others  =>
        end case;
        return retval;
end read_cop0_reg;

procedure write_cop0_reg(indx : in STD_LOGIC_VECTOR (4  downto 0);
                         val  : in STD_LOGIC_VECTOR (31 downto 0)) is
    begin
        case indx is
            when "01100" => SR <= val;
            when others  =>
        end case;
end write_cop0_reg;

begin

    if (CLK50 = '0' and CLK50'event) then
        if (id_regfile_p1 = '0') then
            -- write to regfile
            if (wb_ctrlsig(REG_WRITE) = '1' and wb_rk /= "00000") then
                id_regfile1(conv_integer(wb_rk)) <= wb_value_of_rk;
                id_regfile2(conv_integer(wb_rk)) <= wb_value_of_rk;
            end if;
            id_regfile_p1 <= '1';
        else
            -- read from regfile
            id_val1 <= id_regfile1(conv_integer(id_rs));
            id_val2 <= id_regfile2(conv_integer(id_rt));
            id_regfile_p1 <= '0';
        end if;
    end if;

    if (CLK = '0' and CLK'event) then
        if (if_exphndl='1' and if_exception='1') then
            -- disable interrupts
            SR(5 downto 0) <= SR(3 downto 0) & "00";
        elsif (id_is_rfe='1') then
            SR(3 downto 0) <= SR(5 downto 2);
        elsif (wb_is_mtc0='1') then
            -- write to coprocessor registers
            write_cop0_reg(wb_rk, wb_value_of_rk);
        else
            -- read from coprocessor registers
            id_cop0_regrd <= read_cop0_reg(id_rd);
        end if;

    end if;

end process;

-- combinational logic
id_opcode   <= id_instr(31 downto 26);
id_rs       <= id_instr(25 downto 21);
id_rt       <= id_instr(20 downto 16);
id_rd       <= id_instr(15 downto 11) when id_opcode /= "000011" else "11111";
id_ropcode  <= id_instr(20 downto 16);
id_shamt    <= id_instr(10 downto  6);
id_funct    <= id_instr( 5 downto  0);
id_is_jr    <= '1' when id_opcode="000000" and id_funct="001000" else '0';
id_is_jalr  <= '1' when id_opcode="000000" and id_funct="001001" else '0';
id_is_bltz  <= '1' when id_opcode="000001" and id_ropcode = "00000" else '0';
id_is_bgez  <= '1' when id_opcode="000001" and id_ropcode = "00001" else '0';
id_is_blzal <= '1' when id_opcode="000001" and id_ropcode = "10000" else '0';
id_is_bgzal <= '1' when id_opcode="000001" and id_ropcode = "10001" else '0';
id_is_j     <= '1' when id_opcode="000010" else '0';
id_is_jal   <= '1' when id_opcode="000011" else '0';
id_is_beq   <= '1' when id_opcode="000100" else '0';
id_is_bne   <= '1' when id_opcode="000101" else '0';
id_is_blez  <= '1' when id_opcode="000110" else '0';
id_is_bgtz  <= '1' when id_opcode="000111" else '0';
id_imm32    <= alu_add(id_pc4, x"00000004") when (
                  id_opcode = "000011" or
                  (id_opcode = "000000" and id_funct = "001001") or
                  (id_opcode = "000001" and id_ropcode = "10000") or
                  (id_opcode = "000001" and id_ropcode = "10001")) else
               unsiext2(id_instr(15 downto 0)) when (
                  id_opcode = "001100" or
                  id_opcode = "001101" or
                  id_opcode = "001110") else
               signext2(id_instr(15 downto 0));
id_shl      <= id_imm32(29 downto 0) & "00";
id_braddr   <= alu_add(id_pc4, id_shl);
id_jmpaddr  <= id_pc4(31 downto 28) & id_instr(25 downto 0) & "00";
id_jraddr   <= id_val_of_rs;
id_is_equal <= '1' when id_val_of_rs = id_val_of_rt else '0';
id_is_zero  <= '1' when id_val_of_rs = x"00000000" else '0';
id_is_lez   <= alu_lts(id_val_of_rs, x"00000000")(0) OR id_is_zero;
id_is_gtz   <= NOT id_is_lez;
id_is_mfc0  <= '1' when is_cop0(id_opcode) and id_rs = "00000" else '0';
id_is_mtc0  <= '1' when is_cop0(id_opcode) and id_rs = "00100" else '0';
id_is_rfe   <= '1' when is_cop0(id_opcode) and id_rs = "10000"
                                           and id_funct = "010000" else '0';
id_is_cop0  <= '1' when is_cop0(id_opcode) else '0';

-- register file outputs
id_val_of_rs <= id_val1 when id_is_cop0='0' else
                id_cop0_regrd when id_is_mfc0='1' else
                x"00000000";
id_val_of_rt <= id_val2 when (id_is_cop0='0' or id_is_mtc0='1') else
                x"00000000";

-- generate control signals
id_ctrlsig_in(REG_DEST) <=
    '1'                                 when is_alureg      (id_opcode) else
    '1'                                 when is_branchregimm(id_opcode) else
    '1'                                 when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '0'                                 when is_aluimm      (id_opcode) else
    '0'                                 when is_memload     (id_opcode) else
    '0'                                 when is_memstore    (id_opcode) else
    id_is_mtc0                          when is_cop0        (id_opcode) else
    '0';
id_ctrlsig_in(ALU_SRC) <=
    id_is_jr or id_is_jalr              when is_alureg      (id_opcode) else
    '1'                                 when is_branchregimm(id_opcode) else
    '1'                                 when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '1'                                 when is_aluimm      (id_opcode) else
    '1'                                 when is_memload     (id_opcode) else
    '1'                                 when is_memstore    (id_opcode) else
    '0'                                 when is_cop0        (id_opcode) else
    '0';
id_ctrlsig_in(MEM_TO_REG) <=
    '0'                                 when is_alureg      (id_opcode) else
    '0'                                 when is_branchregimm(id_opcode) else
    '0'                                 when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '0'                                 when is_aluimm      (id_opcode) else
    '1'                                 when is_memload     (id_opcode) else
    '0'                                 when is_memstore    (id_opcode) else
    '0'                                 when is_cop0        (id_opcode) else
    '0';
id_ctrlsig_in(REG_WRITE) <=
    '1'                                 when is_alureg      (id_opcode) else
    id_is_blzal or id_is_bgzal          when is_branchregimm(id_opcode) else
    id_is_jal                           when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '1'                                 when is_aluimm      (id_opcode) else
    '1'                                 when is_memload     (id_opcode) else
    '0'                                 when is_memstore    (id_opcode) else
    id_is_mfc0                          when is_cop0        (id_opcode) else
    '0';
id_ctrlsig_in(MEM_READ) <=
    '0'                                 when is_alureg      (id_opcode) else
    '0'                                 when is_branchregimm(id_opcode) else
    '0'                                 when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '0'                                 when is_aluimm      (id_opcode) else
    '1'                                 when is_memload     (id_opcode) else
    '0'                                 when is_memstore    (id_opcode) else
    '0'                                 when is_cop0        (id_opcode) else
    '0';
id_ctrlsig_in(MEM_WRITE) <=
    '0'                                 when is_alureg      (id_opcode) else
    '0'                                 when is_branchregimm(id_opcode) else
    '0'                                 when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '0'                                 when is_aluimm      (id_opcode) else
    '0'                                 when is_memload     (id_opcode) else
    '1'                                 when is_memstore    (id_opcode) else
    '0'                                 when is_cop0        (id_opcode) else
    '0';
id_ctrlsig_in(BRANCH) <=
    id_is_jr or id_is_jalr              when is_alureg      (id_opcode) else
    '1'                                 when is_branchregimm(id_opcode) else
    '1'                                 when is_jmp         (id_opcode) else
    '1'                                 when is_branch      (id_opcode) else
    '0'                                 when is_aluimm      (id_opcode) else
    '0'                                 when is_memload     (id_opcode) else
    '0'                                 when is_memstore    (id_opcode) else
    '0'                                 when is_cop0        (id_opcode) else
    '0';

-- decoding
id_aluop <= ALUOP_SLL   when is_alureg(id_opcode) and id_funct = "000000" else
            ALUOP_SRL   when is_alureg(id_opcode) and id_funct = "000010" else
            ALUOP_SRA   when is_alureg(id_opcode) and id_funct = "000011" else
            ALUOP_SLLV  when is_alureg(id_opcode) and id_funct = "000100" else
            ALUOP_SRLV  when is_alureg(id_opcode) and id_funct = "000110" else
            ALUOP_SRAV  when is_alureg(id_opcode) and id_funct = "000111" else
            ALUOP_CPYPC when is_alureg(id_opcode) and id_funct = "001000" else
            ALUOP_CPYPC when is_alureg(id_opcode) and id_funct = "001001" else
            ALUOP_EXP   when is_alureg(id_opcode) and id_funct = "001100" else
            ALUOP_EXP   when is_alureg(id_opcode) and id_funct = "001101" else
            ALUOP_MFHI  when is_alureg(id_opcode) and id_funct = "010000" else
            ALUOP_MTHI  when is_alureg(id_opcode) and id_funct = "010001" else
            ALUOP_MFLO  when is_alureg(id_opcode) and id_funct = "010010" else
            ALUOP_MTLO  when is_alureg(id_opcode) and id_funct = "010011" else
            ALUOP_MULT  when is_alureg(id_opcode) and id_funct = "011000" else
            ALUOP_MULTU when is_alureg(id_opcode) and id_funct = "011001" else
            ALUOP_DIV   when is_alureg(id_opcode) and id_funct = "011010" else
            ALUOP_DIVU  when is_alureg(id_opcode) and id_funct = "011011" else
            ALUOP_ADD   when is_alureg(id_opcode) and id_funct = "100000" else
            ALUOP_ADDU  when is_alureg(id_opcode) and id_funct = "100001" else
            ALUOP_SUB   when is_alureg(id_opcode) and id_funct = "100010" else
            ALUOP_SUBU  when is_alureg(id_opcode) and id_funct = "100011" else
            ALUOP_AND   when is_alureg(id_opcode) and id_funct = "100100" else
            ALUOP_OR    when is_alureg(id_opcode) and id_funct = "100101" else
            ALUOP_XOR   when is_alureg(id_opcode) and id_funct = "100110" else
            ALUOP_NOR   when is_alureg(id_opcode) and id_funct = "100111" else
            ALUOP_SLT   when is_alureg(id_opcode) and id_funct = "101010" else
            ALUOP_SLTU  when is_alureg(id_opcode) and id_funct = "101011" else
            ALUOP_ADD   when is_aluimm(id_opcode) and id_opcode= "001000" else
            ALUOP_ADDU  when is_aluimm(id_opcode) and id_opcode= "001001" else
            ALUOP_SLT   when is_aluimm(id_opcode) and id_opcode= "001010" else
            ALUOP_SLTU  when is_aluimm(id_opcode) and id_opcode= "001011" else
            ALUOP_AND   when is_aluimm(id_opcode) and id_opcode= "001100" else
            ALUOP_OR    when is_aluimm(id_opcode) and id_opcode= "001101" else
            ALUOP_XOR   when is_aluimm(id_opcode) and id_opcode= "001110" else
            ALUOP_LUI   when is_aluimm(id_opcode) and id_opcode= "001111" else
            ALUOP_CPYPC when is_jmp(id_opcode)                            else
            ALUOP_ADD   when is_memload(id_opcode)                        else
            ALUOP_ADD   when is_memstore(id_opcode)                       else
            ALUOP_ADD   when id_is_mfc0='1'                               else
            ALUOP_ADD   when id_is_mtc0='1'                               else
            ALUOP_NOP;
id_memop <= "00000" & id_opcode(2 downto 0);

-- hazard detection unit
id_stall <= '1' when
    -- LW followed immediately by instruction that needs its value
    (ex_ctrlsig(MEM_READ) = '1' and ex_rk /= "00000" and
     ((ex_rk=id_rs) or ((ex_rk=id_rt) and (id_ctrlsig_in(MEM_READ)='0')))) or
    -- branch/jmpreg instruction that needs values in EX and MEM stages
    (id_ctrlsig_in(BRANCH) = '1' and (NOT is_jmp(id_opcode)) and
     ((ex_ctrlsig(REG_WRITE) = '1' and ex_rk /= "00000" and
       (ex_rk = id_rs or (id_opcode /= "000001" and ex_rk = id_rt))) or
      (mem_ctrlsig(REG_WRITE) = '1' and mem_rk /= "00000" and
          (mem_rk = id_rs or (id_opcode /= "000001" and mem_rk = id_rt))))) or
    -- mtc0 instruction that needs values in EX and MEM stages
    (id_is_mtc0 = '1' and (
     (ex_ctrlsig(REG_WRITE) ='1' and ex_rk /="00000" and ex_rk =id_rt) or
     (mem_ctrlsig(REG_WRITE)='1' and mem_rk/="00000" and mem_rk=id_rt))) or
    -- mfc0/mtc0 need to introduce 3 bubbles in the pipeline
    ((id_is_mfc0='1' or id_is_mtc0='1' or id_is_rfe='1') and
     (ex_instr /= x"00000000" or mem_instr /= x"00000000" or
      wb_instr /= x"00000000"))
    -- any other case shouldn't need a stall
    else '0';
id_ifclk <= NOT id_stall;
id_pcclk <= NOT id_stall;

-- control signals mux
with id_stall select id_ctrlsig <= id_ctrlsig_in when '0', x"00" when others;

-- pc source selection
id_pc_src <=
  PCSRC_JR     when id_is_jr   ='1'                                        else
  PCSRC_JR     when id_is_jalr ='1'                                        else
  PCSRC_BRANCH when id_is_bltz ='1' and (id_is_lez='1' and id_is_zero='0') else
  PCSRC_BRANCH when id_is_bgez ='1' and (id_is_gtz='1' or  id_is_zero='1') else
  PCSRC_BRANCH when id_is_blzal='1' and (id_is_lez='1' and id_is_zero='0') else
  PCSRC_BRANCH when id_is_bgzal='1' and (id_is_gtz='1' or  id_is_zero='1') else
  PCSRC_JMP    when id_is_j    ='1'                                        else
  PCSRC_JMP    when id_is_jal  ='1'                                        else
  PCSRC_BRANCH when id_is_beq  ='1' and id_is_equal='1'                    else
  PCSRC_BRANCH when id_is_bne  ='1' and id_is_equal='0'                    else
  PCSRC_BRANCH when id_is_blez ='1' and id_is_lez  ='1'                    else
  PCSRC_BRANCH when id_is_bgtz ='1' and id_is_gtz  ='1'                    else
  PCSRC_PC4;

--------------------------------------------------------------------------------
--                               EX STAGE                                     --
--------------------------------------------------------------------------------

-- register transfer
process(CLK)
begin
    if (CLK = '1' and CLK'event and iSTALL = '0') then
        if (ex_exception='1') then
            -- don't move
        elsif (id_exception='1' or id_ifclk = '0') then
            -- introduce a bubble in EX
            ex_instr     <= x"00000000";
            ex_pc4       <= x"00000000";
            ex_rs        <= "00000";
            ex_rt        <= "00000";
            ex_rd        <= "00000";
            ex_shamt     <= "00000";
            ex_aluop     <= x"00";
            ex_memop     <= x"00";
            ex_ctrlsig   <= x"00";
            ex_val_of_rs <= x"00000000";
            ex_val_of_rt <= x"00000000";
            ex_imm32     <= x"00000000";
            ex_is_mfc0   <= '0';
            ex_is_mtc0   <= '0';
        else
            -- normal operation
            ex_instr     <= id_instr;
            ex_pc4       <= id_pc4;
            ex_rs        <= id_rs;
            ex_rt        <= id_rt;
            ex_rd        <= id_rd;
            ex_shamt     <= id_shamt;
            ex_aluop     <= id_aluop;
            ex_memop     <= id_memop;
            ex_ctrlsig   <= id_ctrlsig;
            ex_val_of_rs <= id_val_of_rs;
            ex_val_of_rt <= id_val_of_rt;
            ex_imm32     <= id_imm32;
            ex_is_mfc0   <= id_is_mfc0;
            ex_is_mtc0   <= id_is_mtc0;
        end if;
    end if;
end process;

-- forwarding unit
ex_fu_mux1 <= "10" when (mem_ctrlsig(REG_WRITE) = '1' and
                         mem_rk /= "00000" and
                         mem_rk = ex_rs) else
              "01" when (wb_ctrlsig(REG_WRITE) = '1' and
                         wb_rk /= "00000" and
                         wb_rk = ex_rs) else
              "00";

ex_fu_mux2 <= "10" when (mem_ctrlsig(REG_WRITE) = '1' and
                         mem_rk /= "00000" and
                         mem_rk = ex_rt) else
              "01" when (wb_ctrlsig(REG_WRITE) = '1' and
                         wb_rk /= "00000" and
                         wb_rk = ex_rt) else
              "00";

-- MUX components
with ex_fu_mux1
    select ex_muxop1     <= ex_val_of_rs                    when "00",
                            wb_value_of_rk                  when "01",
                            mem_addr                        when "10",
                            x"00000000"                     when others;
with ex_fu_mux2
    select ex_muxop2     <= ex_val_of_rt                    when "00",
                            wb_value_of_rk                  when "01",
                            mem_addr                        when "10",
                            x"00000000"                     when others;
with ex_aluop
    select ex_alu1       <= x"00000010"                     when ALUOP_LUI,
                            x"000000" & "000" & ex_shamt    when ALUOP_SLL,
                            x"000000" & "000" & ex_shamt    when ALUOP_SRL,
                            x"000000" & "000" & ex_shamt    when ALUOP_SRA,
                            ex_muxop1                       when others;
with ex_ctrlsig(ALU_SRC)
    select ex_alu2       <= ex_muxop2                       when '0',
                            ex_imm32                        when others;
with ex_ctrlsig(REG_DEST)
    select ex_rk         <= ex_rt                           when '0',
                            ex_rd                           when others;

-- ALU
with ex_aluop
    select ex_alu_output <= alu_cpy(ex_alu1, ex_alu2)       when ALUOP_CPYPC,
                            alu_sll(ex_alu1, ex_alu2)       when ALUOP_LUI,
                            alu_add(ex_alu1, ex_alu2)       when ALUOP_ADD,
                            alu_add(ex_alu1, ex_alu2)       when ALUOP_ADDU,
                            alu_sub(ex_alu1, ex_alu2)       when ALUOP_SUB,
                            alu_sub(ex_alu1, ex_alu2)       when ALUOP_SUBU,
                            alu_and(ex_alu1, ex_alu2)       when ALUOP_AND,
                            alu_ior(ex_alu1, ex_alu2)       when ALUOP_OR,
                            alu_xor(ex_alu1, ex_alu2)       when ALUOP_XOR,
                            alu_nor(ex_alu1, ex_alu2)       when ALUOP_NOR,
                            alu_lts(ex_alu1, ex_alu2)       when ALUOP_SLT,
                            alu_ltu(ex_alu1, ex_alu2)       when ALUOP_SLTU,
                            alu_sll(ex_alu1, ex_alu2)       when ALUOP_SLL,
                            alu_srl(ex_alu1, ex_alu2)       when ALUOP_SRL,
                            alu_sra(ex_alu1, ex_alu2)       when ALUOP_SRA,
                            alu_sll(ex_alu1, ex_alu2)       when ALUOP_SLLV,
                            alu_srl(ex_alu1, ex_alu2)       when ALUOP_SRLV,
                            alu_sra(ex_alu1, ex_alu2)       when ALUOP_SRAV,
                            ex_hi                           when ALUOP_MFHI,
                            ex_lo                           when ALUOP_MFLO,
                            x"00000000"                     when others;

process(CLK)

variable N : unsigned(31 downto 0);
variable D : unsigned(31 downto 0);
variable Q : unsigned(31 downto 0);
variable R : unsigned(31 downto 0);

begin

    if (CLK = '0' and CLK'event ) then

        if (ex_busy = 0) then

            if (ex_aluop = ALUOP_MULT  or
                ex_aluop = ALUOP_MULTU or
                ex_aluop = ALUOP_DIV   or
                ex_aluop = ALUOP_DIVU) then
                -- start multiplication/division FSM
                ex_op1    <= ex_alu1;
                ex_op2    <= ex_alu2;
                ex_mulres <= x"0000000000000000";
                N := unsigned(ex_alu1);
                D := unsigned(ex_alu2);
                Q := x"00000000";
                R := x"00000000";
                ex_busy   <= 1;
            elsif (ex_aluop = ALUOP_MTLO) then
                ex_lo <= ex_alu1;
            elsif (ex_aluop = ALUOP_MTHI) then
                ex_hi <= ex_alu1;
            end if;
            ex_phase <= 0;

        elsif (ex_aluop = ALUOP_MULT or ex_aluop = ALUOP_MULTU) then

            -- multiplication
            if (ex_phase = 0) then
                if (ex_aluop = ALUOP_MULT) then
                    ex_mulres <= alu_mul(ex_op1, ex_op2);
                else
                    ex_mulres <= alu_mulu(ex_op1, ex_op2);
                end if;
            elsif (ex_phase = 1) then
                ex_lo   <= ex_mulres(31 downto 0);
                ex_hi   <= ex_mulres(63 downto 32);
                ex_busy <= 0;
            end if;
            ex_phase  <= ex_phase + 1;

        elsif (ex_aluop = ALUOP_DIV or ex_aluop = ALUOP_DIVU) then

            -- division
            if (ex_phase < 32) then
                R := R(30 downto 0) & N(31-ex_phase);
                if R >= D then
                    R := R - D;
                    Q(31-ex_phase) := '1';
                end if;
            elsif (ex_phase = 32) then
                ex_lo   <= std_logic_vector(Q);
                ex_hi   <= std_logic_vector(R);
                ex_busy <= 0;
            end if;
            ex_phase  <= ex_phase + 1;

        end if;

    end if;
end process;

--------------------------------------------------------------------------------
--                               MEM STAGE                                    --
--------------------------------------------------------------------------------

-- register transfer
process(CLK)
begin
    if ( CLK = '1' and CLK'event ) then
        if (iSTALL = '0') then
            if (mem_exception='1') then
                -- don't move
            elsif (ex_exception='1') then
                -- introduce a bubble in MEM
                mem_instr     <= x"00000000";
                mem_pc4       <= x"00000000";
                mem_memop     <= x"00";
                mem_ctrlsig   <= x"00";
                mem_addr      <= x"00000000";
                mem_data_in   <= x"00000000";
                mem_rk        <= "00000";
                mem_is_mfc0   <= '0';
                mem_is_mtc0   <= '0';
            else
                -- normal operation
                mem_instr     <= ex_instr;
                mem_pc4       <= ex_pc4;
                mem_memop     <= ex_memop;
                mem_ctrlsig   <= ex_ctrlsig;
                mem_rk        <= ex_rk;
                mem_is_mfc0   <= ex_is_mfc0;
                mem_is_mtc0   <= ex_is_mtc0;
                if (ex_ctrlsig(MEM_READ)='1' OR
                    ex_ctrlsig(MEM_WRITE)='1') then
                    if (ex_memop = MEMOP_LEFT) then
                        -- first cycle
                        mem_busy    <= true;
                        mem_addr    <= ex_alu_output(31 downto 2) & "00";
                        mem_phase   <= conv_integer(ex_alu_output(1 downto 0));
                        mem_tmp     <= ex_muxop2;
                        mem_tmp2    <= ex_muxop2;
                        if (ex_alu_output(1 downto 0) = "00") then
                            mem_data_in <= x"000000" & ex_muxop2(31 downto 24);
                        elsif (ex_alu_output(1 downto 0) = "01") then
                            mem_data_in <= x"000000" & ex_muxop2(23 downto 16);
                        elsif (ex_alu_output(1 downto 0) = "10") then
                            mem_data_in <= x"000000" & ex_muxop2(15 downto  8);
                        else
                            mem_data_in <= x"000000" & ex_muxop2( 7 downto  0);
                        end if;
                    elsif (ex_memop = MEMOP_RIGHT) then
                        mem_busy    <= true;
                        mem_addr    <= ex_alu_output(31 downto 2) & "11";
                        mem_phase   <= conv_integer(ex_alu_output(1 downto 0));
                        mem_tmp     <= ex_muxop2;
                        mem_tmp2    <= ex_muxop2;
                        if (ex_alu_output(1 downto 0) = "00") then
                            mem_data_in <= x"000000" & ex_muxop2(31 downto 24);
                        elsif (ex_alu_output(1 downto 0) = "01") then
                            mem_data_in <= x"000000" & ex_muxop2(23 downto 16);
                        elsif (ex_alu_output(1 downto 0) = "10") then
                            mem_data_in <= x"000000" & ex_muxop2(15 downto  8);
                        else
                            mem_data_in <= x"000000" & ex_muxop2( 7 downto  0);
                        end if;
                    else
                        -- normal load/store instruction
                        mem_busy    <= false;
                        mem_addr    <= ex_alu_output;
                        mem_data_in <= ex_muxop2;
                    end if;
                else
                    mem_busy    <= false;
                    mem_addr    <= ex_alu_output;
                    mem_data_in <= ex_muxop2;
                end if;
            end if;
        elsif (STALL='0') then
            -- new cache cycle
            if (mem_busy) then
                -- lwl, lwr, swl, swr...
                if (mem_phase = 0) then
                    mem_tmp(31 downto 24) <= dDin(7 downto 0);
                elsif (mem_phase = 1) then
                    mem_tmp(23 downto 16) <= dDin(7 downto 0);
                elsif (mem_phase = 2) then
                    mem_tmp(15 downto  8) <= dDin(7 downto 0);
                elsif (mem_phase = 3) then
                    mem_tmp( 7 downto  0) <= dDin(7 downto 0);
                end if;
                -- update address and phase
                if (mem_memop = MEMOP_LEFT) then
                    if (mem_phase = 1) then
                        -- next phase = 0
                        mem_data_in <= x"000000" & mem_tmp2(31 downto 24);
                    elsif (mem_phase = 2) then
                        -- next phase = 1
                        mem_data_in <= x"000000" & mem_tmp2(23 downto 16);
                    elsif (mem_phase = 3) then
                        -- next phase = 2
                        mem_data_in <= x"000000" & mem_tmp2(15 downto  8);
                    end if;
                    if (mem_phase = 0) then
                        -- done
                        mem_busy <= false;
                    else
                        -- next step
                        mem_addr  <= alu_add(mem_addr, x"00000001");
                        mem_phase <= mem_phase - 1;
                    end if;
                elsif (mem_memop = MEMOP_RIGHT) then
                    if (mem_phase = 0) then
                        -- next phase = 1
                        mem_data_in <= x"000000" & mem_tmp2(23 downto 16);
                    elsif (mem_phase = 1) then
                        -- next phase = 2
                        mem_data_in <= x"000000" & mem_tmp2(15 downto  8);
                    elsif (mem_phase = 2) then
                        -- next phase = 3
                        mem_data_in <= x"000000" & mem_tmp2( 7 downto  0);
                    end if;
                    if (mem_phase = 3) then
                        -- done
                        mem_busy <= false;
                    else
                        -- next step
                        mem_addr  <= alu_sub(mem_addr, x"00000001");
                        mem_phase <= mem_phase + 1;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

-- interfacing dMEM component
dMEME        <= mem_ctrlsig(MEM_READ) OR mem_ctrlsig(MEM_WRITE);
dRW          <= mem_ctrlsig(MEM_WRITE);
dADDR        <= mem_addr(31 downto 0) ;
dDout        <= mem_data_in;

-- specify type
dDTYPE(0)    <= '1' when (mem_memop = MEMOP_BYTE or
                          mem_memop = MEMOP_BYTEU or
                          mem_memop = MEMOP_LEFT or
                          mem_memop = MEMOP_RIGHT) else '0';
dDTYPE(1)    <= '1' when (mem_memop = MEMOP_HALF or
                          mem_memop = MEMOP_HALFU) else '0';
dDTYPE(2)    <= '1' when (mem_memop = MEMOP_WORD) else '0';

-- sign extension for memory data
mem_data_out <= signext1(dDin( 7 downto 0)) when mem_memop = MEMOP_BYTE  else
                unsiext1(dDin( 7 downto 0)) when mem_memop = MEMOP_BYTEU else
                signext2(dDin(15 downto 0)) when mem_memop = MEMOP_HALF  else
                unsiext2(dDin(15 downto 0)) when mem_memop = MEMOP_HALFU else
                         dDin(31 downto 0)  when mem_memop = MEMOP_WORD  else
                         mem_tmp            when mem_memop = MEMOP_LEFT  else
                         mem_tmp            when mem_memop = MEMOP_RIGHT;

--------------------------------------------------------------------------------
--                               WB STAGE                                     --
--------------------------------------------------------------------------------

-- register transfer
process(CLK)
begin
    if ( CLK = '1' and CLK'event and iSTALL = '0') then
        if (mem_exception='1') then
            -- introduce a bubble in WB
            wb_instr     <= x"00000000";
            wb_pc4       <= x"00000000";
            wb_ctrlsig   <= x"00";
            wb_mem_out   <= x"00000000";
            wb_alu_out   <= x"00000000";
            wb_rk        <= "00000";
            wb_is_mfc0   <= '0';
            wb_is_mtc0   <= '0';
        else
            -- normal operation
            wb_instr     <= mem_instr;
            wb_pc4       <= mem_pc4;
            wb_ctrlsig   <= mem_ctrlsig;
            wb_mem_out   <= mem_data_out;
            wb_alu_out   <= mem_addr;
            wb_rk        <= mem_rk;
            wb_is_mfc0   <= mem_is_mfc0;
            wb_is_mtc0   <= mem_is_mtc0;
        end if;
    end if;
end process;

-- the mux
wb_value_of_rk <= wb_mem_out when wb_ctrlsig(MEM_TO_REG) = '1'
                             else wb_alu_out;

end Behavioral;
