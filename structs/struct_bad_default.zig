// Default field values are only appropriate when the data invariants of a
// struct cannot be violated by omitting that field from an initialization.
// Inapropiate:
const Threshold = struct {
    minimum: f32 = 0.25,
    maximum: f32 = 0.75,

    const Category = enum { low, medium, high };

    fn categorize(t: Threshold, value: f32) Category {
        assert(t.maximum >= t.minimum);
        if (value < t.minimum) return .low;
        if (value > t.maximum) return .high;
        return .medium;
    }
};

// To fix this, remove the default values from all the struct fields,
// and provide a named default value:
// const Threshold = struct {
//     minimum: f32,
//     maximum: f32,

//     const default: Threshold = .{
//         .minimum = 0.25,
//         .maximum = 0.75,
//     };
// };

pub fn main() !void {
    var threshold: Threshold = .{
        .maximum = 0.20,
    };
    const category = threshold.categorize(0.90);
    try std.io.getStdOut().writeAll(@tagName(category));
}

const std = @import("std");
const assert = std.debug.assert;
