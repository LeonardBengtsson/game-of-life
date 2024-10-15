const Allocator = @import("std").mem.Allocator;

pub const Size = u16;
const Epoch = u32;

const BoardError = error{ GetCell, SetCell };

const Cell = struct {
    alive: bool,
    neighbours: u8,
};

pub const Game = struct {
    allocator: Allocator,
    sx: Size,
    sy: Size,
    board: []Cell,
    epoch: Epoch,

    pub fn create(allocator: Allocator, sx: Size, sy: Size, init_pattern: fn (sx: Size, sy: Size, i: Size) bool) !Game {
        const board = try allocator.alloc(Cell, sx * sy);
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

    pub fn determineNeighbors(self: *Game, x: Size, y: Size) BoardError!u8 {
        if (x >= self.sx or y >= self.sy) return BoardError.GetCell;

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
            const x: Size = @intCast(x_usize);
            for (0..self.sy) |y_usize| {
                const y: Size = @intCast(y_usize);

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

    pub fn getCell(self: *Game, x: Size, y: Size) BoardError!bool {
        if ((x >= self.sx) or (y >= self.sy)) return BoardError.GetCell;
        return self.board[x + self.sx * y].alive;
    }

    pub fn setCell(self: *Game, x: Size, y: Size, toggle: bool) BoardError!void {
        if ((x >= self.sx) or (y >= self.sy)) return BoardError.SetCell;
        self.board[x + self.sx * y].alive = toggle;
    }

    fn isAlive(self: Game, pos: Size) BoardError!u8 {
        if (pos >= self.sx * self.sy) return BoardError.GetCell;
        return if (self.board[pos].alive) 1 else 0;
    }
};
