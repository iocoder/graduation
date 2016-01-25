#
#        +----------------------------------------------------------+
#        | +------------------------------------------------------+ |
#        | |  NES Over MIPS Emulator.                             | |
#        | |  -> 6502 CPU Emulation Code.                         | |
#        | +------------------------------------------------------+ |
#        +----------------------------------------------------------+
#
# This file is part of Quafios 2.0.1 source code.
# Copyright (C) 2016  Mostafa Abd El-Aziz Mohamed.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Quafios.  If not, see <http://www.gnu.org/licenses/>.
#
# Visit http://www.quafios.com/ for contact information.
#

.include  "common.inc"
.global   cpu_cycle, reset, instr
.set      debug_enabled, 0
.set      count_enabled, 0

## REGISTER MAP:
## -------------
## s0: pc
## s1: a
## s2: x
## s3: y
## s4: p
## s6: mar
## s7: s
## s5: base1
## s8: base2
## t6: '1'
## t5: &read_instr
## t4: &fetch

# set zero/negative flags macro
.macro     zeron      reg
    andi   $s4, $s4,  0x7D
    sltu   $t2, \reg, $t6  # t2 = reg<1 ? 1:0
    sll    $t2, $t2,  1
    or     $s4, $s4,  $t2
    andi   $t2, \reg, 0x80
    or     $s4, $s4,  $t2
.endm

###################################################
#               SECTION: TEXT                     #
###################################################

.text

################################################
#                   reset                      #
# ---------------------------------------------#
# Summary: CPU RESET procedure.                #
# ---------------------------------------------#
# Called by: cpu_cycle                         #
# ---------------------------------------------#
# Next call: fetch                             #
################################################

reset:
    # initialize reserved registers
    lui    $s5, %hi(base1)
    addiu  $s5, $s5, %lo(base1)
    lui    $s8, %hi(base2)
    addiu  $s8, $s8, %lo(base2)
    ori    $t6, $0, 1
    lui    $t5, %hi(rom_instr)
    addiu  $t5, $t5, %lo(rom_instr)
    lui    $t4, %hi(fetch)
    addiu  $t4, $t4, %lo(fetch)
    # register ISR
    lw     $t0, 0x14*4($gp)
    lui    $t1, %hi(isr)
    ori    $t1, $t1, %lo(isr)
    sw     $t1, 3*4($t0)
    # initialize 6502 registers
    ori    $s7, $0, 0xFF
    # read reset vector [PC=ROM[0xFFFC]+(ROM[0xFFFD]<<8)]
    ori    $a0, $0,  0xFFFC
    jal    mem_read
    move   $s0, $v0
    ori    $a0, $0,  0xFFFD
    jal    mem_read
    sll    $v0, $v0, 8
    addu   $s0, $s0, $v0
    j      fetch

################################################
#                    nmi                       #
# ---------------------------------------------#
# Summary: handle NMI signal                   #
# ---------------------------------------------#
# Called by: cpu_cycle                         #
# ---------------------------------------------#
# Next call: fetch                             #
################################################

nmi:
    # push PC
    addiu  $a0, $s7, 0x0FF
    move   $a1, $s0
    jal    ram_write2
    # decrease stack ptr
    addiu  $s7, $s7, -2
    andi   $s7, $s7, 0xFF
    # push P
    addiu  $a0, $s7, 0x100
    move   $a1, $s4
    jal    ram_write
    # decrease stack ptr
    addiu  $s7, $s7, -1
    andi   $s7, $s7, 0xFF
    # set interrupt disable flag
    ori    $s4, 0x04
    # read interrupt vector
    ori    $a0, $0,  0xFFFA
    jal    mem_read2
    move   $s0, $v0
    # reset t5
    srl    $t0, $s0, 11
    andi   $t0, $t0, 28
    addu   $t5, $s5, $t0
    lw     $t5, %lo(__instr_routines)($t5)
    # reset t4
    lui    $t4, %hi(fetch)
    addiu  $t4, $t4, %lo(fetch)
    # fetch next instruction
    j      fetch

################################################
#                    isr                       #
# ---------------------------------------------#
# Summary: ISR handler                         #
# ---------------------------------------------#
# Called by: ISR                               #
# ---------------------------------------------#
# Next call: return to ISR                     #
################################################

isr:
    # a0 has ptr to register frame in stack
    lui    $t0, %hi(nmi)
    addiu  $t0, $t0, %lo(nmi)
    sw     $t0, 12*4($a0)  # set t4 to nmi
    jr     $ra

################################################
#                  fetch                       #
# ---------------------------------------------#
# Summary: Fetch next instruction and increase #
#          PC register by 1.                   #
# ---------------------------------------------#
# Called by: cpu_cycle or <isr>                #
# ---------------------------------------------#
# Next call: <address>                         #
################################################

fetch:
    # debugging info
.if count_enabled
    lui   $t0, 0x1E00
    ori   $t1, $0, 1
    sh    $t1,  0xFF8*2($t0)
.endif
.if debug_enabled
    jal   debug
.endif
    # fetch opcode
    move   $a0, $s0
    addiu  $s0, $s0, 1
    jalr   $t5
    # jump to addressing mode routine
    sll    $v0, $v0, 3
    addu   $v0, $v0, $s5
    lw     $t2, %lo(__instr)+4($v0)
    lw     $t3, %lo(__instr)($v0) # placed in delay slot of jr
    jr     $t2

################################################
#                   debug                      #
# ---------------------------------------------#
# Summary: Print CPU state and disassemble     #
#          running instructions for debugging. #
# ---------------------------------------------#
# Called by: cpu_cycle                         #
# ---------------------------------------------#
# Next call: fetch                             #
################################################

.if debug_enabled
debug:
    # print cpu state if debugging is enabled
    pusha
    lui   $t0, %hi(cur_step)
    lw    $t1, %lo(cur_step)($t0)
    beq   $t1, $0, 1f
    ls    $a0, "| MAR=$%4x | A=$%2x, X=$%2x, "
    move  $a1, $s6
    move  $a2, $s1
    move  $a3, $s2
    bios  printf
    ls    $a0, "Y=$%2x, S=$%2x, P=$%2x\n"
    move  $a1, $s3
    move  $a2, $s7
    move  $a3, $s4
    bios  printf
    #bios  getc
    # enough simulation for today?
1:  #lui   $t0, 0x0000
    #ori   $t0, $t0, 0x8000
    #bne   $t0, $t1, 2f
    #j     .
    # get instruction name
2:  move  $a0, $s0
    jal   mem_read
    lui   $t0, %hi(str)
    sll   $t1, $v0, 3
    addu  $t0, $t0, $t1
    lw    $a2, %lo(str)($t0)
    lw    $t2, %lo(str)+4($t0)
    # PC shall be printed, too.
    move  $a1, $s0
    # load format string
    ls    $a0, "$%4x | %s "
    # now print
    bios  printf
    # load two bytes following PC
    addiu $a0, $s0, 1
    jal   mem_read
    move  $t1, $v0
    addiu $a0, $s0, 2
    jal   mem_read
    move  $a2, $t1
    move  $a1, $v0
    # get format string for addressing mode
    move  $a0, $t2
    # now print
    bios  printf
    # increase cur_step
    lui   $t0, %hi(cur_step)
    lw    $t1, %lo(cur_step)($t0)
    addiu $t1, $t1, 1
    sw    $t1, %lo(cur_step)($t0)
    popa
    jr    $ra
.endif

################################################
#                   imm                        #
# ---------------------------------------------#
# Summary: Immediate addressing mode.          #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

imm:
    # immediate
    move   $v0, $v1
    addiu  $s0, $s0, 1
    # jump to instruction code
    jr     $t3

################################################
#                   abs                        #
# ---------------------------------------------#
# Summary: Absolute addressing mode.           #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

abs:
    # absolute address
    addiu  $s0, $s0, 2
    move   $s6, $a1
    # jump to instruction code
    jr     $t3

################################################
#                   zp                         #
# ---------------------------------------------#
# Summary: Zero page addressing mode.          #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

zp:
    # zero page address
    move   $s6, $v1
    addiu  $s0, $s0, 1
    # jump to instruction code
    jr     $t3

################################################
#                   acc                        #
# ---------------------------------------------#
# Summary: Accumulator addressing mode.        #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

acc:
    # accumulator
    addiu  $s6, $0, -1
    move   $v0, $s1
    # jump to instruction code
    jr     $t3

################################################
#                   imp                        #
# ---------------------------------------------#
# Summary: Implied addressing mode.            #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

imp:
    # implied addressing
    nop
    # jump to instruction code
    jr     $t3

################################################
#                   idir                       #
# ---------------------------------------------#
# Summary: Indexed indirect addressing mode.   #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

idir:
    # indexed indirect (ind, x)
    addiu  $s0, $s0, 1
    # v1 contains second byte of instruction. Add to X.
    addu   $v1, $v1, $s2
    andi   $a0, $v1, 0xFF
    # now a0 points to a memory location in page zero holding the address
    jal    ram_read2
    move   $s6, $v0
    # jump to instruction code
    jr     $t3

################################################
#                   dind                       #
# ---------------------------------------------#
# Summary: Indirect indexed addressing mode.   #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

dind:
    # indirect indexed (ind), Y
    addiu  $s0, $s0, 1
    # v1 contains second byte of instruction. This byte points
    # to a memory location in page zero holding the base address.
    move   $a0, $v1
    jal    ram_read2
    # add Y, store in MAR
    addu   $s6, $v0, $s3
    # jump to instruction code
    jr     $t3

################################################
#                   izx                        #
# ---------------------------------------------#
# Summary: X-indexed zero page addressing      #
#          mode.                               #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

izx:
    # zero page indexed by X 'zr, X'
    addiu  $s0, $s0, 1
    addu   $s6, $s2, $v1
    andi   $s6, $s6, 0xFF
    # jump to instruction code
    jr     $t3

################################################
#                   iax                        #
# ---------------------------------------------#
# Summary: X-indexed absolute addressing mode. #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

iax:
    # indexed absolute X 'Abs, X'
    addiu  $s0, $s0, 2
    addu   $s6, $a1, $s2
    andi   $s6, $s6, 0xFFFF
    # jump to instruction code
    jr     $t3

################################################
#                   iay                        #
# ---------------------------------------------#
# Summary: Y-indexed absolute addressing mode. #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

iay:
    # indexed absolute Y 'Abs, Y'
    addiu  $s0, $s0, 2
    addu   $s6, $a1, $s3
    andi   $s6, $s6, 0xFFFF
    # jump to instruction code
    jr     $t3

################################################
#                   rel                        #
# ---------------------------------------------#
# Summary: Relative addressing mode.           #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

rel:
    # relative addressing
    # v1 contains second byte of instruction. sign extend the byte
    sll    $v1, $v1, 24
    sra    $v1, $v1, 24
    andi   $v1, $v1, 0xFFFF
    addu   $s0, $s0, $v1
    # next cycle
    jr     $t4

################################################
#                   absd                       #
# ---------------------------------------------#
# Summary: Absolute indirect addressing mode.  #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

absd:
    # absolute indirect
    addiu  $s0, $s0, 2
    move   $a0, $a1
    jal    mem_read2
    # only one instruction is absd: jmp
    move   $s6, $v0
    jr     $t3

################################################
#                   izy                        #
# ---------------------------------------------#
# Summary: Y-indexed zero page addressing      #
#          mode.                               #
# ---------------------------------------------#
# Called by: fetch                             #
# ---------------------------------------------#
# Next call: <instr>                           #
################################################

izy:
    # zero page indexed by Y 'zr, Y'
    addiu  $s0, $s0, 1
    addu   $s6, $s3, $v1
    andi   $s6, $s6, 0xFF
    # jump to instruction code
    jr     $t3

################################################
#                   adc                        #
# ---------------------------------------------#
# Summary: 6502 add with carry instruction.    #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

adc:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # load previous carry
adc_imm:
    # get previous carry
    andi   $t1, $s4, 1
    # reset P flags
    andi   $s4, $s4, 0x3C
    # add to accumulator
    add    $s1, $s1, $t1
    add    $s1, $s1, $v0
    # store carry in P
    srl    $t2, $s1, 8
    or     $s4, $s4, $t2
    # make sure there are no extra bits in accumulator
    andi   $s1, $s1, 0xFF
    # store zero and N flag
    zeron  $s1
    # fetch next instruction
    jr     $t4

################################################
#                   and                        #
# ---------------------------------------------#
# Summary: 6502 bitwise and instruction.       #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

and:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # and with A
and_imm:
    and    $s1, $s1, $v0
    # store zero and N flag
    zeron  $s1
    # fetch next instruction
    jr     $t4

################################################
#                   asl                        #
# ---------------------------------------------#
# Summary: 6502 shift left instruction.        #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

asl:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # store higher bit in carry
    srl    $t1, $v0, 7
    and    $t1, $t1, 1
    and    $s4, $s4, 0xFE
    or     $s4, $s4, $t1
    # now shift left by 1
    sll    $t1, $v0, 1
    andi   $t1, $t1, 0xFF
    # store result in memory
    move   $a0, $s6
    move   $a1, $t1
    jal    mem_write
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

asl_acc:
    # store higher bit in carry
    srl    $t1, $v0, 7
    and    $t1, $t1, 1
    and    $s4, $s4, 0xFE
    or     $s4, $s4, $t1
    # now shift left by 1
    sll    $t1, $v0, 1
    andi   $t1, $t1, 0xFF
    # store result in accumulator
    move   $s1, $t1
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

################################################
#                   bcc                        #
# ---------------------------------------------#
# Summary: 6502 branch if carry clear.         #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

bcc:
    # branch on carry clear
    addiu  $s0, $s0, 1
    andi   $t0, $s4, 0x01
    beq    $t0, $0,  rel
    jr     $t4

################################################
#                   bcs                        #
# ---------------------------------------------#
# Summary: 6502 branch if carry set.           #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

bcs:
    # branch on carry set
    addiu  $s0, $s0, 1
    andi   $t0, $s4, 0x01
    bne    $t0, $0,  rel
    jr     $t4

################################################
#                   beq                        #
# ---------------------------------------------#
# Summary: 6502 branch if zero set.            #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

beq:
    # branch on zero set
    addiu  $s0, $s0, 1
    andi   $t0, $s4, 0x02
    bne    $t0, $0,  rel
    jr     $t4

################################################
#                   bit                        #
# ---------------------------------------------#
# Summary: 6502 bit instruction.               #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

bit:
    # fetch next instruction
    jr     $t4

################################################
#                   bmi                        #
# ---------------------------------------------#
# Summary: 6502 branch if negative set.        #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

bmi:
    # branch on negative set
    addiu  $s0, $s0, 1
    andi   $t0, $s4, 0x80
    bne    $t0, $0,  rel
    jr     $t4

################################################
#                   bne                        #
# ---------------------------------------------#
# Summary: 6502 branch if zero clear.          #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

bne:
    # branch on zero clear
    addiu  $s0, $s0, 1
    andi   $t0, $s4, 0x02
    beq    $t0, $0,  rel
    jr     $t4

################################################
#                   bpl                        #
# ---------------------------------------------#
# Summary: 6502 branch if negative clear.      #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

bpl:
    # branch on negative clear
    addiu  $s0, $s0, 1
    andi   $t0, $s4, 0x80
    beq    $t0, $0,  rel
    jr     $t4

################################################
#                   brk                        #
# ---------------------------------------------#
# Summary: 6502 break instruction.             #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

brk:
    break
    # fetch next instruction
    jr     $t4

################################################
#                   bvc                        #
# ---------------------------------------------#
# Summary: 6502 branch if overflow clear       #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

bvc:
    # branch on overflow clear
    addiu  $s0, $s0, 1
    andi   $t0, $s4, 0x40
    beq    $t0, $0,  rel
    jr     $t4

################################################
#                   bvs                        #
# ---------------------------------------------#
# Summary: 6502 branch if overflow set         #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

bvs:
    # branch on overflow set
    addiu  $s0, $s0, 1
    andi   $t0, $s4, 0x40
    bne    $t0, $0,  rel
    jr     $t4

################################################
#                   clc                        #
# ---------------------------------------------#
# Summary: 6502 clear carry instruction.       #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

clc:
    # clear carry flag
    andi   $s4, $s4, 0xFE
    # fetch next instruction
    jr     $t4

################################################
#                   cld                        #
# ---------------------------------------------#
# Summary: 6502 clear decimal instruction.     #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

cld:
    # clear decimal-mode flag
    andi   $s4, $s4, 0xF7
    # fetch next instruction
    jr     $t4

################################################
#                   cli                        #
# ---------------------------------------------#
# Summary: 6502 clear interrupt instruction.   #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

cli:
    # clear interrupt flag
    andi   $s4, $s4, 0xFB
    # fetch next instruction
    jr     $t4

################################################
#                   clv                        #
# ---------------------------------------------#
# Summary: 6502 clear overflow instruction.    #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

clv:
    # clear overflow flag
    andi   $s4, $s4, 0xBF
    # fetch next instruction
    jr     $t4

################################################
#                   cmp                        #
# ---------------------------------------------#
# Summary: 6502 compare A instruction.         #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

cmp:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # subtract M from A
cmp_imm:
    subu   $t1, $s1, $v0
    # reset P flags
    andi   $s4, $s4, 0x3C
    # store borrow (carry complement) in P
    srl    $t2, $t1, 8
    andi   $t2, $t2, 1
    xor    $t2, $t2, 1
    or     $s4, $s4, $t2
    # make sure no extra bits in result
    andi   $t1, $t1, 0xFF
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

################################################
#                   cpx                        #
# ---------------------------------------------#
# Summary: 6502 compare X instruction.         #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

cpx:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # subtract M from X
cpx_imm:
    subu   $t1, $s2, $v0
    # reset P flags
    andi   $s4, $s4, 0x3C
    # store borrow (carry complement) in P
    srl    $t2, $t1, 8
    andi   $t2, $t2, 1
    xor    $t2, $t2, 1
    or     $s4, $s4, $t2
    # make sure no extra bits in result
    andi   $t1, $t1, 0xFF
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

################################################
#                   cpy                        #
# ---------------------------------------------#
# Summary: 6502 compare Y instruction.         #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

cpy:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # subtract M from Y
cpy_imm:
    subu   $t1, $s3, $v0
    # reset P flags
    andi   $s4, $s4, 0x3C
    # store borrow (carry complement) in P
    srl    $t2, $t1, 8
    andi   $t2, $t2, 1
    xor    $t2, $t2, 1
    or     $s4, $s4, $t2
    # make sure no extra bits in result
    andi   $t1, $t1, 0xFF
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

################################################
#                   dec                        #
# ---------------------------------------------#
# Summary: 6502 decrement instruction.         #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

dec:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # decrease the byte
    addiu  $t1, $v0, -1
    andi   $t1, $t1, 0xFF
    # perform memory write
    move   $a0, $s6
    move   $a1, $t1
    jal    mem_write
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

################################################
#                   dex                        #
# ---------------------------------------------#
# Summary: 6502 X decrement instruction.       #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

dex:
    # decrease X
    addiu  $s2, $s2, -1
    andi   $s2, $s2, 0xFF
    # store zero and N flag
    zeron  $s2
    # fetch next instruction
    jr     $t4

################################################
#                   dey                        #
# ---------------------------------------------#
# Summary: 6502 Y decrement instruction.       #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

dey:
    # decrease Y
    addiu  $s3, $s3, -1
    andi   $s3, $s3, 0xFF
    # store zero and N flag
    zeron  $s3
    # fetch next instruction
    jr     $t4

################################################
#                   eor                        #
# ---------------------------------------------#
# Summary: 6502 exclusive or instruction.      #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

eor:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
eor_imm:
    # xor with A
    xor    $s1, $s1, $v0
    # store zero and N flag
    zeron  $s1
    # fetch next instruction
    jr     $t4

################################################
#                   inc                        #
# ---------------------------------------------#
# Summary: 6502 increment instruction.         #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

inc:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # increase the byte
    addiu  $t1, $v0, 1
    andi   $t1, $t1, 0xFF
    # perform memory write
    move   $a0, $s6
    move   $a1, $t1
    jal    mem_write
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

################################################
#                   inx                        #
# ---------------------------------------------#
# Summary: 6502 X-increment instruction.       #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

inx:
    # increase X
    addiu  $s2, $s2, 1
    andi   $s2, $s2, 0xFF
    # store zero and N flag
    zeron  $s2
    # fetch next instruction
    jr     $t4

################################################
#                   iny                        #
# ---------------------------------------------#
# Summary: 6502 Y-increment instruction.       #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

iny:
    # increase Y
    addiu  $s3, $s3, 1
    andi   $s3, $s3, 0xFF
    # store zero and N flag
    zeron  $s3
    # fetch next instruction
    jr     $t4

################################################
#                   jmp                        #
# ---------------------------------------------#
# Summary: 6502 jump instruction.              #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

jmp:
    # move MAR into PC
    move   $s0, $s6
    # reset t5
    srl    $t0, $s0, 11
    andi   $t0, $t0, 28
    addu   $t5, $s5, $t0
    lw     $t5, %lo(__instr_routines)($t5)
    # fetch next instruction
    jr     $t4

################################################
#                   jsr                        #
# ---------------------------------------------#
# Summary: 6502 jump subroutine instruction.   #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

jsr:
    # push PC-1
    addiu  $a0, $s7, 0x0FF
    addiu  $a1, $s0, -1
    jal    ram_write2
    # decrease stack ptr
    addiu  $s7, $s7, -2
    andi   $s7, $s7, 0xFF
    # jmp to new location
    move   $s0, $s6
    # reset t5
    srl    $t0, $s0, 11
    andi   $t0, $t0, 28
    addu   $t5, $s5, $t0
    lw     $t5, %lo(__instr_routines)($t5)
    # fetch next instruction
    jr     $t4

################################################
#                   lda                        #
# ---------------------------------------------#
# Summary: 6502 load A instruction.            #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

lda:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # load result into X
lda_imm:
    move   $s1, $v0
    # store zero and N flag
    zeron  $s1
    # fetch next instruction
    jr     $t4

################################################
#                   ldx                        #
# ---------------------------------------------#
# Summary: 6502 load X instruction.            #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

ldx:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # load result into X
ldx_imm:
    move   $s2, $v0
    # store zero and N flag
    zeron  $s2
    # fetch next instruction
    jr     $t4

################################################
#                   ldy                        #
# ---------------------------------------------#
# Summary: 6502 load Y instruction.            #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

ldy:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # load result into X
ldy_imm:
    move   $s3, $v0
    # store zero and N flag
    zeron  $s3
    # fetch next instruction
    jr     $t4

################################################
#                   lsr                        #
# ---------------------------------------------#
# Summary: 6502 shift right instruction.       #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

lsr:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # store lower bit in carry
    and    $t1, $v0, 1
    and    $s4, $s4, 0xFE
    or     $s4, $s4, $t1
    # now shift right by 1
    srl    $t1, $v0, 1
    andi   $t1, $t1, 0x7F
    # store result in memory
    move   $a0, $s6
    move   $a1, $t1
    jal    mem_write
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

lsr_acc:
    # store lower bit in carry
    and    $t1, $v0, 1
    and    $s4, $s4, 0xFE
    or     $s4, $s4, $t1
    # now shift right by 1
    srl    $t1, $v0, 1
    andi   $t1, $t1, 0x7F
    # store result in memory
    move   $s1, $t1
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

################################################
#                   nop                        #
# ---------------------------------------------#
# Summary: 6502 no-operation instruction.      #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

nop:
    # fetch next instruction
    jr     $t4

################################################
#                   ora                        #
# ---------------------------------------------#
# Summary: 6502 inclusive or instruction.      #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

ora:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
ora_imm:
    # or with A
    or     $s1, $s1, $v0
    # store zero and N flag
    zeron  $s1
    # fetch next instruction
    jr     $t4

################################################
#                   pha                        #
# ---------------------------------------------#
# Summary: 6502 push A instruction.            #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

pha:
    # push A
    addiu  $a0, $s7, 0x100
    move   $a1, $s1
    jal    ram_write
    addiu  $s7, $s7, -1
    andi   $s7, $s7, 0xFF
    # fetch next instruction
    jr     $t4

################################################
#                   php                        #
# ---------------------------------------------#
# Summary: 6502 push P instruction.            #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

php:
    # push P
    addiu  $a0, $s7, 0x100
    move   $a1, $s4
    jal    ram_write
    addiu  $s7, $s7, -1
    andi   $s7, $s7, 0xFF
    # fetch next instruction
    jr     $t4

################################################
#                   pla                        #
# ---------------------------------------------#
# Summary: 6502 pull A instruction.            #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

pla:
    # pull A
    addiu  $s7, $s7, 1
    andi   $s7, $s7, 0xFF
    addiu  $a0, $s7, 0x100
    jal    ram_read
    move   $s1, $v0
    # store zero and N flag
    zeron  $s1
    # fetch next instruction
    jr     $t4

################################################
#                   plp                        #
# ---------------------------------------------#
# Summary: 6502 pull P instruction.            #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

plp:
    # pull P
    addiu  $s7, $s7, 1
    andi   $s7, $s7, 0xFF
    addiu  $a0, $s7, 0x100
    jal    ram_read
    move   $s4, $v0
    # fetch next instruction
    jr     $t4

################################################
#                   rol                        #
# ---------------------------------------------#
# Summary: 6502 rotate left instruction.       #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

rol:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # shift left and insert carry
    sll    $t1, $v0, 1
    and    $t2, $s4, 1
    or     $t1, $t1, $t2
    andi   $t1, $t1, 0xFF
    # store higher bit in carry
    srl    $t2, $v0, 7
    and    $t2, $t2, 1
    and    $s4, $s4, 0xFE
    or     $s4, $s4, $t2
    # store result in memory
    move   $a0, $s6
    move   $a1, $t1
    jal    mem_write
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

rol_acc:
    # shift left and insert carry
    sll    $t1, $v0, 1
    and    $t2, $s4, 1
    or     $t1, $t1, $t2
    andi   $t1, $t1, 0xFF
    # store higher bit in carry
    srl    $t2, $v0, 7
    and    $t2, $t2, 1
    and    $s4, $s4, 0xFE
    or     $s4, $s4, $t2
    # store result in memory
    move   $s1, $t1
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

################################################
#                   ror                        #
# ---------------------------------------------#
# Summary: 6502 rotate right instruction.      #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

ror:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # shift right and insert carry
    srl    $t1, $v0, 1
    and    $t2, $s4, 1
    sll    $t2, $t2, 7
    or     $t1, $t1, $t2
    andi   $t1, $t1, 0xFF
    # store lower bit in carry
    and    $t2, $v0, 1
    and    $s4, $s4, 0xFE
    or     $s4, $s4, $t2
    # store result in memory
    move   $a0, $s6
    move   $a1, $t1
    jal    mem_write
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

ror_acc:
    # shift right and insert carry
    srl    $t1, $v0, 1
    and    $t2, $s4, 1
    sll    $t2, $t2, 7
    or     $t1, $t1, $t2
    andi   $t1, $t1, 0xFF
    # store lower bit in carry
    and    $t2, $v0, 1
    and    $s4, $s4, 0xFE
    or     $s4, $s4, $t2
    # store result in memory
    move   $s1, $t1
    # store zero and N flag
    zeron  $t1
    # fetch next instruction
    jr     $t4

################################################
#                   rti                        #
# ---------------------------------------------#
# Summary: 6502 return from interrupt.         #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

rti:
    # pull P
    addiu  $s7, $s7, 1
    andi   $s7, $s7, 0xFF
    addiu  $a0, $s7, 0x100
    jal    ram_read
    andi   $s4, $v0, 0xEF
    # pull PC
    addiu  $a0, $s7, 0x101
    addiu  $s7, $s7, 2
    jal    ram_read2
    move   $s0, $v0
    # reset t5
    srl    $t0, $s0, 11
    andi   $t0, $t0, 28
    addu   $t5, $s5, $t0
    lw     $t5, %lo(__instr_routines)($t5)
    # fetch next instruction
    jr     $t4

################################################
#                   rts                        #
# ---------------------------------------------#
# Summary: 6502 return from subroutine.        #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

rts:
    # pull PC-1
    addiu  $a0, $s7, 0x101
    addiu  $s7, $s7, 2
    jal    ram_read2
    addiu  $s0, $v0, 1
    # reset t5
    srl    $t0, $s0, 11
    andi   $t0, $t0, 28
    addu   $t5, $s5, $t0
    lw     $t5, %lo(__instr_routines)($t5)
    # fetch next instruction
    jr     $t4

################################################
#                   sbc                        #
# ---------------------------------------------#
# Summary: 6502 sub with carry instruction.    #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

sbc:
    # perform memory read
    move   $a0, $s6
    jal    mem_read
    # load previous not carry (borrow)
sbc_imm:
    andi   $t1, $s4, 1
    xor    $t1, $t1, 1
    # add borrow to M, sub result from A
    add    $t1, $t1, $v0
    sub    $s1, $s1, $t1
    # reset P flags
    andi   $s4, $s4, 0x3C
    # store not borrow (carry) in P
    srl    $t2, $s1, 8
    and    $t2, $t2, 1
    xor    $t2, $t2, 1
    or     $s4, $s4, $t2
    # make sure no extra bits in accumulator
    andi   $s1, $s1, 0xFF
    # store zero and N flag
    zeron  $s1
    # fetch next instruction
    jr     $t4

################################################
#                   sec                        #
# ---------------------------------------------#
# Summary: 6502 set carry instruction.         #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

sec:
    # set carry flag
    ori    $s4, $s4, 0x01
    # fetch next instruction
    jr     $t4

################################################
#                   sed                        #
# ---------------------------------------------#
# Summary: 6502 set decimal instruction.       #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

sed:
    # set decimal-mode flag
    ori    $s4, $s4, 0x08
    # fetch next instruction
    jr     $t4

################################################
#                   sei                        #
# ---------------------------------------------#
# Summary: 6502 set interrupt instruction.     #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

sei:
    # set decimal-mode flag
    ori    $s4, $s4, 0x04
    # fetch next instruction
    jr     $t4

################################################
#                   sta                        #
# ---------------------------------------------#
# Summary: 6502 store A instruction.           #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

sta:
    # write A to memory
    move   $a0, $s6
    move   $a1, $s1
    jal    mem_write
    # fetch next instruction
    jr     $t4

################################################
#                   stx                        #
# ---------------------------------------------#
# Summary: 6502 store X instruction.           #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

stx:
    # write X to memory
    move   $a0, $s6
    move   $a1, $s2
    jal    mem_write
    # fetch next instruction
    jr     $t4

################################################
#                   sty                        #
# ---------------------------------------------#
# Summary: 6502 store Y instruction.           #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

sty:
    # write Y to memory
    move   $a0, $s6
    move   $a1, $s3
    jal    mem_write
    # fetch next instruction
    jr     $t4

################################################
#                   tax                        #
# ---------------------------------------------#
# Summary: 6502 transfer A to X instruction.   #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

tax:
    # load A into X
    move   $s2, $s1
    # store zero and N flag
    zeron  $s2
    # fetch next instruction
    jr     $t4

################################################
#                   tay                        #
# ---------------------------------------------#
# Summary: 6502 transfer A to Y instruction.   #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

tay:
    # load A into Y
    move   $s3, $s1
    # store zero and N flag
    zeron  $s3
    # fetch next instruction
    jr     $t4

################################################
#                   tsx                        #
# ---------------------------------------------#
# Summary: 6502 transfer S to X instruction.   #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

tsx:
    # load S into X
    move   $s2, $s7
    # store zero and N flag
    zeron  $s2
    # fetch next instruction
    jr     $t4

################################################
#                   txa                        #
# ---------------------------------------------#
# Summary: 6502 transfer X to A instruction.   #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

txa:
    # load X into A
    move   $s1, $s2
    # store zero and N flag
    zeron  $s1
    # fetch next instruction
    jr     $t4

################################################
#                   txs                        #
# ---------------------------------------------#
# Summary: 6502 transfer X to S instruction.   #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

txs:
    # load X into S
    move   $s7, $s2
    # fetch next instruction
    jr     $t4

################################################
#                   tya                        #
# ---------------------------------------------#
# Summary: 6502 transfer Y to A instruction.   #
# ---------------------------------------------#
# Called by: <addr>                            #
# ---------------------------------------------#
# Next call: cpu_cycle                         #
################################################

tya:
    # load Y into A
    move   $s1, $s3
    # store zero and N flag
    zeron  $s1
    # fetch next instruction
    jr     $t4

###################################################
#              SECTION: RODATA                    #
###################################################

.section "rodata", "a"

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# instruction names (for debugging/disassembling)
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

.if debug_enabled
_adc: .string "adc"
_and: .string "and"
_asl: .string "asl"
_bcc: .string "bcc"
_bcs: .string "bcs"
_beq: .string "beq"
_bit: .string "bit"
_bmi: .string "bmi"
_bne: .string "bne"
_bpl: .string "bpl"
_brk: .string "brk"
_bvc: .string "bvc"
_bvs: .string "bvs"
_clc: .string "clc"
_cld: .string "cld"
_cli: .string "cli"
_clv: .string "clv"
_cmp: .string "cmp"
_cpx: .string "cpx"
_cpy: .string "cpy"
_dec: .string "dec"
_dex: .string "dex"
_dey: .string "dey"
_eor: .string "eor"
_inc: .string "inc"
_inx: .string "inx"
_iny: .string "iny"
_jmp: .string "jmp"
_jsr: .string "jsr"
_lda: .string "lda"
_ldx: .string "ldx"
_ldy: .string "ldy"
_lsr: .string "lsr"
_nop: .string "nop"
_ora: .string "ora"
_pha: .string "pha"
_php: .string "php"
_pla: .string "pla"
_plp: .string "plp"
_rol: .string "rol"
_ror: .string "ror"
_rti: .string "rti"
_rts: .string "rts"
_sbc: .string "sbc"
_sec: .string "sec"
_sed: .string "sed"
_sei: .string "sei"
_sta: .string "sta"
_stx: .string "stx"
_sty: .string "sty"
_tax: .string "tax"
_tay: .string "tay"
_tsx: .string "tsx"
_txa: .string "txa"
_txs: .string "txs"
_tya: .string "tya"
.endif

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# instruction formats (for debugging/disassembling)
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

.if debug_enabled
_imm:  .string "#$%0X%2X      "
_abs:  .string "$%2X%2X     "
_zp:   .string "$%0X%2X       "
_acc:  .string "          "
_imp:  .string "          "
_idir: .string "idir      "
_dind: .string "($%0X%2X),y   "
_izx:  .string "izx       "
_iax:  .string "$%2X%2X,x   "
_iay:  .string "$%2X%2X,y   "
_rel:  .string "$%0X%2X       "
_absd: .string "($%2X%2X)   "
_izy:  .string "izy       "
.endif

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# pointers to instruction routines and addressing mode routines
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

instr:
/* $00 */ .word brk, brk
/* $01 */ .word ora, idir
/* $02 */ .word 0,   0
/* $03 */ .word 0,   0
/* $04 */ .word 0,   0
/* $05 */ .word ora, zp
/* $06 */ .word asl, zp
/* $07 */ .word 0,   0
/* $08 */ .word php, php
/* $09 */ .word ora_imm, imm
/* $0A */ .word asl_acc, acc
/* $0B */ .word 0,   0
/* $0C */ .word 0,   0
/* $0D */ .word ora, abs
/* $0E */ .word asl, abs
/* $0F */ .word 0,   0
/* $10 */ .word bpl, bpl
/* $11 */ .word ora, dind
/* $12 */ .word 0,   0
/* $13 */ .word 0,   0
/* $14 */ .word 0,   0
/* $15 */ .word ora, izx
/* $16 */ .word asl, izx
/* $17 */ .word 0,   0
/* $18 */ .word clc, clc
/* $19 */ .word ora, iay
/* $1A */ .word 0,   0
/* $1B */ .word 0,   0
/* $1C */ .word 0,   0
/* $1D */ .word ora, iax
/* $1E */ .word asl, iax
/* $1F */ .word 0,   0
/* $20 */ .word jsr, abs
/* $21 */ .word and, idir
/* $22 */ .word 0,   0
/* $23 */ .word 0,   0
/* $24 */ .word bit, zp
/* $25 */ .word and, zp
/* $26 */ .word rol, zp
/* $27 */ .word 0,   0
/* $28 */ .word plp, plp
/* $29 */ .word and_imm, imm
/* $2A */ .word rol_acc, acc
/* $2B */ .word 0,   0
/* $2C */ .word bit, abs
/* $2D */ .word and, abs
/* $2E */ .word rol, abs
/* $2F */ .word 0,   0
/* $30 */ .word bmi, bmi
/* $31 */ .word and, dind
/* $32 */ .word 0,   0
/* $33 */ .word 0,   0
/* $34 */ .word 0,   0
/* $35 */ .word and, izx
/* $36 */ .word rol, izx
/* $37 */ .word 0,   0
/* $38 */ .word sec, sec
/* $39 */ .word and, iay
/* $3A */ .word 0,   0
/* $3B */ .word 0,   0
/* $3C */ .word 0,   0
/* $3D */ .word and, iax
/* $3E */ .word rol, iax
/* $3F */ .word 0,   0
/* $40 */ .word rti, rti
/* $41 */ .word eor, idir
/* $42 */ .word 0,   0
/* $43 */ .word 0,   0
/* $44 */ .word 0,   0
/* $45 */ .word eor, zp
/* $46 */ .word lsr, zp
/* $47 */ .word 0,   0
/* $48 */ .word pha, pha
/* $49 */ .word eor_imm, imm
/* $4A */ .word lsr_acc, acc
/* $4B */ .word 0,   0
/* $4C */ .word jmp, abs
/* $4D */ .word eor, abs
/* $4E */ .word lsr, abs
/* $4F */ .word 0,   0
/* $50 */ .word bvc, bvc
/* $51 */ .word eor, dind
/* $52 */ .word 0,   0
/* $53 */ .word 0,   0
/* $54 */ .word 0,   0
/* $55 */ .word eor, izx
/* $56 */ .word lsr, izx
/* $57 */ .word 0,   0
/* $58 */ .word cli, cli
/* $59 */ .word eor, iay
/* $5A */ .word 0,   0
/* $5B */ .word 0,   0
/* $5C */ .word 0,   0
/* $5D */ .word eor, iax
/* $5E */ .word lsr, iax
/* $5F */ .word 0,   0
/* $60 */ .word rts, rts
/* $61 */ .word adc, idir
/* $62 */ .word 0,   0
/* $63 */ .word 0,   0
/* $64 */ .word 0,   0
/* $65 */ .word adc, zp
/* $66 */ .word ror, zp
/* $67 */ .word 0,   0
/* $68 */ .word pla, pla
/* $69 */ .word adc_imm, imm
/* $6A */ .word ror_acc, acc
/* $6B */ .word 0,   0
/* $6C */ .word jmp, absd
/* $6D */ .word adc, abs
/* $6E */ .word ror, abs
/* $6F */ .word 0,   0
/* $70 */ .word bvs, bvs
/* $71 */ .word adc, dind
/* $72 */ .word 0,   0
/* $73 */ .word 0,   0
/* $74 */ .word 0,   0
/* $75 */ .word adc, izx
/* $76 */ .word ror, izx
/* $77 */ .word 0,   0
/* $78 */ .word sei, sei
/* $79 */ .word adc, iay
/* $7A */ .word 0,   0
/* $7B */ .word 0,   0
/* $7C */ .word 0,   0
/* $7D */ .word adc, iax
/* $7E */ .word ror, iax
/* $7F */ .word 0,   0
/* $80 */ .word 0,   0
/* $81 */ .word sta, idir
/* $82 */ .word 0,   0
/* $83 */ .word 0,   0
/* $84 */ .word sty, zp
/* $85 */ .word sta, zp
/* $86 */ .word stx, zp
/* $87 */ .word 0,   0
/* $88 */ .word dey, dey
/* $89 */ .word 0,   0
/* $8A */ .word txa, txa
/* $8B */ .word 0,   0
/* $8C */ .word sty, abs
/* $8D */ .word sta, abs
/* $8E */ .word stx, abs
/* $8F */ .word 0,   0
/* $90 */ .word bcc, bcc
/* $91 */ .word sta, dind
/* $92 */ .word 0,   0
/* $93 */ .word 0,   0
/* $94 */ .word sty, izx
/* $95 */ .word sta, izx
/* $96 */ .word stx, izy
/* $97 */ .word 0,   0
/* $98 */ .word tya, tya
/* $99 */ .word sta, iay
/* $9A */ .word txs, txs
/* $9B */ .word 0,   0
/* $9C */ .word 0,   0
/* $9D */ .word sta, iax
/* $9E */ .word 0,   0
/* $9F */ .word 0,   0
/* $A0 */ .word ldy_imm, imm
/* $A1 */ .word lda, idir
/* $A2 */ .word ldx_imm, imm
/* $A3 */ .word 0,   0
/* $A4 */ .word ldy, zp
/* $A5 */ .word lda, zp
/* $A6 */ .word ldx, zp
/* $A7 */ .word 0,   0
/* $A8 */ .word tay, tay
/* $A9 */ .word lda_imm, imm
/* $AA */ .word tax, tax
/* $AB */ .word 0,   0
/* $AC */ .word ldy, abs
/* $AD */ .word lda, abs
/* $AE */ .word ldx, abs
/* $AF */ .word 0,   0
/* $B0 */ .word bcs, bcs
/* $B1 */ .word lda, dind
/* $B2 */ .word 0,   0
/* $B3 */ .word 0,   0
/* $B4 */ .word ldy, izx
/* $B5 */ .word lda, izx
/* $B6 */ .word ldx, izy
/* $B7 */ .word 0,   0
/* $B8 */ .word clv, clv
/* $B9 */ .word lda, iay
/* $BA */ .word tsx, tsx
/* $BB */ .word 0,   0
/* $BC */ .word ldy, iax
/* $BD */ .word lda, iax
/* $BE */ .word ldx, iay
/* $BF */ .word 0,   0
/* $C0 */ .word cpy_imm, imm
/* $C1 */ .word cmp, idir
/* $C2 */ .word 0,   0
/* $C3 */ .word 0,   0
/* $C4 */ .word cpy, zp
/* $C5 */ .word cmp, zp
/* $C6 */ .word dec, zp
/* $C7 */ .word 0,   0
/* $C8 */ .word iny, iny
/* $C9 */ .word cmp_imm, imm
/* $CA */ .word dex, dex
/* $CB */ .word 0,   0
/* $CC */ .word cpy, abs
/* $CD */ .word cmp, abs
/* $CE */ .word dec, abs
/* $CF */ .word 0,   0
/* $D0 */ .word bne, bne
/* $D1 */ .word cmp, dind
/* $D2 */ .word 0,   0
/* $D3 */ .word 0,   0
/* $D4 */ .word 0,   0
/* $D5 */ .word cmp, izx
/* $D6 */ .word dec, izx
/* $D7 */ .word 0,   0
/* $D8 */ .word cld, cld
/* $D9 */ .word cmp, iay
/* $DA */ .word 0,   0
/* $DB */ .word 0,   0
/* $DC */ .word 0,   0
/* $DD */ .word cmp, iax
/* $DE */ .word dec, iax
/* $DF */ .word 0,   0
/* $E0 */ .word cpx_imm, imm
/* $E1 */ .word sbc, idir
/* $E2 */ .word 0,   0
/* $E3 */ .word 0,   0
/* $E4 */ .word cpx, zp
/* $E5 */ .word sbc, zp
/* $E6 */ .word inc, zp
/* $E7 */ .word 0,   0
/* $E8 */ .word inx, inx
/* $E9 */ .word sbc_imm, imm
/* $EA */ .word nop, nop
/* $EB */ .word 0,   0
/* $EC */ .word cpx, abs
/* $ED */ .word sbc, abs
/* $EE */ .word inc, abs
/* $EF */ .word 0,   0
/* $F0 */ .word beq, beq
/* $F1 */ .word sbc, dind
/* $F2 */ .word 0,   0
/* $F3 */ .word 0,   0
/* $F4 */ .word 0,   0
/* $F5 */ .word sbc, izx
/* $F6 */ .word inc, izx
/* $F7 */ .word 0,   0
/* $F8 */ .word sed, sed
/* $F9 */ .word sbc, iay
/* $FA */ .word 0,   0
/* $FB */ .word 0,   0
/* $FC */ .word 0,   0
/* $FD */ .word sbc, iax
/* $FE */ .word inc, iax
/* $FF */ .word 0,   0

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# pointers to rodata strings (to print instructions on debugging)
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

.if debug_enabled
str:
/* $00 */ .word _brk, _imp
/* $01 */ .word _ora, _idir
/* $02 */ .word 0,    0
/* $03 */ .word 0,    0
/* $04 */ .word 0,    0
/* $05 */ .word _ora, _zp
/* $06 */ .word _asl, _zp
/* $07 */ .word 0,    0
/* $08 */ .word _php, _imp
/* $09 */ .word _ora, _imm
/* $0A */ .word _asl, _acc
/* $0B */ .word 0,    0
/* $0C */ .word 0,    0
/* $0D */ .word _ora, _abs
/* $0E */ .word _asl, _abs
/* $0F */ .word 0,    0
/* $10 */ .word _bpl, _rel
/* $11 */ .word _ora, _dind
/* $12 */ .word 0,    0
/* $13 */ .word 0,    0
/* $14 */ .word 0,    0
/* $15 */ .word _ora, _izx
/* $16 */ .word _asl, _izx
/* $17 */ .word 0,    0
/* $18 */ .word _clc, _imp
/* $19 */ .word _ora, _iay
/* $1A */ .word 0,    0
/* $1B */ .word 0,    0
/* $1C */ .word 0,    0
/* $1D */ .word _ora, _iax
/* $1E */ .word _asl, _iax
/* $1F */ .word 0,    0
/* $20 */ .word _jsr, _abs
/* $21 */ .word _and, _idir
/* $22 */ .word 0,    0
/* $23 */ .word 0,    0
/* $24 */ .word _bit, _zp
/* $25 */ .word _and, _zp
/* $26 */ .word _rol, _zp
/* $27 */ .word 0,    0
/* $28 */ .word _plp, _imp
/* $29 */ .word _and, _imm
/* $2A */ .word _rol, _acc
/* $2B */ .word 0,    0
/* $2C */ .word _bit, _abs
/* $2D */ .word _and, _abs
/* $2E */ .word _rol, _abs
/* $2F */ .word 0,    0
/* $30 */ .word _bmi, _rel
/* $31 */ .word _and, _dind
/* $32 */ .word 0,    0
/* $33 */ .word 0,    0
/* $34 */ .word 0,    0
/* $35 */ .word _and, _izx
/* $36 */ .word _rol, _izx
/* $37 */ .word 0,    0
/* $38 */ .word _sec, _imp
/* $39 */ .word _and, _iay
/* $3A */ .word 0,    0
/* $3B */ .word 0,    0
/* $3C */ .word 0,    0
/* $3D */ .word _and, _iax
/* $3E */ .word _rol, _iax
/* $3F */ .word 0,    0
/* $40 */ .word _rti, _imp
/* $41 */ .word _eor, _idir
/* $42 */ .word 0,    0
/* $43 */ .word 0,    0
/* $44 */ .word 0,    0
/* $45 */ .word _eor, _zp
/* $46 */ .word _lsr, _zp
/* $47 */ .word 0,    0
/* $48 */ .word _pha, _imp
/* $49 */ .word _eor, _imm
/* $4A */ .word _lsr, _acc
/* $4B */ .word 0,    0
/* $4C */ .word _jmp, _abs
/* $4D */ .word _eor, _abs
/* $4E */ .word _lsr, _abs
/* $4F */ .word 0,    0
/* $50 */ .word _bvc, _rel
/* $51 */ .word _eor, _dind
/* $52 */ .word 0,    0
/* $53 */ .word 0,    0
/* $54 */ .word 0,    0
/* $55 */ .word _eor, _izx
/* $56 */ .word _lsr, _izx
/* $57 */ .word 0,    0
/* $58 */ .word _cli, _imp
/* $59 */ .word _eor, _iay
/* $5A */ .word 0,    0
/* $5B */ .word 0,    0
/* $5C */ .word 0,    0
/* $5D */ .word _eor, _iax
/* $5E */ .word _lsr, _iax
/* $5F */ .word 0,    0
/* $60 */ .word _rts, _imp
/* $61 */ .word _adc, _idir
/* $62 */ .word 0,    0
/* $63 */ .word 0,    0
/* $64 */ .word 0,    0
/* $65 */ .word _adc, _zp
/* $66 */ .word _ror, _zp
/* $67 */ .word 0,    0
/* $68 */ .word _pla, _imp
/* $69 */ .word _adc, _imm
/* $6A */ .word _ror, _acc
/* $6B */ .word 0,    0
/* $6C */ .word _jmp, _absd
/* $6D */ .word _adc, _abs
/* $6E */ .word _ror, _abs
/* $6F */ .word 0,    0
/* $70 */ .word _bvs, _rel
/* $71 */ .word _adc, _dind
/* $72 */ .word 0,    0
/* $73 */ .word 0,    0
/* $74 */ .word 0,    0
/* $75 */ .word _adc, _izx
/* $76 */ .word _ror, _izx
/* $77 */ .word 0,    0
/* $78 */ .word _sei, _imp
/* $79 */ .word _adc, _iay
/* $7A */ .word 0,    0
/* $7B */ .word 0,    0
/* $7C */ .word 0,    0
/* $7D */ .word _adc, _iax
/* $7E */ .word _ror, _iax
/* $7F */ .word 0,    0
/* $80 */ .word 0,    0
/* $81 */ .word _sta, _idir
/* $82 */ .word 0,    0
/* $83 */ .word 0,    0
/* $84 */ .word _sty, _zp
/* $85 */ .word _sta, _zp
/* $86 */ .word _stx, _zp
/* $87 */ .word 0,    0
/* $88 */ .word _dey, _imp
/* $89 */ .word 0,    0
/* $8A */ .word _txa, _imp
/* $8B */ .word 0,    0
/* $8C */ .word _sty, _abs
/* $8D */ .word _sta, _abs
/* $8E */ .word _stx, _abs
/* $8F */ .word 0,    0
/* $90 */ .word _bcc, _rel
/* $91 */ .word _sta, _dind
/* $92 */ .word 0,    0
/* $93 */ .word 0,    0
/* $94 */ .word _sty, _izx
/* $95 */ .word _sta, _izx
/* $96 */ .word _stx, _izy
/* $97 */ .word 0,    0
/* $98 */ .word _tya, _imp
/* $99 */ .word _sta, _iay
/* $9A */ .word _txs, _imp
/* $9B */ .word 0,    0
/* $9C */ .word 0,    0
/* $9D */ .word _sta, _iax
/* $9E */ .word 0,    0
/* $9F */ .word 0,    0
/* $A0 */ .word _ldy, _imm
/* $A1 */ .word _lda, _idir
/* $A2 */ .word _ldx, _imm
/* $A3 */ .word 0,    0
/* $A4 */ .word _ldy, _zp
/* $A5 */ .word _lda, _zp
/* $A6 */ .word _ldx, _zp
/* $A7 */ .word 0,    0
/* $A8 */ .word _tay, _imp
/* $A9 */ .word _lda, _imm
/* $AA */ .word _tax, _imp
/* $AB */ .word 0,    0
/* $AC */ .word _ldy, _abs
/* $AD */ .word _lda, _abs
/* $AE */ .word _ldx, _abs
/* $AF */ .word 0,    0
/* $B0 */ .word _bcs, _rel
/* $B1 */ .word _lda, _dind
/* $B2 */ .word 0,    0
/* $B3 */ .word 0,    0
/* $B4 */ .word _ldy, _izx
/* $B5 */ .word _lda, _izx
/* $B6 */ .word _ldx, _izy
/* $B7 */ .word 0,    0
/* $B8 */ .word _clv, _imp
/* $B9 */ .word _lda, _iay
/* $BA */ .word _tsx, _imp
/* $BB */ .word 0,    0
/* $BC */ .word _ldy, _iax
/* $BD */ .word _lda, _iax
/* $BE */ .word _ldx, _iay
/* $BF */ .word 0,    0
/* $C0 */ .word _cpy, _imm
/* $C1 */ .word _cmp, _idir
/* $C2 */ .word 0,    0
/* $C3 */ .word 0,    0
/* $C4 */ .word _cpy, _zp
/* $C5 */ .word _cmp, _zp
/* $C6 */ .word _dec, _zp
/* $C7 */ .word 0,    0
/* $C8 */ .word _iny, _imp
/* $C9 */ .word _cmp, _imm
/* $CA */ .word _dex, _imp
/* $CB */ .word 0,    0
/* $CC */ .word _cpy, _abs
/* $CD */ .word _cmp, _abs
/* $CE */ .word _dec, _abs
/* $CF */ .word 0,    0
/* $D0 */ .word _bne, _rel
/* $D1 */ .word _cmp, _dind
/* $D2 */ .word 0,    0
/* $D3 */ .word 0,    0
/* $D4 */ .word 0,    0
/* $D5 */ .word _cmp, _izx
/* $D6 */ .word _dec, _izx
/* $D7 */ .word 0,    0
/* $D8 */ .word _cld, _imp
/* $D9 */ .word _cmp, _iay
/* $DA */ .word 0,    0
/* $DB */ .word 0,    0
/* $DC */ .word 0,    0
/* $DD */ .word _cmp, _iax
/* $DE */ .word _dec, _iax
/* $DF */ .word 0,    0
/* $E0 */ .word _cpx, _imm
/* $E1 */ .word _sbc, _idir
/* $E2 */ .word 0,    0
/* $E3 */ .word 0,    0
/* $E4 */ .word _cpx, _zp
/* $E5 */ .word _sbc, _zp
/* $E6 */ .word _inc, _zp
/* $E7 */ .word 0,    0
/* $E8 */ .word _inx, _imp
/* $E9 */ .word _sbc, _imm
/* $EA */ .word _nop, _imp
/* $EB */ .word 0,    0
/* $EC */ .word _cpx, _abs
/* $ED */ .word _sbc, _abs
/* $EE */ .word _inc, _abs
/* $EF */ .word 0,    0
/* $F0 */ .word _beq, _rel
/* $F1 */ .word _sbc, _dind
/* $F2 */ .word 0,    0
/* $F3 */ .word 0,    0
/* $F4 */ .word 0,    0
/* $F5 */ .word _sbc, _izx
/* $F6 */ .word _inc, _izx
/* $F7 */ .word 0,    0
/* $F8 */ .word _sed, _imp
/* $F9 */ .word _sbc, _iay
/* $FA */ .word 0,    0
/* $FB */ .word 0,    0
/* $FC */ .word 0,    0
/* $FD */ .word _sbc, _iax
/* $FE */ .word _inc, _iax
/* $FF */ .word 0,    0
.endif

###################################################
#               SECTION: DATA                     #
###################################################

.data

# >>>>>>>>>>>>>>>>>>
# debugger variables
# >>>>>>>>>>>>>>>>>>

.if debug_enabled
cur_step: .word 0
.endif
