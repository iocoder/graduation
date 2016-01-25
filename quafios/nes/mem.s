.text
.include  "common.inc"
.global   mem_read, mem_read2, instr_read, mem_write, mem_write2, mem_init
.global   read_routines, read2_routines, instr_routines
.global   write_routines, write2_routines
.global   rom, ram
.global   rom_instr, ram_read, ram_read2, ram_write, ram_write2

################################################
#                 mem_read                     #
# ---------------------------------------------#
# Summary: Read byte from memory               #
# ---------------------------------------------#
# Inputs:  a0 <= address(16 bits)              #
# ---------------------------------------------#
# Outputs: v0 <= value  (8  bits)              #
################################################

mem_read:
    # higher 3 bits of address tell us what I/O device is accessed:
    # 00x - RAM
    # 010 - KBD
    # 011 - VGA
    # 1xx - ROM
    srl   $t0, $a0, 11
    andi  $t0, $t0, 28
    addu  $t7, $s5, $t0
    lw    $t7, %lo(__read_routines)($t7)
    andi  $a0, $a0, 0xFFFF
    jr    $t7
vga_read:
    # read word from vga
    andi  $a0, $a0, 0x1FFF
    jr    $ra #leave
kbd_read:
    # read word from kbd
    jr    $ra #leave
ram_read:
    # read word from ram
    addu  $t0, $a0, $s8
    lbu   $v0, %lo(__ram)($t0)
    jr    $ra #leave

################################################
#                 mem_read2                    #
# ---------------------------------------------#
# Summary: Read 2 bytes from memory            #
# ---------------------------------------------#
# Inputs:  a0 <= address(16 bits)              #
# ---------------------------------------------#
# Outputs: v0 <= value  (16 bits)              #
################################################

mem_read2:
    # higher 3 bits of address tell us what I/O device is accessed:
    # 00x - RAM
    # 010 - KBD
    # 011 - VGA
    # 1xx - ROM
    srl   $t0, $a0, 11
    andi  $t0, $t0, 28
    addu  $t7, $s5, $t0
    lw    $t7, %lo(__read2_routines)($t7)
    andi  $a0, $a0, 0xFFFF
    jr    $t7
vga_read2:
    # read word from vga
    andi  $a0, $a0, 0x1FFF
    jr    $ra #leave
kbd_read2:
    # read word from kbd
    jr    $ra #leave
ram_read2:
    # read word from ram
    addu  $t0, $a0, $s8
    lbu   $t7, %lo(__ram)+1($t0)
    lbu   $v0, %lo(__ram)($t0)
    sll   $t7, $t7, 8
    addu  $v0, $v0, $t7
    jr    $ra #leave

################################################
#                instr_read                    #
# ---------------------------------------------#
# Summary: Read instruction from memory        #
# ---------------------------------------------#
# Inputs:  a0 <= address(16 bits)              #
# ---------------------------------------------#
# Outputs: v0 <= first byte                    #
#          v1 <= second byte                   #
#          a1 <= second and third byte         #
################################################

instr_read:
    # higher 3 bits of address tell us what I/O device is accessed:
    # 00x - RAM
    # 010 - KBD
    # 011 - VGA
    # 1xx - ROM
    srl   $t0, $a0, 11
    andi  $t0, $t0, 28
    addu  $t7, $s5, $t0
    lw    $t7, %lo(__instr_routines)($t7)
    andi  $a0, $a0, 0xFFFF
    jr    $t7
vga_instr:
    # read word from vga
    andi  $a0, $a0, 0x1FFF
    jr    $ra #leave
kbd_instr:
    # read word from kbd
    jr    $ra #leave
ram_instr:
    # read word from ram
    andi  $a0, $a0, 0x7FFF
    addu  $t0, $a0, $s8
    lbu   $a1, %lo(__ram)+2($t0)
    lbu   $v1, %lo(__ram)+1($t0)
    lbu   $v0, %lo(__ram)+0($t0)
    sll   $a1, $a1, 8
    addu  $a1, $a1, $v1
    jr    $ra #leave

################################################
#                 mem_write                    #
# ---------------------------------------------#
# Summary: Write byte to memory                #
# ---------------------------------------------#
# Inputs:  a0 <= address(16 bits)              #
#          a1 <= value  (8  bits)              #
# ---------------------------------------------#
# Outputs: N/A                                 #
################################################

mem_write:
    # higher 3 bits of address tell us what I/O device is accessed:
    # 00x - RAM
    # 010 - KBD
    # 011 - VGA
    # 1xx - ROM
    srl   $t0, $a0, 11
    andi  $t0, $t0, 28
    addu  $t7, $s5, $t0
    lw    $t7, %lo(__write_routines)($t7)
    andi  $a0, $a0, 0xFFFF
    jr    $t7
vga_write:
    # write word to vga
    andi  $a0, $a0, 0x1FFF
    ori   $t0, $0,  0x01E0
    sltu  $t0, $a0, $t0
    beq   $t0, $0,  0f
    addu  $a0, $a0, 0x1E0
    #j     1f
0:  ori   $t0, $0,  0x1180
    sltu  $t0, $a0, $t0
    bne   $t0, $0,  0f
    addu  $a0, $a0, -(160*2)
    #j     1f
0:  addiu $a0, $a0, -0x01E0
    sll   $a0, $a0, 1
    lui   $t0, 0xBE00
    addu  $a0, $a0, $t0
    sw    $a1, 0($a0)
1:  jr    $ra #leave
kbd_write:
    # write word to kbd
    jr    $ra #leave
ram_write:
    # write word to ram
    addu  $t0, $a0, $s8
    sb    $a1, %lo(__ram)($t0)
    jr    $ra #leave

################################################
#                 mem_write2                   #
# ---------------------------------------------#
# Summary: Write 2 bytes to memory             #
# ---------------------------------------------#
# Inputs:  a0 <= address(16 bits)              #
#          a1 <= value  (16 bits)              #
# ---------------------------------------------#
# Outputs: N/A                                 #
################################################

mem_write2:
    # higher 3 bits of address tell us what I/O device is accessed:
    # 00x - RAM
    # 010 - KBD
    # 011 - VGA
    # 1xx - ROM
    srl   $t0, $a0, 11
    andi  $t0, $t0, 28
    addu  $t7, $s5, $t0
    lw    $t7, %lo(__write2_routines)($t7)
    andi  $a0, $a0, 0xFFFF
    jr    $t7
vga_write2:
    # write word to vga
    jr    $ra #leave
kbd_write2:
    # write word to kbd
    jr    $ra #leave
ram_write2:
    # write word to ram
    addu  $t0, $a0, $s8
    sb    $a1, %lo(__ram)($t0)
    srl   $a1, $a1, 8
    sb    $a1, %lo(__ram)+1($t0)
    jr    $ra #leave

################################################
#                 mem_init                     #
# ---------------------------------------------#
# Summary: Initialize memory                   #
# ---------------------------------------------#
# Inputs: N/A                                  #
# ---------------------------------------------#
# Outputs: N/A                                 #
################################################

mem_init:
    # nothing to do here
    jr    $ra

.section "rodata", "a"

read_routines:
    .word ram_read
    .word ppu_read
    .word ppu_read
    .word vga_read
    .word rom_read
    .word rom_read
    .word rom_read
    .word rom_read

read2_routines:
    .word ram_read2
    .word ppu_read2
    .word ppu_read2
    .word vga_read2
    .word rom_read2
    .word rom_read2
    .word rom_read2
    .word rom_read2

instr_routines:
    .word ram_instr
    .word ppu_instr
    .word ppu_instr
    .word vga_instr
    .word rom_instr
    .word rom_instr
    .word rom_instr
    .word rom_instr

write_routines:
    .word ram_write
    .word ppu_write
    .word ppu_write
    .word vga_write
    .word rom_write
    .word rom_write
    .word rom_write
    .word rom_write

write2_routines:
    .word ram_write2
    .word ppu_write2
    .word ppu_write2
    .word vga_write2
    .word rom_write2
    .word rom_write2
    .word rom_write2
    .word rom_write2

# RAM
.bss
ram: .space  0x8000
