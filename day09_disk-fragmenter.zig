const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day09.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();

    const allocator = std.heap.page_allocator;
    var disk = std.ArrayList(?usize).init(allocator);
    defer disk.deinit();

    var is_file = true;
    var current_file_id: usize = 0;
    while (true) {
        const byte = try reader.readByte();
        if (byte == '\n') break;
        const count = try std.fmt.parseInt(usize, &[_]u8{byte}, 10);

        if (is_file) {
            try disk.appendNTimes(current_file_id, count);
        } else {
            try disk.appendNTimes(null, count);
        }

        if (is_file) current_file_id += 1;
        is_file = !is_file;
    }

    const part1_checksum = part1(disk);

    print("Part 1 checksum: {}\n", .{part1_checksum});
}

fn part1(disk: std.ArrayList(?usize)) usize {
    var i_file: usize = disk.items.len;
    var i_free: usize = 0;
    while (i_file > 0) {
        i_file -= 1;
        if (i_file == i_free) break;

        const file_id = disk.items[i_file] orelse continue;
        disk.items[i_file] = null;

        while (disk.items[i_free] != null) i_free += 1;
        disk.items[i_free] = file_id;
    }

    var checksum: usize = 0;
    for (disk.items, 0..) |maybe_file_id, i| {
        const file_id = maybe_file_id orelse break;
        checksum += i * file_id;
    }

    return checksum;
}
