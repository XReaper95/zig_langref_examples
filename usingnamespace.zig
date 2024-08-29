//! `usingnamespace` is a declaration that mixes all the public
//! declarations of the operand, which must be a struct, union,
//! enum, or opaque, into the namespace

test "using std namespace" {
    const S = struct {
        usingnamespace @import("std");
    };
    try S.testing.expect(true);
}

// it has an important use case when organizing the public API of a
// file or package. For example, one might have c.zig with all of the
// C imports
pub usingnamespace @cImport({
    @cInclude("epoxy/gl.h");
    @cInclude("GLFW/glfw3.h");
    @cDefine("STBI_ONLY_PNG", "");
    @cDefine("STBI_NO_STDIO", "");
    @cInclude("stb_image.h");
});

// NOTE: this feature might or might not be removed, discussion here:
// https://github.com/ziglang/zig/issues/20663
