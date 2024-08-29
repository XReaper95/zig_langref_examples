// Compile-time
comptime {
    const x = @shrExact(@as(u8, 0b10101010), 2);
    _ = x;
}

const std = @import("std");

// Run-time
pub fn main() void {
    var x: u8 = 0b10101010; // runtime-known
    _ = &x;
    const y = @shrExact(x, 2);
    std.debug.print("value: {}\n", .{y});
}
