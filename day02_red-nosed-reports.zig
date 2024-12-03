const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day02.txt", .{ .mode = .read_only });
    defer file.close();

    const allocator = std.heap.page_allocator;
    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;
    var n_safe: u16 = 0;
    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |report_str| {
        var report = std.ArrayList(i8).init(allocator);
        defer report.deinit();
        var iterator = std.mem.splitScalar(u8, report_str, ' ');
        while (iterator.next()) |level_str| {
            try report.append(try parseInt(level_str));
        }

        if (isSafe(report)) {
            n_safe += 1;
            continue;
        }

        for (report.items, 0..) |_, index| {
            var cloned_report = try report.clone();
            defer cloned_report.deinit();
            _ = cloned_report.orderedRemove(index);
            if (isSafe(cloned_report)) {
                n_safe += 1;
                break;
            }
        }
    }
    std.debug.print("Number of safe reports: {}", .{n_safe});
}

pub fn isSafe(report: std.ArrayList(i8)) bool {
    var previous_pointer: u8 = 0;
    var current_pointer: u8 = 1;
    var previous_diff: i8 = report.items[current_pointer] - report.items[previous_pointer];
    var is_safe: bool = true;
    while (true) {
        if (current_pointer == report.items.len) break;
        const previous_level = report.items[previous_pointer];
        const current_level = report.items[current_pointer];
        const current_diff = current_level - previous_level;
        if (@abs(current_diff) < 1 or @abs(current_diff) > 3) {
            is_safe = false;
            break;
        }
        if ((current_diff < 0 and previous_diff > 0) or (current_diff > 0 and previous_diff < 0)) {
            is_safe = false;
            break;
        }
        previous_pointer = current_pointer;
        current_pointer += 1;
        previous_diff = current_diff;
    }
    return is_safe;
}

pub fn parseInt(raw: []const u8) !i8 {
    return std.fmt.parseInt(i8, raw, 10);
}
