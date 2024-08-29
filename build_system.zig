//! The Zig Build System provides a cross-platform, dependency-free way to declare
//! the logic required to build a project. With this system, the logic to build a
//! project is written in a "build.zig" file, using the Zig Build System API to declare
//! and configure build artifacts and other tasks.
//! Zig has four build modes:
//! - Debug (default)
//! - ReleaseFast
//! - ReleaseSafe
//! - ReleaseSmall

const std = @import("std");

// should be on a "build.zig" file
pub fn build(b: *std.Build) void {
    // add standard options:
    // - `-Doptimize=Debug`: Optimizations off and safety on (default)
    // - `-Doptimize=ReleaseSafe`: Optimizations on and safety on
    // - `-Doptimize=ReleaseFast`: Optimizations on and safety off
    // - `-Doptimize=ReleaseSmall`: Size optimizations on and safety off
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("example.zig"),
        .optimize = optimize,
    });
    b.default_step.dependOn(&exe.step);
}
//These commands should be run in a folder containing a `build.zig` and `example.zig` files
// Debug (`zig build-exe example.zig`):
//      - Fast compilation speed
//      - Safety checks enabled
//      - Slow runtime performance
//      - Large binary size
//      - No reproducible build requirement
// ReleaseFast (`zig build-exe example.zig -O ReleaseFast`):
//      - Fast runtime performance
//      - Safety checks disabled
//      - Slow compilation speed
//      - Large binary size
//      - Reproducible build
// ReleaseSafe (`zig build-exe example.zig -O ReleaseSafe`):
//      - Medium runtime performance
//      - Safety checks enabled
//      - Slow compilation speed
//      - Large binary size
//      - Reproducible build
// ReleaseSmall (`zig build-exe example.zig -O ReleaseSmall`):
//      - Medium runtime performance
//      - Safety checks disabled
//      - Slow compilation speed
//      - Small binary size
//      - Reproducible build

// Single Threaded Builds
// Zig has a compile option `-fsingle-threaded` which has the following effects:
//      - All Thread Local Variables are treated as regular Container Level Variables.
//      - The overhead of Async Functions becomes equivalent to function call overhead.
//      - The @import("builtin").single_threaded becomes true and therefore various
//        userland APIs which read this variable become more efficient. For example
//        std.Mutex becomes an empty data structure and all of its functions become no-ops.

//  Some examples of tasks the build system can help with:
//      - Performing tasks in parallel and caching the results.
//      - Depending on other projects.
//      - Providing a package for other projects to depend on.
//      - Creating build artifacts by executing the Zig compiler.
//        This includes building Zig source code as well as C and C++
//        source code.
//      - Capturing user-configured options and using those options
//        to configure the build.
//      - Surfacing build configuration as comptime values by providing
//        a file that can be imported by Zig code.
//      - Caching build artifacts to avoid unnecessarily repeating steps.
//      - Executing build artifacts or system-installed tools.
//      - Running tests and verifying the output of executing a build artifact
//        matches the expected value.
//      - Running zig fmt on a codebase or a subset of it.
//      - Custom tasks.
// To use the build system, run `zig build --help` to see a command-line usage help menu.
// This will include project-specific options that were declared in the "build.zig" script.
