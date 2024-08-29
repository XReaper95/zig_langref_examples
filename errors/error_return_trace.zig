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
// make this clear.
// This debugging feature makes it easier to iterate quickly on code that robustly
// handles all error conditions. This means that Zig developers will naturally find
// themselves writing correct, robust code in order to increase their development pace.
// Error Return Traces are enabled by default in Debug and ReleaseSafe builds and disabled
// by default in ReleaseFast and ReleaseSmall builds.

// There are a few ways to activate this error return tracing feature:
//  - Return an error from main
//  - An error makes its way to catch unreachable and you have not
//    overridden the default panic handler
//  - Use errorReturnTrace to access the current return trace.
//    You can use std.debug.dumpStackTrace to print it. This function
//    returns comptime-known null when building without error return
//    tracing support.

// ====================== Implementation Details ======================
// To analyze performance cost, there are two cases:
//  - when no errors are returned
//  - when returning errors

// For the case when no errors are returned, the cost is a single memory
// write operation, only in the first non-failable function in the call
// graph that calls a failable function, i.e. when a function returning
// void calls a function returning error. This is to initialize this struct
// in the stack memory

const N = 99; // to avoid compilation error forthis example

pub const StackTrace = struct {
    index: usize,
    instruction_addresses: [N]usize,
};

// Here, N is the maximum function call depth as determined by call graph analysis.
// Recursion is ignored and counts for 2.
// A pointer to StackTrace is passed as a secret parameter to every function that can
// return an error, but it's always the first parameter, so it can likely sit in a
// register and stay there. That's it for the path when no errors occur. It's practically
// free in terms of performance.

// When generating the code for a function that returns an error, just before the return
// statement (only for the return statements that return errors), Zig generates a call to
// this function

// marked as "no-inline" in LLVM IR
fn __zig_return_error(stack_trace: *StackTrace) void {
    stack_trace.instruction_addresses[stack_trace.index] = @returnAddress();
    stack_trace.index = (stack_trace.index + 1) % N;
}

// The cost is 2 math operations plus some memory reads and writes. The memory
// accessed is constrained and should remain cached for the duration of the error
// return bubbling.
// As for code size cost, 1 function call before a return statement is no big deal.
// Even so, there are plans to make the call to __zig_return_error a tail call, which
// brings the code size cost down to actually zero. What is a return statement in code
// without error return tracing can become a jump instruction in code with error return
// tracing
