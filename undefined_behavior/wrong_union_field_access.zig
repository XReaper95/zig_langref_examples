// Compile-time
comptime {
    var f = Foo{ .int = 42 };
    f.float = 12.34;
}

const Foo = union {
    float: f32,
    int: u32,
};

const std = @import("std");

// Run-time
pub fn main() void {
    var f = Foo{ .int = 42 };
    bar(&f);
}

fn bar(f: *Foo) void {
    f.float = 12.34;
    std.debug.print("value: {}\n", .{f.float});
}

// This safety is not available for `extern` or `packed` unions

test "change union active field" {
    var f = Foo{ .int = 42 };
    bar2(&f);
}

fn bar2(f: *Foo) void {
    f.* = Foo{ .float = 12.34 };
    std.debug.print("value: {}\n", .{f.float});
}

// To change the active field of a union when a meaningful value
// for the field is not known, use undefined

test "change union active field when not meaningful value" {
    var f = Foo{ .int = 42 };
    f = Foo{ .float = undefined };
    bar3(&f);
    std.debug.print("value: {}\n", .{f.float});
}

fn bar3(f: *Foo) void {
    f.float = 12.34;
}
