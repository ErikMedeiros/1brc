const std = @import("std");

// this runs in 182.53s for the one billion lines file
pub fn work(input: std.fs.File, output_file: *std.fs.File, allocator: std.mem.Allocator) !void {
    var br = std.io.bufferedReader(input.reader());
    var reader = br.reader();

    var map = std.StringArrayHashMap(StationInfo).init(allocator);
    defer {
        for (map.keys()) |key| allocator.free(key);
        map.deinit();
    }

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();
    var line_writer = line.writer();

    while (reader.streamUntilDelimiter(line_writer, '\n', null)) {
        defer line.clearRetainingCapacity();

        const pivot = std.mem.indexOf(u8, line.items, ";") orelse @panic("malformed input file");
        const station_name = line.items[0..pivot];
        const temperature = try std.fmt.parseFloat(f16, line.items[pivot + 1 ..]);

        var entry = try map.getOrPut(station_name);

        if (entry.found_existing) {
            var station = entry.value_ptr;
            station.sum += temperature;
            station.count += 1;

            station.min = @min(station.min, temperature);
            station.max = @max(station.max, temperature);
        } else {
            entry.key_ptr.* = try allocator.dupe(u8, station_name);
            entry.value_ptr.* = .{ .min = temperature, .max = temperature, .sum = temperature, .count = 1 };
        }
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    const Ctx = struct {
        items: [][]const u8,

        pub fn lessThan(ctx: @This(), a_index: usize, b_index: usize) bool {
            const a = ctx.items[a_index];
            const b = ctx.items[b_index];
            return std.mem.order(u8, a, b).compare(std.math.CompareOperator.lt);
        }
    };

    map.sort(Ctx{ .items = map.keys() });

    var bw = std.io.bufferedWriter(output_file.writer());
    var writer = bw.writer();
    try writer.writeAll("{");

    for (map.keys(), 0..) |station_name, i| {
        const station = map.get(station_name).?;
        const average = station.sum / @as(f16, @floatFromInt(station.count));

        if (i != 0)
            try std.fmt.format(writer, "{s}", .{", "});

        try std.fmt.format(
            writer,
            "{s}={d:.1}/{d:.1}/{d:.1}",
            .{ station_name, station.min, average, station.max },
        );
    }

    try writer.writeAll("}\n");
    try bw.flush();
}

const StationInfo = struct { min: f16, max: f16, sum: f16, count: usize };
