#include <stdio.h>

void print_num(int n) {
    int s[8];
    __asm__("move %0, $s0":"=r"(s[0]));
    __asm__("move %0, $s1":"=r"(s[1]));
    __asm__("move %0, $s2":"=r"(s[2]));
    __asm__("move %0, $s3":"=r"(s[3]));
    __asm__("move %0, $s4":"=r"(s[4]));
    __asm__("move %0, $s5":"=r"(s[5]));
    __asm__("move %0, $s6":"=r"(s[6]));
    __asm__("move %0, $s7":"=r"(s[7]));
    printf("%d\n", n);
    __asm__("move $s0, %0"::"r"(s[0]));
    __asm__("move $s1, %0"::"r"(s[1]));
    __asm__("move $s2, %0"::"r"(s[2]));
    __asm__("move $s3, %0"::"r"(s[3]));
    __asm__("move $s4, %0"::"r"(s[4]));
    __asm__("move $s5, %0"::"r"(s[5]));
    __asm__("move $s6, %0"::"r"(s[6]));
    __asm__("move $s7, %0"::"r"(s[7]));
}

int main() {
    int n;
    printf("Enter number: ");
    scanf("%d", &n);
    fib(n);
    return 0;
}
