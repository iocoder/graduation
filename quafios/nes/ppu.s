.global   ppu_read, ppu_read2, ppu_instr, ppu_write, ppu_write2

ppu_read:
    # read byte from PPU
    lui   $t0, 0x1EC0
    addu  $t0, $t0, $a0
    lbu   $v0, 0($t0)
    jr    $ra

ppu_read2:
    j .

ppu_instr:
    j .

ppu_write:
    # write byte to PPU
    ori   $t0, $0,  0x4014
    beq   $t0, $a0, do_dma
    lui   $t0, 0x1EC0
    addu  $t0, $t0, $a0
    sb    $a1, 0($t0)
    jr    $ra

do_dma:
    sw    $s0,  -4($sp)
    sw    $s1,  -8($sp)
    sw    $s2, -12($sp)
    sw    $ra, -16($sp)
    ori   $s0, $0,  256
    lui   $s1, 0x1EC0
    addiu $s1, $s1, 0x2004
    sll   $s2, $a1, 8
1:  move  $a0, $s2
    jal   mem_read
    sb    $v0, 0($s1)
    addiu $s2, $s2, 1
    addiu $s0, $s0, -1
    bne   $s0, $0,  1b
    lw    $s0,  -4($sp)
    lw    $s1,  -8($sp)
    lw    $s2, -12($sp)
    lw    $ra, -16($sp)
    jr    $ra

ppu_write2:
    j .
