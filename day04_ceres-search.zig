const std = @import("std");

const Pos = struct { row: usize, col: usize };

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day04.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;

    const allocator = std.heap.page_allocator;
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        try lines.append(try allocator.dupe(u8, line));
    }

    var starts = std.ArrayList(Pos).init(allocator);
    defer starts.deinit();
    for (lines.items, 0..) |line, i_row| {
        for (line, 0..) |char, i_col| {
            if (char != 'X') {
                continue;
            }
            try starts.append(Pos{ .row = i_row, .col = i_col });
        }
    }

    const dirs = [_][2]i8{
        [_]i8{ 1, 0 },
        [_]i8{ -1, 0 },
        [_]i8{ 0, 1 },
        [_]i8{ 0, -1 },
        [_]i8{ 1, 1 },
        [_]i8{ -1, -1 },
        [_]i8{ -1, 1 },
        [_]i8{ 1, -1 },
    };

    const target = "XMAS";
    var n: usize = 0;
    for (starts.items) |start| {
        for (dirs) |dir| {
            var is_match = true;
            for (target, 0..) |char, usize_index| {
                is_match = false;

                const index: isize = @intCast(usize_index);

                const start_row: isize = @intCast(start.row);
                const target_row = start_row + index * dir[0];
                if (target_row < 0 or target_row >= lines.items.len) break;

                const start_col: isize = @intCast(start.col);
                const target_col = start_col + index * dir[1];
                if (target_col < 0 or target_col >= lines.items[0].len) break;

                if (lines.items[@intCast(target_row)][@intCast(target_col)] != char) break;
                is_match = true;
            }
            if (is_match) {
                n += 1;
            }
        }
    }
    std.debug.print("Total number: {}\n", .{n});
}
