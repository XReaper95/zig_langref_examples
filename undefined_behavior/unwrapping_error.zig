// Compile-time
comptime {
    const number = getNumberOrFail() catch unreachable;
    _ = number;
}

fn getNumberOrFail() !i32 {
    return error.UnableToReturnNumber;
}

const std = @import("std");

// Run-time
pub fn main() void {
    const number = getNumberOrFail() catch unreachable;
    std.debug.print("value: {}\n", .{number});
}

const expectError = std.testing.expectError;

test "avoid error unwrapping" {
    const result = getNumberOrFail();

    if (result) |number| {
        _ = number;
        unreachable;
    } else |err| {
        try expectError(error.UnableToReturnNumber, err);
    }
}
