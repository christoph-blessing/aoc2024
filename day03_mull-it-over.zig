const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("data/day03.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    var sum: i32 = 0;
    var is_enabled = true;
    while (true) {
        if (!is_enabled) {
            _ = skip_until(reader, &[_][]const u8{"do()"}) catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };
            is_enabled = true;
        }
        const token = skip_until(reader, &[_][]const u8{ "mul(", "don't()" }) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        if (std.mem.eql(u8, token, "don't()")) {
            is_enabled = false;
            continue;
        }
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

pub fn skip_until(reader: anytype, tokens: []const []const u8) ![]const u8 {
    var index: u8 = 0;
    var found: ?[]const u8 = null;
    while (true) {
        const byte = reader.readByte() catch |err| return err;
        var is_active = false;
        for (tokens) |token| {
            if (index >= token.len) continue;
            if (byte != token[index]) continue;
            if (index == token.len - 1) {
                found = token;
                break;
            }
            is_active = true;
        }
        if (found != null) return found.?;
        if (is_active) {
            is_active = false;
            index += 1;
        } else index = 0;
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
