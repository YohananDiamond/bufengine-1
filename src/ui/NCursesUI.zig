const Self = @This();

const std = @import("std");
const File = std.fs.File;

const key = @import("../key.zig");
const Keycode = key.Keycode;

pub fn Vec2(comptime T: type) type {
    return struct {
        x: T,
        y: T,
    };
}

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
    return @intCast(c_uint, code);

    // TODO: how to detect errors?
}

pub fn print(self: *Self, text: [*:0]const u8) UiError!void {
    _ = self;
    if (c.printw(text) == c.ERR)
        return error.UiError;
}

pub fn _printf(self: *Self, fmt: [*:0]const u8, args: anytype) UiError!void {
    _ = self;
    if (@call(.auto, c.printw, .{fmt} ++ args) == c.ERR)
        return error.UiError;
}

pub fn refresh(self: *Self) UiError!void {
    _ = self;
    if (c.refresh() == c.ERR)
        return error.UiError;
}

pub fn setPos(self: *Self, pos: Vec2(c_int)) UiError!void {
    _ = self;
    if (c.move(pos.y, pos.x) == c.ERR)
        return error.UiError;
}
