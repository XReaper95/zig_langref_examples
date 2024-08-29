//! Compiling with safety off (ReleaseFast, ReleaseSmall) will cause UB, else panic (ReleaseSafe)

const std = @import("std");

pub fn main() void {
    var buffer = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };

    // Intentionally misalign the pointer so it won't be evenly divisible by 4
    const misaligned_ptr = &buffer[1];

    const ptr: *u32 = @ptrCast(misaligned_ptr);
    const value: u32 = ptr.*;

    std.debug.print("Value: {s}\n", .{value});
}
