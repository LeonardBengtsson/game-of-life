const c = @cImport({
    @cDefine("_XOPEN_SOURCE 700", {});
    @cDefine("_XOPEN_SOURCE_EXTENDED", {});
    @cInclude("locale.h");
    @cInclude("ncurses.h");
});

pub const NCursesError = error{ Initialize, Deinitialize, ReadInput, SetCharacter, StateChange, RefreshScreen, Color };

pub const KEY_UP = c.KEY_UP;
pub const KEY_DOWN = c.KEY_DOWN;
pub const KEY_LEFT = c.KEY_LEFT;
pub const KEY_RIGHT = c.KEY_RIGHT;

pub const CursorStyle = enum(c_int) { invisible = 0, normal = 1, high_visibility = 2 };

pub const Color = enum(c_short) {
    default = -1,
    black = c.COLOR_BLACK,
    red = c.COLOR_RED,
    green = c.COLOR_GREEN,
    yellow = c.COLOR_YELLOW,
    blue = c.COLOR_BLUE,
    magenta = c.COLOR_MAGENTA,
    cyan = c.COLOR_CYAN,
    white = c.COLOR_WHITE,
    bright_black = 8,
    bright_red = 9,
    bright_green = 10,
    bright_yellow = 11,
    bright_blue = 12,
    bright_magenta = 13,
    bright_cyan = 14,
    bright_white = 15,
};

pub fn init() NCursesError!void {
    _ = c.setlocale(c.LC_ALL, "");
    _ = c.initscr();
    if (c.raw() != 0) return NCursesError.Initialize;
    if (c.keypad(c.stdscr, true) != 0) return NCursesError.Initialize;
    if (c.noecho() != 0) return NCursesError.Initialize;
    if (c.start_color() != 0) return NCursesError.Initialize;
    if (c.use_default_colors() != 0) return NCursesError.Initialize;
}

pub fn deinit() void {
    _ = c.endwin();
}

pub fn getInput() NCursesError!c_uint {
    const in = c.getch();
    return if (in >= 0 and in != c.ERR) @intCast(in) else NCursesError.ReadInput;
}

pub fn getDimensions() struct { u16, u16 } {
    return .{ @intCast(c.getmaxx(c.stdscr)), @intCast(c.getmaxy(c.stdscr)) };
}

pub fn initColorPair(index: u16, foreground: Color, background: Color) NCursesError!void {
    var fg: c_short = @intFromEnum(foreground);
    var bg: c_short = @intFromEnum(background);
    if (c.COLORS <= fg) fg = @mod(fg, 8);
    if (c.COLORS <= bg) bg = @mod(bg, 8);
    const result = c.init_pair(@intCast(index), fg, bg);
    if (result == c.ERR) return NCursesError.Color;
}

pub fn colorPairOn(index: u16) NCursesError!void {
    const result = c.attron(c.COLOR_PAIR(@intCast(index)));
    if (result == c.ERR) return NCursesError.Color;
}

pub fn colorPairOff(index: u16) NCursesError!void {
    const result = c.attroff(c.COLOR_PAIR(@intCast(index)));
    if (result == c.ERR) return NCursesError.Color;
}

pub fn setCharacterAt(x: u16, y: u16, char: u16) NCursesError!void {
    _ = c.mvadd_wch(@intCast(y), @intCast(x), &c.cchar_t{
        .attr = 0,
        .chars = [5]c_int{ @intCast(char), 0x00, 0x00, 0x00, 0x00 },
    });
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
