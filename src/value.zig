pub const Value = f64;

pub fn print(value: Value) void {
    std.debug.print("{d}", .{value});
}

const std = @import("std");
const root = @import("root");
