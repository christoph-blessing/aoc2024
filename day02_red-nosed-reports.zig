const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day02.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;
    var n_safe: i16 = 0;
    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |report| {
        var iterator = std.mem.splitScalar(u8, report, ' ');
        var previous_level = try std.fmt.parseInt(i8, iterator.next().?, 10);
        var previous_difference: ?i8 = null;
        var current_level = try std.fmt.parseInt(i8, iterator.next().?, 10);
        var is_safe = true;
        while (true) {
            const current_difference = current_level - previous_level;
            if (@abs(current_difference) < 1 or @abs(current_difference) > 3) {
                is_safe = false;
                break;
            }
            if (previous_difference != null and haveSameSign(current_difference, previous_difference.?)) {
                is_safe = false;
                break;
            }
            previous_difference = current_difference;
            previous_level = current_level;
            current_level = try std.fmt.parseInt(i8, iterator.next() orelse break, 10);
        }
        if (is_safe) {
            n_safe += 1;
        }
    }
    std.debug.print("Number of safe reports: {}\n", .{n_safe});
}

pub fn haveSameSign(a: i8, b: i8) bool {
    return (a < 0 and b > 0) or (a > 0 and b < 0);
}
