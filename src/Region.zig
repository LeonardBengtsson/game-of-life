const Allocator = @import("std").mem.Allocator;

const Region = @This();

sx: u32,
sy: u32,
data: []bool,

pub fn getCell(self: *const Region, x: u32, y: u32) !bool {
    if (x >= self.sx or y >= self.sy) return error.OutsideRegion;
    return self.data[x + self.sx * y];
}

fn runLengthEncode(self: *const Region) []u8 {
    _ = self;
    @compileError("Not implemented");
}

pub fn free(self: *const Region, allocator: *const Allocator) void {
    allocator.free(self.data);
}
