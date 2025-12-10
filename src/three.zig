const std = @import("std");
const data = std.mem.trim(u8, @embedFile("inputs/3"), "\r\t\n");

const BUF_SIZE = 100;

fn highestPossibleNumber(nDigits: usize, buf: []u8, bank: []const u8) !usize {
    // fill our buffer with the joltages, with zeroes for unused indices
    for (0..bank.len) |i| {
        const num = try std.fmt.parseInt(u8, bank[i .. i + 1], 10);
        buf[i] = num;
    }

    var accumulator: usize = 0;
    var currentOffset: usize = 0;
    // count down from nDigits, where for every digit we find the highest next value in the bank
    // and add that to our accumulator, multiplied by 10^(n - 1) to shift it left in the number
    // we're constructing.
    var i: usize = nDigits;
    while (i > 0) : (i -= 1) {
        // we need to leave at least n-1 numbers for picking to ensure an n-digit number,
        // so we have to consider a slice that is curtailed at the start (by the current offset)
        // and the end (by leaving enough digits to complete the n-digit number we need).
        const idxInSlice = std.mem.indexOfMax(u8, buf[currentOffset .. bank.len - i + 1]);
        const idxInBuf = idxInSlice + currentOffset;
        const value = buf[idxInBuf];
        accumulator += value * try std.math.powi(usize, 10, i - 1);
        currentOffset = idxInBuf + 1;
    }
    return accumulator;
}

fn solve(nDigits: usize) !usize {
    var accumulator: usize = 0;
    var buf: [BUF_SIZE]u8 = undefined;

    var iter = std.mem.tokenizeScalar(u8, data, '\n');
    while (iter.next()) |bank| {
        // clear the buffer before we pass it
        buf = .{0} ** BUF_SIZE;
        const number = try highestPossibleNumber(nDigits, &buf, bank);
        accumulator += number;
    }

    return accumulator;
}
pub fn main() !void {
    std.debug.print("part 1: {}\n", .{try solve(2)});
    std.debug.print("part 2: {}\n", .{try solve(12)});
}

test "highest possible in 987654321111111 with n=2 == 98" {
    var buf: [BUF_SIZE]u8 = .{0} ** BUF_SIZE;
    try std.testing.expectEqual(98, try highestPossibleNumber(2, &buf, "987654321111111"));
}

test "highest possible in 818181911112111 with n=12 == 888911112111" {
    var buf: [BUF_SIZE]u8 = .{0} ** BUF_SIZE;
    try std.testing.expectEqual(888911112111, try highestPossibleNumber(12, &buf, "818181911112111"));
}
