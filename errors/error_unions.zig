//! An error set type and normal type can be combined with the ! binary operator
//! to form an error union type. You are likely to use an error union type more
//! often than an error set type by itself.

const std = @import("std");
const maxInt = std.math.maxInt;

// Notice the return type is `!u64`. This means that the function either returns
// an unsigned 64 bit integer, or an error. We left off the error set to the
// left of the !, so the error set is inferred.
// Within the function definition, you can see some return statements that
// return an error, and at the bottom a return statement that returns a `u64`.
// Both types coerce to `anyerror!u64`
pub fn parseU64(buf: []const u8, radix: u8) !u64 {
    var x: u64 = 0;

    for (buf) |c| {
        const digit = charToDigit(c);

        if (digit >= radix) {
            return error.InvalidChar;
        }

        // x *= radix
        var ov = @mulWithOverflow(x, radix);
        if (ov[1] != 0) return error.OverFlow;

        // x += digit
        ov = @addWithOverflow(ov[0], digit);
        if (ov[1] != 0) return error.OverFlow;
        x = ov[0];
    }

    return x;
}

fn charToDigit(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'A'...'Z' => c - 'A' + 10,
        'a'...'z' => c - 'a' + 10,
        else => maxInt(u8),
    };
}

test "parse u64" {
    const result = try parseU64("1234", 10);
    try std.testing.expect(result == 1234);
}

test "parse u64 error" {
    try std.testing.expectError(error.InvalidChar, parseU64("AA", 10));
    // this literal is the max u64 value + 1
    try std.testing.expectError(error.OverFlow, parseU64("18446744073709551616", 10));
}

// What it looks like to use the `parseU64` function varies depending on what you're trying to do.
// One of the following:
//  - You want to provide a default value if it returned an error.
//  - If it returned an error then you want to return the same error.
//  - You know with complete certainty it will not return an error,
//    so want to unconditionally unwrap it.
//  - You want to take a different action for each possible error.

// Default value using catch, In this code, number will be equal to the
// successfully parsed string, or a default value of 13. The type of the
// right hand side of the binary catch operator must match the unwrapped
// error union type, or be of type noreturn.
fn doAThing(str: []u8) void {
    const number = parseU64(str, 10) catch 13;
    _ = number; // ...
}

// If you want to provide a default value with catch after performing some logic,
// you can combine catch with named Blocks
fn doAnotherThing(str: []u8) void {
    const number = parseU64(str, 10) catch blk: {
        // do things
        break :blk 13;
    };
    _ = number; // number is now initialized
}

// Do this If you wanted to return the error if you got one,
// otherwise continue with the function logic
fn doOneMoreThingThing(str: []u8) !void {
    const number = parseU64(str, 10) catch |err| return err;
    _ = number; // ...
}

// There is a shortcut for this. The try expression
fn doOneMoreThingThing2(str: []u8) !void {
    // `try` evaluates an error union expression. If it is an error, it returns
    // from the current function with the same error. Otherwise, the expression
    // results in the unwrapped value.
    const number = try parseU64(str, 10);
    _ = number; // ...
}

// Here we know for sure that "1234" will parse successfully. So we put the `unreachable`
// value on the right hand side. unreachable generates a panic in Debug and ReleaseSafe
// modes and undefined behavior in ReleaseFast and ReleaseSmall modes. So, while we're
// debugging the application, if there was a surprise error here, the application would
// crash appropriately.
const number2 = parseU64("1234", 10) catch unreachable;

// You may want to take a different action for every situation. For that,
// combine the if and switch expression
fn doYetAnotherThing(str: []u8) void {
    if (parseU64(str, 10)) |number| {
        doSomethingWithNumber(number);
    } else |err| switch (err) {
        error.Overflow => {
            // handle overflow...
        },
        // we promise that InvalidChar won't happen (or crash in debug mode if it does)
        error.InvalidChar => unreachable,
    }
}

// Finally, you may want to handle only some errors. For that, you can capture the
// unhandled errors in the else case, which now contains a narrower error set
fn doYetAnotherThing2(str: []u8) error{InvalidChar}!void {
    if (parseU64(str, 10)) |number| {
        doSomethingWithNumber(number);
    } else |err| switch (err) {
        error.Overflow => {
            // handle overflow...
        },
        else => |leftover_err| return leftover_err,
    }
}

// You must use the variable capture syntax. If you don't need the variable,
// you can capture with _ and avoid the switch
fn doADifferentThing3(str: []u8) void {
    if (parseU64(str, 10)) |number| {
        doSomethingWithNumber(number);
    } else |_| {
        // do as you'd like
    }
}

fn doSomethingWithNumber(number: u64) void {
    _ = number;
}

const expect = @import("std").testing.expect;

// You can use compile-time reflection to access the child type of an error union
test "error union" {
    var foo: anyerror!i32 = undefined;

    // Coerce from child type of an error union:
    foo = 1234;

    // Coerce from an error set:
    foo = error.SomeError;

    // Use compile-time reflection to access the payload type of an error union:
    try comptime expect(@typeInfo(@TypeOf(foo)).ErrorUnion.payload == i32);

    // Use compile-time reflection to access the error set type of an error union:
    try comptime expect(@typeInfo(@TypeOf(foo)).ErrorUnion.error_set == anyerror);
}

// Use the || operator to merge two error sets together. The resulting error set
// contains the errors of both error sets. Doc comments from the left-hand side
// override doc comments from the right-hand side. In this example, the doc
// comments for C.PathNotFound is A doc comment.
// This is especially useful for functions which return different error sets depending
// on comptime branches. For example, the Zig standard library uses
// `LinuxFileOpenError || WindowsFileOpenError` for the error set of opening files
const A = error{
    NotDir,

    /// A doc comment
    PathNotFound,
};
const B = error{
    OutOfMemory,

    /// B doc comment
    PathNotFound,
};

const C = A || B;

fn err_foo() C!void {
    return error.NotDir;
}

test "merge error sets" {
    if (err_foo()) {
        @panic("unexpected");
    } else |err| switch (err) {
        error.OutOfMemory => @panic("unexpected"),
        error.PathNotFound => @panic("unexpected"),
        error.NotDir => {},
    }
}

// Notice that when a function has an inferred error set, that function becomes
// generic and thus it becomes trickier to do certain things with it, such as
// obtain a function pointer, or have an error set that is consistent across
// different build targets. Additionally, inferred error sets are incompatible
// with recursion.
// In these situations, it is recommended to use an explicit error set. You can
// generally start with an empty error set and let compile errors guide you toward
// completing the set. These limitations may be overcomed in a future version of Zig
pub fn add_inferred(comptime T: type, a: T, b: T) !T {
    const ov = @addWithOverflow(a, b);
    if (ov[1] != 0) return error.Overflow;
    return ov[0];
}

// With an explicit error set
pub fn add_explicit(comptime T: type, a: T, b: T) Error!T {
    const ov = @addWithOverflow(a, b);
    if (ov[1] != 0) return error.Overflow;
    return ov[0];
}

const Error = error{
    Overflow,
};

test "inferred error set" {
    if (add_inferred(u8, 255, 1)) |_| unreachable else |err| switch (err) {
        error.Overflow => {}, // ok
    }
}
