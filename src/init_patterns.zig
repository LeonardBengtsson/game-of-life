const Size = @import("game_of_life.zig").Size;

pub fn all_dead(_: Size, _: Size, _: Size) bool {
    return false;
}

pub fn all_alive(_: Size, _: Size, _: Size) bool {
    return true;
}

pub fn checkerboard(sx: Size, _: Size, i: Size) bool {
    return i % 2 == (i / sx) % 2;
}
