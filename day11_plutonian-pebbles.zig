const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day11.txt", .{ .mode = .read_only });
    defer file.close();

    const allocator = std.heap.page_allocator;
    var stone_bytes = std.ArrayList(u8).init(allocator);
    defer stone_bytes.deinit();

    var stones = std.ArrayList(usize).init(allocator);
    defer stones.deinit();

    while (true) {
        const byte = file.reader().readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte == ' ' or byte == '\n') {
            const stone = try std.fmt.parseInt(usize, stone_bytes.items, 10);
            stone_bytes.clearAndFree();

            try stones.append(stone);

            continue;
        }

        try stone_bytes.append(byte);
    }

    const blink_count: usize = 25;
    var blink_index: usize = 0;
    while (blink_index < blink_count) : (blink_index += 1) {
        var clone = try stones.clone();
        defer clone.deinit();
        stones.clearAndFree();

        for (clone.items) |stone| {
            if (stone == 0) {
                try stones.append(1);
                continue;
            }

            const digit_count = getDigitCount(stone);

            if (digit_count % 2 != 0) {
                try stones.append(stone * 2024);
                continue;
            }

            const digits = try stoneToDigits(allocator, stone, digit_count);
            defer allocator.free(digits);

            const first_stone = try std.fmt.parseInt(usize, digits[0 .. digit_count / 2], 10);
            try stones.append(first_stone);

            const second_stone = try std.fmt.parseInt(usize, digits[digit_count / 2 ..], 10);
            try stones.append(second_stone);
        }
    }

    print("Number of stones: {}\n", .{stones.items.len});
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
