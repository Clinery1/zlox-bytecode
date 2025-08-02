const Collector = @This();

pub const RootStatus = enum { root, not_root };

const AllocationData = struct {
    root: RootStatus,
    slice_len: ?usize,
    vtable: *const VTable,
};

const VTable = struct {};

backing: Allocator,
/// Map of allocation pointer to block
blocks: std.AutoHashMap(usize, AllocationData),

pub fn init(backing_allocator: Allocator) Collector {
    return .{
        .backing = backing_allocator,
        .blocks = std.AutoHashMap(usize, AllocationData).init(backing_allocator),
    };
}

pub fn deinit(self: *Collector) void {
    self.blocks.deinit();
}

/// Reallocates the slice keeping the existing root status.
pub inline fn reallocSlice(self: *Collector, comptime T: type, slice: []T, new_len: usize) ![]T {
    return self.reallocSliceOptions(T, slice, new_len, null);
}

pub inline fn reallocSliceRoot(self: *Collector, comptime T: type, slice: []T, new_len: usize) ![]T {
    const val = try self.reallocSliceOptions(T, slice, new_len, .root);
    return val;
}

pub fn reallocSliceOptions(self: *Collector, comptime T: type, slice: []T, new_len: usize, root_status: ?RootStatus) ![]T {
    if (new_len == 0) {
        return error.CannotFreeFromRealloc;
    }

    if (new_len < slice.len or new_len == slice.len) {
        return slice;
    }

    const data_ptr = try self.backing.alloc(T, new_len);

    const new_addr = @intFromPtr(data_ptr.ptr);
    const old_addr = @intFromPtr(slice.ptr);

    std.mem.copyForwards(T, data_ptr, slice);

    if (self.blocks.fetchRemove(old_addr)) |kv| {
        var block = kv.value;
        if (root_status) |status| {
            block.root = status;
        }
        block.slice_len = new_len;
        try self.blocks.put(new_addr, block);
        self.backing.free(slice);
    } else {
        try self.blocks.put(new_addr, .{
            .root = root_status orelse .not_root,
            .slice_len = new_len,
            .vtable = getVTable(T),
        });
    }

    return data_ptr;
}

pub fn free(self: *Collector, slice: anytype) void {
    const addr = @intFromPtr(slice.ptr);
    _ = self.blocks.remove(addr);
    self.backing.free(slice);
}

pub fn allocRoot(self: *Collector, comptime T: type) !*T {
    const ptr = try self.backing.create(T);

    const block = .{
        .root = true,
        .slice_len = null,
        .vtable = getVTable(T),
    };

    try self.blocks.put(@intFromPtr(ptr), block);

    return ptr;
}

fn getVTable(comptime T: type) *const VTable {
    _ = T;
    return &.{};
}

const std = @import("std");
const root = @import("root");
const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;
