#############################
# COMPUTE FIBONACCI NUMBERS #
#############################

.globl fib

fib:
    # store ra
    move   $s0, $ra
    # store limit
    move   $s1, $a0
    # initialize counter
    move   $s2, $0
    # initialize s3 and s4
    addiu  $s3, $0, 0
    addiu  $s4, $0, 1
loop:
    # done?
    beq    $s1, $s2, done
    # print s4
    move   $a0, $s4
    jal    print_num
    # s5 = s3 + s4
    addu   $s5, $s3, $s4
    # shift the numbers
    move   $s3, $s4
    move   $s4, $s5
    # increment the counter
    addiu  $s2, $s2, 1
    # loop
    j      loop
done:
    # return to main()
    j      $s0
