const c = @cImport({
    @cInclude("ncurses.h");
});

pub const NCursesError = error{ Initialize, Deinitialize, ReadInput, SetCharacter };

pub fn init() NCursesError!void {
    if (c.initscr() < 0) return NCursesError.Initialize;
    if (c.raw() != 0) return NCursesError.Initialize;
    if (c.keypad(c.stdscr, true) != 0) return NCursesError.Initialize;
    if (c.noecho() != 0) return NCursesError.Initialize;
}

pub fn deinit() void {
    _ = c.endwin();
}

pub fn getInput() NCursesError!c_uint {}

pub fn getDimensions() struct { u16, u16 } {
    return .{ @intCast(c.COLS), @intCast(c.LINES) };
}
