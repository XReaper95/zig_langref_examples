//! For some types, @sizeOf is 0:
//!     - void
//!     - The Integers u0 and i0.
//!     - Arrays and Vectors with len 0, or with an element type
//!       that is a zero bit type.
//!     - An enum with only 1 tag.
//!     - A struct with all fields being zero bit types.
//!     - A union with only 1 field which is a zero bit type.
//! These types can only ever have one possible value, and thus
//! require 0 bits to represent. Code that makes use of these types
//! is not included in the final generated code.

export fn entry() void {
    var x: void = {};
    var y: void = {};
    x = y;
    y = x;
}

// When this turns into machine code, there is no code generated in
// the body of entry, even in Debug mode. For example, on x86_64:
// 0000000000000010 <entry>:
//   10:    55                   push   %rbp
//   11:    48 89 e5             mov    %rsp,%rbp
//   14:    5d                   pop    %rbp
//   15:    c3                   retq
//
// These assembly instructions do not have any code associated with
// the void values - they only perform the function call prologue and epilogue
// `void` can be useful for instantiating generic types.
// For example, given a Map(Key, Value), one can pass
// void for the Value type to make it into a Set

const std = @import("std");
const expect = std.testing.expect;

test "turn HashMap into a set with void" {
    var map = std.AutoHashMap(i32, void).init(std.testing.allocator);
    defer map.deinit();

    try map.put(1, {});
    try map.put(2, {});

    try expect(map.contains(2));
    try expect(!map.contains(3));

    _ = map.remove(2);
    try expect(!map.contains(2));
}

// Note that this is different from using a dummy value
// for the hash map value. By using void as the type of
// the value, the hash map entry type has no value field,
// and thus the hash map takes up less space. Further, all
// the code that deals with storing and loading the value
// is deleted, as seen above.
// void is distinct from anyopaque. void has a known size of
// 0 bytes, and anyopaque has an unknown, but non-zero, size.

// Expressions of type void are the only ones whose value can be ignored

test "ignoring expression value" {
    foo();
}

test "void is ignored" {
    returnsVoid();
}

test "explicitly ignoring expression value" {
    _ = foo();
}

fn returnsVoid() void {}

fn foo() i32 {
    return 1234;
}
