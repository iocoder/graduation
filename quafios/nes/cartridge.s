.text
.include  "common.inc"
.global   rom_read, rom_read2, rom_instr, rom_write, rom_write2, cart_init
.global   prgrom_start, prgrom_cur, prgrom_last

.macro    getromaddr
    # highest bit of a0 [bit 14] determine action:
    # 0 -> read from curbank
    # 1 -> read from lastbank
    srl   $t0, $a0, 12
    andi  $t0, $t0, 4 # now t0 is 0 or 4
    addu  $t0, $t0, $s5
    lw    $t0, %lo(prgrom_cur)($t0) # now t0 holds ptr to rom slot base
    andi  $a0, $a0, 0x3FFF
    addu  $t0, $t0, $a0 # now t0 holds actual address
.endm

rom_read:
    # read byte from rom
    getromaddr
    lbu   $v0, 0($t0)
    jr    $ra #leave

rom_read2:
    # read 2 bytes from rom
    getromaddr
    lbu   $t7, 1($t0)
    lbu   $v0, 0($t0)
    sll   $t7, $t7, 8
    addu  $v0, $v0, $t7
    jr    $ra #leave

rom_instr:
    # read word from rom
    getromaddr
    lbu   $a1, 2($t0)
    lbu   $v1, 1($t0)
    lbu   $v0, 0($t0)
    sll   $a1, $a1, 8
    addu  $a1, $a1, $v1
    jr    $ra #leave

rom_write:
    # write word to rom
    andi  $a1, $a1, 7
    sll   $a1, $a1, 14
    lw    $t0, %lo(prgrom_start)($s5)
    addu  $t0, $t0, $a1
    sw    $t0, %lo(prgrom_cur)($s5)
    jr    $ra #leave

rom_write2:
#     # write word to rom
#     jr    $ra #leave
    j .

cart_init:
    # load nesfile to memory
    # bios readfile
    # read nesfile header
    lui    $t0, %hi(rom)
    addiu  $t0, $t0, %lo(rom)
    # read magic
    ori    $t1, $0,  'N'
    lbu    $t2, 0($t0)
    bne    $t1, $t2, magic_error
    ori    $t1, $0,  'E'
    lbu    $t2, 1($t0)
    bne    $t1, $t2, magic_error
    ori    $t1, $0,  'S'
    lbu    $t2, 2($t0)
    bne    $t1, $t2, magic_error
    ori    $t1, $0,  0x1A
    lbu    $t2, 3($t0)
    bne    $t1, $t2, magic_error
    # magic success, examine program rom
    addiu  $t0, $t0, 16
    lui    $t1, %hi(prgrom_start)
    addiu  $t1, $t1, %lo(prgrom_start)
    sw     $t0, 0($t1)
    lui    $t1, %hi(prgrom_cur)
    addiu  $t1, $t1, %lo(prgrom_cur)
    sw     $t0, 0($t1)
    addiu  $t0, $t0, 1*16*1024
    addiu  $t0, $t0, 1*16*1024
    addiu  $t0, $t0, 1*16*1024
    addiu  $t0, $t0, 1*16*1024
    addiu  $t0, $t0, 1*16*1024
    addiu  $t0, $t0, 1*16*1024
    addiu  $t0, $t0, 1*16*1024
    lui    $t1, %hi(prgrom_last)
    addiu  $t1, $t1, %lo(prgrom_last)
    sw     $t0, 0($t1)
    addiu  $t0, $t0, 1*8*1024
    # examine trainer/patch
    # TBD...
    # examine video roms
    # TBD...
    # inform user of progress
    move   $s0, $ra
    ls     $a0, "Booting from NES image...\n"
    bios   printf
    # return
    jr     $s0

magic_error:
    ls     $a0, "Invalid magic number!\n"
    bios   printf
    j      .

.data
prgrom_start: .long 0
prgrom_cur:   .long 0
prgrom_last:  .long 0

.section .rawdata
.incbin "contra.nes"
