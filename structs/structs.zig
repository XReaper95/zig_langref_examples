// Declare a struct.
// Zig gives no guarantees about the order of fields and the size of
// the struct but the fields are guaranteed to be ABI-aligned.
const Point = struct {
    x: f32,
    y: f32,
};

// Maybe we want to pass it to OpenGL so we want to be particular about
// how the bytes are arranged.
const Point2 = packed struct {
    x: f32,
    y: f32,
};

// Declare an instance of a struct.
const p = Point{
    .x = 0.12,
    .y = 0.34,
};

// Maybe we're not ready to fill out some of the fields.
var p2 = Point{
    .x = 0.12,
    .y = undefined,
};

// Structs can have methods
// Struct methods are not special, they are only namespaced
// functions that you can call with dot syntax.
const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn dot(self: Vec3, other: Vec3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }
};

const expect = @import("std").testing.expect;
test "dot product" {
    const v1 = Vec3.init(1.0, 0.0, 0.0);
    const v2 = Vec3.init(0.0, 1.0, 0.0);
    try expect(v1.dot(v2) == 0.0);

    // Other than being available to call with dot syntax, struct methods are
    // not special. You can reference them as any other declaration inside
    // the struct:
    try expect(Vec3.dot(v1, v2) == 0.0);
}

// Structs can have declarations.
// Structs can have 0 fields.
const Empty = struct {
    pub const PI = 3.14;
};
test "struct namespaced variable" {
    try expect(Empty.PI == 3.14);
    try expect(@sizeOf(Empty) == 0);

    // you can still instantiate an empty struct
    const does_nothing = Empty{};

    _ = does_nothing;
}

// struct field order is determined by the compiler for optimal performance.
// however, you can still calculate a struct base pointer given a field pointer:
fn setYBasedOnX(x: *f32, y: f32) void {
    const point: *Point = @fieldParentPtr("x", x);
    point.y = y;
}
test "field parent pointer" {
    var point = Point{
        .x = 0.1234,
        .y = 0.5678,
    };
    setYBasedOnX(&point.x, 0.9);
    try expect(point.y == 0.9);
}

// You can return a struct from a function. This is how we do generics
// in Zig:
fn LinkedList(comptime T: type) type {
    return struct {
        pub const Node = struct {
            prev: ?*Node,
            next: ?*Node,
            data: T,
        };

        first: ?*Node,
        last: ?*Node,
        len: usize,
    };
}

test "linked list" {
    // Functions called at compile-time are memoized. This means you can
    // do this:
    try expect(LinkedList(i32) == LinkedList(i32));

    const list = LinkedList(i32){
        .first = null,
        .last = null,
        .len = 0,
    };
    try expect(list.len == 0);

    // Since types are first class values you can instantiate the type
    // by assigning it to a variable:
    const ListOfInts = LinkedList(i32);
    try expect(ListOfInts == LinkedList(i32));

    var node = ListOfInts.Node{
        .prev = null,
        .next = null,
        .data = 1234,
    };
    const list2 = LinkedList(i32){
        .first = &node,
        .last = &node,
        .len = 1,
    };

    // When using a pointer to a struct, fields can be accessed directly,
    // without explicitly dereferencing the pointer.
    // So you can do
    try expect(list2.first.?.data == 1234);
    // instead of try expect(list2.first.?.*.data == 1234);
}

// Each struct field may have an expression indicating the default field value.
// Such expressions are executed at comptime, and allow the field to be omitted
// in a struct literal expression

const Foo = struct {
    a: i32 = 1234,
    b: i32,
};

test "default struct initialization fields" {
    const x: Foo = .{
        .b = 5,
    };
    if (x.a + x.b != 1239) {
        comptime unreachable;
    }
}

// An extern struct has in-memory layout matching the C ABI for the target.
// If well-defined in-memory layout is not required, struct is a better choice
// because it places fewer restrictions on the compiler.

// Unlike normal structs, packed structs have guaranteed in-memory layout:
// - Fields remain in the order declared, least to most significant.
// - There is no padding between fields.
// - Zig supports arbitrary width Integers and although normally,
//   integers with fewer than 8 bits will still use 1 byte of memory,
//   in packed structs, they use exactly their bit width.
// - bool fields use exactly 1 bit.
// - An enum field uses exactly the bit width of its integer tag type.
// - A packed union field uses exactly the bit width of the union field with the largest bit width.

const native_endian = @import("builtin").target.cpu.arch.endian();

const Full = packed struct {
    number: u16,
};
const Divided = packed struct {
    half1: u8,
    quarter3: u4,
    quarter4: u4,
};

test "@bitCast between packed structs" {
    try doTheTest();
    try comptime doTheTest();
}

fn doTheTest() !void {
    try expect(@sizeOf(Full) == 2);
    try expect(@sizeOf(Divided) == 2);
    const full = Full{ .number = 0x1234 };
    const divided: Divided = @bitCast(full);
    try expect(divided.half1 == 0x34);
    try expect(divided.quarter3 == 0x2);
    try expect(divided.quarter4 == 0x1);

    const ordered: [2]u8 = @bitCast(full);
    switch (native_endian) {
        .big => {
            try expect(ordered[0] == 0x12);
            try expect(ordered[1] == 0x34);
        },
        .little => {
            try expect(ordered[0] == 0x34);
            try expect(ordered[1] == 0x12);
        },
    }
}

// The backing integer is inferred from the fields' total bit width.
// Optionally, it can be explicitly provided and enforced at compile time
test "missized packed struct" {
    const S = packed struct(u32) { a: u16, b: u8 };
    _ = S{ .a = 4, .b = 2 };
}

// Zig allows the address to be taken of a non-byte-aligned field
const BitField = packed struct {
    a: u3,
    b: u3,
    c: u2,
};

var foo = BitField{
    .a = 1,
    .b = 2,
    .c = 3,
};

test "pointer to non-byte-aligned field" {
    const ptr = &foo.b;
    try expect(ptr.* == 2);
}

// However, the pointer to a non-byte-aligned field has special properties
// and cannot be passed when a normal pointer is expected
test "pointer to non-byte-aligned field 2" {
    try expect(bar(&foo.b) == 2);
}

// In this case, the function bar cannot be called because the pointer to
// the non-ABI-aligned field mentions the bit offset,
// but the function expects an ABI-aligned pointer
fn bar(x: *const u3) u3 {
    return x.*;
}

// Pointers to non-ABI-aligned fields share the same address
// as the other fields within their host integer
test "pointers of sub-byte-aligned fields share addresses" {
    try expect(@intFromPtr(&foo.a) == @intFromPtr(&foo.b));
    try expect(@intFromPtr(&foo.a) == @intFromPtr(&foo.c));
}

test "offsets of non-byte-aligned fields" {
    comptime {
        try expect(@bitOffsetOf(BitField, "a") == 0);
        try expect(@bitOffsetOf(BitField, "b") == 3);
        try expect(@bitOffsetOf(BitField, "c") == 6);

        try expect(@offsetOf(BitField, "a") == 0);
        try expect(@offsetOf(BitField, "b") == 0);
        try expect(@offsetOf(BitField, "c") == 0);
    }
}

// Packed structs have the same alignment as their backing integer, however,
// overaligned pointers to packed structs can override this
const S2 = packed struct {
    a: u32,
    b: u32,
};

test "overaligned pointer to packed struct" {
    var foo2: S2 align(4) = .{ .a = 1, .b = 2 };
    const ptr: *align(4) S2 = &foo2;
    const ptr_to_b: *u32 = &ptr.b;
    try expect(ptr_to_b.* == 2);
}

const std = @import("std");
const expectEqual = std.testing.expectEqual;

test "aligned struct fields" {
    const S3 = struct {
        a: u32 align(2),
        b: u32 align(64),
    };
    var foo3 = S3{ .a = 1, .b = 2 };

    try expectEqual(64, @alignOf(S3));
    try expectEqual(*align(2) u32, @TypeOf(&foo3.a));
    try expectEqual(*align(64) u32, @TypeOf(&foo3.b));
}

// Using packed structs with volatile is problematic, and may be a compile
// error in the future. For details on this subscribe
// to this issue (https://github.com/ziglang/zig/issues/1761).

// Zig allows omitting the struct type of a literal. When the result is coerced,
// the struct literal will directly instantiate the result location, with no copy
test "anonymous struct literal" {
    const pt: Point = .{
        .x = 13,
        .y = 67,
    };
    try expect(pt.x == 13);
    try expect(pt.y == 67);
}

// The struct type can be inferred. Here the result location does not include a type,
// and so Zig infers the type

test "fully anonymous struct" {
    try check(.{
        .int = @as(u32, 1234),
        .float = @as(f64, 12.34),
        .b = true,
        .s = "hi",
    });
}

fn check(args: anytype) !void {
    try expect(args.int == 1234);
    try expect(args.float == 12.34);
    try expect(args.b);
    try expect(args.s[0] == 'h');
    try expect(args.s[1] == 'i');
}

// Anonymous structs can be created without specifying field names,
// and are referred to as "tuples". The fields are implicitly named
// using numbers starting from 0. Because their names are integers,
// they cannot be accessed with . syntax without also wrapping them in @"".
// Names inside @"" are always recognised as identifiers.
test "tuple" {
    const values = .{
        @as(u32, 1234),
        @as(f64, 12.34),
        true,
        "hi",
    } ++ .{false} ** 2;
    try expect(values[0] == 1234);
    try expect(values[4] == false);
    inline for (values, 0..) |v, i| {
        if (i != 2) continue;
        try expect(v);
    }
    try expect(values.len == 6);
    try expect(values.@"3"[0] == 'h');
}
