// Compile-time
comptime {
    const optional_number: ?i32 = null;
    const number = optional_number.?;
    _ = number;
}

const std = @import("std");

// Run-time
pub fn main() void {
    var optional_number: ?i32 = null;
    _ = &optional_number;
    const number = optional_number.?;
    std.debug.print("value: {}\n", .{number});
}

const expect = std.testing.expect;

test "avoid null unwrapping" {
    const optional_number: ?i32 = null;

    if (optional_number) |number| {
        _ = number;
        unreachable;
    } else {
        try expect(optional_number == null);
    }
}
