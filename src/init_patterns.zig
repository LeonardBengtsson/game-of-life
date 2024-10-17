const std = @import("std");

var prng = std.Random.DefaultPrng.init(1625953);
const rand = prng.random();

pub fn allDead(_: u32, _: u32, _: u32) bool {
    return false;
}

pub fn allAlive(_: u32, _: u32, _: u32) bool {
    return true;
}

pub fn checkerboard(sx: u32, _: u32, i: u32) bool {
    return i % 2 == (i / sx) % 2;
}

pub fn stripes(sx: u32, _: u32, i: u32) bool {
    return (i % sx) % 2 == 0;
}

pub fn random(_: u32, _: u32, _: u32) bool {
    return rand.boolean();
}

pub fn gliderGrid(sx: u32, sy: u32, i: u32) bool {
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
