pub fn DynArray(comptime T: type) type {
    return struct {
        collector: *Collector,
        capacity: usize,
        items: []T,

        pub fn init(collector: *Collector) !@This() {
            const slice = try collector.reallocSlice(T, &[0]T{}, growArray(0));
            return .{
                .collector = collector,
                .capacity = growArray(0),
                .items = slice[0..0],
            };
        }

        pub fn initRoot(collector: *Collector) !@This() {
            const slice = try collector.reallocSliceRoot(T, &[0]T{}, growArray(0));
            return .{
                .collector = collector,
                .capacity = growArray(0),
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
                self.capacity = growArray(self.capacity);
                const old_len = self.items.len;
                self.items = try self.collector.reallocSlice(
                    T,
                    self.items,
                    self.capacity,
                );
                self.items.len = old_len;
            }
            std.debug.assert(self.items.len < self.capacity);
            const index = self.items.len;
            self.items.len += 1;
            self.items[index] = item;
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
