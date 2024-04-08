const std = @import("std");
const AvlTree = @import("avl_tree.zig").AvlTree;
const BreathFirstIterator = @import("avl_tree.zig").BreathFirstIterator;

// this runs in 286s for the one billion lines file
pub fn work(input: std.fs.File, output_file: *std.fs.File, allocator: std.mem.Allocator) !void {
    var br = std.io.bufferedReader(input.reader());

    var tree = StationTree.init(allocator);
    defer {
        var it = tree.iterator();
        while (it.next()) |station| allocator.free(station.name);
        tree.deinit();
    }

    var line_buf: [128]u8 = undefined;

    while (try readLine(&br, '\n', &line_buf)) |line| {
        const pivot = std.mem.indexOf(u8, line, ";").?;
        const station_name = line[0..pivot];
        const temperature = try std.fmt.parseFloat(f16, line[pivot + 1 ..]);

        var entry = tree.get(.{ .name = station_name });

        if (entry) |*ptr| {
            const station = ptr.*;
            station.sum += temperature;
            station.count += 1;

            station.min = @min(station.min, temperature);
            station.max = @max(station.max, temperature);
        } else {
            const name = try allocator.dupe(u8, station_name);
            const station = .{ .name = name, .min = temperature, .max = temperature, .sum = temperature, .count = 1 };

            try tree.insert(station);
        }
    }

    var bw = std.io.bufferedWriter(output_file.writer());
    var writer = bw.writer();
    try writer.writeAll("{");

    var iterator = tree.iterator();

    var index: usize = 0;
    while (iterator.next()) |station| : (index += 1) {
        const average = station.sum / @as(f16, @floatFromInt(station.count));

        if (index != 0)
            try writer.writeAll(", ");

        try std.fmt.format(
            writer,
            "{s}={d:.1}/{d:.1}/{d:.1}",
            .{ station.name, station.min, average, station.max },
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

const StationInfo = struct {
    name: []const u8,
    min: f16 = undefined,
    max: f16 = undefined,
    sum: f16 = undefined,
    count: usize = undefined,
};

const StationContext = struct {
    pub fn compare(a: StationInfo, b: StationInfo) std.math.Order {
        return std.mem.order(u8, a.name, b.name);
    }
};

const StationTree = AvlTree(StationInfo, StationContext);
