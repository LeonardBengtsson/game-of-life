const std = @import("std");

const game_container = @import("game_container.zig");
const Game = @import("game_of_life.zig").Game;
const ncurses = @import("ncurses.zig");
const init_patterns = @import("init_patterns.zig");

const INIT_PATTERN = init_patterns.allDead;

pub fn main() !void {
    try ncurses.init();
    defer ncurses.deinit();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var game = try Game.create(&allocator, ncurses.getWidth(), ncurses.getHeight(), INIT_PATTERN);
    defer game.deinit();

    // default
    try ncurses.initColorPair(0, .default, .default);
    // info line
    try ncurses.initColorPair(1, .black, .bright_white);
    // selection
    try ncurses.initColorPair(2, .blue, .default);
    // pasting
    try ncurses.initColorPair(3, .red, .default);

    try game_container.start(&game, &allocator);
}
