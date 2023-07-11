const std = @import("std");
const Allocator = std.mem.Allocator;

const math = @import("math.zig");
const Vec2 = math.Vec2;

const key = @import("key.zig");

const Self = @This();

allocator: Allocator,
is_active: bool = true,
buffers: std.ArrayListUnmanaged(Buffer) = .{},
buffer_idx: usize = 0,
last_message: [:0]const u8 = "Welcome!",

pub fn deinit(self: *Self) void {
    self.* = undefined;
}

pub fn deinitFull(self: *@This()) void {
    for (self.buffers.items) |*b| {
        b.deinitFull(self.allocator);
    }
    self.buffers.deinit(self.allocator);
    self.* = undefined;
}

pub const Buffer = struct {
    // TODO: use a specific string type (ropes?)
    lines: std.ArrayListUnmanaged(Line) = .{},
    pos: Vec2(usize) = .{.x = 0, .y = 0},

    pub fn deinitFull(self: *@This(), alloc: Allocator) void {
        for (self.lines.items) |l| {
            alloc.free(l);
        }
        self.lines.deinit(alloc);
        self.* = undefined;
    }

    pub fn update(self: *@This()) void {
        // FIXME: does this crash on 0 lines / 0 columns
        self.pos.y = @min(self.pos.y, self.lines.items.len-1);
        self.pos.x = @min(self.pos.x, self.lines.items[self.pos.y].len-1);
    }

    pub fn addLine(self: *@This(), alloc: Allocator, line: []const u8) Allocator.Error!void {
        const mem = try alloc.dupe(u8, line);
        errdefer alloc.free(mem);
        try self.lines.append(alloc, mem);
    }

    pub fn getCurrentLine(self: *@This()) ?*Line {
        self.update();
        return if (self.lines.items.len == 0) null else &self.lines.items[self.pos.y];
    }
};

// pub const Line = std.ArrayListUnmanaged(u8);
pub const Line = []u8;

pub fn init(alloc: Allocator) Allocator.Error!Self {
    var self = Self{
        .allocator = alloc,
    };

    _ = try self.getCurrentBuffer();
    return self;
}

/// Gets the current buffer.
///
/// If the index doesn't exist, focuses the first buffer.
/// If no buffers exist, creates one.
pub fn getCurrentBuffer(self: *Self) Allocator.Error!*Buffer {
    if (self.buffers.items.len == 0) {
        var buf = Buffer{};
        // TODO: errdefer buf.deinit();

        try buf.addLine(self.allocator, "Welcome to insert-editor-name!");
        try buf.addLine(self.allocator, "This is a buffer. Impressed? I'm not.");
        try buf.addLine(self.allocator, "aargh");
        try buf.addLine(self.allocator, "aargh");
        try buf.addLine(self.allocator, "aargh");
        try buf.addLine(self.allocator, "aargh");
        try buf.addLine(self.allocator, "aargh");
        try buf.addLine(self.allocator, "aargh");
        try buf.addLine(self.allocator, "aargh");
        try self.buffers.append(self.allocator, buf);
    }

    // And yes, this is not a "max". It's more akin to wrapping.
    if (self.buffer_idx >= self.buffers.items.len) {
        self.buffer_idx = 0;
    }

    return &self.buffers.items[self.buffer_idx];
}

pub const actions = struct {
    const DummyError = key.DummyError;

    pub fn quit(editor: *Self) !void {
        editor.is_active = false;
    }

    pub fn moveX(editor: *Self, amount: isize) !void {
        const buf = editor.getCurrentBuffer() catch return error.DummyError;
        buf.pos.x = @intCast(@max(0, @as(isize, @intCast(buf.pos.x)) + amount));
    }

    pub fn moveY(editor: *Self, amount: isize) !void {
        const buf = editor.getCurrentBuffer() catch return error.DummyError;
        buf.pos.y = @intCast(@max(0, @as(isize, @intCast(buf.pos.y)) + amount));
    }

    pub fn moveUp(editor: *Self) !void {
        try moveY(editor, -1);
    }

    pub fn moveDown(editor: *Self) !void {
        try moveY(editor, 1);
    }

    pub fn moveLeft(editor: *Self) !void {
        try moveX(editor, -1);
    }

    pub fn moveRight(editor: *Self) !void {
        try moveX(editor, 1);
    }

    pub fn moveXStart(editor: *Self) !void {
        const buf = editor.getCurrentBuffer() catch return error.DummyError;
        buf.pos.x = 0;
    }

    pub fn moveXEnd(editor: *Self) !void {
        const buf = editor.getCurrentBuffer() catch return error.DummyError;
        if (buf.getCurrentLine()) |l| {
            buf.pos.x = if (l.len == 0) 0 else l.len - 1;
        }
    }
};
