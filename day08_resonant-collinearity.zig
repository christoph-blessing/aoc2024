const std = @import("std");
const print = std.debug.print;

const Loc = struct { row: usize, col: usize };

pub fn main() !void {
    const part1_answer = try countAntinodes(1, 1);
    print("Part 1 answer: {}\n", .{part1_answer});

    const part2_answer = try countAntinodes(0, null);
    print("Part 2 answer: {}\n", .{part2_answer});
}

fn countAntinodes(start: usize, end: ?usize) !usize {
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
    const bounds = [2]usize{ n_rows, n_cols };

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
        const combinations = try getCombinations(allocator, entry.value_ptr.items);
        defer {
            for (combinations) |combination| {
                allocator.free(combination);
            }
            allocator.free(combinations);
        }

        for (combinations) |combination| {
            const array: [2]Loc = .{ combination[0], combination[1] };
            const combination_antinodes = try getAntinodes(allocator, array, bounds, start, end);
            for (combination_antinodes) |antinode| try antinodes.put(antinode, true);
        }
    }

    return antinodes.count();
}

fn getAntinodes(allocator: std.mem.Allocator, antennas: [2]Loc, bounds: [2]usize, start: usize, end: ?usize) ![]const Loc {
    const row_a: isize = @intCast(antennas[0].row);
    const col_a: isize = @intCast(antennas[0].col);

    const row_b: isize = @intCast(antennas[1].row);
    const col_b: isize = @intCast(antennas[1].col);

    const row_offset = row_a - row_b;
    const col_offset = col_a - col_b;

    var antinodes = std.ArrayList(Loc).init(allocator);
    errdefer antinodes.deinit();

    const positive_offset = [2]isize{ row_offset, col_offset };
    const positive_antinodes = try getDirAntinodes(allocator, antennas[0], positive_offset, bounds, start, end);
    defer allocator.free(positive_antinodes);
    try antinodes.appendSlice(positive_antinodes);

    const negative_offset = [2]isize{ -row_offset, -col_offset };
    const negative_antinodes = try getDirAntinodes(allocator, antennas[1], negative_offset, bounds, start, end);
    defer allocator.free(negative_antinodes);
    try antinodes.appendSlice(negative_antinodes);

    return try antinodes.toOwnedSlice();
}

const IntegerIterator = struct {
    current: usize,
    end: ?usize,

    pub fn init(start: usize, end: ?usize) IntegerIterator {
        return IntegerIterator{ .current = start, .end = end };
    }

    pub fn next(self: *IntegerIterator) ?usize {
        if (self.end) |end| {
            if (self.current > end) return null;
        }
        const temp = self.current;
        self.current += 1;
        return temp;
    }
};

fn getDirAntinodes(allocator: std.mem.Allocator, antenna: Loc, offset: [2]isize, bounds: [2]usize, start: usize, end: ?usize) ![]const Loc {
    var antinodes = std.ArrayList(Loc).init(allocator);
    errdefer antinodes.deinit();

    var multipliers = IntegerIterator.init(start, end);

    while (multipliers.next()) |multiplier| {
        const multiplier_isize: isize = @intCast(multiplier);
        const antinode = offsetLoc(antenna, [2]isize{ multiplier_isize * offset[0], multiplier_isize * offset[1] }) orelse break;
        if (antinode.row >= bounds[0] or antinode.col >= bounds[1]) break;
        try antinodes.append(antinode);
    }

    return try antinodes.toOwnedSlice();
}

fn offsetLoc(loc: Loc, offset: [2]isize) ?Loc {
    const row: isize = @intCast(loc.row);
    const col: isize = @intCast(loc.col);

    const antinode_row_isize = row + offset[0];
    const antinode_col_isize = col + offset[1];

    var antinode: ?Loc = null;
    if (antinode_row_isize >= 0 and antinode_col_isize >= 0) {
        const antinode_row: usize = @intCast(antinode_row_isize);
        const antinode_col: usize = @intCast(antinode_col_isize);
        antinode = Loc{ .row = antinode_row, .col = antinode_col };
    }

    return antinode;
}

fn getCombinations(allocator: std.mem.Allocator, locs: []const Loc) ![]const []const Loc {
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

    const sub_combinations = try getCombinations(allocator, sub_locs);
    try combinations.appendSlice(sub_combinations);

    return try combinations.toOwnedSlice();
}
