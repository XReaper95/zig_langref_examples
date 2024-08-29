//! Each type has an alignment - a number of bytes such that, when a value of the
//! type is loaded from or stored to memory, the memory address must be evenly divisible
//! by this number. You can use @alignOf to find out this value for any type.
//! Alignment depends on the CPU architecture, but is always a power of two, and less than 1 << 29.
//! In Zig, a pointer type has an alignment value. If the value is equal to the
//! alignment of the underlying type, it can be omitted from the type

const std = @import("std");
const builtin = @import("builtin");
const expectEqual = std.testing.expectEqual;

test "variable alignment" {
    var x: i32 = 1234;
    const align_of_i32 = @alignOf(@TypeOf(x));
    try expectEqual(*i32, @TypeOf(&x));
    try expectEqual(*align(align_of_i32) i32, *i32);
    if (builtin.target.cpu.arch == .x86_64) {
        try expectEqual(4, @typeInfo(*i32).Pointer.alignment);
    }
}

// In the same way that a *i32 can be coerced to a *const i32, a pointer with a
// larger alignment can be implicitly cast to a pointer with a smaller alignment,
// but not vice versa. You can specify alignment on variables and functions.
// If you do this, then pointers to them get the specified alignment.

var foo: u8 align(4) = 100;

test "global variable alignment" {
    try expectEqual(4, @typeInfo(@TypeOf(&foo)).Pointer.alignment);
    try expectEqual(*align(4) u8, @TypeOf(&foo));
    const as_pointer_to_array: *align(4) [1]u8 = &foo;
    const as_slice: []align(4) u8 = as_pointer_to_array;
    const as_unaligned_slice: []u8 = as_slice;
    try expectEqual(100, as_unaligned_slice[0]);
}

fn derp() align(@sizeOf(usize) * 2) i32 {
    return 1234;
}
fn noop1() align(1) void {}
fn noop4() align(4) void {}

test "function alignment" {
    try expectEqual(1234, derp());
    try expectEqual(fn () i32, @TypeOf(derp));
    try expectEqual(*align(@sizeOf(usize) * 2) const fn () i32, @TypeOf(&derp));

    noop1();
    try expectEqual(fn () void, @TypeOf(noop1));
    try expectEqual(*align(1) const fn () void, @TypeOf(&noop1));

    noop4();
    try expectEqual(fn () void, @TypeOf(noop4));
    try expectEqual(*align(4) const fn () void, @TypeOf(&noop4));
}

// If you have a pointer or a slice that has a small alignment, but you know that it
// actually has a bigger alignment, use @alignCast to change the pointer into a more aligned
// pointer. This is a no-op at runtime, but inserts a safety check
test "pointer alignment safety" {
    var array align(4) = [_]u32{ 0x11111111, 0x11111111 };
    const bytes = std.mem.sliceAsBytes(array[0..]);
    try expectEqual(0x11111111, foo2(bytes));
}

fn foo2(bytes: []u8) u32 {
    const slice4 = bytes[1..5];
    const int_slice = std.mem.bytesAsSlice(u32, @as([]align(4) u8, @alignCast(slice4)));
    return int_slice[0];
}

test "alignment ok" {
    var pointer: *u16 = undefined;
    var array = std.mem.zeroes([5]u16);

    pointer = &array[3];
    pointer.* = 0x0001;

    try expectEqual([_]u16{ 0, 0, 0, 1, 0 }, array);
}

test "alignment bad" {
    var pointer: *u16 = undefined;
    var array = std.mem.zeroes([5]u8);

    pointer = @ptrCast(&array[3]); // increases pointer aligment
    pointer.* = 0x0001;

    try expectEqual([_]u16{ 0, 0, 0, 1, 0 }, array);
}
