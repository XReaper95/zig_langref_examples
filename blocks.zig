const std = @import("std");
const expect = std.testing.expect;

test "access variable after block scope" {
    {
        var x: i32 = 1;
        _ = &x;
    }
    x += 1;
}

test "labeled break from labeled block expression" {
    var y: i32 = 123;

    // here, blk can be any name
    const x = blk: {
        y += 1;
        break :blk y;
    };
    try expect(x == 124);
    try expect(y == 124);
}

const pi = 3.14;

// shadowing is not allowed
test "inside test block" {
    // Let's even go inside another block
    {
        var pi: i32 = 1234;
    }
}

test "separate scopes" {
    {
        const pi2 = 3.14;
        _ = pi2;
    }
    {
        var pi2: bool = true;
        _ = &pi2;
    }
}

test "empty block" {
    const a = {};
    const b = void{};
    try expect(@TypeOf(a) == void);
    try expect(@TypeOf(b) == void);
    try expect(a == b);
}
