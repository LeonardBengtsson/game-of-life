const Allocator = @import("std").mem.Allocator;

pub const Size = u16;
const Epoch = u32;

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

    pub fn create(allocator: Allocator, sx: Size, sy: Size) !Game {
        const board = try allocator.alloc(Cell, sx * sy);
        return Game{
            .allocator = allocator,
            .sx = sx,
            .sy = sy,
            .board = board,
            .epoch = 0,
        };
    }

    pub fn deinit(self: Game) void {
        self.allocator.free(self.board);
    }

    pub fn cycle(self: Game) void {
        const size = self.sx * self.sy;
        for (0..self.sx) |x| {
            for (0..self.sy) |y| {
                const pos = x + self.sx * y;
                var neighbors = 0;
                neighbors += self.isAlive((pos + size - self.sx) % size) catch unreachable;
                neighbors += self.isAlive((pos + self.sx) % size) catch unreachable;
                if (x == 0) {
                    neighbors += self.isAlive((pos + size - 1) % size) catch unreachable;
                    neighbors += self.isAlive((pos + self.sx - 1) % size) catch unreachable;
                    neighbors += self.isAlive((pos + 2 * self.sx - 1) % size) catch unreachable;
                } else {
                    neighbors += self.isAlive((pos + size - self.sx - 1) % size) catch unreachable;
                    neighbors += self.isAlive(pos - 1) catch unreachable;
                    neighbors += self.isAlive((pos + self.sx - 1) % size) catch unreachable;
                }
                if (x == self.sx - 1) {
                    neighbors += self.isAlive((pos + size - 2 * self.sx + 1) % size) catch unreachable;
                    neighbors += self.isAlive((pos + size - self.sx + 1) % size) catch unreachable;
                    neighbors += self.isAlive((pos + 1) % size) catch unreachable;
                } else {
                    neighbors += self.isAlive((pos + size + self.sx - 1) % size) catch unreachable;
                    neighbors += self.isAlive(pos + 1) catch unreachable;
                    neighbors += self.isAlive((pos + self.sx + 1) % size) catch unreachable;
                }
                self.board[pos].neighbours = neighbors;
            }
        }
        for (self.board) |cell| {
            if (cell.alive) {
                cell.alive = cell.neighbours == 2 || (cell.neighbours == 3);
            } else {
                cell.alive = cell.neighbours == 3;
            }
        }
        self.epoch += 1;
    }

    fn isAlive(self: Game, pos: Size) !u8 {
        if (pos >= self.sx * self.sy) return error{};
        return if (self.board[pos].alive) 1 else 0;
    }
};
