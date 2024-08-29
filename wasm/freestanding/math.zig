//! Zig supports building for WebAssembly out of the box. For host environments
//! like the web browser and nodejs, build as an executable using the freestanding
//! OS target.

// Example for nodejs, compile with :
// `zig build-exe math.zig -target wasm32-freestanding -fno-entry --export=add`

extern fn print(i32) void;

export fn add(a: i32, b: i32) void {
    print(a + b);
}
