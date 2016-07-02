.text
.include  "common.inc"
.global   entry, main

################################################
#                 main                         #
# ---------------------------------------------#
# Summary: Main procedure.                     #
# ---------------------------------------------#
# Inputs: N/A                                  #
# ---------------------------------------------#
# Outputs: N/A                                 #
################################################

main:
    # print splash
    ls     $a0, "%a"
    ori    $a1, $0 , 0x0A
    bios   printf
    lui    $a0, %hi(splash)
    addiu  $a0, $a0, %lo(splash)
    bios   printf
    ls     $a0, "%a"
    ori    $a1, $0 , 0x0F
    bios   printf
    # initialize cartridge
    jal    cart_init
    # enable serial output
    ls     $a0, "%e"
    bios   printf
    # switch to NES PPU mode
    lui    $t0, 0xBE00
    ori    $t0, $t0, 0x1FF8
    ori    $t1, $0 , 1
    sh     $t1, 0($t0)
    # initialize memory
    jal    mem_init
    # reset CPU
    jal    reset

.section ".entry", "ax"

################################################
#                    entry                     #
# ---------------------------------------------#
# Summary: This procedure is the entry point   #
# of NES simulator code.                       #
# ---------------------------------------------#
# Inputs: N/A                                  #
# ---------------------------------------------#
# Outputs: N/A                                 #
################################################

entry:
    j      main

# splash screen
.section "rodata", "a"
splash:
    .incbin "splash.txt"
    .byte    0
