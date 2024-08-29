//! A variable may be specified to be a thread-local variable using the threadlocal keyword,
//! which makes each thread work with a separate instance of the variable

const std = @import("std");
const assert = std.debug.assert;

threadlocal var x: i32 = 1234;

test "thread local storage" {
    const thread1 = try std.Thread.spawn(.{}, testTls, .{});
    const thread2 = try std.Thread.spawn(.{}, testTls, .{});
    testTls();
    thread1.join();
    thread2.join();
}

fn testTls() void {
    assert(x == 1234);
    x += 1;
    assert(x == 1235);
}

// It is possible to have local variables with static lifetime by using containers inside functions.
test "static local variable" {
    try std.testing.expect(foo() == 1235);
    try std.testing.expect(foo() == 1236);
}

fn foo() i32 {
    const S = struct {
        var x: i32 = 1234;
    };
    S.x += 1;
    return S.x;
}
