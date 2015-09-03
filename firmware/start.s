# ENTRY POINT FOR THE FIRMWARE

.section .entry, "ax"
.global start
start:
    lui   $sp, 0x0001
    ori   $sp, $sp, 0x8000
    nop
    jal   main
    break
