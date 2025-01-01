const std = @import("std");

const Vector = struct { x: isize, y: isize };
const Robot = struct { position: Vector, velocity: Vector };

pub fn main() !void {
    const filepath = "data/day14.txt";
    const space_size = Vector{ .x = 101, .y = 103 };

    const file = try std.fs.cwd().openFile(filepath, .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;

    const allocator = std.heap.page_allocator;
    var robots = std.ArrayList(Robot).init(allocator);
    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        var iterator = std.mem.splitScalar(u8, line, ' ');

        var position_iterator = std.mem.splitScalar(u8, iterator.next().?[2..], ',');
        const position_x = try std.fmt.parseInt(isize, position_iterator.next().?, 10);
        const position_y = try std.fmt.parseInt(isize, position_iterator.next().?, 10);
        const position = Vector{ .x = position_x, .y = position_y };

        var velocity_iterator = std.mem.splitScalar(u8, iterator.next().?[2..], ',');
        const velocity_x = try std.fmt.parseInt(isize, velocity_iterator.next().?, 10);
        const velocity_y = try std.fmt.parseInt(isize, velocity_iterator.next().?, 10);
        const velocity = Vector{ .x = velocity_x, .y = velocity_y };

        try robots.append(Robot{ .position = position, .velocity = velocity });
    }

    const safety_factor = try part1(allocator, robots.items, space_size);
    std.debug.print("Safety factor: {}\n", .{safety_factor});

    const seconds_to_tree = try part2(allocator, robots.items, space_size);
    std.debug.print("Christmas tree displayed after {} seconds\n", .{seconds_to_tree});
}

fn part1(allocator: std.mem.Allocator, robots: []const Robot, size: Vector) !usize {
    var updated_robots = std.ArrayList(Robot).init(allocator);
    defer updated_robots.deinit();

    for (robots) |robot| {
        try updated_robots.append(updateRobot(robot, 100.0, size));
    }

    var quadrant_counts = [_]usize{ 0, 0, 0, 0 };
    for (updated_robots.items) |robot| {
        const mid_x = @divFloor(size.x, 2);
        const mid_y = @divFloor(size.y, 2);

        if (robot.position.x == mid_x) continue;
        if (robot.position.y == mid_y) continue;

        if (robot.position.x < mid_x) {
            if (robot.position.y < mid_y) {
                quadrant_counts[0] += 1;
            } else quadrant_counts[1] += 1;
        } else {
            if (robot.position.y < mid_y) {
                quadrant_counts[2] += 1;
            } else quadrant_counts[3] += 1;
        }
    }

    var safety_factor: usize = 1;
    for (quadrant_counts) |count| {
        safety_factor *= count;
    }

    return safety_factor;
}

fn updateRobot(robot: Robot, step_count: isize, size: Vector) Robot {
    const new_x = @mod(robot.position.x + robot.velocity.x * step_count, size.x);
    const new_y = @mod(robot.position.y + robot.velocity.y * step_count, size.y);

    return Robot{ .position = Vector{ .x = new_x, .y = new_y }, .velocity = robot.velocity };
}

fn part2(allocator: std.mem.Allocator, robots: []const Robot, size: Vector) !usize {
    var max_count: usize = 0;
    var max_count_index: usize = 0;
    var step_index: usize = 2;
    while (step_index < size.x * size.y) : (step_index += 1) {
        var updated_robots = std.ArrayList(Robot).init(allocator);
        defer updated_robots.deinit();

        const step_index_isize: isize = @intCast(step_index);
        for (robots) |robot| {
            try updated_robots.append(updateRobot(robot, step_index_isize, size));
        }

        var count: usize = 0;
        for (updated_robots.items) |robot| {
            const lower_bound = Vector{ .x = @divFloor(size.x, 4), .y = @divFloor(size.y, 4) };
            if (robot.position.x < lower_bound.x or robot.position.y < lower_bound.y) continue;

            const upper_bound = Vector{ .x = 3 * @divFloor(size.x, 4), .y = 3 * @divFloor(size.y, 4) };
            if (robot.position.x > upper_bound.x or robot.position.y > upper_bound.y) continue;

            count += 1;
        }

        if (count > max_count) {
            max_count = count;
            max_count_index = step_index;
        }
    }

    return max_count_index;
}

fn printSpace(robots: []Robot, space_size: Vector) void {
    var space: [space_size.y][space_size.x]u8 = undefined;
    for (&space) |*row| {
        for (row) |*element| {
            element.* = '.';
        }
    }

    for (robots) |robot| {
        const x_usize: usize = @intCast(robot.position.x);
        const y_usize: usize = @intCast(robot.position.y);
        space[y_usize][x_usize] = 'X';
    }

    for (space, 0..) |row, index| {
        std.debug.print("{:3} {s}\n", .{ index, row });
    }
}
