const std = @import("std");

pub fn AvlTree(comptime T: type, comptime Context: type) type {
    return struct {
        const Self = @This();
        const Iterator = InOrderIterator(Self, T);

        value: T,
        height: i32 = 1,
        left: ?*Self = null,
        right: ?*Self = null,
        allocator: std.mem.Allocator,

        pub fn init(value: T, allocator: std.mem.Allocator) !*Self {
            const node = try allocator.create(Self);
            node.* = .{ .value = value, .allocator = allocator };
            return node;
        }

        pub fn deinit(self: *Self) void {
            if (self.left) |left| left.deinit();
            if (self.right) |right| right.deinit();
            self.allocator.destroy(self);
        }

        pub fn insert(self: *Self, value: T) !void {
            _ = try insert_r(self, value, self.allocator);
        }

        pub fn get(self: *Self, value: T) ?*T {
            if (get_r(self, value)) |node| {
                return &node.value;
            }

            return null;
        }

        fn get_r(root: ?*Self, value: T) ?*Self {
            if (root) |node| {
                return switch (Context.compare(value, node.value)) {
                    .lt => get_r(node.left, value),
                    .eq => node,
                    .gt => get_r(node.right, value),
                };
            } else {
                return null;
            }
        }

        pub fn iterator(self: *Self) Iterator {
            return .{ .current = self, .right_most = null };
        }

        fn insert_r(root: ?*Self, value: T, allocator: std.mem.Allocator) !*Self {
            if (root) |node| {
                switch (Context.compare(value, node.value)) {
                    .lt => node.left = try insert_r(node.left, value, allocator),
                    .eq => return node,
                    .gt => node.right = try insert_r(node.right, value, allocator),
                }

                node.updateHeight();

                if (node.balanceFactor() == -2) {
                    if (node.left.?.balanceFactor() == 1)
                        node.left.?.rotateLeft();
                    node.rotateRight();
                } else if (node.balanceFactor() == 2) {
                    if (node.right.?.balanceFactor() == -1)
                        node.right.?.rotateRight();
                    node.rotateLeft();
                }

                return node;
            } else {
                return Self.init(value, allocator);
            }
        }

        fn rotateLeft(self: *Self) void {
            const new_left = self.right.?;
            const new_root = self;

            std.mem.swap(Self, new_left, new_root);

            new_left.right = new_root.left;
            new_root.left = new_left;

            new_left.updateHeight();
            new_root.updateHeight();
        }

        fn rotateRight(self: *Self) void {
            const new_right = self.left.?;
            const new_root = self;

            std.mem.swap(Self, new_right, new_root);

            new_right.left = new_root.right;
            new_root.right = new_right;

            new_right.updateHeight();
            new_root.updateHeight();
        }

        fn updateHeight(self: *Self) void {
            const l_height = if (self.left) |left| left.height else 0;
            const r_height = if (self.right) |right| right.height else 0;

            self.height = 1 + @max(l_height, r_height);
        }

        fn balanceFactor(self: *const Self) i3 {
            const l_height = if (self.left) |left| left.height else 0;
            const r_height = if (self.right) |right| right.height else 0;

            return @intCast(r_height - l_height);
        }
    };
}

/// implementation of the morris traversal algorithm
/// https://levelup.gitconnected.com/morris-traversal-for-binary-trees-e36e43a665cf
pub fn InOrderIterator(comptime Tree: type, comptime T: type) type {
    return struct {
        const Self = @This();

        current: ?*Tree,
        right_most: ?*Tree,

        pub fn next(self: *Self) ?T {
            var value: ?T = null;

            if (self.current) |current| {
                if (current.left) |left| {
                    var next_smaller = left;
                    while (next_smaller.right != null and next_smaller.right != current) {
                        next_smaller = next_smaller.right.?;
                    }

                    if (next_smaller.right == null) {
                        next_smaller.right = current;
                        self.current = current.left;

                        value = self.next();
                    } else {
                        next_smaller.right = null;
                        self.current = current.right;

                        value = current.value;
                    }
                } else {
                    self.current = current.right;
                    value = current.value;
                }
            } else {
                value = null;
            }

            return value;
        }
    };
}

test "small tree" {
    const Context = struct {
        pub fn compare(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    };

    const IntegerTree = AvlTree(i32, Context);

    var root = try IntegerTree.init(20, std.testing.allocator);
    defer root.deinit();

    // depth 1
    try root.insert(4);
    // depth 2
    try root.insert(15);

    try std.testing.expectEqual(@as(i32, 15), root.value);
    try std.testing.expectEqual(@as(i32, 0), root.balanceFactor());

    try std.testing.expectEqual(@as(i32, 4), root.left.?.value);
    try std.testing.expectEqual(@as(i32, 0), root.left.?.balanceFactor());

    try std.testing.expectEqual(@as(i32, 20), root.right.?.value);
    try std.testing.expectEqual(@as(i32, 0), root.right.?.balanceFactor());
}

test "medium tree" {
    const Context = struct {
        pub fn compare(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    };

    const IntegerTree = AvlTree(i32, Context);

    var root = try IntegerTree.init(20, std.testing.allocator);
    defer root.deinit();

    // depth 1
    try root.insert(4);
    try root.insert(26);
    // depth 2
    try root.insert(3);
    try root.insert(9);
    // depth 3
    try root.insert(15);

    try std.testing.expectEqual(@as(i32, 9), root.value);

    try std.testing.expectEqual(@as(i32, 4), root.left.?.value);
    try std.testing.expectEqual(@as(i32, -1), root.left.?.balanceFactor());
    try std.testing.expectEqual(@as(i32, 20), root.right.?.value);

    try std.testing.expectEqual(@as(i32, 3), root.left.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 15), root.right.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 26), root.right.?.right.?.value);
}

test "big tree" {
    const Context = struct {
        pub fn compare(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    };

    const IntegerTree = AvlTree(i32, Context);

    var root = try IntegerTree.init(20, std.testing.allocator);
    defer root.deinit();

    // depth 1
    try root.insert(4);
    try root.insert(26);
    // depth 2
    try root.insert(3);
    try root.insert(9);
    try root.insert(21);
    try root.insert(30);
    // depth 3
    try root.insert(2);
    try root.insert(7);
    try root.insert(11);
    // depth 4
    try root.insert(15);

    try std.testing.expectEqual(@as(i32, 9), root.value);

    try std.testing.expectEqual(@as(i32, 4), root.left.?.value);
    try std.testing.expectEqual(@as(i32, -1), root.left.?.balanceFactor());
    try std.testing.expectEqual(@as(i32, 20), root.right.?.value);

    try std.testing.expectEqual(@as(i32, 3), root.left.?.left.?.value);
    try std.testing.expectEqual(@as(i32, -1), root.left.?.left.?.balanceFactor());
    try std.testing.expectEqual(@as(i32, 7), root.left.?.right.?.value);
    try std.testing.expectEqual(@as(i32, 11), root.right.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 1), root.right.?.left.?.balanceFactor());
    try std.testing.expectEqual(@as(i32, 26), root.right.?.right.?.value);

    try std.testing.expectEqual(@as(i32, 2), root.left.?.left.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 15), root.right.?.left.?.right.?.value);
    try std.testing.expectEqual(@as(i32, 21), root.right.?.right.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 30), root.right.?.right.?.right.?.value);
}

test "retrival and iteration" {
    const Context = struct {
        pub fn compare(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    };

    const IntegerTree = AvlTree(i32, Context);

    var root = try IntegerTree.init(20, std.testing.allocator);
    defer root.deinit();

    // depth 1
    try root.insert(4);
    try root.insert(26);
    // depth 2
    try root.insert(3);
    try root.insert(9);

    const value1 = root.get(20);
    try std.testing.expectEqual(@as(i32, 20), value1.?.*);

    const value2 = root.get(4);
    try std.testing.expectEqual(@as(i32, 4), value2.?.*);

    const value3 = root.get(26);
    try std.testing.expectEqual(@as(i32, 26), value3.?.*);

    const value4 = root.get(5);
    try std.testing.expect(value4 == null);

    var it = root.iterator();
    var buf: [5]i32 = undefined;

    var index: usize = 0;
    while (it.next()) |number| : (index += 1)
        buf[index] = number;

    try std.testing.expectEqualSlices(i32, &.{ 3, 4, 9, 20, 26 }, &buf);
}
