//! In "Debug" and "ReleaseSafe" mode unreachable emits a call to panic with
//! the message reached unreachable code. In "ReleaseFast" and "ReleaseSmall"
//! mode, the optimizer uses the assumption that unreachable code will
//! never be hit to perform optimizations.

const assert = @import("std").debug.assert;

// unreachable is used to assert that control flow will never reach a
// particular location:
test "basic math" {
    const x = 1;
    const y = 2;
    if (x + y != 3) {
        unreachable;
    }
}

// This is how std.debug.assert is implemented
fn assertImpl(ok: bool) void {
    if (!ok) unreachable; // assertion failure
}

// This test will fail because we hit unreachable.
test "this will fail" {
    assertImpl(false);
}

test "type of unreachable" {
    comptime {
        // The type of unreachable is noreturn.

        // However this assertion will still fail to compile because
        // unreachable expressions are compile errors.
        assert(@TypeOf(unreachable) == noreturn);
    }
}
