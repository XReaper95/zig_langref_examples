//! The following operators can cause integer overflow:
//!     + (addition)
//!     - (subtraction)
//!     - (negation)
//!     * (multiplication)
//!     / (division)
//!     @divTrunc (division)
//!     @divFloor (division)
//!     @divExact (division)

// Examples with addition

// Compile-time
// comptime {
//     var byte: u8 = 255;
//     byte += 1;
// }

const std = @import("std");

// Run-time
pub fn main() void {
    var byte: u8 = 255;
    byte += 1;
    std.debug.print("value: {}\n", .{byte});
}

// These functions provided by the standard library return possible errors:
//      - @import("std").math.add
//      - @import("std").math.sub
//      - @import("std").math.mul
//      - @import("std").math.divTrunc
//      - @import("std").math.divFloor
//      - @import("std").math.divExact
//      - @import("std").math.shl

const math = std.math;
const print = std.debug.print;
const expect = std.testing.expect;
const expectError = std.testing.expectError;

test "catching overflow for addition" {
    const byte: u8 = 255;

    const byte_or_err = if (math.add(u8, byte, 1)) |result| result else |err| blk: {
        print("\nunable to add one: {s}\n", .{@errorName(err)});
        break :blk err;
    };

    try expectError(error.Overflow, byte_or_err);
}

// These builtins return a tuple containing whether there was an
// overflow (as a u1) and the possibly overflowed bits of the operation:
//      - @addWithOverflow
//      - @subWithOverflow
//      - @mulWithOverflow
//      - @shlWithOverflow

test "example of @addWithOverflow" {
    const byte: u8 = 255;
    const ov = @addWithOverflow(byte, 10);

    if (ov[1] != 0) {
        try expect(ov[0] == 9);
    } else {
        unreachable;
    }
}

//  These operations have guaranteed wraparound semantics.
//      +% (wraparound addition)
//      -% (wraparound subtraction)
//      -% (wraparound negation)
//      *% (wraparound multiplication)

const minInt = std.math.minInt;
const maxInt = std.math.maxInt;

test "wraparound addition and subtraction" {
    const x: i32 = maxInt(i32);
    const min_val = x +% 1;
    try expect(min_val == minInt(i32));
    const max_val = min_val -% 1;
    try expect(max_val == maxInt(i32));
}
