//! Zig's C translation capability is available as a CLI tool via `zig translate-c`.
//! It requires a single filename as an argument. It may also take a set of optional
//! flags that are forwarded to clang. It writes the translated file to stdout. Flags:
//!   . -I: Specify a search directory for include files. May be used multiple times.
//!         Equivalent to clang's -I flag. The current directory is not included by
//!         default; use -I. to include it.
//!   . -D: Define a preprocessor macro. Equivalent to clang's -D flag.
//!   . -cflags [flags] --: Pass arbitrary additional command line flags to clang.
//!                         Note: the list of flags must end with --
//!   . -target: The target triple for the translated Zig code. If no target is specified,
//!              the current host target will be used.

// IMPORTANT! When translating C code with `zig translate-c`, you must use the same -target
// triple that you will use when compiling the translated code. In addition, you must ensure
// that the -cflags used, if any, match the cflags used by code on the target system. Using
// the incorrect -target or -cflags could result in clang or Zig parse failures, or subtle
// ABI incompatibilities when linking with C code:
//      file contents: long FOO = __LONG_MAX__;
//      $ zig translate-c -target thumb-freestanding-gnueabihf varytarget.h|grep FOO
//      pub export var FOO: c_long = 2147483647;
//      $ zig translate-c -target x86_64-macos-gnu varytarget.h|grep FOO
//      pub export var FOO: c_long = 9223372036854775807;
//      file contents: enum FOO { BAR }; int do_something(enum FOO foo);
//      $ zig translate-c varycflags.h|grep -B1 do_something
//      pub const enum_FOO = c_uint;
//      pub extern fn do_something(foo: enum_FOO) c_int;
//      $ zig translate-c -cflags -fshort-enums -- varycflags.h|grep -B1 do_something
//      pub const enum_FOO = u8;
//      pub extern fn do_something(foo: enum_FOO) c_int;

// `@cImport` and `zig translate-c` use the same underlying C translation functionality,
// so on a technical level they are equivalent. In practice, @cImport is useful as a way
// to quickly and easily access numeric constants, typedefs, and record types without needing
// any extra setup. If you need to pass cflags to clang, or if you would like to edit the
// translated code, it is recommended to use zig translate-c and save the results to a file.
// Common reasons for editing the generated code include: changing anytype parameters in
// function-like macros to more specific types; changing [*c]T pointers to [*]T or *T pointers
// for improved type safety; and enabling or disabling runtime safety within specific functions.

// The C translation feature (whether used via `zig translate-c` or `@cImport`) integrates with
// the Zig caching system. Subsequent runs with the same source file, target, and cflags will use
// the cache instead of repeatedly translating the same code. Use the `--verbose-cimport flag` to
// see where the cached files are stored

// Some C constructs cannot be translated to Zig, like goto, structs with bitfields, and
// token-pasting macros. If found zig demotes those constructs, demotion comes in three
// varieties: opaque, extern, and @compileError. C structs and unions that cannot be translated
// correctly will be translated as opaque{}. Functions that contain opaque types or code constructs
// that cannot be translated will be demoted to extern declarations. Thus, non-translatable types
// can still be used as pointers, and non-translatable functions can be called so long as the linker
// is aware of the compiled function. @compileError is used when top-level definitions (global
// variables, function prototypes, macros) cannot be translated or demoted
