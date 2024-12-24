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

    std.debug.print("Total price: {}\n", .{part1_price});
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

        const neighbors = try getNeighbors(allocator, plot);
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
        if (@abs(x_offset) == @abs(y_offset)) continue;

        const plot_x_isize: isize = @intCast(plot.x);
        const plot_y_isize: isize = @intCast(plot.y);

        const neighbor_x_isize = plot_x_isize + x_offset;
        const neighbor_y_isize = plot_y_isize + y_offset;

        try neighbors.append(Location{ .x = neighbor_x_isize, .y = neighbor_y_isize });
    };

    return neighbors.toOwnedSlice();
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

            const neighbors = try getNeighbors(allocator, plot.*);
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
