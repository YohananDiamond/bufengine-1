const std = @import("std");
const Allocator = std.mem.Allocator;

const NCursesUI = @import("ui/NCursesUI.zig");

// const utf8 = @import("utf8.zig"); // TODO: study unicode and implement it here

const key = @import("key.zig");
const Keybinding = key.Keybinding;
const Keymap = key.Keymap;
const KeymapStack = key.KeymapStack;

const Editor = @import("Editor.zig");

pub fn main() u8 {
    const log = std.log.scoped(.main);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() != .leak);

    var ui = NCursesUI.init() catch |err| {
        log.err("failed to initialize UI: {}", .{err});
        return 1;
    };
    defer ui.deinit() catch
        log.err("failed to properly deinit UI - the temrinal might appear glitchy from now on", .{});

    mainLoop(gpa.allocator(), &ui) catch |err| {
        log.err("main loop fatal error: {}", .{err});
        return 1;
    };

    return 0;
}

pub fn mainLoop(alloc: Allocator, ui: anytype) !void {
    // const log = std.log.scoped(.editor);

    var editor = try Editor.init(alloc);
    defer editor.deinitFull(alloc);

    var km_stack = std.ArrayList(Keymap).init(alloc);
    defer km_stack.deinit();

    while (editor.is_active) {
        try ui.clear();
        try ui.drawEditor(&editor);

        // TODO: read special sequences, whatever they are
        // handle a bunch of keys at once if they have been typed in a short amount of time (rather instantly - good
        // for pasted content)
        const kc = try ui.waitForKey();

        // resolve current keymap
        const current_keymap = &(km_stack.getLastOrNull() orelse root_keymap);

        for (current_keymap.keys) |*keybinding| {
            if (keybinding.key != kc) continue;

            switch (keybinding.action) {
                .DoFunc => |func| try func(&editor),
                .PushKeymap => |keymap| {
                    try km_stack.append(keymap.*);

                    const no_name_str = "<no name>";
                    editor.last_message = keymap.name orelse no_name_str;
                },
                .PopKeymap => if (km_stack.popOrNull()) |_| {
                    const no_name_str = "<no name>";
                    editor.last_message = (km_stack.getLastOrNull() orelse root_keymap).name orelse no_name_str;
                } else {
                    editor.last_message = "Attempted to pop off empty keymap stack";
                },
            }

            break;
        } else switch (kc) {
            1...26 => |raw_n| {
                const n = raw_n - 1 + 65;
                try ui._printf("Key Ctrl-%c :: 0x%x or ASCII %d\r\n", .{ n, n, n });
            },
            128...255 => |n| try ui._printf("Key <???> :: 0x%x or ASCII %d\r\n", .{ n, n }),
            else => |n| try ui._printf("Key %c :: 0x%x or ASCII %d\r\n", .{ n, n, n }),
        }

        const buf = try editor.getCurrentBuffer();
        buf.update();
    }
}

const bitch_keymap = Keymap{
    .name = "Bitch Keymap",
    .keys = &[_]Keybinding{
        .{ .key = 'q', .action = .{ .PopKeymap = {} } },
    },
};

const root_keymap = Keymap{
    .name = "Root Keymap",
    .keys = &[_]Keybinding{
        .{ .key = 'q', .action = .{ .DoFunc = Editor.actions.quit } },
        .{ .key = 'h', .action = .{ .DoFunc = Editor.actions.moveLeft } },
        .{ .key = 'j', .action = .{ .DoFunc = Editor.actions.moveDown } },
        .{ .key = 'k', .action = .{ .DoFunc = Editor.actions.moveUp } },
        .{ .key = 'l', .action = .{ .DoFunc = Editor.actions.moveRight } },
        .{ .key = '0', .action = .{ .DoFunc = Editor.actions.moveXStart } },
        .{ .key = '$', .action = .{ .DoFunc = Editor.actions.moveXEnd } },
        .{ .key = 'g', .action = .{ .PushKeymap = &bitch_keymap } },
    },
};
