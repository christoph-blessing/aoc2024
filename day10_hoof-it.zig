const std = @import("std");
const print = std.debug.print;

const Loc = struct { x: usize, y: usize };

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day10.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;

    const allocator = std.heap.page_allocator;
    var trailheads = std.ArrayList(Loc).init(allocator);
    defer trailheads.deinit();

    var map = std.ArrayList([]const usize).init(allocator);

    var i_row: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        var row = std.ArrayList(usize).init(allocator);

        for (line, 0..) |byte, i_col| {
            const height = try std.fmt.parseInt(usize, &[_]u8{byte}, 10);
            if (height == 0) try trailheads.append(Loc{ .x = i_row, .y = i_col });
            try row.append(height);
        }

        try map.append(try row.toOwnedSlice());

        i_row += 1;
    }

    defer {
        for (map.items) |row| allocator.free(row);
        map.deinit();
    }

    var total_score: usize = 0;
    var total_rating: usize = 0;
    for (trailheads.items) |trailhead| {
        const peaks = try findPeaks(allocator, map.items, trailhead);
        defer allocator.free(peaks);

        var unique_peaks = std.AutoHashMap(Loc, bool).init(allocator);
        defer unique_peaks.deinit();

        for (peaks) |peak| try unique_peaks.put(peak, true);

        total_score += unique_peaks.count();
        total_rating += peaks.len;
    }

    print("Total score: {}\n", .{total_score});
    print("Total rating: {}\n", .{total_rating});
}

fn findPeaks(allocator: std.mem.Allocator, map: [][]const usize, current: Loc) ![]const Loc {
    var peaks = std.ArrayList(Loc).init(allocator);
    errdefer peaks.deinit();

    const current_height = map[current.x][current.y];

    if (current_height == 9) {
        try peaks.append(current);
        return try peaks.toOwnedSlice();
    }

    const neighbors = try getNeighbors(allocator, current);
    defer allocator.free(neighbors);

    const x_max = map.len;
    const y_max = map[0].len;

    for (neighbors) |neighbor| {
        if (neighbor.x >= x_max or neighbor.y >= y_max) continue;

        const neighbor_height = map[neighbor.x][neighbor.y];
        if (current_height + 1 != neighbor_height) continue;

        const sub_peaks = try findPeaks(allocator, map, neighbor);
        defer allocator.free(sub_peaks);

        try peaks.appendSlice(sub_peaks);
    }

    return try peaks.toOwnedSlice();
}

fn getNeighbors(allocator: std.mem.Allocator, loc: Loc) ![]const Loc {
    const x_int: isize = @intCast(loc.x);
    const y_int: isize = @intCast(loc.y);

    const offsets = [_]isize{ -1, 0, 1 };

    var neighbors = std.ArrayList(Loc).init(allocator);
    errdefer neighbors.deinit();

    for (offsets) |x_offset| {
        for (offsets) |y_offset| {
            if (@abs(x_offset) == @abs(y_offset)) continue;

            const x_neighbor_int = x_int + x_offset;
            if (x_neighbor_int < 0) continue;

            const y_neighbor_int = y_int + y_offset;
            if (y_neighbor_int < 0) continue;

            const x_neighbor: usize = @intCast(x_neighbor_int);
            const y_neighbor: usize = @intCast(y_neighbor_int);

            try neighbors.append(Loc{ .x = x_neighbor, .y = y_neighbor });
        }
    }

    return try neighbors.toOwnedSlice();
}
