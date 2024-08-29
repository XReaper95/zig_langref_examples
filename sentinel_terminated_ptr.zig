// needs to be compiled with `-lc`

const std = @import("std");

// The syntax [*:x]T describes a pointer that has a length determined by a sentinel value.
// This provides protection against buffer overflow and overreads.
// This is also available as `std.c.printf`.
pub extern "c" fn printf(format: [*:0]const u8, ...) c_int;

pub fn main() anyerror!void {
    _ = printf("Hello, world!\n"); // OK

    // const msg = "Hello, world!\n";
    // const non_null_terminated_msg: [msg.len]u8 = msg.*;
    // _ = printf(&non_null_terminated_msg); // will fail

    const hello = [_:0]u8{ 'H', 'e', 'l', 'l', 'o', '\n', 0, 0 };
    _ = printf(&hello);
}
