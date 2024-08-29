const win = @import("std").os.windows;

extern "user32" fn MessageBoxA(?win.HWND, [*:0]const u8, [*:0]const u8, u32) callconv(win.WINAPI) i32;

pub fn main() !void {
    _ = MessageBoxA(null, "Your machine belongs to me now", "Hack", 0);
}
