// Compile-time
comptime {
    assert(false);
}
fn assert(ok: bool) void {
    if (!ok) unreachable; // assertion failure
}

const std = @import("std");

// Run-time
pub fn main() void {
    std.debug.assert(false);
}
