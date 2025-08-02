pub fn disassembleChunk(chunk: *Chunk, name: []const u8) void {
    std.debug.print("== {s} ==\n", .{name});

    var offset: usize = 0;
    while (offset < chunk.code.items.len) {
        offset = disassembleInstruction(chunk, offset);
    }
}

pub fn disassembleInstruction(chunk: *Chunk, offset: usize) usize {
    std.debug.print("{d:04} ", .{offset});

    if (offset > 0 and chunk.lines.items[offset] == chunk.lines.items[offset - 1]) {
        std.debug.print(" |    ", .{});
    } else {
        std.debug.print(" {d:<4} ", .{chunk.lines.items[offset]});
    }

    const instruction: Chunk.OpCode = @enumFromInt(chunk.code.items[offset]);
    switch (instruction) {
        .op_return => return simpleInstruction("OP_RETURN", offset),
        .op_constant => return constantInstruction("OP_CONSTANT", chunk, offset),
        _ => {
            std.debug.print("Unknown opcode: {d}\n", .{chunk.code.items[offset]});
            return offset + 1;
        },
    }
}

fn constantInstruction(name: []const u8, chunk: *Chunk, offset: usize) usize {
    const constant = chunk.code.items[offset + 1];
    std.debug.print("{s:<16} {d:4} '", .{ name, constant });
    root.value.print(chunk.constants.items[constant]);
    std.debug.print("'\n", .{});
    return offset + 2;
}

inline fn simpleInstruction(name: []const u8, offset: usize) usize {
    std.debug.print("{s}\n", .{name});
    return offset + 1;
}

const std = @import("std");
const root = @import("root");
const Chunk = root.Chunk;
