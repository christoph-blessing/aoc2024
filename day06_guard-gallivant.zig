const std = @import("std");
const print = std.debug.print;

const Coord = struct { row: usize, col: usize };
const Direction = enum { up, down, left, right };

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day06.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;

    var guard: Coord = undefined;

    const allocator = std.heap.page_allocator;
    var obstructions = std.ArrayList(Coord).init(allocator);
    defer obstructions.deinit();

    var n_cols: usize = undefined;

    var i_row: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        if (i_row == 0) n_cols = line.len;
        for (line, 0..) |element, i_col| {
            if (element == '^') {
                guard = Coord{ .row = i_row, .col = i_col };
            }
            if (element == '#') {
                try obstructions.append(Coord{ .row = i_row, .col = i_col });
            }
        }
        i_row += 1;
    }

    const n_rows: usize = i_row;

    var visited = std.AutoHashMap(Coord, bool).init(allocator);
    defer visited.deinit();
    try visited.put(guard, true);

    var direction = Direction.up;
    while (true) {
        if (guard.row >= n_rows) break;
        if (guard.col >= n_cols) break;
        const candidate = next(guard, direction) orelse break;
        if (is_obstructed(obstructions.items, candidate)) {
            direction = turn(direction);
        } else {
            guard = candidate;
            try visited.put(guard, true);
        }
    }

    print("Number of visited positions: {}\n", .{visited.count()});
}

fn next(current: Coord, direction: Direction) ?Coord {
    switch (direction) {
        Direction.up => {
            if (current.row == 0) return null;
            return Coord{ .row = current.row - 1, .col = current.col };
        },
        Direction.right => {
            return Coord{ .row = current.row, .col = current.col + 1 };
        },
        Direction.down => {
            return Coord{ .row = current.row + 1, .col = current.col };
        },
        Direction.left => {
            if (current.col == 0) return null;
            return Coord{ .row = current.row, .col = current.col - 1 };
        },
    }
}

fn is_obstructed(obstructions: []const Coord, candidate: Coord) bool {
    for (obstructions) |obstruction| {
        if (obstruction.row == candidate.row and obstruction.col == candidate.col) return true;
    }
    return false;
}

fn turn(current: Direction) Direction {
    switch (current) {
        Direction.up => {
            return Direction.right;
        },
        Direction.right => {
            return Direction.down;
        },
        Direction.down => {
            return Direction.left;
        },
        Direction.left => {
            return Direction.up;
        },
    }
}
