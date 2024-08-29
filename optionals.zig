//! The question mark symbolizes the optional type. You can convert a type to
//! an optional type by putting a question mark in front of it

// normal integer, is always an integer
const normal_int: i32 = 1234;

// optional integer, can be an integer or `null`
const optional_int: ?i32 = 5678;

// Optionals secretly compiles down to a normal pointer, since we know we
// can use 0 as the null value for the optional type. But the compiler can
// check your work and make sure you don't assign null to something that
// can't be null. Typically the downside of not having null is that it makes
// the code more verbose to write

// Example task: call malloc, if the result is null, return null.

// ===== C code =====
// // malloc prototype included for reference
// void *malloc(size_t size);

// struct Foo *do_a_thing(void) {
//     char *ptr = malloc(1234);
//     if (!ptr) return NULL;
//     // ...
// }
// ===== C code =====

const Foo = struct {};

// malloc prototype included for reference
extern fn malloc(size: usize) ?[*]u8;

fn doAThing() ?*Foo {
    // The orelse keyword unwraps the optional type and therefore
    // `ptr` is guaranteed to be non-null everywhere it is used
    // in the function.
    const ptr = malloc(1234) orelse return null;
    _ = ptr; // ...
}

// The other form of checking against NULL

// ===== C code =====
// void do_a_thing(struct Foo *foo) {
//     // do some stuff
//
//     if (foo) {
//         do_something_with_foo(foo);
//     }
//
//     // do some stuff
// }
// ===== C code =====

fn doSomethingWithFoo(foo: *Foo) void {
    _ = foo;
}

fn doAThing2(optional_foo: ?*Foo) void {
    // do some stuff

    if (optional_foo) |foo| {
        // the notable thing here is that inside the if block,
        // foo is no longer an optional pointer, it is a
        // pointer, which cannot be null.
        doSomethingWithFoo(foo);
    }

    // do some stuff
}

// One benefit to this is that functions which take pointers as
// arguments can be annotated with the "nonnull" attribute
// (__attribute__((nonnull)) in GCC). The optimizer can sometimes
// make better decisions knowing that pointer arguments cannot be null.

// An optional is created by putting ? in front of a type. You can use
// compile-time reflection to access the child type of an optional

const expect = @import("std").testing.expect;

test "optional type" {
    // Declare an optional and coerce from null:
    var foo: ?i32 = null;

    // Coerce from child type of an optional
    foo = 1234;

    // Use compile-time reflection to access the child type of the optional:
    try comptime expect(@typeInfo(@TypeOf(foo)).Optional.child == i32);
}

// Just like undefined, null has its own type, and the only way to use it is
// to cast it to a different type
const optional_value: ?i32 = null;

// An optional pointer is guaranteed to be the same size as a pointer.
// The null of the optional is guaranteed to be address 0.
test "optional pointers" {
    // Pointers cannot be null. If you want a null pointer, use the optional
    // prefix `?` to make the pointer type optional.
    var ptr: ?*i32 = null;

    var x: i32 = 1;
    ptr = &x;

    try expect(ptr.?.* == 1);

    // Optional pointers are the same size as normal pointers, because pointer
    // value 0 is used as the null value.
    try expect(@sizeOf(?*i32) == @sizeOf(*i32));
}

const std = @import("std");

const T = struct {
    u: U,

    const U = struct { w: W };

    const W = struct { b: i32 };
};

fn maybeT() ?T {
    return T{ .u = .{ .w = .{ .b = 5 } } };
}

fn maybeT2() ?T {
    return null;
}

test "optional access" {
    var opt: ?T = maybeT();
    var opt2: ?T = maybeT2();

    if (opt) |*t| {
        t.*.u.w.b = 2;
    }

    if (opt2) |*t| {
        t.*.u.w.b = 4;
    }

    try expect(opt.?.u.w.b == 2);
    try expect(opt2 == null);
}
