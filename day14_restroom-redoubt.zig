const std = @import("std");

const Vector = struct { x: isize, y: isize };
const Robot = struct { position: Vector, velocity: Vector };

const filepath = "data/day14.txt";
const space_size = Vector{ .x = 101, .y = 103 };
const step_count: usize = 100;

pub fn main() !void {
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

    var step_index: usize = 0;
    while (step_index < step_count) : (step_index += 1) {
        for (robots.items, 0..) |robot, robot_index| {
            var new_x = robot.position.x + robot.velocity.x;
            if (new_x < 0) new_x += space_size.x;
            if (new_x >= space_size.x) new_x -= space_size.x;

            var new_y = robot.position.y + robot.velocity.y;
            if (new_y < 0) new_y += space_size.y;
            if (new_y >= space_size.y) new_y -= space_size.y;

            const updated_robot = Robot{ .position = Vector{ .x = new_x, .y = new_y }, .velocity = robot.velocity };
            robots.items[robot_index] = updated_robot;
        }
    }

    var quadrant_counts = [_]usize{ 0, 0, 0, 0 };
    for (robots.items) |robot| {
        const mid_x = @divFloor(space_size.x, 2);
        const mid_y = @divFloor(space_size.y, 2);

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

    std.debug.print("Safety factor: {}\n", .{safety_factor});
}

fn printSpace(robots: []Robot) void {
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

    for (space) |row| {
        std.debug.print("{s}\n", .{row});
    }
}
