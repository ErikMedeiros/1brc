const std = @import("std");

pub fn work(input: std.fs.File, output_file: *std.fs.File, allocator: std.mem.Allocator) !void {
    var br = std.io.bufferedReader(input.reader());
    var reader = br.reader();

    var map = std.StringArrayHashMap(StationInfo).init(allocator);

    while (true) {
        var buf = std.ArrayList(u8).init(allocator);
        defer buf.deinit();
        var w = buf.writer();

        reader.streamUntilDelimiter(w, '\n', null) catch |err| switch (err) {
            error.EndOfStream => if (buf.items.len == 0) break,
            else => |e| return e,
        };

        const pivot = std.mem.indexOf(u8, buf.items, ";") orelse @panic("malformed input file");
        const station_name = buf.items[0..pivot];
        const temp = try std.fmt.parseFloat(f16, buf.items[pivot + 1 ..]);

        std.debug.print("{s}\n", .{station_name});
        var entry = map.getPtr(station_name);

        if (entry) |station| {
            station.sum += temp;
            station.count += 1;

            if (station.min > temp) station.min = temp;
            if (station.max < temp) station.max = temp;
        } else {
            try map.put(station_name, .{ .min = temp, .max = temp, .sum = temp, .count = 1 });
        }
    }

    map.sort(.{ .lessThan = lessThan });

    var bw = std.io.bufferedWriter(output_file.writer());
    var writer = bw.writer();
    try writer.writeAll("{");

    for (map.keys(), 0..) |station_name, i| {
        const station = map.get(station_name).?;
        const average = @divFloor(station.sum, @as(f16, @floatFromInt(station.count)));

        try std.fmt.format(
            writer,
            "{s}{s}={d}/{d}/{d}",
            .{ if (i == 0) "" else ", ", station_name, station.min, average, station.max },
        );
    }

    try writer.writeAll("}\n");
    try bw.flush();
}

fn lessThan(a_index: usize, b_index: usize) bool {
    return std.mem.order(usize, &.{a_index}, &.{b_index}).compare(std.math.CompareOperator.lt);
}

const StationInfo = struct { min: f16, max: f16, sum: f32, count: usize };
