// Compile-time
comptime {
    const value: i32 = -1;
    const unsigned: u32 = @intCast(value);
    _ = unsigned;
}

const std = @import("std");

// Run-time
pub fn main() void {
    var value: i32 = -1; // runtime-known
    _ = &value;
    const unsigned: u32 = @intCast(value);
    std.debug.print("value: {}\n", .{unsigned});
}

// To obtain the maximum value of an unsigned integer, use `std.math.maxInt`
