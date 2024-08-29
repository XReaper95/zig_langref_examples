// `const` applies to all of the bytes that the identifier immediately addresses.
// Pointers have their own const-ness.
const x = 1234;

// Container level variables have static lifetime and are order-independent and lazily analyzed.
// The initialization value of container level variables is implicitly comptime.
// If a container level variable is const then its value is comptime-known, otherwise it is runtime-known.
var y1: i32 = add(10, x);
const x1: i32 = add(12, 34);

test "container level variables" {
    try std.testing.expect(x1 == 46);
    try std.testing.expect(y1 == 56);
}

fn add(a: i32, b: i32) i32 {
    return a + b;
}

// Container level variables may be declared inside a struct, union, enum, or opaque
test "namespaced container level variable" {
    try expect(foo1() == 1235);
    try expect(foo1() == 1236);
}

const S = struct {
    var x: i32 = 1234;
};

fn foo1() i32 {
    S.x += 1;
    return S.x;
}

const std = @import("std");
const expect = std.testing.expect;

fn foo() void {
    // It works at file scope as well as inside functions.
    const y = 5678;

    // variables can and must be changed
    var z: i32 = 4567;
    // var w: i32;  // error, must be initialized, same as const

    z += 1; // not mutating the variable is an error

    // undefined can be coerced to any type. Once this happens,
    // it is no longer possible to detect that the value is undefined.
    // undefined means the value could be anything, even something
    // that is nonsense according to the type.
    var uninit: i32 = undefined; // leave variable uninitialized
    uninit = 1;

    // Once assigned, an identifier cannot be changed.
    //y += 1;
    @import("std").debug.print("y: {} x: {}, z: {}, undf: {}", .{ y, x, z, uninit });
}

pub fn main() void {
    foo();
}
