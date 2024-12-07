const std = @import("std");
const print = std.debug.print;

const Rule = struct { before: usize, after: usize };

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day05.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;

    const allocator = std.heap.page_allocator;
    var rules = std.ArrayList(Rule).init(allocator);
    defer rules.deinit();

    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        if (std.mem.eql(u8, line, "")) break;
        var iterator = std.mem.splitScalar(u8, line, '|');
        var before: ?usize = null;
        var after: ?usize = null;
        while (iterator.next()) |number_u8| {
            const number = try std.fmt.parseInt(usize, number_u8, 10);
            if (before == null) {
                before = number;
                continue;
            }
            if (after == null) {
                after = number;
                break;
            }
        }
        if (before != null and after != null) {
            try rules.append(Rule{ .before = before.?, .after = after.? });
        }
    }

    var update = std.ArrayList(usize).init(allocator);
    defer update.deinit();

    var n: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        update.clearAndFree();
        var iterator = std.mem.splitScalar(u8, line, ',');
        while (iterator.next()) |number_u8| {
            const number = try std.fmt.parseInt(usize, number_u8, 10);
            try update.append(number);
        }

        var is_correct = true;
        for (rules.items) |rule| {
            var before_index: ?usize = null;
            var after_index: ?usize = null;
            for (update.items, 0..) |number, index| {
                if (number == rule.before) {
                    before_index = index;
                } else if (number == rule.after) {
                    after_index = index;
                }
            }
            if (before_index == null or after_index == null) continue;
            if (before_index.? > after_index.?) {
                is_correct = false;
            }
        }

        if (!is_correct) continue;

        n += update.items[@divFloor(update.items.len, 2)];
    }

    print("Sum of page numbers: {}\n", .{n});
}
