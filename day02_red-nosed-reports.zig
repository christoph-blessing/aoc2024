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
        var previous_level = try parseInt(iterator.next().?);
        var previous_difference: ?i8 = null;
        var current_level = try parseInt(iterator.next().?);
        var is_safe = true;
        while (true) {
            const current_difference = current_level - previous_level;
            if (previous_difference == null) {
                previous_difference = current_difference;
            }
            is_safe = IsSafe(current_level, previous_level, previous_difference.?);
            if (!is_safe) break;
            previous_difference = current_difference;
            previous_level = current_level;
            current_level = try parseInt(iterator.next() orelse break);
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

pub fn parseInt(raw: []const u8) !i8 {
    return std.fmt.parseInt(i8, raw, 10);
}

pub fn isSafeDifference(level1: i8, level2: i8) bool {
    const difference = level1 - level2;
    return @abs(difference) < 1 or @abs(difference) > 3;
}

pub fn IsSafe(current_level: i8, previous_level: i8, previous_difference: i8) bool {
    if (isSafeDifference(current_level, previous_level)) {
        return false;
    }
    if (haveSameSign(current_level - previous_level, previous_difference)) {
        return false;
    }
    return true;
}
