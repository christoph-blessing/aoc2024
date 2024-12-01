const std = @import("std");

pub fn main() !void {
    const print = std.debug.print;
    const file = try std.fs.cwd().openFile("data/day01.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();

    const allocator = std.heap.page_allocator;
    var left_list = std.ArrayList(i32).init(allocator);
    defer left_list.deinit();
    var right_list = std.ArrayList(i32).init(allocator);
    defer right_list.deinit();
    var line_buffer: [1024]u8 = undefined;
    const delimiter = "   ";
    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        var i: u8 = 0;
        var iterator = std.mem.splitSequence(u8, line, delimiter);
        while (iterator.next()) |id_string| {
            const id_integer = try std.fmt.parseInt(i32, id_string, 10);
            if (i == 0) {
                try left_list.append(id_integer);
            } else {
                try right_list.append(id_integer);
            }
            i += 1;
        }
    }

    std.mem.sort(i32, left_list.items, {}, compareIds);
    std.mem.sort(i32, right_list.items, {}, compareIds);

    var total_distance: u32 = 0;
    for (left_list.items, 0..) |id, index| {
        const distance = @abs(id - right_list.items[index]);
        total_distance += distance;
    }
    print("The total distance is: {}\n", .{total_distance});

    var total_score: i32 = 0;
    for (left_list.items) |left_id| {
        var n: u8 = 0;
        for (right_list.items) |right_id| {
            if (right_id == left_id) {
                n += 1;
            }
        }
        total_score += n * left_id;
    }
    print("The total similarity score is: {}\n", .{total_score});
}

fn compareIds(_: void, left_id: i32, right_id: i32) bool {
    return left_id < right_id;
}
