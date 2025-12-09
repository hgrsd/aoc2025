const std = @import("std");
const data = @embedFile("inputs/1");

fn parse_move(from: []const u8) !i32 {
    const abs_parsed = try std.fmt.parseInt(i32, from[1..], 10);
    return if (from[0] == 'L') -abs_parsed else abs_parsed;
}

fn new_pos(cur: i32, move: i32) i32 {
    return @mod(cur + move, 100);
}

/// Version of new_pos that returns a tuple of position, zeroes touched during rotation
fn new_pos_v2(cur: i32, move: i32) struct { i32, u32 } {
    var zeroes: u32 = 0;
    var position = cur;
    const step: i32 = if (move < 0) -1 else 1;
    for (0..@abs(move)) |_| {
        position = new_pos(position, step);
        if (position == 0) zeroes += 1;
    }
    return .{ position, zeroes };
}

fn part_one() !i32 {
    var pos: i32 = 50;
    var zeroes: i32 = 0;
    var iterator = std.mem.tokenizeScalar(u8, data, '\n');
    while (iterator.next()) |line| {
        const move = try parse_move(line);
        pos = new_pos(pos, move);
        if (pos == 0) zeroes += 1;
    }
    return zeroes;
}

fn part_two() !u32 {
    var pos: i32 = 50;
    var zeroes: u32 = 0;
    var iterator = std.mem.tokenizeScalar(u8, data, '\n');
    while (iterator.next()) |line| {
        const move = try parse_move(line);
        const new, const z = new_pos_v2(pos, move);
        pos = new;
        zeroes += z;
    }
    return zeroes;
}

pub fn main() !void {
    std.debug.print("part 1: {d}\n", .{try part_one()});
    std.debug.print("part 2: {d}\n", .{try part_two()});
}

test "50 L68 = 82" {
    try std.testing.expect(new_pos(50, -68) == 82);
}

test "82 L30 = 52" {
    try std.testing.expect(new_pos(82, -30) == 52);
}

test "52 R48 = 0" {
    try std.testing.expect(new_pos(52, 48) == 0);
}

test "55 L55 = 0" {
    try std.testing.expect(new_pos(55, -55) == 0);
}

test "parse L68 = -68" {
    try std.testing.expect(try parse_move("L68") == -68);
}

test "parse R48 = 48" {
    try std.testing.expect(try parse_move("R48") == 48);
}
