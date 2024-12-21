const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day11.txt", .{ .mode = .read_only });
    defer file.close();

    const allocator = std.heap.page_allocator;
    var stone_bytes = std.ArrayList(u8).init(allocator);
    defer stone_bytes.deinit();

    var stones = std.AutoHashMap(usize, usize).init(allocator);
    defer stones.deinit();

    while (true) {
        const byte = file.reader().readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte == ' ' or byte == '\n') {
            const stone = try std.fmt.parseInt(usize, stone_bytes.items, 10);
            stone_bytes.clearAndFree();

            const result = try stones.getOrPut(stone);
            if (result.found_existing) {
                result.value_ptr.* += 1;
                continue;
            }

            result.value_ptr.* = 1;
            continue;
        }

        try stone_bytes.append(byte);
    }

    const part1_count = try countStones(allocator, &stones, 25);
    print("Number of stones after 25 blinks: {}\n", .{part1_count});

    const part2_count = try countStones(allocator, &stones, 75);
    print("Number of stones after 75 blinks: {}\n", .{part2_count});
}

fn countStones(allocator: std.mem.Allocator, stones: *std.AutoHashMap(usize, usize), blink_count: usize) !usize {
    var stones_clone = try stones.clone();
    defer stones_clone.deinit();

    var blink_index: usize = 0;
    while (blink_index < blink_count) : (blink_index += 1) {
        var changes = std.AutoHashMap(usize, usize).init(allocator);
        defer changes.deinit();

        var iterator = stones_clone.iterator();
        while (iterator.next()) |entry| {
            const stone = entry.key_ptr.*;
            const count = entry.value_ptr.*;

            const new_stones = try updateStone(allocator, stone);
            for (new_stones) |new_stone| {
                const result = try changes.getOrPut(new_stone);
                if (!result.found_existing) {
                    result.value_ptr.* = count;
                    continue;
                }
                result.value_ptr.* += count;
            }
        }

        stones_clone.clearAndFree();

        iterator = changes.iterator();
        while (iterator.next()) |entry| {
            try stones_clone.put(entry.key_ptr.*, entry.value_ptr.*);
        }
    }

    var value_iterator = stones_clone.valueIterator();
    var total: usize = 0;
    while (value_iterator.next()) |count| {
        total += count.*;
    }

    return total;
}

fn updateStone(allocator: std.mem.Allocator, stone: usize) ![]const usize {
    var stones = std.ArrayList(usize).init(allocator);
    errdefer stones.deinit();

    if (stone == 0) {
        try stones.append(1);
        return try stones.toOwnedSlice();
    }

    const digit_count = getDigitCount(stone);

    if (digit_count % 2 != 0) {
        try stones.append(stone * 2024);
        return try stones.toOwnedSlice();
    }

    const digits = try stoneToDigits(allocator, stone, digit_count);
    defer allocator.free(digits);

    const first_stone = try std.fmt.parseInt(usize, digits[0 .. digit_count / 2], 10);
    try stones.append(first_stone);

    const second_stone = try std.fmt.parseInt(usize, digits[digit_count / 2 ..], 10);
    try stones.append(second_stone);

    return try stones.toOwnedSlice();
}

fn getDigitCount(stone: usize) usize {
    var temp = stone;
    var digit_count: usize = 0;

    while (temp > 0) : (temp /= 10) {
        digit_count += 1;
    }

    return digit_count;
}

fn stoneToDigits(allocator: std.mem.Allocator, stone: usize, digit_count: usize) ![]u8 {
    var digits = try allocator.alloc(u8, digit_count);

    var digit_index: usize = digit_count;
    var temp = stone;
    while (digit_index > 0) : (digit_index -= 1) {
        const digit: u8 = @intCast(temp % 10);
        digits[digit_index - 1] = digit + '0';
        temp /= 10;
    }

    return digits;
}
