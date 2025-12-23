const std = @import("std");
const input = @embedFile("inputs/7");

const GridValue = enum { tachyon, empty, splitter };

const ParseError = error{ InvalidCharacter, InvalidFileInput };

fn allocParseLine(a: std.mem.Allocator, line: []const u8) ![]GridValue {
    const parsed: []GridValue = try a.alloc(GridValue, line.len);
    errdefer a.free(parsed);

    for (line, 0..) |char, i| {
        parsed[i] = switch (char) {
            '|', 'S' => .tachyon,
            '.' => .empty,
            '^' => .splitter,
            else => return error.InvalidCharacter,
        };
    }

    return parsed;
}

fn allocParseGrid(a: std.mem.Allocator, data: []const u8) ![][]GridValue {
    var rows = std.ArrayList([]GridValue).empty;
    errdefer rows.deinit(a);

    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    while (lines.next()) |line| {
        const parsedRow = try allocParseLine(a, line);
        errdefer a.free(parsedRow);

        try rows.append(a, parsedRow);
    }

    return rows.toOwnedSlice(a);
}

const Grid = struct {
    a: std.mem.Allocator,
    data: [][]GridValue,
    rows: usize,
    cols: usize,

    fn init(a: std.mem.Allocator, data: []const u8) !Grid {
        const parsedGrid = try allocParseGrid(a, data);
        return .{ .a = a, .data = parsedGrid, .cols = parsedGrid[0].len, .rows = parsedGrid.len };
    }

    fn evolve(self: *Grid, row: usize) void {
        const previousRow = self.data[row - 1];
        var currentRow = self.data[row];
        for (previousRow, 0..) |previousValue, i| {
            const currentValue = currentRow[i];
            // we only have to do work if the value above is a tachyon; otherwise, we just keep whatever the current value is intact
            if (previousValue != .tachyon) continue;

            // tachyons continue downward unless they meet a splitter
            if (currentValue != .splitter) {
                currentRow[i] = .tachyon;
            } else {
                // keep splitter in place, split tachyon to the left and right of it. this can safely overwrite already-set tachyon fields,
                // but we do need boundary checks to make sure we stay within the column width.
                if (i > 0) {
                    currentRow[i - 1] = .tachyon;
                }
                if (i < currentRow.len - 1) {
                    currentRow[i + 1] = .tachyon;
                }
            }
        }
    }

    fn deinit(self: *Grid) void {
        for (self.data) |row| {
            self.a.free(row);
        }
        self.a.free(self.data);
    }
};

fn partOne(a: std.mem.Allocator) !usize {
    var grid = try Grid.init(a, input);
    defer grid.deinit();
    for (1..grid.rows) |i| {
        grid.evolve(i);
    }

    var splits: usize = 0;
    // number of tachyon splits = splitters with tachyon above them
    for (1..grid.rows) |i| {
        for (grid.data[i], 0..) |row, j| {
            if (row != .splitter) continue;
            const above = grid.data[i - 1][j];
            if (above == .tachyon) splits += 1;
        }
    }

    return splits;
}

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();

    const allocator = da.allocator();
    std.debug.print("day 7, part 1: {}\n", .{try partOne(allocator)});
}
