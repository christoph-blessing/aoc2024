const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day13.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;

    var token_count: usize = 0;
    var is_done = false;
    while (!is_done) {
        const line_a = (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')).?;
        const button_a = try parse(line_a);

        const line_b = (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')).?;
        const button_b = try parse(line_b);

        const prize_line = (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')).?;
        const prize = try parse(prize_line);

        _ = (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) orelse {
            is_done = true;
        };

        const count_b = @divFloor((prize.x * button_a.y - prize.y * button_a.x), (button_b.x * button_a.y - button_b.y * button_a.x));
        if (count_b < 0 or count_b > 100) continue;

        const count_a = @divFloor((prize.y - button_b.y * count_b), button_a.y);
        if (count_a < 0 or count_a > 100) continue;

        if (count_a * button_a.x + count_b * button_b.x != prize.x) continue;
        if (count_a * button_a.y + count_b * button_b.y != prize.y) continue;

        const count_a_usize: usize = @intCast(count_a);
        const count_b_usize: usize = @intCast(count_b);
        token_count += 3 * count_a_usize + count_b_usize;
    }

    std.debug.print("Token count: {}\n", .{token_count});
}

const Vector = struct { x: isize, y: isize };

fn parse(line: []const u8) !Vector {
    const x_index = std.mem.indexOf(u8, line, "X").?;
    const comma_index = std.mem.indexOf(u8, line, ",").?;
    const x = try std.fmt.parseInt(isize, line[x_index + 2 .. comma_index], 10);

    const y_index = std.mem.indexOf(u8, line, "Y").?;
    const y = try std.fmt.parseInt(isize, line[y_index + 2 ..], 10);

    return Vector{ .x = x, .y = y };
}
