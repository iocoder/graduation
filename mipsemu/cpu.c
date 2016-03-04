#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cpu.h"
#include "mem.h"
#include "pic.h"

/* control signals */
#define REG_DEST    0
#define ALU_SRC     1
#define MEM_TO_REG  2
#define REG_WRITE   3
#define MEM_READ    4
#define MEM_WRITE   5
#define BRANCH      6
#define CTRL_COUNT  7

/* formats */
#define R_FORMAT        0
#define I_FORMAT        1
#define J_FORMAT        2

/* ALU operations */
#define ALUOP_NOP       0x00
#define ALUOP_EXP       0x01
#define ALUOP_CPYPC     0x02
#define ALUOP_LUI       0x03
#define ALUOP_MFHI      0x10
#define ALUOP_MTHI      0x11
#define ALUOP_MFLO      0x12
#define ALUOP_MTLO      0x13
#define ALUOP_MULT      0x14
#define ALUOP_MULTU     0x15
#define ALUOP_DIV       0x16
#define ALUOP_DIVU      0x17
#define ALUOP_ADD       0x20
#define ALUOP_ADDU      0x21
#define ALUOP_SUB       0x22
#define ALUOP_SUBU      0x23
#define ALUOP_AND       0x24
#define ALUOP_OR        0x25
#define ALUOP_XOR       0x26
#define ALUOP_NOR       0x27
#define ALUOP_SLT       0x2A
#define ALUOP_SLTU      0x2B
#define ALUOP_SLL       0x30
#define ALUOP_SRL       0x32
#define ALUOP_SRA       0x33
#define ALUOP_SLLV      0x34
#define ALUOP_SRLV      0x36
#define ALUOP_SRAV      0x37

/* memory operations */
#define MEMOP_BYTE      0x00
#define MEMOP_HALF      0x01
#define MEMOP_LEFT      0x02
#define MEMOP_WORD      0x03
#define MEMOP_BYTEU     0x04
#define MEMOP_HALFU     0x05
#define MEMOP_RIGHT     0x06

/* PC source */
#define PCSRC_PC4       0x00
#define PCSRC_BRANCH    0x01
#define PCSRC_JMP       0x02
#define PCSRC_JR        0x03
#define PCSRC_EXP       0x04

/* cache parameters */
#define CACHE_LINES     1024
#define OFFSET_BITS     2
#define INDEX_BITS      10
#define INDEX_LOW       2
#define INDEX_HIGH      11
#define TAG_BITS        20
#define TAG_LOW         12
#define TAG_HIGH        31

/* halt */
int halted;

/* external signals */
int nmi_pulse;

/* progress info */
int cur_step;

/* IF */
int if_pc;
int if_pc4;
int if_instr;
int if_exphndl;
int if_exception;

/* ID */
int id_instr;
int id_opcode;
int id_rs;
int id_rt;
int id_rd;
int id_ropcode;
int id_shamt;
int id_funct;
int id_is_jr;
int id_is_jalr;
int id_pc;
int id_pc4;
int id_imm32;
int id_shl;
int id_val_of_rs;
int id_val_of_rt;
int id_cop0_regrd;
int id_braddr;
int id_jmpaddr;
int id_jraddr;
int id_is_equal;
int id_is_zero;
int id_is_lez;
int id_is_gtz;
int id_is_mfc0;
int id_is_mtc0;
int id_is_rfe;
int id_is_cop0;
int id_pc_src;
int id_if_flush;
int id_ctrlsig_in[CTRL_COUNT]; /* ctl unit output */
int id_aluop;
int id_memop;
int id_ctrlsig[CTRL_COUNT]; /* ctl mux output */
int id_stall; /* hazard outputs */
int id_ifclk; /* hazard outputs */
int id_pcclk; /* hazard outputs */
int id_exception;
int id_regfile[32];

/* EX */
long long ex_tmp;
int ex_hi;
int ex_lo;
int ex_instr;
int ex_rs;
int ex_rt;
int ex_rd;
int ex_shamt;
int ex_pc4;
int ex_aluop;
int ex_memop;
int ex_ctrlsig[CTRL_COUNT];
int ex_val_of_rs;
int ex_val_of_rt;
int ex_imm32;
int ex_fu_mux1 = 0; /* forwarding unit selector for mux1 */
int ex_fu_mux2 = 0; /* forwarding unit selector for mux2 */
int ex_alu1; /* input 1 for ALU (output of first forwarding mux) */
int ex_muxop; /* output of second forwarding mux */
int ex_alu2; /* input 2 for ALU (muxop or imm?) */
int ex_alu_output; /* output of ALU */
int ex_rk; /* output of forth mux */
int ex_is_mfc0;
int ex_is_mtc0;
int ex_exception;

/* MEM */
int mem_instr;
int mem_pc4;
int mem_memop;
int mem_ctrlsig[CTRL_COUNT];
int mem_tmp;
int mem_addr;
int mem_data_in;
int mem_data_out;
int mem_rk;
int mem_is_mfc0;
int mem_is_mtc0;
int mem_exception;
int mem_array[4096];

/* WB */
int wb_instr;
int wb_pc4;
int wb_ctrlsig[CTRL_COUNT];
int wb_mem_out;
int wb_alu_out;
int wb_value_of_rk;
int wb_rk;
int wb_is_mfc0;
int wb_is_mtc0;
int wb_exception;

/* coprocessor */
int SR;
int CAUSE;
int EPC;
int irq;

/* caches */
unsigned int icache_v   [CACHE_LINES] = {0};
unsigned int icache_data[CACHE_LINES] = {0};
unsigned int icache_tag [CACHE_LINES] = {0};
unsigned int dcache_v   [CACHE_LINES] = {0};
unsigned int dcache_data[CACHE_LINES] = {0};
unsigned int dcache_tag [CACHE_LINES] = {0};

/* I-format instruction mnemonics */
const char *opcode_to_str[] = {
    "NULL ", "NULL ", "j    ", "jal  ", "beq  ", "bne  ", "blez ", "bgtz ",
    "addi ", "addiu", "slti ", "sltiu", "andi ", "ori  ", "xori ", "lui  ",
    "cop0 ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ",
    "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ",
    "lb   ", "lh   ", "lwl  ", "lw   ", "lbu  ", "lhu  ", "lwr  ", "NULL ",
    "sb   ", "sh   ", "swl  ", "sw   ", "NULL ", "NULL ", "swr  ", "NULL ",
    "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ",
    "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL "
};

/* R-format instruction mnemonics */
const char *funct_to_str[] = {
    "sll  ", "NULL ", "srl  ", "sra  ", "sllv ", "NULL ", "srlv ", "srav ",
    "jr   ", "jalr ", "NULL ", "NULL ", "syscl", "brk  ", "NULL ", "NULL ",
    "mfhi ", "mthi ", "mflo ", "mtlo ", "NULL ", "NULL ", "NULL ", "NULL ",
    "mult ", "multu", "div  ", "divu ", "NULL ", "NULL ", "NULL ", "NULL ",
    "add  ", "addu ", "sub  ", "subu ", "and  ", "or   ", "xor  ", "nor  ",
    "NULL ", "NULL ", "slt  ", "sltu ", "NULL ", "NULL ", "NULL ", "NULL ",
    "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ",
    "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL "
};

/* regimm instruction mnemonics */
const char *regimm_to_str[] = {
    "bltz ", "bgez ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ",
    "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ",
    "blzal", "bgzal", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ",
    "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL ", "NULL "
};

/* register names: */
const char *regn[32] = {
    /* zr = zero
     * at = assembler temporary
     * v  = values for function results and expr evaluation
     * a  = arguments
     * t  = temps
     * s  = user regs
     * k  = kernel regs
     * gp = global pointer
     * sp = stack pointer
     * fp = frame pointer
     * ra = return address
     */
    "zr", "at", "v0", "v1", "a0", "a1", "a2", "a3",
    "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7",
    "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7",
    "t8", "t9", "k0", "k1", "gp", "sp", "fp", "ra"
};

/* cache read */
unsigned int static icache_miss_count = 0;
unsigned int static icache_access_count = 0;
unsigned int static icache_stats_enable = 0;
unsigned int static dcache_miss_count = 0;
unsigned int static dcache_access_count = 0;
unsigned int static dcache_stats_enable = 0;

unsigned int cache_read(int which, unsigned int addr, unsigned int size) {
    unsigned int *cache_v    = which?dcache_v   :icache_v;
    unsigned int *cache_data = which?dcache_data:icache_data;
    unsigned int *cache_tag  = which?dcache_tag :icache_tag;
    unsigned int  offset     = (addr>>0        ) & ((1<<OFFSET_BITS)-1);
    unsigned int  index      = (addr>>INDEX_LOW) & ((1<<INDEX_BITS )-1);
    unsigned int  tag        = (addr>>TAG_LOW  ) & ((1<<TAG_BITS   )-1);
    if (!which && addr == 0x00010000) {
        //icache_stats_enable++;
        //dcache_stats_enable++;
    }
    if (!which && icache_stats_enable)
        icache_access_count++;
    if (which && dcache_stats_enable)
        dcache_access_count++;
    /* perform cache query */
    if (!cache_v[index] || cache_tag[index] != tag) {
        /* cache miss */
        if (!which && icache_stats_enable) {
            /* icache miss */
            icache_miss_count++;
            printf("icache misses: %d/%d, %d%\n", icache_miss_count,
                    icache_access_count,
                    icache_miss_count*100/icache_access_count);
        } else if (which && dcache_stats_enable) {
            /* dcache miss */
            dcache_miss_count++;
            printf("dcache misses: %d/%d, %d%\n", dcache_miss_count,
                    dcache_access_count,
                    dcache_miss_count*100/dcache_access_count);
        }
        if ((addr >> 24) == 0x1E) {
            /* uncacheable */
            return mem_read(addr, size);
        } else {
            /* cacheable */
            cache_v   [index] = 1;
            cache_data[index] = mem_read(addr - offset, 2);
            cache_tag [index] = tag;
        }
    }
    /* read result from cache */
    switch(size) {
        case 0:
            return ((unsigned char *) &cache_data[index])[offset];
        case 1:
            return ((unsigned short *) &cache_data[index])[offset/2];
        case 2:
            return cache_data[index];
    }
}

/* cache write */
void cache_write(int which, unsigned int addr, unsigned int data, int size) {
    unsigned int *cache_v    = which?dcache_v   :icache_v;
    unsigned int *cache_data = which?dcache_data:icache_data;
    unsigned int *cache_tag  = which?dcache_tag :icache_tag;
    unsigned int  offset     = (addr>>0        ) & ((1<<OFFSET_BITS)-1);
    unsigned int  index      = (addr>>INDEX_LOW) & ((1<<INDEX_BITS )-1);
    unsigned int  tag        = (addr>>TAG_LOW  ) & ((1<<TAG_BITS   )-1);
    /* write through */
    mem_write(addr, data, size);
    /* estimating cache performance */
    if (which && dcache_stats_enable)
        dcache_access_count++;
    if (which && dcache_stats_enable) {
        /* dcache miss (any write is a miss cuz cache is write through) */
        dcache_miss_count++;
        printf("dcache misses: %d/%d, %d%\n", dcache_miss_count,
                dcache_access_count,
                dcache_miss_count*100/dcache_access_count);
    }
    /* update cache */
    if (cache_v[index] && cache_tag[index] == tag) {
        /* cache hit */
        switch(size) {
            case 0:
                ((unsigned char *) &cache_data[index])[offset] = data;
                break;
            case 1:
                ((unsigned short *) &cache_data[index])[offset/2] = data;
                break;
            case 2:
                cache_data[index] = data;
                break;
        }
    } else {
        /* cache miss */
        if (size == 2 && (addr >> 24) != 0x1E) {
            /* cacheable  word */
            cache_v   [index] = 1;
            cache_data[index] = data;
            cache_tag [index] = tag;
        }
    }
}

/* TLB read */
unsigned int tlb_read(int which, unsigned int addr, int size) {
    if ((addr&0xC0000000) == 0x80000000) {
        addr &= 0x1FFFFFFF;
    }
    return cache_read(which, addr, size);
}

/* TLB write */
void tlb_write(int which, unsigned int addr, unsigned int data, int size) {
    if ((addr&0xC0000000) == 0x80000000) {
        addr &= 0x1FFFFFFF;
    }
    cache_write(which, addr, data, size);
}

/* read coprocessor 0 register */
int read_cop0_reg(int indx) {
    switch (indx) {
        case 12:
            return SR;
        case 13:
            return CAUSE;
        case 14:
            return EPC;
        default:
            return 0;
    }
}

/* write coprocessor 0 register */
void write_cop0_reg(int indx, int val) {
    switch (indx) {
        case 12:
            SR = val;
            break;
        default:
            ;
    }
}

/* trigger irq */
void cpu_irq() {
    irq = 1;
}

/* is alu R-format instruction? */
int is_alureg(int opcode) {
    return opcode == 0;
}

/* is branch regimm instruction? */
int is_branchregimm(int opcode) {
    return opcode == 1;
}

/* is jmp instruction? */
int is_jmp(int opcode) {
    return opcode == 2 || opcode == 3;
}

/* is branch instruction? */
int is_branch(int opcode) {
    return (opcode & 0xFC) == 0x04;
}

/* is aluimm instruction? */
int is_aluimm(int opcode) {
    return (opcode & 0xF8) == 0x08;
}

/* is memload instruction? */
int is_memload(int opcode) {
    return (opcode & 0xF8) == 0x20;
}

/* is memstore instruction? */
int is_memstore(int opcode) {
    return (opcode & 0xF8) == 0x28;
}

/* is coprocessor instruct? */
int is_cop0(int opcode) {
    return opcode == 0x10;
}

/* convert opcode/funct into mnemonic */
const char *get_mnemonic(int opcode, int ropcode, int funct) {
    if (opcode == 0) {
        return funct_to_str[funct];
    } else if (opcode == 1) {
        return regimm_to_str[ropcode];
    } else {
        return opcode_to_str[opcode];
    }
}

/* get instruction format */
int get_format(int opcode) {
    if (opcode == 0) {
        /* R FORMAT */
        return R_FORMAT;
    } else if (opcode == 2 || opcode == 3) {
        /* J FORMAT */
        return J_FORMAT;
    } else {
        /* I FORMAT */
        return I_FORMAT;
    }
}

/* print assembly code */
void print_asm(int pc, int instr) {
    int format;
    int i;
    unsigned int opcode;
    unsigned int ropcode;
    unsigned int rs;
    unsigned int rt;
    unsigned int rd;
    unsigned int shamt;
    unsigned int funct;
    unsigned int imm;
    unsigned int simm;
    unsigned int addr;
    const char *mnemonic;

    /* decode */
    opcode  = (instr>>26) & 0x3F;
    rs      = (instr>>21) & 0x1F;
    rt      = (instr>>16) & 0x1F;
    ropcode = (instr>>16) & 0x1F;
    rd      = (instr>>11) & 0x1F;
    shamt   = (instr>> 6) & 0x1F;
    funct   = (instr>> 0) & 0x3F;
    imm     = (instr>> 0) & 0xFFFF;
    addr    = (instr>> 0) & 0x3FFFFFF;

    mnemonic = get_mnemonic(opcode, ropcode, funct);
    format = get_format(opcode);

    if (format==I_FORMAT && (opcode==12 || opcode==13 || opcode==14)) {
        /* zero extend */
        simm = imm;
    } else {
        /* sign extend */
        simm = (unsigned int) ((signed int) ((signed short) imm));
    }

    /*for (i = 0; i <= 31; i++)
        printf("%s:%08X %c", regn[i], regs[i], i%8==7?'\n':' ');*/

    printf("0x%08X:        ", pc);

    if (instr == 0) {
        printf("nop");
    } else if (format == R_FORMAT && (funct==32||funct==33) && !rt) {
        printf("move          %s,%s", regn[rd], regn[rs]);
    } else if (format == I_FORMAT && (opcode==8||opcode==9) && !rs) {
        printf("li            %s,%d", regn[rt], simm);
    } else {
        printf("%s         ", mnemonic);
        switch (format) {
            case R_FORMAT:
                if ((funct>>3) == 0) {
                    /* shift (first row) */
                    printf("%s,%s,%d", regn[rd], regn[rt], shamt);
                } else if ((funct>>3) == 1) {
                    /* jumps */
                    if ((funct&7) == 0) {
                        printf("%s", regn[rs]);
                    } else if ((funct&7) == 1) {
                        printf("%s,%s", regn[rd], regn[rs]);
                    }
                } else if ((funct>>3) == 2) {
                    /* move special purpose */
                    if ((funct&7) == 0 || (funct&7) == 2) {
                        printf("%s", regn[rd]);
                    } else if ((funct&7) == 1 || (funct&7) == 3) {
                        printf("%s", regn[rs]);
                    }
                } else if ((funct>>3) == 3) {
                    /* mul and div */
                    printf("%s,%s", regn[rs], regn[rt]);
                } else if ((funct>>3) == 4) {
                    /* alu */
                    printf("%s,%s,%s", regn[rd], regn[rs], regn[rt]);
                } else if ((funct>>3) == 5) {
                    /* compare */
                    printf("%s,%s,%s", regn[rd], regn[rs], regn[rt]);
                }
                break;
            case I_FORMAT:
                if (opcode == 1) {
                    /* REGIMM */
                    printf("%s,0x%08X", regn[rs], addr+4+simm*4);
                } else if ((opcode>>3) == 0) {
                    /* branching */
                    if (opcode == 4 || opcode == 5) {
                        printf("%s,%s,0x%08X",regn[rs],regn[rt],addr+4+simm*4);
                    } else if (opcode == 6 || opcode == 7) {
                        printf("%s,0x%08X",regn[rs],addr+4+simm*4);
                    }
                } else if ((opcode>>3) == 1) {
                    /* ALU */
                    if (opcode >= 8 && opcode <= 11) {
                        printf("%s,%s,%d",regn[rt],regn[rs],simm);
                    } else if (opcode >= 12 && opcode <= 14) {
                        printf("%s,%s,0x%04X",regn[rt],regn[rs],simm&0xFFFF);
                    } else if (opcode == 15) {
                        printf("%s,0x%04X",regn[rt],simm&0xFFFF);
                    }
                } else if ((opcode>>3) == 4 || (opcode>>3) == 5) {
                    /* load and store */
                    printf("%s,%d(%s)",regn[rt],simm,regn[rs]);
                }
                break;
            case J_FORMAT:
                printf("0x%08X", ((addr+4)&0xF0000000) + addr*4);
                break;
            default:
                break;
        }
    }
    printf("\n");
}

/* print short debugging info */
void cpu_debug_short() {

    int i;
    FILE *debug = stderr;
    fprintf(debug, "******************* SIMULATOR STEP *******************\n");
    fprintf(debug, "cur step: %d\n", cur_step);
    fprintf(debug, "IF:  ");
    print_asm(if_pc, if_instr);
    fprintf(debug, "ID:  ");
    print_asm(id_pc4-4, id_instr);
    fprintf(debug, "EX:  ");
    print_asm(ex_pc4-4, ex_instr);
    fprintf(debug, "MEM: ");
    print_asm(mem_pc4-4, mem_instr);
    fprintf(debug, "WB:  ");
    print_asm(wb_pc4-4, wb_instr);
    printf("ALUOP: %02X\n", ex_aluop);
    for (i = 0; i <= 31; i++)
        printf("%s:%08X %c", regn[i], id_regfile[i], i%8==7?'\n':' ');
    fprintf(debug, "\n");

}

/* print detailed debugging info */
void cpu_debug() {

    int i;
    FILE *debug = stderr;

    fprintf(debug, "******************* SIMULATOR STEP *******************\n");

    /* instr_t info */

    fprintf(debug, "cur step: %d\n", cur_step);

    /* IF */
    fprintf(debug, "======\n");
    fprintf(debug, "= IF =\n");
    fprintf(debug, "======\n");
    fprintf(debug, "if_pc:            0x%08X\n", if_pc);
    fprintf(debug, "if_pc4:           0x%08X\n", if_pc4);

    /* ID */
    fprintf(debug, "======\n");
    fprintf(debug, "= ID =\n");
    fprintf(debug, "======\n");
    fprintf(debug, "id_pc4:           0x%08X\n", id_pc4);
    fprintf(debug, "id_imm32:         0x%08X\n", id_imm32);
    fprintf(debug, "id_shl:           0x%08X\n", id_shl);
    fprintf(debug, "id_braddr:        0x%08X\n", id_braddr);
    fprintf(debug, "id_val_of_rs:     0x%08X\n", id_val_of_rs);
    fprintf(debug, "id_val_of_rt:     0x%08X\n", id_val_of_rt);
    fprintf(debug, "id_is_equal:      %d\n",     id_is_equal);
    fprintf(debug, "id_pc_src:        %d\n",     id_pc_src);
    fprintf(debug, "id_if_flush:      %d\n",     id_if_flush);
    fprintf(debug, "id_reg_dest_in:   %d\n",     id_ctrlsig_in[REG_DEST]);
    fprintf(debug, "id_alu_src_in:    %d\n",     id_ctrlsig_in[ALU_SRC]);
    fprintf(debug, "id_mem_to_reg_in: %d\n",     id_ctrlsig_in[MEM_TO_REG]);
    fprintf(debug, "id_reg_write_in:  %d\n",     id_ctrlsig_in[REG_WRITE]);
    fprintf(debug, "id_mem_read_in:   %d\n",     id_ctrlsig_in[MEM_READ]);
    fprintf(debug, "id_mem_write_in:  %d\n",     id_ctrlsig_in[MEM_WRITE]);
    fprintf(debug, "id_branch_in:     %d\n",     id_ctrlsig_in[BRANCH]);
    fprintf(debug, "id_reg_dest:      %d\n",     id_ctrlsig[REG_DEST]);
    fprintf(debug, "id_alu_src:       %d\n",     id_ctrlsig[ALU_SRC]);
    fprintf(debug, "id_mem_to_reg:    %d\n",     id_ctrlsig[MEM_TO_REG]);
    fprintf(debug, "id_reg_write:     %d\n",     id_ctrlsig[REG_WRITE]);
    fprintf(debug, "id_mem_read:      %d\n",     id_ctrlsig[MEM_READ]);
    fprintf(debug, "id_mem_write:     %d\n",     id_ctrlsig[MEM_WRITE]);
    fprintf(debug, "id_branch:        %d\n",     id_ctrlsig[BRANCH]);
    fprintf(debug, "id_stall:         %d\n",     id_stall);
    fprintf(debug, "id_ifclk:         %d\n",     id_ifclk);
    fprintf(debug, "id_pcclk:         %d\n",     id_pcclk);
    for (i = 0; i < 32; i++) {
    	fprintf(debug, "REG%02d: 0x%08X   ", i, id_regfile[i]);
        if (!((i+1)%4))
            fprintf(debug, "\n");
    }

    /* EX */
    fprintf(debug, "======\n");
    fprintf(debug, "= EX =\n");
    fprintf(debug, "======\n");
    fprintf(debug, "ex_reg_dest:      %d\n",     ex_ctrlsig[REG_DEST]);
    fprintf(debug, "ex_alu_src:       %d\n",     ex_ctrlsig[ALU_SRC]);
    fprintf(debug, "ex_mem_to_reg:    %d\n",     ex_ctrlsig[MEM_TO_REG]);
    fprintf(debug, "ex_reg_write:     %d\n",     ex_ctrlsig[REG_WRITE]);
    fprintf(debug, "ex_mem_read:      %d\n",     ex_ctrlsig[MEM_READ]);
    fprintf(debug, "ex_mem_write:     %d\n",     ex_ctrlsig[MEM_WRITE]);
    fprintf(debug, "ex_branch:        %d\n",     ex_ctrlsig[BRANCH]);
    fprintf(debug, "ex_val_of_rs:     0x%08X\n", ex_val_of_rs);
    fprintf(debug, "ex_val_of_rt:     0x%08X\n", ex_val_of_rt);
    fprintf(debug, "ex_imm32:         0x%08X\n", ex_imm32);
    fprintf(debug, "ex_fu_mux1:       %d\n",     ex_fu_mux1);
    fprintf(debug, "ex_fu_mux2:       %d\n",     ex_fu_mux2);
    fprintf(debug, "ex_alu1:          0x%08X\n", ex_alu1);
    fprintf(debug, "ex_muxop:         0x%08X\n", ex_muxop);
    fprintf(debug, "ex_alu2 :         0x%08X\n", ex_alu2);
    fprintf(debug, "ex_alu_output:    0x%08X\n", ex_alu_output);
    fprintf(debug, "ex_rk:            %d\n",     ex_rk);

    /* MEM */
    fprintf(debug, "=======\n");
    fprintf(debug, "= MEM =\n");
    fprintf(debug, "=======\n");
    fprintf(debug, "mem_reg_dest:     %d\n",     mem_ctrlsig[REG_DEST]);
    fprintf(debug, "mem_alu_src:      %d\n",     mem_ctrlsig[ALU_SRC]);
    fprintf(debug, "mem_mem_to_reg:   %d\n",     mem_ctrlsig[MEM_TO_REG]);
    fprintf(debug, "mem_reg_write:    %d\n",     mem_ctrlsig[REG_WRITE]);
    fprintf(debug, "mem_mem_read:     %d\n",     mem_ctrlsig[MEM_READ]);
    fprintf(debug, "mem_mem_write:    %d\n",     mem_ctrlsig[MEM_WRITE]);
    fprintf(debug, "mem_branch:       %d\n",     mem_ctrlsig[BRANCH]);
    fprintf(debug, "mem_addr:         0x%08X\n", mem_addr);
    fprintf(debug, "mem_data_in:      0x%08X\n", mem_data_in);
    fprintf(debug, "mem_data_out:     0x%08X\n", mem_data_out);
    fprintf(debug, "mem_rk:           %d\n",     mem_rk);

    /* WB */
    fprintf(debug, "======\n");
    fprintf(debug, "= WB =\n");
    fprintf(debug, "======\n");
    fprintf(debug, "wb_reg_dest:      %d\n",     wb_ctrlsig[REG_DEST]);
    fprintf(debug, "wb_alu_src:       %d\n",     wb_ctrlsig[ALU_SRC]);
    fprintf(debug, "wb_mem_to_reg:    %d\n",     wb_ctrlsig[MEM_TO_REG]);
    fprintf(debug, "wb_reg_write:     %d\n",     wb_ctrlsig[REG_WRITE]);
    fprintf(debug, "wb_mem_read:      %d\n",     wb_ctrlsig[MEM_READ]);
    fprintf(debug, "wb_mem_write:     %d\n",     wb_ctrlsig[MEM_WRITE]);
    fprintf(debug, "wb_branch:        %d\n",     wb_ctrlsig[BRANCH]);
    fprintf(debug, "wb_mem_out:       0x%08X\n", wb_mem_out);
    fprintf(debug, "wb_alu_out:       0x%08X\n", wb_alu_out);
    fprintf(debug, "wb_value_of_rk:   0x%08X\n", wb_value_of_rk);
    fprintf(debug, "wb_rk:            %d\n",     wb_rk);

}

/* clk */
int cpu_clk() {
    /* store clk controls */
    int ifclk = id_ifclk, pcclk = id_pcclk, handle_exception = 0;
    int oldreg = 0;

    if (halted == 1) {
        cpu_debug_short();
        halted++;
    }

    if (halted)
        return 0;

    /* increase step */
    /*if (cur_step == 100) {
        return 0;
    } else {
        cpu_debug_short();
    }*/
    /*cpu_debug_short();*/
    cur_step++;

    /* IF transition */
    if (if_exception && !id_instr && !ex_instr && !mem_instr) {
        /* IF STAGE EXCEPTION */
        handle_exception = 1;
    } else if (id_exception && !ex_instr && !mem_instr) {
        /* ID EXCEPTION */
        handle_exception = 1;
    } else if (ex_exception && !mem_instr) {
        /* EX EXCEPTION */
        handle_exception = 1;
    } else if (mem_exception) {
        /* MEM EXCEPTION */
        handle_exception = 1;
    }
    if (handle_exception) {
        if_pc      = 0xBFC00180;
        if_exphndl = 1;
    } else if (if_exception) {
        /* Don't Move (Phantogram) */
    } else {
        /* normal operation */
        if (pcclk) {
            if (id_pc_src == PCSRC_PC4 || if_exphndl) {
                if_pc = if_pc4;
            } else if (id_pc_src == PCSRC_BRANCH) {
                if_pc = id_braddr;
            } else if (id_pc_src == PCSRC_JMP) {
                if_pc = id_jmpaddr;
            } else if (id_pc_src == PCSRC_JR) {
                if_pc = id_jraddr;
            } else {
                /* ? */
            }
        }
        if_exphndl = 0;
    }

    /* process WB stage */
    if (mem_exception) {
        /* introduce a bubble in WB */
        wb_instr    = 0;
        wb_pc4      = 0;
        wb_ctrlsig[REG_DEST]   = 0;
        wb_ctrlsig[ALU_SRC]    = 0;
        wb_ctrlsig[MEM_TO_REG] = 0;
        wb_ctrlsig[REG_WRITE]  = 0;
        wb_ctrlsig[MEM_READ]   = 0;
        wb_ctrlsig[MEM_WRITE]  = 0;
        wb_ctrlsig[BRANCH]     = 0;
        wb_mem_out  = 0;
        wb_alu_out  = 0;
        wb_rk       = 0;
        wb_is_mfc0  = 0;
        wb_is_mtc0  = 0;
    } else {
        wb_instr = mem_instr;
        wb_pc4 = mem_pc4;
        wb_ctrlsig[REG_DEST] = mem_ctrlsig[REG_DEST];
        wb_ctrlsig[ALU_SRC] = mem_ctrlsig[ALU_SRC];
        wb_ctrlsig[MEM_TO_REG] = mem_ctrlsig[MEM_TO_REG];
        wb_ctrlsig[REG_WRITE] = mem_ctrlsig[REG_WRITE];
        wb_ctrlsig[MEM_READ] = mem_ctrlsig[MEM_READ];
        wb_ctrlsig[MEM_WRITE] = mem_ctrlsig[MEM_WRITE];
        wb_ctrlsig[BRANCH] = mem_ctrlsig[BRANCH];
        wb_mem_out = mem_data_out;
        wb_alu_out = mem_addr;
        wb_value_of_rk = wb_ctrlsig[MEM_TO_REG]?wb_mem_out:wb_alu_out;
        wb_rk = mem_rk;
        wb_is_mfc0 = mem_is_mfc0;
        wb_is_mtc0 = mem_is_mtc0;
    }
    if (wb_ctrlsig[REG_WRITE] && wb_rk)
        id_regfile[wb_rk] = wb_value_of_rk;

    /* process MEM stage */
    if (mem_exception) {
        /* don't move */
    } else if (ex_exception) {
        /* introduce a bubble in MEM */
        mem_instr   = 0;
        mem_pc4     = 0;
        mem_memop   = 0;
        mem_ctrlsig[REG_DEST]   = 0;
        mem_ctrlsig[ALU_SRC]    = 0;
        mem_ctrlsig[MEM_TO_REG] = 0;
        mem_ctrlsig[REG_WRITE]  = 0;
        mem_ctrlsig[MEM_READ]   = 0;
        mem_ctrlsig[MEM_WRITE]  = 0;
        mem_ctrlsig[BRANCH]     = 0;
        mem_tmp     = 0;
        mem_addr    = 0;
        mem_data_in = 0;
        mem_rk      = 0;
        mem_is_mfc0 = 0;
        mem_is_mtc0 = 0;
    } else {
        mem_instr = ex_instr;
        mem_pc4 = ex_pc4;
        mem_memop = ex_memop;
        mem_ctrlsig[REG_DEST] = ex_ctrlsig[REG_DEST];
        mem_ctrlsig[ALU_SRC] = ex_ctrlsig[ALU_SRC];
        mem_ctrlsig[MEM_TO_REG] = ex_ctrlsig[MEM_TO_REG];
        mem_ctrlsig[REG_WRITE] = ex_ctrlsig[REG_WRITE];
        mem_ctrlsig[MEM_READ] = ex_ctrlsig[MEM_READ];
        mem_ctrlsig[MEM_WRITE] = ex_ctrlsig[MEM_WRITE];
        mem_ctrlsig[BRANCH] = ex_ctrlsig[BRANCH];
        mem_tmp = ex_muxop;
        mem_addr = ex_alu_output;
        mem_data_in = ex_muxop;
        mem_rk = ex_rk;
        mem_is_mfc0 = ex_is_mfc0;
        mem_is_mtc0 = ex_is_mtc0;
    }
    if (mem_ctrlsig[MEM_WRITE]) {
        int addr, byte, half, word;
        switch (mem_memop) {
            case MEMOP_BYTE:
                tlb_write(1, mem_addr, mem_data_in, 0);
                break;
            case MEMOP_HALF:
                tlb_write(1, mem_addr, mem_data_in, 1);
                break;
            case MEMOP_LEFT:
                printf("SWL not implemented!!!\n");
                exit(0);
                break;
            case MEMOP_WORD:
                tlb_write(1, mem_addr, mem_data_in, 2);
                break;
            case MEMOP_RIGHT:
                printf("SWR not implemented!!!\n");
                exit(0);
                break;
            default:
                /* exception */
                break;
        }
    }
    if (mem_ctrlsig[MEM_READ]) {
        switch (mem_memop) {
            case MEMOP_BYTE:
                mem_data_out = (int) ((char)tlb_read(1, mem_addr,0));
                break;
            case MEMOP_HALF:
                mem_data_out = (int) ((short)tlb_read(1, mem_addr,1));
                break;
            case MEMOP_LEFT:
                switch(mem_addr&3) {
                    case 0:
                        mem_data_out=(tlb_read(1, mem_addr-0,0)<<24)|
                                     (mem_tmp&0x00FFFFFF);
                        break;
                    case 1:
                        mem_data_out=(tlb_read(1, mem_addr-0,0)<<24)|
                                     (tlb_read(1, mem_addr-1,0)<<16)|
                                     (mem_tmp&0x0000FFFF);
                        break;
                    case 2:
                        mem_data_out=(tlb_read(1, mem_addr-0,0)<<24)|
                                     (tlb_read(1, mem_addr-1,0)<<16)|
                                     (tlb_read(1, mem_addr-2,0)<< 8)|
                                     (mem_tmp&0x000000FF);
                        break;
                    case 3:
                        mem_data_out=(tlb_read(1, mem_addr-0,0)<<24)|
                                     (tlb_read(1, mem_addr-1,0)<<16)|
                                     (tlb_read(1, mem_addr-2,0)<< 8)|
                                     (tlb_read(1, mem_addr-3,0)<< 0);
                        break;
                }
                break;
            case MEMOP_WORD:
                mem_data_out = tlb_read(1, mem_addr,2);
                break;
            case MEMOP_BYTEU:
                mem_data_out = (unsigned int)
                                ((unsigned char)tlb_read(1, mem_addr,0));
                break;
            case MEMOP_HALFU:
                mem_data_out = (unsigned int)
                                ((unsigned short)tlb_read(1, mem_addr,1));
                break;
            case MEMOP_RIGHT:
                switch(mem_addr&3) {
                    case 0:
                        mem_data_out=(tlb_read(1, mem_addr+3,0)<<24)|
                                     (tlb_read(1, mem_addr+2,0)<<16)|
                                     (tlb_read(1, mem_addr+1,0)<< 8)|
                                     (tlb_read(1, mem_addr+0,0)<< 0);
                        break;
                    case 1:
                        mem_data_out=(mem_tmp & 0xFF000000)|
                                     (tlb_read(1, mem_addr+2,0)<<16)|
                                     (tlb_read(1, mem_addr+1,0)<< 8)|
                                     (tlb_read(1, mem_addr+0,0)<< 0);
                        break;
                    case 2:
                        mem_data_out=(mem_tmp & 0xFFFF0000)|
                                     (tlb_read(1, mem_addr+1,0)<< 8)|
                                     (tlb_read(1, mem_addr+0,0)<< 0);
                        break;
                    case 3:
                        mem_data_out=(mem_tmp & 0xFFFFFF00)|
                                     (tlb_read(1, mem_addr+0,0)<< 0);
                        break;
                }
                break;
            default:
                /* exception */
                break;
        }
    }

    /* process EX stage */
    if (ex_exception) {
        /* don't move */
    } else if (id_exception || !ifclk) {
        /* introudce bubble */
        ex_instr = 0;
        ex_pc4 = 0;
        ex_rs = 0;
        ex_rt = 0;
        ex_rd = 0;
        ex_shamt = 0;
        ex_aluop = 0;
        ex_memop = 0;
        ex_ctrlsig[REG_DEST] = 0;
        ex_ctrlsig[ALU_SRC] = 0;
        ex_ctrlsig[MEM_TO_REG] = 0;
        ex_ctrlsig[REG_WRITE] = 0;
        ex_ctrlsig[MEM_READ] = 0;
        ex_ctrlsig[MEM_WRITE] = 0;
        ex_ctrlsig[BRANCH] = 0;
        ex_val_of_rs = 0;
        ex_val_of_rt = 0;
        ex_imm32 = 0;
        ex_is_mfc0 = 0;
        ex_is_mtc0 = 0;
    } else {
        /* get instruction normally */
        ex_instr = id_instr;
        ex_pc4 = id_pc4;
        ex_rs = id_rs;
        ex_rt = id_rt;
        ex_rd = id_rd;
        ex_shamt = id_shamt;
        ex_aluop = id_aluop;
        ex_memop = id_memop;
        ex_ctrlsig[REG_DEST] = id_ctrlsig[REG_DEST];
        ex_ctrlsig[ALU_SRC] = id_ctrlsig[ALU_SRC];
        ex_ctrlsig[MEM_TO_REG] = id_ctrlsig[MEM_TO_REG];
        ex_ctrlsig[REG_WRITE] = id_ctrlsig[REG_WRITE];
        ex_ctrlsig[MEM_READ] = id_ctrlsig[MEM_READ];
        ex_ctrlsig[MEM_WRITE] = id_ctrlsig[MEM_WRITE];
        ex_ctrlsig[BRANCH] = id_ctrlsig[BRANCH];
        if (!id_is_cop0) {
            ex_val_of_rs = id_val_of_rs;
        } else if (id_is_mfc0) {
            ex_val_of_rs = id_cop0_regrd;
        } else {
            ex_val_of_rs = 0;
        }
        if (!id_is_cop0 || id_is_mtc0) {
            ex_val_of_rt = id_val_of_rt;
        } else {
            ex_val_of_rt = 0;
        }
        ex_imm32 = id_imm32;
        ex_is_mfc0 = id_is_mfc0;
        ex_is_mtc0 = id_is_mtc0;
    }
    ex_fu_mux1 = 0;
    ex_fu_mux2 = 0;
    if(wb_ctrlsig[REG_WRITE] && wb_rk && wb_rk==ex_rs)
        ex_fu_mux1 = 1;
    if(wb_ctrlsig[REG_WRITE] && wb_rk && wb_rk==ex_rt)
        ex_fu_mux2 = 1;
    /* instruction in MEM has higher priority than WB */
    if(mem_ctrlsig[REG_WRITE] && mem_rk && mem_rk==ex_rs)
        ex_fu_mux1 = 2;
    if(mem_ctrlsig[REG_WRITE] && mem_rk && mem_rk==ex_rt)
        ex_fu_mux2 = 2;
    switch(ex_fu_mux1) {
        case 0:
            ex_alu1 = ex_val_of_rs;
            break;
        case 1:
            ex_alu1 = wb_value_of_rk;
            break;
        case 2:
            ex_alu1 = mem_addr;
            break;
    }
    switch(ex_fu_mux2) {
        case 0:
            ex_muxop = ex_val_of_rt;
            break;
        case 1:
            ex_muxop = wb_value_of_rk;
            break;
        case 2:
            ex_muxop = mem_addr;
            break;
    }
    /* now calc alu2 */
    ex_alu2 = (ex_ctrlsig[ALU_SRC])?ex_imm32:ex_muxop;
    /* execute */
    switch (ex_aluop) {
        case ALUOP_NOP:
            break;
        case ALUOP_EXP:
            /* not implemented */
            printf("HALTED! (%s:%d)\n", __FILE__, __LINE__);
            halted = 1;
            break;
        case ALUOP_CPYPC:
            ex_alu_output = ex_alu2;
            break;
        case ALUOP_LUI:
            ex_alu_output = ex_alu2<<16;
            break;
        case ALUOP_MFHI:
            ex_alu_output = ex_hi;
            break;
        case ALUOP_MTHI:
            ex_hi = ex_alu1;
            break;
        case ALUOP_MFLO:
            ex_alu_output = ex_lo;
            break;
        case ALUOP_MTLO:
            ex_lo = ex_alu1;
            break;
        case ALUOP_MULT:
            ex_tmp = ((signed long long) ex_alu1)*
                     ((signed long long) ex_alu2);
            ex_lo = ex_tmp & 0xFFFFFFFF;
            ex_hi = ex_tmp>>32;
            break;
        case ALUOP_MULTU:
            ex_tmp = ((unsigned long long) ex_alu1)*
                     ((unsigned long long) ex_alu2);
            ex_lo = ex_tmp & 0xFFFFFFFF;
            ex_hi = ex_tmp>>32;
            break;
        case ALUOP_DIV:
            ex_lo = ((signed int) ex_alu1) / ((signed int) ex_alu2);
            ex_hi = ((signed int) ex_alu1) % ((signed int) ex_alu2);
            break;
        case ALUOP_DIVU:
            ex_lo = ((unsigned int) ex_alu1) / ((unsigned int) ex_alu2);
            ex_hi = ((unsigned int) ex_alu1) % ((unsigned int) ex_alu2);
            break;
        case ALUOP_ADD:
            ex_alu_output = ex_alu1 + ex_alu2;
            break;
        case ALUOP_ADDU:
            ex_alu_output = ex_alu1 + ex_alu2;
            break;
        case ALUOP_SUB:
            ex_alu_output = ex_alu1 - ex_alu2;
            break;
        case ALUOP_SUBU:
            ex_alu_output = ex_alu1 - ex_alu2;
            break;
        case ALUOP_AND:
            ex_alu_output = ex_alu1 & ex_alu2;
            break;
        case ALUOP_OR:
            ex_alu_output = ex_alu1 | ex_alu2;
            break;
        case ALUOP_XOR:
            ex_alu_output = ex_alu1 ^ ex_alu2;
            break;
        case ALUOP_NOR:
            ex_alu_output = ~(ex_alu1 | ex_alu2);
            break;
        case ALUOP_SLT:
            ex_alu_output = ((signed int) ex_alu1)<((signed int) ex_alu2);
            break;
        case ALUOP_SLTU:
            ex_alu_output = ((unsigned int) ex_alu1)<((unsigned int) ex_alu2);
            break;
        case ALUOP_SLL:
            ex_alu_output = ex_alu2 << ex_shamt;
            break;
        case ALUOP_SRL:
            ex_alu_output = ex_alu2 >> ex_shamt;
            break;
        case ALUOP_SRA:
            ex_alu_output = (((signed int) ex_alu2) / (1<<ex_shamt));
            break;
        case ALUOP_SLLV:
            ex_alu_output = ex_alu2 << (ex_alu1&31);
            break;
        case ALUOP_SRLV:
            ex_alu_output = ex_alu2 >> (ex_alu1&31);
            break;
        case ALUOP_SRAV:
            ex_alu_output = (((signed int) ex_alu2) / (1<<(ex_alu1&31)));
            break;
        default:
            /* not implemented */
            break;
    }
    ex_rk = ex_ctrlsig[REG_DEST]?ex_rd:ex_rt;

    /* ID */
    if (id_exception) {
        /* don't move */
    } else if (if_exception) {
        /* flush ID */
        id_instr = 0;
        id_pc    = if_pc4-4;
        id_pc4   = if_pc4;
    } else {
        /* normal operation */
        if (ifclk) {
            id_instr = if_instr;
            id_pc    = if_pc4-4;
            id_pc4   = if_pc4;
        }
    }
    id_opcode = (id_instr>>26)&0x3F;
    id_rs = (id_instr>>21)&0x1F;
    id_rt = (id_instr>>16)&0x1F;
    if (id_opcode == 3) {
        id_rd = 31;
    } else {
        id_rd = (id_instr>>11)&0x1F;
    }
    id_ropcode = (id_instr>>16)&0x1F;
    id_shamt = (id_instr>>6)&0x1F;
    id_funct = (id_instr>>0)&0x3F;
    id_is_jr = id_opcode==0x00 && id_funct==0x08;
    id_is_jalr = id_opcode==0x00 && id_funct==0x09;
    if (id_opcode == 3 || (!id_opcode && id_funct == 9) ||
        (id_opcode == 1 && id_ropcode == 16) ||
        (id_opcode == 1 && id_ropcode == 17)) {
        id_imm32 = id_pc4+4;
    } else if (id_opcode == 12 || id_opcode == 13 || id_opcode == 14) {
        id_imm32 = ((unsigned short)((id_instr>>0)&0xFFFF));
    } else {
        id_imm32 = ((signed short)((id_instr>>0)&0xFFFF));
    }
    id_shl = id_imm32<<2;
    id_val_of_rs = id_regfile[id_rs];
    id_val_of_rt = id_regfile[id_rt];
    id_braddr  = id_pc4 + id_shl;
    id_jmpaddr = (id_pc4&0xF0000000) + ((id_instr&0x3FFFFFF)<<2);
    id_jraddr  = id_val_of_rs;
    id_is_equal = (id_val_of_rs==id_val_of_rt);
    id_is_zero = (id_val_of_rs == 0);
    id_is_lez = (id_val_of_rs <= 0);
    id_is_gtz = (id_val_of_rs > 0);
    id_is_mfc0 = is_cop0(id_opcode) & (id_rs ==  0);
    id_is_mtc0 = is_cop0(id_opcode) & (id_rs ==  4);
    id_is_rfe  = is_cop0(id_opcode) & (id_rs == 16) & (id_funct == 16);
    id_is_cop0 = is_cop0(id_opcode);
    if (is_alureg(id_opcode)) {
        id_ctrlsig_in[REG_DEST]   = 1;
        id_ctrlsig_in[ALU_SRC]    = (id_funct == 8 || id_funct == 9);
        id_ctrlsig_in[MEM_TO_REG] = 0;
        id_ctrlsig_in[REG_WRITE]  = 1;
        id_ctrlsig_in[MEM_READ]   = 0;
        id_ctrlsig_in[MEM_WRITE]  = 0;
        id_ctrlsig_in[BRANCH]     = (id_funct == 8 || id_funct == 9);
        /* decode ALU instructions */
        switch(id_funct) {
            case 0x00:
                id_aluop = ALUOP_SLL;
                break;
            case 0x02:
                id_aluop = ALUOP_SRL;
                break;
            case 0x03:
                id_aluop = ALUOP_SRA;
                break;
            case 0x04:
                id_aluop = ALUOP_SLLV;
                break;
            case 0x06:
                id_aluop = ALUOP_SRLV;
                break;
            case 0x07:
                id_aluop = ALUOP_SRAV;
                break;
            case 0x08:
                id_aluop = ALUOP_CPYPC;
                break;
            case 0x09:
                id_aluop = ALUOP_CPYPC;
                break;
            case 0x0C:
                id_aluop = ALUOP_EXP;
                break;
            case 0x0D:
                id_aluop = ALUOP_EXP;
                break;
            case 0x10:
                id_aluop = ALUOP_MFHI;
                break;
            case 0x11:
                id_aluop = ALUOP_MTHI;
                break;
            case 0x12:
                id_aluop = ALUOP_MFLO;
                break;
            case 0x13:
                id_aluop = ALUOP_MTLO;
                break;
            case 0x18:
                id_aluop = ALUOP_MULT;
                break;
            case 0x19:
                id_aluop = ALUOP_MULTU;
                break;
            case 0x1A:
                id_aluop = ALUOP_DIV;
                break;
            case 0x1B:
                id_aluop = ALUOP_DIVU;
                break;
            case 0x20:
                id_aluop = ALUOP_ADD;
                break;
            case 0x21:
                id_aluop = ALUOP_ADDU;
                break;
            case 0x22:
                id_aluop = ALUOP_SUB;
                break;
            case 0x23:
                id_aluop = ALUOP_SUBU;
                break;
            case 0x24:
                id_aluop = ALUOP_AND;
                break;
            case 0x25:
                id_aluop = ALUOP_OR;
                break;
            case 0x26:
                id_aluop = ALUOP_XOR;
                break;
            case 0x27:
                id_aluop = ALUOP_NOR;
                break;
            case 0x2A:
                id_aluop = ALUOP_SLT;
                break;
            case 0x2B:
                id_aluop = ALUOP_SLTU;
                break;
            default:
                id_aluop = ALUOP_EXP;
        }
    } else if (is_branchregimm(id_opcode)) {
        id_ctrlsig_in[REG_DEST]   = 1;
        id_ctrlsig_in[ALU_SRC]    = 1; /* immediate */
        id_ctrlsig_in[MEM_TO_REG] = 0;
        id_ctrlsig_in[REG_WRITE]  = (id_ropcode==16||id_ropcode==17);
        id_ctrlsig_in[MEM_READ]   = 0;
        id_ctrlsig_in[MEM_WRITE]  = 0;
        id_ctrlsig_in[BRANCH]     = 1;
        id_aluop = ALUOP_NOP;
    } else if (is_jmp(id_opcode)) {
        id_ctrlsig_in[REG_DEST]   = 1;
        id_ctrlsig_in[ALU_SRC]    = 1; /* immediate */
        id_ctrlsig_in[MEM_TO_REG] = 0;
        id_ctrlsig_in[REG_WRITE]  = (id_opcode==3);
        id_ctrlsig_in[MEM_READ]   = 0;
        id_ctrlsig_in[MEM_WRITE]  = 0;
        id_ctrlsig_in[BRANCH]     = 1;
        id_aluop = ALUOP_CPYPC;
    } else if (is_branch(id_opcode)) {
        id_ctrlsig_in[REG_DEST]   = 0;
        id_ctrlsig_in[ALU_SRC]    = 0; /* no immediate */
        id_ctrlsig_in[MEM_TO_REG] = 0;
        id_ctrlsig_in[REG_WRITE]  = 0;
        id_ctrlsig_in[MEM_READ]   = 0;
        id_ctrlsig_in[MEM_WRITE]  = 0;
        id_ctrlsig_in[BRANCH]     = 1;
        id_aluop = ALUOP_NOP;
    } else if (is_aluimm(id_opcode)) {
        id_ctrlsig_in[REG_DEST]   = 0;
        id_ctrlsig_in[ALU_SRC]    = 1; /* immediate */
        id_ctrlsig_in[MEM_TO_REG] = 0;
        id_ctrlsig_in[REG_WRITE]  = 1;
        id_ctrlsig_in[MEM_READ]   = 0;
        id_ctrlsig_in[MEM_WRITE]  = 0;
        id_ctrlsig_in[BRANCH]     = 0;
        switch(id_opcode) {
            case 0x08:
                id_aluop = ALUOP_ADD;
                break;
            case 0x09:
                id_aluop = ALUOP_ADDU;
                break;
            case 0x0A:
                id_aluop = ALUOP_SLT;
                break;
            case 0x0B:
                id_aluop = ALUOP_SLTU;
                break;
            case 0x0C:
                id_aluop = ALUOP_AND;
                break;
            case 0x0D:
                id_aluop = ALUOP_OR;
                break;
            case 0x0E:
                id_aluop = ALUOP_XOR;
                break;
            case 0x0F:
                id_aluop = ALUOP_LUI;
                break;
        }
    } else if (is_memload(id_opcode)) {
        id_ctrlsig_in[REG_DEST]   = 0;
        id_ctrlsig_in[ALU_SRC]    = 1; /* immediate */
        id_ctrlsig_in[MEM_TO_REG] = 1;
        id_ctrlsig_in[REG_WRITE]  = 1;
        id_ctrlsig_in[MEM_READ]   = 1;
        id_ctrlsig_in[MEM_WRITE]  = 0;
        id_ctrlsig_in[BRANCH]     = 0;
        id_aluop = ALUOP_ADD;
        id_memop = id_opcode & 7;
    } else if (is_memstore(id_opcode)) {
        id_ctrlsig_in[REG_DEST]   = 0;
        id_ctrlsig_in[ALU_SRC]    = 1; /* immediate */
        id_ctrlsig_in[MEM_TO_REG] = 0;
        id_ctrlsig_in[REG_WRITE]  = 0;
        id_ctrlsig_in[MEM_READ]   = 0;
        id_ctrlsig_in[MEM_WRITE]  = 1;
        id_ctrlsig_in[BRANCH]     = 0;
        id_aluop = ALUOP_ADD;
        id_memop = id_opcode & 7;
    } else if (is_cop0(id_opcode)) {
        id_ctrlsig_in[REG_DEST]   = id_is_mtc0;
        id_ctrlsig_in[ALU_SRC]    = 0;
        id_ctrlsig_in[MEM_TO_REG] = 0;
        id_ctrlsig_in[REG_WRITE]  = id_is_mfc0;
        id_ctrlsig_in[MEM_READ]   = 0;
        id_ctrlsig_in[MEM_WRITE]  = 0;
        id_ctrlsig_in[BRANCH]     = 0;
        if (id_is_mfc0 || id_is_mtc0) {
            id_aluop = ALUOP_ADD;
        } else {
            id_aluop = ALUOP_NOP;
        }
    } else {
        id_ctrlsig_in[REG_DEST]   = 0;
        id_ctrlsig_in[ALU_SRC]    = 0;
        id_ctrlsig_in[MEM_TO_REG] = 0;
        id_ctrlsig_in[REG_WRITE]  = 0;
        id_ctrlsig_in[MEM_READ]   = 0;
        id_ctrlsig_in[MEM_WRITE]  = 0;
        id_ctrlsig_in[BRANCH]     = 0;
        id_aluop = ALUOP_EXP;
    }
    if ((ex_ctrlsig[MEM_READ] && ex_rk &&
        ((ex_rk == id_rs) ||
         ((ex_rk == id_rt) && (!id_ctrlsig_in[MEM_READ]))))
        ||
        ((id_opcode == 0x04 || id_opcode == 0x05 ||
          id_opcode == 0x06 || id_opcode == 0x07 ||
          id_opcode == 0x01 || id_opcode == 0x02 || id_opcode == 0x03 ||
          (id_opcode == 0x00 && (id_funct == 8 || id_funct == 9))) &&
         ((ex_ctrlsig[REG_WRITE] && ex_rk &&
          (ex_rk == id_rs || (id_opcode != 1 && ex_rk == id_rt))) ||
          (mem_ctrlsig[REG_WRITE] && mem_rk &&
          (mem_rk == id_rs || (id_opcode != 1 && mem_rk == id_rt)))))
        ||
        ((id_is_mfc0 || id_is_mtc0 || id_is_rfe) &&
         (ex_instr || mem_instr || wb_instr))) {
        /* hazard, stall the pipeline */
        id_stall = 1;
        id_ifclk = 0;
        id_pcclk = 0;
    } else {
        id_stall = 0;
        id_ifclk = 1;
        id_pcclk = 1;
    }
    if (id_stall) {
        id_ctrlsig[REG_DEST]   = 0;
        id_ctrlsig[ALU_SRC]    = 0;
        id_ctrlsig[MEM_TO_REG] = 0;
        id_ctrlsig[REG_WRITE]  = 0;
        id_ctrlsig[MEM_READ]   = 0;
        id_ctrlsig[MEM_WRITE]  = 0;
        id_ctrlsig[BRANCH]     = 0;
    } else {
        id_ctrlsig[REG_DEST]   = id_ctrlsig_in[REG_DEST];
        id_ctrlsig[ALU_SRC]    = id_ctrlsig_in[ALU_SRC];
        id_ctrlsig[MEM_TO_REG] = id_ctrlsig_in[MEM_TO_REG];
        id_ctrlsig[REG_WRITE]  = id_ctrlsig_in[REG_WRITE];
        id_ctrlsig[MEM_READ]   = id_ctrlsig_in[MEM_READ];
        id_ctrlsig[MEM_WRITE]  = id_ctrlsig_in[MEM_WRITE];
        id_ctrlsig[BRANCH]     = id_ctrlsig_in[BRANCH];
    }
    /* select PC source */
    if (id_opcode == 0 && id_funct == 8) {
        /* jr */
        id_pc_src = PCSRC_JR;
    } else if (id_opcode == 0 && id_funct == 9) {
        /* jalr */
        id_pc_src = PCSRC_JR;
    } else if (id_opcode == 1 && id_ropcode == 0) {
        /* bltz */
        id_pc_src = (id_is_lez&&!id_is_zero)?PCSRC_BRANCH:PCSRC_PC4;
    } else if (id_opcode == 1 && id_ropcode == 1) {
        /* bgez */
        id_pc_src = (id_is_gtz||id_is_zero)?PCSRC_BRANCH:PCSRC_PC4;
    } else if (id_opcode == 1 && id_ropcode == 16) {
        /* bltzal */
        id_pc_src = (id_is_lez&&!id_is_zero)?PCSRC_BRANCH:PCSRC_PC4;
    } else if (id_opcode == 1 && id_ropcode == 17) {
        /* bgtzal */
        id_pc_src = (id_is_gtz||id_is_zero)?PCSRC_BRANCH:PCSRC_PC4;
    } else if (id_opcode == 2) {
        /* j */
        id_pc_src = PCSRC_JMP;
    } else if (id_opcode == 3) {
        /* jal */
        id_pc_src = PCSRC_JMP;
    } else if (id_opcode == 4) {
        /* beq */
        id_pc_src = id_is_equal ? PCSRC_BRANCH : PCSRC_PC4;
    } else if (id_opcode == 5) {
        /* bne */
        id_pc_src = !id_is_equal ? PCSRC_BRANCH : PCSRC_PC4;
    } else if (id_opcode == 6) {
        /* blez */
        id_pc_src = id_is_lez ? PCSRC_BRANCH : PCSRC_PC4;
    } else if (id_opcode == 7) {
        /* bgtz */
        id_pc_src = id_is_gtz ? PCSRC_BRANCH : PCSRC_PC4;
    } else {
        /* no branching */
        id_pc_src = PCSRC_PC4;
    }

    /* IF */
    if_pc4 = if_pc + 4;
    if_instr = tlb_read(0, if_pc, 2);

    /* coprocessor handling (on the falling edge) */
    if (if_exphndl && if_exception) {
        /* disable interrupts */
        SR <<= 2;
    } else if (id_is_rfe) {
        /* return from exception */
        SR = (SR & 0xFFFFFFF0)|((SR>>2)&0xF);
    } else if (wb_is_mtc0) {
        write_cop0_reg(wb_rk, wb_value_of_rk);
    } else {
        id_cop0_regrd = read_cop0_reg(id_rd);
    }

    /* handle exceptions (falling edge) */
    /* if exception conditions are satisfied, next cycle is
     * an exception fetch, and all stages before and including the
     * exception-source stage shall be flushed.
     */
    if (if_exphndl) {
        /* exception served */
        if_exception = 0;
        irq = 0;
        pic_iak();
    } else if (irq && (SR&1) && !if_exception) {
        /* IRQ happened! */
        if_exception = 1;
        if (id_is_jr || id_is_jalr ||
            is_branchregimm(id_opcode) ||
            is_jmp(id_opcode) ||
            is_branch(id_opcode)) {
            /* branch instruction in ID stage */
            EPC = id_pc;
            CAUSE = 0x80000000;
        } else {
            EPC = if_pc;
            CAUSE = 0x00000000;
        }
    }

    /* done */
    return 0;
}

/* signal initialization */
void cpu_init() {

    int i;

    /* instr_t info */
    cur_step = 0;

    /* IF */
    if_pc = 0xBFC00000;
    if_pc4 = if_pc+4;
    if_instr = tlb_read(0, if_pc, 2);
    if_exphndl = 0;
    if_exception = 0;

    /* ID */
    id_rs = 0;
    id_rt = 0;
    id_pc = 0;
    id_pc4 = 0;
    id_imm32 = 0;
    id_shl = 0;
    id_braddr = 0;
    id_val_of_rs = 0;
    id_val_of_rt = 0;
    id_cop0_regrd = 0;
    id_is_equal = 0;
    id_is_mfc0 = 0;
    id_is_mtc0 = 0;
    id_is_rfe = 0;
    id_is_cop0 = 0;
    id_pc_src = 0;
    id_if_flush = 0;
    id_ctrlsig_in[REG_DEST] = 0;
    id_ctrlsig_in[ALU_SRC] = 0;
    id_ctrlsig_in[MEM_TO_REG] = 0;
    id_ctrlsig_in[REG_WRITE] = 0;
    id_ctrlsig_in[MEM_READ] = 0;
    id_ctrlsig_in[MEM_WRITE] = 0;
    id_ctrlsig_in[BRANCH] = 0;
    id_ctrlsig[REG_DEST] = 0;
    id_ctrlsig[ALU_SRC] = 0;
    id_ctrlsig[MEM_TO_REG] = 0;
    id_ctrlsig[REG_WRITE] = 0;
    id_ctrlsig[MEM_READ] = 0;
    id_ctrlsig[MEM_WRITE] = 0;
    id_ctrlsig[BRANCH] = 0;
    id_stall = 0; /* hazard outputs */
    id_ifclk = 1; /* hazard outputs */
    id_pcclk = 1; /* hazard outputs */
    id_exception = 0;
    for (i = 0; i < 32; i++)
        id_regfile[i] = 0;

    /* EX */
    ex_rt = 0;
    ex_rd = 0;
    ex_ctrlsig[REG_DEST] = 0;
    ex_ctrlsig[ALU_SRC] = 0;
    ex_ctrlsig[MEM_TO_REG] = 0;
    ex_ctrlsig[REG_WRITE] = 0;
    ex_ctrlsig[MEM_READ] = 0;
    ex_ctrlsig[MEM_WRITE] = 0;
    ex_ctrlsig[BRANCH] = 0;
    ex_val_of_rs = 0;
    ex_val_of_rt = 0;
    ex_imm32 = 0;
    ex_fu_mux1 = 0; /* forwarding unit selector for mux1 */
    ex_fu_mux2 = 0; /* forwarding unit selector for mux2 */
    ex_alu1 = 0; /* input 1 for ALU */
    ex_muxop = 0;
    ex_alu2 = 0; /* input 2 for ALU */
    ex_alu_output = 0; /* output of ALU */
    ex_rk = 0; /* output of forth mux */
    ex_is_mfc0 = 0;
    ex_is_mtc0 = 0;
    ex_exception = 0;

    /* MEM */
    mem_ctrlsig[REG_DEST] = 0;
    mem_ctrlsig[ALU_SRC] = 0;
    mem_ctrlsig[MEM_TO_REG] = 0;
    mem_ctrlsig[REG_WRITE] = 0;
    mem_ctrlsig[MEM_READ] = 0;
    mem_ctrlsig[MEM_WRITE] = 0;
    mem_ctrlsig[BRANCH] = 0;
    mem_tmp = 0;
    mem_addr = 0;
    mem_data_in = 0;
    mem_data_out = 0;
    mem_rk = 0;
    mem_is_mfc0 = 0;
    mem_is_mtc0 = 0;
    mem_exception = 0;

    /* WB */
    wb_ctrlsig[REG_DEST] = 0;
    wb_ctrlsig[ALU_SRC] = 0;
    wb_ctrlsig[MEM_TO_REG] = 0;
    wb_ctrlsig[REG_WRITE] = 0;
    wb_ctrlsig[MEM_READ] = 0;
    wb_ctrlsig[MEM_WRITE] = 0;
    wb_ctrlsig[BRANCH] = 0;
    wb_mem_out = 0;
    wb_alu_out = 0;
    wb_value_of_rk = 0;
    wb_rk = 0;
    wb_is_mfc0 = 0;
    wb_is_mtc0 = 0;
    wb_exception = 0;

    /* coprocessor */
    SR = 0;
    CAUSE = 0;
    EPC = 0;
    irq = 0;

}
