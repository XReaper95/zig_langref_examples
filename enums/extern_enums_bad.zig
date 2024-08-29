//! By default, enums are not guaranteed to be compatible with the C ABI

const Foo = enum { a, b, c };
export fn entry(foo: Foo) void {
    _ = foo;
}
