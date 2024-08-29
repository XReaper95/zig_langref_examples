//! During compilation, every Zig expression and sub-expression is
//! assigned optional result location information. This information
//! dictates what type the expression should have (its result type),
//! and where the resulting value should be placed in memory
//! (its result location). The information is optional in the sense
//! that not every expression has this information: assignment to _,
//! for instance, does not provide any information about the type of
//! an expression, nor does it provide a concrete memory location to
//! place it in.

// Consider:
const x: u32 = 42;
// The type annotation here provides a result type of u32 to the
// initialization expression 42, instructing the compiler to coerce
// this integer (initially of type comptime_int) to this type.

// This is not an implementation detail: the logic outlined above
// is codified into the Zig language specification, and is the primary
// mechanism of type inference in the language. This system is collectively
// referred to as "Result Location Semantics".

// Result types are propagated recursively through expressions where possible.
// The result type mechanism is utilized by casting builtins such as @intCast.
// Rather than taking as an argument the type to cast to, these builtins use
// their result type to determine this information. The result type is often
// known from context; where it is not, the @as builtin can be used to explicitly
// provide a result type.

const expectEqual = @import("std").testing.expectEqual;
test "result type propagates through struct initializer" {
    const S = struct { x: u32 };
    const val: u64 = 123;
    const s: S = .{ .x = @intCast(val) };
    // .{ .x = @intCast(val) }   has result type `S` due to the type annotation
    //         @intCast(val)     has result type `u32` due to the type of the field `S.x`
    //                  val      has no result type, as it is permitted to be any integer type
    try expectEqual(@as(u32, 123), s.x);
}

// This result type information is useful for the aforementioned cast builtins,
// as well as to avoid the construction of pre-coercion values, and to avoid
// the need for explicit type coercions in some cases.

// ======================================================================================

// In addition to result type information, every expression may be
// optionally assigned a result location: a pointer to which the value
// must be directly written. This system can be used to prevent intermediate
// copies when initializing data structures, which can be important for types
// which must have a fixed memory address ("pinned" types).
// When compiling the simple assignment expression `x = e`, many languages would
// create the temporary value e on the stack, and then assign it to x, potentially
// performing a type coercion in the process. Zig approaches this differently. The
// expression e is given a result type matching the type of x, and a result location
// of `&x`. For many syntactic forms of e, this has no practical impact. However, it
// can have important semantic effects when working with more complex syntax forms.
// For instance, if the expression `.{ .a = x, .b = y }` has a result location of ptr,
// then x is given a result location of &ptr.a, and y a result location of &ptr.b.
// Without this system, this expression would construct a temporary struct value
// entirely on the stack, and only then copy it to the destination address. In essence,
// Zig desugars the assignment foo = .{ .a = x, .b = y } to the two statements
// foo.a = x; foo.b = y;. This can sometimes be important when assigning an aggregate
// value where the initialization expression depends on the previous value of the aggregate.

test "attempt to swap array elements with array initializer" {
    var arr: [2]u32 = .{ 1, 2 };
    arr = .{ arr[1], arr[0] };
    // The previous line is equivalent to the following two lines:
    //   arr[0] = arr[1];
    //   arr[1] = arr[0];
    // So this fails!
    try expectEqual(2, arr[0]); // succeeds
    try expectEqual(1, arr[1]); // fails
}
