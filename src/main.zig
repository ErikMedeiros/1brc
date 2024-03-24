const std = @import("std");
const work = @import("work.zig").work;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip();

    const input_path = args.next().?;
    const input_file = try std.fs.cwd().openFile(input_path, .{});
    defer input_file.close();

    var stdout_file = std.io.getStdOut();
    defer stdout_file.close();

    try work(input_file, &stdout_file, allocator);
}
