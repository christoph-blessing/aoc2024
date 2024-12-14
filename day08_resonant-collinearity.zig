const std = @import("std");
const print = std.debug.print;

const Loc = struct { row: usize, col: usize };

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day08.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;

    const allocator = std.heap.page_allocator;
    var antennas = std.AutoHashMap(u8, std.ArrayList(Loc)).init(allocator);
    defer antennas.deinit();

    var n_cols: usize = undefined;

    var i_row: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        n_cols = line.len;

        for (line, 0..) |char, i_col| {
            if (char == '.') continue;
            if (!antennas.contains(char)) {
                const locs = std.ArrayList(Loc).init(allocator);
                try antennas.put(char, locs);
            }
            var locs = antennas.getPtr(char).?;
            try locs.append(Loc{ .row = i_row, .col = i_col });
        }
        i_row += 1;
    }

    const n_rows: usize = i_row;

    defer {
        var iterator = antennas.valueIterator();
        while (iterator.next()) |locs| {
            locs.deinit();
        }
    }

    var antinodes = std.AutoHashMap(Loc, bool).init(allocator);
    defer antinodes.deinit();

    var iterator = antennas.iterator();
    while (iterator.next()) |entry| {
        const combinations = try get_combinations(allocator, entry.value_ptr.items);
        defer {
            for (combinations) |combination| {
                allocator.free(combination);
            }
            allocator.free(combinations);
        }

        for (combinations) |combination| {
            const row_a: isize = @intCast(combination[0].row);
            const col_a: isize = @intCast(combination[0].col);

            const row_b: isize = @intCast(combination[1].row);
            const col_b: isize = @intCast(combination[1].col);

            const row_offset = row_a - row_b;
            const col_offset = col_a - col_b;

            const antinode_a_row_isize = row_a + row_offset;
            const antinode_a_col_isize = col_a + col_offset;

            var antinode_a: ?Loc = null;
            if (antinode_a_row_isize >= 0 and antinode_a_col_isize >= 0) {
                const antinode_a_row: usize = @intCast(antinode_a_row_isize);
                const antinode_a_col: usize = @intCast(antinode_a_col_isize);
                antinode_a = Loc{ .row = antinode_a_row, .col = antinode_a_col };
            }

            if (antinode_a) |antinode| {
                if (antinode.row < n_rows and antinode.col < n_cols) {
                    try antinodes.put(antinode, true);
                }
            }

            const antinode_b_row_isize = row_b - row_offset;
            const antinode_b_col_isize = col_b - col_offset;

            var antinode_b: ?Loc = null;
            if (antinode_b_row_isize >= 0 and antinode_b_col_isize >= 0) {
                const antinode_b_row: usize = @intCast(antinode_b_row_isize);
                const antinode_b_col: usize = @intCast(antinode_b_col_isize);
                antinode_b = Loc{ .row = antinode_b_row, .col = antinode_b_col };
            }

            if (antinode_b) |antinode| {
                if (antinode.row < n_rows and antinode.col < n_cols) {
                    try antinodes.put(antinode, true);
                }
            }
        }
    }

    print("Number of locations with antinodes: {}\n", .{antinodes.count()});
}

fn get_combinations(allocator: std.mem.Allocator, locs: []const Loc) ![]const []const Loc {
    var combinations = std.ArrayList([]const Loc).init(allocator);

    if (locs.len == 0) return try combinations.toOwnedSlice();

    for (locs, 0..) |loc, i| {
        if (i == 0) continue;

        var combination = try allocator.alloc(Loc, 2);
        combination[0] = locs[0];
        combination[1] = loc;

        try combinations.append(combination);
    }

    var sub_locs = try allocator.alloc(Loc, locs.len - 1);
    for (locs[1..], 0..) |loc, i| {
        sub_locs[i] = loc;
    }
    defer allocator.free(sub_locs);

    const sub_combinations = try get_combinations(allocator, sub_locs);
    try combinations.appendSlice(sub_combinations);

    return try combinations.toOwnedSlice();
}
