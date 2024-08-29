// compile the library with `zig cc -c c_lib.c -O3` to produce c_lib.obj

#include <stdint.h>
#include <stdio.h>

#define MY_NUM 4

int32_t square(int32_t x) {
    return x * x;
}

void talk_from_c(){
    printf("Hi! This is being printed from a C library!!\n");
    printf("C says: square of %d is %d\n", MY_NUM, square(MY_NUM));
}