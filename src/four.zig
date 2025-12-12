const std = @import("std");
const data = @embedFile("inputs/4");

const CoordinateValue = enum { empty, paper };
const Coordinate = struct {
    row: usize,
    col: usize,
    value: CoordinateValue,

    fn neighbours(self: *const Coordinate, on: *const Grid) NeighbourIterator {
        return NeighbourIterator.init(on, self.row, self.col);
    }
};

const NeighbourIterator = struct {
    grid: *const Grid,
    row: usize,
    col: usize,
    directionIdx: usize = 0,

    const directions = [_][2]i32{
        .{ 0, -1 },
        .{ -1, -1 },
        .{ -1, 0 },
        .{ -1, 1 },
        .{ 0, 1 },
        .{ 1, 1 },
        .{ 1, 0 },
        .{ 1, -1 },
    };

    fn init(grid: *const Grid, row: usize, col: usize) NeighbourIterator {
        return .{ .grid = grid, .row = row, .col = col };
    }

    fn next(self: *NeighbourIterator) ?Coordinate {
        while (self.directionIdx < directions.len) {
            const rowOffset, const colOffset = directions[self.directionIdx];
            const newRow = @as(i32, @intCast(self.row)) + rowOffset;
            const newCol = @as(i32, @intCast(self.col)) + colOffset;
            self.directionIdx += 1;
            if (newRow < 0 or newCol < 0) {
                continue;
            }
            const value = self.grid.valueAt(@as(usize, @intCast(newRow)), @as(usize, @intCast(newCol)));
            if (value != null) {
                return value;
            }
        }
        return null;
    }
};

const Grid = struct {
    data: std.ArrayList(std.ArrayList(Coordinate)),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, fromData: []const u8) !Grid {
        var tokenized = std.mem.tokenizeScalar(u8, fromData, '\n');
        var rowCount: usize = 0;
        var grid = std.ArrayList(std.ArrayList(Coordinate)).empty;
        while (tokenized.next()) |row| {
            var r = try std.ArrayList(Coordinate).initCapacity(allocator, row.len);
            for (row, 0..) |char, i| {
                const value: CoordinateValue = switch (char) {
                    '@' => .paper,
                    '.' => .empty,
                    else => unreachable,
                };
                try r.append(allocator, .{ .row = rowCount, .col = @as(usize, @intCast(i)), .value = value });
            }
            rowCount += 1;
            try grid.append(allocator, r);
        }
        return .{ .data = grid, .allocator = allocator };
    }

    fn valueAt(self: *const Grid, row: usize, col: usize) ?Coordinate {
        if (row < 0 or col < 0 or row >= self.data.items.len) return null;
        const r = self.data.items[@as(usize, @intCast(row))];
        if (col >= r.items.len) return null;
        return r.items[@as(usize, @intCast(col))];
    }

    fn removePaperAt(self: *Grid, r: usize, c: usize) void {
        const row = &self.data.items[r];
        const new = [_]Coordinate{.{ .row = r, .col = c, .value = .empty }};
        row.replaceRangeAssumeCapacity(c, 1, &new);
    }

    fn iter(self: *const Grid) Gridterator {
        return Gridterator.init(self);
    }

    fn deinit(self: *Grid) void {
        for (self.data.items) |*row| {
            row.deinit(self.allocator);
        }
        self.data.deinit(self.allocator);
    }
};

const Gridterator = struct {
    grid: *const Grid,
    row: usize = 0,
    col: usize = 0,

    fn init(grid: *const Grid) Gridterator {
        return .{ .grid = grid };
    }

    fn next(self: *Gridterator) ?Coordinate {
        if (self.row == self.grid.data.items.len) {
            return null;
        }
        const currentRow = self.grid.data.items[self.row];
        if (self.col == currentRow.items.len) {
            self.col = 0;
            self.row += 1;
        }
        const value = self.grid.valueAt(self.row, self.col);
        self.col += 1;
        return value;
    }
};

fn part1(allocator: std.mem.Allocator) !u32 {
    var grid = try Grid.init(allocator, data);
    defer grid.deinit();

    var accessible: u32 = 0;
    var iter = grid.iter();
    while (iter.next()) |coordinate| {
        if (coordinate.value != .paper) continue;
        var rolls: u32 = 0;
        var neighbours = coordinate.neighbours(&grid);
        while (neighbours.next()) |neighbour| {
            if (neighbour.value == .paper) {
                rolls += 1;
            }
        }
        if (rolls < 4) {
            accessible += 1;
        }
    }
    return accessible;
}

fn part2(allocator: std.mem.Allocator) !u32 {
    var grid = try Grid.init(allocator, data);
    defer grid.deinit();

    var removed: u32 = 0;
    while (true) {
        var removable: usize = 0;
        var bufRemovable: [4096]Coordinate = undefined;
        var iter = grid.iter();
        while (iter.next()) |coordinate| {
            if (coordinate.value != .paper) continue;
            var rolls: u32 = 0;
            var neighbours = coordinate.neighbours(&grid);
            while (neighbours.next()) |neighbour| {
                if (neighbour.value == .paper) {
                    rolls += 1;
                }
            }
            if (rolls < 4) {
                bufRemovable[removable] = coordinate;
                removable += 1;
            }
        }
        if (removable == 0) {
            break;
        }
        for (0..removable) |i| {
            const coord = bufRemovable[i];
            grid.removePaperAt(coord.row, coord.col);
            removed += 1;
        }
    }
    return removed;
}

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const allocator = da.allocator();
    std.debug.print("day 4, part 1: {}\n", .{try part1(allocator)});
    std.debug.print("day 4, part 2: {}\n", .{try part2(allocator)});
}
