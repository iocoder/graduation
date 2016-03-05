# ENTRY POINT FOR THE FIRMWARE

.section .entry, "ax"
.global start
start:

    /*j .*/

    /*lui   $v0, 0xBE00       # IF ID EX MM WB
    ori   $v0, $v0, 0x0000  #    IF ID EX MM WB
    ori   $v1, $0, 'H'      #       IF ID EX MM WB
    sw    $v1, 0x00($v0)    #          IF ID EX MM WB
    ori   $v1, $0, 'e'      #             IF ID EX MM WB
    sw    $v1, 0x08($v0)
    ori   $v1, $0, 'l'
    sw    $v1, 0x10($v0)
    ori   $v1, $0, 'l'
    sw    $v1, 0x18($v0)
    ori   $v1, $0, 'o'
    sw    $v1, 0x20($v0)
    ori   $v1, $0, ' '
    sw    $v1, 0x28($v0)
    ori   $v1, $0, 'f'
    sw    $v1, 0x30($v0)
    ori   $v1, $0, 'r'
    sw    $v1, 0x38($v0)
    ori   $v1, $0, 'o'
    sw    $v1, 0x40($v0)
    ori   $v1, $0, 'm'
    sw    $v1, 0x48($v0)
    ori   $v1, $0, ' '
    sw    $v1, 0x50($v0)
    ori   $v1, $0, 'M'
    sw    $v1, 0x58($v0)
    ori   $v1, $0, 'I'
    sw    $v1, 0x60($v0)
    ori   $v1, $0, 'P'
    sw    $v1, 0x68($v0)
    ori   $v1, $0, 'S'
    sw    $v1, 0x70($v0)
    ori   $v1, $0, '!'
    sw    $v1, 0x78($v0)
    nop
    nop
    nop
    j     .*/

    /*lui   $a2, 0x0001
    sw    $v1, 0x00($a2)
    lw    $v1, 0x00($a2)*/
/*     sw    $v1, 0x78($v0) */

/*    ori   $v1, $0, 'H'      # WB
    lui   $v0, 0x0001       # MEM
    ori   $v0, $v0, 0x8000  # EX
    nop                     # ID
    nop
    nop
    nop
    nop
    nop
    nop
    sw    $v1, 0x00($v0)    # IF
    ori   $v1, $0, 'e'
    sw    $v1, 0x08($v0)
    ori   $v1, $0, 'l'
    sw    $v1, 0x10($v0)
    ori   $v1, $0, 'l'
    sw    $v1, 0x18($v0)
    ori   $v1, $0, 'o'
    sw    $v1, 0x20($v0)
    ori   $v1, $0, ' '
    sw    $v1, 0x28($v0)
    ori   $v1, $0, 'f'
    sw    $v1, 0x30($v0)
    ori   $v1, $0, 'r'
    sw    $v1, 0x38($v0)
    ori   $v1, $0, 'o'
    sw    $v1, 0x40($v0)
    ori   $v1, $0, 'm'
    sw    $v1, 0x48($v0)
    ori   $v1, $0, ' '
    sw    $v1, 0x50($v0)
    ori   $v1, $0, 'M'
    sw    $v1, 0x58($v0)
    ori   $v1, $0, 'I'
    sw    $v1, 0x60($v0)
    ori   $v1, $0, 'P'
    sw    $v1, 0x68($v0)
    ori   $v1, $0, 'S'
    sw    $v1, 0x70($v0)
    ori   $v1, $0, '!'
    sw    $v1, 0x78($v0)
    j     .
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop*/

    lui   $sp, 0x8000
    ori   $sp, $sp, 0x8000
    nop
    jal   main
    break

.org 0x180
    .set noat
    .set noreorder
    nop
    nop
    nop
    nop
    lui   $k0, %hi(isr_loc)
    lw    $k0, %lo(isr_loc)($k0)
    jr    $k0
    nop

.org 0x200

.global isr_routine
isr_routine:
    addi  $sp, -4*32

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

    move  $a0, $sp
    jal   handle_interrupt
    nop

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

    addi  $sp, 4*32

    mfc0  $k0, $14

    jr    $k0
    rfe
