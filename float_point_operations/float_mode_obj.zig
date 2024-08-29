// build with `zig build-obj float_mode_obj.zig -O ReleaseFast`

const std = @import("std");
const big = @as(f64, 1 << 40);

export fn foo_strict(x: f64) f64 {
    return x + big - big;
}

export fn foo_optimized(x: f64) f64 {
    // By default floating point operations use Strict mode,
    // but you can switch to Optimized mode on a per-block basis
    @setFloatMode(.optimized);
    return x + big - big;
}
