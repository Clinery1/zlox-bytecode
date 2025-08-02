pub fn main() !void {
    var gp_alloc = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gp_alloc.deinit();

    var collector = Collector.init(gp_alloc.allocator());
    defer collector.deinit();

    var chunk = try Chunk.init(&collector);
    defer chunk.deinit();

    var vm = try VM.init(&collector);
    defer vm.deinit();

    var constant = try chunk.addConstant(1.2);
    try chunk.writeOp(.op_constant, 123);
    try chunk.write(constant, 123);

    constant = try chunk.addConstant(3.4);
    try chunk.writeOp(.op_constant, 123);
    try chunk.write(constant, 123);

    try chunk.writeOp(.op_add, 123);

    constant = try chunk.addConstant(5.6);
    try chunk.writeOp(.op_constant, 123);
    try chunk.write(constant, 123);

    try chunk.writeOp(.op_divide, 123);

    try chunk.writeOp(.op_negate, 123);
    try chunk.writeOp(.op_return, 123);

    debug.disassembleChunk(&chunk, "test chunk");

    try vm.interpret(&chunk);
}

const std = @import("std");

const OpCode = Chunk.OpCode;

pub const value = @import("value.zig");
pub const debug = @import("debug.zig");
pub const Chunk = @import("Chunk.zig");
pub const Collector = @import("Collector.zig");
pub const VM = @import("VM.zig");

pub const Value = value.Value;
pub const DynArray = @import("dyn_array.zig").DynArray;
