//! Error Return Traces show all the points in the code that an error was returned
//! to the calling function. This makes it practical to use try everywhere and then
//! still be able to know what happened if an error ends up bubbling all the way out
//! of your application

pub fn main() !void {
    try foo(12);
}

fn foo(x: i32) !void {
    if (x >= 5) {
        try bar();
    } else {
        try bang2();
    }
}

fn bar() !void {
    if (baz()) {
        try quux();
    } else |err| switch (err) {
        error.FileNotFound => try hello(),
    }
}

fn baz() !void {
    try bang1();
}

fn quux() !void {
    try bang2();
}

fn hello() !void {
    try bang2();
}

fn bang1() !void {
    return error.FileNotFound;
}

fn bang2() !void {
    return error.PermissionDenied;
}

// Look closely at this example. This is no stack trace.
// You can see that the final error bubbled up was PermissionDenied,
// but the original error that started this whole thing was FileNotFound.
// In the bar function, the code handles the original error code, and
// then returns another one, from the switch statement. Error Return Traces
// make this clear
