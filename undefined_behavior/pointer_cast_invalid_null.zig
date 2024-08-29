//! This happens when casting a pointer with the address 0 to a pointer
//! which may not have the address 0. For example, C Pointers, Optional
//! Pointers, and allowzero pointers allow address zero, but normal Pointers
//! do not.

// Compile-time
comptime {
    const opt_ptr: ?*i32 = null;
    const ptr: *i32 = @ptrCast(opt_ptr);
    _ = ptr;
}

const std = @import("std");

// Run-time
pub fn main() void {
    var opt_ptr: ?*i32 = null;
    _ = &opt_ptr;
    const ptr: *i32 = @ptrCast(opt_ptr);
    _ = ptr;
}
