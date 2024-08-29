//! `anyerror` refers to the global error set. This is the error set that contains
//! all errors in the entire compilation unit. It is a superset of all other error
//! sets and a subset of none of them. You can coerce any error set to the global
//! one, and you can explicitly cast an error of the global error set to a
//! non-global one. This inserts a language-level assert to make sure the error
//! value is in fact in the destination error set. The global error set should
//! generally be avoided because it prevents the compiler from knowing what
//! errors are possible at compile-time. Knowing the error set at compile-time
//! is better for generated documentation and helpful error messages, such as
//! forgetting a possible error value in a switch.
