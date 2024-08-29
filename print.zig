const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, {s}!\n", .{"world"});

    // Most of the time, it is more appropriate to write to stderr rather than stdout,
    // and whether or not the message is successfully written to the stream is irrelevant. For this common case, there is a simpler API:
    std.debug.print("Hello, world again!\n", .{});
}
