pub fn DynArray(comptime T: type) type {
    return struct {
        collector: *Collector,
        capacity: usize,
        items: []T,

        pub fn init(collector: *Collector) !@This() {
            const slice = try collector.reallocSlice(T, &[0]T{}, growArray(0));
            return .{
                .collector = collector,
                .capacity = slice.len,
                .items = slice[0..0],
            };
        }

        pub fn initRoot(collector: *Collector) !@This() {
            const slice = try collector.reallocSliceRoot(T, &[0]T{}, growArray(0));
            return .{
                .collector = collector,
                .capacity = slice.len,
                .items = slice[0..0],
            };
        }

        pub fn deinit(self: @This()) void {
            self.collector.free(self.allocatorSlice());
        }

        fn allocatorSlice(self: *const @This()) []T {
            // `items.len` is the length, not the capacity.
            return self.items.ptr[0..self.capacity];
        }

        pub fn append(self: *@This(), item: T) !void {
            if (self.items.len == self.capacity) {
                const old_len = self.items.len;
                const new_slice = try self.collector.reallocSlice(
                    T,
                    self.allocatorSlice(),
                    growArray(self.capacity),
                );
                self.capacity = new_slice.len;
                self.items = new_slice[0..old_len];
            }
            std.debug.assert(self.items.len < self.capacity);
            self.items.len += 1;
            self.items[self.items.len - 1] = item;
        }
    };
}

fn growArray(capacity: usize) usize {
    if (capacity < 8) {
        return 8;
    }
    return capacity * 2;
}

const std = @import("std");
const root = @import("root");
const Collector = root.Collector;
