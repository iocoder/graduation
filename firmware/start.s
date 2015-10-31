# ENTRY POINT FOR THE FIRMWARE

.section .entry, "ax"
.global start
start:
/*    lui   $v0, 0x0001       # IF ID EX MM WB
    ori   $v0, $v0, 0x8000  #    IF ID EX MM WB
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

    lui   $sp, 0x0001
    ori   $sp, $sp, 0x8000
    nop
    jal   main
    break
