const std = @import("std");

// this runs in 108.83s for the one billion lines file
pub fn work(input: std.fs.File, output_file: *std.fs.File, allocator: std.mem.Allocator) !void {
    var br = std.io.bufferedReader(input.reader());

    var map = std.StringArrayHashMap(StationInfo).init(allocator);
    defer {
        for (map.keys()) |key| allocator.free(key);
        map.deinit();
    }

    var line_buf: [128]u8 = undefined;

    while (try readLine(&br, '\n', &line_buf)) |line| {
        const pivot = std.mem.indexOf(u8, line, ";").?;
        const station_name = line[0..pivot];
        const temperature = try std.fmt.parseFloat(f16, line[pivot + 1 ..]);

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
            try writer.writeAll(", ");

        try std.fmt.format(
            writer,
            "{s}={d:.1}/{d:.1}/{d:.1}",
            .{ station_name, station.min, average, station.max },
        );
    }

    try writer.writeAll("}\n");
    try bw.flush();
}

/// a nice optimization done by the zul library
/// https://github.com/karlseguin/zul/blob/master/src/fs.zig#L27
fn readLine(reader: *std.io.BufferedReader(4096, std.fs.File.Reader), delimiter: u8, buf: []u8) !?[]u8 {
    var written: usize = 0;

    while (true) {
        const start = reader.start;

        if (std.mem.indexOfScalar(u8, reader.buf[start..reader.end], delimiter)) |index| {
            const written_end = written + index;
            if (written_end > buf.len) return error.StreamTooLong;

            const delimiter_index = start + index;

            if (written == 0) {
                reader.start = delimiter_index + 1;
                return reader.buf[start..delimiter_index];
            } else {
                @memcpy(buf[written..written_end], reader.buf[start..delimiter_index]);
                reader.start = delimiter_index + 1;
                return buf[0..written_end];
            }
        } else {
            const written_end = written + reader.end - start;
            if (written_end > buf.len) return error.StreamTooLong;

            @memcpy(buf[written..written_end], reader.buf[start..reader.end]);
            written = written_end;

            const n = try reader.unbuffered_reader.read(reader.buf[0..]);
            if (n == 0) return null;

            reader.start = 0;
            reader.end = n;
        }
    }
}

const StationInfo = struct { min: f16, max: f16, sum: f16, count: usize };
