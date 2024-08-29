const expect = @import("std").testing.expect;

test "while basic" {
    var i: usize = 0;
    while (i < 10) {
        i += 1;
    }
    try expect(i == 10);
}

test "while break" {
    var i: usize = 0;
    while (true) {
        if (i == 10)
            break;
        i += 1;
    }
    try expect(i == 10);
}

test "while continue" {
    var i: usize = 0;
    while (true) {
        i += 1;
        if (i < 10)
            continue;
        break;
    }
    try expect(i == 10);
}

test "while loop continue expression" {
    var i: usize = 0;
    while (i < 10) : (i += 1) {}
    try expect(i == 10);
}

test "while loop continue expression, more complicated" {
    var i: usize = 1;
    var j: usize = 1;
    while (i * j < 2000) : ({
        i *= 2;
        j *= 3;
    }) {
        const my_ij = i * j;
        try expect(my_ij < 2000);
    }
}

// While loops are expressions. The result of the expression is the result
// of the else clause of a while loop, which is executed when the condition
// of the while loop is tested as false.
// `break`, like `return`, accepts a value parameter. This is the result of
// the while expression. When you break from a while loop, the else branch
// is not evaluated

test "while else" {
    try expect(rangeHasNumber(0, 10, 5));
    try expect(!rangeHasNumber(0, 10, 15));
}

fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            // can also use return here
            break true;
        }
    } else false;
}

test "labeled while nested break" {
    outer: while (true) {
        while (true) {
            break :outer;
        }
    }
}

test "labeled while nested continue" {
    var i: usize = 0;
    outer: while (i < 10) : (i += 1) {
        while (true) {
            continue :outer;
        }
    }
}

test "while null capture" {
    var sum1: u32 = 0;
    numbers_left = 3;
    // When the `|x|` syntax is present on a while expression,
    // the while condition must have an Optional Type.
    while (eventuallyNullSequence()) |value| {
        sum1 += value;
    }
    try expect(sum1 == 3);

    // null capture with an else block
    var sum2: u32 = 0;
    numbers_left = 3;
    while (eventuallyNullSequence()) |value| {
        sum2 += value;
    } else {
        // The else branch is allowed on optional iteration.
        // In this case, it will be executed on the first null value encountered.
        try expect(sum2 == 3);
    }

    // null capture with a continue expression
    var i: u32 = 0;
    var sum3: u32 = 0;
    numbers_left = 3;
    while (eventuallyNullSequence()) |value| : (i += 1) {
        sum3 += value;
    }
    try expect(i == 3);
}

var numbers_left: u32 = undefined;
fn eventuallyNullSequence() ?u32 {
    return if (numbers_left == 0) null else blk: {
        numbers_left -= 1;
        break :blk numbers_left;
    };
}

test "while error union capture" {
    var sum1: u32 = 0;
    numbers_left2 = 3;
    while (eventuallyErrorSequence()) |value| {
        sum1 += value;
    } else |err| {
        // When the `else |x|` syntax is present on a while expression,
        // the while condition must have an Error Union Type.
        try expect(err == error.ReachedZero);
    }
}

var numbers_left2: u32 = undefined;

fn eventuallyErrorSequence() anyerror!u32 {
    return if (numbers_left2 == 0) error.ReachedZero else blk: {
        numbers_left2 -= 1;
        break :blk numbers_left2;
    };
}

// While loops can be inlined. This causes the loop to be unrolled,
// which allows the code to do some things which only work at
// compile time, such as use types as first class values
// It is recommended to use inline loops only for one of these reasons:
// - You need the loop to execute at comptime for the semantics to work.
// - You have a benchmark to prove that forcibly unrolling the loop in this way
//   is measurably faster.
test "inline while loop" {
    comptime var i = 0;
    var sum: usize = 0;
    inline while (i < 3) : (i += 1) {
        const T = switch (i) {
            0 => f32,
            1 => i8,
            2 => bool,
            else => unreachable,
        };
        sum += typeNameLength(T);
    }
    try expect(sum == 9);
}

fn typeNameLength(comptime T: type) usize {
    return @typeName(T).len;
}
