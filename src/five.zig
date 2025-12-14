const std = @import("std");
const data = @embedFile("inputs/5");

const Range = struct {
    start: usize,
    end: usize,
    fn containsValue(self: Range, value: usize) bool {
        return value >= self.start and value <= self.end;
    }
    fn nValues(self: Range) usize {
        return self.end - self.start + 1;
    }
};

fn parseRanges(a: std.mem.Allocator, buf: []const u8) ![]Range {
    var ranges = std.ArrayList(Range).empty;
    errdefer ranges.deinit(a);

    var iter = std.mem.tokenizeScalar(u8, buf, '\n');
    while (iter.next()) |range| {
        var split = std.mem.splitScalar(u8, range, '-');
        const start = split.next() orelse unreachable;
        const end = split.next() orelse unreachable;
        const r: Range = .{ .start = try std.fmt.parseInt(usize, start, 10), .end = try std.fmt.parseInt(usize, end, 10) };
        try ranges.append(a, r);
    }

    return ranges.toOwnedSlice(a);
}

fn mergeRanges(a: std.mem.Allocator, ranges: []const Range) ![]Range {
    if (ranges.len == 0) return &[_]Range{};

    const copied = try a.dupe(Range, ranges);
    defer a.free(copied);

    std.mem.sort(Range, copied, {}, struct {
        fn lessThan(_: void, left: Range, right: Range) bool {
            return left.start < right.start;
        }
    }.lessThan);

    var merged = try std.ArrayList(Range).initCapacity(a, ranges.len);
    errdefer merged.deinit(a);
    try merged.append(a, copied[0]);
    for (copied[1..]) |range| {
        var prev = &merged.items[merged.items.len - 1];
        if (range.start <= prev.end + 1) {
            prev.end = @max(prev.end, range.end);
        } else {
            try merged.append(a, range);
        }
    }

    return merged.toOwnedSlice(a);
}

fn partOne(a: std.mem.Allocator) !usize {
    var split = std.mem.tokenizeSequence(u8, data, "\n\n");
    const rangeBuf = split.next() orelse unreachable;
    const ingredientsBuf = split.next() orelse unreachable;

    const parsedRanges = try parseRanges(a, rangeBuf);
    defer a.free(parsedRanges);

    var accumulator: usize = 0;
    var ingredientsIter = std.mem.tokenizeScalar(u8, ingredientsBuf, '\n');
    while (ingredientsIter.next()) |ingredient| {
        const parsed = try std.fmt.parseInt(usize, ingredient, 10);
        for (parsedRanges) |range| {
            if (range.containsValue(parsed)) {
                accumulator += 1;
                break;
            }
        }
    }

    return accumulator;
}

fn partTwo(a: std.mem.Allocator) !usize {
    var split = std.mem.tokenizeSequence(u8, data, "\n\n");
    const rangeBuf = split.next() orelse unreachable;
    const parsedRanges = try parseRanges(a, rangeBuf);
    defer a.free(parsedRanges);
    const mergedRanges = try mergeRanges(a, parsedRanges);
    defer a.free(mergedRanges);

    var accumulator: usize = 0;
    for (mergedRanges) |range| {
        accumulator += range.nValues();
    }

    return accumulator;
}
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();

    std.debug.print("day 5, part 1: {}\n", .{try partOne(da.allocator())});
    std.debug.print("day 5, part 2: {}\n", .{try partTwo(da.allocator())});
}
