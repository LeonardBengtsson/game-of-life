const std = @import("std");

const game_container = @import("game_container.zig");
const Game = @import("game_of_life.zig").Game;
const ncurses = @import("ncurses.zig");
const init_patterns = @import("init_patterns.zig");

const c = @cImport({
    @cInclude("ncurses.h");
});

const INIT_PATTERN = init_patterns.allDead;

pub fn main() !void {
    try ncurses.init();
    defer ncurses.deinit();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const dims = ncurses.getDimensions();
    try init_patterns.initRandom();
    var game = try Game.create(allocator, @intCast(dims.@"0"), @intCast(dims.@"1"), INIT_PATTERN);
    defer game.deinit();

    try game_container.start(&game);
}
