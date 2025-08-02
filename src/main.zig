pub fn main() !u8 {
    const args = std.os.argv;
    if (args.len == 1) {
        return repl();
    } else if (args.len == 2) {
        const path = std.mem.span(args[1]);
        return runFile(path);
    } else {
        std.debug.print("Usage: clox [path]\n", .{});
        return 64;
    }
}

fn runFile(path: []const u8) !u8 {
    var gp_alloc = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gp_alloc.deinit();

    var collector = Collector.init(gp_alloc.allocator());
    defer collector.deinit();

    var vm = try VM.init(&collector);
    defer vm.deinit();

    const source = try readFile(path, gp_alloc.allocator());
    defer gp_alloc.allocator().free(source);

    vm.interpret(source) catch |err| switch (err) {
        error.CompileError => return 65,
        error.RuntimeError => return 70,
        else => return err,
    };

    return 0;
}

fn readFile(path: []const u8, alloc: std.mem.Allocator) ![]u8 {
    return std.fs.cwd().readFileAlloc(
        alloc,
        path,
        1024 * 1024 * 64,
    );
}

fn repl() !u8 {
    var gp_alloc = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gp_alloc.deinit();

    var collector = Collector.init(gp_alloc.allocator());
    defer collector.deinit();

    var vm = try VM.init(&collector);
    defer vm.deinit();

    var line = std.ArrayList(u8).init(gp_alloc.allocator());
    try line.ensureTotalCapacity(512);
    defer line.deinit();

    var stdin = std.io.getStdIn();
    var stdout = std.io.getStdOut();

    while (true) {
        line.clearRetainingCapacity();
        try stdout.writeAll("> ");
        // Max size of 1MiB
        stdin.reader().readUntilDelimiterArrayList(&line, '\n', 1024 * 1024) catch |err| switch (err) {
            error.EndOfStream => {
                try stdout.writeAll("\n");
                break;
            },
            else => return err,
        };
        vm.interpret(line.items) catch |err| switch (err) {
            error.RuntimeError => try stdout.writeAll("Runtime error\n"),
            error.CompileError => try stdout.writeAll("Compile error\n"),
            else => return err,
        };
    }

    return 0;
}

const std = @import("std");

const OpCode = Chunk.OpCode;

pub const value = @import("value.zig");
pub const debug = @import("debug.zig");
pub const Chunk = @import("Chunk.zig");
pub const Collector = @import("Collector.zig");
pub const VM = @import("VM.zig");
pub const Compiler = @import("Compiler.zig");

pub const Value = value.Value;
pub const DynArray = @import("dyn_array.zig").DynArray;
