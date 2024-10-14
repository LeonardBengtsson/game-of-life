const std = @import("std");

const Game = @import("game_of_life.zig").Game;
const ncurses = @import("ncurses.zig");

const c = @cImport({
    @cInclude("ncurses.h");
});

pub fn main() !void {
    // const stdout = std.io.getStdOut().writer();

    try ncurses.init();
    defer ncurses.deinit();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const dims = ncurses.getDimensions();
    var game = try Game.create(allocator, @intCast(dims.@"0"), @intCast(dims.@"1"));
    defer game.deinit();

    ///////////////////////////

    const window = c.initscr();
    _ = window;
    const raw = c.raw();
    std.debug.print("{}", .{raw});
    const keypad = c.keypad(c.stdscr, true);
    std.debug.print("{}", .{keypad});
    const noecho = c.noecho();
    std.debug.print("{}", .{noecho});

    var ch: c_uint = 0;
    var x: i32 = 0;
    var y: i32 = 0;

    while (ch != 'q') {
        const input = c.getch();
        ch = if (input >= 0) @intCast(input) else break;
        switch (ch) {
            c.KEY_UP => y = if (y > 0) y - 1 else y,
            c.KEY_DOWN => y = if (y < c.LINES - 1) y + 1 else y,
            c.KEY_LEFT => x = if (x > 0) x - 1 else x,
            c.KEY_RIGHT => x = if (x < c.COLS - 1) x + 1 else x,
            else => {
                const err = c.mvaddch(y, x, ch);
                if (err != 0) break;
                x += 1;
                if (x >= c.COLS) {
                    x = 0;
                    y += 1;
                }
            },
        }
        _ = c.move(y, x);
        _ = c.refresh();
    }

    defer _ = c.endwin();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
