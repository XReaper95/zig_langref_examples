//! Zig has many instances of undefined behavior. If undefined behavior
//! is detected at compile-time, Zig emits a compile error and refuses to
//! continue. Most undefined behavior that cannot be detected at compile-time
//! can be detected at runtime. In these cases, Zig has safety checks.
//! Safety checks can be disabled on a per-block basis with @setRuntimeSafety.
//! The ReleaseFast and ReleaseSmall build modes disable all safety checks
//! (except where overridden by @setRuntimeSafety) in order to facilitate
//! optimizations.
//!
//! Note: for the runtime examples to work, compile time examples must
//! be commented.

// example stack trace
test "safety check" {
    unreachable;
}
