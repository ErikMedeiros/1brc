const std = @import("std");
const work = @import("work.zig").work;

fn testFile(comptime path: []const u8) !void {
    const cwd = std.fs.cwd();

    const input_path = path ++ ".txt";
    const input_file = try cwd.openFile(input_path, .{});
    defer input_file.close();

    const expected_path = path ++ ".out";
    const expected_file = try cwd.openFile(expected_path, .{});
    defer expected_file.close();

    const output_path = path ++ ".test";
    var output_file = try cwd.createFile(output_path, .{ .read = true });
    defer output_file.close();
    errdefer cwd.deleteFile(output_path) catch unreachable;

    try work(input_file, &output_file, std.testing.allocator);
    try output_file.seekTo(0);

    var expected_buffered = std.io.bufferedReader(expected_file.reader());
    var expected_reader = expected_buffered.reader();
    var expected = std.ArrayList(u8).init(std.testing.allocator);
    defer expected.deinit();

    var output_buffered = std.io.bufferedReader(output_file.reader());
    var output_reader = output_buffered.reader();
    var output = std.ArrayList(u8).init(std.testing.allocator);
    defer output.deinit();

    while (expected_reader.streamUntilDelimiter(expected.writer(), ',', null)) {
        defer output.clearRetainingCapacity();
        defer expected.clearRetainingCapacity();

        try output_reader.streamUntilDelimiter(output.writer(), ',', null);
        try std.testing.expectEqualSlices(u8, expected.items, output.items);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    try cwd.deleteFile(output_path);
}

test "samples/measurements-short.txt" {
    try testFile("samples/measurements-short");
}

test "samples/measurements-10.txt" {
    try testFile("samples/measurements-10");
}

test "samples/measurements-20.txt" {
    try testFile("samples/measurements-20");
}

test "samples/measurements-1.txt" {
    try testFile("samples/measurements-1");
}

test "samples/measurements-shortest.txt" {
    try testFile("samples/measurements-shortest");
}

test "samples/measurements-dot.txt" {
    try testFile("samples/measurements-dot");
}

test "samples/measurements-2.txt" {
    try testFile("samples/measurements-2");
}

test "samples/measurements-3.txt" {
    try testFile("samples/measurements-3");
}

test "samples/measurements-complex-utf8.txt" {
    try testFile("samples/measurements-complex-utf8");
}

test "samples/measurements-10000-unique-keys.txt" {
    try testFile("samples/measurements-10000-unique-keys");
}

test "samples/measurements-boundaries.txt" {
    try testFile("samples/measurements-boundaries");
}

test "samples/measurements-rounding.txt" {
    try testFile("samples/measurements-rounding");
}
