const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day03.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const token = [_]u8{ 'm', 'u', 'l', '(' };
    var sum: i32 = 0;
    while (true) {
        skip_until(reader, &token) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        const number1 = parse_number(reader, ',') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        } orelse continue;
        const number2 = parse_number(reader, ')') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        } orelse continue;
        sum += number1 * number2;
    }
    std.debug.print("The total is: {}", .{sum});
}

pub fn skip_until(reader: anytype, token: []const u8) !void {
    var index: u8 = 0;
    while (true) {
        const byte = reader.readByte() catch |err| return err;
        if (byte == token[index]) {
            index += 1;
        } else continue;
        if (index == token.len) {
            break;
        }
    }
}

pub fn parse_number(reader: anytype, end: u8) !?i32 {
    const allocator = std.heap.page_allocator;
    var number = std.ArrayList(u8).init(allocator);
    defer number.deinit();

    while (true) {
        const byte = reader.readByte() catch |err| return err;
        if (!std.ascii.isDigit(byte)) {
            if (byte != end) return null;
            return try std.fmt.parseInt(i32, number.items, 10);
        }
        try number.append(byte);
    }
}
