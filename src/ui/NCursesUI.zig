const Self = @This();

const std = @import("std");
const File = std.fs.File;

const key = @import("../key.zig");
const Keycode = key.Keycode;

const Editor = @import("../Editor.zig");

const math = @import("../math.zig");
const Vec2 = math.Vec2;

pub const InitError = error{InitError};
pub const DeinitError = error{DeinitError};
pub const UiError = error{UiError};

const c = @cImport({
    @cInclude("ncurses.h");
});
const Window = c.WINDOW;

main_win: *Window,

pub fn init() InitError!Self {
    const window = c.initscr() orelse return error.InitError;
    errdefer _ = c.endwin();

    if (c.raw() == c.ERR) return error.InitError;
    if (c.noecho() == c.ERR) return error.InitError;
    if (c.attroff(c.A_BLINK) == c.ERR) return error.InitError;

    return Self{
        .main_win = window,
    };
}

pub fn deinit(self: *Self) DeinitError!void {
    switch (c.endwin()) {
        c.OK => {},
        else => return error.DeinitError,
    }

    self.* = undefined;
}

pub fn waitForKey(self: *Self) UiError!Keycode {
    _ = self;

    const code = c.getch();
    return @intCast(code);

    // TODO: how to detect errors?
}

pub fn print(self: *Self, text: []const u8) UiError!void {
    _ = self;
    if (c.addnstr(text.ptr, @intCast(text.len)) == c.ERR)
        return error.UiError;
}

pub fn _printf(self: *Self, fmt: [*:0]const u8, args: anytype) UiError!void {
    _ = self;
    if (@call(.auto, c.printw, .{fmt} ++ args) == c.ERR)
        return error.UiError;
}

pub fn clear(self: *Self) UiError!void {
    _ = self;
    if (c.erase() == c.ERR)
        return error.UiError;
}

pub fn present(self: *Self) UiError!void {
    _ = self;
    if (c.refresh() == c.ERR)
        return error.UiError;
}

pub fn setPos(self: *Self, pos: Vec2(c_int)) UiError!void {
    _ = self;
    if (c.move(pos.y, pos.x) == c.ERR)
        return error.UiError;
}

pub fn getSize(self: *const Self) UiError!Vec2(c_int) {
    const x = c.getmaxx(self.main_win);
    if (x == c.ERR) return error.UiError;

    const y = c.getmaxy(self.main_win);
    if (y == c.ERR) return error.UiError;

    return Vec2(c_int){ .x = x, .y = y };
}

pub fn drawEditor(self: *Self, editor: *Editor) !void {
    const size = try self.getSize();

    const buf = try editor.getCurrentBuffer();
    for (buf.lines.items, 0..) |line, y| {
        if (y >= @as(usize, @intCast(size.y)) - 2) break;
        try self.setPos(.{ .x = 0, .y = @intCast(y) });
        const len = @min(@as(usize, @intCast(size.x)), line.len);
        try self.print(line[0..len]);
    }

    try self.setPos(.{ .x = 0, .y = size.y - 2 });
    try self.print(editor.last_message);

    try self.setPos(.{ .x = @intCast(buf.pos.x), .y = @intCast(buf.pos.y) });
}
