// run with `zig run c_lib.zig c_lib.obj -lc`
// see c_lib.c to compile the C library

extern fn square(x: i32) i32;
extern fn talk_from_c() void;

const print = @import("std").debug.print;

pub fn main() void {
    const num: i32 = 4;
    print("This is being printed from Zig!!\n", .{});
    print("Zig says: square of {d} is {d}\n", .{ num, square(num) });

    talk_from_c();
}
