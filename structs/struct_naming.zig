//! Since all structs are anonymous, Zig infers the type name based on a few rules.
//! - If the struct is in the initialization expression of a variable,
//!   it gets named after that variable.
//! - If the struct is in the return expression, it gets named after the function
//!   it is returning from, with the parameter values serialized.
//! - Otherwise, the struct gets a name such as (filename.funcname.__struct_ID).
//! - If the struct is declared inside another struct, it gets named after both the
//! - parent struct and the name inferred by the previous rules, separated by a dot.

const std = @import("std");

pub fn main() void {
    const Foo = struct {};
    const Parent = struct {
        const Child = struct {};
    };
    const child = Parent.Child{};
    std.debug.print("variable: {s}\n", .{@typeName(Foo)});
    std.debug.print("anonymous: {s}\n", .{@typeName(struct {})});
    std.debug.print("function: {s}\n", .{@typeName(List(i32))});
    std.debug.print("nested: {s}\n", .{@typeName(@TypeOf(child))});
}

fn List(comptime T: type) type {
    return struct {
        x: T,
    };
}
