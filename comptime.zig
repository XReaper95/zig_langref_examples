//! Zig places importance on the concept of whether an expression
//! is known at compile-time. There are a few different places this
//! concept is used, and these building blocks are used to keep the
//! language small, readable, and powerful.

// Compile-time parameters is how Zig implements generics.
// It is compile-time duck typing

fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

fn gimmeTheBiggerFloat(a: f32, b: f32) f32 {
    return max(f32, a, b);
}

fn gimmeTheBiggerInteger(a: u64, b: u64) u64 {
    return max(u64, a, b);
}

// In Zig, types are first-class citizens. They can be assigned to variables,
// passed as parameters to functions, and returned from functions. However,
// they can only be used in expressions which are known at compile-time, which
// is why the parameter T in the above snippet must be marked with comptime.
// A comptime parameter means that:
//      - At the callsite, the value must be known at compile-time,
//        or it is a compile error.
//      - In the function definition, the value is known at compile-time

test "try to pass a runtime type" {
    foo(false);
}

fn foo(condition: bool) void {
    // This is an error because the programmer attempted to pass a
    // value only known at run-time to a function which expects a
    // value known at compile-time, for this to work, `condition`
    // should be marked comptime
    const result = max(if (condition) f32 else u64, 1234, 5678);
    _ = result;
}

// Another way to get an error is if we pass a type that violates the
// type checker when the function is analyzed. This is what it means
// to have compile-time duck typing.

test "try to compare bools" {
    _ = max(bool, true, false);
}

// On the flip side, inside the function definition with the comptime
// parameter, the value is known at compile-time. This means that we
// actually could make this work for the bool type if we wanted to

fn max2(comptime T: type, a: T, b: T) T {
    if (T == bool) {
        return a or b;
    } else if (a > b) {
        return a;
    } else {
        return b;
    }
}

test "try to compare bools 2" {
    try @import("std").testing.expect(max2(bool, false, true) == true);
}

// This works because Zig implicitly inlines if expressions when the condition
// is known at compile-time, and the compiler guarantees that it will skip
// analysis of the branch not taken. So the actual generated function is like this
fn max3(a: bool, b: bool) bool {
    {
        return a or b;
    }
}

// All the code that dealt with compile-time known values is eliminated and
// we are left with only the necessary run-time code to accomplish the task.
// This works the same way for `switch` expressions - they are implicitly
// inlined when the target expression is compile-time known

// Compile-Time Variables
// In Zig, the programmer can label variables as comptime. This guarantees
// to the compiler that every load and store of the variable is performed
// at compile-time. Any violation of this results in a compile error.
// This combined with the fact that we can inline loops allows us to write a
// function which is partially evaluated at compile-time and partially at run-time

const expect = @import("std").testing.expect;

const CmdFn = struct {
    name: []const u8,
    func: fn (i32) i32,
};

const cmd_fns = [_]CmdFn{
    CmdFn{ .name = "one", .func = one },
    CmdFn{ .name = "two", .func = two },
    CmdFn{ .name = "three", .func = three },
};
fn one(value: i32) i32 {
    return value + 1;
}
fn two(value: i32) i32 {
    return value + 2;
}
fn three(value: i32) i32 {
    return value + 3;
}

fn performFn(comptime prefix_char: u8, start_value: i32) i32 {
    var result: i32 = start_value;
    comptime var i = 0;
    inline while (i < cmd_fns.len) : (i += 1) {
        if (cmd_fns[i].name[0] == prefix_char) {
            result = cmd_fns[i].func(result);
        }
    }
    return result;
}

test "perform fn" {
    try expect(performFn('t', 1) == 6);
    try expect(performFn('o', 0) == 1);
    try expect(performFn('w', 99) == 99);
}

// This example is a bit contrived, because the compile-time evaluation
// component is unnecessary; this code would work fine if it was all done
// at run-time. But it does end up generating different code. In this
// example, the function `performFn` is generated three different times,
// for the different values of prefix_char provided

// From the line:
// expect(performFn('t', 1) == 6);
fn performFn1(start_value: i32) i32 {
    var result: i32 = start_value;
    result = two(result);
    result = three(result);
    return result;
}

// From the line:
// expect(performFn('o', 0) == 1);
fn performFn2(start_value: i32) i32 {
    var result: i32 = start_value;
    result = one(result);
    return result;
}

// From the line:
// expect(performFn('w', 99) == 99);
fn performFn3(start_value: i32) i32 {
    var result: i32 = start_value;
    _ = &result;
    return result;
}

// Note that this happens even in a debug build. This is not a way
// to write more optimized code, but it is a way to make sure that
// what **should** happen at compile-time, **does** happen at compile-time

// Compile-Time Expressions
// In Zig, it matters whether a given expression is known at compile-time or
// run-time. A programmer can use a comptime expression to guarantee that the
// expression will be evaluated at compile-time. If this cannot be accomplished,
// the compiler will emit an error

extern fn exit() noreturn;

test "foo" {
    comptime {
        // it doesn't make sense that a program could call exit()
        // (or any other external function) at compile-time, so this is a compile error
        exit();
    }
}

// Within a comptime expression:
//      - All variables are comptime variables.
//      - All `if`, `while`, `for`, and `switch` expressions are evaluated at
//        compile-time, or emit a compile error if this is not possible.
//      - All `return` and `try` expressions are invalid (unless the function
//        itself is called at compile-time).
//      - All code with runtime side effects or depending on runtime values
//        emits a compile error.
//      - All function calls cause the compiler to interpret the function at
//        compile-time, emitting a compile error if the function tries to do
//        something that has global runtime side effects.
// This means that a programmer can create a function which is called
// both at compile-time and run-time

fn fibonacci(index: u32) u32 {
    if (index < 2) return index;
    return fibonacci(index - 1) + fibonacci(index - 2);
}

test "fibonacci" {
    const seven = 7; // works, constant with comptime value
    // var seven = 7;  // wont work, runtime variable
    // comptime var seven = 7;  // works, mutable compile-time variable

    // test fibonacci at run-time
    try expect(fibonacci(seven) == 13);

    // test fibonacci at compile-time
    try comptime expect(fibonacci(seven) == 13);
}

fn fibonacci2(index: u32) u32 {
    //if (index < 2) return index;
    return fibonacci2(index - 1) + fibonacci2(index - 2);
}

test "fibonacci 2" {
    // if we forget the base case of the recursive function,
    // the compiler produces an error which is a stack trace from
    // trying to evaluate the function at compile-time
    // Luckily, we used an unsigned integer, and so when we tried
    // to subtract 1 from 0, it triggered undefined behavior, which
    // is always a compile error if the compiler knows it happened
    try comptime expect(fibonacci2(7) == 13);
}

const assert = @import("std").debug.assert;

fn fibonacci3(index: i32) i32 {
    //if (index < 2) return index;
    return fibonacci3(index - 1) + fibonacci3(index - 2);
}

test "fibonacci 3" {
    // The compiler notices that evaluating this function at compile-time took
    // more than 1000 branches, and thus emits an error and gives up. If the
    // programmer wants to increase the budget for compile-time computation,
    // they can use a built-in function called `@setEvalBranchQuota` to change
    // the default number 1000 to something else.
    try comptime assert(fibonacci3(7) == 13);
}

fn fibonacci4(index: i32) i32 {
    if (index < 2) return index;
    return fibonacci4(index - 1) + fibonacci4(index - 2);
}

test "fibonacci 4" {
    // if we fix the base case, but put the wrong value in the assert
    // we get a compile time error
    try comptime assert(fibonacci4(7) == 99999);
}

// At container level (outside of any function), all expressions are implicitly
// comptime expressions. This means that we can use functions to initialize
// complex static data

const first_25_primes = firstNPrimes(25);
const sum_of_first_25_primes = sum(&first_25_primes);

fn firstNPrimes(comptime n: usize) [n]i32 {
    var prime_list: [n]i32 = undefined;
    var next_index: usize = 0;
    var test_number: i32 = 2;
    while (next_index < prime_list.len) : (test_number += 1) {
        var test_prime_index: usize = 0;
        var is_prime = true;
        while (test_prime_index < next_index) : (test_prime_index += 1) {
            if (test_number % prime_list[test_prime_index] == 0) {
                is_prime = false;
                break;
            }
        }
        if (is_prime) {
            prime_list[next_index] = test_number;
            next_index += 1;
        }
    }
    return prime_list;
}

// Note that we did not have to do anything special with the syntax of these
// functions. For example, we could call the sum function as is with a slice of
// numbers whose length and values were only known at run-time
fn sum(numbers: []const i32) i32 {
    var result: i32 = 0;
    for (numbers) |x| {
        result += x;
    }
    return result;
}

test "variable values" {
    // we can use `comptime` here to guarantee the evaluation or an error,
    // but even without it, it is implicitly comptime
    try @import("std").testing.expect(sum_of_first_25_primes == 1060);
}

// When we compile this program, Zig generates the constants with the answer
// pre-computed. Here are the lines from the generated LLVM IR
// @0 = internal unnamed_addr constant [25 x i32] [i32 2, i32 3, i32 5, i32 7, i32 11, i32 13, i32 17, i32 19, i32 23, i32 29, i32 31, i32 37, i32 41, i32 43, i32 47, i32 53, i32 59, i32 61, i32 67, i32 71, i32 73, i32 79, i32 83, i32 89, i32 97]
// @1 = internal unnamed_addr constant i32 1060

// Generic Data Structures
// Zig uses comptime capabilities to implement generic data structures
// without introducing any special-case syntax

fn List(comptime T: type) type {
    return struct {
        items: []T,
        len: usize,
    };
}

// The generic List data structure can be instantiated by passing in a type:
var buffer: [10]i32 = undefined;

// That's it. It's a function that returns an anonymous struct.
// For the purposes of error messages and debugging, Zig infers the
// name "List(i32)" from the function name and parameters invoked when
// creating the anonymous struct
var list = List(i32){
    .items = &buffer,
    .len = 0,
};

// To explicitly give a type a name, we assign it to a constant,
// in this example, the Node struct refers to itself. This works
// because all top level declarations are order-independent. As long
// as the compiler can determine the size of the struct, it is free
// to refer to itself. In this case, Node refers to itself as a pointer,
// which has a well-defined size at compile time, so it works fine.
const Node = struct {
    next: ?*Node,
    name: []const u8,
};

const mem = @import("std").mem;

test "nodes" {
    var node_a = Node{
        .next = null,
        .name = "Node A",
    };

    const node_b = Node{
        .next = &node_a,
        .name = "Node B",
    };

    const node = node_b;

    try expect(mem.eql(u8, node.name, "Node B"));
    try expect(mem.eql(u8, node.next.?.*.name, "Node A"));
    try expect(node.next.?.next == null);
}
