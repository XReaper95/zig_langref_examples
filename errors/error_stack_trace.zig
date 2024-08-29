// Error Return Traces make following errors easier,
// whereas a stack trace would look like this
pub fn main() void {
    foo(12);
}

fn foo(x: i32) void {
    if (x >= 5) {
        bar();
    } else {
        bang2();
    }
}

fn bar() void {
    if (baz()) {
        quux();
    } else {
        hello();
    }
}

fn baz() bool {
    return bang1();
}

fn quux() void {
    bang2();
}

fn hello() void {
    bang2();
}

fn bang1() bool {
    return false;
}

fn bang2() void {
    @panic("PermissionDenied");
}

// Here, the stack trace does not explain how the control flow
// in bar got to the hello() call. One would have to open a debugger
// or further instrument the application in order to find out. The
// error return trace, on the other hand, shows exactly how the error
// bubbled up
