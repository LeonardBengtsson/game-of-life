const ncurses = @import("ncurses.zig");

pub fn roundedBox(x1: u16, y1: u16, x2: u16, y2: u16, colorPair: u16) !void {
    try ncurses.colorPairOn(colorPair);
    if (x2 - x1 > 0) {
        for (x1..(x2 + 1)) |x_usize| {
            const x: u16 = @intCast(x_usize);
            try ncurses.setCharacterAt(@truncate(x), @truncate(y1), 0x2500);
            try ncurses.setCharacterAt(@truncate(x), @truncate(y2), 0x2500);
        }
    }
    if (y2 - y1 > 0) {
        for (y1..(y2 + 1)) |y_usize| {
            const y: u16 = @intCast(y_usize);
            try ncurses.setCharacterAt(@truncate(x1), @truncate(y), 0x2502);
            try ncurses.setCharacterAt(@truncate(x2), @truncate(y), 0x2502);
        }
    }
    if (x2 - x1 > 0 and y2 - y1 > 0) {
        try ncurses.setCharacterAt(@truncate(x1), @truncate(y1), 0x256d);
        try ncurses.setCharacterAt(@truncate(x2), @truncate(y1), 0x256e);
        try ncurses.setCharacterAt(@truncate(x2), @truncate(y2), 0x256f);
        try ncurses.setCharacterAt(@truncate(x1), @truncate(y2), 0x2570);
    } else if (y2 - y1 > 0) {
        try ncurses.setCharacterAt(@truncate(x1), @truncate(y1), 0x2577);
        try ncurses.setCharacterAt(@truncate(x1), @truncate(y2), 0x2575);
    } else if (x2 - x1 > 0) {
        try ncurses.setCharacterAt(@truncate(x1), @truncate(y1), 0x2576);
        try ncurses.setCharacterAt(@truncate(x2), @truncate(y1), 0x2574);
    } else {
        try ncurses.setCharacterAt(@truncate(x1), @truncate(y1), 0x25cb);
    }
    try ncurses.colorPairOff(colorPair);
}

pub fn textLine(y: u16, text: []const u16, colorPair: u16) !void {
    const w = ncurses.getWidth();
    const h = ncurses.getHeight();
    if (y >= h) return error.OutsideWindow;

    try ncurses.colorPairOn(colorPair);
    for (0..w) |x_usize| {
        const x: u16 = @truncate(x_usize);
        const ch = if (x >= text.len) ' ' else text[x];
        try ncurses.setCharacterAt(x, y, ch);
    }
    try ncurses.colorPairOff(colorPair);
}

pub fn clearScreen() !void {
    const w = ncurses.getWidth();
    const h = ncurses.getHeight();
    for (0..w) |x_usize| {
        const x: u16 = @intCast(x_usize);
        for (0..h) |y_usize| {
            const y: u16 = @intCast(y_usize);
            try ncurses.setCharacterAt(x, y, ' ');
        }
    }
}
