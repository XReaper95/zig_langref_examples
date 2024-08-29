const std = @import("std");
const print = @import("std").debug.print;

pub fn main() void {
    const thisManyCeroes = 33;
    const comptimeCeroes = comptime makeCeroes(thisManyCeroes);
    const runtimeCeroes = makeCeroes(thisManyCeroes);

    print("{d} comptime ceroes: {s}\n", .{ thisManyCeroes, comptimeCeroes });
    print("{d} runtime  ceroes: {s}\n", .{ thisManyCeroes, runtimeCeroes });
}

fn makeCeroes(comptime zeroAmount: i32) [zeroAmount]u8 {
    var buf: [zeroAmount]u8 = undefined;

    if (!@inComptime()) {
        // won't work at compile-time
        print("Hello from run-time\n", .{});
    } else {
        // compile log stops compilation if used https://github.com/ziglang/zig/issues/5469
        //@compileLog("Hello from compile-time\n");
    }

    for (0..zeroAmount) |i| {
        buf[i] = '0';
    }

    return buf;
}
