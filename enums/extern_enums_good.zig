//! For a C-ABI-compatible enum, provide an explicit tag type to the enum

const Foo = enum(c_int) { a, b, c };
export fn entry(foo: Foo) void {
    _ = foo;
}
