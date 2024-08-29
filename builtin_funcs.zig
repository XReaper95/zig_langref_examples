//! Builtin functions are provided by the compiler and are prefixed with @.
//! The comptime keyword on a parameter means that the parameter must be
//! known at compile time.
//!
//! See the zig documentation for details on them.

// Most importants:

// @import(comptime path: []const u8) type
// This function finds a zig file corresponding to path and adds it to the build, if it
// is not already added/ Zig source files are implicitly structs, with a name equal to
// the file's basename with the extension truncated. `@import` returns the struct type
// corresponding to the file. Declarations which have the `pub` keyword may be referenced
// from a different source file than the one they are declared in. The `path` parameter can
// be a relative path or it can be the name of a package. If it is a relative path, it is
// relative to the file that contains the @import function call.
// The following packages are always available:
//      - @import("std") - Zig Standard Library
//      - @import("builtin") - Target-specific information The command `zig build-exe
//        --show-builtin` outputs the source to stdout for reference.
//      - @import("root") - Root source file This is usually "src/main.zig" but depends
//        on what file is built.
