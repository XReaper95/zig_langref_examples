//! One of the primary use cases for Zig is exporting a library with the C ABI
//! for other programming languages to call into. The `export` keyword in front
//! of functions, variables, and types causes them to be part of the library API
//! To make a static library:
//!     $ zig build-lib mathtest.zig
//! To make a shared library:
//!     $ zig build-lib mathtest.zig -dynamic

export fn add(a: i32, b: i32) i32 {
    return a + b;
}
