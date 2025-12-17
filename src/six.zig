const std = @import("std");
const data = @embedFile("inputs/6");

const Op = union(enum) { add, mult, lit: usize };

fn reduce(In: type, Out: type, f: *const fn (Out, In) Out, values: []const In, default: Out) Out {
    var acc: Out = default;
    for (values) |value| {
        acc = f(acc, value);
    }
    return acc;
}

fn sum(a: usize, b: usize) usize {
    return a + b;
}
fn mult(a: usize, b: usize) usize {
    return a * b;
}

fn partOne(a: std.mem.Allocator) !u64 {
    var rows = std.ArrayList(std.ArrayList(Op)).empty;
    defer rows.deinit(a);
    defer for (rows.items) |*row| {
        row.deinit(a);
    };

    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    while (lines.next()) |line| {
        var row = std.ArrayList(Op).empty;
        errdefer row.deinit(a);

        var ops = std.mem.tokenizeScalar(u8, line, ' ');
        while (ops.next()) |op| {
            const parsed = switch (op[0]) {
                '+' => Op.add,
                '*' => Op.mult,
                else => Op{ .lit = try std.fmt.parseInt(usize, op, 10) },
            };
            try row.append(a, parsed);
        }
        try rows.append(a, row);
    }

    var accumulator: u64 = 0;
    for (0..rows.items[0].items.len) |col| {
        const op = rows.getLast().items[col];
        var result: u64 = if (op == .add) 0 else 1;
        for (rows.items[0 .. rows.items.len - 1]) |row| {
            switch (row.items[col]) {
                .lit => |val| {
                    if (op == .add) {
                        result += val;
                    } else {
                        result *= val;
                    }
                },
                else => unreachable,
            }
        }
        accumulator += result;
    }

    return accumulator;
}

fn partTwo(a: std.mem.Allocator) !u64 {
    var rows = std.ArrayList([]const u8).empty;
    defer rows.deinit(a);

    var rowIter = std.mem.tokenizeScalar(u8, data, '\n');
    while (rowIter.next()) |row| {
        try rows.append(a, row);
    }

    var accumulator: usize = 0;
    var i: i64 = @as(i64, @intCast(rows.items[0].len - 1));
    var collectedNumbers = std.ArrayList(usize).empty;
    defer collectedNumbers.deinit(a);
    while (i >= 0) : (i -= 1) {
        const idx: usize = @as(usize, @intCast(i));
        var num: usize = 0;
        for (rows.items[0 .. rows.items.len - 1]) |row| {
            if (row[idx] != ' ') {
                if (num != 0) {
                    num *= 10;
                }
                num += try std.fmt.charToDigit(row[idx], 10);
            }
        }
        try collectedNumbers.append(a, num);
        const maybeOp = rows.items[rows.items.len - 1][idx];
        switch (maybeOp) {
            '+' => {
                const partialResult = reduce(usize, usize, sum, collectedNumbers.items, 0);
                accumulator += partialResult;
                if (i > 0) {
                    i -= 1;
                }
                collectedNumbers.clearRetainingCapacity();
            },
            '*' => {
                const partialResult = reduce(usize, usize, mult, collectedNumbers.items, 1);
                accumulator += partialResult;
                if (i > 0) {
                    i -= 1;
                }
                collectedNumbers.clearRetainingCapacity();
            },
            else => {},
        }
    }

    return accumulator;
}

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();
    std.debug.print("day 6, part 1: {}\n", .{try partOne(allocator)});
    std.debug.print("day 6, part 2: {}\n", .{try partTwo(allocator)});
}
