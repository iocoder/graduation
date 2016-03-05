/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> MIPS: interrupt service routine.                 | |
 *        | +------------------------------------------------------+ |
 *        +----------------------------------------------------------+
 *
 * This file is part of Quafios 2.0.1 source code.
 * Copyright (C) 2015  Mostafa Abd El-Aziz Mohamed.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Quafios.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Visit http://www.quafios.com/ for contact information.
 *
 */

.text

.global isr, isr_init

.section .text.isr

.section .text.isr_init

isr_init:
    addiu $sp, $sp, -20
    sw    $ra, 16($sp)
    lui   $a0, %hi(isr)
    addiu $a0, %lo(isr)
    jal   legacy_set_isr_loc
    lw    $ra, 16($sp)
    addiu $sp, $sp, 20
    jr    $ra

isr:
.set noat
.set noreorder
    /* re-align stack */
    addi  $sp, -4*32
    /* push registers */
    sw    $0,  4* 0($sp)
    sw    $1,  4* 1($sp)
    sw    $2,  4* 2($sp)
    sw    $3,  4* 3($sp)
    sw    $4,  4* 4($sp)
    sw    $5,  4* 5($sp)
    sw    $6,  4* 6($sp)
    sw    $7,  4* 7($sp)
    sw    $8,  4* 8($sp)
    sw    $9,  4* 9($sp)
    sw    $10, 4*10($sp)
    sw    $11, 4*11($sp)
    sw    $12, 4*12($sp)
    sw    $13, 4*13($sp)
    sw    $14, 4*14($sp)
    sw    $15, 4*15($sp)
    sw    $16, 4*16($sp)
    sw    $17, 4*17($sp)
    sw    $18, 4*18($sp)
    sw    $19, 4*19($sp)
    sw    $20, 4*20($sp)
    sw    $21, 4*21($sp)
    sw    $22, 4*22($sp)
    sw    $23, 4*23($sp)
    sw    $24, 4*24($sp)
    sw    $25, 4*25($sp)
    sw    $26, 4*26($sp)
    sw    $27, 4*27($sp)
    sw    $28, 4*28($sp)
    sw    $29, 4*29($sp)
    sw    $30, 4*30($sp)
    sw    $31, 4*31($sp)
    /* store pointer to regs */
    move  $a0, $sp
    /* examine cause */
    mfc0  $t0, $13
    srl   $t0, $t0, 2
    andi  $t0, 0x0F
    beq   $0, $t0, cause_zero
    nop
    j     cause_one
    nop
cause_zero:
    /* interrupt */
    jal   irq
    nop
    j     return
    nop
cause_one:
    /* TLB miss */
    jal   tlb_miss
    nop
    j     return
    nop
return:
    /* pop registers */
    lw    $0,  4* 0($sp)
    lw    $1,  4* 1($sp)
    lw    $2,  4* 2($sp)
    lw    $3,  4* 3($sp)
    lw    $4,  4* 4($sp)
    lw    $5,  4* 5($sp)
    lw    $6,  4* 6($sp)
    lw    $7,  4* 7($sp)
    lw    $8,  4* 8($sp)
    lw    $9,  4* 9($sp)
    lw    $10, 4*10($sp)
    lw    $11, 4*11($sp)
    lw    $12, 4*12($sp)
    lw    $13, 4*13($sp)
    lw    $14, 4*14($sp)
    lw    $15, 4*15($sp)
    lw    $16, 4*16($sp)
    lw    $17, 4*17($sp)
    lw    $18, 4*18($sp)
    lw    $19, 4*19($sp)
    lw    $20, 4*20($sp)
    lw    $21, 4*21($sp)
    lw    $22, 4*22($sp)
    lw    $23, 4*23($sp)
    lw    $24, 4*24($sp)
    lw    $25, 4*25($sp)
    lw    $26, 4*26($sp)
    lw    $27, 4*27($sp)
    lw    $28, 4*28($sp)
    lw    $29, 4*29($sp)
    lw    $30, 4*30($sp)
    lw    $31, 4*31($sp)
    /* reset stack pointer */
    addi  $sp, 4*32
    /* jmp to EPC */
    mfc0  $k0, $14
    jr    $k0
    rfe

