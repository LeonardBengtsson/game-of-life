const std = @import("std");
const ncurses = @import("ncurses.zig");
const Game = @import("game_of_life.zig").Game;

const CELL_CHAR = '#';
const EMPTY_CHAR = '.';
const DEFAULT_FPS = 20;
const DEFAULT_DELAY = 5 * std.time.ns_per_ms;
const WRAP_CURSOR_MOVEMENT = true;

const GameContainer = struct {
    game: *Game,
    screen_fps: u32 = DEFAULT_FPS,
    running: bool = true,
    paused: bool = true,
    delay_ns: u64 = DEFAULT_DELAY,
    cursor: bool = true,
    cursor_x: u16 = 0,
    cursor_y: u16 = 0,
    screen_w: u16 = 0,
    screen_h: u16 = 0,

    fn inputLoop(self: *GameContainer) !void {
        while (self.running) {
            const dimensions = ncurses.getDimensions();
            self.screen_w = dimensions.@"0";
            self.screen_h = dimensions.@"1";

            const input = try ncurses.getInput();
            switch (input) {
                'q' => return,
                'x' => {
                    const cell = try self.game.getCell(@intCast(self.cursor_x), @intCast(self.cursor_y));
                    try self.game.setCell(@intCast(self.cursor_x), @intCast(self.cursor_y), !cell);
                    try self.togglePaused(true);
                },
                't' => self.game.cycle(),
                ' ' => try self.togglePaused(!self.paused),
                ncurses.KEY_UP, 'w', 'k' => try self.moveCursor(0, -1, WRAP_CURSOR_MOVEMENT),
                ncurses.KEY_DOWN, 's', 'j' => try self.moveCursor(0, 1, WRAP_CURSOR_MOVEMENT),
                ncurses.KEY_LEFT, 'a', 'h' => try self.moveCursor(-1, 0, WRAP_CURSOR_MOVEMENT),
                ncurses.KEY_RIGHT, 'd', 'l' => try self.moveCursor(1, 0, WRAP_CURSOR_MOVEMENT),
                else => {},
            }
        }
    }

    fn gameLoop(self: *GameContainer) !void {
        const screen_update_us: i64 = @intFromFloat(1_000_000.0 / @as(f32, @floatFromInt(self.screen_fps)));
        var last_update: i64 = std.time.microTimestamp();
        while (self.running) {
            const time: i64 = std.time.microTimestamp();
            if (time - last_update > screen_update_us) {
                try self.updateScreen();
                last_update += screen_update_us;
            }

            if (self.paused) {
                // wait for update
                std.Thread.sleep(std.time.ns_per_ms);
                continue;
            }

            self.game.cycle();

            if (self.delay_ns > 0) {
                std.Thread.sleep(self.delay_ns);
            }
        }
    }

    fn updateScreen(self: *GameContainer) !void {
        for (0..self.screen_w) |x_usize| {
            const x: u16 = @intCast(x_usize);
            for (0..self.screen_h) |y_usize| {
                const y: u16 = @intCast(y_usize);
                const cell: bool = self.game.getCell(x, y) catch continue;
                const char: u8 = if (cell) CELL_CHAR else EMPTY_CHAR;
                try ncurses.setCharacterAt(x, y, char);
            }
        }
        try ncurses.moveCursor(@intCast(self.cursor_x), @intCast(self.cursor_y));
        try ncurses.refreshScreen();
    }

    fn togglePaused(self: *GameContainer, toggle: bool) !void {
        self.paused = toggle;
        try self.toggleCursor(toggle);
    }

    fn toggleCursor(self: *GameContainer, toggle: bool) !void {
        self.cursor = toggle;
        const style = if (toggle) ncurses.CursorStyle.normal else ncurses.CursorStyle.invisible;
        try ncurses.setCursorStyle(style);
    }

    fn moveCursor(self: *GameContainer, dx: i16, dy: i16, wrap: bool) !void {
        try self.toggleCursor(true);
        self.paused = true;

        var temp_x: i16 = @as(i16, @intCast(self.cursor_x)) + dx;
        var temp_y: i16 = @as(i16, @intCast(self.cursor_y)) + dy;
        if (wrap) {
            self.cursor_x = @intCast(@mod(temp_x, @as(i16, @intCast(self.screen_w))));
            self.cursor_y = @intCast(@mod(temp_y, @as(i16, @intCast(self.screen_h))));
        } else {
            if (temp_x < 0) temp_x = 0;
            if (temp_y < 0) temp_y = 0;
            self.cursor_x = @min(self.screen_w - 1, @as(u16, @intCast(temp_x)));
            self.cursor_y = @min(self.screen_h - 1, @as(u16, @intCast(temp_y)));
        }
    }
};

pub fn start(game: *Game) !void {
    var container = GameContainer{ .game = game };

    var game_thread = try std.Thread.spawn(.{}, GameContainer.gameLoop, .{&container});
    defer {
        container.running = false;
        game_thread.join();
    }

    try container.inputLoop();
}
