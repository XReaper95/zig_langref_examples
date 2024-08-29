//! C Translation makes a best-effort attempt to translate function-like macros into
//! equivalent Zig functions. Since C macros operate at the level of lexical tokens,
//! not all C macros can be translated to Zig. Macros that cannot be translated will be
//! demoted to @compileError. Note that C code which uses macros will be translated without
//! any additional issues (since Zig operates on the pre-processed source with macros
//! expanded). It is merely the macros themselves which may not be translatable to Zig.

// For example
// #define MAKELOCAL(NAME, INIT) int NAME = INIT
// int foo(void) {
//    MAKELOCAL(a, 1);
//    MAKELOCAL(b, 2);
//    return a + b;
// }

// `zig translate-c macro.c > macro.zig` produces:
pub export fn foo() c_int {
    var a: c_int = 1;
    _ = &a;
    var b: c_int = 2;
    _ = &b;
    return a + b;
}
pub const MAKELOCAL =
    @compileError("unable to translate C expr: unexpected token .Equal"); // macro.c:1:9

// Note that foo was translated correctly despite using a non-translatable macro.
// MAKELOCAL was demoted to @compileError since it cannot be expressed as a Zig
// function; this simply means that you cannot directly use MAKELOCAL from Zig.
