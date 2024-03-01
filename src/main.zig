const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    for (0..44) |num|
        try std.fmt.format(stdout, "Fibonacci({d}) = {d}\n", .{ num, fibonacci(num) });
}

fn fibonacci(num: usize) usize {
    if (num == 0) return 0;
    if (num == 1) return 1;
    return fibonacci(num - 1) + fibonacci(num - 2);
}
