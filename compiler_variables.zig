//! Compile variables are accessible by importing the "builtin" package, which the
//! compiler makes available to every Zig source file. It contains compile-time
//! constants such as the current target, endianness, and release mode
const builtin = @import("builtin");
const separator = if (builtin.os.tag == .windows) '\\' else '/';

// Example of what is imported with `@import("builtin")`:

const std = @import("std");
/// Zig version. When writing code that supports multiple versions of Zig, prefer
/// feature detection (i.e. with `@hasDecl` or `@hasField`) over version checks.
pub const zig_version = std.SemanticVersion.parse(zig_version_string) catch unreachable;
pub const zig_version_string = "0.14.0-dev.1081+5d080e25d";
pub const zig_backend = std.builtin.CompilerBackend.stage2_llvm;

pub const output_mode = std.builtin.OutputMode.Exe;
pub const link_mode = std.builtin.LinkMode.static;
pub const is_test = false;
pub const single_threaded = false;
pub const abi = std.Target.Abi.gnu;
pub const cpu: std.Target.Cpu = .{
    .arch = .x86_64,
    .model = &std.Target.x86.cpu.znver2,
    .features = std.Target.x86.featureSet(&[_]std.Target.x86.Feature{
        .@"64bit",
        .adx,
        .aes,
        .allow_light_256_bit,
        .avx,
        .avx2,
        .bmi,
        .bmi2,
        .branchfusion,
        .clflushopt,
        .clwb,
        .clzero,
        .cmov,
        .crc32,
        .cx16,
        .cx8,
        .f16c,
        .fast_15bytenop,
        .fast_bextr,
        .fast_lzcnt,
        .fast_movbe,
        .fast_scalar_fsqrt,
        .fast_scalar_shift_masks,
        .fast_variable_perlane_shuffle,
        .fast_vector_fsqrt,
        .fma,
        .fsgsbase,
        .fxsr,
        .lzcnt,
        .mmx,
        .movbe,
        .mwaitx,
        .nopl,
        .pclmul,
        .popcnt,
        .prfchw,
        .rdpid,
        .rdpru,
        .rdrnd,
        .rdseed,
        .sahf,
        .sbb_dep_breaking,
        .sha,
        .slow_shld,
        .sse,
        .sse2,
        .sse3,
        .sse4_1,
        .sse4_2,
        .sse4a,
        .ssse3,
        .vzeroupper,
        .wbnoinvd,
        .x87,
        .xsave,
        .xsavec,
        .xsaveopt,
        .xsaves,
    }),
};
pub const os = std.Target.Os{
    .tag = .linux,
    .version_range = .{ .linux = .{
        .range = .{
            .min = .{
                .major = 5,
                .minor = 10,
                .patch = 0,
            },
            .max = .{
                .major = 5,
                .minor = 10,
                .patch = 0,
            },
        },
        .glibc = .{
            .major = 2,
            .minor = 31,
            .patch = 0,
        },
    } },
};
pub const target: std.Target = .{
    .cpu = cpu,
    .os = os,
    .abi = abi,
    .ofmt = object_format,
    .dynamic_linker = std.Target.DynamicLinker.init("/lib64/ld-linux-x86-64.so.2"),
};
pub const object_format = std.Target.ObjectFormat.elf;
pub const mode = std.builtin.OptimizeMode.Debug;
pub const link_libc = false;
pub const link_libcpp = false;
pub const have_error_return_tracing = true;
pub const valgrind_support = true;
pub const sanitize_thread = false;
pub const fuzz = false;
pub const position_independent_code = false;
pub const position_independent_executable = false;
pub const strip_debug_info = false;
pub const code_model = std.builtin.CodeModel.default;
pub const omit_frame_pointer = false;
