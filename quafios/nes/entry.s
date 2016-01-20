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
    # disable interrupts
    mtc0   $0, $12
    # enable serial output
    ls     $a0, "%e"
    bios   printf
    # show welcome message
    #ls     $a0, "%eNES over MIPS Emulator 1.0.1\n"
    #bios   printf
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
