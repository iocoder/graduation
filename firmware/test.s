# USE .text SECTION FOR CODE
# USE .rodata OR .text SECTION FOR CONSTANTS
# USE .bss SECTION FOR UNINTIALIZED DATA
# DATA MUST BE INITIALIZED MANUALLY BECAUSE BIOS IS LOADED TO ROM, NOT RAM.

.text

str: .string "HELLO WORLD!\n"

.global test
.align  2
test:
    # reserve a stack frame of 24 bytes
    addiu  $sp,$sp,-24 # stack pointer -= 24
    sw     $31,20($sp) # store register 31
    sw     $fp,16($sp) # store frame pointer
    move   $fp,$sp     # frame pointer <- stack pointer

    # CALL print_str
    lui    $4,%hi(str) # a0 should contain first argument
    ori    $4,%lo(str)
    li     $5,0x20     # a1 should contain second argument
    lui    $2,%hi(print_str)
    ori    $2,%lo(print_str)
    jal    $2          # address of print_str is now in v0

    # clear stack frame
    move   $sp,$fp     # restore sp
    lw     $31,20($sp) # restore register 31
    lw     $fp,16($sp) # restore frame pointer
    addiu  $sp,$sp,24  # free the frame

    # return
    j      $31         # link register holds the caller
    nop
