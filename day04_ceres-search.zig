const std = @import("std");

const Pos = struct { row: usize, col: usize };

const allocator = std.heap.page_allocator;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day04.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        try lines.append(try allocator.dupe(u8, line));
    }

    const n_xmas = try count_xmas(&lines);
    std.debug.print("Total number of XMAS: {}\n", .{n_xmas});

    const n_x_mas = try count_x_mas(&lines);
    std.debug.print("Total number of X-MAS: {}\n", .{n_x_mas});
}

fn count_xmas(lines: *std.ArrayList([]const u8)) !usize {
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

    const anchors = try get_pos(lines, target[0]);
    defer allocator.free(anchors);

    var n: usize = 0;
    for (anchors) |anchor| {
        for (dirs) |dir| {
            const length: isize = @intCast(target.len);

            const anchor_row: isize = @intCast(anchor.row);
            const end_row = anchor_row + (length - 1) * dir[0];
            const start_row = end_row - (length - 1) * dir[0];
            if (start_row < 0 or start_row >= lines.items.len) continue;
            if (end_row < 0 or end_row >= lines.items.len) continue;

            const anchor_col: isize = @intCast(anchor.col);
            const end_col = anchor_col + (length - 1) * dir[1];
            const start_col = end_col - (length - 1) * dir[1];
            if (start_col < 0 or start_col >= lines.items.len) continue;
            if (end_col < 0 or end_col >= lines.items[0].len) continue;

            var is_match = true;
            for (target, 0..) |char, index_usize| {
                const index: isize = @intCast(index_usize);
                const target_row = start_row + index * dir[0];
                const target_col = start_col + index * dir[1];
                if (lines.items[@intCast(target_row)][@intCast(target_col)] != char) {
                    is_match = false;
                    break;
                }
            }
            if (is_match) {
                n += 1;
            }
        }
    }
    return n;
}

fn count_x_mas(lines: *std.ArrayList([]const u8)) !usize {
    const centers = try get_pos(lines, 'A');
    defer allocator.free(centers);
    var buffer: [3]u8 = undefined;
    var n: usize = 0;
    for (centers) |start| {
        if (start.row <= 0) continue;
        if (start.row >= lines.items.len - 1) continue;
        if (start.col <= 0) continue;
        if (start.col >= lines.items[0].len - 1) continue;
        buffer[0] = lines.items[start.row - 1][start.col - 1];
        buffer[1] = lines.items[start.row][start.col];
        buffer[2] = lines.items[start.row + 1][start.col + 1];
        if (!std.mem.eql(u8, &buffer, "SAM") and !std.mem.eql(u8, &buffer, "MAS")) continue;
        buffer[0] = lines.items[start.row - 1][start.col + 1];
        buffer[1] = lines.items[start.row][start.col];
        buffer[2] = lines.items[start.row + 1][start.col - 1];
        if (!std.mem.eql(u8, &buffer, "SAM") and !std.mem.eql(u8, &buffer, "MAS")) continue;
        n += 1;
    }
    return n;
}

fn get_pos(lines: *std.ArrayList([]const u8), target: u8) ![]Pos {
    var pos = std.ArrayList(Pos).init(allocator);
    defer pos.deinit();
    for (lines.items, 0..) |line, i_row| {
        for (line, 0..) |char, i_col| {
            if (char != target) {
                continue;
            }
            try pos.append(Pos{ .row = i_row, .col = i_col });
        }
    }
    return pos.toOwnedSlice();
}
