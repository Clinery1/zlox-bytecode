const VM = @This();
const STACK_MAX = 256;

pub const Error = error{
    CompileError,
    RuntimeError,
};

collector: *Collector,
chunk: ?*root.Chunk,
ip: ?[]u8,

stack: []Value,
stack_ptr: [*]Value,

pub fn init(collector: *Collector) !VM {
    const stack = try collector.reallocSlice(Value, &[0]Value{}, STACK_MAX);
    return .{
        .collector = collector,
        .chunk = null,
        .ip = null,
        .stack = stack,
        .stack_ptr = stack.ptr,
    };
}

pub fn resetStack(self: *VM) void {
    self.stack_ptr = self.stack.ptr;
}

pub fn push(self: *VM, value: Value) void {
    self.stack_ptr[0] = value;
    self.stack_ptr += 1;
}

pub fn pop(self: *VM) Value {
    self.stack_ptr -= 1;
    return self.stack_ptr[0];
}

pub fn deinit(self: *VM) void {
    self.collector.free(self.stack);
}

pub fn interpret(self: *VM, source: []const u8) !void {
    var compiler = try Compiler.init(self.collector);
    defer compiler.deinit();

    const chunk = try compiler.compile(source);
    self.chunk = chunk;
    self.ip = chunk.code.items;

    return error.RuntimeError;

    // return self.run();
}

inline fn readByte(self: *VM) u8 {
    const byte = self.ip.?[0];
    self.ip = self.ip.?[1..];
    return byte;
}
inline fn readOp(self: *VM) OpCode {
    return @enumFromInt(self.readByte());
}
inline fn readConstant(self: *VM) Value {
    const idx = self.readByte();
    return self.chunk.?.constants.items[idx];
}

pub fn run(self: *VM) !void {
    while (true) {
        const instruction = self.readOp();
        switch (instruction) {
            .op_return => {
                const val = self.pop();
                root.value.print(val);
                std.debug.print("\n", .{});
                return;
            },
            .op_constant => {
                const val = self.readConstant();
                self.push(val);
            },
            .op_negate => {
                self.push(-self.pop());
            },
            .op_add, .op_subtract, .op_multiply, .op_divide => {
                const b = self.pop();
                const a = self.pop();
                switch (instruction) {
                    .op_add => self.push(a + b),
                    .op_subtract => self.push(a - b),
                    .op_multiply => self.push(a * b),
                    .op_divide => self.push(a / b),
                    else => unreachable,
                }
            },
            _ => {},
        }
    }
}

const std = @import("std");
const root = @import("root");

const Compiler = root.Compiler;
const Collector = root.Collector;
const OpCode = root.Chunk.OpCode;
const Value = root.Value;
