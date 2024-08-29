const c = @cImport({
    // See https://github.com/ziglang/zig/issues/515
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
});
pub fn main() void {
    _ = c.printf("hello\n");
}

// The @cImport function takes an expression as a parameter. This expression
// is evaluated at compile-time and is used to control preprocessor directives
// and include multiple .h files
const builtin = @import("builtin");

// usually you'll want a single @cImport call
const c2 = @cImport({
    const something = true; // some condition

    @cDefine("NDEBUG", builtin.mode == .ReleaseFast);
    if (something) {
        @cDefine("_GNU_SOURCE", {});
    }
    @cInclude("stdlib.h");
    if (something) {
        @cUndef("_GNU_SOURCE");
    }
    @cInclude("soundio.h");
});
