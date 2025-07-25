//! opaque {} declares a new type with an unknown (but non-zero) size and alignment.
//! It can contain declarations the same as structs, unions, and enums.
//! This is typically used for type safety when interacting with C code that does
//! not expose struct details

const Derp = opaque {};
const Wat = opaque {};

extern fn bar(d: *Derp) void;

fn foo(w: *Wat) callconv(.C) void {
    bar(w);
}

test "call foo" {
    foo(undefined);
}
