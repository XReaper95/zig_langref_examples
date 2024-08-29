//! Zig's support for WebAssembly System Interface (WASI) is under active development.
//! Example of using the standard library and reading command line arguments
//! Compile with: `zig build-exe wasi_args.zig -target wasm32-wasi`
//! Run with: `wasmtime wasi_args.wasm 123 hello` (requires WasmTime)

const std = @import("std");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    for (args, 0..) |arg, i| {
        std.debug.print("{}: {s}\n", .{ i, arg });
    }
}
