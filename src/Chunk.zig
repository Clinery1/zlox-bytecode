const Chunk = @This();

pub const OpCode = enum(u8) {
    op_return,
    op_constant,
    _,
};

code: root.DynArray(u8),
constants: root.DynArray(root.Value),
lines: root.DynArray(u32),

pub fn init(collector: *root.Collector) !Chunk {
    return .{
        .code = try root.DynArray(u8).init(collector),
        .constants = try root.DynArray(root.Value).init(collector),
        .lines = try root.DynArray(u32).init(collector),
    };
}

pub fn deinit(self: Chunk) void {
    self.code.deinit();
    self.constants.deinit();
    self.lines.deinit();
}

pub fn addConstant(self: *Chunk, constant: root.Value) !u8 {
    std.debug.assert(self.constants.items.len <= 255);
    const ret = self.constants.items.len;
    try self.constants.append(constant);
    return @intCast(ret);
}

pub inline fn writeOp(self: *Chunk, op: OpCode, line: u32) !void {
    try self.write(@intFromEnum(op), line);
}

pub fn write(self: *Chunk, byte: u8, line: u32) !void {
    try self.code.append(byte);
    try self.lines.append(line);
}

const std = @import("std");
const root = @import("root");
