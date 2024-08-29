//! An error set is like an enum. However, each error name across the
//! entire compilation gets assigned an unsigned integer greater than 0.
//! You are allowed to declare the same error name more than once, and
//! if you do, it gets assigned the same integer value.
//! The error set type defaults to a u16, though if the maximum number
//! of distinct error values is provided via the --error-limit [num]
//! command line parameter an integer type with the minimum number of
//! bits required to represent all of the error values will be used.

const std = @import("std");

const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};

const AllocationError = error{
    OutOfMemory,
};

test "coerce subset to superset" {
    const err = foo(AllocationError.OutOfMemory);
    try std.testing.expect(err == FileOpenError.OutOfMemory);
}

fn foo(err: AllocationError) FileOpenError {
    return err;
}

test "coerce superset to subset" {
    foo2(FileOpenError.OutOfMemory) catch {};
}

fn foo2(err: FileOpenError) AllocationError {
    return err;
}

// There is a shortcut for declaring an error set with only 1 value,
// and then getting that value
const err1 = error.FileNotFound;
// Same as
const err2 = (error{FileNotFound}).FileNotFound;
