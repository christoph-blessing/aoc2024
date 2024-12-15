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
            const combination_antinodes = try get_antinodes(allocator, combination[0], combination[1], n_rows, n_cols);
            for (combination_antinodes) |antinode| try antinodes.put(antinode, true);
        }
    }

    print("Number of locations with antinodes: {}\n", .{antinodes.count()});
}

fn get_antinodes(allocator: std.mem.Allocator, a: Loc, b: Loc, n_rows: usize, n_cols: usize) ![]const Loc {
    const row_a: isize = @intCast(a.row);
    const col_a: isize = @intCast(a.col);

    const row_b: isize = @intCast(b.row);
    const col_b: isize = @intCast(b.col);

    const row_offset = row_a - row_b;
    const col_offset = col_a - col_b;

    var antinodes = std.ArrayList(Loc).init(allocator);
    errdefer antinodes.deinit();

    var n: isize = 0;
    while (true) : (n += 1) {
        const antinode = offset_loc(a, n * row_offset, n * col_offset) orelse break;
        if (antinode.row >= n_rows or antinode.col >= n_cols) break;
        try antinodes.append(antinode);
    }

    n = 1;
    while (true) : (n += 1) {
        const antinode = offset_loc(a, -(n * row_offset), -(n * col_offset)) orelse break;
        if (antinode.row >= n_rows or antinode.col >= n_cols) break;
        try antinodes.append(antinode);
    }

    return try antinodes.toOwnedSlice();
}

fn offset_loc(loc: Loc, row_offset: isize, col_offset: isize) ?Loc {
    const row: isize = @intCast(loc.row);
    const col: isize = @intCast(loc.col);

    const antinode_row_isize = row + row_offset;
    const antinode_col_isize = col + col_offset;

    var antinode: ?Loc = null;
    if (antinode_row_isize >= 0 and antinode_col_isize >= 0) {
        const antinode_row: usize = @intCast(antinode_row_isize);
        const antinode_col: usize = @intCast(antinode_col_isize);
        antinode = Loc{ .row = antinode_row, .col = antinode_col };
    }

    return antinode;
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
