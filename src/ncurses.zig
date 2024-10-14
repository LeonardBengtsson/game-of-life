const c = @cImport({
    @cInclude("ncurses.h");
});

pub const NCursesError = error{ Initialize, Deinitialize, ReadInput, SetCharacter, StateChange, RefreshScreen };

pub const KEY_UP = c.KEY_UP;
pub const KEY_DOWN = c.KEY_DOWN;
pub const KEY_LEFT = c.KEY_LEFT;
pub const KEY_RIGHT = c.KEY_RIGHT;

pub const CursorStyle = enum(c_int) { invisible = 0, normal = 1, high_visibility = 2 };

pub fn init() NCursesError!void {
    if (c.initscr() < 0) return NCursesError.Initialize;
    if (c.raw() != 0) return NCursesError.Initialize;
    if (c.keypad(c.stdscr, true) != 0) return NCursesError.Initialize;
    if (c.noecho() != 0) return NCursesError.Initialize;
}

pub fn deinit() void {
    _ = c.endwin();
}

pub fn getInput() NCursesError!c_uint {
    const in = c.getch();
    return if (in >= 0 and in != c.ERR) @intCast(in) else NCursesError.ReadInput;
}

pub fn getDimensions() struct { u16, u16 } {
    return .{ @intCast(c.COLS), @intCast(c.LINES) };
}

pub fn setCharacterAt(x: u16, y: u16, char: u8) NCursesError!void {
    _ = c.mvaddch(@intCast(y), @intCast(x), @intCast(char));
    // const result = c.mvaddch(@intCast(y), @intCast(x), @intCast(char));
    // if (result == c.ERR) return NCursesError.SetCharacter;
}

pub fn moveCursor(x: u16, y: u16) NCursesError!void {
    const result = c.move(@intCast(y), @intCast(x));
    if (result == c.ERR) return NCursesError.StateChange;
}

pub fn refreshScreen() NCursesError!void {
    const result = c.refresh();
    if (result == c.ERR) return NCursesError.RefreshScreen;
}

pub fn setCursorStyle(style: CursorStyle) NCursesError!void {
    const result = c.curs_set(@intFromEnum(style));
    if (result == c.ERR) return NCursesError.StateChange;
}
