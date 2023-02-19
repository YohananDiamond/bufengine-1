const std = @import("std");
const Allocator = std.mem.Allocator;

const Editor = @import("Editor.zig");

pub const Keycode = u8; // TODO: switch to u32 when unicode

pub fn isAsciiCtrl(key: Keycode) bool {
    return switch (key) {
        1...26 => true,
        else => false,
    };
}

pub const Keybinding = struct {
    key: u8,
    action: Action,

    const Action = union(enum) {
        func: fn (*Editor) void,
        push_keymap: *const Keymap,
        pop_keymap: void,
    };
};

pub const Keymap = struct {
    name: ?[]const u8 = null,
    keys: []const Keybinding,
};

pub const KeymapStack = struct {
    stack: std.ArrayList(*const Keymap),

    const Self = @This();

    pub fn init(allocator: *Allocator) Self {
        return .{
            .stack = std.ArrayList(*const Keymap).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.stack.deinit();
    }

    pub fn push(self: *Self, keymap: *const Keymap) Allocator.Error!void {
        try self.stack.append(keymap);
    }

    pub fn popOrNull(self: *Self) ?*const Keymap {
        return self.stack.popOrNull();
    }

    pub fn getLastOrNull(self: *const Self) ?*const Keymap {
        return if (self.stack.items.len == 0)
            null
        else
            self.stack.items[self.stack.items.len - 1];
    }
};
