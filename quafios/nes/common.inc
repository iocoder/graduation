.macro    enter  size
    sw    $ra, -4($sp)
    sw    $fp, -8($sp)
    move  $fp, $sp
    addiu $sp, $sp, -((\size+2)*4)
.endm

.macro    leave
    move  $sp, $fp
    lw    $fp, -8($sp)
    lw    $ra, -4($sp)
    jr    $ra
.endm

.macro    pusha
    addiu $sp, $sp, -128
    sw    $2,    8($sp)
    sw    $3,   12($sp)
    sw    $4,   16($sp)
    sw    $5,   20($sp)
    sw    $6,   24($sp)
    sw    $7,   28($sp)
    sw    $8,   32($sp)
    sw    $9,   36($sp)
    sw    $10,  40($sp)
    sw    $11,  44($sp)
    sw    $12,  48($sp)
    sw    $13,  52($sp)
    sw    $14,  56($sp)
    sw    $15,  60($sp)
    sw    $16,  64($sp)
    sw    $17,  68($sp)
    sw    $18,  72($sp)
    sw    $19,  76($sp)
    sw    $20,  80($sp)
    sw    $21,  84($sp)
    sw    $22,  88($sp)
    sw    $23,  92($sp)
    sw    $24,  96($sp)
    sw    $25, 100($sp)
    sw    $26, 104($sp)
    sw    $27, 108($sp)
    sw    $28, 112($sp)
    sw    $29, 116($sp)
    sw    $30, 120($sp)
    sw    $31, 124($sp)
.endm

.macro    popa
    lw    $2,    8($sp)
    lw    $3,   12($sp)
    lw    $4,   16($sp)
    lw    $5,   20($sp)
    lw    $6,   24($sp)
    lw    $7,   28($sp)
    lw    $8,   32($sp)
    lw    $9,   36($sp)
    lw    $10,  40($sp)
    lw    $11,  44($sp)
    lw    $12,  48($sp)
    lw    $13,  52($sp)
    lw    $14,  56($sp)
    lw    $15,  60($sp)
    lw    $16,  64($sp)
    lw    $17,  68($sp)
    lw    $18,  72($sp)
    lw    $19,  76($sp)
    lw    $20,  80($sp)
    lw    $21,  84($sp)
    lw    $22,  88($sp)
    lw    $23,  92($sp)
    lw    $24,  96($sp)
    lw    $25, 100($sp)
    lw    $26, 104($sp)
    lw    $27, 108($sp)
    lw    $28, 112($sp)
    lw    $29, 116($sp)
    lw    $30, 120($sp)
    lw    $31, 124($sp)
    addiu $sp, $sp, 128
.endm

.macro    store  reg, indx
    sw    \reg, \indx*4($sp)
.endm

.macro    restr  indx, reg
    lw    \reg, \indx*4($sp)
.endm

.macro    ls     reg, str
.section "rodata", "a"
0: .string "\str"
.text
    lui   \reg, %hi(0b)
    addiu \reg, \reg, %lo(0b)
.endm

.macro    bios   routine
    .set  noat

.ifeqs "\routine", "putx"
    .set  __routine, 0x09
.endif

.ifeqs "\routine", "printf"
    .set  __routine, 0x0C
.endif

.ifeqs "\routine", "getc"
    .set  __routine, 0x0D
.endif

    addiu $sp, $sp, -16
    lw    $at, __routine*4($gp)
    jalr  $ra, $at
    addiu $sp, $sp, 16

    .set  at
.endm
