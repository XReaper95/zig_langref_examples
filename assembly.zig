//! For some use cases, it may be necessary to directly control the
//! machine code generated by Zig programs, rather than relying
//! on Zig's code generation. For these cases, one can use inline
//! assembly.

// Compile with `zig build-exe inline_assembly.zig -target x86_64-linux`,
// can only be ran in a Linux host (like WSL)

pub fn main() noreturn {
    // Here is an example of implementing Hello, World on x86_64 Linux using inline assembly
    const msg = "hello world\n";
    _ = syscall3(SYS_write, STDOUT_FILENO, @intFromPtr(msg), msg.len);
    _ = syscall1(SYS_exit, 0);
    unreachable;
}

pub const SYS_write = 1;
pub const SYS_exit = 60;

pub const STDOUT_FILENO = 1;

pub fn syscall1(number: usize, arg1: usize) usize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> usize),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
        : "rcx", "r11"
    );
}

pub fn syscall3(number: usize, arg1: usize, arg2: usize, arg3: usize) usize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> usize),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
          [arg3] "{rdx}" (arg3),
        : "rcx", "r11"
    );
}

pub fn syscall1Disected(number: usize, arg1: usize) usize {
    // Inline assembly is an expression which returns a value.
    // the `asm` keyword begins the expression.
    return asm
    // `volatile` is an optional modifier that tells Zig this
    // inline assembly expression has side-effects. Without
    // `volatile`, Zig is allowed to delete the inline assembly
    // code if the result is unused.
    volatile (
    // Next is a comptime string which is the assembly code.
    // Inside this string one may use `%[ret]`, `%[number]`,
    // or `%[arg1]` where a register is expected, to specify
    // the register that Zig uses for the argument or return value,
    // if the register constraint strings are used. However in
    // the below code, this is not used. A literal `%` can be
    // obtained by escaping it with a double percent: `%%`.
    // Often multiline string syntax comes in handy here.
        \\syscall
        // Next is the output. It is possible in the future Zig will
        // support multiple outputs, depending on how
        // https://github.com/ziglang/zig/issues/215 is resolved.
        // It is allowed for there to be no outputs, in which case
        // this colon would be directly followed by the colon for the inputs.
        :
        // This specifies the name to be used in `%[ret]` syntax in
        // the above assembly string. This example does not use it,
        // but the syntax is mandatory.
          [ret]
          // Next is the output constraint string. This feature is still
          // considered unstable in Zig, and so LLVM/GCC documentation
          // must be used to understand the semantics.
          // http://releases.llvm.org/10.0.0/docs/LangRef.html#inline-asm-constraint-string
          // https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html
          // In this example, the constraint string means "the result value of
          // this inline assembly instruction is whatever is in $rax".
          "={rax}"
          // Next is either a value binding, or `->` and then a type. The
          // type is the result type of the inline assembly expression.
          // If it is a value binding, then `%[ret]` syntax would be used
          // to refer to the register bound to the value.
          (-> usize),
          // Next is the list of inputs.
          // The constraint for these inputs means, "when the assembly code is
          // executed, $rax shall have the value of `number` and $rdi shall have
          // the value of `arg1`". Any number of input parameters is allowed,
          // including none.
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
          // Next is the list of clobbers. These declare a set of registers whose
          // values will not be preserved by the execution of this assembly code.
          // These do not include output or input registers. The special clobber
          // value of "memory" means that the assembly writes to arbitrary undeclared
          // memory locations - not only the memory pointed to by a declared indirect
          // output. In this example we list $rcx and $r11 because it is known the
          // kernel syscall does not preserve these registers.
        : "rcx", "r11"
    );
}

// For x86 and x86_64 targets, the syntax is AT&T syntax, rather than the more popular
// Intel syntax. This is due to technical constraints; assembly parsing is provided by
// LLVM and its support for Intel syntax is buggy and not well tested.
// Some day Zig may have its own assembler. This would allow it to integrate more seamlessly
// into the language, as well as be compatible with the popular NASM syntax. This documentation
// section will be updated before 1.0.0 is released, with a conclusive statement about the status
// of AT&T vs Intel/NASM syntax.

// Output and Input Constraint
// Output and input constraints are still considered to be unstable in Zig, and so
// LLVM (http://releases.llvm.org/10.0.0/docs/LangRef.html#inline-asm-constraint-string)
// and GCC (https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html) documentation must be used
// to understand the semantics. Note that some breaking changes to output constraints are
// planned with issue https://github.com/ziglang/zig/issues/215.

// Clobbers
// Clobbers are the set of registers whose values will not be preserved
// by the execution of the assembly code. These do not include output or
// input registers. The special clobber value of "memory" means that the
// assembly causes writes to arbitrary undeclared memory locations - not
// only the memory pointed to by a declared indirect output. Failure to
// declare the full set of clobbers for a given inline assembly expression
// is unchecked Undefined Behavior.

// Global Assembly
//  When an assembly expression occurs in a container level comptime block,
// this is global assembly. This kind of assembly has different rules than
// inline assembly. First, volatile is not valid because all global assembly
// is unconditionally included. Second, there are no inputs, outputs, or clobbers.
// All global assembly is concatenated verbatim into one long string and assembled
// together. There are no template substitution rules regarding % as there are in
// inline assembly expressions.

const std = @import("std");
const expect = std.testing.expect;

comptime {
    asm (
        \\.global my_func;
        \\.type my_func, @function;
        \\my_func:
        \\  lea (%rdi,%rsi,1),%eax
        \\  retq
    );
}

extern fn my_func(a: i32, b: i32) i32;

// test with `zig test ... -target x86_64-linux`
test "global assembly" {
    try expect(my_func(12, 34) == 46);
}
