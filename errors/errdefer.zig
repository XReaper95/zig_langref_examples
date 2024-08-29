//! The other component to error handling is defer statements.
//! In addition to an unconditional defer, Zig has errdefer, which
//! evaluates the deferred expression on block exit path if and only
//! if the function returned with an error from the block.

// The neat thing about this is that you get robust error handling
// without the verbosity and cognitive overhead of trying to make
// sure every exit path is covered. The deallocation code is always
// directly following the allocation code.
fn createFoo(param: i32) !Foo {
    const foo = try tryToAllocateFoo();
    // now we have allocated foo. we need to free it if the function fails.
    // but we want to return it if the function succeeds.
    errdefer deallocateFoo(foo);

    const tmp_buf = allocateTmpBuffer() orelse return error.OutOfMemory;
    // tmp_buf is truly a temporary resource, and we for sure want to clean it up
    // before this block leaves scope
    defer deallocateTmpBuffer(tmp_buf);

    if (param > 1337) return error.InvalidParam;

    // here the errdefer will not run since we're returning success from the function.
    // but the defer will run!
    return foo;
}

extern fn allocateTmpBuffer() ?[]u8;
extern fn deallocateTmpBuffer(temBuf: []u8) void;

const std = @import("std");
const Allocator = std.mem.Allocator;

fn captureError(captured: *?anyerror) !void {
    errdefer |err| {
        captured.* = err;
    }
    return error.GeneralFailure;
}

test "errdefer capture" {
    var captured: ?anyerror = null;

    if (captureError(&captured)) unreachable else |err| {
        try std.testing.expectEqual(error.GeneralFailure, captured.?);
        try std.testing.expectEqual(error.GeneralFailure, err);
    }
}

// It should be noted that errdefer statements only last until the end
// of the block they are written in, and therefore are not run if an error
// is returned outside of that block

const Foo = struct {
    data: u32,
};

fn tryToAllocateFoo(allocator: Allocator) !*Foo {
    return allocator.create(Foo);
}

fn deallocateFoo(allocator: Allocator, foo: *Foo) void {
    allocator.destroy(foo);
}

fn getFooData() !u32 {
    return 666;
}

fn createFoo2(allocator: Allocator, param: i32) !*Foo {
    const foo = getFoo: {
        var foo = try tryToAllocateFoo(allocator);
        errdefer deallocateFoo(allocator, foo); // Only lasts until the end of getFoo

        // Calls deallocateFoo on error
        foo.data = try getFooData();

        break :getFoo foo;
    };

    // Outside of the scope of the errdefer, so
    // deallocateFoo will not be called here
    if (param > 1337) return error.InvalidParam;

    return foo;
}

test "createFoo2 bad" {
    try std.testing.expectError(error.InvalidParam, createFoo(std.testing.allocator, 2468));
}

fn createFoo3(allocator: Allocator, param: i32) !*Foo {
    const foo = getFoo: {
        var foo = try tryToAllocateFoo(allocator);
        errdefer deallocateFoo(allocator, foo);

        foo.data = try getFooData();

        break :getFoo foo;
    };
    // This lasts for the rest of the function
    errdefer deallocateFoo(allocator, foo);

    // Error is now properly handled by errdefer
    if (param > 1337) return error.InvalidParam;

    return foo;
}

test "createFoo3 god" {
    try std.testing.expectError(error.InvalidParam, createFoo(std.testing.allocator, 2468));
}

// The fact that errdefers only last for the block they are declared
// in is especially important when using loops
const Foo2 = struct { data: *u32 };

fn getData() !u32 {
    return 666;
}

fn genFoos(allocator: Allocator, num: usize) ![]Foo2 {
    const foos = try allocator.alloc(Foo2, num);
    errdefer allocator.free(foos);

    for (foos, 0..) |*foo, i| {
        foo.data = try allocator.create(u32);
        // This errdefer does not last between iterations
        errdefer allocator.destroy(foo.data);

        // The data for the first 3 foos will be leaked
        if (i >= 3) return error.TooManyFoos;

        foo.data.* = try getData();
    }

    return foos;
}

test "genFoos bad" {
    try std.testing.expectError(error.TooManyFoos, genFoos(std.testing.allocator, 5));
}

fn genFoos2(allocator: Allocator, num: usize) ![]Foo2 {
    const foos = try allocator.alloc(Foo2, num);
    errdefer allocator.free(foos);

    // Used to track how many foos have been initialized
    // (including their data being allocated)
    var num_allocated: usize = 0;
    errdefer for (foos[0..num_allocated]) |foo| {
        allocator.destroy(foo.data);
    };
    for (foos, 0..) |*foo, i| {
        foo.data = try allocator.create(u32);
        num_allocated += 1;

        if (i >= 3) return error.TooManyFoos;

        foo.data.* = try getData();
    }

    return foos;
}

test "genFoos2 good" {
    try std.testing.expectError(error.TooManyFoos, genFoos2(std.testing.allocator, 5));
}

// A couple of other tidbits about error handling:
// - These primitives give enough expressiveness that it's completely practical
//   to have failing to check for an error be a compile error. If you really want
//   to ignore the error, you can add catch unreachable and get the added benefit of
//   crashing in Debug and ReleaseSafe modes if your assumption was wrong.
// - Since Zig understands error types, it can pre-weight branches in favor of errors
//   not occurring. Just a small optimization benefit that is not available in other languages.
