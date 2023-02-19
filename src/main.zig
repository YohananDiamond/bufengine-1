const std = @import("std");

const terminal = @import("terminal.zig");
const utf8 = @import("utf8.zig"); // TODO: study unicode and implement it here

const key = @import("key.zig");
const Keybinding = key.Keybinding;
const Keymap = key.Keymap;
const KeymapStack = key.KeymapStack;

const Editor = @import("Editor.zig");

pub fn main() u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const i_stream = std.io.getStdIn();

    const o_stream = std.io.getStdErr();
    const o_stream_w = o_stream.writer();

    var term = terminal.Terminal(.posix).init(i_stream, o_stream) catch {
        o_stream_w.print("Fatal error - failed to enable raw mode\n", .{}) catch return 2;
        return 1;
    };
    defer term.deinit() catch {
        o_stream_w.print("Warning - failed to disable raw mode. Your terminal might appear glitchy.\n", .{}) catch {};
    };

    o_stream_w.print("Welcome!\r\n", .{}) catch return 2;

    var editor = Editor{};
    defer editor.deinit();

    const bitch_keymap = Keymap{
        .name = "Bitch Keymap",
        .keys = &[_]Keybinding{
            .{ .key = 'q', .action = .{ .pop_keymap = {} } },
        },
    };

    const root_keymap = Keymap{
        .name = "Root Keymap",
        .keys = &[_]Keybinding{
            .{ .key = 'q', .action = .{ .func = Editor.actions.quit } },
            .{ .key = '', .action = .{ .func = Editor.actions.quit } },
            .{ .key = 'g', .action = .{ .push_keymap = &bitch_keymap } },
        },
    };

    var keymap_stack = KeymapStack.init(&gpa.allocator);
    defer keymap_stack.deinit();

    while (editor.is_active) {
        // get a character from stdin
        // TODO: read special sequences, whatever they are
        const kc = term.getKey() catch {
            o_stream_w.print("Fatal error - could not read from stdin\n", .{}) catch {};
            return 2;
        };

        // resolve current keymap
        switch (kc) {
            0, 170 => unreachable,
            else => {
                const current_keymap = keymap_stack.getLastOrNull() orelse &root_keymap;

                for (current_keymap.keys) |*keybinding| {
                    if (keybinding.key != kc) continue;

                    switch (keybinding.action) {
                        .func => |func| func(&editor),
                        .push_keymap => |keymap| {
                            keymap_stack.push(keymap) catch {
                                o_stream_w.print("Fatal error - could not allocate memory for keymap\r\n", .{}) catch return 2;
                                return 1;
                            };

                            const no_name_str: []const u8 = "<no name>";
                            var runtime_expr = keymap.name orelse no_name_str;
                            o_stream_w.print("Entering keymap - name: {s}\r\n", .{runtime_expr}) catch return 2;
                        },
                        .pop_keymap => if (keymap_stack.popOrNull()) |_| {
                            const no_name_str: []const u8 = "<no name>";
                            var runtime_expr = (keymap_stack.getLastOrNull() orelse &root_keymap).name orelse no_name_str;

                            o_stream_w.print("Popped off stack - current one's name: {s}\r\n", .{runtime_expr}) catch return 2;
                        } else {
                            o_stream_w.print("Attempted to empty keymap stack\r\n", .{}) catch return 2;
                        },
                    }

                    break;
                } else switch (kc) {
                    1...26 => |raw_n| {
                        const n = raw_n - 1 + 65;
                        o_stream_w.print(
                            "Key Ctrl-{c} :: 0x{X} or ASCII {d}\r\n",
                            .{ n, n, n },
                        ) catch return 2;
                    },
                    128...255 => |n| o_stream_w.print(
                        "Key <???> :: 0x{X} or ASCII {d}\r\n",
                        .{ n, n },
                    ) catch return 2,
                    else => |n| {
                        o_stream_w.print(
                            "Key {c} :: 0x{X} or ASCII {d}\r\n",
                            .{ n, n, n },
                        ) catch return 2;
                    },
                }
            },
        }
    }

    return 0;
}
