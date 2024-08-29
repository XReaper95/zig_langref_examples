//!A bare union defines a set of possible types that a value can be as a list of fields.
//! Only one field can be active at a time. The in-memory representation of bare unions
//! is not guaranteed. Bare unions cannot be used to reinterpret memory. For that,
//! use @ptrCast, or use an extern union or a packed union which have guaranteed in-memory
//! layout. Accessing the non-active field is safety-checked Undefined Behavior

const std = @import("std");
const expect = std.testing.expect;

const Payload = union {
    int: i64,
    float: f64,
    boolean: bool,
};

test "simple union" {
    var payload = Payload{ .int = 1234 };
    payload.float = 12.34;
}

test "simple union activate another field" {
    var payload = Payload{ .int = 1234 };
    try expect(payload.int == 1234);
    payload = Payload{ .float = 12.34 };
    try expect(payload.float == 12.34);
}

const ComplexTypeTag = enum {
    ok,
    not_ok,
};
const ComplexType = union(ComplexTypeTag) {
    ok: u8,
    not_ok: void,
};

// or, mixing both
const TaggedComplexType = union(enum) {
    ok: u8,
    not_ok: void,
};

test "switch on tagged union" {
    const c = ComplexType{ .ok = 42 };
    try expect(@as(ComplexTypeTag, c) == ComplexTypeTag.ok);

    switch (c) {
        ComplexTypeTag.ok => |value| try expect(value == 42),
        ComplexTypeTag.not_ok => unreachable,
    }

    const c2 = TaggedComplexType{ .ok = 42 };

    switch (c2) {
        TaggedComplexType.ok => |value| try expect(value == 42),
        TaggedComplexType.not_ok => unreachable,
    }
}

test "get tag type" {
    try expect(std.meta.Tag(ComplexType) == ComplexTypeTag);
}

test "modify tagged union in switch" {
    var c = ComplexType{ .ok = 42 };

    switch (c) {
        // use `*` to modify the payload of an union value
        ComplexTypeTag.ok => |*value| value.* += 1,
        ComplexTypeTag.not_ok => unreachable,
    }

    try expect(c.ok == 43);
}

// Unions can be made to infer the enum tag type and have methods like struct and enums
const Variant = union(enum) {
    int: i32,
    boolean: bool,

    // void can be omitted when inferring enum tag type.
    none,

    fn truthy(self: Variant) bool {
        return switch (self) {
            Variant.int => |x_int| x_int != 0,
            Variant.boolean => |x_bool| x_bool,
            Variant.none => false,
        };
    }
};

test "union method" {
    var v1: Variant = .{ .int = 1 };
    var v2: Variant = .{ .boolean = false };
    var v3: Variant = .none;

    try expect(v1.truthy());
    try expect(!v2.truthy());
    try expect(!v3.truthy());
}

const Small2 = union(enum) {
    a: i32,
    b: bool,
    c: u8,
};

test "@tagName" {
    try expect(std.mem.eql(u8, @tagName(Small2.a), "a"));
}

// An extern union has memory layout guaranteed to be compatible with the target C ABI.
// A packed union has well-defined in-memory layout and is eligible to be in a packed struct.

const Number = union {
    int: i32,
    float: f64,
};

test "anonymous union literal syntax" {
    const i: Number = .{ .int = 42 }; // anonymous
    const f = makeNumber();
    try expect(i.int == 42);
    try expect(f.float == 12.34);
}

fn makeNumber() Number {
    return .{ .float = 12.34 }; // anonymous
}
