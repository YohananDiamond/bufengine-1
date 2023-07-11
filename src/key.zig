const std = @import("std");
const Allocator = std.mem.Allocator;

const Editor = @import("Editor.zig");

pub const Keycode = c_uint; // TODO: switch to u32 when unicode

pub fn isAsciiCtrl(key: Keycode) bool {
    return switch (key) {
        1...26 => true,
        else => false,
    };
}

pub const DummyError = error{DummyError};

pub const Keybinding = struct {
    key: Keycode,
    action: Action,

    pub const Action = union(enum) {
        DoFunc: *const fn (*Editor) DummyError!void,
        PushKeymap: *const Keymap,
        PopKeymap: void,
    };
};

pub const Keymap = struct {
    name: ?[:0]const u8 = null,
    keys: []const Keybinding,
};
