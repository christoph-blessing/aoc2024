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

        const combinations = try get_combinations(allocator, "*+|", equation.numbers.len - 1);
        defer {
            for (combinations) |combination| {
                allocator.free(combination);
            }
            allocator.free(combinations);
        }
        for (combinations) |combination| {
            var actual = equation.numbers[0];
            print("({}", .{equation.numbers[0]});
            for (combination, 1..) |operator, index| {
                print(" {c} {}", .{ operator, equation.numbers[index] });
                switch (operator) {
                    '*' => {
                        actual *= equation.numbers[index];
                    },
                    '+' => {
                        actual += equation.numbers[index];
                    },
                    '|' => {
                        const number_u8 = try std.fmt.allocPrint(allocator, "{}", .{equation.numbers[index]});
                        defer allocator.free(number_u8);

                        const old_actual_u8 = try std.fmt.allocPrint(allocator, "{}", .{actual});
                        defer allocator.free(old_actual_u8);

                        const actual_u8 = try std.mem.concat(allocator, u8, &[_][]u8{ old_actual_u8, number_u8 });
                        defer allocator.free(actual_u8);

                        actual = try std.fmt.parseInt(usize, actual_u8, 10);
                    },
                    else => unreachable,
                }
            }
            print(" = {})", .{actual});
            if (actual == equation.result) {
                sum += equation.result;
                print(" == {}\n", .{equation.result});
                break;
            }
            print(" != {}\n", .{equation.result});
        }
    }
    print("The total calibration result is: {}\n", .{sum});
}

fn get_combinations(allocator: std.mem.Allocator, elements: []const u8, repetitions: usize) ![]const []const u8 {
    var combinations = std.ArrayList([]const u8).init(allocator);
    for (elements) |element| {
        if (repetitions == 1) {
            var combination = try allocator.alloc(u8, 1);
            combination[0] = element;
            try combinations.append(combination);
            continue;
        }
        const sub_combinations = try get_combinations(allocator, elements, repetitions - 1);
        defer {
            for (sub_combinations) |sub_combination| {
                allocator.free(sub_combination);
            }
            allocator.free(sub_combinations);
        }
        for (sub_combinations) |sub_combination| {
            var combination = try allocator.alloc(u8, sub_combination.len + 1);
            combination[0] = element;
            std.mem.copyForwards(u8, combination[1..], sub_combination);
            try combinations.append(combination);
        }
    }
    return combinations.toOwnedSlice();
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
