//! This is a top level comment, generate with `zig test -femit-docs comments.zig`

const std = @import("std");

//A doc comment is one that begins with exactly three slashes (i.e. /// but not ////);
// multiple doc comments in a row are merged together to form a multiline doc comment.
/// The doc comment documents whatever immediately follows it.
/// A structure for storing a timestamp, with nanosecond precision (this is a
/// multiline doc comment).
const Timestamp = struct {
    /// The number of seconds since the epoch (this is also a doc comment).
    seconds: i64, // signed so we can represent pre-1970 (not a doc comment)
    /// The number of nanoseconds past the second (doc comment again).
    nanos: u32,

    /// Returns a `Timestamp` struct representing the Unix epoch; that is, the
    /// moment of 1970 Jan 1 00:00:00 UTC (this is a doc comment too).
    pub fn unixEpoch() Timestamp {
        return Timestamp{
            .seconds = 0,
            .nanos = 0,
        };
    }
};

pub fn main() void {
    // regular comment (ignored)
    std.debug.print("Hi\n", .{});
}
