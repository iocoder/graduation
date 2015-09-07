library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.cpu_pkg.all;

entity pipeline is
    Port (
        CLK    : in  STD_LOGIC;
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
type     regfile_t is array (0 to 31) of STD_LOGIC_VECTOR (31 downto 0);

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

-- IF
signal   if_pc          : STD_LOGIC_VECTOR (31 downto 0) := x"FFFFFFFC";
signal   if_pc4         : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   if_instr       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";

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
signal   id_pc4         : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_imm32       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_shl         : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_val_of_rs   : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_val_of_rt   : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_braddr      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_jmpaddr     : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_jraddr      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   id_is_equal    : STD_LOGIC := '0';
signal   id_is_zero     : STD_LOGIC := '0';
signal   id_is_lez      : STD_LOGIC := '0';
signal   id_is_gtz      : STD_LOGIC := '0';
signal   id_pc_src      : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   id_if_flush    : STD_LOGIC := '0';
signal   id_ctrlsig_in  : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   id_aluop       : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   id_memop       : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   id_ctrlsig     : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   id_stall       : STD_LOGIC := '0';
signal   id_ifclk       : STD_LOGIC := '1';
signal   id_pcclk       : STD_LOGIC := '1';
signal   id_regfile     : regfile_t := (others => x"00000000");

-- EX
signal   ex_hi          : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   ex_lo          : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
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

-- MEM
signal   mem_instr      : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_pc4        : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_memop      : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   mem_ctrlsig    : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   mem_addr       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_data_in    : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_data_out   : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   mem_rk         : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";

-- WB
signal   wb_instr       : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   wb_pc4         : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   wb_ctrlsig     : STD_LOGIC_VECTOR ( 7 downto 0) := x"00";
signal   wb_mem_out     : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   wb_alu_out     : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   wb_value_of_rk : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
signal   wb_rk          : STD_LOGIC_VECTOR ( 4 downto 0) := "00000";

begin

--------------------------------------------------------------------------------
--                               IF STAGE                                     --
--------------------------------------------------------------------------------

-- register transfer
process(CLK)
begin
    if ( CLK = '1' and CLK'event ) then
        if (id_pcclk = '1') then
            if (id_pc_src = PCSRC_PC4) then
                if_pc <= if_pc4;
            elsif (id_pc_src = PCSRC_BRANCH) then
                if_pc <= id_braddr;
            elsif (id_pc_src = PCSRC_JMP) then
                if_pc <= id_jmpaddr;
            elsif (id_pc_src = PCSRC_JR) then
                if_pc <= id_jraddr;
            end if;
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
begin
    if ( CLK = '1' and CLK'event ) then
        if (id_ifclk = '1') then
            id_instr <= if_instr;
            id_pc4   <= if_pc4;
        end if;
    end if;
end process;

-- register file operation
process(CLK)
begin
    if ( CLK = '0' and CLK'event ) then
        if (wb_ctrlsig(REG_WRITE) = '1' and wb_rk /= x"00") then
            id_regfile(conv_integer(wb_rk)) <= wb_value_of_rk;
            if (wb_rk = id_rs) then
                id_val_of_rs <= wb_value_of_rk;
            else
                id_val_of_rs <= id_regfile(conv_integer(id_rs));
            end if;
            if (wb_rk = id_rt) then
                id_val_of_rt <= wb_value_of_rk;
            else
                id_val_of_rt <= id_regfile(conv_integer(id_rt));
            end if;
        else
            id_val_of_rs <= id_regfile(conv_integer(id_rs));
            id_val_of_rt <= id_regfile(conv_integer(id_rt));
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

-- generate control signals
id_ctrlsig_in(REG_DEST) <=
    '1'                                 when is_alureg      (id_opcode) else
    '1'                                 when is_branchregimm(id_opcode) else
    '1'                                 when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '0'                                 when is_aluimm      (id_opcode) else
    '0'                                 when is_memload     (id_opcode) else
    '0'                                 when is_memstore    (id_opcode) else
    '0';
id_ctrlsig_in(ALU_SRC) <=
    id_is_jr or id_is_jalr              when is_alureg      (id_opcode) else
    '1'                                 when is_branchregimm(id_opcode) else
    '1'                                 when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '1'                                 when is_aluimm      (id_opcode) else
    '1'                                 when is_memload     (id_opcode) else
    '1'                                 when is_memstore    (id_opcode) else
    '0';
id_ctrlsig_in(MEM_TO_REG) <=
    '0'                                 when is_alureg      (id_opcode) else
    '0'                                 when is_branchregimm(id_opcode) else
    '0'                                 when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '0'                                 when is_aluimm      (id_opcode) else
    '1'                                 when is_memload     (id_opcode) else
    '0'                                 when is_memstore    (id_opcode) else
    '0';
id_ctrlsig_in(REG_WRITE) <=
    '1'                                 when is_alureg      (id_opcode) else
    id_is_blzal or id_is_bgzal          when is_branchregimm(id_opcode) else
    id_is_jal                           when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '1'                                 when is_aluimm      (id_opcode) else
    '1'                                 when is_memload     (id_opcode) else
    '0'                                 when is_memstore    (id_opcode) else
    '0';
id_ctrlsig_in(MEM_READ) <=
    '0'                                 when is_alureg      (id_opcode) else
    '0'                                 when is_branchregimm(id_opcode) else
    '0'                                 when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '0'                                 when is_aluimm      (id_opcode) else
    '1'                                 when is_memload     (id_opcode) else
    '0'                                 when is_memstore    (id_opcode) else
    '0';
id_ctrlsig_in(MEM_WRITE) <=
    '0'                                 when is_alureg      (id_opcode) else
    '0'                                 when is_branchregimm(id_opcode) else
    '0'                                 when is_jmp         (id_opcode) else
    '0'                                 when is_branch      (id_opcode) else
    '0'                                 when is_aluimm      (id_opcode) else
    '0'                                 when is_memload     (id_opcode) else
    '1'                                 when is_memstore    (id_opcode) else
    '0';
id_ctrlsig_in(BRANCH) <=
    id_is_jr or id_is_jalr              when is_alureg      (id_opcode) else
    '1'                                 when is_branchregimm(id_opcode) else
    '1'                                 when is_jmp         (id_opcode) else
    '1'                                 when is_branch      (id_opcode) else
    '0'                                 when is_aluimm      (id_opcode) else
    '0'                                 when is_memload     (id_opcode) else
    '0'                                 when is_memstore    (id_opcode) else
    '0';

-- decoding
id_aluop <= ALUOP_SLL   when is_alureg(id_opcode) and id_funct = x"00" else
            ALUOP_SRL   when is_alureg(id_opcode) and id_funct = x"02" else
            ALUOP_SRA   when is_alureg(id_opcode) and id_funct = x"03" else
            ALUOP_SLLV  when is_alureg(id_opcode) and id_funct = x"04" else
            ALUOP_SRLV  when is_alureg(id_opcode) and id_funct = x"06" else
            ALUOP_SRAV  when is_alureg(id_opcode) and id_funct = x"07" else
            ALUOP_CPYPC when is_alureg(id_opcode) and id_funct = x"08" else
            ALUOP_CPYPC when is_alureg(id_opcode) and id_funct = x"09" else
            ALUOP_EXP   when is_alureg(id_opcode) and id_funct = x"0C" else
            ALUOP_EXP   when is_alureg(id_opcode) and id_funct = x"0D" else
            ALUOP_MFHI  when is_alureg(id_opcode) and id_funct = x"10" else
            ALUOP_MTHI  when is_alureg(id_opcode) and id_funct = x"11" else
            ALUOP_MFLO  when is_alureg(id_opcode) and id_funct = x"12" else
            ALUOP_MTLO  when is_alureg(id_opcode) and id_funct = x"13" else
            ALUOP_MULT  when is_alureg(id_opcode) and id_funct = x"18" else
            ALUOP_MULTU when is_alureg(id_opcode) and id_funct = x"19" else
            ALUOP_DIV   when is_alureg(id_opcode) and id_funct = x"1A" else
            ALUOP_DIVU  when is_alureg(id_opcode) and id_funct = x"1B" else
            ALUOP_ADD   when is_alureg(id_opcode) and id_funct = x"20" else
            ALUOP_ADDU  when is_alureg(id_opcode) and id_funct = x"21" else
            ALUOP_SUB   when is_alureg(id_opcode) and id_funct = x"22" else
            ALUOP_SUBU  when is_alureg(id_opcode) and id_funct = x"23" else
            ALUOP_AND   when is_alureg(id_opcode) and id_funct = x"24" else
            ALUOP_OR    when is_alureg(id_opcode) and id_funct = x"25" else
            ALUOP_XOR   when is_alureg(id_opcode) and id_funct = x"26" else
            ALUOP_NOR   when is_alureg(id_opcode) and id_funct = x"27" else
            ALUOP_SLT   when is_alureg(id_opcode) and id_funct = x"2A" else
            ALUOP_SLTU  when is_alureg(id_opcode) and id_funct = x"2B" else
            ALUOP_ADD   when is_aluimm(id_opcode) and id_opcode= x"08" else
            ALUOP_ADDU  when is_aluimm(id_opcode) and id_opcode= x"09" else
            ALUOP_SLT   when is_aluimm(id_opcode) and id_opcode= x"0A" else
            ALUOP_SLTU  when is_aluimm(id_opcode) and id_opcode= x"0B" else
            ALUOP_AND   when is_aluimm(id_opcode) and id_opcode= x"0C" else
            ALUOP_OR    when is_aluimm(id_opcode) and id_opcode= x"0D" else
            ALUOP_XOR   when is_aluimm(id_opcode) and id_opcode= x"0E" else
            ALUOP_LUI   when is_aluimm(id_opcode) and id_opcode= x"0F" else
            ALUOP_CPYPC when is_jmp(id_opcode)                         else
            ALUOP_ADD   when is_memload(id_opcode)                     else
            ALUOP_ADD   when is_memstore(id_opcode)                    else
            ALUOP_NOP;
id_memop <= "00000" & id_opcode(2 downto 0);

-- hazard detection unit
id_stall <= '1' when
    -- LW followed immediately by instruction that needs its value
    (ex_ctrlsig(MEM_READ) = '1' and ex_rk /= x"00" and
     ((ex_rk=id_rs) or ((ex_rk=id_rt) and (id_ctrlsig_in(MEM_READ)='0')))) or
    -- branch/jmp instruction that needs values in EX and MEM stages
    (id_ctrlsig_in(BRANCH) = '1' and
     ((ex_ctrlsig(REG_WRITE) = '1' and ex_rk /= x"00" and
       (ex_rk = id_rs or (id_opcode /= x"01" and ex_rk = id_rt))) or
      (mem_ctrlsig(REG_WRITE) = '1' and mem_rk /= x"00" and
          (mem_rk = id_rs or (id_opcode /= x"01" and mem_rk = id_rt)))))
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
    if ( CLK = '1' and CLK'event ) then
        if (id_ifclk = '0') then
            -- introduce bubble
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
        else
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
                            x"00000000"                     when others;

-- TODO: multiplication and division

-- TODO: move from/to LO/HI regs

--------------------------------------------------------------------------------
--                               MEM STAGE                                    --
--------------------------------------------------------------------------------

-- register transfer
process(CLK)
begin
    if ( CLK = '1' and CLK'event ) then
        mem_instr   <= ex_instr;
        mem_pc4     <= ex_pc4;
        mem_memop   <= ex_memop;
        mem_ctrlsig <= ex_ctrlsig;
        mem_addr    <= ex_alu_output;
        mem_data_in <= ex_muxop2;
        mem_rk      <= ex_rk;
    end if;
end process;

-- interfacing dMEM component
dMEME        <= mem_ctrlsig(MEM_READ) OR mem_ctrlsig(MEM_WRITE);
dRW          <= mem_ctrlsig(MEM_WRITE);
dADDR        <= mem_addr(31 downto 0);
dDout        <= mem_data_in;

-- specify type
dDTYPE(0)    <= '1' when (mem_memop = MEMOP_BYTE or
                          mem_memop = MEMOP_BYTEU) else '0';
dDTYPE(1)    <= '1' when (mem_memop = MEMOP_HALF or
                          mem_memop = MEMOP_HALFU) else '0';
dDTYPE(2)    <= '1' when (mem_memop = MEMOP_WORD) else '0';

-- sign extension for memory data
mem_data_out( 7 downto 0) <= dDin( 7 downto 0);
mem_data_out <= signext1(dDin( 7 downto 0)) when mem_memop = MEMOP_BYTE  else
                unsiext1(dDin( 7 downto 0)) when mem_memop = MEMOP_BYTEU else
                signext2(dDin(15 downto 0)) when mem_memop = MEMOP_HALF  else
                unsiext2(dDin(15 downto 0)) when mem_memop = MEMOP_HALFU else
                         dDin(31 downto 0)  when mem_memop = MEMOP_WORD;

--------------------------------------------------------------------------------
--                               WB STAGE                                     --
--------------------------------------------------------------------------------

-- register transfer
process(CLK)
begin
    if ( CLK = '1' and CLK'event ) then
        wb_instr   <= mem_instr;
        wb_pc4     <= mem_pc4;
        wb_ctrlsig <= mem_ctrlsig;
        wb_mem_out <= mem_data_out;
        wb_alu_out <= mem_addr;
        wb_rk      <= mem_rk;
    end if;
end process;

-- the mux
wb_value_of_rk <= wb_mem_out when wb_ctrlsig(MEM_TO_REG) = '1'
                             else wb_alu_out;

end Behavioral;
