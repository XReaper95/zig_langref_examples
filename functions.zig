const std = @import("std");
const builtin = @import("builtin");
const native_arch = builtin.cpu.arch;
const expect = std.testing.expect;

// Functions are declared like this
fn add(a: i8, b: i8) i8 {
    if (a == 0) {
        return b;
    }

    return a + b;
}

// The export specifier makes a function externally visible in the generated
// object file, and makes it use the C ABI.
export fn sub(a: i8, b: i8) i8 {
    return a - b;
}

// The extern specifier is used to declare a function that will be resolved
// at link time, when linking statically, or at runtime, when linking
// dynamically. The quoted identifier after the extern keyword specifies
// the library that has the function. (e.g. "c" -> libc.so)
// The callconv specifier changes the calling convention of the function.
const WINAPI: std.builtin.CallingConvention = if (native_arch == .x86) .Stdcall else .C;
extern "kernel32" fn ExitProcess(exit_code: u32) callconv(WINAPI) noreturn;
extern "c" fn atan2(a: f64, b: f64) f64;

// The @setCold builtin tells the optimizer that a function is rarely called.
fn abort() noreturn {
    @setCold(true);
    while (true) {}
}

// The naked calling convention makes a function not have any function prologue or epilogue.
// This can be useful when integrating with assembly.
fn _start() callconv(.Naked) noreturn {
    abort();
}

// The inline calling convention forces a function to be inlined at all call sites.
// If the function cannot be inlined, it is a compile-time error.
inline fn shiftLeftOne(a: u32) u32 {
    return a << 1;
}

// The pub specifier allows the function to be visible when importing.
// Another file can use @import and call sub2
pub fn sub2(a: i8, b: i8) i8 {
    return a - b;
}

// Function pointers are prefixed with `*const `.
const Call2Op = *const fn (a: i8, b: i8) i8;
fn doOp(fnCall: Call2Op, op1: i8, op2: i8) i8 {
    return fnCall(op1, op2);
}

// There is a difference between a function body and a function pointer.
// Function bodies are comptime-only types while function Pointers may be runtime-known
test "function" {
    try expect(doOp(add, 5, 6) == 11);
    try expect(doOp(sub2, 5, 6) == -1);
}

// Primitive types such as Integers and Floats passed as parameters are copied,
// and then the copy is available in the function body. This is called "passing by value".
// Copying a primitive type is essentially free and typically involves nothing
// more than setting a register.
// Structs, unions, and arrays can sometimes be more efficiently passed as a reference,
// since a copy could be arbitrarily expensive depending on the size. When these types
// are passed as parameters, Zig may choose to copy and pass by value, or pass by reference,
// whichever way Zig decides will be faster. This is made possible, in part, by the fact
// that parameters are immutable.
// For extern functions, Zig follows the C ABI for passing structs and unions by value.

const Point = struct {
    x: i32,
    y: i32,
};

fn foo(point: Point) i32 {
    // Here, `point` could be a reference, or a copy. The function body
    // can ignore the difference and treat it as a value. Be very careful
    // taking the address of the parameter - it should be treated as if
    // the address will become invalid when the function returns.
    return point.x + point.y;
}

test "pass struct to function" {
    try expect(foo(Point{ .x = 1, .y = 2 }) == 3);
}

// Function parameters can be declared with anytype in place of the type.
// In this case the parameter types will be inferred when the function is called.
// Use @TypeOf and @typeInfo to get information about the inferred type

fn addFortyTwo(x: anytype) @TypeOf(x) {
    return x + 42;
}

test "fn type inference" {
    try expect(addFortyTwo(1) == 43);
    try expect(@TypeOf(addFortyTwo(1)) == comptime_int);
    const y: i64 = 2;
    try expect(addFortyTwo(y) == 44);
    try expect(@TypeOf(addFortyTwo(y)) == i64);
}

// Adding the inline keyword to a function definition makes that function
// become semantically inlined at the callsite. This is not a hint to be
// possibly observed by optimization passes, but has implications on the
// types and values involved in the function call. Unlike normal function
// calls, arguments at an inline function callsite which are compile-time
// known are treated as Compile Time Parameters. This can potentially
// propagate all the way to the return value

test "inline function call" {
    if (foo2(1200, 34) != 1234) {
        @compileError("bad");
    }
}

// If inline is removed, the test fails with the compile error instead of passing.
inline fn foo2(a: i32, b: i32) i32 {
    return a + b;
}

// It is generally better to let the compiler decide when to inline a function,
// except for these scenarios:
//  - To change how many stack frames are in the call stack, for debugging purposes.
//  - To force comptime-ness of the arguments to propagate to the return value of the
//    function, as in the above example.
//  - Real world performance measurements demand it.
// Note that inline actually restricts what the compiler is allowed to do.
// This can harm binary size, compilation speed, and even runtime performance

const math = std.math;
const testing = std.testing;

test "fn reflection" {
    try testing.expect(@typeInfo(@TypeOf(testing.expect)).Fn.params[0].type.? == bool);
    try testing.expect(@typeInfo(@TypeOf(testing.tmpDir)).Fn.return_type.? == testing.TmpDir);

    try testing.expect(@typeInfo(@TypeOf(math.Log2Int)).Fn.is_generic);
}
