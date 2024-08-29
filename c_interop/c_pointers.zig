//! This type is to be avoided whenever possible. The only valid reason for using
//! a C pointer is in auto-generated code from translating C code.When importing
//! C header files, it is ambiguous whether pointers should be translated as
//! single-item pointers (*T) or many-item pointers ([*]T). C pointers are a
//! compromise so that Zig code can utilize translated header files directly.

// [*c]T - C pointer.
//      - Supports all the syntax of the other two pointer types (*T) and ([*]T).
//      - Coerces to other pointer types, as well as Optional Pointers. When a C
//        pointer is coerced to a non-optional pointer, safety-checked Undefined
//        Behavior occurs if the address is 0.
//      - Allows address 0. On non-freestanding targets, dereferencing address 0
//        is safety-checked Undefined Behavior. Optional C pointers introduce another
//        bit to keep track of null, just like ?usize. Note that creating an optional
//        C pointer is unnecessary as one can use normal Optional Pointers.
//      - Supports Type Coercion to and from integers.
//      - Supports comparison with integers.
//      - Does not support Zig-only pointer attributes such as alignment. Use normal
//        Pointers please!

// When a C pointer is pointing to a single struct (not an array), dereference the C pointer
// to access the struct's fields or member data. That syntax looks like this:
//      ptr_to_struct.*.struct_member
// This is comparable to doing -> in C. When a C pointer is pointing to an array of structs,
// the syntax reverts to this:
//      ptr_to_struct_array[index].struct_member
