const std = @import("std");
const print = std.debug.print;
const allocator = std.heap.page_allocator;

const Coord = struct { row: usize, col: usize };
const Direction = enum { up, down, left, right };
const PatrolState = struct { position: Coord, direction: Direction };

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day06_example.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;

    var initial: PatrolState = undefined;

    var obstructions = std.ArrayList(Coord).init(allocator);
    defer obstructions.deinit();

    var n_cols: usize = undefined;

    var i_row: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        if (i_row == 0) n_cols = line.len;
        for (line, 0..) |element, i_col| {
            if (element == '^') {
                initial = PatrolState{ .position = Coord{ .row = i_row, .col = i_col }, .direction = Direction.up };
            }
            if (element == '#') {
                try obstructions.append(Coord{ .row = i_row, .col = i_col });
            }
        }
        i_row += 1;
    }

    const n_rows: usize = i_row;
    const size = Coord{ .row = n_rows, .col = n_cols };

    var visited = std.AutoHashMap(Coord, bool).init(allocator);
    defer visited.deinit();
    try visited.put(initial.position, true);

    var patrol_iterator = PatrolIterator{ .initial = initial, .obstructions = obstructions.items, .size = size };
    while (patrol_iterator.next()) |state| {
        try visited.put(state.position, true);
    }

    print("Number of visited positions: {}\n", .{visited.count()});
}

fn is_looping(initial: PatrolState, obstructions: []const Coord, size: Coord) !bool {
    var iterator = PatrolIterator{ .initial = initial, .obstructions = obstructions, .size = size };
    var visited = std.AutoHashMap(PatrolState, bool).init(allocator);
    defer visited.deinit();

    while (iterator.next()) |state| {
        if (visited.contains(state)) return true;
        try visited.put(state, true);
    }
    return false;
}

const PatrolIterator = struct {
    initial: PatrolState,
    obstructions: []const Coord,
    size: Coord,
    fn next(self: *PatrolIterator) ?PatrolState {
        while (true) {
            if (self.initial.position.row >= self.size.row - 1) return null;
            if (self.initial.position.col >= self.size.col - 1) return null;
            const candidate = get_candidate(self.initial) orelse return null;
            if (is_obstructed(self.obstructions, candidate)) {
                self.initial.direction = turn(self.initial.direction);
            } else {
                self.initial.position = candidate;
                return self.initial;
            }
        }
    }
};

fn get_candidate(current: PatrolState) ?Coord {
    switch (current.direction) {
        Direction.up => {
            if (current.position.row == 0) return null;
            return Coord{ .row = current.position.row - 1, .col = current.position.col };
        },
        Direction.right => {
            return Coord{ .row = current.position.row, .col = current.position.col + 1 };
        },
        Direction.down => {
            return Coord{ .row = current.position.row + 1, .col = current.position.col };
        },
        Direction.left => {
            if (current.position.col == 0) return null;
            return Coord{ .row = current.position.row, .col = current.position.col - 1 };
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
