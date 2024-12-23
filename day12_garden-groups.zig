const std = @import("std");

const Location = struct { x: usize, y: usize };
const Region = struct {
    plant: u8,
    plots: std.AutoHashMap(Location, bool),
    fn init(allocator: std.mem.Allocator, plant: u8) Region {
        return Region{ .plant = plant, .plots = std.AutoHashMap(Location, bool).init(allocator) };
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

    const max = Location{ .x = garden.items.len - 1, .y = garden.items[0].len - 1 };

    for (garden.items, 0..) |row, x| for (row, 0..) |_, y| {
        const plot = Location{ .x = x, .y = y };

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

    var price: usize = 0;
    for (regions.items) |region| {
        var region_perimeter: usize = 0;

        var iterator = region.plots.keyIterator();
        while (iterator.next()) |plot| {
            var plot_perimeter: usize = 4;

            const neighbors = try getNeighbors(allocator, plot.*, max);
            defer allocator.free(neighbors);

            for (neighbors) |neighbor| {
                if (region.plots.contains(neighbor)) plot_perimeter -= 1;
            }

            region_perimeter += plot_perimeter;
        }

        price += region.plots.count() * region_perimeter;
    }

    std.debug.print("Total price: {}\n", .{price});
}

fn getRegion(allocator: std.mem.Allocator, garden: *[]const []const u8, start: Location, max: Location) !*Region {
    const region_plant = garden.*[start.x][start.y];

    var queue = std.ArrayList(Location).init(allocator);
    defer queue.deinit();
    try queue.append(start);

    var seen = std.AutoHashMap(Location, bool).init(allocator);
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

        const neighbors = try getNeighbors(allocator, plot, max);
        defer allocator.free(neighbors);

        for (neighbors) |neighbor| {
            if (seen.contains(neighbor)) continue;
            try seen.put(neighbor, true);
            try queue.append(neighbor);
        }
    }

    return region;
}

fn getNeighbors(allocator: std.mem.Allocator, plot: Location, max: Location) ![]const Location {
    var neighbors = std.ArrayList(Location).init(allocator);
    errdefer neighbors.deinit();

    const offsets = [_]isize{ -1, 0, 1 };
    for (offsets) |x_offset| for (offsets) |y_offset| {
        if (@abs(x_offset) == @abs(y_offset)) continue;

        const start_x_isize: isize = @intCast(plot.x);
        const start_y_isize: isize = @intCast(plot.y);

        const candidate_x_isize = start_x_isize + x_offset;
        if (candidate_x_isize < 0 or candidate_x_isize > max.x) continue;

        const candidate_y_isize = start_y_isize + y_offset;
        if (candidate_y_isize < 0 or candidate_y_isize > max.y) continue;

        const candidate_x: usize = @intCast(candidate_x_isize);
        const candidate_y: usize = @intCast(candidate_y_isize);

        try neighbors.append(Location{ .x = candidate_x, .y = candidate_y });
    };

    return neighbors.toOwnedSlice();
}
