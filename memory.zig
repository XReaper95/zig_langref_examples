//! The Zig language performs no memory management on behalf of the programmer.
//! This is why Zig has no runtime, and why Zig code works seamlessly in so many
//! environments, including real-time software, operating system kernels, embedded
//! devices, and low latency servers.

// Like Zig, the C programming language has manual memory management.
// However, unlike Zig, C has a default allocator - `malloc`, `realloc`,
// and `free`. When linking against libc, Zig exposes this allocator with
// `std.heap.c_allocator`.
// By convention, there is no default allocator in Zig. Instead, functions
// which need to allocate accept an Allocator parameter. Likewise, data
// structures such as std.ArrayList accept an Allocator parameter in their
// initialization functions

const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

// In this example, 100 bytes of stack memory are used to initialize
// a FixedBufferAllocator, which is then passed to a function. As a
// convenience there is a global FixedBufferAllocator available for
// quick tests at std.testing.allocator, which will also perform basic
// leak detection.
test "using an allocator" {
    var buffer: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const result = try concat(allocator, "foo", "bar");
    try expect(std.mem.eql(u8, "foobar", result));
}

fn concat(allocator: Allocator, a: []const u8, b: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, a.len + b.len);
    @memcpy(result[0..a.len], a);
    @memcpy(result[a.len..], b);
    return result;
}

//
// Choosing an Allocator
// What allocator to use depends on a number of factors:
//      1. For a library is best to accept an Allocator as a
//         parameter and allow your library's users to decide
//         what allocator to use.
//      2. When linking libc: `std.heap.c_allocator` is likely
//         the right choice, at least for the main allocator.
//      3. When the maximum number of byes is know at compile-time:
//         use `std.heap.FixedBufferAllocator` or
//         `std.heap.ThreadSafeFixedBufferAllocator` depending on
//         whether thread-safety is needed or not.
//      4. When the program runs runs from start to end without any
//         fundamental cyclical pattern (like a video game main loop,
//         or a web server request handler), such that it would make sense
//         to free everything at once at the end, it is recommended to
//         follow the arena allocator pattern:
pub fn arenaAllocatorExample() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const ptr = try allocator.create(i32);
    std.debug.print("ptr={*}\n", .{ptr});
}
//         When using this kind of allocator, there is no need to free
//         anything manually. Everything gets freed at once with the call
//         to `arena.deinit()`.
//      5. If an upper bound of memory can be established,
//         then `std.heap.FixedBufferAllocator` can be used as a further
//         optimization to the previous point.
//      6. When writing a test, to make sure `error.OutOfMemory` is handled
//         correctly use `std.testing.FailingAllocator`.
//      7. When writing a regular test use `std.testing.allocator`.
//      8. If none of the above apply, use a general purpose allocator. Zig's
//         general purpose allocator is available as a function that takes a
//         comptime struct of configuration options and returns a type. Generally,
//         you will set up one `std.heap.GeneralPurposeAllocator` in your main
//         function, and then pass it or sub-allocators around to various parts of
//         your application.
//      9. You can also consider implementing an allocator, Zig programmers can
//         implement their own allocators by fulfilling the Allocator interface.
//         In order to do this one must read carefully the documentation comments
//         in "std/mem.zig" and then supply a `allocFn` and a `resizeFn`. There are
//         many example allocators to look at for inspiration. Look at "std/heap.zig ""
//         and `std.heap.GeneralPurposeAllocator`.

// Bytes are stored on different places:

// String literals such as "hello" are in the global constant data section,
fn foo(s: []u8) void {
    _ = s;
}

// so this is an error
test "string literal to mutable slice" {
    foo("hello");
}

// a constant slice will work
fn foo2(s: []const u8) void {
    _ = s;
}

test "string literal to constant slice" {
    foo2("hello");
}

// Just like string literals, `const` declarations, when the value is known
// at comptime, are stored in the global constant data section, just like
// compile time variables

// `var` declarations inside functions are stored in the function's stack frame.
// Once a function returns, any Pointers to variables in the function's stack
// frame become invalid references, and dereferencing them becomes unchecked
// Undefined Behavior

// `var` declarations at the top level or in struct declarations are stored in
// the global data section.

// The location of memory allocated with allocator.alloc or allocator.create is
// determined by the allocator's implementation.

// TODO: thread local variables

// Many programming languages choose to handle the possibility of heap allocation
// failure by unconditionally crashing. By convention, Zig programmers do not consider
// this to be a satisfactory solution. Instead, `error.OutOfMemory` represents heap
// allocation failure, and Zig libraries return this error code whenever heap allocation
// failure prevented an operation from completing successfully.

// Pointers lifetime and ownership should be documented, there is no builtin borrow
// checker. Zig offers some protection using runtime checks in some build modes.
