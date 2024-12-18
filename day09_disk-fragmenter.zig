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

    const part1_checksum = try part1(&disk);
    print("Part 1 checksum: {}\n", .{part1_checksum});

    const part2_checksum = try part2(allocator, &disk);
    print("Part 2 checksum: {}\n", .{part2_checksum});
}

fn part1(disk: *const std.ArrayList(?usize)) !usize {
    var cloned_disk = try disk.clone();
    defer cloned_disk.deinit();

    var i_file: usize = cloned_disk.items.len;
    var i_free: usize = 0;
    while (i_file > 0) {
        i_file -= 1;
        if (i_file == i_free) break;

        const file_id = cloned_disk.items[i_file] orelse continue;
        cloned_disk.items[i_file] = null;

        while (cloned_disk.items[i_free] != null) i_free += 1;
        cloned_disk.items[i_free] = file_id;
    }

    var checksum: usize = 0;
    for (cloned_disk.items, 0..) |maybe_file_id, i| {
        const file_id = maybe_file_id orelse break;
        checksum += i * file_id;
    }

    return checksum;
}

fn part2(allocator: std.mem.Allocator, disk: *const std.ArrayList(?usize)) !usize {
    const cloned_disk = try disk.clone();
    defer cloned_disk.deinit();

    var moved = std.AutoHashMap(usize, bool).init(allocator);
    defer moved.deinit();

    var i_file: usize = cloned_disk.items.len;
    var file_size: usize = 0;
    var maybe_file_id: ?usize = null;
    while (i_file > 0) {
        i_file -= 1;

        if (cloned_disk.items[i_file] == null and maybe_file_id == null) continue;

        if (cloned_disk.items[i_file]) |current_file_id| {
            if (maybe_file_id) |prev_file_id| {
                if (current_file_id == prev_file_id) {
                    file_size += 1;
                    continue;
                }

                if (!moved.contains(prev_file_id)) {
                    try moveFile(cloned_disk.items, i_file + 1, file_size);
                    try moved.put(prev_file_id, true);
                }

                maybe_file_id = current_file_id;
                file_size = 1;

                if (moved.contains(current_file_id)) continue;

                if (i_file != 0) continue;

                try moveFile(cloned_disk.items, i_file + 1, file_size);
                try moved.put(current_file_id, true);
                continue;
            }

            maybe_file_id = current_file_id;
            file_size += 1;

            if (moved.contains(current_file_id)) continue;

            if (i_file != 0) continue;

            try moveFile(cloned_disk.items, i_file, file_size);
            try moved.put(current_file_id, true);
        }

        const file_id = maybe_file_id.?;
        if (!moved.contains(file_id)) {
            try moveFile(cloned_disk.items, i_file + 1, file_size);
            try moved.put(file_id, true);
        }

        maybe_file_id = null;
        file_size = 0;
    }

    var checksum: usize = 0;
    for (cloned_disk.items, 0..) |block, i| {
        checksum += i * (block orelse continue);
    }

    return checksum;
}

fn moveFile(disk: []?usize, start: usize, file_size: usize) !void {
    const file_id = disk[start].?;
    var i_free: usize = 0;
    var free_size: usize = 0;
    while (i_free < disk.len) : (i_free += 1) {
        if (i_free >= start) break;

        if (disk[i_free] != null) {
            free_size = 0;
            continue;
        }

        free_size += 1;

        if (file_size != free_size) continue;

        var i: usize = start;
        while (i < start + file_size) : (i += 1) {
            if (disk[i] == null) unreachable;
            disk[i] = null;
        }

        i = i_free;
        while (i > i_free - file_size) : (i -= 1) {
            if (disk[i] != null) unreachable;
            disk[i] = file_id;
        }

        break;
    }
}
