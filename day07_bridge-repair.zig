const std = @import("std");
const print = std.debug.print;

const Equation = struct { result: usize, numbers: []const usize };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("data/day07.txt", .{ .mode = .read_only });
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();
    var line_buffer: [1024]u8 = undefined;

    var sum: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        const result = try parse_equation(allocator, line);
        defer allocator.free(result[1]);
        const equation = result[0];
        print("{}\n", .{equation});

        const start = equation.numbers[0];
        const numbers = equation.numbers[1..];
        if (can_reach(start, numbers, equation.result)) {
            sum += equation.result;
        }
    }
    print("The total calibration result is: {}\n", .{sum});
}

fn can_reach(start: usize, numbers: []const usize, target: usize) bool {
    if (numbers.len == 0) return start == target;

    if (start > target) return false;

    const first = numbers[0];
    const rest = numbers[1..];
    return can_reach(start * first, rest, target) or can_reach(start + first, rest, target) or can_reach(concat(start, first), rest, target);
}

fn concat(a: usize, b: usize) usize {
    var offset: usize = 1;

    while (offset <= b) {
        offset *= 10;
    }

    return a * offset + b;
}

fn parse_equation(allocator: std.mem.Allocator, line: []u8) !struct { Equation, []const usize } {
    var iterator = std.mem.splitSequence(u8, line, ": ");
    const result = try std.fmt.parseInt(usize, iterator.next().?, 10);

    var numbers = std.ArrayList(usize).init(allocator);
    errdefer numbers.deinit();
    const rest = iterator.next().?;
    var numbers_iterator = std.mem.splitScalar(u8, rest, ' ');
    while (numbers_iterator.next()) |number_u8| {
        const number = try std.fmt.parseInt(usize, number_u8, 10);
        try numbers.append(number);
    }
    const owned_numbers = try numbers.toOwnedSlice();
    return .{ Equation{ .result = result, .numbers = owned_numbers }, owned_numbers };
}
