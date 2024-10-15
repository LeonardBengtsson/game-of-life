const std = @import("std");

const Size = @import("game_of_life.zig").Size;

var rand: ?std.Random = null;

pub fn initRandom() !void {
    rand = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    }).random();
}

pub fn allDead(_: Size, _: Size, _: Size) bool {
    return false;
}

pub fn allAlive(_: Size, _: Size, _: Size) bool {
    return true;
}

pub fn checkerboard(sx: Size, _: Size, i: Size) bool {
    return i % 2 == (i / sx) % 2;
}

pub fn stripes(sx: Size, _: Size, i: Size) bool {
    return (i % sx) % 2 == 0;
}

pub fn random(_: Size, _: Size, _: Size) bool {
    return if (rand) |r| r.boolean() else false;
}
