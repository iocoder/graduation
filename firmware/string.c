#include "string.h"

int str_len(char *str) {
    int i = 0;
    while(str[i++]);
    return i;
}

int str_cmp(const char *str1, const char *str2) {
    int i = 0;
    while (str1[i] && str1[i] == str2[i]) i++;
    if (str1[i] > str2[i]) return i+1;
    else if (str1[i] < str2[i]) return -i-1;
    else return 0;
}

int str_to_int(char *str, int *num) {
    int i = 0;
    int r = 10;
    *num = 0;
    if (str[0] == '0' && str[1] == 'x') {
        i = 2;
        r = 16;
    }
    if (!str[i])
        return -1;
    while (str[i]) {
        int digit;
        if (str[i] >= '0' && str[i] <= '9') {
            digit = str[i] - '0';
        } else if (r == 16 && str[i] >= 'A' && str[i] <= 'F') {
            digit = str[i] - 'A' + 10;
        } else if (r == 16 && str[i] >= 'a' && str[i] <= 'f') {
            digit = str[i] - 'a' + 10;
        } else {
            return -1;
        }
        *num = *num*r + digit;
        i++;
    }
    return 0;
}
