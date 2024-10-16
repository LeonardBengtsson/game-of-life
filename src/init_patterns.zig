const std = @import("std");

const Size = @import("game_of_life.zig").Size;

var rand: ?std.Random = null;

pub fn initRandom() !void {
    var r = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    rand = r.random();
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

pub fn gliderGrid(sx: Size, sy: Size, i: Size) bool {
    const x = i % sx;
    const y = i / sx;
    if (x >= sx - @mod(sx, 5)) return false;
    if (y >= sy - @mod(sy, 5)) return false;
    const dx = @mod(x, 5);
    const dy = @mod(y, 5);
    if (dx == 0 and dy < 3) return true;
    if (dx == 1 and dy == 0) return true;
    if (dx == 2 and dy == 1) return true;
    return false;
}
