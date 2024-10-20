const std = @import("std");

const ncurses = @import("ncurses.zig");
const render = @import("render.zig");
const init_patterns = @import("init_patterns.zig");

const Allocator = std.mem.Allocator;

const Vec2 = @import("util.zig").Vec2;
const Region = @import("Region.zig");
const Game = @import("game_of_life.zig").Game;

const c = @cImport({
    @cInclude("ncurses.h");
});

const VERSION = "0.0.4";

const ALIVE_CELL_CHAR = 0x25ca;
const DEAD_CELL_CHAR = ' ';

const DEFAULT_FPS = 30;
const DEFAULT_DELAY = 10 * std.time.ns_per_ms;
const BLINKING_PERIOD_MS = 1000;
const BLINKING_DURATION_MS = 700;

const WRAP_CURSOR_MOVEMENT = true;

const CursorMode = union(enum) {
    normal: void,
    select: Vec2,
    paste: Region,
};

pub const GameContainer = struct {
    allocator: *const Allocator,

    game: *Game,
    delay_ns: u64 = DEFAULT_DELAY,
    running: bool = true,
    paused: bool = true,

    cursor_pos: Vec2 = Vec2{ .x = 0, .y = 0 },
    cursor_mode: CursorMode = CursorMode.normal,
    cursor_visible: bool = true,
    camera_pos: Vec2 = Vec2{ .x = 0, .y = 0 },

    screen_fps: u32 = DEFAULT_FPS,
    screen_w: u32 = 0,
    screen_h: u32 = 0,

    fn inputLoop(self: *GameContainer) !void {
        while (self.running) {
            self.screen_w = ncurses.getWidth();
            self.screen_h = ncurses.getHeight() - 1;

            const input = try ncurses.getInput();
            switch (input) {
                'Q' => {
                    return;
                },
                'D' => {
                    self.game.reset(init_patterns.allDead);
                },
                'R' => {
                    self.game.reset(init_patterns.random);
                },
                'w' => self.game.cycle(),
                'p' => try self.togglePaused(!self.paused),
                ' ' => {
                    if (self.cursor_mode == .normal) {
                        self.cursor_mode = .{ .select = self.cursor_pos };
                    }
                },
                'q' => {
                    if (self.cursor_mode == .select) {
                        self.cursor_mode = .normal;
                    } else if (self.cursor_mode == .paste) {
                        self.cursor_mode.paste.free(self.allocator);
                        self.cursor_mode = .normal;
                    }
                },
                't' => {
                    if (self.cursor_mode == .normal) {
                        const cell = try self.game.getCell(self.cursor_pos.x, self.cursor_pos.y);
                        try self.game.setCell(self.cursor_pos.x, self.cursor_pos.y, !cell);
                        try self.togglePaused(true);
                    } else if (self.cursor_mode == .select) {
                        try self.game.toggleSubRegion(self.cursor_mode.select, self.cursor_pos);
                        self.cursor_mode = .normal;
                    }
                },
                'f' => {
                    if (self.cursor_mode == .select) {
                        try self.game.fillSubRegion(self.cursor_mode.select, self.cursor_pos, true);
                        self.cursor_mode = .normal;
                    }
                },
                'd' => {
                    if (self.cursor_mode == .select) {
                        try self.game.fillSubRegion(self.cursor_mode.select, self.cursor_pos, false);
                        self.cursor_mode = .normal;
                    }
                },
                'c' => {
                    if (self.cursor_mode == .select) {
                        const pos = self.cursor_mode.select;
                        const region = try self.game.getSubRegion(self.allocator, self.cursor_mode.select, self.cursor_pos);
                        self.cursor_mode = .{ .paste = region };
                        self.cursor_pos = Vec2{ .x = @min(pos.x, self.cursor_pos.x), .y = @min(pos.y, self.cursor_pos.y) };
                    }
                },
                'x' => {
                    if (self.cursor_mode == .select) {
                        const pos = self.cursor_mode.select;
                        const region = try self.game.getSubRegion(self.allocator, self.cursor_mode.select, self.cursor_pos);
                        self.cursor_mode = .{ .paste = region };
                        try self.game.fillSubRegion(pos, self.cursor_pos, false);
                        self.cursor_pos = Vec2{ .x = @min(pos.x, self.cursor_pos.x), .y = @min(pos.y, self.cursor_pos.y) };
                    }
                },
                'o' => {
                    if (self.cursor_mode == .select) {
                        const pos = self.cursor_mode.select;
                        self.cursor_mode = .{ .select = self.cursor_pos };
                        self.cursor_pos = pos;
                    }
                },
                'v' => {
                    if (self.cursor_mode == .paste) {
                        try self.game.setSubRegion(self.cursor_pos, &self.cursor_mode.paste);
                        self.cursor_mode.paste.free(self.allocator);
                        self.cursor_mode = .normal;
                    }
                },
                '=' => {
                    try render.clearScreen();
                },
                ncurses.KEY_UP, 'k' => try self.moveCursor(0, -1, WRAP_CURSOR_MOVEMENT),
                ncurses.KEY_DOWN, 'j' => try self.moveCursor(0, 1, WRAP_CURSOR_MOVEMENT),
                ncurses.KEY_LEFT, 'h' => try self.moveCursor(-1, 0, WRAP_CURSOR_MOVEMENT),
                ncurses.KEY_RIGHT, 'l' => try self.moveCursor(1, 0, WRAP_CURSOR_MOVEMENT),
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
        try ncurses.colorPairOn(0);
        for (0..self.screen_w) |x_usize| {
            const x: u16 = @intCast(x_usize);
            for (0..self.screen_h) |y_usize| {
                const y: u16 = @intCast(y_usize);
                const cell: bool = self.game.getCell(x, y) catch continue;
                const char: u16 = if (cell) ALIVE_CELL_CHAR else DEAD_CELL_CHAR;
                try ncurses.setCharacterAt(x, y, char);
            }
        }
        try ncurses.colorPairOff(0);

        const blink = @mod(std.time.milliTimestamp(), BLINKING_PERIOD_MS) < BLINKING_DURATION_MS;
        if (blink) {
            switch (self.cursor_mode) {
                .select => {
                    const x1 = @min(self.cursor_mode.select.x, self.cursor_pos.x);
                    const y1 = @min(self.cursor_mode.select.y, self.cursor_pos.y);
                    const x2 = @max(self.cursor_mode.select.x, self.cursor_pos.x);
                    const y2 = @max(self.cursor_mode.select.y, self.cursor_pos.y);
                    try render.roundedBox(@truncate(x1), @truncate(y1), @truncate(x2), @truncate(y2), 2);
                },
                .paste => {
                    const x1 = self.cursor_pos.x;
                    const y1 = self.cursor_pos.y;
                    const x2 = self.cursor_pos.x + self.cursor_mode.paste.sx - 1;
                    const y2 = self.cursor_pos.y + self.cursor_mode.paste.sy - 1;
                    try ncurses.colorPairOn(3);
                    for (x1..x2) |x_usize| {
                        const x: u16 = @intCast(x_usize);
                        for (y1..y2) |y_usize| {
                            const y: u16 = @intCast(y_usize);
                            const cell = try self.cursor_mode.paste.getCell(x - x1, y - y1);
                            const char: u16 = if (cell) ALIVE_CELL_CHAR else DEAD_CELL_CHAR;
                            try ncurses.setCharacterAt(@truncate(x), @truncate(y), char);
                        }
                    }
                    try ncurses.colorPairOff(3);
                    try render.roundedBox(@truncate(x1), @truncate(y1), @truncate(x2), @truncate(y2), 3);
                },
                else => {},
            }
        }

        var utf8Buffer: [200]u8 = [_]u8{' '} ** 200;
        _ = try std.fmt.bufPrint(&utf8Buffer, "Game of Life v{s} [{}x{}] | (Q)uit | (t)oggle | (p)ause | (w) step | ( ) select | Current Epoch: {}", .{ VERSION, self.screen_w, self.screen_h, self.game.epoch });
        var utf16Buffer: [200]u16 = [_]u16{' '} ** 200;
        _ = try std.unicode.utf8ToUtf16Le(&utf16Buffer, &utf8Buffer);
        try render.textLine(ncurses.getHeight() - 1, &utf16Buffer, 1);

        try ncurses.moveCursor(@truncate(self.cursor_pos.x), @truncate(self.cursor_pos.y));
        try ncurses.refreshScreen();
    }

    fn togglePaused(self: *GameContainer, toggle: bool) !void {
        self.paused = toggle;
        try self.toggleCursor(toggle);
    }

    fn toggleCursor(self: *GameContainer, toggle: bool) !void {
        self.cursor_visible = toggle;
        const style = if (toggle) ncurses.CursorStyle.normal else ncurses.CursorStyle.invisible;
        try ncurses.setCursorStyle(style);
    }

    fn moveCursor(self: *GameContainer, dx: i16, dy: i16, wrap: bool) !void {
        try self.toggleCursor(true);
        self.paused = true;

        var temp_x: i16 = @as(i16, @intCast(self.cursor_pos.x)) + dx;
        var temp_y: i16 = @as(i16, @intCast(self.cursor_pos.y)) + dy;
        if (wrap) {
            self.cursor_pos.x = @intCast(@mod(temp_x, @as(i16, @intCast(self.screen_w))));
            self.cursor_pos.y = @intCast(@mod(temp_y, @as(i16, @intCast(self.screen_h))));
        } else {
            if (temp_x < 0) temp_x = 0;
            if (temp_y < 0) temp_y = 0;
            self.cursor_pos.x = @min(self.screen_w - 1, @as(u16, @intCast(temp_x)));
            self.cursor_pos.y = @min(self.screen_h - 1, @as(u16, @intCast(temp_y)));
        }
    }
};

pub fn start(game: *Game, allocator: *const Allocator) !void {
    var container = GameContainer{ .game = game, .allocator = allocator };

    var game_thread = try std.Thread.spawn(.{}, GameContainer.gameLoop, .{&container});
    defer {
        container.running = false;
        game_thread.join();
    }

    try container.inputLoop();
}
