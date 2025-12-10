const std = @import("std");
const data = std.mem.trim(u8, @embedFile("inputs/2"), "\r\t\n");

fn parseRange(from: []const u8) !struct { usize, usize } {
    var iter = std.mem.splitScalar(u8, from, '-');
    const start = iter.next().?;
    const end = iter.next().?;
    return .{ try std.fmt.parseInt(usize, start, 10), try std.fmt.parseInt(usize, end, 10) };
}

fn isValid(number: usize) !bool {
    var buf: [32]u8 = undefined;
    const stringified = try std.fmt.bufPrint(&buf, "{}", .{number});

    if (@mod(stringified.len, 2) != 0) return true;
    const midpoint = stringified.len / 2;
    return !std.mem.eql(u8, stringified[0..midpoint], stringified[midpoint..]);
}

fn isValidTheSecond(number: usize) !bool {
    var buf: [32]u8 = undefined;
    const stringified = try std.fmt.bufPrint(&buf, "{}", .{number});
    for (2..stringified.len + 1) |nChunks| {
        if (stringified.len % nChunks != 0) continue;
        const chunkSize = stringified.len / nChunks;
        var windows = std.mem.window(u8, stringified, chunkSize, chunkSize);
        const firstChunk = windows.next().?;
        var allMatch = true;
        while (windows.next()) |chunk| {
            if (!std.mem.eql(u8, firstChunk, chunk)) {
                allMatch = false;
                break;
            }
        }
        if (allMatch) return false;
    }
    return true;
}

fn sumInvalidNumbers(start: usize, end: usize, isValidFn: anytype) !usize {
    var acc: usize = 0;
    for (start..end + 1) |n| {
        if (!try isValidFn(n)) {
            acc += n;
        }
    }
    return acc;
}

fn solve(isValidFn: anytype) !usize {
    var iter = std.mem.tokenizeScalar(u8, data, ',');
    var acc: usize = 0;
    while (iter.next()) |range| {
        const start, const end = try parseRange(range);
        acc += try sumInvalidNumbers(start, end, isValidFn);
    }

    return acc;
}

pub fn main() !void {
    std.debug.print("part 1: {}\n", .{try solve(isValid)});
    std.debug.print("part 2: {}\n", .{try solve(isValidTheSecond)});
}
