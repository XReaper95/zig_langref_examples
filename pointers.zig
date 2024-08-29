//!  Zig has two kinds of pointers: single-item and many-item.
//!     *T - single-item pointer to exactly one item.
//!         Supports deref syntax: ptr.*
//!         Supports slice syntax: ptr[0..1]
//!         Supports pointer subtraction: ptr - ptr
//!     [*]T - many-item pointer to unknown number of items.
//!         Supports index syntax: ptr[i]
//!         Supports slice syntax: ptr[start..end] and ptr[start..]
//!         Supports pointer-integer arithmetic: ptr + int, ptr - int
//!         Supports pointer subtraction: ptr - ptr
//!     T must have a known size, which means that it cannot be anyopaque or any other opaque type.
//! These types are closely related to Arrays and Slices:
//!     *[N]T - pointer to N items, same as single-item pointer to an array.
//!         Supports index syntax: array_ptr[i]
//!         Supports slice syntax: array_ptr[start..end]
//!         Supports len property: array_ptr.len
//!         Supports pointer subtraction: array_ptr - array_ptr
//!     []T - is a slice (a fat pointer, which contains a pointer of type [*]T and a length).
//!         Supports index syntax: slice[i]
//!        Supports slice syntax: slice[start..end]
//!         Supports len property: slice.len

const expect = @import("std").testing.expect;
const mem = @import("std").mem;

test "address of syntax" {
    // Get the address of a variable:
    const x: i32 = 1234;
    const x_ptr = &x;

    // Dereference a pointer:
    try expect(x_ptr.* == 1234);

    // When you get the address of a const variable, you get a const single-item pointer.
    try expect(@TypeOf(x_ptr) == *const i32);

    // If you want to mutate the value, you'd need an address of a mutable variable:
    var y: i32 = 5678;
    const y_ptr = &y;
    try expect(@TypeOf(y_ptr) == *i32);
    y_ptr.* += 1;
    try expect(y_ptr.* == 5679);
}

test "pointer array access" {
    // Taking an address of an individual element gives a
    // single-item pointer. This kind of pointer
    // does not support pointer arithmetic.
    var array = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    const ptr = &array[2];
    try expect(@TypeOf(ptr) == *u8);

    try expect(array[2] == 3);
    ptr.* += 1;
    try expect(array[2] == 4);
}

test "slice syntax" {
    // Get a pointer to a variable:
    var x: i32 = 1234;
    const x_ptr = &x;

    // Convert to array pointer using slice syntax:
    const x_array_ptr = x_ptr[0..1];
    try expect(@TypeOf(x_array_ptr) == *[1]i32);

    // Coerce to many-item pointer:
    const x_many_ptr: [*]i32 = x_array_ptr;
    try expect(x_many_ptr[0] == 1234);
}

test "pointer arithmetic with many-item pointer" {
    const array = [_]i32{ 1, 2, 3, 4 };
    var ptr: [*]const i32 = &array;

    try expect(ptr[0] == 1);
    ptr += 1;
    try expect(ptr[0] == 2);

    // slicing a many-item pointer without an end is equivalent to
    // pointer arithmetic: `ptr[start..] == ptr + start`
    try expect(ptr[1..] == ptr + 1);

    // subtraction between any two pointers except slices based on element size is supported
    try expect(&ptr[1] - &ptr[0] == 1);
}

test "pointer arithmetic with slices" {
    var array = [_]i32{ 1, 2, 3, 4 };
    var length: usize = 0; // var to make it runtime-known
    _ = &length; // suppress 'var is never mutated' error
    var slice = array[length..array.len];

    try expect(slice[0] == 1);
    try expect(slice.len == 4);

    slice.ptr += 1;
    // now the slice is in an bad state since len has not been updated

    try expect(slice[0] == 2);
    try expect(slice.len == 4);
}

test "pointer slicing" {
    var array = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    var start: usize = 2; // var to make it runtime-known
    _ = &start; // suppress 'var is never mutated' error
    const slice = array[start..4];
    try expect(slice.len == 2);

    try expect(array[3] == 4);
    slice[1] += 1;
    try expect(array[3] == 5);
}

// Pointers work at compile-time too, as long as the
// code does not depend on an undefined memory layout
test "comptime pointers" {
    comptime {
        var x: i32 = 1;
        const ptr = &x;
        ptr.* += 1;
        x += 1;
        try expect(ptr.* == 3);
    }
}

test "@intFromPtr and @ptrFromInt" {
    const ptr: *i32 = @ptrFromInt(0xdeadbee0);
    const addr = @intFromPtr(ptr);
    try expect(@TypeOf(addr) == usize);
    try expect(addr == 0xdeadbee0);
}

test "comptime @ptrFromInt" {
    comptime {
        // Zig is able to preserve memory addresses at compile-time, as long as
        // ptr is never dereferenced.
        const ptr: *i32 = @ptrFromInt(0xdeadbee0);
        const addr = @intFromPtr(ptr);
        try expect(@TypeOf(addr) == usize);
        try expect(addr == 0xdeadbee0);
    }
}

// Loads and stores are assumed to not have side effects.
// If a given load or store should have side effects,
// such as Memory Mapped Input/Output (MMIO), use `volatile`.
// In the following code, loads and stores with mmio_ptr are
// guaranteed to all happen and in the same order as in source code
// `volatile` is unrelated to concurrency and Atomics.
// If you see code that is using volatile for something other
// than Memory Mapped Input/Output, it is probably a bug.
test "volatile" {
    const mmio_ptr: *volatile u8 = @ptrFromInt(0x12345678);
    try expect(@TypeOf(mmio_ptr) == *volatile u8);
}

// @ptrCast converts a pointer's element type to another.
// This creates a new pointer that can cause undetectable illegal behavior
// depending on the loads and stores that pass through it.
// Generally, other kinds of type conversions are preferable to @ptrCast if possible.
test "pointer casting" {
    const bytes align(@alignOf(u32)) = [_]u8{ 0x12, 0x12, 0x12, 0x12 };
    const u32_ptr: *const u32 = @ptrCast(&bytes);
    try expect(u32_ptr.* == 0x12121212);

    // Even this example is contrived - there are better ways to do the above than
    // pointer casting. For example, using a slice narrowing cast:
    const u32_value = mem.bytesAsSlice(u32, bytes[0..])[0];
    try expect(u32_value == 0x12121212);

    // And even another way, the most straightforward way to do it:
    try expect(@as(u32, @bitCast(bytes)) == 0x12121212);
}

test "pointer child type" {
    // pointer types have a `child` field which tells you the type they point to.
    try expect(@typeInfo(*u32).Pointer.child == u32);
}

// The `allowzero` pointer attribute allows a pointer to have address zero.
// This is only ever needed on the freestanding OS target, where the address
// zero is mappable. If you want to represent null pointers, use
// Optional Pointers instead. Optional Pointers with allowzero are not the same size
// as pointers. In this code example, if the pointer did not have the allowzero attribute,
// this would be a Pointer Cast Invalid Null panic
test "allowzero" {
    var zero: usize = 0; // var to make to runtime-known
    _ = &zero; // suppress 'var is never mutated' error
    const ptr: *allowzero i32 = @ptrFromInt(zero);
    try expect(@intFromPtr(ptr) == 0);
}

pub extern "c" fn printf(format: [*:0]const u8, ...) c_int;

test "will fail" {
    _ = printf("Hello, world!\n"); // OK

    const msg = "Hello, world!\n";
    const non_null_terminated_msg: [msg.len]u8 = msg.*;
    _ = printf(&non_null_terminated_msg);
}
