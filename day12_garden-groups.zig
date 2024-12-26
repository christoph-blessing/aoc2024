const std = @import("std");

const Location = struct { x: isize, y: isize };
const ValidLocation = struct { x: usize, y: usize };
const Region = struct {
    plant: u8,
    plots: std.AutoHashMap(ValidLocation, bool),
    fn init(allocator: std.mem.Allocator, plant: u8) Region {
        return Region{ .plant = plant, .plots = std.AutoHashMap(ValidLocation, bool).init(allocator) };
    }
    fn deinit(self: *Region) void {
        self.plots.deinit();
    }
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day12.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;

    const allocator = std.heap.page_allocator;
    var garden = std.ArrayList([]const u8).init(allocator);
    defer {
        for (garden.items) |row| allocator.free(row);
        garden.deinit();
    }

    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        try garden.append(try allocator.dupe(u8, line));
    }

    var regions = std.ArrayList(*Region).init(allocator);
    defer {
        for (regions.items) |region| region.deinit();
        regions.deinit();
    }

    const max = ValidLocation{ .x = garden.items.len - 1, .y = garden.items[0].len - 1 };

    for (garden.items, 0..) |row, x| for (row, 0..) |_, y| {
        const plot = ValidLocation{ .x = x, .y = y };

        var seen = false;
        for (regions.items) |region| {
            if (region.plots.contains(plot)) {
                seen = true;
                break;
            }
        }
        if (seen) continue;

        var region = try getRegion(allocator, &garden.items, plot, max);
        errdefer region.deinit();

        try regions.append(region);
    };

    const part1_price = try part1(allocator, regions.items, max);
    std.debug.print("Part 1 price: {}\n", .{part1_price});

    const part2_price = try part2(allocator, regions.items, max);
    std.debug.print("Part 2 price: {}\n", .{part2_price});
}

fn getRegion(allocator: std.mem.Allocator, garden: *[]const []const u8, start: ValidLocation, max: ValidLocation) !*Region {
    const region_plant = garden.*[start.x][start.y];

    var queue = std.ArrayList(ValidLocation).init(allocator);
    defer queue.deinit();
    try queue.append(start);

    var seen = std.AutoHashMap(ValidLocation, bool).init(allocator);
    defer seen.deinit();
    try seen.put(start, true);

    var region = try allocator.create(Region);
    region.* = Region.init(allocator, region_plant);
    errdefer region.deinit();

    while (true) {
        if (queue.items.len == 0) break;
        const plot = queue.orderedRemove(0);

        const plant = garden.*[plot.x][plot.y];
        if (plant != region_plant) continue;

        try region.plots.put(plot, true);

        const neighbors = try getTouchingNeighbors(allocator, plot);
        defer allocator.free(neighbors);

        for (neighbors) |neighbor| {
            const valid_neighbor = validateLocation(neighbor, max) orelse continue;
            if (seen.contains(valid_neighbor)) continue;
            try seen.put(valid_neighbor, true);
            try queue.append(valid_neighbor);
        }
    }

    return region;
}

fn getNeighbors(allocator: std.mem.Allocator, plot: ValidLocation) ![]const Location {
    var neighbors = std.ArrayList(Location).init(allocator);
    errdefer neighbors.deinit();

    const offsets = [_]isize{ -1, 0, 1 };
    for (offsets) |x_offset| for (offsets) |y_offset| {
        if (x_offset == 0 and y_offset == 0) continue;

        const plot_x_isize: isize = @intCast(plot.x);
        const plot_y_isize: isize = @intCast(plot.y);

        const neighbor_x_isize = plot_x_isize + x_offset;
        const neighbor_y_isize = plot_y_isize + y_offset;

        try neighbors.append(Location{ .x = neighbor_x_isize, .y = neighbor_y_isize });
    };

    return neighbors.toOwnedSlice();
}

fn getTouchingNeighbors(allocator: std.mem.Allocator, plot: ValidLocation) ![]const Location {
    const neighbors = try getNeighbors(allocator, plot);
    defer allocator.free(neighbors);

    var touching_neighbors = std.ArrayList(Location).init(allocator);
    errdefer touching_neighbors.deinit();

    for (neighbors) |neighbor| {
        if (check_diagonality(plot, neighbor)) continue;
        try touching_neighbors.append(neighbor);
    }

    return try touching_neighbors.toOwnedSlice();
}

fn validateLocation(maybe_location: Location, max: ValidLocation) ?ValidLocation {
    if (maybe_location.x < 0 or maybe_location.y < 0) return null;
    if (maybe_location.x > max.x or maybe_location.y > max.y) return null;

    const x: usize = @intCast(maybe_location.x);
    const y: usize = @intCast(maybe_location.y);
    return ValidLocation{ .x = x, .y = y };
}

fn part1(allocator: std.mem.Allocator, regions: []*const Region, max: ValidLocation) !usize {
    var price: usize = 0;
    for (regions) |region| {
        var region_perimeter: usize = 0;

        var iterator = region.plots.keyIterator();
        while (iterator.next()) |plot| {
            var plot_perimeter: usize = 4;

            const neighbors = try getTouchingNeighbors(allocator, plot.*);
            defer allocator.free(neighbors);

            for (neighbors) |neighbor| {
                const valid_neighbor = validateLocation(neighbor, max) orelse continue;
                if (region.plots.contains(valid_neighbor)) plot_perimeter -= 1;
            }

            region_perimeter += plot_perimeter;
        }

        price += region.plots.count() * region_perimeter;
    }

    return price;
}

const Quadrant = enum { north_west, north_east, south_east, south_west };
const Corner = struct { location: Location, is_diagonal: bool };

fn part2(allocator: std.mem.Allocator, regions: []*const Region, max: ValidLocation) !usize {
    const quadrants = [_]Quadrant{
        Quadrant.north_west,
        Quadrant.north_east,
        Quadrant.south_east,
        Quadrant.south_west,
    };
    const operator = std.math.CompareOperator;
    const quadrant_comparators = [4][3][2]operator{ [3][2]operator{
        [_]operator{ operator.eq, operator.lt },
        [_]operator{ operator.lt, operator.lt },
        [_]operator{ operator.lt, operator.eq },
    }, [3][2]operator{
        [_]operator{ operator.lt, operator.eq },
        [_]operator{ operator.lt, operator.gt },
        [_]operator{ operator.eq, operator.gt },
    }, [3][2]operator{
        [_]operator{ operator.eq, operator.gt },
        [_]operator{ operator.gt, operator.gt },
        [_]operator{ operator.gt, operator.eq },
    }, [3][2]operator{
        [_]operator{ operator.gt, operator.eq },
        [_]operator{ operator.gt, operator.lt },
        [_]operator{ operator.eq, operator.lt },
    } };

    var price: usize = 0;

    for (regions) |region| {
        var corners = std.AutoHashMap(Corner, bool).init(allocator);
        defer corners.deinit();

        var iterator = region.plots.keyIterator();
        while (iterator.next()) |plot| {
            const neighbors = try getNeighbors(allocator, plot.*);
            defer allocator.free(neighbors);

            var in_neighbors = std.ArrayList(ValidLocation).init(allocator);
            defer in_neighbors.deinit();
            for (neighbors) |neighbor| {
                const valid_neighbor = validateLocation(neighbor, max) orelse continue;
                if (!region.plots.contains(valid_neighbor)) continue;
                try in_neighbors.append(valid_neighbor);
            }

            for (quadrant_comparators, 0..) |comparators, quadrant_index| {
                var occupancy = [_]bool{ false, false, false };

                for (comparators, 0..) |comparator, comparator_index| {
                    for (in_neighbors.items) |neighbor| {
                        const is_occupied = check_occupancy(plot.*, comparator, neighbor);
                        occupancy[comparator_index] = is_occupied;
                        if (is_occupied) break;
                    }
                }

                var occupied_count: u8 = 0;
                for (occupancy) |is_occupied| {
                    if (is_occupied == true) occupied_count += 1;
                }

                const is_corner = switch (occupied_count) {
                    0 => true,
                    2 => true,
                    1 => occupancy[1],
                    3 => false,
                    else => unreachable,
                };
                if (!is_corner) continue;

                const plot_x_isize: isize = @intCast(plot.x);
                const plot_y_isize: isize = @intCast(plot.y);

                const corner_location = switch (quadrants[quadrant_index]) {
                    Quadrant.north_west => Location{ .x = plot_x_isize - 1, .y = plot_y_isize - 1 },
                    Quadrant.north_east => Location{ .x = plot_x_isize - 1, .y = plot_y_isize },
                    Quadrant.south_east => Location{ .x = plot_x_isize, .y = plot_y_isize },
                    Quadrant.south_west => Location{ .x = plot_x_isize, .y = plot_y_isize - 1 },
                };
                const corner = Corner{ .location = corner_location, .is_diagonal = occupied_count == 1 and occupancy[1] };

                try corners.put(corner, true);
            }
        }

        var corner_count = corners.count();
        var corner_iterator = corners.keyIterator();
        while (corner_iterator.next()) |corner| {
            if (!corner.is_diagonal) continue;
            corner_count += 1;
        }

        price += region.plots.count() * corner_count;
    }

    return price;
}

fn check_diagonality(plot: anytype, neighbor: anytype) bool {
    return (plot.x != neighbor.x and plot.y != neighbor.y);
}

fn check_occupancy(plot: ValidLocation, comparator: [2]std.math.CompareOperator, neighbor: ValidLocation) bool {
    return std.math.compare(neighbor.x, comparator[0], plot.x) and std.math.compare(neighbor.y, comparator[1], plot.y);
}
