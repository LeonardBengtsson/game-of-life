const Allocator = @import("std").mem.Allocator;
const Region = @import("Region.zig");
const Vec2 = @import("util.zig").Vec2;

const Error = error{ GetCell, SetCell };

const Cell = struct {
    alive: bool,
    neighbours: u8,
};

pub const Game = struct {
    allocator: *const Allocator,
    sx: u32,
    sy: u32,
    board: []Cell,
    epoch: u32,

    pub fn create(allocator: *const Allocator, sx: u32, sy: u32, init_pattern: fn (sx: u32, sy: u32, i: u32) bool) !Game {
        const board = try allocator.*.alloc(Cell, sx * sy);
        for (board, 0..) |*cell, i| {
            cell.alive = init_pattern(sx, sy, @intCast(i));
            cell.neighbours = 0;
        }
        return Game{
            .allocator = allocator,
            .sx = sx,
            .sy = sy,
            .board = board,
            .epoch = 0,
        };
    }

    pub fn deinit(self: *Game) void {
        self.allocator.free(self.board);
    }

    pub fn reset(self: *Game, init_pattern: fn (sx: u32, sy: u32, i: u32) bool) void {
        for (self.board, 0..) |*cell, i| {
            cell.alive = init_pattern(self.sx, self.sy, @intCast(i));
            cell.neighbours = 0;
        }
    }

    pub fn determineNeighbors(self: *Game, x: u32, y: u32) Error!u8 {
        if (x >= self.sx or y >= self.sy) return Error.GetCell;

        var neighbors: u8 = 0;
        if (try self.getCell((x + self.sx - 1) % self.sx, (y + self.sy - 1) % self.sy)) neighbors += 1;
        if (try self.getCell((x + self.sx - 1) % self.sx, y)) neighbors += 1;
        if (try self.getCell((x + self.sx - 1) % self.sx, (y + 1) % self.sy)) neighbors += 1;
        if (try self.getCell(x, (y + self.sy - 1) % self.sy)) neighbors += 1;
        if (try self.getCell(x, (y + 1) % self.sy)) neighbors += 1;
        if (try self.getCell((x + 1) % self.sx, (y + self.sy - 1) % self.sy)) neighbors += 1;
        if (try self.getCell((x + 1) % self.sx, y)) neighbors += 1;
        if (try self.getCell((x + 1) % self.sx, (y + 1) % self.sy)) neighbors += 1;
        return neighbors;
    }

    pub fn cycle(self: *Game) void {
        for (0..self.sx) |x_usize| {
            const x: u32 = @intCast(x_usize);
            for (0..self.sy) |y_usize| {
                const y: u32 = @intCast(y_usize);

                const pos = x + self.sx * y;
                self.board[pos].neighbours = self.determineNeighbors(x, y) catch unreachable;
            }
        }
        for (self.board) |*cell| {
            if (cell.alive) {
                cell.alive = cell.neighbours == 2 or cell.neighbours == 3;
            } else {
                cell.alive = cell.neighbours == 3;
            }
        }
        self.epoch += 1;
    }

    pub fn getCell(self: *Game, x: u32, y: u32) Error!bool {
        if ((x >= self.sx) or (y >= self.sy)) return Error.GetCell;
        return self.board[x + self.sx * y].alive;
    }

    pub fn setCell(self: *Game, x: u32, y: u32, toggle: bool) Error!void {
        if ((x >= self.sx) or (y >= self.sy)) return Error.SetCell;
        self.board[x + self.sx * y].alive = toggle;
    }

    pub fn getSubRegion(self: *Game, allocator: *const Allocator, from: Vec2, to: Vec2) !Region {
        const x1 = @min(from.x, to.x);
        const y1 = @min(from.y, to.y);
        const x2 = @max(from.x, to.x);
        const y2 = @max(from.y, to.y);
        const sx = x2 - x1 + 1;
        const sy = y2 - y1 + 1;

        const data = try allocator.alloc(bool, sx * sy);
        for (0..sx) |x_usize| {
            const x: u32 = @intCast(x_usize);
            for (0..sy) |y_usize| {
                const y: u32 = @intCast(y_usize);
                data[x + sx * y] = try self.getCell(x1 + x, y1 + y);
            }
        }
        return Region{ .sx = sx, .sy = sy, .data = data };
    }

    pub fn setSubRegion(self: *Game, pos: Vec2, region: *const Region) !void {
        if (pos.x + region.sx > self.sx or pos.y + region.sy > self.sy) return Error.SetCell;
        for (0..region.sx) |x_usize| {
            const x: u32 = @as(u32, @intCast(x_usize));
            for (0..region.sy) |y_usize| {
                const y: u32 = @as(u32, @intCast(y_usize));
                try self.setCell(pos.x + x, pos.y + y, try region.getCell(x, y));
            }
        }
    }

    pub fn fillSubRegion(self: *Game, from: Vec2, to: Vec2, toggle: bool) !void {
        const x1 = @min(from.x, to.x);
        const y1 = @min(from.y, to.y);
        const x2 = @max(from.x, to.x);
        const y2 = @max(from.y, to.y);
        const sx = x2 - x1 + 1;
        const sy = y2 - y1 + 1;

        for (0..sx) |x_usize| {
            const x: u32 = x1 + @as(u32, @intCast(x_usize));
            for (0..sy) |y_usize| {
                const y: u32 = y1 + @as(u32, @intCast(y_usize));
                try self.setCell(x, y, toggle);
            }
        }
    }

    pub fn toggleSubRegion(self: *Game, from: Vec2, to: Vec2) !void {
        const x1 = @min(from.x, to.x);
        const y1 = @min(from.y, to.y);
        const x2 = @max(from.x, to.x);
        const y2 = @max(from.y, to.y);
        const sx = x2 - x1 + 1;
        const sy = y2 - y1 + 1;

        for (0..sx) |x_usize| {
            const x: u32 = x1 + @as(u32, @intCast(x_usize));
            for (0..sy) |y_usize| {
                const y: u32 = y1 + @as(u32, @intCast(y_usize));
                try self.setCell(x, y, !(try self.getCell(x, y)));
            }
        }
    }
};
